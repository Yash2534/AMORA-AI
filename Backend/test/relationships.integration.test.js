const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Relationship integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let models; let server; let baseUrl;
const users = {}; const userIds = [];
const tokenFor = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  return { status: response.status, body: await response.json() };
}

async function json(path, method, user, body) {
  return request(path, {
    method,
    headers: { ...auth(user), 'content-type': 'application/json' },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
}

async function createUser(key, values = {}) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `Relationship ${key}`,
    email: `${suffix}@relationships.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
    ...values,
  });
  userIds.push(user.id);
  users[key] = user;
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1997-05-12',
    gender: 'Woman',
    interestedIn: ['Men'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    hometown: 'Ahmedabad',
    interests: ['music'],
    lifestyle: {},
    prompts: { idealDate: 'Coffee' },
    pronouns: ['she/her'],
    valuedQualities: ['kindness'],
    loveLanguages: ['quality_time'],
    preferredTalkingHours: ['evening'],
    communicationStyle: 'calls',
    photos: ['/uploads/relationships.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await Promise.all([
    createUser('viewer'), createUser('targetA'), createUser('targetB'),
    createUser('targetC'), createUser('otherOwner'), createUser('outsider'),
    createUser('inactive', { accountStatus: 'deactivated', deactivatedAt: new Date() }),
  ]);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
    await models.SavedProfile.destroy({ where: { [Op.or]: [{ userId: userIds }, { savedUserId: userIds }] } });
    await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: userIds }, { blockedUserId: userIds }] } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('all /api/me relationship endpoints require Bearer authentication', async () => {
  assert.equal((await request('/api/me/saved-profiles')).status, 401);
  assert.equal((await request(`/api/me/saved-profiles/${users.targetA.id}`, { method: 'PUT' })).status, 401);
  assert.equal((await request(`/api/me/saved-profiles/${users.targetA.id}`, { method: 'DELETE' })).status, 401);
  assert.equal((await request('/api/me/likes')).status, 401);
  assert.equal((await request('/api/me/super-likes')).status, 401);
  assert.equal((await request('/api/me/received-likes')).status, 401);
});

test('saved profiles are owner-scoped, idempotent, paginated, and visibility-filtered', async () => {
  const first = await json(`/api/me/saved-profiles/${users.targetA.id}`, 'PUT', users.viewer);
  assert.equal(first.status, 201); assert.equal(first.body.data.saved, true); assert.equal(first.body.data.userId, String(users.targetA.id));
  const duplicate = await json(`/api/me/saved-profiles/${users.targetA.id}`, 'PUT', users.viewer);
  assert.equal(duplicate.status, 200);
  assert.equal(await models.SavedProfile.count({ where: { userId: users.viewer.id, savedUserId: users.targetA.id } }), 1);

  assert.equal((await json(`/api/me/saved-profiles/${users.viewer.id}`, 'PUT', users.viewer)).status, 400);
  assert.equal((await json(`/api/me/saved-profiles/${users.inactive.id}`, 'PUT', users.viewer)).status, 404);

  await models.Block.create({ blockerUserId: users.targetB.id, blockedUserId: users.viewer.id });
  assert.equal((await json(`/api/me/saved-profiles/${users.targetB.id}`, 'PUT', users.viewer)).status, 404);
  await models.Block.destroy({ where: { blockerUserId: users.targetB.id, blockedUserId: users.viewer.id } });

  await json(`/api/me/saved-profiles/${users.targetB.id}`, 'PUT', users.viewer);
  await json(`/api/me/saved-profiles/${users.targetC.id}`, 'PUT', users.viewer);
  const pageOne = await request('/api/me/saved-profiles?page=1&limit=2', { headers: auth(users.viewer) });
  const pageTwo = await request('/api/me/saved-profiles?page=2&limit=2', { headers: auth(users.viewer) });
  assert.equal(pageOne.status, 200); assert.equal(pageOne.body.data.profiles.length, 2); assert.equal(pageOne.body.data.pagination.hasMore, true);
  assert.equal(pageTwo.body.data.profiles.length, 1); assert.equal(pageTwo.body.data.pagination.hasMore, false);
  assert.deepEqual(new Set([...pageOne.body.data.profiles, ...pageTwo.body.data.profiles].map((profile) => profile.id)), new Set([String(users.targetA.id), String(users.targetB.id), String(users.targetC.id)]));

  await models.Block.create({ blockerUserId: users.viewer.id, blockedUserId: users.targetA.id });
  const filtered = await request('/api/me/saved-profiles?page=1&limit=20', { headers: auth(users.viewer) });
  assert.equal(filtered.body.data.profiles.some((profile) => profile.id === String(users.targetA.id)), false);
  await models.Block.destroy({ where: { blockerUserId: users.viewer.id, blockedUserId: users.targetA.id } });

  await json(`/api/me/saved-profiles/${users.outsider.id}`, 'PUT', users.otherOwner);
  const viewerUnsave = await json(`/api/me/saved-profiles/${users.outsider.id}`, 'DELETE', users.viewer);
  assert.equal(viewerUnsave.status, 200); assert.equal(viewerUnsave.body.data.saved, false);
  assert.equal(await models.SavedProfile.count({ where: { userId: users.otherOwner.id, savedUserId: users.outsider.id } }), 1);

  assert.equal((await json(`/api/me/saved-profiles/${users.targetA.id}`, 'DELETE', users.viewer)).body.data.saved, false);
  assert.equal((await json(`/api/me/saved-profiles/${users.targetA.id}`, 'DELETE', users.viewer)).body.data.saved, false);
  assert.equal(await models.SavedProfile.count({ where: { userId: users.viewer.id, savedUserId: users.targetA.id } }), 0);
});

test('sent likes persist, paginate, preserve reciprocal matching, and enforce visibility', async () => {
  await json('/api/discover/swipe', 'POST', users.otherOwner, { targetUserId: users.viewer.id, action: 'like' });
  for (const target of [users.targetA, users.targetB, users.targetC]) {
    assert.equal((await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: target.id, action: 'like' })).status, 200);
  }
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.viewer.id, action: 'like' } }), 3);
  const persistedLikes = await models.DiscoverAction.findAll({
    where: { actorUserId: users.viewer.id, targetUserId: [users.targetA.id, users.targetB.id, users.targetC.id] },
  });
  assert.ok(persistedLikes.every((row) => row.action === 'like'));
  assert.ok(persistedLikes.every((row) => row.createdAt && row.updatedAt));

  const pageOne = await request('/api/me/likes?page=1&limit=2', { headers: auth(users.viewer) });
  const pageTwo = await request('/api/me/likes?page=2&limit=2', { headers: auth(users.viewer) });
  assert.equal(pageOne.body.data.pagination.hasMore, true); assert.equal(pageTwo.body.data.pagination.hasMore, false);
  const sentIds = [...pageOne.body.data.profiles, ...pageTwo.body.data.profiles].map((profile) => profile.id);
  assert.deepEqual(new Set(sentIds), new Set([String(users.targetA.id), String(users.targetB.id), String(users.targetC.id)]));
  assert.equal(sentIds.includes(String(users.otherOwner.id)), false);

  await models.Block.create({ blockerUserId: users.targetB.id, blockedUserId: users.viewer.id });
  const blockedList = await request('/api/me/likes?page=1&limit=20', { headers: auth(users.viewer) });
  assert.equal(blockedList.body.data.profiles.some((profile) => profile.id === String(users.targetB.id)), false);
  assert.equal((await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: users.targetB.id, action: 'like' })).status, 404);
  await models.Block.destroy({ where: { blockerUserId: users.targetB.id, blockedUserId: users.viewer.id } });

  await users.targetC.update({ accountStatus: 'deactivated', deactivatedAt: new Date() });
  const inactiveList = await request('/api/me/likes?page=1&limit=20', { headers: auth(users.viewer) });
  assert.equal(inactiveList.body.data.profiles.some((profile) => profile.id === String(users.targetC.id)), false);
  await users.targetC.update({ accountStatus: 'active', deactivatedAt: null });

  await json('/api/discover/swipe', 'POST', users.targetA, { targetUserId: users.viewer.id, action: 'like' });
  const matched = await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: users.targetA.id, action: 'like' });
  assert.equal(matched.body.data.matched, true);
  const viewerMatchNotification = await models.Notification.findOne({
    where: { userId: users.viewer.id, type: 'new_match' },
  });
  const targetMatchNotification = await models.Notification.findOne({
    where: { userId: users.targetA.id, type: 'new_match' },
  });
  assert.equal(Number(viewerMatchNotification.actorUserId), users.targetA.id);
  assert.equal(Number(targetMatchNotification.actorUserId), users.viewer.id);
  await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: users.targetA.id, action: 'like' });
  const first = Math.min(users.viewer.id, users.targetA.id); const second = Math.max(users.viewer.id, users.targetA.id);
  assert.equal(await models.Match.count({ where: { userOneId: first, userTwoId: second } }), 1);
});

test('received likes are database-backed, owner-scoped, and visibility-filtered', async () => {
  const received = await request('/api/me/received-likes?page=1&limit=20', {
    headers: auth(users.viewer),
  });
  assert.equal(received.status, 200);
  assert.equal(received.body.data.total, 2);
  assert.deepEqual(
    new Set(received.body.data.profiles.map((profile) => profile.id)),
    new Set([String(users.otherOwner.id), String(users.targetA.id)]),
  );
  assert.equal(
    received.body.data.profiles.some((profile) => profile.id === String(users.targetB.id)),
    false,
  );

  await models.Block.create({ blockerUserId: users.viewer.id, blockedUserId: users.otherOwner.id });
  const filtered = await request('/api/me/received-likes?page=1&limit=20', {
    headers: auth(users.viewer),
  });
  assert.equal(filtered.body.data.total, 1);
  assert.equal(
    filtered.body.data.profiles.some((profile) => profile.id === String(users.otherOwner.id)),
    false,
  );
  await models.Block.destroy({ where: { blockerUserId: users.viewer.id, blockedUserId: users.otherOwner.id } });
});

test('Super Likes use DiscoverActions, paginate, deduplicate, and enforce visibility', async () => {
  await models.DiscoverAction.destroy({ where: { actorUserId: users.viewer.id } });
  await models.Notification.destroy({
    where: {
      actorUserId: users.viewer.id,
      type: { [Op.in]: ['new_like', 'new_super_like'] },
    },
    force: true,
  });
  await json('/api/discover/swipe', 'POST', users.otherOwner, { targetUserId: users.outsider.id, action: 'superLike' });
  for (const target of [users.targetA, users.targetB, users.targetC]) {
    assert.equal((await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: target.id, action: 'superLike' })).status, 200);
  }
  const persisted = await models.DiscoverAction.findAll({ where: { actorUserId: users.viewer.id, action: 'superLike' } });
  assert.equal(persisted.length, 3);
  assert.deepEqual(new Set(persisted.map((row) => Number(row.targetUserId))), new Set([users.targetA.id, users.targetB.id, users.targetC.id]));
  assert.ok(persisted.every((row) => row.createdAt && row.updatedAt));
  assert.equal(await models.Notification.count({
    where: {
      userId: [users.targetA.id, users.targetB.id, users.targetC.id],
      actorUserId: users.viewer.id,
      type: 'new_super_like',
    },
  }), 2);
  await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: users.targetB.id, action: 'superLike' });
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.viewer.id, targetUserId: users.targetB.id, action: 'superLike' } }), 1);
  assert.equal(await models.Notification.count({ where: { userId: users.targetB.id, actorUserId: users.viewer.id, type: 'new_super_like' } }), 1);

  const pageOne = await request('/api/me/super-likes?page=1&limit=2', { headers: auth(users.viewer) });
  const pageTwo = await request('/api/me/super-likes?page=2&limit=2', { headers: auth(users.viewer) });
  assert.equal(pageOne.body.data.profiles.length, 2); assert.equal(pageOne.body.data.pagination.hasMore, true);
  assert.equal(pageTwo.body.data.profiles.length, 1); assert.equal(pageTwo.body.data.pagination.hasMore, false);

  await models.Block.create({ blockerUserId: users.viewer.id, blockedUserId: users.targetB.id });
  const blockedList = await request('/api/me/super-likes?page=1&limit=20', { headers: auth(users.viewer) });
  assert.equal(blockedList.body.data.profiles.some((profile) => profile.id === String(users.targetB.id)), false);
  await models.Block.destroy({ where: { blockerUserId: users.viewer.id, blockedUserId: users.targetB.id } });

  await users.targetC.update({ accountStatus: 'deactivated', deactivatedAt: new Date() });
  const inactiveList = await request('/api/me/super-likes?page=1&limit=20', { headers: auth(users.viewer) });
  assert.equal(inactiveList.body.data.profiles.some((profile) => profile.id === String(users.targetC.id)), false);
  await users.targetC.update({ accountStatus: 'active', deactivatedAt: null });

  await models.OnboardingProfile.update({ onboardingCompleted: false }, { where: { userId: users.outsider.id } });
  const incomplete = await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: users.outsider.id, action: 'superLike' });
  assert.equal(incomplete.status, 404);
  assert.equal(incomplete.body.code, 'PROFILE_NOT_DISCOVERABLE');
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.viewer.id, targetUserId: users.outsider.id } }), 0);
  await models.OnboardingProfile.update({ onboardingCompleted: true }, { where: { userId: users.outsider.id } });

  await models.Block.create({ blockerUserId: users.outsider.id, blockedUserId: users.viewer.id });
  const blocked = await json('/api/discover/swipe', 'POST', users.viewer, { targetUserId: users.outsider.id, action: 'superLike' });
  assert.equal(blocked.status, 404);
  assert.equal(blocked.body.code, 'PROFILE_NOT_DISCOVERABLE');
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.viewer.id, targetUserId: users.outsider.id } }), 0);
  await models.Block.destroy({ where: { blockerUserId: users.outsider.id, blockedUserId: users.viewer.id } });
});
