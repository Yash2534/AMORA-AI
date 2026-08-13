const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { io: socketClient } = require('socket.io-client');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Mutual-like chat tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { pairKeyFor } = require('../src/services/conversationAccessService');
const { createHttpServer } = require('../src/server');
const { closeRealtimeServer } = require('../src/realtime/realtimeHub');

let models; let server; let baseUrl;
const sockets = [];
const users = {}; const userIds = [];
const tokenFor = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0), session: Math.random().toString(36).slice(2) }, process.env.JWT_SECRET, { expiresIn: '15m' });
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

async function createUser(key) {
  const suffix = `${Date.now()}_${key}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `Mutual ${key.toUpperCase()}`,
    email: `${suffix}@mutual-like-chat.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
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
    photos: ['/uploads/mutual-chat.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
}

async function like(actor, target) {
  return json('/api/discover/swipe', 'POST', actor, { targetUserId: target.id, action: 'like' });
}

async function connectSocket(user) {
  const socket = socketClient(baseUrl, {
    auth: { token: tokenFor(user) },
    transports: ['websocket'],
    forceNew: true,
    reconnection: false,
  });
  sockets.push(socket);
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Socket connection timed out.')), 5000);
    socket.once('connect', () => { clearTimeout(timer); resolve(socket); });
    socket.once('connect_error', (error) => { clearTimeout(timer); reject(error); });
  });
}

