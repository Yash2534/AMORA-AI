
const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');

const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;

if (
  !testDatabase
  || testDatabase === applicationDatabase
  || !/test/i.test(testDatabase)
) {
  throw new Error(
    'Relationship integration tests require an isolated TEST_DB_NAME containing "test".',
  );
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
let relationshipTestPremiumPlan;

const users = {};
const userIds = [];

const tokenFor = (user) => jwt.sign(
  {
    sub: user.id,
    ver: Number(user.tokenVersion || 0),
  },
  process.env.JWT_SECRET,
  { expiresIn: '15m' },
);

const auth = (user) => ({
  authorization: `Bearer ${tokenFor(user)}`,
});

// ======================================================
// HTTP HELPERS
// ======================================================

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  const responseText = await response.text();

  let body;

  try {
    body = responseText ? JSON.parse(responseText) : {};
  } catch {
    body = {
      raw: responseText.slice(0, 2000),
    };
  }

  return {
    status: response.status,
    body,
  };
}

async function json(path, method, user, body) {
  return request(path, {
    method,
    headers: {
      ...auth(user),
      'content-type': 'application/json',
    },
    ...(body === undefined
      ? {}
      : { body: JSON.stringify(body) }),
  });
}

// ======================================================
// USER AND PROFILE FIXTURES
// ======================================================

async function createUser(key, userValues = {}, profileValues = {}) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random()
    .toString(16)
    .slice(2)}`;

  const user = await models.User.create({
    name: `Relationship ${key}`,
    email: `${suffix}@relationships.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
    ...userValues,
  });

  userIds.push(user.id);
  users[key] = user;

  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: profileValues.birthDate || '1997-05-12',

    gender: profileValues.gender ?? 'Female',
    interestedIn: profileValues.interestedIn ?? ['Male'],

    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',

    // Synthetic coordinates for integration tests only.
    matchLatitude: profileValues.matchLatitude ?? 23.0225,
    matchLongitude: profileValues.matchLongitude ?? 72.5714,

    profession: 'Engineer',
    education: 'Graduate',
    hometown: 'Ahmedabad',
    interests: ['music'],
    lifestyle: {},
    prompts: {
      idealDate: 'Coffee',
    },
    pronouns: ['she/her'],
    valuedQualities: ['kindness'],
    loveLanguages: ['quality_time'],
    preferredTalkingHours: ['evening'],
    communicationStyle: 'calls',

    photos: [
      '/uploads/relationships.jpg',
      '/uploads/relationships-two.jpg',
    ],

    stage: 'complete',
    onboardingCompleted: true,
  });

  return user;
}

// ======================================================
// TEST-ONLY PREMIUM SUBSCRIPTIONS
// ======================================================

async function createPremiumSubscriptions(userList) {
  relationshipTestPremiumPlan = await models.SubscriptionPlan.create({
    id: `relationships-premium-${Date.now()}`,
    name: 'premium',
    displayName: 'Relationship Integration Premium',
    description: 'Premium plan for relationship integration tests.',
    priceMinor: 0,
    currency: 'INR',
    billingPeriod: 'month',
    billingInterval: 1,
    features: [],
    entitlements: {
      premium: true,
      unlimitedSuperLikes: true,
    },
    trialDays: 0,
    active: true,
    sortOrder: 0,
  });

  const subscriptionStart = new Date();

  const subscriptionEnd = new Date(
    subscriptionStart.getTime() + 30 * 24 * 60 * 60 * 1000,
  );

  await models.Subscription.bulkCreate(
    userList.map((user) => ({
      userId: user.id,
      planId: relationshipTestPremiumPlan.id,
      status: 'active',
      provider: 'razorpay',
      startedAt: subscriptionStart,
      currentPeriodStart: subscriptionStart,
      currentPeriodEnd: subscriptionEnd,
      autoRenew: false,
      cancelAtPeriodEnd: false,
    })),
  );
}

// ======================================================
// BEFORE: DATABASE, USERS AND SERVER
// ======================================================

