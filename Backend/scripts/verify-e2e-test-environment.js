require('../src/config/bootstrapEnv');
require('../src/config/env');

const assert = require('node:assert/strict');
const { Op, QueryTypes } = require('sequelize');
const { app } = require('../src/server');
const { getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { seed, SEED_PASSWORD, UNVERIFIED_OTP } = require('./seed-e2e-test-data');

const results = [];
let baseUrl;

async function rawRequest(method, path, { token, body, headers } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      accept: 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(headers || {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  let payload;
  try { payload = await response.json(); } catch (_) { payload = null; }
  return { status: response.status, body: payload };
}

async function check(name, method, path, options = {}) {
  const expected = Array.isArray(options.expected) ? options.expected : [options.expected ?? 200];
  try {
    const response = await rawRequest(method, path, options);
    assert.ok(expected.includes(response.status), `${method} ${path} returned ${response.status}; expected ${expected.join(' or ')}. ${JSON.stringify(response.body)}`);
    if (options.success !== undefined) assert.equal(response.body?.success, options.success);
    if (options.verify) await options.verify(response.body, response);
    results.push({ name, method, endpoint: path, status: 'PASS', actualStatus: response.status });
    return response;
  } catch (error) {
    results.push({ name, method, endpoint: path, status: 'FAIL', error: error.message });
    throw error;
  }
}

async function login(key, expected = 200) {
  return check(`Login ${key}`, 'POST', '/api/auth/login', {
    body: { email: `qa.${key}@example.test`, password: SEED_PASSWORD },
    expected,
    success: expected === 200,
  });
}

async function verifyIntegrity(models, users) {
  const sequelize = getSequelize();
  const orphanQueries = {
    profiles: 'SELECT COUNT(*) count_ FROM OnboardingProfiles p LEFT JOIN Users u ON u.id=p.userId WHERE u.id IS NULL',
    actions: 'SELECT COUNT(*) count_ FROM DiscoverActions a LEFT JOIN Users actor ON actor.id=a.actorUserId LEFT JOIN Users target ON target.id=a.targetUserId WHERE actor.id IS NULL OR target.id IS NULL',
    matches: 'SELECT COUNT(*) count_ FROM Matches m LEFT JOIN Users a ON a.id=m.userOneId LEFT JOIN Users b ON b.id=m.userTwoId WHERE a.id IS NULL OR b.id IS NULL',
    participants: 'SELECT COUNT(*) count_ FROM ConversationParticipants p LEFT JOIN Conversations c ON c.id=p.conversationId LEFT JOIN Users u ON u.id=p.userId WHERE c.id IS NULL OR u.id IS NULL',
    messages: 'SELECT COUNT(*) count_ FROM Messages m LEFT JOIN Conversations c ON c.id=m.conversationId LEFT JOIN Users u ON u.id=m.senderId WHERE c.id IS NULL OR u.id IS NULL',
    notifications: 'SELECT COUNT(*) count_ FROM Notifications n LEFT JOIN Users u ON u.id=n.userId WHERE u.id IS NULL',
    eventRelations: `SELECT (
      (SELECT COUNT(*) FROM EventRegistrations r LEFT JOIN Events e ON e.id=r.eventId LEFT JOIN Users u ON u.id=r.userId WHERE e.id IS NULL OR u.id IS NULL) +
      (SELECT COUNT(*) FROM EventWaitlist w LEFT JOIN Events e ON e.id=w.eventId LEFT JOIN Users u ON u.id=w.userId WHERE e.id IS NULL OR u.id IS NULL) +
      (SELECT COUNT(*) FROM EventGroupMessages g LEFT JOIN Events e ON e.id=g.eventId LEFT JOIN Users u ON u.id=g.senderId WHERE e.id IS NULL OR u.id IS NULL)
    ) count_`,
  };
  for (const [name, sql] of Object.entries(orphanQueries)) {
    const [row] = await sequelize.query(sql, { type: QueryTypes.SELECT });
    assert.equal(Number(row.count_), 0, `Orphan validation failed for ${name}.`);
  }

  const duplicateMatches = await sequelize.query(
    'SELECT LEAST(userOneId,userTwoId) a, GREATEST(userOneId,userTwoId) b, COUNT(*) count_ FROM Matches GROUP BY a,b HAVING COUNT(*) > 1',
    { type: QueryTypes.SELECT },
  );
  assert.equal(duplicateMatches.length, 0, 'Duplicate match pairs exist.');
  const badConversationMembers = await sequelize.query(
    'SELECT c.id FROM Conversations c LEFT JOIN ConversationParticipants p ON p.conversationId=c.id GROUP BY c.id HAVING COUNT(p.id) <> 2',
    { type: QueryTypes.SELECT },
  );
  assert.equal(badConversationMembers.length, 0, 'A direct conversation does not have exactly two participants.');
  const nonParticipantMessages = await sequelize.query(
    'SELECT m.id FROM Messages m LEFT JOIN ConversationParticipants p ON p.conversationId=m.conversationId AND p.userId=m.senderId WHERE p.id IS NULL',
    { type: QueryTypes.SELECT },
  );
  assert.equal(nonParticipantMessages.length, 0, 'A message sender is not a conversation participant.');
  assert.equal(await models.User.count({ where: { email: { [Op.like]: 'qa.%@example.test' } } }), 15);
  assert.equal(await models.OnboardingProfile.count({ where: { userId: Object.values(users).map((user) => user.id) } }), 15);
  results.push({ name: 'Database integrity and seed cardinality', method: 'SQL', endpoint: 'MySQL', status: 'PASS', actualStatus: 0 });
}

async function baselineSummary(models) {
  const qaUsers = await models.User.findAll({
    attributes: ['id', 'phoneNumber'],
    where: { email: { [Op.like]: 'qa.%@example.test' } },
  });
  const userIds = qaUsers.map((user) => user.id);
  const phones = qaUsers.map((user) => user.phoneNumber).filter(Boolean);
  const qaEvents = await models.Event.findAll({
    attributes: ['id'],
    where: { title: { [Op.like]: 'AMORAA QA %' } },
  });
  const eventIds = qaEvents.map((event) => event.id);
  const count = (model, where) => model.count({ where });
  return {
    users: qaUsers.length,
    profiles: await count(models.OnboardingProfile, { userId: userIds }),
    discoveryPreferences: await count(models.DiscoverFilterPreference, { userId: userIds }),
    notificationPreferences: await count(models.NotificationPreference, { userId: userIds }),
    discoverActions: await count(models.DiscoverAction, { actorUserId: userIds }),
    matches: await count(models.Match, { userOneId: userIds }),
    savedProfiles: await count(models.SavedProfile, { userId: userIds }),
    blocks: await count(models.Block, { blockerUserId: userIds }),
    reports: await count(models.Report, { reporterUserId: userIds }),
    conversations: await models.ConversationParticipant.count({
      distinct: true,
      col: 'conversationId',
      where: { userId: userIds },
    }),
    conversationParticipants: await count(models.ConversationParticipant, { userId: userIds }),
    messages: await count(models.Message, { senderId: userIds }),
    notifications: await count(models.Notification, { userId: userIds }),
    events: eventIds.length,
    eventRegistrations: await count(models.EventRegistration, { eventId: eventIds }),
    eventWaitlist: await count(models.EventWaitlist, { eventId: eventIds }),
    eventCheckIns: await count(models.EventCheckIn, { eventId: eventIds }),
    eventFeedback: await count(models.EventFeedback, { eventId: eventIds }),
    eventGroupMessages: await count(models.EventGroupMessage, { eventId: eventIds }),
    subscriptions: await count(models.Subscription, { userId: userIds }),
    payments: await count(models.Payment, { userId: userIds }),
    wallets: await count(models.Wallet, { userId: userIds }),
    walletTransactions: await count(models.WalletTransaction, { userId: userIds }),
    giftTransactions: await count(models.GiftTransaction, { senderId: userIds }),
    boostEntitlements: await count(models.BoostEntitlement, { userId: userIds }),
    boosts: await count(models.Boost, { userId: userIds }),
    otpTokens: await count(models.OtpToken, { phoneNumber: phones }),
    refreshTokens: await count(models.RefreshToken, { userId: userIds }),
    subscriptionPlans: await models.SubscriptionPlan.count(),
    walletProducts: await models.WalletProduct.count(),
    boostProducts: await models.BoostProduct.count(),
    gifts: await models.Gift.count(),
  };
}

async function main() {
  if (!process.argv.includes('--confirm-development-db')) throw new Error('Run through npm run verify:e2e.');
  await seed();
  const models = getModels();
  const users = Object.fromEntries((await models.User.findAll({ where: { email: { [Op.like]: 'qa.%@example.test' } } })).map((user) => [user.email.split('@')[0].replace('qa.', ''), user]));
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;

  let primaryRefresh;
  let hostRefresh;
  let diyaRefresh;
  let verifiedRefresh;
  try {
    await check('Protected endpoint rejects missing auth', 'GET', '/api/notifications', { expected: 401, success: false });
    await check('Invalid login rejected', 'POST', '/api/auth/login', { body: { email: 'qa.aarav@example.test', password: 'wrong-password' }, expected: 401, success: false });
    await login('isha', 403);
    const verified = await check('Verify unverified account with development OTP', 'POST', '/api/auth/verify-account', {
      body: { phoneNumber: users.isha.phoneNumber, code: UNVERIFIED_OTP },
      expected: 200,
      success: true,
    });
    verifiedRefresh = verified.body.data.refreshToken;
    await check('Logout verified scenario account', 'POST', '/api/auth/logout', {
      token: verified.body.data.accessToken,
      body: { refreshToken: verifiedRefresh },
      success: true,
    });

    const loginResponse = await login('aarav');
    let token = loginResponse.body.data.accessToken;
    primaryRefresh = loginResponse.body.data.refreshToken;
    const refreshed = await check('Refresh access token', 'POST', '/api/auth/refresh-token', {
      body: { refreshToken: primaryRefresh },
      success: true,
    });
    token = refreshed.body.data.accessToken;
    primaryRefresh = refreshed.body.data.refreshToken;

    await check('Authenticated account', 'GET', '/api/auth/me', { token, success: true });
    await check('Onboarding status', 'GET', '/api/onboarding/status', { token, success: true, verify: (body) => assert.equal(body.data.onboarding.onboardingCompleted, true) });
    await check('Own profile load', 'GET', '/api/me/profile', { token, success: true, verify: (body) => assert.equal(body.data.profile.name, 'Aarav Mehta') });
    await check('Own profile update', 'PUT', '/api/me/profile', {
      token,
      body: { iceBreaker: 'What is one small ritual that makes your week better?' },
      success: true,
      verify: async (body) => {
        assert.equal(body.data.profile.iceBreaker, 'What is one small ritual that makes your week better?');
        const profile = await models.OnboardingProfile.findOne({ where: { userId: users.aarav.id } });
        assert.equal(profile.iceBreaker, body.data.profile.iceBreaker);
      },
    });
    await check('Public profile contract', 'GET', `/api/profiles/${users.diya.id}`, { token, success: true, verify: (body) => assert.equal(body.data.profile.id, String(users.diya.id)) });

    const discover = await check('Discover eligibility and exclusions', 'GET', '/api/discover/feed?page=1&limit=30', { token, success: true });
    const discoveredIds = new Set(discover.body.data.profiles.map((profile) => profile.id));
    assert.ok(discoveredIds.has(String(users.diya.id)), 'Eligible Discover candidate B is missing.');
    for (const excluded of ['riya', 'nisha', 'sara', 'tara', 'kavya', 'ananya', 'leela']) {
      assert.equal(discoveredIds.has(String(users[excluded].id)), false, `${excluded} should be excluded from Discover.`);
    }
    await check('Update account preferences', 'PUT', '/api/me/preferences', { token, body: { minAge: 22, maxAge: 40, maxDistanceKm: 90, verifiedOnly: true }, success: true });
    await check('Reload account preferences', 'GET', '/api/me/preferences', { token, success: true, verify: (body) => assert.equal(body.data.preferences.maxDistanceKm, 90) });

    const matchMutation = await check('Reciprocal Like creates match', 'POST', '/api/discover/swipe', { token, body: { targetUserId: users.priya.id, action: 'like' }, success: true, verify: (body) => assert.equal(body.data.matched, true) });
    assert.ok(await models.Match.findByPk(matchMutation.body.data.matchId));
    await check('Pass persists', 'POST', '/api/discover/swipe', { token, body: { targetUserId: users.zoya.id, action: 'pass' }, success: true });
    assert.equal((await models.DiscoverAction.findOne({ where: { actorUserId: users.aarav.id, targetUserId: users.zoya.id } })).action, 'pass');
    await check('Rewind removes latest action', 'POST', '/api/discover/rewind', { token, success: true });
    await check('Boost rejects missing idempotency key', 'POST', '/api/discover/boost', { token, expected: 400, success: false });
    const entitlement = await models.BoostEntitlement.findOne({ where: { userId: users.aarav.id, idempotencyKey: 'e2e:boost:inventory' } });
    const beforeBoost = Number(entitlement.remainingQuantity);
    await check('Boost activates with idempotency key', 'POST', '/api/discover/boost', { token, headers: { 'Idempotency-Key': 'e2e:verify:boost' }, success: true });
    await entitlement.reload();
    assert.equal(Number(entitlement.remainingQuantity), beforeBoost - 1);
    await check('Boost retry is idempotent', 'POST', '/api/discover/boost', { token, headers: { 'Idempotency-Key': 'e2e:verify:boost' }, success: true });
    await entitlement.reload();
    assert.equal(Number(entitlement.remainingQuantity), beforeBoost - 1);

    await check('Saved profiles list', 'GET', '/api/me/saved-profiles?page=1&limit=20', { token, success: true, verify: (body) => assert.ok(body.data.profiles.some((profile) => profile.id === String(users.neha.id))) });
    await check('Save profile', 'PUT', `/api/me/saved-profiles/${users.zoya.id}`, { token, expected: [200, 201], success: true });
    await check('Duplicate save is idempotent', 'PUT', `/api/me/saved-profiles/${users.zoya.id}`, { token, expected: 200, success: true });
    await check('Unsave profile', 'DELETE', `/api/me/saved-profiles/${users.zoya.id}`, { token, success: true });
    await check('Sent Likes list', 'GET', '/api/me/likes?page=1&limit=20', { token, success: true });
    await check('Sent Super Likes list', 'GET', '/api/me/super-likes?page=1&limit=20', { token, success: true });

    const matches = await check('Matches list', 'GET', '/api/matches', { token, success: true, verify: (body) => assert.ok(body.data.matches.length >= 3) });
    const matchId = matches.body.data.matches[0].id;
    await check('Match detail', 'GET', `/api/matches/${matchId}`, { token, success: true });
    const conversations = await check('Conversation list', 'GET', '/api/conversations?page=1&limit=20', { token, success: true, verify: (body) => assert.equal(body.data.conversations.length, 2) });
    const conversation = conversations.body.data.conversations.find((item) => item.participant.id === String(users.ananya.id));
    await check('Conversation history', 'GET', `/api/conversations/${conversation.id}/messages?limit=30`, { token, success: true, verify: (body) => assert.ok(body.data.messages.length >= 6) });
    const sent = await check('Send text message', 'POST', `/api/conversations/${conversation.id}/messages`, { token, body: { text: 'E2E verification message persisted through the API.' }, expected: 201, success: true });
    assert.ok(await models.Message.findByPk(sent.body.data.message.id));
    await check('Mark conversation read', 'PUT', `/api/conversations/${conversation.id}/read`, { token, body: { messageId: Number(sent.body.data.message.id) }, success: true });
    await check('Save conversation draft', 'PUT', `/api/conversations/${conversation.id}/draft`, { token, body: { text: 'A temporary E2E draft' }, success: true });
    await check('Clear conversation draft', 'DELETE', `/api/conversations/${conversation.id}/draft`, { token, success: true });

    const notifications = await check('Notification inbox', 'GET', '/api/notifications?page=1&limit=20', { token, success: true, verify: (body) => assert.equal(body.data.notifications.length, 10) });
    const unread = notifications.body.data.notifications.find((item) => !item.isRead);
    const read = await check('Mark notification read', 'PUT', `/api/notifications/${unread.id}/read`, { token, success: true });
    const readAt = read.body.data.notification.readAt;
    await check('Repeat notification read is idempotent', 'PUT', `/api/notifications/${unread.id}/read`, { token, success: true, verify: (body) => assert.equal(body.data.notification.readAt, readAt) });
    const foreignNotification = await models.Notification.findOne({ where: { userId: users.kavya.id } });
    await check('Cannot read another user notification', 'PUT', `/api/notifications/${foreignNotification.id}/read`, { token, expected: 404, success: false });
    await check('Mark all notifications read', 'PUT', '/api/notifications/read-all', { token, success: true });
    const offer = await models.Notification.findOne({ where: { userId: users.aarav.id, type: 'offer' } });
    await check('Delete notification', 'DELETE', `/api/notifications/${offer.id}`, { token, success: true });
    await check('Invalid notification pagination rejected', 'GET', '/api/notifications?page=0', { token, expected: 400, success: false });
    await check('Notification preferences load', 'GET', '/api/notification-preferences', { token, success: true });
    await check('Notification preferences update', 'PUT', '/api/notification-preferences', { token, body: { newMatches: true, messages: true, offers: true, quietStart: '21:30' }, success: true });

    await check('Blocked profiles list', 'GET', '/api/blocks', { token, success: true });
    await check('Block profile', 'POST', `/api/blocks/${users.zoya.id}`, { token, expected: [200, 201], success: true });
    await check('Duplicate block is idempotent', 'POST', `/api/blocks/${users.zoya.id}`, { token, expected: 200, success: true });
    await check('Unblock profile', 'DELETE', `/api/blocks/${users.zoya.id}`, { token, success: true });
    await check('Report profile', 'POST', '/api/reports', { token, body: { targetType: 'profile', targetUserId: users.zoya.id, reason: 'other', notes: 'E2E API verification report.' }, expected: 201, success: true });

    const events = await check('Events browse', 'GET', '/api/events?page=1&limit=20&timing=all', { token, success: true, verify: (body) => assert.ok(body.data.events.length >= 4) });
    const byTitle = Object.fromEntries(events.body.data.events.map((event) => [event.title, event]));
    const upcoming = byTitle['AMORAA QA Coffee & Conversation'];
    const full = byTitle['AMORAA QA Intimate Garba Evening'];
    const active = byTitle['AMORAA QA Live Music Social'];
    const past = byTitle['AMORAA QA Old City Food Walk'];
    await check('Event detail', 'GET', `/api/events/${upcoming.id}`, { token, success: true });
    await check('My Events', 'GET', '/api/events/me?page=1&limit=20&category=all', { token, success: true });
    await check('Event registration is idempotent', 'POST', `/api/events/${upcoming.id}/registration`, { token, expected: 201, success: true });
    await check('Cancel event registration', 'DELETE', `/api/events/${upcoming.id}/registration`, { token, success: true });
    await check('Restore event registration', 'POST', `/api/events/${upcoming.id}/registration`, { token, expected: 201, success: true });
    await check('Join full event waitlist idempotently', 'POST', `/api/events/${full.id}/waitlist`, { token, expected: 201, success: true });
    await check('Leave event waitlist', 'DELETE', `/api/events/${full.id}/waitlist`, { token, success: true });
    await check('Event check-in is idempotent', 'POST', `/api/events/${active.id}/check-in`, { token, success: true });
    await check('Event feedback persists', 'POST', `/api/events/${past.id}/feedback`, { token, body: { rating: 5, venueRating: 4, hostRating: 5, safetyRating: 5, experienceRating: 5, feedbackText: 'Verified through the E2E API flow.', recommend: true }, expected: 200, success: true });
    await check('Event group messages load', 'GET', `/api/events/${upcoming.id}/group-chat/messages?limit=50`, { token, success: true });
    const groupMessage = await check('Event group message sends', 'POST', `/api/events/${upcoming.id}/group-chat/messages`, { token, body: { text: 'E2E verification group message.' }, expected: 201, success: true });
    assert.ok(await models.EventGroupMessage.findByPk(groupMessage.body.data.message.id));

    await check('Subscription plans', 'GET', '/api/subscriptions/plans', { success: true, verify: (body) => assert.equal(body.data.plans.length, 3) });
    await check('Current membership', 'GET', '/api/subscriptions/me', { token, success: true, verify: (body) => assert.equal(body.data.membership.premium, true) });
    await check('Wallet state', 'GET', '/api/wallet', { token, success: true });
    await check('Wallet products', 'GET', '/api/wallet/products', { token, success: true });
    await check('Wallet transactions', 'GET', '/api/wallet/transactions?page=1&limit=20', { token, success: true });
    await check('Redeem wallet boost', 'POST', '/api/wallet/redemptions', { token, body: { productId: 'redeem_boost_30', idempotencyKey: 'e2e:verify:redemption' }, success: true });
    await check('Boost product catalog', 'GET', '/api/boosts/products', { token, success: true });
    await check('Boost inventory', 'GET', '/api/boosts/me', { token, success: true });
    await check('Buy boost with wallet', 'POST', '/api/boosts/purchase', { token, body: { productId: 'boost_starter_30', source: 'wallet', idempotencyKey: 'e2e:verify:boost-purchase' }, expected: 201, success: true });
    await check('Gift catalog', 'GET', '/api/gifts', { expected: 200, success: true });
    await check('Send wallet-backed gift', 'POST', '/api/gifts/send', { token, body: { recipientId: users.ananya.id, giftId: 'rose_ritual', conversationId: Number(conversation.id), note: 'E2E verification gift.', idempotencyKey: 'e2e:verify:gift' }, expected: 201, success: true });

    const hostLogin = await login('vihaan');
    hostRefresh = hostLogin.body.data.refreshToken;
    await check('Host dashboard', 'GET', '/api/host/dashboard', { token: hostLogin.body.data.accessToken, success: true, verify: (body) => assert.equal(body.data.events.length, 5) });
    await check('Non-host cannot access host dashboard', 'GET', '/api/host/dashboard', { token, expected: 403, success: false });

    const diyaLogin = await login('diya');
    diyaRefresh = diyaLogin.body.data.refreshToken;
    await check('Conversation authorization blocks unrelated user', 'GET', `/api/conversations/${conversation.id}/messages`, { token: diyaLogin.body.data.accessToken, expected: 404, success: false });

    await verifyIntegrity(models, users);

    await check('Logout host', 'POST', '/api/auth/logout', { token: hostLogin.body.data.accessToken, body: { refreshToken: hostRefresh }, success: true });
    await check('Logout unrelated user', 'POST', '/api/auth/logout', { token: diyaLogin.body.data.accessToken, body: { refreshToken: diyaRefresh }, success: true });
    await check('Logout primary user', 'POST', '/api/auth/logout', { token, body: { refreshToken: primaryRefresh }, success: true });
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await seed();
  }

  const failed = results.filter((result) => result.status === 'FAIL');
  const summary = await baselineSummary(models);
  console.log(`[E2E] ${results.length - failed.length}/${results.length} API/database checks passed.`);
  console.log(`[E2E] Stable baseline counts: ${JSON.stringify(summary)}`);
  for (const result of results) console.log(`[E2E] ${result.status} ${result.method} ${result.endpoint} - ${result.name}`);
  if (failed.length) throw new Error(`${failed.length} E2E checks failed.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}).finally(async () => {
  try { await getSequelize().close(); } catch (_) { /* not initialized */ }
});
