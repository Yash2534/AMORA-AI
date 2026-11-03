const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase.toLowerCase() === String(applicationDatabase || '').toLowerCase() || !/test/i.test(testDatabase)) {
  throw new Error('Location privacy tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const logger = require('../src/utils/logger');
const { validateSwipeEligibility } = require('../src/services/discoverEligibilityPolicy');

let server;
let baseUrl;
let models;
let viewer;
let target;
let viewerToken;
const createdUserIds = [];

function birthDateForAge(age) {
  return `${new Date().getUTCFullYear() - age}-03-15`;
}

async function createMember(name, profileValues = {}) {
  const suffix = `${Date.now()}_${createdUserIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@privacy.test`,
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
  });
  createdUserIds.push(user.id);
  const profile = await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: birthDateForAge(28),
    gender: profileValues.gender || 'Male',
    interestedIn: profileValues.interestedIn || ['Female'],
    relationshipGoals: ['long_term'],
    city: profileValues.city || 'Ahmedabad',
    profession: 'Software Engineer',
    education: 'Postgraduate',
    interests: profileValues.interests || ['technology', 'travel'],
    languages: ['Gujarati', 'English'],
    photos: ['/uploads/privacy-one.jpg', '/uploads/privacy-two.jpg'],
    matchLatitude: profileValues.matchLatitude ?? 23.0225,
    matchLongitude: profileValues.matchLongitude ?? 72.5714,
    locationUpdatedAt: new Date(),
    stage: 'complete',
    onboardingCompleted: true,
  });
  return { user, profile };
}

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
  });
  return { status: response.status, body: await response.json() };
}

function authorized(path, options = {}) {
  return request(path, {
    ...options,
    headers: { authorization: `Bearer ${viewerToken}`, ...(options.headers || {}) },
  });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();

  ({ user: viewer } = await createMember('Privacy Viewer', {
    gender: 'Female',
    interestedIn: ['Male'],
    matchLatitude: 23.0225,
    matchLongitude: 72.5714,
  }));
  viewerToken = jwt.sign({ sub: viewer.id }, process.env.JWT_SECRET, { expiresIn: '15m' });

  ({ user: target } = await createMember('Target Candidate', {
    gender: 'Male',
    interestedIn: ['Female'],
    matchLatitude: 23.0325,
    matchLongitude: 72.5814,
  }));

  await models.DiscoverFilterPreference.create({
    userId: viewer.id,
    minAge: 18,
    maxAge: 45,
    maxDistanceKm: 80,
    minScore: 0,
  });

  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && createdUserIds.length) {
    const { Op } = require('sequelize');
    await models.MatchRecommendationEvent.destroy({ where: { viewerUserId: createdUserIds } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: createdUserIds }, { targetUserId: createdUserIds }] } });
    await models.DiscoverFilterPreference.destroy({ where: { userId: createdUserIds } });
    await models.OnboardingProfile.destroy({ where: { userId: createdUserIds } });
    await models.User.destroy({ where: { id: createdUserIds } });
  }
  try { await getSequelize().close(); } catch (_) { /* already closed */ }
});

const FORBIDDEN_COORDINATE_FIELDS = [
  'latitude', 'longitude', 'matchLatitude', 'matchLongitude',
  'lat', 'lng', 'coordinates', 'geo', 'rawDistance',
  'distanceKmPrecise', 'distanceRank',
];