before(async () => {
  await migrate({
    databaseName: testDatabase,
    quiet: true,
  });

  await initializeDatabase();

  models = getModels();

  // Male viewer interested in female candidates.
  await createUser('viewer', {}, {
    gender: 'Male',
    interestedIn: ['Female'],
  });

  // Female candidates interested in males.
  await createUser('targetA');
  await createUser('targetB');
  await createUser('targetC');

  await createUser('otherOwner');

  // Dedicated incoming-Like fixture.
  // This user is not involved in the reciprocal match test.
  await createUser('receivedOnly');

  // Male outsider for otherOwner's Super Like.
  await createUser('outsider', {}, {
    gender: 'Male',
    interestedIn: ['Female'],
  });

  await createUser(
    'inactive',
    {
      accountStatus: 'deactivated',
      deactivatedAt: new Date(),
    },
  );

  // The viewer and otherOwner need active premium entitlements
  // to send Super Likes.
  await createPremiumSubscriptions([
    users.viewer,
    users.otherOwner,
  ]);

  assert.ok(relationshipTestPremiumPlan);

  const viewerSubscription = await models.Subscription.findOne({
    where: {
      userId: users.viewer.id,
      planId: relationshipTestPremiumPlan.id,
    },
  });

  const otherOwnerSubscription = await models.Subscription.findOne({
    where: {
      userId: users.otherOwner.id,
      planId: relationshipTestPremiumPlan.id,
    },
  });

  assert.ok(viewerSubscription);
  assert.ok(otherOwnerSubscription);

  server = app.listen(0);

  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });

  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

// ======================================================
// AFTER: CLEANUP
// ======================================================

after(async () => {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }

  if (models) {
    await models.Match.destroy({
      where: {
        [Op.or]: [
          { userOneId: userIds },
          { userTwoId: userIds },
        ],
      },
    });

    await models.DiscoverAction.destroy({
      where: {
        [Op.or]: [
          { actorUserId: userIds },
          { targetUserId: userIds },
        ],
      },
    });

    await models.SavedProfile.destroy({
      where: {
        [Op.or]: [
          { userId: userIds },
          { savedUserId: userIds },
        ],
      },
    });

    await models.Block.destroy({
      where: {
        [Op.or]: [
          { blockerUserId: userIds },
          { blockedUserId: userIds },
        ],
      },
    });

    await models.Notification.destroy({
      where: {
        [Op.or]: [
          { userId: userIds },
          { actorUserId: userIds },
        ],
      },
      force: true,
    });

    await models.Subscription.destroy({
      where: {
        userId: userIds,
      },
    });

    await models.OnboardingProfile.destroy({
      where: {
        userId: userIds,
      },
    });

    await models.User.destroy({
      where: {
        id: userIds,
      },
    });

    if (relationshipTestPremiumPlan) {
      await models.SubscriptionPlan.destroy({
        where: {
          id: relationshipTestPremiumPlan.id,
        },
      });
    }
  }

  try {
    await getSequelize().close();
  } catch (_) {
    // Connection may already be closed.
  }
});

// ======================================================
// TEST 1: AUTHENTICATION
// ======================================================

test(
  'all /api/me relationship endpoints require Bearer authentication',
  async () => {
    assert.equal(
      (await request('/api/me/saved-profiles')).status,
      401,
    );

    assert.equal(
      (
        await request(
          `/api/me/saved-profiles/${users.targetA.id}`,
          { method: 'PUT' },
        )
      ).status,
      401,
    );

    assert.equal(
      (
        await request(
          `/api/me/saved-profiles/${users.targetA.id}`,
          { method: 'DELETE' },
        )
      ).status,
      401,
    );

    assert.equal(
      (await request('/api/me/likes')).status,
      401,
    );

    assert.equal(
      (await request('/api/me/super-likes')).status,
      401,
    );

    assert.equal(
      (await request('/api/me/received-likes')).status,
      401,
    );
  },
);

// ======================================================
// TEST 2: SAVED PROFILES
// ======================================================

