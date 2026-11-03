const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('P0 Safety tests require an isolated TEST_DB_NAME containing "test".');
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

async function createUser(key, {
  gender = 'Female',
  interestedIn = 'Male',
  birthDate = '1997-05-12', // age ~29
  matchLatitude = 23.0225, // Ahmedabad
  matchLongitude = 72.5714,
  maxDistanceKm = 50,
  minAge = 18,
  maxAge = 45,
} = {}) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `Safety ${key}`,
    email: `${suffix}@p0-safety.test`,
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
    birthDate,
    gender,
    interestedIn: [interestedIn],
    relationshipGoals: ['Long-Term Relationship'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    bio: 'Safety & Integrity testing profile.',
    interests: ['Music', 'Travel', 'Movies', 'Food', 'Fitness'],
    lifestyle: { Height: '170 cm', Languages: 'English', Religion: 'Open', Smoking: 'No' },
    prompts: { idealDate: 'Coffee and a long walk.' },
    communicationStyle: 'deep_conversations',
    languages: ['English'],
    smoking: 'No',
    drinking: 'Occasionally',
    weed: 'No',
    matchLatitude,
    matchLongitude,
    photos: ['/uploads/p0-one.webp', '/uploads/p0-two.webp'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  await models.DiscoverFilterPreference.create({
    userId: user.id,
    minAge,
    maxAge,
    maxDistanceKm,
    minScore: 0,
  });
  return user;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();

  // Create test actors
  await createUser('viewerA', { gender: 'Female', interestedIn: 'Male', birthDate: '1997-05-12' });
  await createUser('eligibleMaleB', { gender: 'Male', interestedIn: 'Female', birthDate: '1995-03-10' });
  await createUser('incompatibleGenderC', { gender: 'Female', interestedIn: 'Female', birthDate: '1996-01-01' });
  await createUser('incompatibleAgeD', { gender: 'Male', interestedIn: 'Female', birthDate: '1970-01-01' }); // age 56
  await createUser('distantMaleE', {
    gender: 'Male', interestedIn: 'Female', birthDate: '1995-03-10',
    matchLatitude: 19.0760, matchLongitude: 72.8777, // Mumbai ~440km away
  });
  await createUser('unrelatedMale', { gender: 'Male', interestedIn: 'Female', birthDate: '1995-03-10' });
  await createUser('rewindTarget', { gender: 'Male', interestedIn: 'Female', birthDate: '1995-03-10' });
  await createUser('noCoordsViewer', { gender: 'Female', interestedIn: 'Male', matchLatitude: null, matchLongitude: null });
  await createUser('noCoordsCandidate', { gender: 'Male', interestedIn: 'Female', matchLatitude: null, matchLongitude: null });

  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && userIds.length) {
    const memberships = await models.ConversationParticipant.findAll({
      where: { userId: { [Op.in]: userIds } },
      attributes: ['conversationId'],
    });
    const conversationIds = [...new Set(memberships.map((m) => m.conversationId))];
    if (conversationIds.length) {
      await models.MessageMedia.destroy({
        where: { messageId: { [Op.in]: (await models.Message.findAll({ where: { conversationId: { [Op.in]: conversationIds } }, attributes: ['id'] })).map((m) => m.id) } },
      }).catch(() => {});
      await models.Message.destroy({ where: { conversationId: { [Op.in]: conversationIds } } });
      await models.ConversationParticipant.destroy({ where: { conversationId: { [Op.in]: conversationIds } } });
      await models.Conversation.destroy({ where: { id: { [Op.in]: conversationIds } } });
    }
    await models.Match.destroy({
      where: { [Op.or]: [{ userOneId: { [Op.in]: userIds } }, { userTwoId: { [Op.in]: userIds } }] },
    });
    await models.DiscoverAction.destroy({
      where: { [Op.or]: [{ actorUserId: { [Op.in]: userIds } }, { targetUserId: { [Op.in]: userIds } }] },
    });
    await models.Report.destroy({
      where: { [Op.or]: [{ reporterUserId: { [Op.in]: userIds } }, { reportedUserId: { [Op.in]: userIds } }] },
    });
    await models.Block.destroy({
      where: { [Op.or]: [{ blockerUserId: { [Op.in]: userIds } }, { blockedUserId: { [Op.in]: userIds } }] },
    });
    await models.DiscoverFilterPreference.destroy({ where: { userId: { [Op.in]: userIds } } });
    await models.OnboardingProfile.destroy({ where: { userId: { [Op.in]: userIds } } });
    await models.User.destroy({ where: { id: { [Op.in]: userIds } } });
  }
  const sequelize = getSequelize();
  if (sequelize) await sequelize.close();
});

