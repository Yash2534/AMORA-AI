const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase.toLowerCase() === String(applicationDatabase || '').toLowerCase() || !/test/i.test(testDatabase)) {
  throw new Error('Location integration tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { distanceKm, sqlDistanceExpression } = require('../src/utils/geoDistance');

let server;
let baseUrl;
let models;
let viewer;
let token;
const users = [];
const candidates = {};

function birthDateForAge(age) {
  return `${new Date().getUTCFullYear() - age}-02-01`;
}

async function createMember(name, profileValues = {}) {
  const suffix = `${Date.now()}_${users.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@location.test`,
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
  });
  users.push(user.id);
  const profile = await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: birthDateForAge(28),
    gender: profileValues.gender || 'Male',
    interestedIn: profileValues.interestedIn || ['Female'],
    relationshipGoals: ['long_term'],
    city: profileValues.city || 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    interests: profileValues.interests || ['music', 'hiking'],
    languages: ['Gujarati', 'English'],
    photos: ['/uploads/location-one.jpg', '/uploads/location-two.jpg'],
    matchLatitude: profileValues.matchLatitude ?? null,
    matchLongitude: profileValues.matchLongitude ?? null,
    locationUpdatedAt: profileValues.matchLatitude == null ? null : new Date(),
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
    headers: { authorization: `Bearer ${token}`, ...(options.headers || {}) },
  });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  ({ user: viewer } = await createMember('Location Viewer', {
    gender: 'Female',
    interestedIn: ['Male'],
  }));
  token = jwt.sign({ sub: viewer.id }, process.env.JWT_SECRET, { expiresIn: '15m' });
  candidates.closest = await createMember('Closest Candidate', {
    city: 'Vadodara', matchLatitude: 23.0225, matchLongitude: 72.5764,
  });
  candidates.near = await createMember('Near Candidate', {
    matchLatitude: 23.0325, matchLongitude: 72.5814,
  });
  candidates.boundary = await createMember('Boundary Candidate', {
    matchLatitude: 23.0225, matchLongitude: 72.5811,
  });
  candidates.outside = await createMember('Outside Candidate', {
    matchLatitude: 24.0225, matchLongitude: 72.5714,
  });
  candidates.missing = await createMember('Missing Location Candidate');
  await models.DiscoverFilterPreference.create({
    userId: viewer.id, minAge: 18, maxAge: 45, maxDistanceKm: 50, minScore: 0,
  });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && users.length) {
    await models.MatchRecommendationEvent.destroy({ where: { viewerUserId: users } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: users }, { targetUserId: users }] } });
    await models.DiscoverFilterPreference.destroy({ where: { userId: users } });
    await models.OnboardingProfile.destroy({ where: { userId: users } });
    await models.User.destroy({ where: { id: users } });
  }
  try { await getSequelize().close(); } catch (_) { /* already closed */ }
});

test('legacy viewer without coordinates keeps default Discover but Near You requires location', async () => {
  const defaultFeed = await authorized('/api/discover/feed?limit=30');
  assert.equal(defaultFeed.status, 200);
  assert.equal(defaultFeed.body.data.locationMatching.viewerLocationAvailable, false);
  assert.equal(defaultFeed.body.data.locationMatching.distanceFilterActive, false);
  assert.ok(defaultFeed.body.data.profiles.some((item) => item.id === String(candidates.missing.user.id)));
  assert.ok(defaultFeed.body.data.profiles.every((item) => item.distanceKm === null && item.distance === null));

  const nearYou = await authorized('/api/discover/feed?surface=near_you');
  assert.equal(nearYou.status, 409);
  assert.equal(nearYou.body.code, 'LOCATION_REQUIRED');
});