test(
  'saved profiles are owner-scoped, idempotent, paginated, and visibility-filtered',
  async () => {
    const first = await json(
      `/api/me/saved-profiles/${users.targetA.id}`,
      'PUT',
      users.viewer,
    );

    assert.equal(first.status, 201);
    assert.equal(first.body.data.saved, true);
    assert.equal(first.body.data.userId, String(users.targetA.id));

    const duplicate = await json(
      `/api/me/saved-profiles/${users.targetA.id}`,
      'PUT',
      users.viewer,
    );

    assert.equal(duplicate.status, 200);

    assert.equal(
      await models.SavedProfile.count({
        where: {
          userId: users.viewer.id,
          savedUserId: users.targetA.id,
        },
      }),
      1,
    );

    assert.equal(
      (
        await json(
          `/api/me/saved-profiles/${users.viewer.id}`,
          'PUT',
          users.viewer,
        )
      ).status,
      400,
    );

    assert.equal(
      (
        await json(
          `/api/me/saved-profiles/${users.inactive.id}`,
          'PUT',
          users.viewer,
        )
      ).status,
      404,
    );

    await models.Block.create({
      blockerUserId: users.targetB.id,
      blockedUserId: users.viewer.id,
    });

    assert.equal(
      (
        await json(
          `/api/me/saved-profiles/${users.targetB.id}`,
          'PUT',
          users.viewer,
        )
      ).status,
      404,
    );

    await models.Block.destroy({
      where: {
        blockerUserId: users.targetB.id,
        blockedUserId: users.viewer.id,
      },
    });

    await json(
      `/api/me/saved-profiles/${users.targetB.id}`,
      'PUT',
      users.viewer,
    );

    await json(
      `/api/me/saved-profiles/${users.targetC.id}`,
      'PUT',
      users.viewer,
    );

    const pageOne = await request(
      '/api/me/saved-profiles?page=1&limit=2',
      {
        headers: auth(users.viewer),
      },
    );

    const pageTwo = await request(
      '/api/me/saved-profiles?page=2&limit=2',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(pageOne.status, 200);
    assert.equal(pageOne.body.data.profiles.length, 2);
    assert.equal(pageOne.body.data.pagination.hasMore, true);

    assert.equal(pageTwo.status, 200);
    assert.equal(pageTwo.body.data.profiles.length, 1);
    assert.equal(pageTwo.body.data.pagination.hasMore, false);

    assert.deepEqual(
      new Set(
        [
          ...pageOne.body.data.profiles,
          ...pageTwo.body.data.profiles,
        ].map((profile) => profile.id),
      ),
      new Set([
        String(users.targetA.id),
        String(users.targetB.id),
        String(users.targetC.id),
      ]),
    );

    await models.Block.create({
      blockerUserId: users.viewer.id,
      blockedUserId: users.targetA.id,
    });

    const filtered = await request(
      '/api/me/saved-profiles?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(
      filtered.body.data.profiles.some(
        (profile) => profile.id === String(users.targetA.id),
      ),
      false,
    );

    await models.Block.destroy({
      where: {
        blockerUserId: users.viewer.id,
        blockedUserId: users.targetA.id,
      },
    });

    await json(
      `/api/me/saved-profiles/${users.outsider.id}`,
      'PUT',
      users.otherOwner,
    );

    const viewerUnsave = await json(
      `/api/me/saved-profiles/${users.outsider.id}`,
      'DELETE',
      users.viewer,
    );

    assert.equal(viewerUnsave.status, 200);
    assert.equal(viewerUnsave.body.data.saved, false);

    assert.equal(
      await models.SavedProfile.count({
        where: {
          userId: users.otherOwner.id,
          savedUserId: users.outsider.id,
        },
      }),
      1,
    );

    assert.equal(
      (
        await json(
          `/api/me/saved-profiles/${users.targetA.id}`,
          'DELETE',
          users.viewer,
        )
      ).body.data.saved,
      false,
    );

    assert.equal(
      (
        await json(
          `/api/me/saved-profiles/${users.targetA.id}`,
          'DELETE',
          users.viewer,
        )
      ).body.data.saved,
      false,
    );

    assert.equal(
      await models.SavedProfile.count({
        where: {
          userId: users.viewer.id,
          savedUserId: users.targetA.id,
        },
      }),
      0,
    );
  },
);

// ======================================================
// TEST 3: SENT LIKES AND RECIPROCAL MATCHING
// ======================================================

test(
  'sent likes persist, paginate, preserve reciprocal matching, and enforce visibility',
  async () => {
    // otherOwner sends an incoming Like to the viewer.
    const incoming = await json(
      '/api/discover/swipe',
      'POST',
      users.otherOwner,
      {
        targetUserId: users.viewer.id,
        action: 'like',
      },
    );

    assert.equal(
      incoming.status,
      200,
      JSON.stringify(incoming.body),
    );

    // Viewer sends Likes to three female candidates.
    for (const target of [
      users.targetA,
      users.targetB,
      users.targetC,
    ]) {
      const response = await json(
        '/api/discover/swipe',
        'POST',
        users.viewer,
        {
          targetUserId: target.id,
          action: 'like',
        },
      );

      assert.equal(
        response.status,
        200,
        JSON.stringify(response.body),
      );
    }

    assert.equal(
      await models.DiscoverAction.count({
        where: {
          actorUserId: users.viewer.id,
          action: 'like',
        },
      }),
      3,
    );

    const persistedLikes = await models.DiscoverAction.findAll({
      where: {
        actorUserId: users.viewer.id,
        targetUserId: [
          users.targetA.id,
          users.targetB.id,
          users.targetC.id,
        ],
      },
    });

    assert.ok(
      persistedLikes.every((row) => row.action === 'like'),
    );

    assert.ok(
      persistedLikes.every((row) => row.createdAt && row.updatedAt),
    );

    const pageOne = await request(
      '/api/me/likes?page=1&limit=2',
      {
        headers: auth(users.viewer),
      },
    );

    const pageTwo = await request(
      '/api/me/likes?page=2&limit=2',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(pageOne.status, 200);
    assert.equal(pageTwo.status, 200);
    assert.equal(pageOne.body.data.pagination.hasMore, true);
    assert.equal(pageTwo.body.data.pagination.hasMore, false);

    const sentIds = [
      ...pageOne.body.data.profiles,
      ...pageTwo.body.data.profiles,
    ].map((profile) => profile.id);

    assert.deepEqual(
      new Set(sentIds),
      new Set([
        String(users.targetA.id),
        String(users.targetB.id),
        String(users.targetC.id),
      ]),
    );

    assert.equal(
      sentIds.includes(String(users.otherOwner.id)),
      false,
    );

    // A block in the opposite direction must hide the candidate.
    await models.Block.create({
      blockerUserId: users.targetB.id,
      blockedUserId: users.viewer.id,
    });

    const blockedList = await request(
      '/api/me/likes?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(
      blockedList.body.data.profiles.some(
        (profile) => profile.id === String(users.targetB.id),
      ),
      false,
    );

    const blockedSwipe = await json(
      '/api/discover/swipe',
      'POST',
      users.viewer,
      {
        targetUserId: users.targetB.id,
        action: 'like',
      },
    );

    assert.equal(blockedSwipe.status, 404);

    await models.Block.destroy({
      where: {
        blockerUserId: users.targetB.id,
        blockedUserId: users.viewer.id,
      },
    });

    // Deactivated candidates must be hidden.
    await users.targetC.update({
      accountStatus: 'deactivated',
      deactivatedAt: new Date(),
    });

    const inactiveList = await request(
      '/api/me/likes?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(
      inactiveList.body.data.profiles.some(
        (profile) => profile.id === String(users.targetC.id),
      ),
      false,
    );

    await users.targetC.update({
      accountStatus: 'active',
      deactivatedAt: null,
    });

    // Target A reciprocates the viewer's Like.
    const reciprocalLike = await json(
      '/api/discover/swipe',
      'POST',
      users.targetA,
      {
        targetUserId: users.viewer.id,
        action: 'like',
      },
    );

    assert.equal(
      reciprocalLike.status,
      200,
      JSON.stringify(reciprocalLike.body),
    );

    const matched = await json(
      '/api/discover/swipe',
      'POST',
      users.viewer,
      {
        targetUserId: users.targetA.id,
        action: 'like',
      },
    );

    assert.equal(
      matched.status,
      200,
      JSON.stringify(matched.body),
    );

    assert.equal(matched.body.data.matched, true);

    const viewerMatchNotification = await models.Notification.findOne({
      where: {
        userId: users.viewer.id,
        type: 'new_match',
      },
    });

    const targetMatchNotification = await models.Notification.findOne({
      where: {
        userId: users.targetA.id,
        type: 'new_match',
      },
    });

    assert.ok(viewerMatchNotification);
    assert.ok(targetMatchNotification);

    assert.equal(
      Number(viewerMatchNotification.actorUserId),
      users.targetA.id,
    );

    assert.equal(
      Number(targetMatchNotification.actorUserId),
      users.viewer.id,
    );

    // Repeated Like must not create a duplicate match.
    await json(
      '/api/discover/swipe',
      'POST',
      users.viewer,
      {
        targetUserId: users.targetA.id,
        action: 'like',
      },
    );

    const first = Math.min(
      users.viewer.id,
      users.targetA.id,
    );

    const second = Math.max(
      users.viewer.id,
      users.targetA.id,
    );

    assert.equal(
      await models.Match.count({
        where: {
          userOneId: first,
          userTwoId: second,
        },
      }),
      1,
    );
  },
);

// ======================================================
// TEST 4: RECEIVED LIKES
// ======================================================

test(
  'received likes are database-backed, owner-scoped, and visibility-filtered',
  async () => {
    // targetA has already become matched with the viewer in Test 3.
    // The received-Likes endpoint should exclude matched users.
    //
    // Add a fresh independent incoming Like so this test can verify
    // incoming Likes without relying on a matched sender.

    const incomingLike = await json(
      '/api/discover/swipe',
      'POST',
      users.receivedOnly,
      {
        targetUserId: users.viewer.id,
        action: 'like',
      },
    );

    assert.equal(
      incomingLike.status,
      200,
      JSON.stringify(incomingLike.body),
    );

    const received = await request(
      '/api/me/received-likes?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(received.status, 200);
    assert.equal(received.body.data.total, 2);

    assert.deepEqual(
      new Set(
        received.body.data.profiles.map((profile) => profile.id),
      ),
      new Set([
        String(users.otherOwner.id),
        String(users.receivedOnly.id),
      ]),
    );

    // targetA is matched and must not appear in received Likes.
    assert.equal(
      received.body.data.profiles.some(
        (profile) => profile.id === String(users.targetA.id),
      ),
      false,
    );

    assert.equal(
      received.body.data.profiles.some(
        (profile) => profile.id === String(users.targetB.id),
      ),
      false,
    );

    // Blocking otherOwner must hide that sender.

    await models.Block.create({
      blockerUserId: users.viewer.id,
      blockedUserId: users.otherOwner.id,
    });

    const filtered = await request(
      '/api/me/received-likes?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(filtered.status, 200);
    assert.equal(filtered.body.data.total, 1);

    assert.equal(
      filtered.body.data.profiles.some(
        (profile) => profile.id === String(users.otherOwner.id),
      ),
      false,
    );

    assert.ok(
      filtered.body.data.profiles.some(
        (profile) => profile.id === String(users.receivedOnly.id),
      ),
    );

    await models.Block.destroy({
      where: {
        blockerUserId: users.viewer.id,
        blockedUserId: users.otherOwner.id,
      },
    });
  },
);

// ======================================================
// TEST 5: SUPER LIKES
// ======================================================

test(
  'Super Likes use DiscoverActions, paginate, deduplicate, and enforce visibility',
  async () => {
    // Clear prior viewer actions to isolate Super Like assertions.

    await models.DiscoverAction.destroy({
      where: {
        actorUserId: users.viewer.id,
      },
    });

    await models.Notification.destroy({
      where: {
        actorUserId: users.viewer.id,
        type: {
          [Op.in]: ['new_like', 'new_super_like'],
        },
      },
      force: true,
    });

    // Verify the viewer's premium entitlements.

    const { hasEntitlement } = require('../src/services/entitlementService');

    assert.equal(
      await hasEntitlement(users.viewer.id, 'premium'),
      true,
      'Viewer must have premium entitlement.',
    );

    assert.equal(
      await hasEntitlement(users.viewer.id, 'unlimitedSuperLikes'),
      true,
      'Viewer must have unlimited Super Likes entitlement.',
    );

    // otherOwner sends a Super Like to outsider.

    const otherOwnerSuperLike = await json(
      '/api/discover/swipe',
      'POST',
      users.otherOwner,
      {
        targetUserId: users.outsider.id,
        action: 'superLike',
      },
    );

    assert.equal(
      otherOwnerSuperLike.status,
      200,
      JSON.stringify(otherOwnerSuperLike.body),
    );

    // Viewer sends three Super Likes.

    for (const target of [
      users.targetA,
      users.targetB,
      users.targetC,
    ]) {
      const response = await json(
        '/api/discover/swipe',
        'POST',
        users.viewer,
        {
          targetUserId: target.id,
          action: 'superLike',
        },
      );

      assert.equal(
        response.status,
        200,
        JSON.stringify(response.body),
      );
    }

    const persisted = await models.DiscoverAction.findAll({
      where: {
        actorUserId: users.viewer.id,
        action: 'superLike',
      },
    });

    assert.equal(persisted.length, 3);

    assert.deepEqual(
      new Set(
        persisted.map((row) => Number(row.targetUserId)),
      ),
      new Set([
        users.targetA.id,
        users.targetB.id,
        users.targetC.id,
      ]),
    );

    assert.ok(
      persisted.every((row) => row.createdAt && row.updatedAt),
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: [
            users.targetA.id,
            users.targetB.id,
            users.targetC.id,
          ],
          actorUserId: users.viewer.id,
          type: 'new_super_like',
        },
      }),
      2,
    );

    // Repeated Super Like must not duplicate the action or notification.

    const repeat = await json(
      '/api/discover/swipe',
      'POST',
      users.viewer,
      {
        targetUserId: users.targetB.id,
        action: 'superLike',
      },
    );

    assert.equal(
      repeat.status,
      200,
      JSON.stringify(repeat.body),
    );

    assert.equal(
      await models.DiscoverAction.count({
        where: {
          actorUserId: users.viewer.id,
          targetUserId: users.targetB.id,
          action: 'superLike',
        },
      }),
      1,
    );

    assert.equal(
      await models.Notification.count({
        where: {
          userId: users.targetB.id,
          actorUserId: users.viewer.id,
          type: 'new_super_like',
        },
      }),
      1,
    );

    // Pagination.

    const pageOne = await request(
      '/api/me/super-likes?page=1&limit=2',
      {
        headers: auth(users.viewer),
      },
    );

    const pageTwo = await request(
      '/api/me/super-likes?page=2&limit=2',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(pageOne.status, 200);
    assert.equal(pageOne.body.data.profiles.length, 2);
    assert.equal(pageOne.body.data.pagination.hasMore, true);

    assert.equal(pageTwo.status, 200);
    assert.equal(pageTwo.body.data.profiles.length, 1);
    assert.equal(pageTwo.body.data.pagination.hasMore, false);

    // Blocked profiles must be hidden.

    await models.Block.create({
      blockerUserId: users.viewer.id,
      blockedUserId: users.targetB.id,
    });

    const blockedList = await request(
      '/api/me/super-likes?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(
      blockedList.body.data.profiles.some(
        (profile) => profile.id === String(users.targetB.id),
      ),
      false,
    );

    await models.Block.destroy({
      where: {
        blockerUserId: users.viewer.id,
        blockedUserId: users.targetB.id,
      },
    });

    // Deactivated profiles must be hidden.

    await users.targetC.update({
      accountStatus: 'deactivated',
      deactivatedAt: new Date(),
    });

    const inactiveList = await request(
      '/api/me/super-likes?page=1&limit=20',
      {
        headers: auth(users.viewer),
      },
    );

    assert.equal(
      inactiveList.body.data.profiles.some(
        (profile) => profile.id === String(users.targetC.id),
      ),
      false,
    );

    await users.targetC.update({
      accountStatus: 'active',
      deactivatedAt: null,
    });

    // Incomplete profiles must not be Super Liked.

    await models.OnboardingProfile.update(
      {
        onboardingCompleted: false,
      },
      {
        where: {
          userId: users.outsider.id,
        },
      },
    );

    const incomplete = await json(
      '/api/discover/swipe',
      'POST',
      users.viewer,
      {
        targetUserId: users.outsider.id,
        action: 'superLike',
      },
    );

    assert.equal(incomplete.status, 404);

    assert.equal(
      incomplete.body.code,
      'PROFILE_NOT_DISCOVERABLE',
    );

    assert.equal(
      await models.DiscoverAction.count({
        where: {
          actorUserId: users.viewer.id,
          targetUserId: users.outsider.id,
        },
      }),
      0,
    );

    await models.OnboardingProfile.update(
      {
        onboardingCompleted: true,
      },
      {
        where: {
          userId: users.outsider.id,
        },
      },
    );

    // A block in the opposite direction must also prevent Super Likes.

    await models.Block.create({
      blockerUserId: users.outsider.id,
      blockedUserId: users.viewer.id,
    });

    const blocked = await json(
      '/api/discover/swipe',
      'POST',
      users.viewer,
      {
        targetUserId: users.outsider.id,
        action: 'superLike',
      },
    );

    assert.equal(blocked.status, 404);

    assert.equal(
      blocked.body.code,
      'PROFILE_NOT_DISCOVERABLE',
    );

    assert.equal(
      await models.DiscoverAction.count({
        where: {
          actorUserId: users.viewer.id,
          targetUserId: users.outsider.id,
        },
      }),
      0,
    );

    await models.Block.destroy({
      where: {
        blockerUserId: users.outsider.id,
        blockedUserId: users.viewer.id,
      },
    });
  },
);