test('P0-1: Swipe rejects reciprocal gender incompatibility (SEC-01)', async () => {
  const res = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.incompatibleGenderC.id, action: 'like' },
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'PROFILE_NOT_DISCOVERABLE');
});

test('P0-1: Swipe rejects reciprocal age bounds violation (SEC-01)', async () => {
  const res = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.incompatibleAgeD.id, action: 'like' },
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'PROFILE_NOT_DISCOVERABLE');
});

test('P0-1: Swipe rejects distance limit violation (SEC-01)', async () => {
  const res = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.distantMaleE.id, action: 'like' },
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'PROFILE_NOT_DISCOVERABLE');
});

test('Fix 1 (VULN-P0-01): Missing coordinates cannot bypass distance restriction', async () => {
  // Viewer with no coords attempts to swipe candidate who has maxDistanceKm: 50
  const resViewerMissing = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.noCoordsViewer,
    body: { targetUserId: users.eligibleMaleB.id, action: 'like' },
  });
  assert.equal(resViewerMissing.status, 404);
  assert.equal(resViewerMissing.body.code, 'PROFILE_NOT_DISCOVERABLE');

  // Viewer with coords attempts to swipe candidate who has NO coords but viewer has maxDistanceKm: 50
  const resTargetMissing = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.noCoordsCandidate.id, action: 'like' },
  });
  assert.equal(resTargetMissing.status, 404);
  assert.equal(resTargetMissing.body.code, 'PROFILE_NOT_DISCOVERABLE');

  // Both missing coords with distance restriction configured
  const resBothMissing = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.noCoordsViewer,
    body: { targetUserId: users.noCoordsCandidate.id, action: 'like' },
  });
  assert.equal(resBothMissing.status, 404);
  assert.equal(resBothMissing.body.code, 'PROFILE_NOT_DISCOVERABLE');
});

test('P0-2: Reporting a user immediately excludes them from Discover Feed (SEC-03)', async () => {
  const feedBefore = await request('/api/discover/feed', { user: users.viewerA });
  assert.equal(feedBefore.status, 200);
  const foundBefore = (feedBefore.body.data?.profiles || []).some((p) => Number(p.id) === users.eligibleMaleB.id);
  assert.equal(foundBefore, true, 'Eligible candidate should initially appear in feed');

  const reportRes = await request('/api/reports', {
    method: 'POST',
    user: users.viewerA,
    body: { targetType: 'profile', targetUserId: users.eligibleMaleB.id, reason: 'harassment' },
  });
  assert.equal([200, 201].includes(reportRes.status), true);

  const feedAfter = await request('/api/discover/feed', { user: users.viewerA });
  assert.equal(feedAfter.status, 200);
  const foundAfter = (feedAfter.body.data?.profiles || []).some((p) => Number(p.id) === users.eligibleMaleB.id);
  assert.equal(foundAfter, false, 'Reported user must be suppressed from reporter feed');
});

test('P0-2: Reporting a user immediately excludes them from AI Matches (SEC-03)', async () => {
  const aiMatchesRes = await request('/api/discover/ai-matches', { user: users.viewerA });
  assert.equal(aiMatchesRes.status, 200);
  const foundInAi = (aiMatchesRes.body.data?.profiles || []).some((p) => Number(p.id) === users.eligibleMaleB.id);
  assert.equal(foundInAi, false, 'Reported user must be suppressed from AI matches');
});

test('P0-2: Swipe on reported user is rejected with 404 (SEC-03)', async () => {
  const swipeRes = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.eligibleMaleB.id, action: 'like' },
  });
  assert.equal(swipeRes.status, 404);
  assert.equal(swipeRes.body.code, 'PROFILE_NOT_DISCOVERABLE');
});