test('location API enforces authentication, strict coordinates, ownership, and server timestamp', async () => {
  assert.equal((await request('/api/me/location')).status, 401);
  for (const body of [
    { latitude: 91, longitude: 0 }, { latitude: -91, longitude: 0 },
    { latitude: 0, longitude: 181 }, { latitude: 0, longitude: -181 },
    { latitude: '23.0225', longitude: 72.5714 }, { latitude: null, longitude: 0 },
    { latitude: 23.0225 }, { longitude: 72.5714 },
    { latitude: 23.0225, longitude: 72.5714, userId: candidates.near.user.id },
  ]) {
    const response = await authorized('/api/me/location', { method: 'PUT', body: JSON.stringify(body) });
    assert.equal(response.status, 400, JSON.stringify(body));
  }

  const before = Date.now();
  const updated = await authorized('/api/me/location', {
    method: 'PUT',
    body: JSON.stringify({ latitude: 23.0225, longitude: 72.5714 }),
  });
  assert.equal(updated.status, 200);
  assert.equal(updated.body.data.location.locationAvailable, true);
  assert.ok(new Date(updated.body.data.location.locationUpdatedAt).getTime() >= before);
  assert.equal('matchLatitude' in updated.body.data.location, false);
  assert.equal('matchLongitude' in updated.body.data.location, false);
  const other = await candidates.near.profile.reload();
  assert.equal(Number(other.matchLatitude), 23.0325);
});

test('default Discover enforces precise max distance and publishes only rounded distance', async () => {
  const feed = await authorized('/api/discover/feed?limit=30');
  assert.equal(feed.status, 200);
  const ids = feed.body.data.profiles.map((item) => item.id);
  assert.ok(ids.includes(String(candidates.closest.user.id)));
  assert.ok(ids.includes(String(candidates.near.user.id)));
  assert.ok(!ids.includes(String(candidates.outside.user.id)));
  assert.ok(!ids.includes(String(candidates.missing.user.id)));
  for (const profile of feed.body.data.profiles) {
    assert.equal(Number.isInteger(profile.distanceKm), true);
    assert.equal(profile.distance, profile.distanceKm);
    assert.equal('matchLatitude' in profile, false);
    assert.equal('matchLongitude' in profile, false);
  }

  const publicProfile = await authorized(`/api/profiles/${candidates.near.user.id}`);
  assert.equal(publicProfile.status, 200);
  assert.equal('matchLatitude' in publicProfile.body.data.profile, false);
  assert.equal('matchLongitude' in publicProfile.body.data.profile, false);
});

test('one-kilometre boundary is included while a farther candidate is excluded', async () => {
  await models.DiscoverFilterPreference.update({ maxDistanceKm: 1 }, { where: { userId: viewer.id } });
  const feed = await authorized('/api/discover/feed?limit=30');
  const ids = feed.body.data.profiles.map((item) => item.id);
  assert.ok(ids.includes(String(candidates.boundary.user.id)));
  assert.ok(!ids.includes(String(candidates.near.user.id)));
  await models.DiscoverFilterPreference.update({ maxDistanceKm: 50 }, { where: { userId: viewer.id } });
});

test('Near You ranks distance then compatibility then stable user id and city remains independent', async () => {
  const nearYou = await authorized('/api/discover/feed?surface=near_you&limit=30');
  assert.equal(nearYou.status, 200);
  const ids = nearYou.body.data.profiles.map((item) => item.id);
  assert.ok(ids.indexOf(String(candidates.closest.user.id)) < ids.indexOf(String(candidates.near.user.id)));

  await models.DiscoverFilterPreference.update({ city: 'Ahmedabad' }, { where: { userId: viewer.id } });
  const cityFeed = await authorized('/api/discover/feed?surface=near_you&limit=30');
  assert.ok(!cityFeed.body.data.profiles.some((item) => item.id === String(candidates.closest.user.id)));
  assert.ok(cityFeed.body.data.profiles.some((item) => item.id === String(candidates.near.user.id)));
  await models.DiscoverFilterPreference.update({ city: null }, { where: { userId: viewer.id } });
});

