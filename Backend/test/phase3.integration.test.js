const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { io: socketClient } = require('socket.io-client');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Phase 3 integration tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');
const { closeRealtimeServer } = require('../src/realtime/realtimeHub');

let models;
let server;
let baseUrl;
const users = {};
const userIds = [];
const sockets = [];
const mediaFiles = [];
let primaryConversationId;

const tokenFor = (user) => jwt.sign({ sub: user.id, ver: user.tokenVersion || 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });

async function createUser(key, accountStatus = 'active') {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `P3 ${key}`,
    email: `${suffix}@phase3.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
    accountStatus,
    deactivatedAt: accountStatus === 'deactivated' ? new Date() : null,
    deletedAt: accountStatus === 'deleted' ? new Date() : null,
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
    photos: ['/uploads/phase3-profile.jpg'],
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

async function request(url, options = {}) {
  const response = await fetch(`${baseUrl}${url}`, options);
  const type = response.headers.get('content-type') || '';
  return { status: response.status, body: type.includes('application/json') ? await response.json() : await response.arrayBuffer() };
}

async function jsonRequest(url, method, user, body) {
  return request(url, {
    method,
    headers: { ...auth(user), ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function createConversation(user, target) {
  return jsonRequest('/api/conversations', 'POST', user, { targetUserId: target.id });
}

async function realtimeToken(user) {
  return tokenFor(user);
}

async function connectSocket(token, expectSuccess = true) {
  const socket = socketClient(baseUrl, { auth: { token }, transports: ['websocket'], forceNew: true, reconnection: false });
  sockets.push(socket);
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Socket connection timed out.')), 5000);
    socket.once('connect', () => {
      clearTimeout(timeout);
      if (!expectSuccess) reject(new Error('Invalid realtime token connected.')); else resolve(socket);
    });
    socket.once('connect_error', (error) => {
      clearTimeout(timeout);
      if (expectSuccess) reject(error); else resolve(error);
    });
  });
}

function nextEvent(socket, name, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${name}.`)), timeoutMs);
    socket.once(name, (value) => { clearTimeout(timer); resolve(value); });
  });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await Promise.all([
    createUser('alice'),
    createUser('bob'),
    createUser('carol'),
    createUser('blocked'),
    createUser('outsider'),
    createUser('deactivated', 'deactivated'),
    createUser('deleted', 'deleted'),
  ]);
  await Promise.all([
    match(users.alice, users.bob),
    match(users.alice, users.carol),
    match(users.alice, users.blocked),
    match(users.alice, users.deactivated),
    match(users.alice, users.deleted),
  ]);
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
    const media = await models.MessageMedia.findAll({
      include: [{ model: models.Message, as: 'message', include: [{ model: models.Conversation, as: 'conversation', include: [{ model: models.ConversationParticipant, as: 'participants', where: { userId: userIds } }] }] }],
    });
    mediaFiles.push(...media.map((row) => path.join(__dirname, '..', 'private-uploads', row.storagePath)));
    const conversations = await models.ConversationParticipant.findAll({ where: { userId: userIds }, attributes: ['conversationId'] });
    const conversationIds = [...new Set(conversations.map((row) => row.conversationId))];
    const messages = await models.Message.findAll({ where: { conversationId: conversationIds }, attributes: ['id'] });
    await models.MessageMedia.destroy({ where: { messageId: messages.map((row) => row.id) } });
    await models.ConversationParticipant.update({ lastReadMessageId: null }, { where: { conversationId: conversationIds } });
    await models.Conversation.update({ lastMessageId: null }, { where: { id: conversationIds } });
    await models.Message.destroy({ where: { conversationId: conversationIds }, force: true });
    await models.ConversationParticipant.destroy({ where: { conversationId: conversationIds } });
    await models.Conversation.destroy({ where: { id: conversationIds } });
    await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: userIds }, { blockedUserId: userIds }] } });
    await models.Report.destroy({ where: { [Op.or]: [{ reporterUserId: userIds }, { reportedUserId: userIds }] } });
    await models.Match.destroy({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.RefreshToken.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  await Promise.all(mediaFiles.map((file) => fs.rm(file, { force: true })));
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

test('conversation creation authenticates, enforces eligibility, and is idempotent', async () => {
  assert.equal((await request('/api/conversations')).status, 401);
  const created = await createConversation(users.alice, users.bob);
  assert.equal(created.status, 201, JSON.stringify(created.body));
  primaryConversationId = created.body.data.conversation.id;
  const repeated = await createConversation(users.alice, users.bob);
  assert.equal(repeated.status, 200);
  assert.equal(repeated.body.data.conversation.id, primaryConversationId);
  const reverseDirection = await createConversation(users.bob, users.alice);
  assert.equal(reverseDirection.status, 200);
  assert.equal(reverseDirection.body.data.conversation.id, primaryConversationId);
  assert.equal(await models.Conversation.count({ where: { pairKey: `${Math.min(users.alice.id, users.bob.id)}:${Math.max(users.alice.id, users.bob.id)}` } }), 1);
  assert.equal((await createConversation(users.alice, users.alice)).status, 400);
  assert.equal((await createConversation(users.alice, users.outsider)).status, 403);
  assert.equal((await createConversation(users.alice, users.deactivated)).status, 404);
  assert.equal((await createConversation(users.alice, users.deleted)).status, 404);
  assert.equal((await jsonRequest('/api/conversations', 'POST', users.alice, { targetUserId: 2147483000 })).status, 404);
});

test('block and unblock restore an existing chat without recreating it', async () => {
  const conversationCount = await models.Conversation.count({ where: { id: primaryConversationId } });
  const blocked = await jsonRequest(`/api/blocks/${users.bob.id}`, 'POST', users.alice);
  assert.equal(blocked.status, 200, JSON.stringify(blocked.body));
  const unavailableList = await request('/api/conversations?limit=20', { headers: auth(users.alice) });
  const unavailable = unavailableList.body.data.conversations.find((row) => row.id === primaryConversationId);
  assert.equal(unavailable.canMessage, false);
  assert.equal(unavailable.availabilityReason, 'you_blocked_profile');

  await models.Match.destroy({ where: {
    userOneId: Math.min(users.alice.id, users.bob.id),
    userTwoId: Math.max(users.alice.id, users.bob.id),
  } });
  const unblocked = await jsonRequest(`/api/blocks/${users.bob.id}`, 'DELETE', users.alice);
  assert.equal(unblocked.status, 200, JSON.stringify(unblocked.body));
  assert.equal(unblocked.body.data.restoredMatch, true);
  assert.equal(await models.Conversation.count({ where: { id: primaryConversationId } }), conversationCount);
  assert.equal(await models.Match.count({ where: {
    userOneId: Math.min(users.alice.id, users.bob.id),
    userTwoId: Math.max(users.alice.id, users.bob.id),
  } }), 1);
  const restoredList = await request('/api/conversations?limit=20', { headers: auth(users.alice) });
  const restored = restoredList.body.data.conversations.find((row) => row.id === primaryConversationId);
  assert.equal(restored.canMessage, true);
  assert.equal(restored.availabilityReason, null);
});

test('conversation list is database-filtered, newest-first, paginated, and reports real unread state', async () => {
  const carol = await createConversation(users.alice, users.carol);
  const blocked = await createConversation(users.alice, users.blocked);
  assert.equal(carol.status, 201);
  assert.equal(blocked.status, 201);
  await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.bob, { text: 'Unread from Bob' });
  await jsonRequest(`/api/conversations/${carol.body.data.conversation.id}/messages`, 'POST', users.carol, { text: 'Newest from Carol' });
  await models.Block.create({ blockerUserId: users.blocked.id, blockedUserId: users.alice.id });
  const first = await request('/api/conversations?page=1&limit=1', { headers: auth(users.alice) });
  const second = await request('/api/conversations?page=2&limit=1', { headers: auth(users.alice) });
  assert.equal(first.status, 200, JSON.stringify(first.body));
  assert.equal(first.body.data.pagination.hasMore, true);
  assert.notEqual(first.body.data.conversations[0].id, second.body.data.conversations[0].id);
  const all = await request('/api/conversations?limit=20', { headers: auth(users.alice) });
  const blockedConversation = all.body.data.conversations.find((row) => row.participant.id === String(users.blocked.id));
  assert.equal(blockedConversation.canMessage, false);
  assert.equal(blockedConversation.availabilityReason, 'profile_blocked_you');
  const bobConversation = all.body.data.conversations.find((row) => row.id === primaryConversationId);
  assert.equal(bobConversation.unreadCount, 1);
  assert.equal(bobConversation.lastMessage.text, 'Unread from Bob');
  assert.equal(Object.hasOwn(bobConversation.participant, 'email'), false);
  await users.carol.update({ accountStatus: 'deactivated', deactivatedAt: new Date() });
  const inactiveList = await request('/api/conversations?limit=20', { headers: auth(users.alice) });
  const inactiveConversation = inactiveList.body.data.conversations.find((row) => row.participant.id === String(users.carol.id));
  assert.equal(inactiveConversation.canMessage, false);
  assert.equal(inactiveConversation.availabilityReason, 'account_unavailable');
  await users.carol.update({ accountStatus: 'active', deactivatedAt: null });
});

test('message history enforces membership and uses stable chronological cursor pages', async () => {
  await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'Second message' });
  await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.bob, { text: 'Third message' });
  const page = await request(`/api/conversations/${primaryConversationId}/messages?limit=2`, { headers: auth(users.alice) });
  assert.equal(page.status, 200);
  assert.equal(page.body.data.messages.length, 2);
  assert.equal(page.body.data.pagination.hasMore, true);
  assert.ok(Number(page.body.data.messages[0].id) < Number(page.body.data.messages[1].id));
  const older = await request(`/api/conversations/${primaryConversationId}/messages?limit=2&beforeId=${page.body.data.pagination.nextCursor}`, { headers: auth(users.alice) });
  assert.equal(older.status, 200);
  assert.equal(older.body.data.messages.some((item) => page.body.data.messages.some((current) => current.id === item.id)), false);
  assert.equal((await request(`/api/conversations/${primaryConversationId}/messages`, { headers: auth(users.outsider) })).status, 404);

  const aliceHistory = await request(`/api/conversations/${primaryConversationId}/messages?limit=100`, { headers: auth(users.alice) });
  const bobHistory = await request(`/api/conversations/${primaryConversationId}/messages?limit=100`, { headers: auth(users.bob) });
  assert.equal(aliceHistory.status, 200);
  assert.equal(bobHistory.status, 200);
  assert.deepEqual(
    aliceHistory.body.data.messages.map((message) => [message.id, message.senderId, message.text]),
    bobHistory.body.data.messages.map((message) => [message.id, message.senderId, message.text]),
  );
  assert.ok(aliceHistory.body.data.messages.some((message) => message.senderId === String(users.alice.id) && message.mine === true));
  assert.ok(aliceHistory.body.data.messages.some((message) => message.senderId === String(users.bob.id) && message.mine === false));
  assert.ok(bobHistory.body.data.messages.some((message) => message.senderId === String(users.alice.id) && message.mine === false));
  assert.ok(bobHistory.body.data.messages.some((message) => message.senderId === String(users.bob.id) && message.mine === true));
  const persistedRows = await models.Message.findAll({ where: { conversationId: primaryConversationId }, order: [['id', 'ASC']] });
  assert.deepEqual(
    persistedRows.map((message) => [String(message.id), String(message.senderId), message.text]),
    aliceHistory.body.data.messages.map((message) => [message.id, message.senderId, message.text]),
  );
});