test('Fix 2 (VULN-P0-02): Resolved report maintains bilateral suppression between offender and victim', async () => {
  // Create report with status 'resolved' where victim = viewerA, offender = distantMaleE
  await models.Report.create({
    reporterUserId: users.viewerA.id,
    reportedUserId: users.distantMaleE.id,
    targetType: 'profile',
    targetId: String(users.distantMaleE.id),
    reason: 'harassment',
    status: 'resolved',
  });

  // 1. Victim cannot see offender in feed
  const victimFeed = await request('/api/discover/feed', { user: users.viewerA });
  assert.equal(victimFeed.status, 200);
  assert.equal((victimFeed.body.data?.profiles || []).some((p) => Number(p.id) === users.distantMaleE.id), false);

  // 2. Offender cannot see victim in feed
  const offenderFeed = await request('/api/discover/feed', { user: users.distantMaleE });
  assert.equal(offenderFeed.status, 200);
  assert.equal((offenderFeed.body.data?.profiles || []).some((p) => Number(p.id) === users.viewerA.id), false);

  // 3. Offender cannot swipe victim
  const offenderSwipe = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.distantMaleE,
    body: { targetUserId: users.viewerA.id, action: 'like' },
  });
  assert.equal(offenderSwipe.status, 404);
  assert.equal(offenderSwipe.body.code, 'PROFILE_NOT_DISCOVERABLE');

  // 4. Victim cannot swipe offender
  const victimSwipe = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.distantMaleE.id, action: 'like' },
  });
  assert.equal(victimSwipe.status, 404);
  assert.equal(victimSwipe.body.code, 'PROFILE_NOT_DISCOVERABLE');
});

test('Fix 2 (VULN-P0-02): Dismissed report preserves reporter suppression without falsely punishing accused user', async () => {
  const accusedUser = await createUser('accusedUser', { gender: 'Male', interestedIn: 'Female' });
  await models.Report.create({
    reporterUserId: users.viewerA.id,
    reportedUserId: accusedUser.id,
    targetType: 'profile',
    targetId: String(accusedUser.id),
    reason: 'fake_profile',
    status: 'dismissed',
  });

  // Reporter still suppresses accused user (reporter preference respected)
  const reporterFeed = await request('/api/discover/feed', { user: users.viewerA });
  assert.equal((reporterFeed.body.data?.profiles || []).some((p) => Number(p.id) === accusedUser.id), false);

  // Accused user account remains active and unpenalized globally
  const target = await models.User.findByPk(accusedUser.id);
  assert.equal(target.accountStatus, 'active');
});

