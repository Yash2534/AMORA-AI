
const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');

const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;

if (
  !testDatabase
  || testDatabase === applicationDatabase
  || !/test/i.test(testDatabase)
) {
  throw new Error(
    'Notification integration tests require an isolated TEST_DB_NAME containing "test".',
  );
}

process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { hasEntitlement } = require('../src/services/entitlementService');
const { app } = require('../src/server');

let server;
let baseUrl;
let models;

let owner;
let other;
let candidate;
let thirdSender;
let rollbackSender;

let notificationTestPremiumPlan;

let token;
let otherToken;
let candidateToken;
let thirdSenderToken;
let rollbackSenderToken;

const userIds = [];

async function createUser(
  name,
  birthDate = '1997-04-03',
  profileValues = {},
) {
  const suffix = `${Date.now()}_${Math.random()}`;

  const user = await models.User.create({
    name,
    email: `${suffix}@notification.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
  });

  userIds.push(user.id);

  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate,
    gender: profileValues.gender || 'Male',
    interestedIn: profileValues.interestedIn || ['Female'],
    relationshipGoals: ['Meaningful Dating'],
    city: 'Ahmedabad',

    // Synthetic coordinates exclusively for test fixtures.
    matchLatitude: profileValues.matchLatitude ?? 23.0225,
    matchLongitude: profileValues.matchLongitude ?? 72.5714,

    profession: 'Engineer',
    education: 'Graduate',
    photos: [
      '/uploads/notification.jpg',
      '/uploads/notification-two.jpg',
    ],
    stage: 'complete',
    onboardingCompleted: true,
  });

  return user;
}

async function request(
  path,
  { method = 'GET', body, bearer = token } = {},
) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(bearer ? { authorization: `Bearer ${bearer}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  const responseText = await response.text();

  let responseBody;

  try {
    responseBody = responseText ? JSON.parse(responseText) : {};
  } catch {
    responseBody = {
      raw: responseText.slice(0, 2000),
    };
  }

  return {
    status: response.status,
    body: responseBody,
  };
}

// ======================================================
// DATABASE AND SERVER SETUP
// ======================================================

before(async () => {
  await migrate({
    databaseName: testDatabase,
    quiet: true,
  });

  await initializeDatabase();

  models = getModels();

  owner = await createUser('Notification Owner', '1997-04-03', {
    gender: 'Female',
    interestedIn: ['Male'],
  });

  other = await createUser('Ananya');
  candidate = await createUser('Priya', '1998-05-04');
  thirdSender = await createUser('Neha', '1996-06-05');

  rollbackSender = await createUser(
    'Rollback Sender',
    '1995-07-06',
  );

  // Create a dedicated premium plan for this integration test.
  // The production entitlement and notification-obfuscation
  // implementation remain unchanged.

  notificationTestPremiumPlan = await models.SubscriptionPlan.create({
    id: `notification-premium-${Date.now()}-${owner.id}`,
    name: 'premium',
    displayName: 'Notification Test Premium',
    description: 'Premium plan for notification integration tests.',
    priceMinor: 0,
    currency: 'INR',
    billingPeriod: 'month',
    billingInterval: 1,
    features: [],
    entitlements: {
      premium: true,
    },
    trialDays: 0,
    active: true,
    sortOrder: 0,
  });

  const subscriptionStart = new Date();

  await models.Subscription.create({
    userId: owner.id,
    planId: notificationTestPremiumPlan.id,
    status: 'active',
    provider: 'razorpay',
    startedAt: subscriptionStart,
    currentPeriodStart: subscriptionStart,
    currentPeriodEnd: new Date(
      subscriptionStart.getTime() + 30 * 24 * 60 * 60 * 1000,
    ),
    autoRenew: false,
    cancelAtPeriodEnd: false,
  });

  // Create authentication tokens.

  token = jwt.sign(
    { sub: owner.id, ver: 0 },
    process.env.JWT_SECRET,
    { expiresIn: '15m' },
  );

  otherToken = jwt.sign(
    { sub: other.id, ver: 0 },
    process.env.JWT_SECRET,
    { expiresIn: '15m' },
  );

  candidateToken = jwt.sign(
    { sub: candidate.id, ver: 0 },
    process.env.JWT_SECRET,
    { expiresIn: '15m' },
  );

  thirdSenderToken = jwt.sign(
    { sub: thirdSender.id, ver: 0 },
    process.env.JWT_SECRET,
    { expiresIn: '15m' },
  );

  rollbackSenderToken = jwt.sign(
    { sub: rollbackSender.id, ver: 0 },
    process.env.JWT_SECRET,
    { expiresIn: '15m' },
  );

  // Seed initial notifications.

  const now = Date.now();

  await models.Notification.bulkCreate([
    {
      userId: owner.id,
      type: 'like',
      category: 'Likes',
      title: 'Old like',
      message: 'Old notification',
      isRead: false,
      data: { targetUserId: candidate.id },
      createdAt: new Date(now - 3000),
      updatedAt: new Date(now - 3000),
    },
    {
      userId: owner.id,
      type: 'message',
      category: 'Messages',
      title: 'Middle message',
      message: 'Middle notification',
      isRead: false,
      data: { conversationId: '44' },
      createdAt: new Date(now - 2000),
      updatedAt: new Date(now - 2000),
    },
    {
      userId: owner.id,
      type: 'event',
      category: 'Events',
      title: 'Newest event',
      message: 'Newest notification',
      isRead: false,
      data: { eventId: '8' },
      createdAt: new Date(now - 1000),
      updatedAt: new Date(now - 1000),
    },
    {
      userId: other.id,
      type: 'security',
      category: 'Security',
      title: 'Other private notification',
      message: 'Must remain private',
      isRead: false,
      data: {},
      createdAt: new Date(now),
      updatedAt: new Date(now),
    },
  ]);

  // Start the isolated HTTP server.

  server = app.listen(0);

  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });

  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

// ======================================================
// DATABASE CLEANUP
// ======================================================

after(async () => {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }

  if (models) {
    await models.Notification.destroy({
      where: { userId: userIds },
    });

    await models.NotificationPreference.destroy({
      where: { userId: userIds },
    });

    await models.DiscoverFilterPreference.destroy({
      where: { userId: userIds },
    });

    // Remove subscriptions before deleting users or plans.

    await models.Subscription.destroy({
      where: { userId: userIds },
    });

    await models.OnboardingProfile.destroy({
      where: { userId: userIds },
    });

    await models.User.destroy({
      where: { id: userIds },
    });

    if (notificationTestPremiumPlan) {
      await models.SubscriptionPlan.destroy({
        where: {
          id: notificationTestPremiumPlan.id,
        },
      });
    }
  }

  await getSequelize().close();
});

// ======================================================
// TEST 1: AUTHENTICATION
// ======================================================

test(
  'notification and preference APIs require Bearer authentication',
  async () => {
    for (const path of [
      '/api/notifications',
      '/api/notification-preferences',
      '/api/me/preferences',
    ]) {
      const response = await request(path, {
        bearer: null,
      });

      assert.equal(response.status, 401);
    }
  },
);

// ======================================================
// TEST 2: NOTIFICATION LIST
// ======================================================

test(
  'GET notifications is owner-scoped, newest-first, filtered, and paginated',
  async () => {
    const first = await request(
      '/api/notifications?page=1&limit=2',
    );

    assert.equal(first.status, 200);

    assert.deepEqual(
      first.body.data.notifications.map((item) => item.title),
      ['Newest event', 'Middle message'],
    );

    assert.equal(first.body.data.pagination.hasMore, true);
    assert.equal(first.body.data.pagination.nextPage, 2);
    assert.equal(first.body.data.unreadCount, 3);

    assert.equal(
      first.body.data.notifications.some(
        (item) => item.title.includes('Other'),
      ),
      false,
    );

    const second = await request(
      '/api/notifications?page=2&limit=2',
    );

    assert.deepEqual(
      second.body.data.notifications.map((item) => item.title),
      ['Old like'],
    );

    const events = await request(
      '/api/notifications?category=Events',
    );

    assert.deepEqual(
      events.body.data.notifications.map((item) => item.category),
      ['Events'],
    );

    const unread = await request(
      '/api/notifications?unread=true',
    );

    assert.equal(unread.body.data.notifications.length, 3);
  },
);

// ======================================================
// TEST 3: MARK AS READ
// ======================================================

test(
  'mark read is idempotent and cannot modify another user notification',
  async () => {
    const own = await models.Notification.findOne({
      where: {
        userId: owner.id,
        title: 'Middle message',
      },
    });

    const foreign = await models.Notification.findOne({
      where: {
        userId: other.id,
      },
    });

    const first = await request(
      `/api/notifications/${own.id}/read`,
      { method: 'PUT' },
    );

    assert.equal(first.status, 200);
    assert.equal(first.body.data.notification.isRead, true);
    assert.ok(first.body.data.notification.readAt);

    const readAt = first.body.data.notification.readAt;

    const repeated = await request(
      `/api/notifications/${own.id}/read`,
      { method: 'PUT' },
    );

    assert.equal(
      repeated.body.data.notification.readAt,
      readAt,
    );

    const foreignResponse = await request(
      `/api/notifications/${foreign.id}/read`,
      { method: 'PUT' },
    );

    assert.equal(foreignResponse.status, 404);

    await own.reload();

    assert.equal(own.isRead, true);
    assert.ok(own.readAt);
  },
);

// ======================================================
// TEST 4: READ ALL
// ======================================================

test(
  'read-all updates only the authenticated user',
  async () => {
    const response = await request(
      '/api/notifications/read-all',
      { method: 'PUT' },
    );

    assert.equal(response.status, 200);
    assert.equal(response.body.data.updatedCount, 2);
    assert.equal(response.body.data.unreadCount, 0);

    assert.equal(
      await models.Notification.count({
        where: {
          userId: owner.id,
          isRead: false,
        },
      }),
      0,
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: other.id,
          isRead: false,
        },
      }),
      1,
    );
  },
);

