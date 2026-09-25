const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Account lifecycle tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

const password = 'LifecyclePass1!';
const ids = [];
let models;
let server;
let baseUrl;
let member;
let rollbackMember;
let viewer;

async function createMember(label) {
  const unique = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: label,
    email: `${unique}@deactivation.test`,
    phoneNumber: `+91${String(Math.floor(Math.random() * 9000000000) + 1000000000).slice(0, 10)}`,
    passwordHash: await bcrypt.hash(password, 12),
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
    accountStatus: 'active',
  });
  ids.push(user.id);
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1997-04-12',
    gender: 'Woman',
    interestedIn: ['Men'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    photos: ['/uploads/preserved-one.jpg', '/uploads/preserved-two.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  return { status: response.status, body: await response.json() };
}

const json = (path, body, token) => request(path, {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    ...(token ? { authorization: `Bearer ${token}` } : {}),
  },
  body: JSON.stringify(body),
});

const login = (user, suppliedPassword = password) => json('/api/auth/login', {
  email: user.email,
  password: suppliedPassword,
});

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  member = await createMember('Lifecycle Member');
  rollbackMember = await createMember('Rollback Member');
  viewer = await createMember('Viewer Member');
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    await models.UserDevice.destroy({ where: { userId: ids } });
    await models.RefreshToken.destroy({ where: { userId: ids } });
    await models.UserLoginEvent.destroy({ where: { userId: ids } });
    await models.OnboardingProfile.destroy({ where: { userId: ids } });
    await models.User.destroy({ where: { id: ids } });
  }
  try { await getSequelize().close(); } catch (_) { /* already closed */ }
});

test('deactivation is authenticated, password-required, and wrong password is non-mutating', async () => {
  assert.equal((await json('/api/account/deactivate', { password })).status, 401);
  const signedIn = await login(member);
  assert.equal(signedIn.status, 200);
  const token = signedIn.body.data.accessToken;
  assert.equal((await json('/api/account/deactivate', {}, token)).status, 400);
  const wrong = await json('/api/account/deactivate', { password: 'WrongPass1!' }, token);
  assert.equal(wrong.status, 401);
  assert.equal(wrong.body.code, 'CURRENT_PASSWORD_INCORRECT');
  await member.reload();
  assert.equal(member.accountStatus, 'active');
  assert.equal((await request('/api/auth/me', { headers: { authorization: `Bearer ${token}` } })).status, 200);
});

test('critical cleanup failure rolls the state transition back', async () => {
  const signedIn = await login(rollbackMember);
  const token = signedIn.body.data.accessToken;
  const originalDestroy = models.UserDevice.destroy;
  models.UserDevice.destroy = async () => { throw new Error('forced device cleanup failure'); };
  try {
    const result = await json('/api/account/deactivate', { password }, token);
    assert.equal(result.status, 500);
  } finally {
    models.UserDevice.destroy = originalDestroy;
  }
  await rollbackMember.reload();
  assert.equal(rollbackMember.accountStatus, 'active');
  assert.equal(await models.RefreshToken.count({ where: { userId: rollbackMember.id } }), 1);
});

let oldAccessToken;
let oldRefreshToken;
let challenge;
let originalProfile;

test('correct password atomically deactivates while preserving identity and profile', async () => {
  const signedIn = await login(member);
  oldAccessToken = signedIn.body.data.accessToken;
  oldRefreshToken = signedIn.body.data.refreshToken;
  originalProfile = (await models.OnboardingProfile.findOne({ where: { userId: member.id } })).toJSON();
  await models.UserDevice.create({
    userId: member.id,
    pushToken: `device-${Date.now()}`,
    platform: 'android',
    lastSeenAt: new Date(),
  });
  const result = await json('/api/account/deactivate', { password }, oldAccessToken);
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.equal(result.body.data.user.accountStatus, 'deactivated');
  await member.reload();
  assert.equal(member.accountStatus, 'deactivated');
  assert.ok(member.deactivatedAt);
  assert.equal(await models.RefreshToken.count({ where: { userId: member.id } }), 0);
  assert.equal(await models.UserDevice.count({ where: { userId: member.id } }), 0);
  const preserved = await models.OnboardingProfile.findOne({ where: { userId: member.id } });
  assert.equal(preserved.onboardingCompleted, true);
  assert.deepEqual(preserved.photos, originalProfile.photos);
  assert.equal((await request('/api/auth/me', { headers: { authorization: `Bearer ${oldAccessToken}` } })).status, 401);
  assert.equal((await json('/api/auth/refresh-token', { refreshToken: oldRefreshToken })).status, 401);
});