test('Near You cursor preserves distance, compatibility, and id order without duplicates', async () => {
  const pages = [];
  let cursor;
  let firstCursor;
  do {
    const result = await authorized(`/api/discover/feed?surface=near_you&limit=1${cursor ? `&cursor=${encodeURIComponent(cursor)}` : ''}`);
    assert.equal(result.status, 200, JSON.stringify(result.body));
    pages.push(...result.body.data.profiles);
    cursor = result.body.data.pagination.nextCursor;
    firstCursor ??= cursor;
  } while (cursor && pages.length < 10);
  assert.equal(new Set(pages.map((profile) => profile.id)).size, pages.length);
  for (let index = 1; index < pages.length; index += 1) {
    assert.ok(
      pages[index - 1].distanceKm <= pages[index].distanceKm,
      `${pages[index - 1].distanceKm} must precede ${pages[index].distanceKm}`,
    );
  }
  const defaultFirst = await authorized('/api/discover/feed?limit=1');
  const wrongSurface = await authorized(`/api/discover/feed?surface=near_you&limit=1&cursor=${encodeURIComponent(defaultFirst.body.data.pagination.nextCursor)}`);
  assert.equal(wrongSurface.status, 400);
  assert.equal(wrongSurface.body.code, 'PAGINATION_CURSOR_INVALID');
  const viewerProfile = await models.OnboardingProfile.findOne({ where: { userId: viewer.id } });
  await viewerProfile.update({ matchLatitude: 23.0226 });
  const changedLocation = await authorized(`/api/discover/feed?surface=near_you&limit=1&cursor=${encodeURIComponent(firstCursor)}`);
  assert.equal(changedLocation.status, 400);
  assert.equal(changedLocation.body.code, 'PAGINATION_CONTEXT_CHANGED');
  await viewerProfile.update({ matchLatitude: 23.0225 });
});

test('Near You keyset remains gap-free after page-one action with equal-distance ties', async () => {
  const city = `NearCursor${Date.now()}`;
  const fixtures = [];
  for (let index = 0; index < 5; index += 1) {
    fixtures.push(await createMember(`Near cursor ${index}`, {
      city,
      matchLatitude: 23.0425,
      matchLongitude: 72.5814,
      interests: index === 0 ? ['unrelated'] : ['music', 'hiking'],
    }));
  }
  const first = await authorized(`/api/discover/feed?surface=near_you&city=${city}&limit=2`);
  assert.equal(first.status, 200);
  const firstIds = first.body.data.profiles.map((profile) => profile.id);
  assert.equal(firstIds.length, 2);
  await models.DiscoverAction.create({ actorUserId: viewer.id, targetUserId: Number(firstIds[0]), action: 'pass' });

  const allIds = [...firstIds];
  let cursor = first.body.data.pagination.nextCursor;
  while (cursor) {
    const page = await authorized(`/api/discover/feed?surface=near_you&city=${city}&limit=2&cursor=${encodeURIComponent(cursor)}`);
    assert.equal(page.status, 200, JSON.stringify(page.body));
    allIds.push(...page.body.data.profiles.map((profile) => profile.id));
    cursor = page.body.data.pagination.nextCursor;
  }
  assert.equal(new Set(allIds).size, allIds.length);
  assert.equal(allIds.length, fixtures.length);
});

test('AI Matches shares geographic eligibility and SQL distance agrees with canonical JS', async () => {
  const ai = await authorized('/api/discover/ai-matches?limit=30');
  assert.equal(ai.status, 200);
  const ids = ai.body.data.recommendations.map((item) => item.id);
  assert.ok(ids.includes(String(candidates.near.user.id)));
  assert.ok(!ids.includes(String(candidates.outside.user.id)));
  assert.ok(!ids.includes(String(candidates.missing.user.id)));
  assert.ok(ai.body.data.recommendations.every((item) => Number.isInteger(item.profile.distanceKm)));

  const sequelize = getSequelize();
  const expression = sqlDistanceExpression(sequelize, {
    viewerLatitude: 23.0225,
    viewerLongitude: 72.5714,
  });
  const [rows] = await sequelize.query(
    `SELECT ${expression} AS distanceValue FROM \`OnboardingProfiles\` AS \`OnboardingProfile\` WHERE \`OnboardingProfile\`.\`id\` = :profileId`,
    { replacements: { profileId: candidates.near.profile.id } },
  );
  const jsDistance = distanceKm(23.0225, 72.5714, 23.0325, 72.5814);
  assert.ok(Math.abs(Number(rows[0].distanceValue) - jsDistance) < 0.000001);
});