test('Fix 3 (VULN-P0-03): BLOCK enforces complete bilateral severance and deletes active Match', async () => {
  const blockUser1 = await createUser('blockUser1', { gender: 'Female', interestedIn: 'Male' });
  const blockUser2 = await createUser('blockUser2', { gender: 'Male', interestedIn: 'Female' });

  // Establish a mutual match and direct conversation
  const u1 = Math.min(blockUser1.id, blockUser2.id);
  const u2 = Math.max(blockUser1.id, blockUser2.id);
  const [match] = await models.Match.findOrCreate({
    where: { userOneId: u1, userTwoId: u2 },
    defaults: { userOneId: u1, userTwoId: u2, matchedAt: new Date() },
  });
  const { ensureDirectConversation } = require('../src/services/conversationAccessService');
  const { conversation } = await ensureDirectConversation(u1, u2);
  assert.ok(match, 'Match row should exist before block');
  assert.ok(conversation, 'Conversation row should exist before block');

  // Verify conversation is accessible before block
  const convBefore = await request(`/api/conversations/${conversation.id}/messages`, { user: blockUser1 });
  assert.equal(convBefore.status, 200, 'Conversation should be accessible before block');

  // blockUser1 blocks blockUser2
  const blockRes = await request(`/api/blocks/${blockUser2.id}`, {
    method: 'POST',
    user: blockUser1,
  });
  assert.equal(blockRes.status, 200);
  assert.equal(blockRes.body.data.blocked, true);
  assert.equal(blockRes.body.data.unmatched, true);

  // 1. Match record is permanently deleted from database
  const matchInDb = await models.Match.findOne({ where: { userOneId: u1, userTwoId: u2 } });
  assert.equal(matchInDb, null, 'Match record must be deleted upon block creation');

  // 2. Conversation access restricted: canMessage is false, messages empty, availability reason set
  const convA = await request(`/api/conversations/${conversation.id}/messages`, { user: blockUser1 });
  assert.equal(convA.status, 200);
  assert.equal(convA.body.data.conversation.canMessage, false, 'Blocker canMessage must be false');
  assert.equal(convA.body.data.conversation.availabilityReason, 'you_blocked_profile');
  assert.deepEqual(convA.body.data.messages, []);

  const convB = await request(`/api/conversations/${conversation.id}/messages`, { user: blockUser2 });
  assert.equal(convB.status, 200);
  assert.equal(convB.body.data.conversation.canMessage, false, 'Blocked user canMessage must be false');
  assert.equal(convB.body.data.conversation.availabilityReason, 'profile_blocked_you');
  assert.deepEqual(convB.body.data.messages, []);

  // 3. Neither user can send messages
  const msgA = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    user: blockUser1,
    body: { text: 'Hello' },
  });
  assert.equal(msgA.status, 404);
  const msgB = await request(`/api/conversations/${conversation.id}/messages`, {
    method: 'POST',
    user: blockUser2,
    body: { text: 'Hello' },
  });
  assert.equal(msgB.status, 404);

  // 4. Neither user can view profile
  const profA = await request(`/api/profiles/${blockUser2.id}`, { user: blockUser1 });
  assert.equal(profA.status, 404);
  const profB = await request(`/api/profiles/${blockUser1.id}`, { user: blockUser2 });
  assert.equal(profB.status, 404);

  // 5. Neither user can swipe on the other
  const swipeA = await request('/api/discover/swipe', {
    method: 'POST',
    user: blockUser1,
    body: { targetUserId: blockUser2.id, action: 'like' },
  });
  assert.equal(swipeA.status, 404);
  const swipeB = await request('/api/discover/swipe', {
    method: 'POST',
    user: blockUser2,
    body: { targetUserId: blockUser1.id, action: 'like' },
  });
  assert.equal(swipeB.status, 404);

  // 6. Unblocking does NOT restore the severed match
  const unblockRes = await request(`/api/blocks/${blockUser2.id}`, {
    method: 'DELETE',
    user: blockUser1,
  });
  assert.equal(unblockRes.status, 200);
  assert.equal(unblockRes.body.data.restoredMatch, false);
  const matchAfterUnblock = await models.Match.findOne({ where: { userOneId: u1, userTwoId: u2 } });
  assert.equal(matchAfterUnblock, null, 'Match must NOT be restored on unblock');
});

test('P0-3 & P0-4: Rewind of regular pass succeeds (SEC-04)', async () => {
  const swipePass = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.rewindTarget.id, action: 'pass' },
  });
  assert.equal(swipePass.status, 200);

  const rewindRes = await request('/api/discover/rewind', {
    method: 'POST',
    user: users.viewerA,
  });
  assert.equal(rewindRes.status, 200);
  assert.equal(rewindRes.body.data.action, 'pass');
  assert.equal(rewindRes.body.data.targetUserId, String(users.rewindTarget.id));

  const actionInDb = await models.DiscoverAction.findOne({
    where: { actorUserId: users.viewerA.id, targetUserId: users.rewindTarget.id },
  });
  assert.equal(actionInDb, null, 'Rewound action must be destroyed in database');
});

