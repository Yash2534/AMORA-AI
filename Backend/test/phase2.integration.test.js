const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Phase 2 integration tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let models;
let server;
let baseUrl;
const users = {};
const userIds = [];
const lifecyclePassword = 'LifecyclePass1!';

const tokenFor = (user) => jwt.sign(
  { sub: user.id, ver: user.tokenVersion || 0 },
  process.env.JWT_SECRET,
  { expiresIn: '15m' },
);
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });

async function createUser(key, state = 'active') {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `P2 ${key}`,
    email: `${suffix}@phase2.test`,
    phoneNumber: '',
    authProvider: 'local',
    passwordHash: key === 'lifecycle' ? await bcrypt.hash(lifecyclePassword, 12) : null,
    isVerified: true,
    termsAcceptedAt: new Date(),
    accountStatus: state,
    deactivatedAt: state === 'deactivated' ? new Date() : null,
    deletedAt: state === 'deleted' ? new Date() : null,
  });
  userIds.push(user.id);
  users[key] = user;
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1998-04-12',
    gender: 'Woman',
    interestedIn: ['Men'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    hometown: 'Ahmedabad',
    interests: ['music', 'hiking'],
    lifestyle: { fitness: 'active' },
    prompts: { idealDate: 'Coffee and a walk' },
    pronouns: ['she/her'],
    valuedQualities: ['kindness'],
    loveLanguages: ['quality_time'],
    preferredTalkingHours: ['evening'],
    communicationStyle: 'calls',
    languages: ['Gujarati', 'English'],
    photos: ['/uploads/phase2-one.jpg', '/uploads/phase2-two.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function request(url, options = {}) {
  const response = await fetch(`${baseUrl}${url}`, options);
  const body = await response.json();
  return { status: response.status, body };
}

async function jsonRequest(url, method, user, body) {
  return request(url, {
    method,
    headers: { ...auth(user), ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await Promise.all([
    createUser('viewer'),
    createUser('target'),
    createUser('outsider'),
    createUser('deactivated', 'deactivated'),
    createUser('deleted', 'deleted'),
    createUser('lifecycle'),
    createUser('deleteMe'),
  ]);
  const first = Math.min(users.viewer.id, users.target.id);
  const second = Math.max(users.viewer.id, users.target.id);
  await models.Match.create({ userOneId: first, userTwoId: second, matchedAt: new Date() });
  await models.DiscoverAction.create({ actorUserId: users.viewer.id, targetUserId: users.target.id, action: 'like' });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    await models.Report.destroy({ where: { [Op.or]: [{ reporterUserId: userIds }, { reportedUserId: userIds }] } });
    await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: userIds }, { blockedUserId: userIds }] } });
    await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
    await models.DiscoverFilterPreference.destroy({ where: { userId: userIds } });
    await models.RefreshToken.destroy({ where: { userId: userIds } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

test('public profile requires auth, enforces lifecycle visibility, and returns safe relationship data', async () => {
  assert.equal((await request(`/api/profiles/${users.target.id}`)).status, 401);
  assert.equal((await request(`/api/profiles/${users.target.id}`, { headers: { authorization: 'Bearer invalid' } })).status, 401);
  const result = await request(`/api/profiles/${users.target.id}`, { headers: auth(users.viewer) });
  assert.equal(result.status, 200);
  assert.equal(result.body.data.profile.relationship.liked, true);
  assert.equal(result.body.data.profile.relationship.matched, true);
  for (const field of ['passwordHash', 'tokenVersion', 'deletionReason', 'otpCode', 'email', 'phoneNumber']) {
    assert.equal(Object.hasOwn(result.body.data.profile, field), false);
  }
  assert.equal((await request('/api/profiles/999999999', { headers: auth(users.viewer) })).status, 404);
  assert.equal((await request(`/api/profiles/${users.deactivated.id}`, { headers: auth(users.viewer) })).status, 404);
  assert.equal((await request(`/api/profiles/${users.deleted.id}`, { headers: auth(users.viewer) })).status, 404);
});

test('blocks are idempotent, forbid self-blocking, enforce both directions, Discover, and matches', async () => {
  assert.equal((await jsonRequest(`/api/blocks/${users.viewer.id}`, 'POST', users.viewer)).status, 400);
  const created = await jsonRequest(`/api/blocks/${users.target.id}`, 'POST', users.viewer);
  const duplicate = await jsonRequest(`/api/blocks/${users.target.id}`, 'POST', users.viewer);
  assert.equal(created.status, 200);
  assert.equal(created.body.data.created, true);
  assert.equal(duplicate.status, 200);
  assert.equal(duplicate.body.data.created, false);
  assert.equal(await models.Block.count({ where: { blockerUserId: users.viewer.id, blockedUserId: users.target.id } }), 1);
  const list = await request('/api/blocks', { headers: auth(users.viewer) });
  assert.deepEqual(list.body.data.blocks.map((item) => item.profile.id), [String(users.target.id)]);
  assert.equal((await request(`/api/profiles/${users.target.id}`, { headers: auth(users.viewer) })).status, 404);
  assert.equal((await request(`/api/profiles/${users.viewer.id}`, { headers: auth(users.target) })).status, 404);
  await models.DiscoverAction.destroy({ where: { actorUserId: users.viewer.id, targetUserId: users.target.id } });
  const feed = await request('/api/discover/feed?limit=30&minScore=0', { headers: auth(users.viewer) });
  assert.equal(feed.status, 200, JSON.stringify(feed.body));
  assert.equal(feed.body.data.profiles.some((profile) => profile.id === String(users.target.id)), false);
  await models.Match.create({
    userOneId: Math.min(users.viewer.id, users.target.id),
    userTwoId: Math.max(users.viewer.id, users.target.id),
    matchedAt: new Date(),
  });
  assert.equal((await request('/api/matches', { headers: auth(users.viewer) })).body.data.matches.length, 0);
  await models.Match.destroy({ where: { [Op.or]: [{ userOneId: users.viewer.id, userTwoId: users.target.id }, { userOneId: users.target.id, userTwoId: users.viewer.id }] } });
  assert.equal((await jsonRequest(`/api/blocks/${users.target.id}`, 'DELETE', users.viewer)).status, 200);
  const repeated = await jsonRequest(`/api/blocks/${users.target.id}`, 'DELETE', users.viewer);
  assert.equal(repeated.status, 200);
  assert.equal(repeated.body.data.removed, false);
});

let reportId;
test('reports validate reasons, persist optional notes, and deduplicate abuse', async () => {
  const invalid = await jsonRequest('/api/reports', 'POST', users.viewer, {
    targetType: 'profile', targetUserId: users.target.id, reason: 'client_controlled_reason',
  });
  assert.equal(invalid.status, 400);
  const valid = await jsonRequest('/api/reports', 'POST', users.viewer, {
    targetType: 'profile', targetUserId: users.target.id, reason: 'harassment', notes: 'Repeated unwanted contact.', status: 'resolved',
  });
  assert.equal(valid.status, 201);
  reportId = valid.body.data.report.id;
  const row = await models.Report.findByPk(reportId);
  assert.equal(row.notes, 'Repeated unwanted contact.');
  assert.equal(row.status, 'open');
  const duplicate = await jsonRequest('/api/reports', 'POST', users.viewer, {
    targetType: 'profile', targetUserId: users.target.id, reason: 'harassment', notes: 'duplicate',
  });
  assert.equal(duplicate.status, 200);
  assert.equal(duplicate.body.data.created, false);
  assert.equal(duplicate.body.data.report.id, reportId);
  const content = await jsonRequest('/api/reports', 'POST', users.viewer, {
    targetType: 'event', targetId: 'phase2-event-1', reason: 'scam',
  });
  assert.equal(content.status, 201);
  assert.equal(content.body.data.report.targetType, 'event');
});

test('account deactivation revokes every session and valid login reactivates the account', async () => {
  const initialLogin = await request('/api/auth/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: users.lifecycle.email, password: lifecyclePassword }),
  });
  assert.equal(initialLogin.status, 200, JSON.stringify(initialLogin.body));
  const token = initialLogin.body.data.accessToken;
  const refreshToken = initialLogin.body.data.refreshToken;
  const deactivated = await request('/api/account/deactivate', { method: 'POST', headers: { authorization: `Bearer ${token}` } });
  assert.equal(deactivated.status, 200);
  assert.equal(deactivated.body.data.user.accountStatus, 'deactivated');
  assert.equal((await request('/api/matches', { headers: { authorization: `Bearer ${token}` } })).status, 401);
  const rejectedRefresh = await request('/api/auth/refresh-token', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });
  assert.equal(rejectedRefresh.status, 401);
  assert.equal((await request(`/api/profiles/${users.lifecycle.id}`, { headers: auth(users.viewer) })).status, 404);
  const hiddenFeed = await request('/api/discover/feed?limit=30&minScore=0', { headers: auth(users.viewer) });
  assert.equal(hiddenFeed.body.data.profiles.some((profile) => profile.id === String(users.lifecycle.id)), false);
  const loginAgain = await request('/api/auth/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: users.lifecycle.email, password: lifecyclePassword }),
  });
  assert.equal(loginAgain.status, 200, JSON.stringify(loginAgain.body));
  assert.equal(loginAgain.body.data.reactivated, true);
  assert.equal(loginAgain.body.data.user.accountStatus, 'active');
  assert.equal((await request('/api/auth/me', { headers: { authorization: `Bearer ${loginAgain.body.data.accessToken}` } })).status, 200);
  assert.equal((await request('/api/auth/me', { headers: { authorization: `Bearer ${token}` } })).status, 401);
  const profile = await models.OnboardingProfile.findOne({ where: { userId: users.lifecycle.id } });
  assert.equal(profile.onboardingCompleted, true);
  assert.equal((await request(`/api/profiles/${users.lifecycle.id}`, { headers: auth(users.viewer) })).status, 200);
});

