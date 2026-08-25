const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Admin financial integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
require('../src/config/env');
const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server;
let baseUrl;
let financeAdmin;
let limitedAdmin;
let financeRole;
let limitedRole;
let user;
let plan;
let subscription;
let paid;
let failed;
let password;

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      ...(options.accessToken ? { authorization: `Bearer ${options.accessToken}` } : {}),
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
    ...(options.body ? { body: JSON.stringify(options.body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

async function login(administrator) {
  const response = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(response.status, 200);
  return response.body.data.accessToken;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  const {
    Administrator, AdminRole, AdminPermission, User, SubscriptionPlan,
    Subscription, Payment, PaymentEvent,
  } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  password = `FinanceAdmin!${suffix}Aa1`;
  financeRole = await AdminRole.create({
    key: `finance_admin_${suffix}`,
    name: 'Finance Admin Integration Role',
    isActive: true,
  });
  limitedRole = await AdminRole.create({
    key: `finance_limited_${suffix}`,
    name: 'Limited Finance Integration Role',
    isActive: true,
  });
  const readKeys = ['payments.transactions.view', 'payments.transactions.details.view'];
  const elevatedKeys = [
    ...readKeys,
    'payments.transactions.sensitiveFields.view',
    'payments.audit.view',
    'membership.plans.view',
  ];
  const readPermissions = await AdminPermission.findAll({ where: { key: readKeys } });
  const elevatedPermissions = await AdminPermission.findAll({ where: { key: elevatedKeys } });
  assert.equal(readPermissions.length, readKeys.length);
  assert.equal(elevatedPermissions.length, elevatedKeys.length);
  await limitedRole.addPermissions(readPermissions);
  await financeRole.addPermissions(elevatedPermissions);
  financeAdmin = await Administrator.create({
    name: 'Finance Integration Admin',
    email: `finance.admin.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(password, 12),
  });
  limitedAdmin = await Administrator.create({
    name: 'Limited Finance Integration Admin',
    email: `finance.limited.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(password, 12),
  });
  await financeAdmin.addRole(financeRole);
  await limitedAdmin.addRole(limitedRole);
  user = await User.create({
    name: `Financial Consumer ${suffix}`,
    email: `financial.consumer.${suffix}@example.test`,
    phoneNumber: `+9197${String(crypto.randomInt(10000000, 99999999))}`,
    passwordHash: await bcrypt.hash(`Client!${suffix}Aa1`, 4),
    isVerified: true,
    accountStatus: 'active',
  });
  plan = await SubscriptionPlan.create({
    id: `premium_${suffix}`,
    name: 'premium',
    displayName: 'Premium Integration Plan',
    description: 'Authoritative integration plan.',
    priceMinor: 129900,
    currency: 'INR',
    billingPeriod: 'month',
    billingInterval: 1,
    features: ['Verified plan feature'],
    entitlements: { dailyLikes: 25 },
    active: true,
    sortOrder: 9000,
  });
  const now = new Date();
  subscription = await Subscription.create({
    userId: user.id,
    planId: plan.id,
    status: 'active',
    provider: 'razorpay',
    providerCustomerId: `cust_${suffix}`,
    providerSubscriptionId: `sub_${suffix}`,
    startedAt: now,
    currentPeriodStart: now,
    currentPeriodEnd: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000),
    autoRenew: true,
  });
  paid = await Payment.create({
    userId: user.id,
    planId: plan.id,
    productType: 'subscription',
    productReferenceId: plan.id,
    provider: 'razorpay',
    providerOrderId: `order_${suffix}`,
    providerPaymentId: `pay_${suffix}`,
    amountMinor: 129900,
    currency: 'INR',
    status: 'paid',
    idempotencyKey: `paid_${suffix}`,
    verifiedAt: now,
    metadata: { providerStatus: 'captured', secretLikeValue: 'must-not-leave-backend' },
  });
  failed = await Payment.create({
    userId: user.id,
    planId: plan.id,
    productType: 'subscription',
    productReferenceId: plan.id,
    provider: 'razorpay',
    providerOrderId: `failed_order_${suffix}`,
    amountMinor: 129900,
    currency: 'INR',
    status: 'failed',
    idempotencyKey: `failed_${suffix}`,
    failureCode: 'PAYMENT_DECLINED',
    failureMessage: 'Provider-private failure detail.',
  });
  await PaymentEvent.create({
    paymentId: paid.id,
    provider: 'razorpay',
    providerEventId: `event_${suffix}`,
    eventType: 'payment.captured',
    payloadHash: crypto.createHash('sha256').update(suffix).digest('hex'),
    payload: { payment: { card: 'raw-provider-payload-must-not-be-returned' } },
    status: 'processed',
    processedAt: now,
  });
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const {
    AdminAuditLog, AdminRefreshToken, Administrator, AdminRole, PaymentEvent,
    Payment, Subscription, SubscriptionPlan, RefreshToken, User,
  } = getModels();
  if (paid || failed) await PaymentEvent.destroy({ where: { paymentId: [paid?.id, failed?.id].filter(Boolean) } });
  if (user) {
    await Payment.destroy({ where: { userId: user.id } });
    await Subscription.destroy({ where: { userId: user.id } });
    await RefreshToken.destroy({ where: { userId: user.id } });
    await User.destroy({ where: { id: user.id } });
  }
  if (plan) await SubscriptionPlan.destroy({ where: { id: plan.id } });
  for (const administrator of [financeAdmin, limitedAdmin]) {
    if (!administrator) continue;
    await AdminAuditLog.destroy({ where: { administratorId: administrator.id } });
    await AdminRefreshToken.destroy({ where: { administratorId: administrator.id }, force: true });
    await administrator.setRoles([]);
    await Administrator.destroy({ where: { id: administrator.id } });
  }
  for (const role of [financeRole, limitedRole]) {
    if (!role) continue;
    await role.setPermissions([]);
    await AdminRole.destroy({ where: { id: role.id } });
  }
  await getSequelize().close();
});

test('financial Admin reads are database-backed, projected by RBAC, filtered, and audited', async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
  const financeToken = await login(financeAdmin);
  const limitedToken = await login(limitedAdmin);

  const planList = await request(`/api/admin/v1/membership-plans?search=${encodeURIComponent('Premium Integration')}&status=active&currency=INR&page=1&pageSize=20`, {
    accessToken: financeToken,
  });
  assert.equal(planList.status, 200);
  const listedPlan = planList.body.data.items.find((item) => item.planId === plan.id);
  assert.ok(listedPlan);
  assert.equal(listedPlan.price.amountMinor, 129900);
  assert.equal(listedPlan.activeMemberships, 1);
  assert.deepEqual(listedPlan.allowedActions, []);
  const deniedPlans = await request('/api/admin/v1/membership-plans', { accessToken: limitedToken });
  assert.equal(deniedPlans.status, 403);

  const from = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const to = new Date(Date.now() + 60 * 60 * 1000).toISOString();
  const list = await request(`/api/admin/v1/payment-transactions?status=paid&currency=INR&planId=${encodeURIComponent(plan.id)}&from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&search=${user.id}&page=1&pageSize=1&sortBy=createdAt&sortDirection=desc`, {
    accessToken: limitedToken,
  });
  assert.equal(list.status, 200);
  assert.equal(list.body.data.items.length, 1);
  assert.equal(list.body.data.pagination.totalItems, 1);
  const projected = list.body.data.items[0];
  assert.equal(projected.transactionId, String(paid.id));
  assert.equal(projected.membershipId, String(subscription.id));
  assert.notEqual(projected.maskedUserSummary, user.email);
  assert.equal(projected.maskedUserSummary.includes(user.email), false);
  assert.equal(projected.providerTransactionId, undefined);
  assert.equal(projected.reconciliationHistory, undefined);
  assert.equal(projected.refundEligibility.eligible, false);
  assert.deepEqual(projected.allowedActions, []);

  const deniedSensitive = await request(`/api/admin/v1/payment-transactions?includeSensitive=true`, { accessToken: limitedToken });
  assert.equal(deniedSensitive.status, 403);
  const deniedProviderFilter = await request(`/api/admin/v1/payment-transactions?providerReference=${encodeURIComponent(paid.providerPaymentId)}`, { accessToken: limitedToken });
  assert.equal(deniedProviderFilter.status, 403);
  const deniedHistory = await request(`/api/admin/v1/payment-transactions/${paid.id}?includeReconciliation=true`, { accessToken: limitedToken });
  assert.equal(deniedHistory.status, 403);

  const detail = await request(`/api/admin/v1/payment-transactions/${paid.id}?includeSensitive=true&includeReconciliation=true`, {
    accessToken: financeToken,
  });
  assert.equal(detail.status, 200);
  const transaction = detail.body.data.transaction;
  assert.equal(transaction.providerTransactionId, paid.providerPaymentId);
  assert.equal(transaction.providerOrderId, paid.providerOrderId);
  assert.equal(transaction.reconciliationStatus, 'processed');
  assert.equal(transaction.reconciliationHistory.length, 1);
  assert.equal(transaction.reconciliationHistory[0].providerEventId.startsWith('event_'), true);
  assert.equal(JSON.stringify(transaction).includes('raw-provider-payload'), false);
  assert.equal(JSON.stringify(transaction).includes('Provider-private failure detail'), false);
  const { AdminAuditLog } = getModels();
  assert.equal(await AdminAuditLog.count({
    where: { administratorId: financeAdmin.id, action: 'admin.payments.transaction.read', targetId: String(paid.id) },
  }), 1);

  const failedList = await request('/api/admin/v1/payment-transactions?status=failed&hasRefund=false', { accessToken: financeToken });
  assert.equal(failedList.status, 200);
  const failedProjection = failedList.body.data.items.find((item) => item.transactionId === String(failed.id));
  assert.equal(failedProjection.safeFailureCategory, 'PAYMENT_DECLINED');
  assert.equal(JSON.stringify(failedProjection).includes('Provider-private failure detail'), false);

  const refund = await request(`/api/admin/v1/payment-transactions/${paid.id}/refund`, {
    method: 'POST',
    accessToken: financeToken,
    body: { amountMinor: 129900, currency: 'INR', reasonId: 'anything' },
  });
  assert.equal(refund.status, 404);
  await paid.reload();
  assert.equal(paid.status, 'paid');
});
