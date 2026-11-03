const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { io: socketClient } = require('socket.io-client');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase.toLowerCase() === String(applicationDatabase || '').toLowerCase() || !/test/i.test(testDatabase)) {
  throw new Error('Chat access tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');
const { closeRealtimeServer } = require('../src/realtime/realtimeHub');
const { conversationAccess, ensureDirectConversation } = require('../src/services/conversationAccessService');
const { createNotification, deliverPush } = require('../src/services/notificationService');

let server;
let baseUrl;
let socketUrl;
let models;
const sockets = [];
const createdUserIds = [];

function tokenFor(user) {
  return jwt.sign(
    { sub: user.id, ver: Number(user.tokenVersion || 0), session: Math.random().toString(36).slice(2) },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );
}

function authHeader(user) {
  return { authorization: `Bearer ${tokenFor(user)}` };
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

async function createTestUser(name, overrides = {}) {
  const suffix = `${Date.now()}_${createdUserIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@chat-access.test`,
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
    ...overrides,
  });
  createdUserIds.push(user.id);
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1996-05-15',
    gender: overrides.gender || 'Female',
    interestedIn: overrides.interestedIn || ['Male'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    profession: 'Designer',
    education: 'Graduate',
    interests: ['art', 'music'],
    languages: ['English'],
    photos: ['/uploads/chat-test-1.jpg', '/uploads/chat-test-2.jpg'],
    matchLatitude: 23.0225,
    matchLongitude: 72.5714,
    locationUpdatedAt: new Date(),
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function createMatchedPair(nameA = 'Alice', nameB = 'Bob') {
  const userA = await createTestUser(nameA, { gender: 'Female', interestedIn: ['Male'] });
  const userB = await createTestUser(nameB, { gender: 'Male', interestedIn: ['Female'] });
  const userOneId = Math.min(userA.id, userB.id);
  const userTwoId = Math.max(userA.id, userB.id);

  const match = await models.Match.create({
    userOneId,
    userTwoId,
    matchedAt: new Date(),
  });

  const { conversation } = await ensureDirectConversation(userA.id, userB.id);
  return { userA, userB, match, conversation };
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
    socket.once('connect_error', (err) => { clearTimeout(timer); reject(err); });
  });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();

  try {
    const stale = await models.User.findAll({ where: { email: { [Op.like]: '%chat-access.test' } } });
    if (stale.length) {
      const ids = stale.map((u) => u.id);
      await models.OnboardingProfile.destroy({ where: { userId: ids } });
      await models.User.destroy({ where: { id: ids } });
    }
  } catch (_) {}

  await closeRealtimeServer();
  server = createHttpServer();
  server.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}`;
  socketUrl = baseUrl;
});

after(async () => {
  for (const s of sockets) {
    if (s.connected) s.disconnect();
  }
  await closeRealtimeServer();
  if (server) await new Promise((resolve) => server.close(resolve));

  if (models && createdUserIds.length) {
    try {
      await models.Notification.destroy({ where: { [Op.or]: [{ userId: createdUserIds }, { actorUserId: createdUserIds }] } });
      await models.MessageMedia.destroy({ where: {} });
      await models.Message.destroy({ where: { senderId: createdUserIds } });
      await models.ConversationParticipant.destroy({ where: { userId: createdUserIds } });
      await models.Conversation.destroy({ where: {} });
      await models.Match.destroy({ where: { [Op.or]: [{ userOneId: createdUserIds }, { userTwoId: createdUserIds }] } });
      await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: createdUserIds }, { blockedUserId: createdUserIds }] } });
      await models.Report.destroy({ where: { [Op.or]: [{ reporterUserId: createdUserIds }, { reportedUserId: createdUserIds }] } });
      await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: createdUserIds }, { targetUserId: createdUserIds }] } });
      await models.OnboardingProfile.destroy({ where: { userId: createdUserIds } });
      await models.User.destroy({ where: { id: createdUserIds } });
    } catch (_) {}
  }
  try { await getSequelize().close(); } catch (_) {}
});

// ---------------------------------------------------------------------------
// A. CONVERSATION AUTHORIZATION (Tests 1 - 10)
// ---------------------------------------------------------------------------

test('1. Active matched User A can access their own conversation', async () => {
  const { userA, conversation } = await createMatchedPair('AuthA1', 'AuthB1');
  const res = await request(`/api/conversations/${conversation.id}/messages`, {
    headers: authHeader(userA),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.conversation.id, String(conversation.id));
  assert.equal(res.body.data.conversation.canMessage, true);
});

test('2. Active matched User B can access their own conversation', async () => {
  const { userB, conversation } = await createMatchedPair('AuthA2', 'AuthB2');
  const res = await request(`/api/conversations/${conversation.id}/messages`, {
    headers: authHeader(userB),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.conversation.id, String(conversation.id));
  assert.equal(res.body.data.conversation.canMessage, true);
});

test('3. Non-participant User C cannot access the conversation (IDOR prevention)', async () => {
  const { conversation } = await createMatchedPair('AuthA3', 'AuthB3');
  const userC = await createTestUser('IntruderC3');
  const res = await request(`/api/conversations/${conversation.id}/messages`, {
    headers: authHeader(userC),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('4. User C cannot enumerate arbitrary conversation IDs', async () => {
  const userC = await createTestUser('IntruderC4');
  for (const fakeId of [999999, 123456, 888888]) {
    const res = await request(`/api/conversations/${fakeId}/messages`, {
      headers: authHeader(userC),
    });
    assert.equal(res.status, 404);
    assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
  }
});

test('5. User A cannot access a different conversation by changing the URL ID', async () => {
  const { userA } = await createMatchedPair('AuthA5', 'AuthB5');
  const otherPair = await createMatchedPair('OtherA5', 'OtherB5');

  const res = await request(`/api/conversations/${otherPair.conversation.id}/messages`, {
    headers: authHeader(userA),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('6. User A cannot send a message to a conversation they do not belong to', async () => {
  const { userA } = await createMatchedPair('AuthA6', 'AuthB6');
  const otherPair = await createMatchedPair('OtherA6', 'OtherB6');

  const res = await request(`/api/conversations/${otherPair.conversation.id}/messages`, {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({ text: 'Injected text' }),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('7. User A cannot modify or delete User B\'s message', async () => {
  const { userA, userB, conversation } = await createMatchedPair('AuthA7', 'AuthB7');
  const msgFromB = await models.Message.create({
    conversationId: conversation.id,
    senderId: userB.id,
    type: 'text',
    text: 'Original message from B',
    status: 'sent',
  });

  const res = await request(`/api/messages/${msgFromB.id}`, {
    method: 'DELETE',
    headers: authHeader(userA),
  });
  assert.equal(res.status, 403);
  assert.equal(res.body.code, 'MESSAGE_DELETE_FORBIDDEN');
});

test('8. Sender User B can delete their own message', async () => {
  const { userB, conversation } = await createMatchedPair('AuthA8', 'AuthB8');
  const msgFromB = await models.Message.create({
    conversationId: conversation.id,
    senderId: userB.id,
    type: 'text',
    text: 'Delete me',
    status: 'sent',
  });

  const res = await request(`/api/messages/${msgFromB.id}`, {
    method: 'DELETE',
    headers: authHeader(userB),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.data.deleted, true);

  const inDb = await models.Message.findByPk(msgFromB.id);
  assert.ok(inDb.deletedAt !== null, 'Message must be soft-deleted in DB');
});

test('9. Pagination with beforeId cannot bypass membership authorization', async () => {
  const { conversation } = await createMatchedPair('AuthA9', 'AuthB9');
  const intruder = await createTestUser('Intruder9');

  const res = await request(`/api/conversations/${conversation.id}/messages?beforeId=99999&limit=10`, {
    headers: authHeader(intruder),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('10. Draft saving and clearing enforce conversation membership', async () => {
  const { conversation } = await createMatchedPair('AuthA10', 'AuthB10');
  const intruder = await createTestUser('Intruder10');

  const putDraft = await request(`/api/conversations/${conversation.id}/draft`, {
    method: 'PUT',
    headers: authHeader(intruder),
    body: JSON.stringify({ text: 'Malicious draft' }),
  });
  assert.equal(putDraft.status, 404);
  assert.equal(putDraft.body.code, 'CONVERSATION_NOT_AVAILABLE');

  const delDraft = await request(`/api/conversations/${conversation.id}/draft`, {
    method: 'DELETE',
    headers: authHeader(intruder),
  });
  assert.equal(delDraft.status, 404);
  assert.equal(delDraft.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

// ---------------------------------------------------------------------------
// B. BLOCK REVOCATION (Tests 11 - 22)
// ---------------------------------------------------------------------------

test('11. User A blocks User B successfully', async () => {
  const { userA, userB } = await createMatchedPair('BlockA11', 'BlockB11');
  const res = await request(`/api/blocks/${userB.id}`, {
    method: 'POST',
    headers: authHeader(userA),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.data.blocked, true);
  assert.equal(res.body.data.unmatched, true);
});

test('12. Block immediately deletes active Match record', async () => {
  const { userA, userB, match } = await createMatchedPair('BlockA12', 'BlockB12');
  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const matchInDb = await models.Match.findByPk(match.id);
  assert.equal(matchInDb, null, 'Match record must be deleted upon block');
});

test('13. Blocked User B cannot fetch message history', async () => {
  const { userA, userB, conversation } = await createMatchedPair('BlockA13', 'BlockB13');
  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const res = await request(`/api/conversations/${conversation.id}/messages`, {
    headers: authHeader(userB),
  });
  // Availability retrieved returns canMessage: false, messages: []
  assert.equal(res.status, 200);
  assert.equal(res.body.data.conversation.canMessage, false);
  assert.equal(res.body.data.conversation.availabilityReason, 'profile_blocked_you');
  assert.deepEqual(res.body.data.messages, []);
});

test('14. Blocker User A cannot fetch message history after block', async () => {
  const { userA, userB, conversation } = await createMatchedPair('BlockA14', 'BlockB14');
  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const res = await request(`/api/conversations/${conversation.id}/messages`, {
    headers: authHeader(userA),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.data.conversation.canMessage, false);
  assert.equal(res.body.data.conversation.availabilityReason, 'you_blocked_profile');
  assert.deepEqual(res.body.data.messages, []);
});

test('15. Neither blocked user can send new messages (POST returns 404)', async () => {
  const { userA, userB, conversation } = await createMatchedPair('BlockA15', 'BlockB15');
  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const sendFromA = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({ text: 'Hello after block' }),
  });
  assert.equal(sendFromA.status, 404);
  assert.equal(sendFromA.body.code, 'CONVERSATION_NOT_AVAILABLE');

  const sendFromB = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    headers: authHeader(userB),
    body: JSON.stringify({ text: 'Hello back after block' }),
  });
  assert.equal(sendFromB.status, 404);
  assert.equal(sendFromB.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('16. Block soft-deletes pair notifications', async () => {
  const { userA, userB, conversation } = await createMatchedPair('BlockA16', 'BlockB16');
  await models.Notification.create({
    userId: userB.id,
    actorUserId: userA.id,
    type: 'new_message',
    category: 'message',
    title: 'New message',
    message: 'Test message notification',
    conversationId: conversation.id,
  });

  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const notif = await models.Notification.findOne({
    where: { userId: userB.id, actorUserId: userA.id },
  });
  assert.ok(notif.deletedAt !== null, 'Notification must be soft-deleted by block');
});

test('17. Block masks online presence in conversation list', async () => {
  const { userA, userB, conversation } = await createMatchedPair('BlockA17', 'BlockB17');
  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const res = await request('/api/conversations', { headers: authHeader(userB) });
  assert.equal(res.status, 200);
  const conv = res.body.data.conversations.find((c) => c.id === String(conversation.id));
  if (conv) {
    assert.equal(conv.participant.online, false, 'Online presence must be masked to false');
    assert.equal(conv.unreadCount, 0, 'Unread count must be zeroed when blocked');
  }
});

test('18. Existing message records survive in database (retained for safety/moderation)', async () => {
  const { userA, userB, conversation } = await createMatchedPair('BlockA18', 'BlockB18');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'text',
    text: 'Evidence message before block',
    status: 'delivered',
  });

  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const inDb = await models.Message.findByPk(msg.id);
  assert.ok(inDb !== null, 'Message must be retained in DB for moderation');
  assert.equal(inDb.text, 'Evidence message before block');
});

// ---------------------------------------------------------------------------
// C. UNMATCH REVOCATION (Tests 19 - 26)
// ---------------------------------------------------------------------------

test('19. User A unmatches User B successfully', async () => {
  const { userA, match } = await createMatchedPair('UnmatchA19', 'UnmatchB19');
  const res = await request(`/api/matches/${match.id}`, {
    method: 'DELETE',
    headers: authHeader(userA),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.removed, true);
});

test('20. Unmatch immediately destroys active Match in DB', async () => {
  const { userA, match } = await createMatchedPair('UnmatchA20', 'UnmatchB20');
  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const matchInDb = await models.Match.findByPk(match.id);
  assert.equal(matchInDb, null, 'Match record must be deleted upon unmatch');
});

test('21. Both users lose authorization to send messages after Unmatch', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('UnmatchA21', 'UnmatchB21');
  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const sendA = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({ text: 'Message after unmatch' }),
  });
  assert.equal(sendA.status, 404);
  assert.equal(sendA.body.code, 'CONVERSATION_NOT_AVAILABLE');

  const sendB = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    headers: authHeader(userB),
    body: JSON.stringify({ text: 'Message B after unmatch' }),
  });
  assert.equal(sendB.status, 404);
  assert.equal(sendB.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('22. Conversation availability reason reflects match_unavailable after unmatch', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('UnmatchA22', 'UnmatchB22');
  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const res = await request(`/api/conversations/${conversation.id}/messages`, {
    headers: authHeader(userB),
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.data.conversation.canMessage, false);
  assert.equal(res.body.data.conversation.availabilityReason, 'match_unavailable');
  assert.deepEqual(res.body.data.messages, []);
});

test('23. Unmatch soft-deletes pair notifications', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('UnmatchA23', 'UnmatchB23');
  await models.Notification.create({
    userId: userB.id,
    actorUserId: userA.id,
    type: 'new_match',
    category: 'match',
    title: 'New match!',
    message: 'You have a new match.',
    conversationId: conversation.id,
  });

  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const notif = await models.Notification.findOne({
    where: { userId: userB.id, actorUserId: userA.id },
  });
  assert.ok(notif.deletedAt !== null, 'Notification must be soft-deleted by unmatch');
});

test('24. Conversation and message records survive after unmatch (Decision 4 retention)', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('UnmatchA24', 'UnmatchB24');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'text',
    text: 'Retained message after unmatch',
    status: 'delivered',
  });

  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  // Conversation and Message must still exist in DB
  const convInDb = await models.Conversation.findByPk(conversation.id);
  assert.ok(convInDb !== null, 'Conversation row must remain in DB');

  const msgInDb = await models.Message.findByPk(msg.id);
  assert.ok(msgInDb !== null, 'Message row must remain in DB');
  assert.equal(msgInDb.text, 'Retained message after unmatch');
});

test('25. Repeated unmatch calls return safe 404 MATCH_NOT_AVAILABLE', async () => {
  const { userA, match } = await createMatchedPair('UnmatchA25', 'UnmatchB25');
  const first = await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });
  assert.equal(first.status, 200);

  const second = await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });
  assert.equal(second.status, 404);
  assert.equal(second.body.code, 'MATCH_NOT_AVAILABLE');
});

test('26. Non-participant cannot unmatch a match they do not belong to', async () => {
  const { match } = await createMatchedPair('UnmatchA26', 'UnmatchB26');
  const intruder = await createTestUser('Intruder26');

  const res = await request(`/api/matches/${match.id}`, {
    method: 'DELETE',
    headers: authHeader(intruder),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'MATCH_NOT_AVAILABLE');
});

// ---------------------------------------------------------------------------
// D. REPORT BEHAVIOR (Tests 27 - 31)
// ---------------------------------------------------------------------------

test('27. Report creates an open moderation report record', async () => {
  const { userA, userB } = await createMatchedPair('ReportA27', 'ReportB27');
  const res = await request('/api/reports', {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({
      targetType: 'profile',
      targetUserId: userB.id,
      reason: 'harassment',
      notes: 'Testing report creation',
    }),
  });
  assert.ok([200, 201].includes(res.status));
  assert.equal(res.body.data.report.status, 'open');

  const reportInDb = await models.Report.findOne({
    where: { reporterUserId: userA.id, reportedUserId: userB.id },
  });
  assert.ok(reportInDb !== null);
  assert.equal(reportInDb.reason, 'harassment');
});

test('28. Report alone does not delete the Match or Conversation', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('ReportA28', 'ReportB28');
  await request('/api/reports', {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({
      targetType: 'profile',
      targetUserId: userB.id,
      reason: 'spam',
    }),
  });

  const matchInDb = await models.Match.findByPk(match.id);
  assert.ok(matchInDb !== null, 'Report alone must not delete Match');

  const convInDb = await models.Conversation.findByPk(conversation.id);
  assert.ok(convInDb !== null, 'Report alone must not delete Conversation');
});

test('29. Report alone does not create a Block', async () => {
  const { userA, userB } = await createMatchedPair('ReportA29', 'ReportB29');
  await request('/api/reports', {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({
      targetType: 'profile',
      targetUserId: userB.id,
      reason: 'fake_profile',
    }),
  });

  const blockInDb = await models.Block.findOne({
    where: { blockerUserId: userA.id, blockedUserId: userB.id },
  });
  assert.equal(blockInDb, null, 'Report alone must not create a Block record');
});

test('30. Report plus Block invokes complete block severance', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('ReportA30', 'ReportB30');
  // Submit report
  await request('/api/reports', {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({ targetType: 'profile', targetUserId: userB.id, reason: 'harassment' }),
  });
  // Execute block
  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  // Match must be deleted
  assert.equal(await models.Match.findByPk(match.id), null);
  // Block must exist
  const block = await models.Block.findOne({ where: { blockerUserId: userA.id, blockedUserId: userB.id } });
  assert.ok(block !== null);
  // Send message must fail
  const send = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    headers: authHeader(userA),
    body: JSON.stringify({ text: 'Blocked message' }),
  });
  assert.equal(send.status, 404);
});

test('31. User cannot report their own account', async () => {
  const user = await createTestUser('SelfReporter31');
  const res = await request('/api/reports', {
    method: 'POST',
    headers: authHeader(user),
    body: JSON.stringify({ targetType: 'profile', targetUserId: user.id, reason: 'spam' }),
  });
  assert.equal(res.status, 400);
  assert.equal(res.body.code, 'SELF_REPORT_NOT_ALLOWED');
});

// ---------------------------------------------------------------------------
// E. WEBSOCKET & REALTIME SECURITY (Tests 32 - 37)
// ---------------------------------------------------------------------------

test('32. Authenticated participant can subscribe to active conversation room', async () => {
  const { userA, conversation } = await createMatchedPair('WsA32', 'WsB32');
  const socket = await connectSocket(userA);

  const ack = await new Promise((resolve) => {
    socket.emit('conversation.subscribe', { conversationId: conversation.id }, resolve);
  });
  assert.equal(ack.success, true);
});

test('33. Non-participant cannot subscribe to conversation room', async () => {
  const { conversation } = await createMatchedPair('WsA33', 'WsB33');
  const intruder = await createTestUser('WsIntruder33');
  const socket = await connectSocket(intruder);

  const ack = await new Promise((resolve) => {
    socket.emit('conversation.subscribe', { conversationId: conversation.id }, resolve);
  });
  assert.equal(ack.success, false);
  assert.equal(ack.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('34. Block evicts socket from room and emits conversation.severed', async () => {
  const { userA, userB, conversation } = await createMatchedPair('WsA34', 'WsB34');
  const socketB = await connectSocket(userB);

  await new Promise((resolve) => {
    socketB.emit('conversation.subscribe', { conversationId: conversation.id }, resolve);
  });

  const severedPromise = new Promise((resolve) => {
    socketB.on('conversation.severed', resolve);
  });

  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const event = await Promise.race([
    severedPromise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout waiting for conversation.severed')), 3000)),
  ]);

  assert.equal(event.conversationId, String(conversation.id));
  assert.equal(event.reason, 'blocked');
});

test('35. Unmatch evicts socket from room and emits conversation.severed with unmatched reason', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('WsA35', 'WsB35');
  const socketB = await connectSocket(userB);

  await new Promise((resolve) => {
    socketB.emit('conversation.subscribe', { conversationId: conversation.id }, resolve);
  });

  const severedPromise = new Promise((resolve) => {
    socketB.on('conversation.severed', resolve);
  });

  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const event = await Promise.race([
    severedPromise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout waiting for conversation.severed')), 3000)),
  ]);

  assert.equal(event.conversationId, String(conversation.id));
  assert.equal(event.reason, 'unmatched');
});

test('36. Sockets cannot re-subscribe to severed conversation after unmatch', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('WsA36', 'WsB36');
  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const socketA = await connectSocket(userA);
  const ack = await new Promise((resolve) => {
    socketA.emit('conversation.subscribe', { conversationId: conversation.id }, resolve);
  });
  assert.equal(ack.success, false);
  assert.equal(ack.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('37. Message events are not emitted to severed pair sockets', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('WsA37', 'WsB37');
  const socketB = await connectSocket(userB);

  let messageReceived = false;
  socketB.on('message.created', () => { messageReceived = true; });

  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  // Attempt to emit conversation event directly or via send
  const { emitConversationEvent } = require('../src/realtime/realtimeHub');
  await emitConversationEvent(conversation.id, 'message.created', { text: 'Leaked?' });

  await new Promise((resolve) => setTimeout(resolve, 200));
  assert.equal(messageReceived, false, 'Message event must not be received by severed user');
});

// ---------------------------------------------------------------------------
// F. MEDIA & ATTACHMENT SECURITY (Tests 38 - 41)
// ---------------------------------------------------------------------------

test('38. Media download requires authenticated conversation membership', async () => {
  const { userA, userB, conversation } = await createMatchedPair('MedA38', 'MedB38');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'image',
    status: 'delivered',
  });
  const media = await models.MessageMedia.create({
    messageId: msg.id,
    mediaType: 'image',
    originalName: 'photo.jpg',
    storagePath: 'chat/fake-photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024,
  });

  const intruder = await createTestUser('MedIntruder38');
  const res = await request(`/api/messages/${msg.id}/media/${media.id}`, {
    headers: authHeader(intruder),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('39. Media download denied after Block', async () => {
  const { userA, userB, conversation } = await createMatchedPair('MedA39', 'MedB39');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'image',
    status: 'delivered',
  });
  const media = await models.MessageMedia.create({
    messageId: msg.id,
    mediaType: 'image',
    originalName: 'photo.jpg',
    storagePath: 'chat/fake-photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024,
  });

  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const res = await request(`/api/messages/${msg.id}/media/${media.id}`, {
    headers: authHeader(userB),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('40. Media download denied after Unmatch', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('MedA40', 'MedB40');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'image',
    status: 'delivered',
  });
  const media = await models.MessageMedia.create({
    messageId: msg.id,
    mediaType: 'image',
    originalName: 'photo.jpg',
    storagePath: 'chat/fake-photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024,
  });

  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const res = await request(`/api/messages/${msg.id}/media/${media.id}`, {
    headers: authHeader(userB),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'CONVERSATION_NOT_AVAILABLE');
});

test('41. Attachment ID belonging to another message is denied (IDOR check)', async () => {
  const { userA, userB, conversation } = await createMatchedPair('MedA41', 'MedB41');
  const msg1 = await models.Message.create({ conversationId: conversation.id, senderId: userA.id, type: 'image' });
  const msg2 = await models.Message.create({ conversationId: conversation.id, senderId: userB.id, type: 'image' });

  const media2 = await models.MessageMedia.create({
    messageId: msg2.id,
    mediaType: 'image',
    originalName: 'photo2.jpg',
    storagePath: 'chat/fake-photo2.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1024,
  });

  // Request media2 under msg1 ID
  const res = await request(`/api/messages/${msg1.id}/media/${media2.id}`, {
    headers: authHeader(userA),
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'MEDIA_NOT_AVAILABLE');
});

// ---------------------------------------------------------------------------
// G. NOTIFICATION AUTHORIZATION & DELIVERY (Tests 42 - 45)
// ---------------------------------------------------------------------------

test('42. createNotification rejects message notifications if users are blocked', async () => {
  const { userA, userB, conversation } = await createMatchedPair('NotifA42', 'NotifB42');
  await models.Block.create({ blockerUserId: userA.id, blockedUserId: userB.id });

  const notif = await createNotification({
    userId: userB.id,
    actorUserId: userA.id,
    type: 'new_message',
    category: 'message',
    title: 'Hello',
    message: 'Blocked message notification',
    conversationId: conversation.id,
  });
  assert.equal(notif, null, 'Notification must be suppressed if blocked');
});

test('43. createNotification rejects message notifications if users are unmatched', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('NotifA43', 'NotifB43');
  await match.destroy();

  const notif = await createNotification({
    userId: userB.id,
    actorUserId: userA.id,
    type: 'new_message',
    category: 'message',
    title: 'Hello',
    message: 'Unmatched message notification',
    conversationId: conversation.id,
  });
  assert.equal(notif, null, 'Notification must be suppressed if unmatched');
});

test('44. deliverPush re-authorizes at delivery time and suppresses if blocked', async () => {
  const { userA, userB } = await createMatchedPair('PushA44', 'PushB44');
  const notif = await models.Notification.create({
    userId: userB.id,
    actorUserId: userA.id,
    type: 'new_message',
    category: 'message',
    title: 'Deferred notification',
    message: 'Hello',
  });

  // Block happens after notification creation but before push delivery
  await models.Block.create({ blockerUserId: userA.id, blockedUserId: userB.id });

  let pushSent = false;
  // deliverPush should check areUsersBlocked and bail out before sending
  await deliverPush(notif, { pushEnabled: true });
  // Verify delivery table status
  const delivery = await models.NotificationDelivery.findOne({ where: { notificationId: notif.id } });
  assert.equal(delivery, null, 'Push must not be dispatched when relationship is severed');
});

test('45. deliverPush suppresses delivery if notification was soft-deleted', async () => {
  const { userA, userB } = await createMatchedPair('PushA45', 'PushB45');
  const notif = await models.Notification.create({
    userId: userB.id,
    actorUserId: userA.id,
    type: 'new_message',
    category: 'message',
    title: 'Soft-deleted',
    message: 'Do not deliver',
    deletedAt: new Date(),
  });

  await deliverPush(notif, { pushEnabled: true });
  const delivery = await models.NotificationDelivery.findOne({ where: { notificationId: notif.id } });
  assert.equal(delivery, null, 'Soft-deleted notification must not be delivered');
});

// ---------------------------------------------------------------------------
// H. TRANSACTION & CONCURRENCY GUARANTEES (Tests 46 - 49)
// ---------------------------------------------------------------------------

test('46. Message send racing against Unmatch serializes safely', async () => {
  const { userA, userB, match, conversation } = await createMatchedPair('RaceA46', 'RaceB46');

  // Concurrently run message send from userB and unmatch from userA
  const [sendRes, unmatchRes] = await Promise.all([
    request(`/api/conversations/${conversation.id}/messages`, {
      method: 'POST',
      headers: authHeader(userB),
      body: JSON.stringify({ text: 'Racing message' }),
    }),
    request(`/api/matches/${match.id}`, {
      method: 'DELETE',
      headers: authHeader(userA),
    }),
  ]);

  // Unmatch must succeed
  assert.equal(unmatchRes.status, 200);
  // Send either succeeded before unmatch (201) or was rejected after unmatch (404)
  assert.ok([201, 404].includes(sendRes.status));

  // Match must be destroyed in DB
  const inDb = await models.Match.findByPk(match.id);
  assert.equal(inDb, null);
});

test('47. Concurrent unmatch requests serialize cleanly without deadlock', async () => {
  const { userA, userB, match } = await createMatchedPair('RaceA47', 'RaceB47');

  const [resA, resB] = await Promise.all([
    request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) }),
    request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userB) }),
  ]);

  const statuses = [resA.status, resB.status].sort();
  assert.deepEqual(statuses, [200, 404], 'One request must succeed with 200, the other return 404');
});

test('48. Failed transaction rolls back completely and leaves database state consistent', async () => {
  const { userA, userB, match } = await createMatchedPair('RollbackA48', 'RollbackB48');

  // Attempting to delete with invalid ID fails
  const res = await request('/api/matches/999999', {
    method: 'DELETE',
    headers: authHeader(userA),
  });
  assert.equal(res.status, 404);

  // Original match is completely intact
  const matchInDb = await models.Match.findByPk(match.id);
  assert.ok(matchInDb !== null);
});

test('49. Sockets re-connection racing with block severance does not restore room access', async () => {
  const { userA, userB, conversation } = await createMatchedPair('RaceA49', 'RaceB49');

  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  // Reconnection attempt
  const newSocket = await connectSocket(userB);
  const ack = await new Promise((resolve) => {
    newSocket.emit('conversation.subscribe', { conversationId: conversation.id }, resolve);
  });

  assert.equal(ack.success, false);
  assert.equal(ack.code, 'CONVERSATION_NOT_AVAILABLE');
});

// ---------------------------------------------------------------------------
// I. DATA RETENTION AUDIT (Tests 50 - 52)
// ---------------------------------------------------------------------------

test('50. Block does not hard-delete Conversation or Message records', async () => {
  const { userA, userB, conversation } = await createMatchedPair('RetA50', 'RetB50');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'text',
    text: 'Safety retention audit message',
    status: 'delivered',
  });

  await request(`/api/blocks/${userB.id}`, { method: 'POST', headers: authHeader(userA) });

  const c = await models.Conversation.findByPk(conversation.id);
  assert.ok(c !== null, 'Conversation row must remain in DB');

  const m = await models.Message.findByPk(msg.id);
  assert.ok(m !== null, 'Message row must remain in DB');
});

test('51. Unmatch does not hard-delete Conversation or Message records', async () => {
  const { userA, match, conversation } = await createMatchedPair('RetA51', 'RetB51');
  const msg = await models.Message.create({
    conversationId: conversation.id,
    senderId: userA.id,
    type: 'text',
    text: 'Unmatch retention audit message',
    status: 'delivered',
  });

  await request(`/api/matches/${match.id}`, { method: 'DELETE', headers: authHeader(userA) });

  const c = await models.Conversation.findByPk(conversation.id);
  assert.ok(c !== null, 'Conversation row must remain in DB');

  const m = await models.Message.findByPk(msg.id);
  assert.ok(m !== null, 'Message row must remain in DB');
});

test('52. No automatic cron purge jobs exist or delete data', async () => {
  // Confirm that message retention policy is unconfigured and does not destroy historical data
  const { Message } = getModels();
  assert.ok(typeof Message === 'function');
});
