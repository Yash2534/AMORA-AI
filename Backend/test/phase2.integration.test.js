const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
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
const accountDeletionService = require('../src/services/accountDeletionService');
const { AccountDeletionService, FAILURE_CODES } = require('../src/services/accountDeletionService');

let models;
let server;
let baseUrl;
const users = {};
const userIds = [];
const lifecyclePassword = 'LifecyclePass1!';
const deletionPassword = 'DeletionPass1!';

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
    photos: ['/uploads/onboarding-photos/phase2-one.jpg', '/uploads/onboarding-photos/phase2-two.jpg'],
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
    createUser('service'),
    createUser('concurrent'),
    createUser('failure'),
  ]);
  users.deleteMe.passwordHash = await bcrypt.hash(deletionPassword, 12);
  await users.deleteMe.save();
  users.outsider.passwordHash = await bcrypt.hash(deletionPassword, 12);
  await users.outsider.save();
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
    await models.AccountDeletionFileTask.destroy({ where: {} });
    await models.AccountDeletionRequest.destroy({ where: { userId: userIds } });
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

test('account deletion request lifecycle schema stores only minimal operational metadata', async () => {
  assert.equal(models.AccountDeletionRequest.STATUSES.BLOCKED_BY_RETENTION_DECISION, 'BLOCKED_BY_RETENTION_DECISION');
  const request = await models.AccountDeletionRequest.create({
    userId: users.viewer.id,
    requestedAt: new Date(),
  });
  await request.reload();
  assert.match(request.correlationId, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i);
  assert.equal(request.status, 'PENDING');
  assert.equal(request.legalHold, false);
  assert.equal(request.verifiedAt, null);
  assert.equal(request.processingStartedAt, null);
  assert.equal(request.completedAt, null);
  assert.equal(request.failedAt, null);
  await assert.rejects(() => models.AccountDeletionRequest.create({ userId: users.viewer.id, correlationId: crypto.randomUUID(), requestedAt: new Date(), status: 'RANDOM_VALUE' }));
  await assert.rejects(() => models.AccountDeletionRequest.create({ userId: users.viewer.id, correlationId: request.correlationId, requestedAt: new Date() }));
  await assert.rejects(() => models.AccountDeletionRequest.create({ userId: 999999999, correlationId: crypto.randomUUID(), requestedAt: new Date() }));
  const schema = await getSequelize().getQueryInterface().describeTable('AccountDeletionRequests');
  for (const forbidden of ['password', 'otp', 'token', 'aadhaar', 'authToken', 'googleToken']) assert.equal(Object.hasOwn(schema, forbidden), false);
});

test('account deletion service is idempotent, state-safe, and records controlled failures', async () => {
  const testService = new AccountDeletionService({ backupRetentionApproved: true });
  const createVerifiedRequest = (user) => models.AccountDeletionRequest.create({
    userId: user.id, status: 'VERIFIED', requestedAt: new Date(), verifiedAt: new Date(),
  });

  const pending = await models.AccountDeletionRequest.create({ userId: users.outsider.id, requestedAt: new Date() });
  const pendingResult = await testService.execute({ userId: users.outsider.id, deletionRequestId: pending.id, correlationId: pending.correlationId });
  assert.equal(pendingResult.notVerified, true);
  const blocked = await models.AccountDeletionRequest.create({
    userId: users.outsider.id, status: 'BLOCKED_BY_RETENTION_DECISION', legalHold: true, legalHoldReason: 'RETENTION_REVIEW_REQUIRED', requestedAt: new Date(),
  });
  const blockedResult = await testService.execute({ userId: users.outsider.id, deletionRequestId: blocked.id, correlationId: blocked.correlationId });
  assert.equal(blockedResult.blocked, true);

  const serviceRequest = await createVerifiedRequest(users.service);
  const completed = await testService.execute({ userId: users.service.id, deletionRequestId: serviceRequest.id, correlationId: serviceRequest.correlationId, deletionReason: 'privacy_concerns' });
  assert.equal(completed.completed, true);
  await serviceRequest.reload();
  assert.equal(serviceRequest.status, 'COMPLETED');
  assert.ok(serviceRequest.processingStartedAt);
  assert.ok(serviceRequest.completedAt);
  assert.equal(serviceRequest.failedAt, null);
  assert.equal(await models.OnboardingProfile.count({ where: { userId: users.service.id } }), 0, 'missing profile files are treated as already cleaned');
  const repeated = await testService.execute({ userId: users.service.id, deletionRequestId: serviceRequest.id, correlationId: serviceRequest.correlationId });
  assert.equal(repeated.alreadyCompleted, true);

  const concurrentRequest = await createVerifiedRequest(users.concurrent);
  const concurrentResults = await Promise.all([
    testService.execute({ userId: users.concurrent.id, deletionRequestId: concurrentRequest.id, correlationId: concurrentRequest.correlationId, deletionReason: 'privacy_concerns' }),
    testService.execute({ userId: users.concurrent.id, deletionRequestId: concurrentRequest.id, correlationId: concurrentRequest.correlationId, deletionReason: 'privacy_concerns' }),
  ]);
  assert.equal(concurrentResults.filter((result) => result.completed).length, 1);
  assert.equal(concurrentResults.filter((result) => result.alreadyProcessing || result.alreadyCompleted).length, 1);

});

