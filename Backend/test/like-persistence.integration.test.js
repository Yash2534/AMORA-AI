const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Like persistence tests require an isolated TEST_DB_NAME containing "test".');
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
const tokenFor = (user) => jwt.sign(
  { sub: user.id, ver: Number(user.tokenVersion || 0) },
  process.env.JWT_SECRET,
  { expiresIn: '15m' },
);

async function request(path, { method = 'GET', user, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(user ? { authorization: `Bearer ${tokenFor(user)}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

async function createUser(key, gender, interestedIn) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `Like ${key}`,
    email: `${suffix}@like-persistence.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
    accountStatus: 'active',
  });
  userIds.push(user.id);
  users[key] = user;
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1997-05-12',
    gender,
    interestedIn: [interestedIn],
    relationshipGoals: ['Long-Term Relationship'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    bio: 'A complete profile used for deterministic relationship persistence testing.',
    interests: ['Music', 'Travel', 'Movies', 'Food', 'Fitness'],
    lifestyle: { Height: '170 cm', Languages: 'English', Religion: 'Open', Smoking: 'No' },
    prompts: { idealDate: 'Coffee and a long walk through the city.' },
    communicationStyle: 'deep_conversations',
    languages: ['English'],
    smoking: 'No',
    drinking: 'Occasionally',
    weed: 'No',
    photos: ['/uploads/like-one.webp', '/uploads/like-two.webp'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  await models.DiscoverFilterPreference.create({
    userId: user.id,
    minAge: 18,
    maxAge: 45,
    maxDistanceKm: 50,
    minScore: 0,
  });
  return user;
}

const pairWhere = () => ({
  userOneId: Math.min(users.a.id, users.b.id),
  userTwoId: Math.max(users.a.id, users.b.id),
});

async function clearPair() {
  await models.DiscoverAction.destroy({
    where: {
      [Op.or]: [
        { actorUserId: users.a.id, targetUserId: users.b.id },
        { actorUserId: users.b.id, targetUserId: users.a.id },
      ],
    },
  });
  await models.Match.destroy({ where: pairWhere() });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await createUser('a', 'Female', 'Male');
  await createUser('b', 'Male', 'Female');
  await createUser('unrelated', 'Male', 'Female');
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && userIds.length) {
    const memberships = await models.ConversationParticipant.findAll({
      where: { userId: userIds }, attributes: ['conversationId'], raw: true,
    });
    const conversationIds = [...new Set(memberships.map((row) => row.conversationId))];
    if (conversationIds.length) {
      await models.Conversation.update({ lastMessageId: null }, { where: { id: conversationIds } });
      await models.ConversationParticipant.destroy({ where: { conversationId: conversationIds } });
      await models.Conversation.destroy({ where: { id: conversationIds } });
    }
    const notifications = await models.Notification.findAll({
      where: { [Op.or]: [{ userId: userIds }, { actorUserId: userIds }] },
      attributes: ['id'],
      raw: true,
    });
    const notificationIds = notifications.map((row) => row.id);
    if (notificationIds.length) {
      await models.NotificationDelivery.destroy({ where: { notificationId: notificationIds } });
    }
    await models.Notification.destroy({
      where: { [Op.or]: [{ userId: userIds }, { actorUserId: userIds }] }, force: true,
    });
    await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
    await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: userIds }, { blockedUserId: userIds }] } });
    await models.DiscoverFilterPreference.destroy({ where: { userId: userIds } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

test('A Likes B persists directionally and repeated Like is idempotent', async () => {
  await clearPair();
  const first = await request('/api/discover/swipe', {
    method: 'POST', user: users.a, body: { targetUserId: users.b.id, action: 'like' },
  });
  const repeated = await request('/api/discover/swipe', {
    method: 'POST', user: users.a, body: { targetUserId: users.b.id, action: 'like' },
  });
  assert.equal(first.status, 200);
  assert.equal(first.body.data.liked, true);
  assert.equal(first.body.data.likeStatus, 'liked');
  assert.equal(repeated.body.data.liked, true);
  assert.equal(repeated.body.data.likeStatus, 'already_liked');
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.a.id, targetUserId: users.b.id, action: 'like' } }), 1);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.b.id, targetUserId: users.a.id } }), 0);
  assert.equal(await models.Match.count({ where: pairWhere() }), 0);
});

test('profile, Discover, AI Matches, and new authentication reads preserve Like', async () => {
  for (const path of [
    `/api/profiles/${users.b.id}`,
    '/api/discover/feed?limit=30&minScore=0',
    '/api/discover/ai-matches?limit=30&minScore=0',
    `/api/profiles/${users.b.id}`,
  ]) {
    const response = await request(path, { user: users.a });
    assert.equal(response.status, 200, path);
    assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.a.id, targetUserId: users.b.id, action: 'like' } }), 1, path);
  }
  const profile = await request(`/api/profiles/${users.b.id}`, { user: users.a });
  assert.equal(profile.body.data.profile.relationship.liked, true);
});

test('concurrent duplicate Like requests remain one Like without a Match', async () => {
  await clearPair();
  const responses = await Promise.all(Array.from({ length: 6 }, () => request('/api/discover/swipe', {
    method: 'POST', user: users.a, body: { targetUserId: users.b.id, action: 'like' },
  })));
  assert.ok(responses.every((response) => response.status === 200 && response.body.data.liked === true));
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.a.id, targetUserId: users.b.id, action: 'like' } }), 1);
  assert.equal(await models.Match.count({ where: pairWhere() }), 0);
});

test('reciprocal Like creates one Match and retains both Like rows', async () => {
  const first = await request('/api/discover/swipe', {
    method: 'POST', user: users.b, body: { targetUserId: users.a.id, action: 'like' },
  });
  const repeated = await request('/api/discover/swipe', {
    method: 'POST', user: users.b, body: { targetUserId: users.a.id, action: 'like' },
  });
  assert.equal(first.status, 200);
  assert.equal(repeated.status, 200);
  assert.equal(await models.Match.count({ where: pairWhere() }), 1);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.a.id, targetUserId: users.b.id, action: 'like' } }), 1);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.b.id, targetUserId: users.a.id, action: 'like' } }), 1);
  const profile = await request(`/api/profiles/${users.b.id}`, { user: users.a });
  assert.equal(profile.body.data.profile.relationship.liked, true);
  assert.equal(profile.body.data.profile.relationship.matched, true);
});

test('explicit Unlike is idempotent and preserves unrelated Likes', async () => {
  await models.DiscoverAction.create({ actorUserId: users.unrelated.id, targetUserId: users.b.id, action: 'like' });
  const first = await request(`/api/reactions/${users.b.id}`, { method: 'DELETE', user: users.a });
  const repeated = await request(`/api/reactions/${users.b.id}`, { method: 'DELETE', user: users.a });
  assert.equal(first.body.data.liked, false);
  assert.equal(repeated.body.data.liked, false);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.a.id, targetUserId: users.b.id } }), 0);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.unrelated.id, targetUserId: users.b.id, action: 'like' } }), 1);
});

test('blocked relationship rejects Like without changing unrelated records', async () => {
  await models.Block.create({ blockerUserId: users.b.id, blockedUserId: users.a.id });
  const response = await request('/api/discover/swipe', {
    method: 'POST', user: users.a, body: { targetUserId: users.b.id, action: 'like' },
  });
  assert.equal(response.status, 404);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.a.id, targetUserId: users.b.id } }), 0);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: users.unrelated.id, targetUserId: users.b.id, action: 'like' } }), 1);
});
