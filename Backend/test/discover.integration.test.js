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
    gender: values.gender || 'Woman',
    interestedIn: values.interestedIn || ['Men'],
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
    interestedIn: ['Women'],
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
  await models.Boost.create({
    userId: candidates.voiceBoosted.id,
    startedAt: new Date(),
    expiresAt: new Date(Date.now() + 30 * 60 * 1000),
    active: true,
  });

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
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
    await models.Boost.destroy({ where: { userId: userIds } });
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
  assert.equal(second.body.data.pagination.hasMore, false);
  assert.equal(second.body.data.pagination.nextPage, null);
});

test('database-backed profile and JSON filters compose before pagination', async () => {
  const result = await authorized('/api/discover/feed?city=Ahmedabad&languages=Gujarati&communicationStyles=calls&limit=30&minScore=0');
  assert.equal(result.status, 200);
  assert.deepEqual(
    new Set(result.body.data.profiles.map((profile) => profile.id)),
    new Set([String(candidates.callOne.id), String(candidates.callThree.id)]),
  );
});

test('minimum compatibility score is evaluated in the database query', async () => {
  const result = await authorized('/api/discover/feed?minScore=85&limit=30');
  assert.equal(result.status, 200);
  assert.deepEqual(
    result.body.data.profiles.map((profile) => profile.id),
    [String(candidates.callOne.id)],
  );
  assert.ok(result.body.data.profiles[0].score >= 85);
});

test('onlineNow does not invent presence when no persisted source exists', async () => {
  const result = await authorized('/api/discover/feed?onlineNow=true&limit=30&minScore=0');
  assert.equal(result.status, 200);
  assert.deepEqual(result.body.data.profiles, []);
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