// ======================================================
// TEST 5: DELETE
// ======================================================

test(
  'delete is owner-scoped, idempotent, persisted, and excluded from reload',
  async () => {
    const own = await models.Notification.findOne({
      where: {
        userId: owner.id,
        title: 'Old like',
      },
    });

    const foreign = await models.Notification.findOne({
      where: {
        userId: other.id,
      },
    });

    assert.equal(
      (
        await request(`/api/notifications/${own.id}`, {
          method: 'DELETE',
        })
      ).status,
      200,
    );

    assert.equal(
      (
        await request(`/api/notifications/${own.id}`, {
          method: 'DELETE',
        })
      ).status,
      200,
    );

    assert.equal(
      (
        await request(`/api/notifications/${foreign.id}`, {
          method: 'DELETE',
        })
      ).status,
      404,
    );

    await own.reload();

    assert.ok(own.deletedAt);

    const list = await request('/api/notifications');

    assert.equal(
      list.body.data.notifications.some(
        (item) => item.id === String(own.id),
      ),
      false,
    );
  },
);

// ======================================================
// TEST 6: NOTIFICATION PREFERENCES
// ======================================================

test(
  'notification preferences retain defaults, whitelist fields, and persist',
  async () => {
    const defaults = await request(
      '/api/notification-preferences',
    );

    assert.equal(defaults.status, 200);
    assert.equal(
      defaults.body.data.preferences.newMatches,
      true,
    );

    const updated = await request(
      '/api/notification-preferences',
      {
        method: 'PUT',
        body: {
          newMatches: false,
          quietHoursEnabled: true,
          quietStart: '21:30',
        },
      },
    );

    assert.equal(
      updated.body.data.preferences.newMatches,
      false,
    );

    assert.equal(
      updated.body.data.preferences.quietStart,
      '21:30',
    );

    assert.equal(
      (
        await request('/api/notification-preferences', {
          method: 'PUT',
          body: { role: 'admin' },
        })
      ).status,
      400,
    );

    assert.equal(
      (
        await request('/api/notification-preferences', {
          method: 'PUT',
          body: { newMatches: 'no' },
        })
      ).status,
      400,
    );

    assert.equal(
      (
        await request('/api/notification-preferences')
      ).body.data.preferences.newMatches,
      false,
    );
  },
);

