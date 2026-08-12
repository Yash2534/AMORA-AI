require('../src/config/bootstrapEnv');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { io: socketClient } = require('socket.io-client');
const { Op } = require('sequelize');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');
const { closeRealtimeServer } = require('../src/realtime/realtimeHub');

if (!process.argv.includes('--confirm-development-db') || process.env.NODE_ENV === 'production') {
  throw new Error('Pass --confirm-development-db and run only against the development schema.');
}

let server;
let socket;
let models;
const userIds = [];

function tokenFor(user) {
  return jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
}

async function createUser(name) {
  const suffix = `${Date.now()}_${Math.random().toString(36).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@chat-history-verification.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
  });
  userIds.push(user.id);
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1997-04-03',
    gender: 'Female',
    interestedIn: ['Male'],
    relationshipGoals: ['Meaningful Dating'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    photos: ['/uploads/chat-verification.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function match(first, second) {
  return models.Match.create({
    userOneId: Math.min(first.id, second.id),
    userTwoId: Math.max(first.id, second.id),
    matchedAt: new Date(),
  });
}

async function api(baseUrl, path, { method = 'GET', user, body } = {}) {
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

function nextSocketEvent(target, event) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${event}.`)), 5000);
    target.once(event, (value) => {
      clearTimeout(timer);
      resolve(value);
    });
  });
}

async function connectReceiver(baseUrl, user) {
  const token = jwt.sign(
    { sub: user.id, ver: Number(user.tokenVersion || 0) },
    process.env.JWT_SECRET,
    { expiresIn: '15m' },
  );
  const target = socketClient(baseUrl, {
    auth: { token },
    transports: ['websocket'],
    forceNew: true,
    reconnection: false,
  });
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Realtime connection timed out.')), 5000);
    target.once('connect', () => {
      clearTimeout(timer);
      resolve();
    });
    target.once('connect_error', reject);
  });
  return target;
}

async function cleanup() {
  if (!models || !userIds.length) return;
  const memberships = await models.ConversationParticipant.findAll({ where: { userId: userIds }, attributes: ['conversationId'] });
  const conversationIds = [...new Set(memberships.map((row) => Number(row.conversationId)))];
  if (conversationIds.length) {
    const messages = await models.Message.findAll({ where: { conversationId: conversationIds }, attributes: ['id'] });
    await models.MessageMedia.destroy({ where: { messageId: messages.map((row) => row.id) } });
    await models.ConversationParticipant.update({ lastReadMessageId: null }, { where: { conversationId: conversationIds } });
    await models.Conversation.update({ lastMessageId: null }, { where: { id: conversationIds } });
    await models.Message.destroy({ where: { conversationId: conversationIds }, force: true });
    await models.ConversationParticipant.destroy({ where: { conversationId: conversationIds } });
    await models.Conversation.destroy({ where: { id: conversationIds } });
  }
  await models.Notification.destroy({ where: { [Op.or]: [{ userId: userIds }, { actorUserId: userIds }] }, force: true });
  await models.NotificationPreference.destroy({ where: { userId: userIds } });
  await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
  await models.OnboardingProfile.destroy({ where: { userId: userIds } });
  await models.RefreshToken.destroy({ where: { userId: userIds } });
  await models.User.destroy({ where: { id: userIds } });
}