test('two authenticated realtime clients receive only persisted authorized message/read events', async () => {
  assert.ok(await connectSocket('invalid-token', false));
  const aliceSocket = await connectSocket(await realtimeToken(users.alice));
  const bobSocket = await connectSocket(await realtimeToken(users.bob));
  const outsiderSocket = await connectSocket(await realtimeToken(users.outsider));
  let outsiderReceived = false;
  outsiderSocket.on('message.created', () => { outsiderReceived = true; });
  const onlineList = await request('/api/conversations', { headers: auth(users.alice) });
  assert.equal(onlineList.body.data.conversations.find((row) => row.id === primaryConversationId).participant.online, true);
  const bobMessageEvent = nextEvent(bobSocket, 'message.created');
  const sent = await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'Realtime persisted message' });
  assert.equal(sent.status, 201);
  assert.equal(sent.body.data.message.status, 'delivered');
  const event = await bobMessageEvent;
  assert.equal(event.message.id, sent.body.data.message.id);
  const deliveredMessage = await models.Message.findByPk(event.message.id);
  assert.equal(deliveredMessage.status, 'delivered');
  assert.ok(deliveredMessage.deliveredAt);
  await new Promise((resolve) => setTimeout(resolve, 100));
  assert.equal(outsiderReceived, false);
  const aliceReadEvent = nextEvent(aliceSocket, 'message.read');
  const read = await jsonRequest(`/api/conversations/${primaryConversationId}/read`, 'PUT', users.bob, { messageId: event.message.id });
  assert.equal(read.status, 200);
  assert.equal((await aliceReadEvent).userId, String(users.bob.id));
  const membership = await models.ConversationParticipant.findOne({ where: { conversationId: primaryConversationId, userId: users.bob.id } });
  assert.equal(String(membership.lastReadMessageId), event.message.id);
  const readMessage = await models.Message.findByPk(event.message.id);
  assert.equal(readMessage.status, 'read');
  assert.ok(readMessage.readAt);
  const refreshedHistory = await request(`/api/conversations/${primaryConversationId}/messages?limit=30`, { headers: auth(users.alice) });
  assert.equal(refreshedHistory.body.data.messages.find((item) => item.id === event.message.id).status, 'read');
  const list = await request('/api/conversations', { headers: auth(users.bob) });
  assert.equal(list.body.data.conversations.find((row) => row.id === primaryConversationId).unreadCount, 0);
  const aliceReplyEvent = nextEvent(aliceSocket, 'message.created');
  const reply = await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.bob, { text: 'Reply from Bob' });
  assert.equal(reply.status, 201);
  assert.equal((await aliceReplyEvent).message.id, reply.body.data.message.id);
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/read`, 'PUT', users.outsider, {})).status, 404);
});

test('text validation, inactive accounts, and bidirectional blocks prevent messaging and realtime delivery', async () => {
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: '   ' })).status, 400);
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'x'.repeat(4001) })).status, 400);
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.outsider, { text: 'forbidden' })).status, 404);
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.deactivated, { text: 'inactive' })).status, 403);
  const bobSocket = sockets.find((socket) => socket.connected && socket.auth?.token);
  let leaked = false;
  const listener = () => { leaked = true; };
  bobSocket.on('message.created', listener);
  await models.Block.create({ blockerUserId: users.bob.id, blockedUserId: users.alice.id });
  const unavailableList = await request('/api/conversations?limit=20', { headers: auth(users.alice) });
  const unavailableConversation = unavailableList.body.data.conversations.find((row) => row.id === primaryConversationId);
  assert.equal(unavailableConversation.canMessage, false);
  assert.equal(unavailableConversation.availabilityReason, 'profile_blocked_you');
  const unavailableHistory = await request(`/api/conversations/${primaryConversationId}/messages`, { headers: auth(users.alice) });
  assert.equal(unavailableHistory.status, 200);
  assert.equal(unavailableHistory.body.data.conversation.availabilityReason, 'profile_blocked_you');
  const denied = await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'blocked' });
  assert.equal(denied.status, 404);
  await new Promise((resolve) => setTimeout(resolve, 150));
  bobSocket.off('message.created', listener);
  assert.equal(leaked, false);
  const blockerHistory = await request(`/api/conversations/${primaryConversationId}/messages`, { headers: auth(users.bob) });
  assert.equal(blockerHistory.status, 200);
  assert.equal(blockerHistory.body.data.conversation.availabilityReason, 'you_blocked_profile');
  await models.Block.destroy({ where: { blockerUserId: users.bob.id, blockedUserId: users.alice.id } });
  const restoredList = await request('/api/conversations?limit=20', { headers: auth(users.alice) });
  const restoredConversation = restoredList.body.data.conversations.find((row) => row.id === primaryConversationId);
  assert.equal(restoredConversation.canMessage, true);
  assert.equal(restoredConversation.availabilityReason, null);
});

test('chat-origin reports bind the authenticated reporter to the other participant', async () => {
  const valid = await jsonRequest('/api/reports', 'POST', users.alice, {
    targetType: 'profile',
    targetUserId: users.bob.id,
    conversationId: Number(primaryConversationId),
    reason: 'spam',
  });
  assert.equal(valid.status, 201, JSON.stringify(valid.body));
  const invalid = await jsonRequest('/api/reports', 'POST', users.alice, {
    targetType: 'profile',
    targetUserId: users.carol.id,
    conversationId: Number(primaryConversationId),
    reason: 'spam',
  });
  assert.equal(invalid.status, 403);
  assert.equal(invalid.body.code, 'REPORT_TARGET_MISMATCH');
  const reverse = await jsonRequest('/api/reports', 'POST', users.bob, {
    targetType: 'profile',
    targetUserId: users.alice.id,
    conversationId: Number(primaryConversationId),
    reason: 'other',
  });
  assert.equal(reverse.status, 201, JSON.stringify(reverse.body));
});

test('image media is signature-validated, private, persisted, and accessible only to participants', async () => {
  const png = Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]);
  const data = new FormData();
  data.append('media', new Blob([png], { type: 'image/png' }), 'unsafe original.png');
  data.append('caption', 'A safe image');
  const uploaded = await request(`/api/conversations/${primaryConversationId}/media`, { method: 'POST', headers: auth(users.alice), body: data });
  assert.equal(uploaded.status, 201, JSON.stringify(uploaded.body));
  const media = uploaded.body.data.message.media[0];
  const row = await models.MessageMedia.findByPk(media.id);
  assert.equal(row.mimeType, 'image/png');
  assert.equal(row.storagePath.includes('unsafe original.png'), false);
  assert.equal((await request(media.url, { headers: auth(users.bob) })).status, 200);
  assert.equal((await request(media.url, { headers: auth(users.outsider) })).status, 404);
  const invalid = new FormData();
  invalid.append('media', new Blob([Uint8Array.from([1, 2, 3])], { type: 'application/x-msdownload' }), 'payload.exe');
  assert.equal((await request(`/api/conversations/${primaryConversationId}/media`, { method: 'POST', headers: auth(users.alice), body: invalid })).status, 400);
  const oversized = new FormData();
  oversized.append('media', new Blob([new Uint8Array(10 * 1024 * 1024 + 1)], { type: 'image/png' }), 'huge.png');
  const tooLarge = await request(`/api/conversations/${primaryConversationId}/media`, { method: 'POST', headers: auth(users.alice), body: oversized });
  assert.equal(tooLarge.status, 400);
  assert.equal(tooLarge.body.code, 'MEDIA_TOO_LARGE');
});

test('message deletion is sender-only, soft, idempotent, and draft persistence is server-backed', async () => {
  const sent = await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'Delete me' });
  const messageId = sent.body.data.message.id;
  assert.equal((await jsonRequest(`/api/messages/${messageId}`, 'DELETE', users.bob)).status, 403);
  const removed = await jsonRequest(`/api/messages/${messageId}`, 'DELETE', users.alice);
  assert.equal(removed.status, 200);
  assert.ok((await models.Message.findByPk(messageId)).deletedAt);
  assert.equal((await jsonRequest(`/api/messages/${messageId}`, 'DELETE', users.alice)).status, 200);
  const saved = await jsonRequest(`/api/conversations/${primaryConversationId}/draft`, 'PUT', users.alice, { text: 'Persist this draft' });
  assert.equal(saved.status, 200);
  const history = await request(`/api/conversations/${primaryConversationId}/messages?limit=1`, { headers: auth(users.alice) });
  assert.equal(history.body.data.conversation.draft, 'Persist this draft');
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/draft`, 'DELETE', users.alice)).status, 200);
});

