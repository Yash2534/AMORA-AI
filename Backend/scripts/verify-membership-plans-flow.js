require('../src/config/bootstrapEnv');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');
const { closeRealtimeServer } = require('../src/realtime/realtimeHub');

if (!process.argv.includes('--confirm-development-db') || process.env.NODE_ENV === 'production') {
  throw new Error('Pass --confirm-development-db and run only against the development schema.');
}

let server;
let models;
const userIds = [];
const password = 'Membership-QA-2026!';

async function createUser(name) {
  const suffix = `${Date.now()}_${Math.random().toString(36).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@membership-plans-verification.test`,
    phoneNumber: '',
    passwordHash: await bcrypt.hash(password, 4),
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
  });
  userIds.push(user.id);
  return user;
}

async function api(baseUrl, path, { method = 'GET', accessToken, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(accessToken ? { authorization: `Bearer ${accessToken}` } : {}),
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

async function login(baseUrl, user) {
  const response = await api(baseUrl, '/api/auth/login', {
    method: 'POST',
    body: { email: user.email, password },
  });
  assert.equal(response.status, 200, JSON.stringify(response.body));
  const payload = jwt.verify(response.body.data.accessToken, process.env.JWT_SECRET);
  assert.equal(Number(payload.sub), user.id);
  return response.body.data;
}

async function cleanup() {
  if (!models || !userIds.length) return;
  await models.Subscription.destroy({ where: { userId: userIds } });
  await models.RefreshToken.destroy({ where: { userId: userIds } });
  await models.OnboardingProfile.destroy({ where: { userId: userIds } });
  await models.User.destroy({ where: { id: userIds } });
}

async function main() {
  await initializeDatabase();
  models = getModels();
  const databasePlans = await models.SubscriptionPlan.findAll({
    where: { active: true },
    order: [['sortOrder', 'ASC'], ['id', 'ASC']],
  });
  assert.ok(databasePlans.length > 0, 'The development SubscriptionPlans catalog is empty.');
  const plan = databasePlans[0];
  const userA = await createUser('Membership Verification User A');
  const userB = await createUser('Membership Verification User B');
  const expiredUser = await createUser('Membership Verification Expired User');
  const now = new Date();
  const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const active = await models.Subscription.create({
    userId: userA.id,
    planId: plan.id,
    status: 'active',
    provider: 'razorpay',
    startedAt: now,
    currentPeriodStart: now,
    currentPeriodEnd: periodEnd,
    autoRenew: true,
    cancelAtPeriodEnd: false,
  });
  const expiredEnd = new Date(now.getTime() - 60 * 60 * 1000);
  const expired = await models.Subscription.create({
    userId: expiredUser.id,
    planId: plan.id,
    status: 'active',
    provider: 'razorpay',
    startedAt: new Date(now.getTime() - 31 * 24 * 60 * 60 * 1000),
    currentPeriodStart: new Date(now.getTime() - 31 * 24 * 60 * 60 * 1000),
    currentPeriodEnd: expiredEnd,
    autoRenew: true,
    cancelAtPeriodEnd: false,
  });

  server = createHttpServer();
  server.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  const plansResponse = await api(baseUrl, '/api/subscriptions/plans');
  assert.equal(plansResponse.status, 200, JSON.stringify(plansResponse.body));
  assert.deepEqual(plansResponse.body.data.plans.map((value) => value.id), databasePlans.map((value) => value.id));
  assert.ok(plansResponse.body.data.plans.every((value) => Array.isArray(value.features)));
  assert.ok(plansResponse.body.data.plans.every((value) => value.entitlements && typeof value.entitlements === 'object' && !Array.isArray(value.entitlements)));
  assert.ok(plansResponse.body.data.plans.every((value) => Number.isInteger(value.priceMinor) && Number.isInteger(value.billingInterval)));

  const sessionA = await login(baseUrl, userA);
  const membershipA = await api(baseUrl, '/api/subscriptions/me', { accessToken: sessionA.accessToken });
  assert.equal(membershipA.status, 200, JSON.stringify(membershipA.body));
  assert.equal(membershipA.body.data.membership.id, String(active.id));
  assert.equal(membershipA.body.data.membership.planId, plan.id);
  assert.equal(membershipA.body.data.membership.plan.id, plan.id);
  assert.equal(membershipA.body.data.membership.status, 'active');
  assert.equal(membershipA.body.data.membership.premium, true);
  assert.equal(
    Math.floor(new Date(membershipA.body.data.membership.currentPeriodEnd).getTime() / 1000),
    Math.floor(periodEnd.getTime() / 1000),
  );

  const sessionB = await login(baseUrl, userB);
  const membershipB = await api(baseUrl, `/api/subscriptions/me?userId=${userA.id}`, { accessToken: sessionB.accessToken });
  assert.equal(membershipB.status, 200, JSON.stringify(membershipB.body));
  assert.equal(membershipB.body.data.membership.status, 'none');
  assert.equal(membershipB.body.data.membership.plan, null);

  const expiredSession = await login(baseUrl, expiredUser);
  const expiredResponse = await api(baseUrl, '/api/subscriptions/me', { accessToken: expiredSession.accessToken });
  assert.equal(expiredResponse.status, 200, JSON.stringify(expiredResponse.body));
  assert.equal(expiredResponse.body.data.membership.status, 'expired');
  assert.equal(expiredResponse.body.data.membership.premium, false);
  await expired.reload();
  assert.equal(expired.status, 'expired');
  assert.equal(expired.autoRenew, false);

  const noToken = await api(baseUrl, '/api/subscriptions/me');
  assert.equal(noToken.status, 401);
  const invalidToken = await api(baseUrl, '/api/subscriptions/me', { accessToken: 'invalid.jwt.token' });
  assert.equal(invalidToken.status, 401);

  const logout = await api(baseUrl, '/api/auth/logout', {
    method: 'POST',
    accessToken: sessionA.accessToken,
    body: { refreshToken: sessionA.refreshToken },
  });
  assert.equal(logout.status, 200, JSON.stringify(logout.body));
  const newSessionA = await login(baseUrl, userA);
  const afterLogin = await api(baseUrl, '/api/subscriptions/me', { accessToken: newSessionA.accessToken });
  assert.equal(afterLogin.status, 200, JSON.stringify(afterLogin.body));
  assert.equal(afterLogin.body.data.membership.id, String(active.id));

  const persisted = await models.Subscription.findOne({ where: { userId: userA.id }, include: [{ model: models.SubscriptionPlan, as: 'plan' }] });
  assert.ok(persisted);
  assert.equal(persisted.planId, plan.id);
  assert.equal(persisted.plan.id, plan.id);

  console.log(JSON.stringify({
    database: process.env.DB_NAME,
    endpoints: { plans: 'GET /api/subscriptions/plans', membership: 'GET /api/subscriptions/me' },
    plans: {
      databaseCount: databasePlans.length,
      apiCount: plansResponse.body.data.plans.length,
      typedFeatures: true,
      typedEntitlements: true,
      numericPriceAndDuration: true,
    },
    membership: {
      authenticatedUserId: userA.id,
      subscriptionId: String(active.id),
      planId: plan.id,
      status: membershipA.body.data.membership.status,
      currentPeriodEnd: membershipA.body.data.membership.currentPeriodEnd,
    },
    noMembershipState: membershipB.body.data.membership.status,
    userIsolation: membershipB.body.data.membership.plan === null,
    expiredStatusPersisted: expired.status === 'expired',
    noTokenStatus: noToken.status,
    invalidTokenStatus: invalidToken.status,
    logoutLoginPersistence: afterLogin.body.data.membership.id === String(active.id),
  }, null, 2));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (server?.listening) await new Promise((resolve) => server.close(resolve));
    await closeRealtimeServer().catch(() => {});
    await cleanup().catch((error) => {
      console.error('[Cleanup]', error.message);
      process.exitCode = 1;
    });
    try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
  });