// ======================================================
// TEST 7: ACCOUNT PREFERENCES AND DISCOVER FILTERS
// ======================================================

test(
  'account preferences persist, reject unsupported values, and enforce Discover filters',
  async () => {
    const initial = await request('/api/me/preferences');

    assert.equal(initial.status, 200);
    assert.equal(initial.body.data.preferences.minAge, 18);

    const hidden = await request(
      '/api/me/preferences',
      {
        method: 'PUT',
        body: {
          minAge: 35,
          maxAge: 45,
          maxDistanceKm: 25,
        },
      },
    );

    assert.equal(hidden.status, 200, JSON.stringify(hidden.body));
    assert.equal(hidden.body.data.preferences.minAge, 35);

    assert.equal(
      (
        await request('/api/me/preferences', {
          method: 'PUT',
          body: {
            minAge: 60,
            maxAge: 30,
          },
        })
      ).status,
      400,
    );

    assert.equal(
      (
        await request('/api/me/preferences', {
          method: 'PUT',
          body: { role: 'admin' },
        })
      ).status,
      400,
    );

    assert.equal(
      (
        await request('/api/me/preferences', {
          method: 'PUT',
          body: { onlineNow: 'sometimes' },
        })
      ).status,
      400,
    );

    const excluded = await request(
      '/api/discover/feed?limit=30&verifiedOnly=true&minScore=0',
    );

    assert.equal(
      excluded.body.data.profiles.some(
        (profile) => profile.id === String(candidate.id),
      ),
      false,
    );

    // Restore age settings. The distance filter remains at 25 km.
    // All integration test profiles use identical synthetic coordinates.

    const reset = await request(
      '/api/me/preferences',
      {
        method: 'PUT',
        body: {
          minAge: 18,
          maxAge: 45,
        },
      },
    );

    assert.equal(reset.status, 200);

    const included = await request(
      '/api/discover/feed?limit=30&verifiedOnly=true&minScore=0',
    );

    assert.equal(
      included.body.data.profiles.some(
        (profile) => profile.id === String(candidate.id),
      ),
      true,
    );

    const otherPreferences = await request(
      '/api/me/preferences',
      { bearer: otherToken },
    );

    assert.equal(
      otherPreferences.body.data.preferences.minAge,
      18,
    );

    assert.equal(
      (
        await request('/api/me/preferences')
      ).body.data.preferences.minAge,
      18,
    );
  },
);