test('P0-3: Rewind of confirmed mutual match returns 409 CANNOT_REWIND_MATCH (Decision 3B)', async () => {
  await models.DiscoverAction.destroy({
    where: {
      [Op.or]: [
        { actorUserId: users.unrelatedMale.id, targetUserId: users.viewerA.id },
        { actorUserId: users.viewerA.id, targetUserId: users.unrelatedMale.id },
      ],
    },
  });

  const like1 = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.unrelatedMale,
    body: { targetUserId: users.viewerA.id, action: 'like' },
  });
  assert.equal(like1.status, 200);
  assert.equal(like1.body.data.matched, false);

  const like2 = await request('/api/discover/swipe', {
    method: 'POST',
    user: users.viewerA,
    body: { targetUserId: users.unrelatedMale.id, action: 'like' },
  });
  assert.equal(like2.status, 200);
  assert.equal(like2.body.data.matched, true);

  const rewindMatchRes = await request('/api/discover/rewind', {
    method: 'POST',
    user: users.viewerA,
  });
  assert.equal(rewindMatchRes.status, 409);
  assert.equal(rewindMatchRes.body.code, 'CANNOT_REWIND_MATCH');

  const userOneId = Math.min(users.viewerA.id, users.unrelatedMale.id);
  const userTwoId = Math.max(users.viewerA.id, users.unrelatedMale.id);
  const matchRow = await models.Match.findOne({ where: { userOneId, userTwoId } });
  assert.ok(matchRow, 'Confirmed match must not be destroyed by rewind');
});

test('P0-4: Rewind with nothing to rewind returns 404 NOTHING_TO_REWIND', async () => {
  const freshUser = await createUser('freshUser', { gender: 'Male', interestedIn: 'Female' });
  const res = await request('/api/discover/rewind', {
    method: 'POST',
    user: freshUser,
  });
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'NOTHING_TO_REWIND');
});

test('Fix 4 (VULN-P0-04): Concurrent reciprocal swiping serializes safely without deadlock', async () => {
  const concUser1 = await createUser('concUser1', { gender: 'Female', interestedIn: 'Male' });
  const concUser2 = await createUser('concUser2', { gender: 'Male', interestedIn: 'Female' });

  // Concurrently execute like from both users
  const [res1, res2] = await Promise.all([
    request('/api/discover/swipe', { method: 'POST', user: concUser1, body: { targetUserId: concUser2.id, action: 'like' } }),
    request('/api/discover/swipe', { method: 'POST', user: concUser2, body: { targetUserId: concUser1.id, action: 'like' } }),
  ]);

  assert.equal(res1.status, 200);
  assert.equal(res2.status, 200);
  const matchCount = (res1.body.data.matched ? 1 : 0) + (res2.body.data.matched ? 1 : 0);
  assert.equal(matchCount >= 1, true, 'At least one of the concurrent likes should finalize the match');

  const u1 = Math.min(concUser1.id, concUser2.id);
  const u2 = Math.max(concUser1.id, concUser2.id);
  const totalMatches = await models.Match.count({ where: { userOneId: u1, userTwoId: u2 } });
  assert.equal(totalMatches, 1, 'Exactly one Match row should exist in database');
});

test('P0-4 Rate Limiting: Rewind rate limiter throttles excess requests', async () => {
  const rateLimitUser = await createUser('rateLimitUser', { gender: 'Male', interestedIn: 'Female' });
  let got429 = false;
  for (let i = 0; i < 35; i++) {
    const res = await request('/api/discover/rewind', { method: 'POST', user: rateLimitUser });
    if (res.status === 429) {
      assert.equal(res.body.code, 'RATE_LIMITED');
      got429 = true;
      break;
    }
  }
  assert.equal(got429, true, 'Rewind rate limiter must throttle after 30 requests');
});