async function main() {
  await initializeDatabase();
  models = getModels();
  const priya = await createUser('Priya');
  const rahul = await createUser('Rahul');
  const userC = await createUser('User C');
  await Promise.all([match(priya, rahul), match(priya, userC)]);

  server = createHttpServer();
  server.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  const created = await api(baseUrl, '/api/conversations', {
    method: 'POST', user: priya, body: { targetUserId: rahul.id },
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const conversationId = created.body.data.conversation.id;
  const reverse = await api(baseUrl, '/api/conversations', {
    method: 'POST', user: rahul, body: { targetUserId: priya.id },
  });
  assert.equal(reverse.status, 200);
  assert.equal(reverse.body.data.conversation.id, conversationId);

  socket = await connectReceiver(baseUrl, rahul);
  const expected = [
    [priya, 'Hello Rahul'],
    [rahul, 'Hi Priya'],
    [priya, 'How are you?'],
    [rahul, "I'm good"],
  ];
  const firstRealtime = nextSocketEvent(socket, 'message.created');
  const sentIds = [];
  for (const [sender, text] of expected) {
    const sent = await api(baseUrl, `/api/conversations/${conversationId}/messages`, {
      method: 'POST', user: sender, body: { text },
    });
    assert.equal(sent.status, 201, JSON.stringify(sent.body));
    sentIds.push(sent.body.data.message.id);
  }
  const realtime = await firstRealtime;
  assert.equal(realtime.message.id, sentIds[0]);
  assert.equal(realtime.message.senderId, String(priya.id));

  const priyaHistory = await api(baseUrl, `/api/conversations/${conversationId}/messages?limit=100`, { user: priya });
  const rahulHistory = await api(baseUrl, `/api/conversations/${conversationId}/messages?limit=100`, { user: rahul });
  const canonical = priyaHistory.body.data.messages.map((message) => [message.id, message.senderId, message.text]);
  assert.deepEqual(rahulHistory.body.data.messages.map((message) => [message.id, message.senderId, message.text]), canonical);
  assert.deepEqual(canonical.map((item) => item[2]), expected.map((item) => item[1]));
  assert.deepEqual(
    priyaHistory.body.data.messages.map((message) => message.mine),
    [true, false, true, false],
  );
  assert.deepEqual(
    rahulHistory.body.data.messages.map((message) => message.mine),
    [false, true, false, true],
  );

  const persisted = await models.Message.findAll({ where: { conversationId }, order: [['id', 'ASC']] });
  assert.deepEqual(persisted.map((message) => [String(message.id), String(message.senderId), message.text]), canonical);
  const participants = await models.ConversationParticipant.findAll({ where: { conversationId }, order: [['userId', 'ASC']] });
  assert.deepEqual(participants.map((row) => Number(row.userId)), [priya.id, rahul.id].sort((a, b) => a - b));

  assert.equal((await api(baseUrl, `/api/conversations/${conversationId}/messages`, { user: userC })).status, 404);
  assert.equal((await api(baseUrl, `/api/conversations/${conversationId}/messages`, { method: 'POST', user: userC, body: { text: 'intrusion' } })).status, 404);
  assert.equal((await api(baseUrl, `/api/conversations/${conversationId}/read`, { method: 'PUT', user: userC, body: {} })).status, 404);

  const secondConversation = await api(baseUrl, '/api/conversations', {
    method: 'POST', user: priya, body: { targetUserId: userC.id },
  });
  const secondConversationId = secondConversation.body.data.conversation.id;
  assert.notEqual(secondConversationId, conversationId);
  assert.equal((await api(baseUrl, `/api/conversations/${secondConversationId}/messages`, {
    method: 'POST', user: priya, body: { text: 'Private C thread' },
  })).status, 201);
  const refreshedRahul = await api(baseUrl, `/api/conversations/${conversationId}/messages?limit=100`, { user: rahul });
  assert.equal(refreshedRahul.body.data.messages.length, 4);
  assert.equal(refreshedRahul.body.data.messages.some((message) => message.text === 'Private C thread'), false);

  console.log(JSON.stringify({
    database: process.env.DB_NAME,
    conversationId,
    reverseDirectionConversationId: reverse.body.data.conversation.id,
    participantUserIds: participants.map((row) => Number(row.userId)),
    messages: canonical,
    priyaMine: priyaHistory.body.data.messages.map((message) => message.mine),
    rahulMine: rahulHistory.body.data.messages.map((message) => message.mine),
    realtimeMessageId: realtime.message.id,
    thirdUserDenied: true,
    crossConversationIsolation: true,
  }, null, 2));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (socket) socket.disconnect();
    await closeRealtimeServer().catch(() => {});
    if (server?.listening) await new Promise((resolve) => server.close(resolve));
    await cleanup().catch((error) => {
      console.error('[Cleanup]', error.message);
      process.exitCode = 1;
    });
    try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
  });