// ======================================================
// TEST 8: LIKE NOTIFICATIONS, ACTORS AND PHOTOS
// ======================================================

test(
  'likes persist relational actors and receiver sees each current sender name and photo',
  async () => {
    // Confirm that the premium fixture is functioning before
    // testing premium-only notification actor visibility.

    const ownerHasPremium = await hasEntitlement(
      owner.id,
      'premium',
    );

    console.log(
      '[TEST] Owner premium entitlement:',
      ownerHasPremium,
    );

    assert.equal(
      ownerHasPremium,
      true,
      'Notification test owner must have an active premium entitlement.',
    );

    await request(
      '/api/notification-preferences',
      {
        method: 'PUT',
        body: { newMatches: true },
      },
    );

    const senders = [
      [candidate, candidateToken],
      [other, otherToken],
      [thirdSender, thirdSenderToken],
    ];

    for (const [sender, bearer] of senders) {
      const response = await request(
        '/api/discover/swipe',
        {
          method: 'POST',
          bearer,
          body: {
            targetUserId: owner.id,
            action: 'like',
          },
        },
      );

      assert.equal(
        response.status,
        200,
        JSON.stringify(response.body),
      );

      const action = await models.DiscoverAction.findOne({
        where: {
          actorUserId: sender.id,
          targetUserId: owner.id,
        },
      });

      assert.ok(
        action,
        `Missing Discover action for ${sender.name}`,
      );

      assert.equal(action.action, 'like');
    }

    // Check actual relational notification records.

    const rows = await models.Notification.findAll({
      where: {
        userId: owner.id,
        type: 'new_like',
      },
      order: [['actorUserId', 'ASC']],
    });

    assert.equal(rows.length, 3);

    assert.deepEqual(
      new Set(rows.map((row) => Number(row.actorUserId))),
      new Set([
        candidate.id,
        other.id,
        thirdSender.id,
      ]),
    );

    assert.ok(
      rows.every((row) => row.category === 'Likes'),
    );

    // Verify actor serialization through the real notification API.

    const receiverList = await request(
      '/api/notifications?category=Likes',
    );

    assert.equal(receiverList.status, 200);

    const receivedLikes = receiverList.body.data.notifications.filter(
      (item) => item.type === 'new_like',
    );

    assert.equal(receivedLikes.length, 3);

    assert.ok(
      receivedLikes.every((item) => item.actor),
      `Missing notification actor:\n${JSON.stringify(receivedLikes, null, 2)}`,
    );

    assert.deepEqual(
      new Set(receivedLikes.map((item) => item.actor.name)),
      new Set(['Priya', 'Ananya', 'Neha']),
    );

    assert.ok(
      receivedLikes.every(
        (item) => item.actor.photoUrl.endsWith(
          `/api/media/profile/${item.actor.userId}/notification.jpg`,
        ),
      ),
      JSON.stringify(receivedLikes),
    );

    assert.ok(
      receivedLikes.every(
        (item) => String(item.data.targetUserId) === item.actor.userId,
      ),
      JSON.stringify(receivedLikes),
    );

    // Change profile photos and verify current photo serialization.

    await models.OnboardingProfile.update(
      {
        photos: [
          '/uploads/priya-current.jpg',
          '/uploads/priya-current-two.jpg',
        ],
        primaryPhotoIndex: 0,
      },
      {
        where: { userId: candidate.id },
      },
    );

    await models.OnboardingProfile.update(
      {
        photos: ['/uploads/ananya-current.jpg'],
        primaryPhotoIndex: 0,
      },
      {
        where: { userId: other.id },
      },
    );

    await models.OnboardingProfile.update(
      {
        photos: [],
        primaryPhotoIndex: 0,
      },
      {
        where: { userId: thirdSender.id },
      },
    );

    const currentImages = await request(
      '/api/notifications?category=Likes',
    );

    const currentLikeItems = currentImages.body.data.notifications.filter(
      (item) => item.type === 'new_like',
    );

    assert.equal(currentLikeItems.length, 3);

    assert.ok(
      currentLikeItems.every((item) => item.actor),
      `Missing actor after photo update:\n${JSON.stringify(currentLikeItems, null, 2)}`,
    );

    const byActor = Object.fromEntries(
      currentLikeItems.map((item) => [
        item.actor.userId,
        item.actor.photoUrl,
      ]),
    );

    assert.ok(
      byActor[String(candidate.id)].endsWith(
        `/api/media/profile/${candidate.id}/priya-current.jpg`,
      ),
    );

    assert.ok(
      byActor[String(other.id)].endsWith(
        `/api/media/profile/${other.id}/ananya-current.jpg`,
      ),
    );

    assert.equal(
      byActor[String(thirdSender.id)],
      null,
    );

    // Sender accounts must not see another user's notifications.

    for (const bearer of [
      candidateToken,
      otherToken,
      thirdSenderToken,
    ]) {
      const senderList = await request(
        '/api/notifications',
        { bearer },
      );

      assert.equal(
        senderList.body.data.notifications.some(
          (item) => item.type === 'new_like'
            && item.actor?.userId === String(candidate.id),
        ),
        false,
      );
    }

    // The API should show the sender's current name.

    await candidate.update({
      name: 'Priya Sharma',
    });

    const refreshed = await request(
      '/api/notifications?category=Likes',
    );

    const renamed = refreshed.body.data.notifications.find(
      (item) => item.actor?.userId === String(candidate.id),
    );

    assert.ok(
      renamed,
      'Renamed sender notification was not found.',
    );

    assert.equal(
      renamed.actor.name,
      'Priya Sharma',
    );

    // Repeated likes must not create duplicate notifications.

    const retry = await request(
      '/api/discover/swipe',
      {
        method: 'POST',
        bearer: candidateToken,
        body: {
          targetUserId: owner.id,
          action: 'like',
        },
      },
    );

    assert.equal(
      retry.status,
      200,
      JSON.stringify(retry.body),
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: owner.id,
          actorUserId: candidate.id,
          type: 'new_like',
        },
      }),
      1,
    );

    const ownNotification = await models.Notification.findOne({
      where: {
        userId: owner.id,
        actorUserId: candidate.id,
        type: 'new_like',
      },
    });

    assert.ok(ownNotification);

    const markedRead = await request(
      `/api/notifications/${ownNotification.id}/read`,
      { method: 'PUT' },
    );

    assert.equal(markedRead.status, 200);

    assert.equal(
      markedRead.body.data.notification.actor.name,
      'Priya Sharma',
    );

    // A different user cannot delete the owner's notification.

    const foreignDelete = await request(
      `/api/notifications/${ownNotification.id}`,
      {
        method: 'DELETE',
        bearer: thirdSenderToken,
      },
    );

    assert.equal(foreignDelete.status, 404);

    // The owner can delete their own notification.

    const ownDelete = await request(
      `/api/notifications/${ownNotification.id}`,
      { method: 'DELETE' },
    );

    assert.equal(ownDelete.status, 200);

    // Retrying the like must not restore the deleted notification.

    const afterDeleteSwipe = await request(
      '/api/discover/swipe',
      {
        method: 'POST',
        bearer: candidateToken,
        body: {
          targetUserId: owner.id,
          action: 'like',
        },
      },
    );

    assert.equal(
      afterDeleteSwipe.status,
      200,
      JSON.stringify(afterDeleteSwipe.body),
    );

    const afterDelete = await request(
      '/api/notifications?category=Likes',
    );

    assert.equal(
      afterDelete.body.data.notifications.some(
        (item) => item.id === String(ownNotification.id),
      ),
      false,
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: owner.id,
          actorUserId: candidate.id,
          type: 'new_like',
        },
      }),
      1,
    );
  },
);