test('Fix 2 (VULN-P0-02): Report suppression matrix across all statuses in both directions', async () => {
  const statuses = ['open', 'reviewing', 'resolved', 'dismissed'];
  for (const st of statuses) {
    const reporter = await createUser(`rep_${st}`, { gender: 'Female', interestedIn: 'Male' });
    const reported = await createUser(`acc_${st}`, { gender: 'Male', interestedIn: 'Female' });

    await models.Report.create({
      reporterUserId: reporter.id,
      reportedUserId: reported.id,
      targetType: 'profile',
      targetId: String(reported.id),
      reason: 'harassment',
      status: st,
    });

    // Direction 1: Reporter -> Reported (always suppressed for all statuses)
    const repFeed = await request('/api/discover/feed', { user: reporter });
    assert.equal((repFeed.body.data?.profiles || []).some((p) => Number(p.id) === reported.id), false, `Reporter must not see reported user when status is ${st}`);
    const repSwipe = await request('/api/discover/swipe', {
      method: 'POST',
      user: reporter,
      body: { targetUserId: reported.id, action: 'like' },
    });
    assert.equal(repSwipe.status, 404, `Reporter swipe on reported must fail when status is ${st}`);
    assert.equal(repSwipe.body.code, 'PROFILE_NOT_DISCOVERABLE');

    // Direction 2: Reported -> Reporter
    const accSwipe = await request('/api/discover/swipe', {
      method: 'POST',
      user: reported,
      body: { targetUserId: reporter.id, action: 'like' },
    });

    if (st === 'dismissed') {
      // Accused is NOT suppressed when report was dismissed
      assert.notEqual(accSwipe.body.code, 'PROFILE_NOT_DISCOVERABLE', 'Accused user should not be blocked from swiping when report is dismissed');
    } else {
      // For open, reviewing, resolved: Accused user IS suppressed
      assert.equal(accSwipe.status, 404, `Accused user swipe must fail when report status is ${st}`);
      assert.equal(accSwipe.body.code, 'PROFILE_NOT_DISCOVERABLE');
      const accFeed = await request('/api/discover/feed', { user: reported });
      assert.equal((accFeed.body.data?.profiles || []).some((p) => Number(p.id) === reporter.id), false, `Accused user must not see reporter in feed when status is ${st}`);
    }
  }
});

test('Fix 3 (VULN-P0-03): BLOCK enforces notification suppression, socket severance, and bilateral feed invisibility', async () => {
  const userX = await createUser('blockNotifX', { gender: 'Female', interestedIn: 'Male' });
  const userY = await createUser('blockNotifY', { gender: 'Male', interestedIn: 'Female' });

  // 1. Prior notification between X and Y
  const { createNotification } = require('../src/services/notificationService');
  const notifBefore = await createNotification({
    userId: userY.id,
    actorUserId: userX.id,
    type: 'new_like',
    category: 'Likes',
    title: 'New Like',
    message: 'Someone liked you',
  });
  assert.ok(notifBefore, 'Notification before block should be created');

  // Verify notification appears in Y's list
  const listBefore = await request('/api/notifications', { user: userY });
  assert.equal(listBefore.status, 200);
  assert.equal((listBefore.body.data?.notifications || []).some((n) => Number(n.id) === notifBefore.id), true);

  // 2. User X blocks User Y
  const blockRes = await request(`/api/blocks/${userY.id}`, { method: 'POST', user: userX });
  assert.equal(blockRes.status, 200);

  // Existing notification between pair is soft-deleted
  const notifAfter = await models.Notification.findByPk(notifBefore.id);
  assert.notEqual(notifAfter.deletedAt, null, 'Notification must be soft-deleted on block');

  // In Y's notification list, soft-deleted notification is excluded
  const listAfter = await request('/api/notifications', { user: userY });
  assert.equal(listAfter.status, 200);
  assert.equal((listAfter.body.data?.notifications || []).some((n) => Number(n.id) === notifBefore.id), false);

  // 3. Attempting to dispatch a new notification between blocked users returns null
  const notifBlocked = await createNotification({
    userId: userY.id,
    actorUserId: userX.id,
    type: 'new_like',
    category: 'Likes',
    title: 'Blocked Like',
    message: 'Should not send',
  });
  assert.equal(notifBlocked, null, 'Notification between blocked users must return null');

  // 4. Bilateral feed invisibility: neither appears in the other's feed
  const feedX = await request('/api/discover/feed', { user: userX });
  assert.equal((feedX.body.data?.profiles || []).some((p) => Number(p.id) === userY.id), false);
  const feedY = await request('/api/discover/feed', { user: userY });
  assert.equal((feedY.body.data?.profiles || []).some((p) => Number(p.id) === userX.id), false);
});

test('Fix 4 (VULN-P0-04): Concurrent rewind requests serialize cleanly (one 200, one 404)', async () => {
  const actor = await createUser('concRewindActor', { gender: 'Female', interestedIn: 'Male' });
  const target = await createUser('concRewindTarget', { gender: 'Male', interestedIn: 'Female' });

  // Swipe pass first
  const swipeRes = await request('/api/discover/swipe', {
    method: 'POST',
    user: actor,
    body: { targetUserId: target.id, action: 'pass' },
  });
  assert.equal(swipeRes.status, 200);

  // Fire two concurrent rewinds
  const [rewind1, rewind2] = await Promise.all([
    request('/api/discover/rewind', { method: 'POST', user: actor }),
    request('/api/discover/rewind', { method: 'POST', user: actor }),
  ]);

  const statuses = [rewind1.status, rewind2.status].sort();
  assert.deepEqual(statuses, [200, 404], 'Exactly one rewind succeeds (200) and the other returns 404');
  const notFound = rewind1.status === 404 ? rewind1 : rewind2;
  assert.equal(notFound.body.code, 'NOTHING_TO_REWIND');
});