test('blocks are idempotent, forbid self-blocking, enforce both directions, Discover, and matches', async () => {
  assert.equal((await jsonRequest(`/api/blocks/${users.viewer.id}`, 'POST', users.viewer)).status, 400);
  const created = await jsonRequest(`/api/blocks/${users.target.id}`, 'POST', users.viewer);
  const duplicate = await jsonRequest(`/api/blocks/${users.target.id}`, 'POST', users.viewer);
  assert.equal(created.status, 200);
  assert.equal(created.body.data.created, true);
  assert.equal(created.body.data.unmatched, false);
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
  assert.equal(await models.Match.count({ where: {
    userOneId: Math.min(users.viewer.id, users.target.id),
    userTwoId: Math.max(users.viewer.id, users.target.id),
  } }), 1);
  assert.equal((await request('/api/matches', { headers: auth(users.viewer) })).body.data.matches.length, 0);
  assert.equal((await jsonRequest(`/api/blocks/${users.target.id}`, 'DELETE', users.viewer)).status, 200);
  assert.equal((await request(`/api/profiles/${users.target.id}`, { headers: auth(users.viewer) })).status, 200);
  assert.equal((await request('/api/matches', { headers: auth(users.viewer) })).body.data.matches.length, 1);
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

test('deletion request enters retention review without claiming completion', async () => {
  const token = tokenFor(users.deleteMe);
  const noConfirmation = await request('/api/account', {
    method: 'DELETE',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ reason: 'privacy_concerns' }),
  });
  assert.equal(noConfirmation.status, 401);
  const wrongPassword = await request('/api/account/deletion/reauthenticate', {
    method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify({ password: 'wrong-password' }),
  });
  assert.equal(wrongPassword.status, 401);
  const expiredReauthentication = await request('/api/account/deletion/reauthenticate', {
    method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify({ password: deletionPassword }),
  });
  assert.equal(expiredReauthentication.status, 200);
  const expiredConfirmation = expiredReauthentication.body.data.deletionConfirmation;
  await models.AccountDeletionConfirmation.update({ expiresAt: new Date(Date.now() - 1000) }, { where: { tokenSelector: expiredConfirmation.split('.')[0] } });
  const expiredAttempt = await request('/api/account', {
    method: 'DELETE', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify({ reason: 'privacy_concerns', deletionConfirmation: expiredConfirmation }),
  });
  assert.equal(expiredAttempt.status, 401);
  const reauthenticated = await request('/api/account/deletion/reauthenticate', {
    method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify({ password: deletionPassword }),
  });
  assert.equal(reauthenticated.status, 200, JSON.stringify(reauthenticated.body));
  const confirmation = reauthenticated.body.data.deletionConfirmation;
  assert.match(confirmation, /^[a-f0-9]{32}\.[a-f0-9]{64}$/);
  const storedConfirmation = await models.AccountDeletionConfirmation.findOne({ where: { tokenSelector: confirmation.split('.')[0] } });
  assert.equal(storedConfirmation.tokenHash.includes(confirmation), false);
  const invalidConfirmation = await request('/api/account', {
    method: 'DELETE', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify({ reason: 'privacy_concerns', deletionConfirmation: `${'a'.repeat(32)}.${'b'.repeat(64)}` }),
  });
  assert.equal(invalidConfirmation.status, 401);
  const crossAccountAttempt = await request('/api/account', {
    method: 'DELETE', headers: { ...auth(users.outsider), 'content-type': 'application/json' }, body: JSON.stringify({ reason: 'privacy_concerns', deletionConfirmation: confirmation }),
  });
  assert.equal(crossAccountAttempt.status, 401);
  const deleted = await request('/api/account', {
    method: 'DELETE',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ reason: 'privacy_concerns', deletionConfirmation: confirmation }),
  });
  assert.equal(deleted.status, 202);
  assert.equal(deleted.body.data.deletionStatus, 'BLOCKED_BY_RETENTION_DECISION');
  assert.equal(deleted.body.data.canRetry, false);
  const row = await models.User.findByPk(users.deleteMe.id);
  assert.equal(row.accountStatus, 'active');
  assert.equal(await models.AccountDeletionConfirmation.count({ where: { tokenSelector: confirmation.split('.')[0] } }), 0);
  const deletionRequest = await models.AccountDeletionRequest.findOne({ where: { userId: users.deleteMe.id }, order: [['id', 'DESC']] });
  assert.equal(deletionRequest.status, 'BLOCKED_BY_RETENTION_DECISION');
  const reused = await request('/api/account', {
    method: 'DELETE', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify({ reason: 'privacy_concerns', deletionConfirmation: confirmation }),
  });
  assert.equal(reused.status, 401);
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