function assertNoCoordinatesOrPreciseDistance(obj, path = '') {
  if (!obj || typeof obj !== 'object') return;
  if (Array.isArray(obj)) {
    obj.forEach((item, index) => assertNoCoordinatesOrPreciseDistance(item, `${path}[${index}]`));
    return;
  }
  for (const key of Object.keys(obj)) {
    const fullPath = path ? `${path}.${key}` : key;
    assert.equal(
      FORBIDDEN_COORDINATE_FIELDS.includes(key),
      false,
      `Forbidden location/coordinate field "${key}" found at ${fullPath}`,
    );
    if (key === 'distance' || key === 'distanceKm') {
      const val = obj[key];
      if (val !== null) {
        assert.equal(typeof val, 'number', `${fullPath} must be a number or null`);
        assert.equal(Number.isInteger(val), true, `${fullPath} must be an integer, got ${val}`);
        assert.ok(val >= 5, `${fullPath} must be coarsened with minimum 5 km floor, got ${val}`);
        assert.equal(val % 5, 0, `${fullPath} must be a multiple of 5 km, got ${val}`);
      }
    }
    assertNoCoordinatesOrPreciseDistance(obj[key], fullPath);
  }
}

test('1. Discover feed response contains no exact coordinates or raw distances', async () => {
  const res = await authorized('/api/discover/feed?limit=10');
  assert.equal(res.status, 200);
  assertNoCoordinatesOrPreciseDistance(res.body);
  assert.ok(res.body.data.profiles.length > 0);
  for (const p of res.body.data.profiles) {
    assert.equal('matchLatitude' in p, false);
    assert.equal('matchLongitude' in p, false);
    assert.equal('distanceKmPrecise' in p, false);
    assert.equal('distanceRank' in p, false);
  }
});

test('2. AI Matches response contains no exact coordinates or raw distances', async () => {
  const res = await authorized('/api/discover/ai-matches?limit=10');
  assert.equal(res.status, 200);
  assertNoCoordinatesOrPreciseDistance(res.body);
});

test('3. Near You surface response contains no exact coordinates or raw distances', async () => {
  const res = await authorized('/api/discover/feed?surface=near_you&limit=10');
  assert.equal(res.status, 200);
  assertNoCoordinatesOrPreciseDistance(res.body);
  for (const p of res.body.data.profiles) {
    assert.equal('distanceRank' in p, false);
    assert.equal('distanceKmPrecise' in p, false);
  }
});

test('4. Target public profile view contains no coordinates or calculated distance', async () => {
  const res = await authorized(`/api/profiles/${target.id}`);
  assert.equal(res.status, 200);
  assertNoCoordinatesOrPreciseDistance(res.body);
  const profile = res.body.data.profile;
  assert.equal(profile.distance, null);
  assert.equal(profile.distanceKm, null);
  assert.equal('matchLatitude' in profile, false);
  assert.equal('matchLongitude' in profile, false);
});

test('5. Current user own profile view exposes only city and locationAvailable', async () => {
  const res = await authorized('/api/me/profile');
  assert.equal(res.status, 200);
  assertNoCoordinatesOrPreciseDistance(res.body);
  const profile = res.body.data.profile;
  assert.equal(profile.locationAvailable, true);
  assert.equal(profile.location, 'Ahmedabad');
  assert.equal('matchLatitude' in profile, false);
  assert.equal('matchLongitude' in profile, false);
});

test('6. Location management endpoints (GET, PUT, DELETE) never echo coordinates back', async () => {
  const getRes = await authorized('/api/me/location');
  assert.equal(getRes.status, 200);
  assert.equal('matchLatitude' in getRes.body.data.location, false);
  assert.equal('matchLongitude' in getRes.body.data.location, false);
  assert.equal('latitude' in getRes.body.data.location, false);
  assert.equal('longitude' in getRes.body.data.location, false);

  const putRes = await authorized('/api/me/location', {
    method: 'PUT',
    body: JSON.stringify({ latitude: 19.0760, longitude: 72.8777 }),
  });
  assert.equal(putRes.status, 200);
  assert.equal('matchLatitude' in putRes.body.data.location, false);
  assert.equal('matchLongitude' in putRes.body.data.location, false);
  assert.equal('latitude' in putRes.body.data.location, false);
  assert.equal('longitude' in putRes.body.data.location, false);
  assert.equal(putRes.body.data.location.locationAvailable, true);

  // Restore coordinates
  await authorized('/api/me/location', {
    method: 'PUT',
    body: JSON.stringify({ latitude: 23.0225, longitude: 72.5714 }),
  });
});