test('deactivated account is excluded from discovery, AI matches, and profile lookup', async () => {
  const viewerLogin = await login(viewer);
  const headers = { authorization: `Bearer ${viewerLogin.body.data.accessToken}` };
  assert.equal((await request(`/api/profiles/${member.id}`, { headers })).status, 404);
  const discover = await request('/api/discover/feed?limit=30&minScore=0', { headers });
  assert.equal(discover.status, 200);
  assert.equal(discover.body.data.profiles.some((item) => item.id === String(member.id)), false);
  const ai = await request('/api/discover/ai-matches?limit=30', { headers });
  assert.equal(ai.status, 200);
  const aiItems = ai.body.data.matches || ai.body.data.profiles || [];
  assert.equal(aiItems.some((item) => String(item.id || item.userId) === String(member.id)), false);
});

test('valid login returns only ACCOUNT_DEACTIVATED challenge and invalid password remains rejected', async () => {
  assert.equal((await login(member, 'WrongPass1!')).status, 401);
  const result = await login(member);
  assert.equal(result.status, 403);
  assert.equal(result.body.code, 'ACCOUNT_DEACTIVATED');
  assert.equal(result.body.data.accessToken, undefined);
  assert.equal(result.body.data.refreshToken, undefined);
  challenge = result.body.data.reactivationToken;
  const decoded = jwt.verify(challenge, process.env.JWT_SECRET, {
    issuer: 'amoraa-backend',
    audience: 'amoraa-account-reactivation',
  });
  assert.equal(decoded.sub, String(member.id));
  assert.equal(decoded.purpose, 'account_reactivation');
});

test('invalid, expired, wrong-purpose, and other-user challenges are rejected', async () => {
  assert.equal((await json('/api/auth/reactivate', { reactivationToken: 'invalid' })).status, 401);
  const expired = jwt.sign({ sub: String(member.id), ver: member.tokenVersion, purpose: 'account_reactivation' }, process.env.JWT_SECRET, {
    expiresIn: -1,
    issuer: 'amoraa-backend',
    audience: 'amoraa-account-reactivation',
  });
  assert.equal((await json('/api/auth/reactivate', { reactivationToken: expired })).body.code, 'REACTIVATION_EXPIRED');
  const wrongPurpose = jwt.sign({ sub: String(member.id), ver: member.tokenVersion, purpose: 'password_reset' }, process.env.JWT_SECRET, {
    expiresIn: '10m', issuer: 'amoraa-backend', audience: 'amoraa-account-reactivation',
  });
  assert.equal((await json('/api/auth/reactivate', { reactivationToken: wrongPurpose })).status, 401);
  const activeUserChallenge = jwt.sign({ sub: String(viewer.id), ver: viewer.tokenVersion, purpose: 'account_reactivation' }, process.env.JWT_SECRET, {
    expiresIn: '10m', issuer: 'amoraa-backend', audience: 'amoraa-account-reactivation',
  });
  assert.equal((await json('/api/auth/reactivate', { reactivationToken: activeUserChallenge })).status, 409);
});

test('activation restores the same user and normal session without restarting onboarding', async () => {
  const result = await json('/api/auth/reactivate', { reactivationToken: challenge });
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.equal(result.body.data.user.id, member.id);
  assert.equal(result.body.data.user.accountStatus, 'active');
  assert.ok(result.body.data.accessToken);
  assert.ok(result.body.data.refreshToken);
  await member.reload();
  assert.equal(member.accountStatus, 'active');
  assert.equal(member.deactivatedAt, null);
  const profile = await models.OnboardingProfile.findOne({ where: { userId: member.id } });
  assert.equal(profile.onboardingCompleted, true);
  assert.deepEqual(profile.photos, originalProfile.photos);
  assert.equal((await request('/api/auth/me', { headers: { authorization: `Bearer ${result.body.data.accessToken}` } })).status, 200);
  assert.equal((await json('/api/auth/reactivate', { reactivationToken: challenge })).status, 409);
  assert.equal(await models.User.count({ where: { email: member.email } }), 1);
});

test('deleted accounts cannot enter the reactivation flow', async () => {
  const deleted = await createMember('Deleted Member');
  await deleted.update({ accountStatus: 'deleted', deletedAt: new Date() });
  assert.equal((await login(deleted)).status, 401);
  const forged = jwt.sign({ sub: String(deleted.id), ver: deleted.tokenVersion, purpose: 'account_reactivation' }, process.env.JWT_SECRET, {
    expiresIn: '10m', issuer: 'amoraa-backend', audience: 'amoraa-account-reactivation',
  });
  assert.equal((await json('/api/auth/reactivate', { reactivationToken: forged })).status, 401);
});
