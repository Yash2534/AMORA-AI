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
const { scoreCompatibility } = require('../src/services/matchEngineService');
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
  assert.ok(result.body.data.profiles.every((profile) => profile.distance === null && profile.status === null));
});

test('Communication Style is filtered before SQL pagination with stable pages', async () => {
  const first = await authorized('/api/discover/feed?communicationStyles=calls&limit=2&page=1&minScore=0');
  assert.equal(first.status, 200);
  assert.equal(first.body.data.profiles.length, 2);
  assert.ok(first.body.data.profiles.every((profile) => profile.communicationStyle === 'calls'));
  assert.equal(first.body.data.pagination.hasMore, true);
  assert.equal(first.body.data.pagination.nextPage, 2);

  const second = await authorized('/api/discover/feed?communicationStyles=calls&limit=2&page=2&minScore=0');
  assert.equal(second.status, 200);
  assert.equal(second.body.data.profiles.length, 2);
  assert.ok(second.body.data.profiles.every((profile) => profile.communicationStyle === 'calls'));
  const firstIds = new Set(first.body.data.profiles.map((profile) => profile.id));
  assert.ok(second.body.data.profiles.every((profile) => !firstIds.has(profile.id)));
  assert.equal(typeof second.body.data.pagination.hasMore, 'boolean');
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

test('Discover response exposes deterministic additions but no account secrets or client-selected viewer', async () => {
  const result = await authorized(`/api/discover/feed?limit=1&userId=${candidates.callOne.id}`);
  assert.equal(result.status, 200);
  const profile = result.body.data.profiles[0];
  assert.equal(typeof profile.compatibilityScore, 'number');
  assert.ok(Array.isArray(profile.compatibilityReasons));
  for (const privateKey of ['email', 'phoneNumber', 'birthDate', 'passwordHash', 'tokenVersion', 'latitude', 'longitude']) {
    assert.equal(Object.hasOwn(profile, privateKey), false);
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
  const getPage = (page) => authorized(`/api/discover/feed?limit=10&page=${page}&minScore=0`);
  const [first, second, third, repeatFirst, repeatSecond, repeatThird] = await Promise.all([getPage(1), getPage(2), getPage(3), getPage(1), getPage(2), getPage(3)]);
  for (const result of [first, second, third]) assert.equal(result.status, 200);
  const ids = [first, second, third].flatMap((result) => result.body.data.profiles.map((profile) => profile.id));
  assert.equal(new Set(ids).size, ids.length);
  assert.deepEqual(first.body.data.profiles.map((p) => p.id), repeatFirst.body.data.profiles.map((p) => p.id));
  assert.deepEqual(second.body.data.profiles.map((p) => p.id), repeatSecond.body.data.profiles.map((p) => p.id));
  assert.deepEqual(third.body.data.profiles.map((p) => p.id), repeatThird.body.data.profiles.map((p) => p.id));
  for (const excluded of [blockedByViewer, blocksViewer, acted, matched, tooOld, reciprocalMismatch, incomplete, deactivated, liked, superLiked]) assert.equal(ids.includes(String(excluded.id)), false);
  const ranked = [first, second, third].flatMap((result) => result.body.data.profiles);
  for (let index = 1; index < ranked.length; index += 1) assert.ok(ranked[index - 1].score > ranked[index].score || (ranked[index - 1].score === ranked[index].score && Number(ranked[index - 1].id) < Number(ranked[index].id)));
  assert.equal(first.body.data.pagination.limit, 10);
  assert.equal(first.body.data.pagination.nextPage, 2);
  const last = await getPage(100);
  assert.equal(last.body.data.pagination.hasMore, false);
  assert.equal(last.body.data.pagination.nextPage, null);
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
    const baseline = await getPage(1);
    process.env.MATCH_ENGINE_TELEMETRY_ENABLED = 'true';
    const telemetryOn = await getPage(1);
    process.env.MATCH_ENGINE_EXPERIMENT_ENABLED = 'true';
    process.env.MATCH_ENGINE_EXPERIMENT_CONFIG = JSON.stringify({ id: 'gate_b', allocation: 0 });
    const control = await getPage(1);
    process.env.MATCH_ENGINE_EXPERIMENT_CONFIG = JSON.stringify({ id: 'gate_b', allocation: 100 });
    const variant = await getPage(1);
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