function nextEvent(socket, name) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${name}.`)), 5000);
    socket.once(name, (value) => { clearTimeout(timer); resolve(value); });
  });
}

async function restartServer() {
  for (const socket of sockets.splice(0)) socket.disconnect();
  await closeRealtimeServer();
  if (server?.listening) await new Promise((resolve) => server.close(resolve));
  server = createHttpServer();
  server.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await Promise.all(['a', 'b', 'c', 'd'].map(createUser));
  server = createHttpServer();
  server.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  for (const socket of sockets) socket.disconnect();
  await closeRealtimeServer();
  if (server?.listening) await new Promise((resolve) => server.close(resolve));
  if (models) {
    const memberships = await models.ConversationParticipant.findAll({ where: { userId: userIds }, attributes: ['conversationId'] });
    const conversationIds = [...new Set(memberships.map((item) => item.conversationId))];
    if (conversationIds.length) {
      await models.Message.destroy({ where: { conversationId: conversationIds } });
      await models.ConversationParticipant.destroy({ where: { conversationId: conversationIds } });
      await models.Conversation.destroy({ where: { id: conversationIds } });
    }
    await models.Notification.destroy({ where: { [Op.or]: [{ userId: userIds }, { actorUserId: userIds }] }, force: true });
    await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
    await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('mutual likes atomically create one canonical match and conversation', async () => {
  const firstLike = await like(users.a, users.b);
  assert.equal(firstLike.status, 200);
  assert.equal(firstLike.body.data.matched, false);
  assert.equal(await models.Match.count({ where: { userOneId: Math.min(users.a.id, users.b.id), userTwoId: Math.max(users.a.id, users.b.id) } }), 0);
  assert.equal(await models.Conversation.count({ where: { pairKey: pairKeyFor(users.a.id, users.b.id) } }), 0);

  const aSocket = await connectSocket(users.a);
  const bSocket = await connectSocket(users.b);
  const aConversationAvailable = nextEvent(aSocket, 'conversation.updated');
  const bConversationAvailable = nextEvent(bSocket, 'conversation.updated');
  const reciprocal = await like(users.b, users.a);
  assert.equal(reciprocal.status, 200, JSON.stringify(reciprocal.body));
  assert.equal(reciprocal.body.data.matched, true);
  const match = await models.Match.findOne({ where: { userOneId: Math.min(users.a.id, users.b.id), userTwoId: Math.max(users.a.id, users.b.id) } });
  const conversation = await models.Conversation.findOne({ where: { pairKey: pairKeyFor(users.a.id, users.b.id) } });
  assert.equal(reciprocal.body.data.matchId, String(match.id));
  assert.equal(reciprocal.body.data.conversationId, String(conversation.id));
  assert.ok(match.matchedAt instanceof Date);
  assert.equal(conversation.type, 'direct');
  assert.equal((await aConversationAvailable).conversationId, String(conversation.id));
  assert.equal((await bConversationAvailable).conversationId, String(conversation.id));
  assert.deepEqual(
    (await models.ConversationParticipant.findAll({ where: { conversationId: conversation.id }, order: [['userId', 'ASC']] })).map((item) => Number(item.userId)),
    [users.a.id, users.b.id].sort((a, b) => a - b),
  );

  const retry = await like(users.b, users.a);
  assert.equal(retry.body.data.matchId, String(match.id));
  assert.equal(retry.body.data.conversationId, String(conversation.id));
  assert.equal(await models.Match.count({ where: { userOneId: match.userOneId, userTwoId: match.userTwoId } }), 1);
  assert.equal(await models.Conversation.count({ where: { pairKey: conversation.pairKey } }), 1);
  assert.equal(await models.ConversationParticipant.count({ where: { conversationId: conversation.id } }), 2);
});

test('an existing valid pair conversation is reused for a second mutual match', async () => {
  await like(users.c, users.d);
  const pairKey = pairKeyFor(users.c.id, users.d.id);
  const existing = await models.Conversation.create({ pairKey, type: 'direct' });
  await models.ConversationParticipant.bulkCreate([
    { conversationId: existing.id, userId: users.c.id, joinedAt: new Date() },
    { conversationId: existing.id, userId: users.d.id, joinedAt: new Date() },
  ]);

  const reciprocal = await like(users.d, users.c);
  assert.equal(reciprocal.status, 200);
  assert.equal(reciprocal.body.data.conversationId, String(existing.id));
  assert.equal(await models.Conversation.count({ where: { pairKey } }), 1);
  assert.equal(await models.Match.count({ where: { userOneId: Math.min(users.c.id, users.d.id), userTwoId: Math.max(users.c.id, users.d.id) } }), 1);
});

test('chat lists, refreshed sessions, and messages remain participant-isolated', async () => {
  await restartServer();
  const ab = await models.Conversation.findOne({ where: { pairKey: pairKeyFor(users.a.id, users.b.id) } });
  const cd = await models.Conversation.findOne({ where: { pairKey: pairKeyFor(users.c.id, users.d.id) } });
  for (const [user, includedId, excludedId] of [
    [users.a, ab.id, cd.id], [users.b, ab.id, cd.id],
    [users.c, cd.id, ab.id], [users.d, cd.id, ab.id],
  ]) {
    const list = await request('/api/conversations?page=1&limit=20', { headers: auth(user) });
    assert.equal(list.status, 200);
    const ids = list.body.data.conversations.map((item) => Number(item.id));
    assert.equal(ids.includes(includedId), true);
    assert.equal(ids.includes(excludedId), false);
  }

  const refreshedA = await request('/api/conversations?page=1&limit=20', { headers: auth(users.a) });
  const refreshedB = await request('/api/conversations?page=1&limit=20', { headers: auth(users.b) });
  assert.equal(refreshedA.body.data.conversations.some((item) => Number(item.id) === ab.id), true);
  assert.equal(refreshedB.body.data.conversations.some((item) => Number(item.id) === ab.id), true);

  const sent = await json(`/api/conversations/${ab.id}/messages`, 'POST', users.a, { text: 'Private A to B message' });
  assert.equal(sent.status, 201);
  const historyB = await request(`/api/conversations/${ab.id}/messages?limit=30`, { headers: auth(users.b) });
  assert.equal(historyB.body.data.messages.some((item) => item.text === 'Private A to B message' && Number(item.senderId) === users.a.id), true);
  assert.equal((await request(`/api/conversations/${ab.id}/messages?limit=30`, { headers: auth(users.c) })).status, 404);
  assert.equal((await request(`/api/conversations/${cd.id}/messages?limit=30`, { headers: auth(users.a) })).status, 404);
  assert.equal((await json(`/api/conversations/${ab.id}/messages`, 'POST', users.d, { text: 'Unauthorized' })).status, 404);
  assert.equal(await models.Message.count({ where: { conversationId: ab.id, senderId: users.d.id } }), 0);
  assert.equal(await models.Message.count({ where: { conversationId: cd.id } }), 0);
});