// ======================================================
// TEST 9: NOTIFICATION FAILURE MUST ROLL BACK THE LIKE
// ======================================================

test(
  'notification write failure rolls back the like action',
  async () => {
    const preferenceResponse = await request(
      '/api/notification-preferences',
      {
        method: 'PUT',
        body: { newMatches: true },
      },
    );

    assert.equal(
      preferenceResponse.status,
      200,
      JSON.stringify(preferenceResponse.body),
    );

    // Ensure the test starts without previous actions
    // or notifications for this user pair.

    assert.equal(
      await models.DiscoverAction.count({
        where: {
          actorUserId: rollbackSender.id,
          targetUserId: owner.id,
        },
      }),
      0,
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: owner.id,
          actorUserId: rollbackSender.id,
        },
      }),
      0,
    );

    // Force Notification.create() to fail during the request.

    models.Notification.addHook(
      'beforeCreate',
      'force-like-notification-failure',
      () => {
        throw new Error('forced notification failure');
      },
    );

    try {
      const response = await request(
        '/api/discover/swipe',
        {
          method: 'POST',
          bearer: rollbackSenderToken,
          body: {
            targetUserId: owner.id,
            action: 'like',
          },
        },
      );

      assert.equal(
        response.status,
        500,
        `Expected HTTP 500 after forced notification failure. Actual response: ${JSON.stringify(response.body, null, 2)}`,
      );
    } finally {
      models.Notification.removeHook(
        'beforeCreate',
        'force-like-notification-failure',
      );
    }

    // Prove the database transaction actually rolled back.

    assert.equal(
      await models.DiscoverAction.count({
        where: {
          actorUserId: rollbackSender.id,
          targetUserId: owner.id,
        },
      }),
      0,
      'Like action must not persist after notification creation fails.',
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: owner.id,
          actorUserId: rollbackSender.id,
        },
      }),
      0,
      'Notification must not persist after the forced write failure.',
    );
  },
);
