const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');

const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (
  !testDatabase
  || testDatabase.toLowerCase() === String(applicationDatabase || '').toLowerCase()
  || !/test/i.test(testDatabase)
) {
  throw new Error('Discover integration tests require a separate TEST_DB_NAME containing "test".');
}

process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { scoreCompatibility, sqlCompatibilityExpressions } = require('../src/services/matchEngineService');
const { _test: discoverTest } = require('../src/controllers/discoverController');

let server;
let baseUrl;
let models;
let accessToken;
const userIds = [];
const phones = [];
const candidates = {};

function birthDateForAge(age) {
  return `${new Date().getUTCFullYear() - age}-01-15`;
}

async function createUser(name, values = {}) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@phase1.test`,
    phoneNumber: values.phoneNumber || '',
    authProvider: 'local',
    isVerified: values.isVerified ?? true,
    identityVerifiedAt: (values.isVerified ?? true) ? new Date() : null,
    termsAcceptedAt: new Date(),
  });
  userIds.push(user.id);
  if (user.phoneNumber) phones.push(user.phoneNumber);
  return user;
}

async function createProfile(user, values = {}) {
  return models.OnboardingProfile.create({
    userId: user.id,
    birthDate: values.birthDate || birthDateForAge(28),
    gender: values.gender || 'Male',
    interestedIn: values.interestedIn || ['Female'],
    relationshipGoals: values.relationshipGoals || ['long_term'],
    city: values.city || 'Ahmedabad',
    profession: values.profession || 'Engineer',
    education: values.education || 'Graduate',
    hometown: values.hometown || 'Ahmedabad',
    interests: values.interests || ['hiking', 'music'],
    lifestyle: values.lifestyle || { fitness: 'active', drinking: 'never' },
    prompts: values.prompts || { idealDate: 'Coffee and a walk' },
    pronouns: values.pronouns || ['she/her'],
    sexuality: values.sexuality || 'straight',
    valuedQualities: values.valuedQualities || ['kindness'],
    loveLanguages: values.loveLanguages || ['quality_time'],
    preferredTalkingHours: values.preferredTalkingHours || ['evening'],
    communicationStyle: values.communicationStyle || 'calls',
    languages: values.languages || ['Gujarati', 'English'],
    photos: ['/uploads/test-one.jpg', '/uploads/test-two.jpg'],
    stage: values.onboardingCompleted === false ? 'photos' : 'complete',
    onboardingCompleted: values.onboardingCompleted ?? true,
  });
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

function authorized(path) {
  return request(path, { headers: { authorization: `Bearer ${accessToken}` } });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();

  const viewer = await createUser('Phase Viewer');
  await createProfile(viewer, {
    gender: 'Female',
    interestedIn: ['Male'],
    languages: ['Gujarati', 'English'],
    interests: ['hiking', 'music'],
    valuedQualities: ['kindness'],
  });
  accessToken = jwt.sign({ sub: viewer.id }, process.env.JWT_SECRET, { expiresIn: '15m' });

  for (const [key, values] of Object.entries({
    callOne: { communicationStyle: 'calls', city: 'Ahmedabad', languages: ['Gujarati', 'English'] },
    callTwo: { communicationStyle: 'calls', city: 'Vadodara', languages: ['Gujarati'] },
    callThree: { communicationStyle: 'calls', city: 'Ahmedabad', languages: ['Gujarati', 'Hindi'] },
    callFour: { communicationStyle: 'calls', city: 'Surat', languages: ['Hindi'] },
    voiceBoosted: { communicationStyle: 'voice_notes', city: 'Mumbai', languages: ['English'] },
  })) {
    const user = await createUser(key);
    await createProfile(user, values);
    candidates[key] = user;
  }

  candidates.swiped = await createUser('swiped');
  await createProfile(candidates.swiped, { communicationStyle: 'calls' });
  await models.DiscoverAction.create({ actorUserId: viewer.id, targetUserId: candidates.swiped.id, action: 'pass' });

  candidates.unverified = await createUser('unverified', { isVerified: false });
  await createProfile(candidates.unverified, { communicationStyle: 'calls' });
  candidates.incomplete = await createUser('incomplete');
  await createProfile(candidates.incomplete, { communicationStyle: 'calls', onboardingCompleted: false });
  candidates.tooOld = await createUser('tooOld');
  await createProfile(candidates.tooOld, { communicationStyle: 'calls', birthDate: birthDateForAge(60) });

  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && userIds.length) {
    await models.RoseTransaction.destroy({ where: { [Op.or]: [{ senderId: userIds }, { recipientId: userIds }] } });
    await models.SavedProfile.destroy({ where: { [Op.or]: [{ userId: userIds }, { savedUserId: userIds }] } });
    await models.Report.destroy({ where: { [Op.or]: [{ reporterUserId: userIds }, { reportedUserId: userIds }] } });
    await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
    await models.MatchRecommendationEvent.destroy({ where: { viewerUserId: userIds } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
    await models.DiscoverFilterPreference.destroy({ where: { userId: userIds } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.RefreshToken.destroy({ where: { userId: userIds } });
    if (phones.length) await models.OtpToken.destroy({ where: { phoneNumber: phones } });
    await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

test('Discover rejects missing and invalid authentication', async () => {
  const missing = await request('/api/discover/feed');
  assert.equal(missing.status, 401);
  assert.equal(missing.body.code, 'TOKEN_INVALID');

  const invalid = await request('/api/discover/feed', {
    headers: { authorization: 'Bearer not-a-token' },
  });
  assert.equal(invalid.status, 401);
  assert.equal(invalid.body.code, 'TOKEN_INVALID');
});

test('Discover filter ranges accept boundaries, reject malformed values, and normalize stale storage', async () => {
  const headers = { authorization: `Bearer ${accessToken}` };
  const update = (body) => request('/api/discover/filters', {
    method: 'PUT',
    headers,
    body: JSON.stringify(body),
  });

  const minimum = await update({
    minAge: 18,
    maxAge: 18,
    maxDistanceKm: 1,
    minScore: 0,
    minHeight: 137,
  });
  assert.equal(minimum.status, 200, JSON.stringify(minimum.body));

  const maximum = await update({
    minAge: 99,
    maxAge: 99,
    maxDistanceKm: 300,
    minScore: 100,
    minHeight: 213,
  });
  assert.equal(maximum.status, 200, JSON.stringify(maximum.body));
  assert.equal(maximum.body.data.filters.maxDistanceKm, 300);

  for (const invalidBody of [
    { maxDistanceKm: 301 },
    { maxDistanceKm: 0 },
    { maxDistanceKm: 'not-a-number' },
    { minHeight: 136 },
    { minHeight: 214 },
  ]) {
    const invalid = await update(invalidBody);
    assert.equal(invalid.status, 400, JSON.stringify(invalid.body));
  }
  const invalidFeed = await authorized('/api/discover/feed?maxDistanceKm=301');
  assert.equal(invalidFeed.status, 400);
  const accountPreferenceInvalid = await request('/api/me/preferences', {
    method: 'PUT',
    headers,
    body: JSON.stringify({ maxDistanceKm: 301 }),
  });
  assert.equal(accountPreferenceInvalid.status, 400);
  const accountPreferenceBoundary = await request('/api/me/preferences', {
    method: 'PUT',
    headers,
    body: JSON.stringify({ maxDistanceKm: 300, minHeight: 213 }),
  });
  assert.equal(accountPreferenceBoundary.status, 200, JSON.stringify(accountPreferenceBoundary.body));

  const viewerId = Number(jwt.decode(accessToken).sub);
  await models.DiscoverFilterPreference.update(
    { maxDistanceKm: 500 },
    { where: { userId: viewerId } },
  );
  const normalized = await request('/api/discover/filters', { headers });
  assert.equal(normalized.status, 200);
  assert.equal(normalized.body.data.filters.maxDistanceKm, 300);
  const restored = await update({
    minAge: 18,
    maxAge: 45,
    maxDistanceKm: 80,
    minScore: 0,
    minHeight: null,
  });
  assert.equal(restored.status, 200, JSON.stringify(restored.body));
});

test('authenticated Discover uses database eligibility and exclusions', async () => {
  const result = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.equal(result.status, 200);
  assert.equal(result.body.success, true);
  const ids = result.body.data.profiles.map((profile) => profile.id);
  assert.equal(ids.includes(String(candidates.swiped.id)), false);
  assert.equal(ids.includes(String(candidates.unverified.id)), false);
  assert.equal(ids.includes(String(candidates.incomplete.id)), false);
  assert.equal(ids.includes(String(candidates.tooOld.id)), false);
  assert.equal(ids.includes(String(candidates.voiceBoosted.id)), true);
  assert.ok(result.body.data.profiles.every((profile) => profile.distance === null && profile.status === null && profile.recentlyActive === false));
});

test('canonical completion excludes stale flags and restored required data becomes eligible', async () => {
  const staleCases = [
    ['one-photo', { photos: ['/uploads/only.jpg'] }],
    ['missing-city', { city: '' }],
    ['missing-goal', { relationshipGoals: [] }],
    ['missing-interest', { interestedIn: [] }],
    ['missing-gender', { gender: '' }],
  ];
  const created = [];
  for (const [name, mutation] of staleCases) {
    const user = await createUser(`stale-${name}`);
    const profile = await createProfile(user);
    await profile.update(mutation);
    created.push({ user, profile });
  }

  const excluded = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.equal(excluded.status, 200, JSON.stringify(excluded.body));
  const excludedIds = new Set(excluded.body.data.profiles.map((profile) => profile.id));
  for (const { user } of created) assert.equal(excludedIds.has(String(user.id)), false);

  await created[0].profile.update({ photos: ['/uploads/one.jpg', '/uploads/two.jpg'] });
  const restored = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.equal(restored.status, 200, JSON.stringify(restored.body));
  assert.equal(restored.body.data.profiles.some((profile) => profile.id === String(created[0].user.id)), true);
});

test('Pass, Like, and Super Like exclude while Rose, Save, and Report alone do not', async () => {
  const viewerId = Number(jwt.decode(accessToken).sub);
  const byPolicy = {};
  for (const name of ['pass', 'like', 'superLike', 'rose', 'save', 'report']) {
    const user = await createUser(`policy-${name}`);
    await createProfile(user);
    byPolicy[name] = user;
  }
  for (const action of ['pass', 'like', 'superLike']) {
    await models.DiscoverAction.create({ actorUserId: viewerId, targetUserId: byPolicy[action].id, action });
  }
  await models.RoseTransaction.create({
    senderId: viewerId,
    recipientId: byPolicy.rose.id,
    idempotencyKey: `phase2-rose-${Date.now()}`,
  });
  await models.SavedProfile.create({ userId: viewerId, savedUserId: byPolicy.save.id });
  await models.Report.create({
    reporterUserId: viewerId,
    reportedUserId: byPolicy.report.id,
    targetType: 'profile',
    targetId: String(byPolicy.report.id),
    reason: 'fake_profile',
  });

  const result = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.equal(result.status, 200, JSON.stringify(result.body));
  const ids = new Set(result.body.data.profiles.map((profile) => profile.id));
  for (const action of ['pass', 'like', 'superLike']) assert.equal(ids.has(String(byPolicy[action].id)), false, action);
  for (const relationship of ['rose', 'save', 'report']) assert.equal(ids.has(String(byPolicy[relationship].id)), true, relationship);
});

test('unsupported surfaces fail explicitly while location and AI surfaces use controlled contracts', async () => {
  const nearYou = await authorized('/api/discover/feed?surface=near_you');
  assert.equal(nearYou.status, 409);
  assert.equal(nearYou.body.code, 'LOCATION_REQUIRED');
  for (const surface of ['similar_interests', 'new_here', 'recently_active']) {
    const result = await authorized(`/api/discover/feed?surface=${surface}`);
    assert.equal(result.status, 400, surface);
    assert.equal(result.body.code, 'DISCOVER_SURFACE_UNSUPPORTED');
  }
  const ai = await authorized('/api/discover/ai-matches?limit=2&minScore=0');
  assert.equal(ai.status, 200, JSON.stringify(ai.body));
  assert.equal(ai.body.data.provider, 'LOCAL');
});

test('recent activity serializes safely and onlineNow uses the same window', async () => {
  const recent = await createUser('recent-candidate');
  await createProfile(recent);
  await recent.update({ lastActiveAt: new Date() });
  const stale = await createUser('stale-candidate');
  await createProfile(stale);
  await stale.update({ lastActiveAt: new Date(Date.now() - 60 * 60 * 1000) });

  const all = await authorized('/api/discover/feed?limit=30&minScore=0');
  const recentProfile = all.body.data.profiles.find((profile) => profile.id === String(recent.id));
  const staleProfile = all.body.data.profiles.find((profile) => profile.id === String(stale.id));
  assert.equal(recentProfile.recentlyActive, true);
  assert.equal(recentProfile.status, 'Recently active');
  assert.equal(staleProfile.recentlyActive, false);
  assert.equal(staleProfile.status, null);

  const filtered = await authorized('/api/discover/feed?onlineNow=true&limit=30&minScore=0');
  const filteredIds = new Set(filtered.body.data.profiles.map((profile) => profile.id));
  assert.equal(filteredIds.has(String(recent.id)), true);
  assert.equal(filteredIds.has(String(stale.id)), false);
});

test('Communication Style is filtered before cursor pagination with stable pages', async () => {
  const first = await authorized('/api/discover/feed?communicationStyles=calls&limit=2&minScore=0');
  assert.equal(first.status, 200);
  assert.equal(first.body.data.profiles.length, 2);
  assert.ok(first.body.data.profiles.every((profile) => profile.communicationStyle === 'calls'));
  assert.equal(first.body.data.pagination.hasMore, true);
  assert.equal(typeof first.body.data.pagination.nextCursor, 'string');

  const second = await authorized(`/api/discover/feed?communicationStyles=calls&limit=2&minScore=0&cursor=${encodeURIComponent(first.body.data.pagination.nextCursor)}`);
  assert.equal(second.status, 200);
  assert.equal(second.body.data.profiles.length, 2);
  assert.ok(second.body.data.profiles.every((profile) => profile.communicationStyle === 'calls'));
  const firstIds = new Set(first.body.data.profiles.map((profile) => profile.id));
  assert.ok(second.body.data.profiles.every((profile) => !firstIds.has(profile.id)));
  assert.equal(typeof second.body.data.pagination.hasMore, 'boolean');
});

test('cursor pagination stays duplicate-free across live insert and action mutations', async () => {
  const profession = `CursorMutation${Date.now()}`;
  const fixtures = [];
  for (let index = 0; index < 12; index += 1) {
    const user = await createUser(`cursor-mutation-${index}`);
    await createProfile(user, { profession, interests: ['hiking'], city: 'Ahmedabad' });
    fixtures.push(user);
  }
  const first = await authorized(`/api/discover/feed?profession=${profession}&limit=5&minScore=0`);
  assert.equal(first.status, 200);
  const cursor = first.body.data.pagination.nextCursor;
  assert.equal(typeof cursor, 'string');

  const inserted = await createUser('cursor-mutation-inserted');
  await createProfile(inserted, { profession, interests: ['hiking'], city: 'Ahmedabad' });
  const viewerId = Number(jwt.decode(accessToken).sub);
  await models.DiscoverAction.bulkCreate([
    { actorUserId: viewerId, targetUserId: fixtures[0].id, action: 'pass' },
    { actorUserId: viewerId, targetUserId: fixtures[1].id, action: 'like' },
    { actorUserId: viewerId, targetUserId: fixtures[2].id, action: 'superLike' },
  ]);
  await models.Match.create({ userOneId: Math.min(viewerId, fixtures[5].id), userTwoId: Math.max(viewerId, fixtures[5].id) });
  await models.Block.create({ blockerUserId: viewerId, blockedUserId: fixtures[6].id });
  await fixtures[7].update({ accountStatus: 'deactivated' });

  const allIds = first.body.data.profiles.map((profile) => profile.id);
  let nextCursor = cursor;
  while (nextCursor) {
    const pageResult = await authorized(`/api/discover/feed?profession=${profession}&limit=5&minScore=0&cursor=${encodeURIComponent(nextCursor)}`);
    assert.equal(pageResult.status, 200);
    allIds.push(...pageResult.body.data.profiles.map((profile) => profile.id));
    nextCursor = pageResult.body.data.pagination.nextCursor;
  }
  assert.equal(new Set(allIds).size, allIds.length);
  for (const excluded of [fixtures[5], fixtures[6], fixtures[7]]) assert.equal(allIds.includes(String(excluded.id)), false);
  for (const expected of fixtures.slice(8)) assert.equal(allIds.includes(String(expected.id)), true);
  assert.equal(allIds.includes(String(inserted.id)), true);
});

test('cursors reject tampering, cross-viewer replay, changed filters, and page-number continuation', async () => {
  const first = await authorized('/api/discover/feed?limit=2&minScore=0');
  const cursor = first.body.data.pagination.nextCursor;
  assert.equal(typeof cursor, 'string');
  const tampered = `${cursor.slice(0, -1)}${cursor.endsWith('a') ? 'b' : 'a'}`;
  assert.equal((await authorized(`/api/discover/feed?limit=2&minScore=0&cursor=${encodeURIComponent(tampered)}`)).body.code, 'PAGINATION_CURSOR_INVALID');
  assert.equal((await authorized(`/api/discover/feed?limit=2&minScore=1&cursor=${encodeURIComponent(cursor)}`)).body.code, 'PAGINATION_CONTEXT_CHANGED');
  assert.equal((await authorized('/api/discover/feed?page=2&limit=2')).body.code, 'PAGINATION_CURSOR_REQUIRED');

  const otherViewer = await createUser('cursor-other-viewer');
  await createProfile(otherViewer, { gender: 'Female', interestedIn: ['Male'] });
  const otherToken = jwt.sign({ sub: otherViewer.id }, process.env.JWT_SECRET, { expiresIn: '15m' });
  const replay = await request(`/api/discover/feed?limit=2&minScore=0&cursor=${encodeURIComponent(cursor)}`, {
    headers: { authorization: `Bearer ${otherToken}` },
  });
  assert.equal(replay.status, 400);
  assert.equal(replay.body.code, 'PAGINATION_CURSOR_INVALID');
});

test('database-backed profile and JSON filters compose before pagination', async () => {
  const result = await authorized('/api/discover/feed?city=Ahmedabad&languages=Gujarati&communicationStyles=calls&limit=30&minScore=0');
  assert.equal(result.status, 200);
  const fixtureIds = new Set(Object.values(candidates).map((candidate) => String(candidate.id)));
  assert.deepEqual(
    new Set(result.body.data.profiles.map((profile) => profile.id).filter((id) => fixtureIds.has(id))),
    new Set([String(candidates.callOne.id), String(candidates.callThree.id)]),
  );
});

test('minimum compatibility score is evaluated in the database query', async () => {
  const result = await authorized('/api/discover/feed?minScore=85&limit=30');
  assert.equal(result.status, 200);
  assert.ok(result.body.data.profiles.some((profile) => profile.id === String(candidates.callOne.id)));
  assert.ok(result.body.data.profiles.every((profile) => profile.score >= 85));
});

test('Discover applies reciprocal gender preference, account lifecycle, blocks, and existing-match exclusions', async () => {
  const reciprocalMismatch = await createUser('reciprocal mismatch');
  await createProfile(reciprocalMismatch, { interestedIn: ['Male'] });
  const deactivated = await createUser('deactivated');
  await createProfile(deactivated, {});
  await deactivated.update({ accountStatus: 'deactivated' });
  const blocked = await createUser('blocked');
  await createProfile(blocked, {});
  const matched = await createUser('matched');
  await createProfile(matched, {});
  const viewerId = Number(jwt.decode(accessToken).sub);
  await models.Block.create({ blockerUserId: viewerId, blockedUserId: blocked.id });
  await models.Match.create({ userOneId: Math.min(viewerId, matched.id), userTwoId: Math.max(viewerId, matched.id) });

  const result = await authorized('/api/discover/feed?limit=30&minScore=0');
  assert.equal(result.status, 200);
  const ids = new Set(result.body.data.profiles.map((profile) => profile.id));
  for (const user of [reciprocalMismatch, deactivated, blocked, matched]) assert.equal(ids.has(String(user.id)), false);
});

test('deactivated and deleted accounts are excluded and reactivation restores the same profile', async () => {
  const deactivated = await createUser('lifecycle-deactivated');
  await createProfile(deactivated);
  await deactivated.update({ accountStatus: 'deactivated', deactivatedAt: new Date() });
  const deleted = await createUser('lifecycle-deleted');
  await createProfile(deleted);
  await deleted.update({ accountStatus: 'deleted' });

  const hidden = await authorized('/api/discover/feed?limit=30&minScore=0');
  const hiddenIds = new Set(hidden.body.data.profiles.map((profile) => profile.id));
  assert.equal(hiddenIds.has(String(deactivated.id)), false);
  assert.equal(hiddenIds.has(String(deleted.id)), false);

  await deactivated.update({ accountStatus: 'active', deactivatedAt: null });
  const restored = await authorized('/api/discover/feed?limit=30&minScore=0');
  const restoredIds = new Set(restored.body.data.profiles.map((profile) => profile.id));
  assert.equal(restoredIds.has(String(deactivated.id)), true);
  assert.equal(restoredIds.has(String(deleted.id)), false);
  assert.equal(await models.OnboardingProfile.count({ where: { userId: deactivated.id } }), 1);
});

test('Discover response exposes deterministic additions but no account secrets or client-selected viewer', async () => {
  const result = await authorized(`/api/discover/feed?limit=1&userId=${candidates.callOne.id}`);
  assert.equal(result.status, 200);
  const profile = result.body.data.profiles[0];
  assert.equal(typeof profile.compatibilityScore, 'number');
  assert.ok(Array.isArray(profile.compatibilityReasons));
  for (const privateKey of ['email', 'phoneNumber', 'birthDate', 'passwordHash', 'tokenVersion', 'latitude', 'longitude']) {
    assert.equal(Object.hasOwn(profile, privateKey), false);
  }
  const forbiddenKeys = new Set([
    'passwordHash', 'tokenVersion', 'refreshToken', 'accessToken', 'otp',
    'matchLatitude', 'matchLongitude', 'locationUpdatedAt', 'minAge', 'maxAge',
    'maxDistanceKm', 'deletionReason', 'deletionDetails', 'reportState',
  ]);
  const inspect = (value) => {
    if (Array.isArray(value)) return value.forEach(inspect);
    if (!value || typeof value !== 'object') return;
    for (const [key, nested] of Object.entries(value)) {
      assert.equal(forbiddenKeys.has(key), false, `public recommendation leaked ${key}`);
      inspect(nested);
    }
  };
  inspect(result.body.data);
});

test('opt-in recommendation observability emits bounded stage counts without identity or location labels', async () => {
  const previous = process.env.MATCH_ENGINE_OBSERVABILITY_ENABLED;
  const original = console.log;
  const events = [];
  process.env.MATCH_ENGINE_OBSERVABILITY_ENABLED = 'true';
  console.log = (...values) => {
    const event = values.find((value) => value && typeof value === 'object' && value.event === 'match_engine.recommendation');
    if (event) events.push(event);
  };
  try {
    const result = await authorized('/api/discover/feed?limit=1');
    assert.equal(result.status, 200, JSON.stringify(result.body));
    assert.equal(events.length, 1);
    const event = events[0];
    assert.equal(event.surface, 'default');
    assert.equal(event.provider, 'STANDARD');
    assert.equal(Number.isInteger(event.candidateCounts.beforeEligibility), true);
    assert.equal(Number.isInteger(event.candidateCounts.afterEligibility), true);
    assert.equal(Number.isInteger(event.candidateCounts.afterDistance), true);
    assert.equal(event.candidateCounts.returned, result.body.data.profiles.length);
    const serialized = JSON.stringify(event);
    for (const forbidden of ['viewerUserId', 'candidateUserId', 'nextCursor', 'cursorPayload', 'latitude', 'longitude']) {
      assert.doesNotMatch(serialized, new RegExp(forbidden, 'i'));
    }
  } finally {
    console.log = original;
    if (previous === undefined) delete process.env.MATCH_ENGINE_OBSERVABILITY_ENABLED;
    else process.env.MATCH_ENGINE_OBSERVABILITY_ENABLED = previous;
  }
});

test('100-candidate Discover pagination is eligible-first, stable, ordered, telemetry-safe, and query-bounded', async () => {
  const viewerId = Number(jwt.decode(accessToken).sub);
  const scale = [];
  const queryCountFor = async () => {
    const sequelize = models.User.sequelize;
    const originalQuery = sequelize.query;
    const queries = [];
    sequelize.query = function countedQuery(...args) { queries.push(String(args[0])); return originalQuery.apply(this, args); };
    try { await authorized('/api/discover/feed?limit=10&page=1&minScore=0'); } finally { sequelize.query = originalQuery; }
    return { count: queries.length, sql: queries.find((query) => query.includes('FROM `Users` AS `User`') && query.includes('ORDER BY') && query.includes('OnboardingProfiles')) };
  };
  for (let index = 0; index < 50; index += 1) {
    const user = await createUser(`scale-${index}`);
    await createProfile(user, {
      interests: index % 3 === 0 ? ['hiking', 'music'] : index % 3 === 1 ? ['hiking'] : ['unrelated'],
      relationshipGoals: index % 4 === 0 ? ['long_term'] : ['friendship'],
      communicationStyle: index % 2 === 0 ? 'calls' : 'voice_notes',
      languages: index % 2 === 0 ? ['Gujarati', 'English'] : ['Hindi'],
      city: index % 2 === 0 ? 'Ahmedabad' : 'Surat',
      smoking: index % 2 === 0 ? 'never' : 'often', drinking: 'never', weed: 'never',
    });
    scale.push(user);
  }
  const queryCount50 = await queryCountFor();
  for (let index = 50; index < 100; index += 1) {
    const user = await createUser(`scale-${index}`);
    await createProfile(user, {
      interests: index % 3 === 0 ? ['hiking', 'music'] : index % 3 === 1 ? ['hiking'] : ['unrelated'],
      relationshipGoals: index % 4 === 0 ? ['long_term'] : ['friendship'],
      communicationStyle: index % 2 === 0 ? 'calls' : 'voice_notes',
      languages: index % 2 === 0 ? ['Gujarati', 'English'] : ['Hindi'],
      city: index % 2 === 0 ? 'Ahmedabad' : 'Surat',
      smoking: index % 2 === 0 ? 'never' : 'often', drinking: 'never', weed: 'never',
    });
    scale.push(user);
  }
  const queryCount100 = await queryCountFor();
  assert.ok(queryCount100.count - queryCount50.count < 10, `query growth ${queryCount50.count} -> ${queryCount100.count} must not be candidate-proportional`);
  assert.equal(await models.DiscoverFilterPreference.count({ where: { userId: scale.map((user) => user.id) } }), 0, 'recommendation reads must not create candidate preference rows');
  assert.ok(queryCount100.sql, 'Discover candidate SQL must be captured for EXPLAIN');
  const [plan] = await models.User.sequelize.query(`EXPLAIN ${queryCount100.sql}`);
  assert.ok(plan.length > 0, 'MySQL EXPLAIN must return a plan');
  console.log(`[Gate B] query counts: 50=${queryCount50.count}, 100=${queryCount100.count}; EXPLAIN=${JSON.stringify(plan.map((row) => ({ table: row.table, type: row.type, key: row.key, rows: row.rows, extra: row.Extra })))} `);
  const blockedByViewer = scale[0]; const blocksViewer = scale[1]; const acted = scale[2]; const matched = scale[3]; const tooOld = scale[4]; const reciprocalMismatch = scale[5];
  const incomplete = scale[6]; const deactivated = scale[7]; const liked = scale[8]; const superLiked = scale[9];
  await models.Block.create({ blockerUserId: viewerId, blockedUserId: blockedByViewer.id });
  await models.Block.create({ blockerUserId: blocksViewer.id, blockedUserId: viewerId });
  await models.DiscoverAction.create({ actorUserId: viewerId, targetUserId: acted.id, action: 'pass' });
  await models.Match.create({ userOneId: Math.min(viewerId, matched.id), userTwoId: Math.max(viewerId, matched.id) });
  await models.OnboardingProfile.update({ birthDate: birthDateForAge(60) }, { where: { userId: tooOld.id } });
  await models.OnboardingProfile.update({ interestedIn: ['Male'] }, { where: { userId: reciprocalMismatch.id } });
  await models.OnboardingProfile.update({ onboardingCompleted: false, stage: 'photos' }, { where: { userId: incomplete.id } });
  await models.User.update({ accountStatus: 'deactivated' }, { where: { id: deactivated.id } });
  await models.DiscoverAction.create({ actorUserId: viewerId, targetUserId: liked.id, action: 'like' });
  await models.DiscoverAction.create({ actorUserId: viewerId, targetUserId: superLiked.id, action: 'superLike' });
  const getPage = (cursor) => authorized(`/api/discover/feed?limit=10&minScore=0${cursor ? `&cursor=${encodeURIComponent(cursor)}` : ''}`);
  const first = await getPage();
  const second = await getPage(first.body.data.pagination.nextCursor);
  const third = await getPage(second.body.data.pagination.nextCursor);
  const repeatFirst = await getPage();
  const repeatSecond = await getPage(repeatFirst.body.data.pagination.nextCursor);
  const repeatThird = await getPage(repeatSecond.body.data.pagination.nextCursor);
  for (const result of [first, second, third]) assert.equal(result.status, 200);
  const traversed = [first, second, third];
  let traversalCursor = third.body.data.pagination.nextCursor;
  while (traversalCursor) {
    const result = await getPage(traversalCursor);
    assert.equal(result.status, 200);
    traversed.push(result);
    traversalCursor = result.body.data.pagination.nextCursor;
  }
  const ids = traversed.flatMap((result) => result.body.data.profiles.map((profile) => profile.id));
  assert.equal(new Set(ids).size, ids.length);
  assert.equal(traversed.at(-1).body.data.pagination.hasMore, false);
  assert.equal(traversed.at(-1).body.data.pagination.nextCursor, null);
  assert.deepEqual(first.body.data.profiles.map((p) => p.id), repeatFirst.body.data.profiles.map((p) => p.id));
  assert.deepEqual(second.body.data.profiles.map((p) => p.id), repeatSecond.body.data.profiles.map((p) => p.id));
  assert.deepEqual(third.body.data.profiles.map((p) => p.id), repeatThird.body.data.profiles.map((p) => p.id));
  const excludedScale = [blockedByViewer, blocksViewer, acted, matched, tooOld, reciprocalMismatch, incomplete, deactivated, liked, superLiked];
  for (const excluded of excludedScale) assert.equal(ids.includes(String(excluded.id)), false);
  const excludedScaleIds = new Set(excludedScale.map((user) => user.id));
  for (const expected of scale.filter((user) => !excludedScaleIds.has(user.id))) {
    assert.equal(ids.includes(String(expected.id)), true, `eligible scale candidate ${expected.id} must be returned exactly once`);
  }
  const ranked = [first, second, third].flatMap((result) => result.body.data.profiles);
  for (let index = 1; index < ranked.length; index += 1) assert.ok(ranked[index - 1].score > ranked[index].score || (ranked[index - 1].score === ranked[index].score && Number(ranked[index - 1].id) < Number(ranked[index].id)));
  assert.equal(first.body.data.pagination.limit, 10);
  assert.equal(typeof first.body.data.pagination.nextCursor, 'string');
  assert.equal(typeof first.body.data.pagination.rankingVersion, 'string');
  assert.equal((await authorized('/api/discover/feed?page=2')).body.code, 'PAGINATION_CURSOR_REQUIRED');
  assert.equal((await authorized('/api/discover/feed?page=0')).status, 400);
  assert.equal((await authorized('/api/discover/feed?limit=31')).status, 400);
  assert.ok(ranked.some((profile) => profile.compatibilityCoverage < 100));
  const previousTelemetry = process.env.MATCH_ENGINE_TELEMETRY_ENABLED;
  const previousExperimentEnabled = process.env.MATCH_ENGINE_EXPERIMENT_ENABLED;
  const previousExperimentConfig = process.env.MATCH_ENGINE_EXPERIMENT_CONFIG;
  const snapshot = (result) => result.body.data;
  try {
    process.env.MATCH_ENGINE_TELEMETRY_ENABLED = 'false';
    process.env.MATCH_ENGINE_EXPERIMENT_ENABLED = 'false';
    const baseline = await getPage();
    process.env.MATCH_ENGINE_TELEMETRY_ENABLED = 'true';
    const telemetryOn = await getPage();
    process.env.MATCH_ENGINE_EXPERIMENT_ENABLED = 'true';
    process.env.MATCH_ENGINE_EXPERIMENT_CONFIG = JSON.stringify({ id: 'gate_b', allocation: 0 });
    const control = await getPage();
    process.env.MATCH_ENGINE_EXPERIMENT_CONFIG = JSON.stringify({ id: 'gate_b', allocation: 100 });
    const variant = await getPage();
    assert.deepEqual(snapshot(telemetryOn), snapshot(baseline));
    assert.deepEqual(snapshot(control), snapshot(baseline));
    assert.deepEqual(snapshot(variant), snapshot(baseline));
  } finally {
    process.env.MATCH_ENGINE_TELEMETRY_ENABLED = previousTelemetry;
    process.env.MATCH_ENGINE_EXPERIMENT_ENABLED = previousExperimentEnabled;
    process.env.MATCH_ENGINE_EXPERIMENT_CONFIG = previousExperimentConfig;
  }
});

test('SQL ranking score exactly matches the deterministic service across rich and cold-start profiles', async () => {
  const viewerId = Number(jwt.decode(accessToken).sub);
  const viewer = await models.OnboardingProfile.findOne({ where: { userId: viewerId } });
  const variants = [
    { interests: ['hiking', 'music'], relationshipGoals: ['long_term'], communicationStyle: 'calls', languages: ['Gujarati', 'English'], city: 'Ahmedabad', smoking: 'never', drinking: 'never', weed: 'never' },
    { interests: ['unrelated'], relationshipGoals: ['friendship'], communicationStyle: 'voice_notes', languages: ['Hindi'], city: 'Surat', smoking: 'often', drinking: 'often', weed: 'often' },
    { relationshipGoals: ['long_term'] },
    { interests: [], relationshipGoals: [], communicationStyle: null, languages: [], city: '', smoking: '', drinking: '', weed: '' },
  ];
  const sql = discoverTest.compatibilityScoreSql(models.User.sequelize, viewer);
  for (const [index, values] of variants.entries()) {
    const user = await createUser(`parity-${index}`); const profile = await createProfile(user, values);
    const [rows] = await models.User.sequelize.query(`SELECT ${sql} AS score FROM OnboardingProfiles AS OnboardingProfile WHERE OnboardingProfile.id = ${Number(profile.id)}`);
    assert.equal(Number(rows[0].score), scoreCompatibility(viewer, profile).score);
  }
});

test('SQL generator selects bounded sources for MariaDB 10 and documented MySQL 8', () => {
  const sequelize = models.User.sequelize;
  const originalVersion = sequelize.options.databaseVersion;
  try {
    sequelize.options.databaseVersion = '10.4.32';
    const maria = sqlCompatibilityExpressions(sequelize, { interests: ['music'] }).score;
    assert.match(maria, /seq_0_to_19/);
    assert.doesNotMatch(maria, /JSON_TABLE/);

    sequelize.options.databaseVersion = '8.0.0';
    const mysql = sqlCompatibilityExpressions(sequelize, { interests: ['music'] }).score;
    assert.match(mysql, /JSON_TABLE/);
    assert.match(mysql, /`score_interests_indices`\.`itemIndex` <= 20/);
    assert.doesNotMatch(mysql, /seq_0_to_19/);
  } finally {
    sequelize.options.databaseVersion = originalVersion;
  }
});

test('SQL handles null arrays, declined answers, whitespace and genuine zero safely', async () => {
  const full = { interests: ['music'], relationshipGoals: ['long_term'], communicationStyle: 'calls', languages: ['English'], city: 'Pune', smoking: 'never', drinking: 'never', weed: 'never' };
  const variants = [
    { interests: null, relationshipGoals: null, communicationStyle: null, languages: null, city: null, smoking: null, drinking: null, weed: null },
    { ...full, interests: [], relationshipGoals: [], languages: [], city: '  Pune ', smoking: ' Prefer not to say ', drinking: '', weed: null },
    { interests: ['other'], relationshipGoals: ['friendship'], communicationStyle: 'voice_notes', languages: ['Hindi'], city: 'Surat', smoking: 'often', drinking: 'often', weed: 'often' },
  ];
  const sequelize = models.User.sequelize;
  for (const candidate of variants) {
    const columns = Object.entries(candidate).map(([key, value]) => `${sequelize.escape(Array.isArray(value) ? JSON.stringify(value) : value)} AS ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier(key)}`).join(', ');
    const sql = discoverTest.compatibilityScoreSql(sequelize, full);
    assert.doesNotMatch(sql, /undefined|NaN|Infinity/);
    const [rows] = await sequelize.query(`SELECT ${sql} AS score FROM (SELECT ${columns}) AS OnboardingProfile`);
    assert.notEqual(rows[0].score, null);
    assert.equal(Number(rows[0].score), scoreCompatibility(full, candidate).score);
  }
});

test('SQL and JavaScript score and coverage agree across a deterministic 128-profile dirty matrix', async () => {
  const sequelize = models.User.sequelize;
  const viewer = {
    interests: ['Music', ' travel ', 'music'], relationshipGoals: ['long_term', 'Prefer not to say'],
    communicationStyle: ' Calls ', languages: ['English', ' gujarati '], city: ' Ahmedabad ',
    smoking: 'never', drinking: 'occasionally', weed: 'never',
  };
  const listValues = [
    ['music'], [' Music ', 'music', 'Prefer not to say', '', 7], [], 'malformed-list-shape',
    ['unrelated'], ['MUSIC', ' travel '], [false, 7, 'english'], ['   ', 'Prefer not to say'],
  ];
  const scalarValues = ['calls', ' CALLS ', 'different', '', null, 'Prefer not to say', 7, false];
  const users = await models.User.bulkCreate(Array.from({ length: 128 }, (_, index) => ({
    name: `matrix-${index}`, email: `phase5-matrix-${Date.now()}-${index}@test.invalid`,
    phoneNumber: '', authProvider: 'local', isVerified: true, identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(), accountStatus: 'active',
  })));
  userIds.push(...users.map((user) => user.id));
  const candidates = users.map((user, index) => ({
    userId: user.id, birthDate: birthDateForAge(28), gender: 'Male', interestedIn: ['Female'],
    relationshipGoals: listValues[(index + 1) % listValues.length], city: scalarValues[(index + 2) % scalarValues.length],
    photos: ['/uploads/one.jpg', '/uploads/two.jpg'], onboardingCompleted: true, stage: 'complete',
    interests: listValues[index % listValues.length], languages: listValues[(index + 3) % listValues.length],
    communicationStyle: scalarValues[index % scalarValues.length], smoking: scalarValues[(index + 4) % scalarValues.length],
    drinking: scalarValues[(index + 5) % scalarValues.length], weed: scalarValues[(index + 6) % scalarValues.length],
  }));
  const insertedProfiles = await models.OnboardingProfile.bulkCreate(candidates);
  const profiles = await models.OnboardingProfile.findAll({ where: { id: insertedProfiles.map((profile) => profile.id) }, order: [['id', 'ASC']] });
  const expressions = sqlCompatibilityExpressions(sequelize, viewer);
  const ids = profiles.map((profile) => Number(profile.id)).join(', ');
  const [rows] = await sequelize.query(`SELECT id, ${expressions.score} AS score, ${expressions.coverage} AS coverage FROM OnboardingProfiles AS OnboardingProfile WHERE id IN (${ids}) ORDER BY id ASC`);
  const actual = new Map(rows.map((row) => [Number(row.id), row]));
  for (const profile of profiles) {
    const expected = scoreCompatibility(viewer, profile);
    assert.equal(Number(actual.get(Number(profile.id)).score), expected.score, `score profile ${profile.id}`);
    assert.equal(Number(actual.get(Number(profile.id)).coverage), expected.coverage, `coverage profile ${profile.id}`);
  }
  assert.equal(rows.length, 128);
});

test('minScore exact boundary and canonical dirty-data order use the returned score', async () => {
  const profession = `Phase5Boundary${Date.now()}`;
  const viewerId = Number(jwt.decode(accessToken).sub);
  const viewer = await models.OnboardingProfile.findOne({ where: { userId: viewerId } });
  const created = [];
  for (const [index, interests] of [[0, [' Music ', 'music', '', 'Prefer not to say']], [1, ['music', 'other']], [2, ['other']]]) {
    const user = await createUser(`phase5-boundary-${index}`);
    const profile = await createProfile(user, { profession, interests });
    created.push({ user, score: scoreCompatibility(viewer, profile).score });
  }
  const ranked = await authorized(`/api/discover/feed?profession=${profession}&limit=30&minScore=0`);
  assert.equal(ranked.status, 200, JSON.stringify(ranked.body));
  const expectedOrder = [...created].sort((left, right) => right.score - left.score || left.user.id - right.user.id);
  assert.deepEqual(ranked.body.data.profiles.map((profile) => profile.id), expectedOrder.map(({ user }) => String(user.id)));
  assert.deepEqual(ranked.body.data.profiles.map((profile) => profile.compatibilityScore), expectedOrder.map(({ score }) => score));

  const boundary = expectedOrder[1];
  for (const delta of [-1, 0, 1]) {
    const threshold = boundary.score + delta;
    const result = await authorized(`/api/discover/feed?profession=${profession}&limit=30&minScore=${threshold}`);
    const returned = result.body.data.profiles.some((profile) => profile.id === String(boundary.user.id));
    assert.equal(returned, delta <= 0, `minScore ${threshold}`);
  }
});

test('onlineNow excludes fixture users without persisted presence', async () => {
  const result = await authorized('/api/discover/feed?onlineNow=true&limit=30&minScore=0');
  assert.equal(result.status, 200);
  const fixtureIds = new Set(Object.values(candidates).map((candidate) => String(candidate.id)));
  assert.ok(result.body.data.profiles.every((profile) => !fixtureIds.has(profile.id)));
});

test('verification resend is non-enumerating and sends only to eligible users', async () => {
  const eligiblePhone = '+919876500001';
  const verifiedPhone = '+919876500002';
  const missingPhone = '+919876500003';
  const eligible = await createUser('otp eligible', { phoneNumber: eligiblePhone, isVerified: false });
  await createUser('otp verified', { phoneNumber: verifiedPhone, isVerified: true });

  const eligibleResponse = await request('/api/auth/resend-verification-code', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber: eligiblePhone }),
  });
  const verifiedResponse = await request('/api/auth/resend-verification-code', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber: verifiedPhone.slice(3) }),
  });
  const missingResponse = await request('/api/auth/resend-verification-code', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber: missingPhone.slice(3) }),
  });

  for (const response of [eligibleResponse, verifiedResponse, missingResponse]) {
    assert.equal(response.status, 200);
    assert.equal(response.body.success, true);
    assert.equal(response.body.message, 'If an eligible account exists, a verification code has been sent.');
    assert.deepEqual(Object.keys(response.body).sort(), ['data', 'message', 'success']);
  }
  assert.equal(await models.OtpToken.count({ where: { phoneNumber: eligible.phoneNumber, purpose: 'account_verification' } }), 1);
  assert.equal(await models.OtpToken.count({ where: { phoneNumber: verifiedPhone, purpose: 'account_verification' } }), 0);
  assert.equal(await models.OtpToken.count({ where: { phoneNumber: missingPhone, purpose: 'account_verification' } }), 0);

  const limited = await request('/api/auth/resend-verification-code', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber: eligiblePhone.slice(3) }),
  });
  assert.equal(limited.status, 429);
  assert.equal(limited.body.code, 'RATE_LIMITED');
});