test('soft deletion revokes old tokens and removes the account from public access', async () => {
  const token = tokenFor(users.deleteMe);
  const deleted = await request('/api/account', {
    method: 'DELETE',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ reason: 'privacy_concerns' }),
  });
  assert.equal(deleted.status, 200);
  const row = await models.User.findByPk(users.deleteMe.id);
  assert.equal(row.accountStatus, 'deleted');
  assert.equal(row.tokenVersion, 1);
  assert.equal(row.name, 'Deleted Member');
  assert.match(row.email, /^deleted-\d+-\d+@deleted\.amora\.invalid$/);
  assert.equal(row.passwordHash, null);
  assert.equal(row.isVerified, false);
  assert.equal((await request('/api/account/reactivate', { method: 'POST', headers: { authorization: `Bearer ${token}` } })).status, 404);
  assert.equal((await request(`/api/profiles/${users.deleteMe.id}`, { headers: auth(users.viewer) })).status, 404);
});

test('matches use the existing table, enforce membership/visibility, and unmatch idempotently', async () => {
  const first = Math.min(users.viewer.id, users.target.id);
  const second = Math.max(users.viewer.id, users.target.id);
  await models.DiscoverAction.upsert({
    actorUserId: users.target.id,
    targetUserId: users.viewer.id,
    action: 'like',
  });
  const swipe = await jsonRequest('/api/discover/swipe', 'POST', users.viewer, {
    targetUserId: users.target.id,
    action: 'like',
  });
  assert.equal(swipe.status, 200);
  assert.equal(swipe.body.data.matched, true);
  await jsonRequest('/api/discover/swipe', 'POST', users.viewer, {
    targetUserId: users.target.id,
    action: 'like',
  });
  const match = await models.Match.findOne({ where: { userOneId: first, userTwoId: second } });
  assert.equal(await models.Match.count({ where: { userOneId: first, userTwoId: second } }), 1);
  const outsiderMatch = await models.Match.create({
    userOneId: Math.min(users.target.id, users.outsider.id),
    userTwoId: Math.max(users.target.id, users.outsider.id),
    matchedAt: new Date(),
  });
  await models.Match.create({
    userOneId: Math.min(users.viewer.id, users.deactivated.id),
    userTwoId: Math.max(users.viewer.id, users.deactivated.id),
    matchedAt: new Date(),
  });
  await models.Match.create({
    userOneId: Math.min(users.viewer.id, users.deleted.id),
    userTwoId: Math.max(users.viewer.id, users.deleted.id),
    matchedAt: new Date(),
  });
  const list = await request('/api/matches', { headers: auth(users.viewer) });
  assert.equal(list.status, 200);
  assert.deepEqual(
    list.body.data.matches.map((item) => item.id),
    [String(match.id)],
    JSON.stringify({
      response: list.body,
      blocks: await models.Block.findAll({ raw: true }),
      matches: await models.Match.findAll({ raw: true }),
    }),
  );
  assert.equal((await request(`/api/matches/${match.id}`, { headers: auth(users.viewer) })).status, 200);
  assert.equal((await request(`/api/matches/${outsiderMatch.id}`, { headers: auth(users.viewer) })).status, 404);
  assert.equal((await request(`/api/matches/${match.id}`, { headers: auth(users.outsider) })).status, 404);
  assert.equal((await jsonRequest(`/api/matches/${match.id}`, 'DELETE', users.outsider)).status, 404);
  const removed = await jsonRequest(`/api/matches/${match.id}`, 'DELETE', users.viewer);
  assert.equal(removed.status, 200);
  assert.equal(removed.body.data.removed, true);
  const repeated = await jsonRequest(`/api/matches/${match.id}`, 'DELETE', users.viewer);
  assert.equal(repeated.status, 200);
  assert.equal(repeated.body.data.removed, false);
});