test('conversation mute persists per participant and suppresses message notification delivery', async () => {
  await models.NotificationPreference.upsert({ userId: users.bob.id, messages: true, pushEnabled: true });
  const registered = await jsonRequest('/api/devices', 'POST', users.bob, {
    pushToken: `phase3-device-token-${users.bob.id}-1234567890`,
    platform: 'android',
    installationId: 'phase3-bob-device',
  });
  assert.ok([200, 201].includes(registered.status));

  const muted = await jsonRequest(`/api/conversations/${primaryConversationId}/mute`, 'PUT', users.bob, {});
  assert.equal(muted.status, 200);
  const list = await request('/api/conversations', { headers: auth(users.bob) });
  assert.equal(list.body.data.conversations.find((row) => row.id === primaryConversationId).muted, true);
  const before = await models.Notification.count({ where: { userId: users.bob.id, type: 'new_message' } });
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'Muted notification check' })).status, 201);
  assert.equal(await models.Notification.count({ where: { userId: users.bob.id, type: 'new_message' } }), before);

  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/mute`, 'DELETE', users.bob, {})).status, 200);
  const sent = await jsonRequest(`/api/conversations/${primaryConversationId}/messages`, 'POST', users.alice, { text: 'Unmuted notification check' });
  assert.equal(sent.status, 201);
  const notification = await models.Notification.findOne({ where: { userId: users.bob.id, dedupeKey: `message:${sent.body.data.message.id}` } });
  assert.ok(notification);
  assert.equal(Number(notification.actorUserId), users.alice.id);
  const inbox = await request('/api/notifications', { headers: auth(users.bob) });
  const messageNotification = inbox.body.data.notifications.find((item) => item.id === String(notification.id));
  assert.equal(messageNotification.actor.userId, String(users.alice.id));
  assert.ok(messageNotification.actor.photoUrl);
  const delivery = await models.NotificationDelivery.findOne({ where: { notificationId: notification.id } });
  assert.equal(delivery.status, 'credentials_required');
  assert.equal((await jsonRequest(`/api/conversations/${primaryConversationId}/mute`, 'PUT', users.outsider, {})).status, 404);
});