test('candidate reciprocal age uses inclusive bounds, defaults safely, and never creates preference rows', async () => {
  const candidateId = candidates.near.user.id;
  assert.equal(await models.DiscoverFilterPreference.count({ where: { userId: candidateId } }), 0);
  let feed = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.ok(feed.body.data.profiles.some((item) => item.id === String(candidateId)));
  assert.equal(await models.DiscoverFilterPreference.count({ where: { userId: candidateId } }), 0);

  await models.DiscoverFilterPreference.create({
    userId: candidateId, minAge: 29, maxAge: 45, maxDistanceKm: 80, minScore: 0,
  });
  feed = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.ok(!feed.body.data.profiles.some((item) => item.id === String(candidateId)));
  let ai = await authorized('/api/discover/ai-matches?limit=30&minScore=0');
  assert.ok(!ai.body.data.recommendations.some((item) => item.id === String(candidateId)));

  await models.DiscoverFilterPreference.update({ minAge: 18, maxAge: 27 }, { where: { userId: candidateId } });
  feed = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.ok(!feed.body.data.profiles.some((item) => item.id === String(candidateId)));

  await models.DiscoverFilterPreference.update({ minAge: 28, maxAge: 28 }, { where: { userId: candidateId } });
  feed = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.ok(feed.body.data.profiles.some((item) => item.id === String(candidateId)));
  ai = await authorized('/api/discover/ai-matches?limit=30&minScore=0');
  assert.ok(ai.body.data.recommendations.some((item) => item.id === String(candidateId)));

  await models.DiscoverFilterPreference.update({ minAge: 50, maxAge: 20 }, { where: { userId: candidateId } });
  feed = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.ok(feed.body.data.profiles.some((item) => item.id === String(candidateId)));
  await models.DiscoverFilterPreference.destroy({ where: { userId: candidateId } });
});

test('reciprocal distance uses the same distance for both limits in Discover, Near You, and AI Matches', async () => {
  await models.DiscoverFilterPreference.create({
    userId: candidates.near.user.id, minAge: 18, maxAge: 45, maxDistanceKm: 1, minScore: 0,
  });
  await models.DiscoverFilterPreference.create({
    userId: candidates.boundary.user.id, minAge: 18, maxAge: 45, maxDistanceKm: 1, minScore: 0,
  });
  await models.DiscoverFilterPreference.create({
    userId: candidates.outside.user.id, minAge: 18, maxAge: 45, maxDistanceKm: 300, minScore: 0,
  });

  const discover = await authorized('/api/discover/feed?limit=30&minScore=0');
  const discoverIds = discover.body.data.profiles.map((item) => item.id);
  assert.ok(!discoverIds.includes(String(candidates.near.user.id)));
  assert.ok(discoverIds.includes(String(candidates.boundary.user.id)));
  assert.ok(!discoverIds.includes(String(candidates.outside.user.id)));

  const nearYou = await authorized('/api/discover/feed?surface=near_you&limit=30&minScore=0');
  const nearIds = nearYou.body.data.profiles.map((item) => item.id);
  assert.ok(!nearIds.includes(String(candidates.near.user.id)));
  assert.ok(nearIds.includes(String(candidates.boundary.user.id)));

  const ai = await authorized('/api/discover/ai-matches?limit=30&minScore=0');
  const aiIds = ai.body.data.recommendations.map((item) => item.id);
  assert.ok(!aiIds.includes(String(candidates.near.user.id)));
  assert.ok(aiIds.includes(String(candidates.boundary.user.id)));

  await models.DiscoverFilterPreference.destroy({
    where: { userId: [candidates.near.user.id, candidates.boundary.user.id, candidates.outside.user.id] },
  });
});

test('reciprocal preferences and internal exclusion details never enter public payloads', async () => {
  const feed = await authorized('/api/discover/feed?limit=30&minScore=0');
  const forbidden = [
    'candidateMinAge', 'candidateMaxAge', 'candidateMaxDistanceKm',
    'candidateDealbreakers', 'exclusionReason', 'matchLatitude', 'matchLongitude',
  ];
  for (const profile of feed.body.data.profiles) {
    for (const key of forbidden) assert.equal(Object.hasOwn(profile, key), false, key);
  }
});

test('clearing location does not clear city and restores migration-safe Discover', async () => {
  const cleared = await authorized('/api/me/location', { method: 'DELETE' });
  assert.equal(cleared.status, 200);
  assert.equal(cleared.body.data.location.locationAvailable, false);
  const profile = await models.OnboardingProfile.findOne({ where: { userId: viewer.id } });
  assert.equal(profile.matchLatitude, null);
  assert.equal(profile.matchLongitude, null);
  assert.equal(profile.locationUpdatedAt, null);
  assert.equal(profile.city, 'Ahmedabad');
  const feed = await authorized('/api/discover/feed?limit=30');
  assert.ok(feed.body.data.profiles.some((item) => item.id === String(candidates.missing.user.id)));
});