test('7. OnboardingProfile.prototype.toJSON strips matchLatitude and matchLongitude by default', async () => {
  const profile = await models.OnboardingProfile.findOne({ where: { userId: viewer.id } });
  assert.ok(profile.matchLatitude !== null, 'Model instance has latitude');
  assert.ok(profile.matchLongitude !== null, 'Model instance has longitude');

  const serialized = profile.toJSON();
  assert.equal('matchLatitude' in serialized, false, 'toJSON must not include matchLatitude');
  assert.equal('matchLongitude' in serialized, false, 'toJSON must not include matchLongitude');

  const jsonString = JSON.stringify(profile);
  assert.equal(jsonString.includes('matchLatitude'), false);
  assert.equal(jsonString.includes('matchLongitude'), false);
});

test('8. Logger redacts coordinate and precise distance keys automatically', () => {
  const originalLog = console.log;
  let loggedOutput = '';
  console.log = (...args) => {
    loggedOutput += args.map((a) => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' ');
  };
  try {
    logger.info({
      userId: 42,
      matchLatitude: 23.0225,
      matchLongitude: 72.5714,
      latitude: 19.076,
      longitude: 72.877,
      distanceKmPrecise: 3.14159,
      distanceRank: 3.14159,
      safeCity: 'Ahmedabad',
    });
    assert.ok(loggedOutput.includes('[REDACTED_SENSITIVE_FIELD]'));
    assert.equal(loggedOutput.includes('23.0225'), false, 'Exact latitude must not be logged');
    assert.equal(loggedOutput.includes('72.5714'), false, 'Exact longitude must not be logged');
    assert.equal(loggedOutput.includes('3.14159'), false, 'Exact distance must not be logged');
    assert.ok(loggedOutput.includes('Ahmedabad'), 'Non-sensitive fields must be preserved');
  } finally {
    console.log = originalLog;
  }
});

test('9. validateSwipeEligibility does not retain exact distance in failure object', () => {
  const viewerProfile = {
    birthDate: '1996-01-01',
    gender: 'Female',
    interestedIn: ['Male'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    photos: ['/one.jpg', '/two.jpg'],
    matchLatitude: 23.0225,
    matchLongitude: 72.5714,
    onboardingCompleted: true,
    stage: 'complete',
  };
  const targetProfile = {
    birthDate: '1995-01-01',
    gender: 'Male',
    interestedIn: ['Female'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    photos: ['/one.jpg', '/two.jpg'],
    matchLatitude: 24.0225,
    matchLongitude: 72.5714,
    onboardingCompleted: true,
    stage: 'complete',
  };
  const result = validateSwipeEligibility({
    viewerProfile,
    viewerFilters: { maxDistanceKm: 1 },
    targetUser: { id: 99, accountStatus: 'active' },
    targetProfile,
    targetFilters: { maxDistanceKm: 1 },
  });
  assert.equal(result.eligible, false);
  assert.equal(result.reason, 'distance_exceeded');
  assert.equal('distance' in result, false, 'Exact distance must not be attached to result');
  assert.equal('maxAllowedDistance' in result, false, 'maxAllowedDistance must not be attached to result');
});

test('10. Encrypted recommendation cursors contain zero plaintext coordinates', async () => {
  const res = await authorized('/api/discover/feed?limit=1');
  assert.equal(res.status, 200);
  const cursor = res.body.data.pagination.nextCursor;
  if (cursor) {
    assert.equal(cursor.includes('23.0225'), false);
    assert.equal(cursor.includes('72.5714'), false);
    assert.equal(cursor.includes('matchLatitude'), false);
    assert.equal(cursor.includes('matchLongitude'), false);
  }
});