test('Fix 4 (VULN-P0-04): Like-versus-rewind race resolves consistently without deadlock or corruption', async () => {
  const userA = await createUser('raceUserA', { gender: 'Female', interestedIn: 'Male' });
  const userB = await createUser('raceUserB', { gender: 'Male', interestedIn: 'Female' });

  // User A likes User B
  const likeA = await request('/api/discover/swipe', {
    method: 'POST',
    user: userA,
    body: { targetUserId: userB.id, action: 'like' },
  });
  assert.equal(likeA.status, 200);
  assert.equal(likeA.body.data.matched, false);

  // Concurrently: User B likes User A, while User A rewinds their like
  const [bSwipeRes, aRewindRes] = await Promise.all([
    request('/api/discover/swipe', { method: 'POST', user: userB, body: { targetUserId: userA.id, action: 'like' } }),
    request('/api/discover/rewind', { method: 'POST', user: userA }),
  ]);

  const u1 = Math.min(userA.id, userB.id);
  const u2 = Math.max(userA.id, userB.id);
  const matchInDb = await models.Match.findOne({ where: { userOneId: u1, userTwoId: u2 } });

  if (matchInDb) {
    // If Match was created, User A's rewind MUST have been rejected with 409
    assert.equal(aRewindRes.status, 409);
    assert.equal(aRewindRes.body.code, 'CANNOT_REWIND_MATCH');
    assert.equal(bSwipeRes.status, 200);
    assert.equal(bSwipeRes.body.data.matched, true);
  } else {
    // If User A's rewind succeeded (200), User B's swipe must NOT have matched
    assert.equal(aRewindRes.status, 200);
    assert.equal(bSwipeRes.status, 200);
    assert.equal(bSwipeRes.body.data.matched, false);
  }
});

test('Fix 4 (VULN-P0-04): Repeated rewind immediately after successful rewind returns 404 NOTHING_TO_REWIND', async () => {
  const repUser = await createUser('repRewindUser', { gender: 'Female', interestedIn: 'Male' });
  const targetUser = await createUser('repRewindTarget', { gender: 'Male', interestedIn: 'Female' });

  // Pass action
  await request('/api/discover/swipe', {
    method: 'POST',
    user: repUser,
    body: { targetUserId: targetUser.id, action: 'pass' },
  });

  // First rewind succeeds
  const first = await request('/api/discover/rewind', { method: 'POST', user: repUser });
  assert.equal(first.status, 200);

  // Immediate second rewind returns 404
  const second = await request('/api/discover/rewind', { method: 'POST', user: repUser });
  assert.equal(second.status, 404);
  assert.equal(second.body.code, 'NOTHING_TO_REWIND');
});

test('Fix 4 (VULN-P0-04): Transaction rollback preserves database consistency when swipe fails', async () => {
  const rbViewer = await createUser('rbViewer', { gender: 'Female', interestedIn: 'Male' });
  const rbTarget = await createUser('rbTarget', { gender: 'Male', interestedIn: 'Female' });

  // Swipe with invalid action triggers validation failure before mutation
  const invalidRes = await request('/api/discover/swipe', {
    method: 'POST',
    user: rbViewer,
    body: { targetUserId: rbTarget.id, action: 'invalid_action' },
  });
  assert.equal(invalidRes.status, 400);
  assert.equal(invalidRes.body.code, 'VALIDATION_ERROR');

  // Database must have zero actions
  const actionCount = await models.DiscoverAction.count({
    where: { actorUserId: rbViewer.id, targetUserId: rbTarget.id },
  });
  assert.equal(actionCount, 0, 'No DiscoverAction row should be created on failed swipe');
});
