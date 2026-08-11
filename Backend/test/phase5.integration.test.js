const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) throw new Error('Phase 5 integration tests require a separate TEST_DB_NAME containing "test".');
process.env.DB_NAME = testDatabase; process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { setPaymentProviderForTests, clearPaymentProviderForTests } = require('../src/services/razorpayProvider');
const { postWalletTransaction } = require('../src/services/walletService');
const catalog = require('../scripts/seed-monetization-catalog');

let models; let server; let baseUrl; const users = {}; const userIds = []; const providerPayments = new Map(); let nextOrder = 1;
const tokenFor = (user) => jwt.sign({ sub: user.id, ver: user.tokenVersion || 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });
const request = async (path, options = {}) => { const response = await fetch(`${baseUrl}${path}`, options); return { status: response.status, body: await response.json() }; };
const json = (path, method, user, body, headers = {}) => request(path, { method, headers: { ...auth(user), 'content-type': 'application/json', ...headers }, body: body === undefined ? undefined : JSON.stringify(body) });
const idem = (label) => `phase5:${label}:${Date.now()}`;

async function createUser(key) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({ name: `P5 ${key}`, email: `${suffix}@phase5.test`, phoneNumber: '', authProvider: 'local', isVerified: true, termsAcceptedAt: new Date() });
  userIds.push(user.id); users[key] = user;
  await models.OnboardingProfile.create({ userId: user.id, birthDate: '1997-05-12', gender: 'Woman', interestedIn: ['Men'], relationshipGoals: ['long_term'], city: 'Ahmedabad', profession: 'Engineer', education: 'Graduate', hometown: 'Ahmedabad', interests: ['music'], lifestyle: {}, prompts: { idealDate: 'Coffee' }, pronouns: ['she/her'], valuedQualities: ['kindness'], loveLanguages: ['quality_time'], preferredTalkingHours: ['evening'], communicationStyle: 'calls', photos: ['/uploads/phase5.jpg'], stage: 'complete', onboardingCompleted: true });
  return user;
}

async function credit(user, amount, key) {
  await models.Wallet.sequelize.transaction((transaction) => postWalletTransaction({ userId: user.id, direction: 'credit', amount, type: 'adjustment', referenceType: 'test_fixture', referenceId: key, idempotencyKey: key, description: 'Phase 5 controlled fixture' }, transaction));
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true }); await initializeDatabase(); models = getModels();
  await Promise.all([createUser('buyer'), createUser('recipient'), createUser('empty'), createUser('other'), createUser('renewal')]);
  for (const value of catalog.plans) await models.SubscriptionPlan.upsert(value);
  for (const value of catalog.walletProducts) await models.WalletProduct.upsert(value);
  for (const value of catalog.boosts) await models.BoostProduct.upsert(value);
  for (const value of catalog.gifts) await models.Gift.upsert(value);
  await credit(users.buyer, 5000, idem('initial-credit'));
  setPaymentProviderForTests({
    name: 'razorpay', isConfigured: () => true, publicKey: () => 'rzp_test_public',
    createOrder: async ({ amount, currency }) => ({ id: `order_p5_${nextOrder++}`, amount, currency, status: 'created' }),
    verifyCheckoutSignature: ({ signature }) => signature === 'valid-signature',
    fetchPayment: async (paymentId) => providerPayments.get(paymentId),
    verifyWebhookSignature: (_raw, signature) => signature === 'valid-webhook',
  });
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  clearPaymentProviderForTests(); if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    await models.Boost.destroy({ where: { userId: userIds } }); await models.GiftTransaction.destroy({ where: { [Op.or]: [{ senderId: userIds }, { recipientId: userIds }] } });
    await models.BoostEntitlement.destroy({ where: { userId: userIds } }); await models.PaymentEvent.destroy({ where: { paymentId: (await models.Payment.findAll({ where: { userId: userIds }, attributes: ['id'] })).map((row) => row.id) } });
    await models.Subscription.destroy({ where: { userId: userIds } }); await models.WalletTransaction.destroy({ where: { userId: userIds } }); await models.Wallet.destroy({ where: { userId: userIds } }); await models.Payment.destroy({ where: { userId: userIds } });
    await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: userIds }, { blockedUserId: userIds }] } }); await models.OnboardingProfile.destroy({ where: { userId: userIds } }); await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('plans and membership are database-backed and private membership requires auth', async () => {
  const plans = await request('/api/subscriptions/plans'); assert.equal(plans.status, 200); assert.equal(plans.body.data.plans.length, 3); assert.ok(plans.body.data.plans.every((plan) => plan.active));
  assert.equal((await request('/api/subscriptions/me')).status, 401);
  const membership = await request('/api/subscriptions/me', { headers: auth(users.buyer) }); assert.equal(membership.status, 200); assert.equal(membership.body.data.membership.status, 'none');
});

test('payment order uses server price, persists audit data, and is idempotent', async () => {
  const key = idem('subscription-order'); const body = { planId: 'amoraa_plus_monthly', amount: 1, currency: 'USD', idempotencyKey: key };
  const first = await json('/api/payments/orders', 'POST', users.buyer, body); assert.equal(first.status, 201); assert.equal(first.body.data.order.amountMinor, 119900); assert.equal(first.body.data.order.currency, 'INR');
  const second = await json('/api/payments/orders', 'POST', users.buyer, body); assert.equal(second.body.data.order.providerOrderId, first.body.data.order.providerOrderId);
  const persisted = await models.Payment.findByPk(first.body.data.order.paymentId); assert.equal(persisted.amountMinor, 119900); assert.equal(persisted.idempotencyKey, key);
  assert.equal((await json('/api/payments/orders', 'POST', users.buyer, { planId: 'missing', idempotencyKey: idem('missing-plan') })).status, 404);
  users.subscriptionOrder = first.body.data.order;
});

test('provider verification rejects tampering and activates membership exactly once', async () => {
  const order = users.subscriptionOrder; providerPayments.set('pay_p5_subscription', { id: 'pay_p5_subscription', order_id: order.providerOrderId, amount: order.amountMinor, currency: order.currency, status: 'captured' });
  assert.equal((await json('/api/payments/verify', 'POST', users.buyer, { providerOrderId: order.providerOrderId, providerPaymentId: 'pay_p5_subscription', signature: 'bad' })).status, 400);
  const verified = await json('/api/payments/verify', 'POST', users.buyer, { providerOrderId: order.providerOrderId, providerPaymentId: 'pay_p5_subscription', signature: 'valid-signature' }); assert.equal(verified.status, 200); assert.equal(verified.body.data.membership.status, 'active'); assert.equal(verified.body.data.membership.premium, true);
  const duplicate = await json('/api/payments/verify', 'POST', users.buyer, { providerOrderId: order.providerOrderId, providerPaymentId: 'pay_p5_subscription', signature: 'valid-signature' }); assert.equal(duplicate.status, 200); assert.equal(await models.Subscription.count({ where: { userId: users.buyer.id } }), 1);
  assert.equal((await json('/api/payments/verify', 'POST', users.other, { providerOrderId: order.providerOrderId, providerPaymentId: 'pay_p5_subscription', signature: 'valid-signature' })).status, 404);
});

test('provider verification rejects exact amount and currency mismatches', async () => {
  const created = await json('/api/payments/orders', 'POST', users.other, { planId: 'amoraa_plus_monthly', idempotencyKey: idem('mismatch-order') });
  const order = created.body.data.order;
  providerPayments.set('pay_p5_mismatch', { id: 'pay_p5_mismatch', order_id: order.providerOrderId, amount: order.amountMinor - 1, currency: 'USD', status: 'captured' });
  const result = await json('/api/payments/verify', 'POST', users.other, { providerOrderId: order.providerOrderId, providerPaymentId: 'pay_p5_mismatch', signature: 'valid-signature' });
  assert.equal(result.status, 400); assert.equal(result.body.code, 'PAYMENT_MISMATCH'); assert.equal(await models.Subscription.count({ where: { userId: users.other.id } }), 0);
});

test('cancel and restore preserve paid access until period end', async () => {
  const cancelled = await json('/api/subscriptions/cancel', 'POST', users.buyer); assert.equal(cancelled.status, 200); assert.equal(cancelled.body.data.membership.cancelAtPeriodEnd, true); assert.equal(cancelled.body.data.membership.premium, true);
  const restored = await json('/api/subscriptions/restore', 'POST', users.buyer); assert.equal(restored.status, 200); assert.equal(restored.body.data.membership.status, 'cancelled');
});

test('wallet is private, paginated, and redemption is transactional/idempotent', async () => {
  assert.equal((await request('/api/wallet')).status, 401); const before = await request('/api/wallet', { headers: auth(users.buyer) }); const start = before.body.data.wallet.balance;
  const key = idem('redeem'); const redeemed = await json('/api/wallet/redemptions', 'POST', users.buyer, { productId: 'redeem_boost_30', idempotencyKey: key }); assert.equal(redeemed.status, 200); assert.equal(redeemed.body.data.wallet.balance, start - 299);
  const duplicate = await json('/api/wallet/redemptions', 'POST', users.buyer, { productId: 'redeem_boost_30', idempotencyKey: key }); assert.equal(duplicate.status, 200); assert.equal(duplicate.body.data.wallet.balance, start - 299);
  const history = await request('/api/wallet/transactions?page=1&limit=1', { headers: auth(users.buyer) }); assert.equal(history.status, 200); assert.equal(history.body.data.transactions.length, 1); assert.equal(history.body.data.pagination.hasMore, true);
  assert.equal((await json('/api/wallet/redemptions', 'POST', users.empty, { productId: 'redeem_boost_30', idempotencyKey: idem('insufficient') })).status, 409);
});

test('verified top-up credits wallet only after provider capture', async () => {
  const orderResponse = await json('/api/wallet/top-up/orders', 'POST', users.empty, { productId: 'credits_100', idempotencyKey: idem('topup') }); assert.equal(orderResponse.status, 201); const order = orderResponse.body.data.order;
  assert.equal((await request('/api/wallet', { headers: auth(users.empty) })).body.data.wallet.balance, 0);
  providerPayments.set('pay_p5_topup', { id: 'pay_p5_topup', order_id: order.providerOrderId, amount: order.amountMinor, currency: order.currency, status: 'captured' });
  assert.equal((await json('/api/payments/verify', 'POST', users.empty, { providerOrderId: order.providerOrderId, providerPaymentId: 'pay_p5_topup', signature: 'valid-signature' })).status, 200);
  assert.equal((await request('/api/wallet', { headers: auth(users.empty) })).body.data.wallet.balance, 100);
});

test('boost contract, authentication, entitlement consumption, and retries are database-backed', async () => {
  const unauthenticated = await request('/api/discover/boost', { method: 'POST', headers: { 'content-type': 'application/json', 'Idempotency-Key': idem('unauthenticated') } });
  assert.equal(unauthenticated.status, 401);

  const missing = await json('/api/discover/boost', 'POST', users.buyer);
  assert.equal(missing.status, 400); assert.equal(missing.body.code, 'IDEMPOTENCY_KEY_REQUIRED');
  const invalid = await json('/api/discover/boost', 'POST', users.buyer, undefined, { 'Idempotency-Key': 'short' });
  assert.equal(invalid.status, 400); assert.equal(invalid.body.code, 'IDEMPOTENCY_KEY_REQUIRED');

  const noEntitlement = await json('/api/discover/boost', 'POST', users.other, undefined, { 'Idempotency-Key': idem('no-boost') });
  assert.equal(noEntitlement.status, 402); assert.equal(noEntitlement.body.code, 'BOOST_ENTITLEMENT_REQUIRED');
  const expiredEntitlement = await models.BoostEntitlement.create({ userId: users.other.id, source: 'admin', quantity: 1, remainingQuantity: 1, durationMinutes: 30, status: 'active', expiresAt: new Date(Date.now() - 60000), idempotencyKey: idem('expired-entitlement') });
  const expired = await json('/api/discover/boost', 'POST', users.other, undefined, { 'Idempotency-Key': idem('expired-attempt') });
  assert.equal(expired.status, 402); await expiredEntitlement.reload(); assert.equal(expiredEntitlement.remainingQuantity, 1);

  await users.other.update({ accountStatus: 'deactivated', deactivatedAt: new Date() });
  const inactive = await json('/api/discover/boost', 'POST', users.other, undefined, { 'Idempotency-Key': idem('inactive') });
  assert.equal(inactive.status, 403); assert.equal(inactive.body.code, 'ACCOUNT_DEACTIVATED');
  await users.other.update({ accountStatus: 'active', deactivatedAt: null });

  const inventory = await request('/api/boosts/me', { headers: auth(users.buyer) }); assert.ok(inventory.body.data.boost.available >= 1);
  const entitlement = await models.BoostEntitlement.findOne({ where: { userId: users.buyer.id, status: 'active', remainingQuantity: { [Op.gt]: 0 } }, order: [['id', 'ASC']] });
  const beforeRemaining = Number(entitlement.remainingQuantity);
  const beforeBoosts = await models.Boost.count({ where: { userId: users.buyer.id } });
  const key = idem('activate');
  const activated = await json('/api/discover/boost', 'POST', users.buyer, undefined, { 'Idempotency-Key': key });
  assert.equal(activated.status, 200); assert.equal(activated.body.data.active, true); assert.ok(activated.body.data.startedAt); assert.ok(activated.body.data.expiresAt);
  await entitlement.reload(); assert.equal(Number(entitlement.remainingQuantity), beforeRemaining - 1);
  assert.equal(await models.Boost.count({ where: { userId: users.buyer.id } }), beforeBoosts + 1);

  const retried = await json('/api/discover/boost', 'POST', users.buyer, undefined, { 'Idempotency-Key': key });
  assert.equal(retried.status, 200); assert.equal(retried.body.data.expiresAt, activated.body.data.expiresAt);
  await entitlement.reload(); assert.equal(Number(entitlement.remainingQuantity), beforeRemaining - 1);
  assert.equal(await models.Boost.count({ where: { userId: users.buyer.id, idempotencyKey: key } }), 1);

  const alreadyActive = await json('/api/discover/boost', 'POST', users.buyer, undefined, { 'Idempotency-Key': idem('while-active') });
  assert.equal(alreadyActive.status, 200); assert.equal(alreadyActive.body.message, 'Boost is already active.'); assert.equal(alreadyActive.body.data.expiresAt, activated.body.data.expiresAt);
  await entitlement.reload(); assert.equal(Number(entitlement.remainingQuantity), beforeRemaining - 1);

  const renewalEntitlement = await models.BoostEntitlement.create({ userId: users.renewal.id, source: 'admin', quantity: 2, remainingQuantity: 2, durationMinutes: 30, status: 'active', idempotencyKey: idem('renewal-entitlement') });
  const firstKey = idem('renewal-first'); const secondKey = idem('renewal-second');
  const firstActivation = await json('/api/discover/boost', 'POST', users.renewal, undefined, { 'Idempotency-Key': firstKey });
  assert.equal(firstActivation.status, 200);
  await models.Boost.update({ active: false, expiresAt: new Date(Date.now() - 1000) }, { where: { userId: users.renewal.id, idempotencyKey: firstKey } });
  const secondActivation = await json('/api/discover/boost', 'POST', users.renewal, undefined, { 'Idempotency-Key': secondKey });
  assert.equal(secondActivation.status, 200); await renewalEntitlement.reload(); assert.equal(Number(renewalEntitlement.remainingQuantity), 0);
  assert.equal(await models.Boost.count({ where: { userId: users.renewal.id } }), 2);
});

test('gift price is server-owned, blocked recipients are denied, and retry charges once', async () => {
  const catalogResponse = await request('/api/gifts'); assert.equal(catalogResponse.status, 200); assert.ok(catalogResponse.body.data.gifts.some((gift) => gift.id === 'rose_ritual' && gift.priceCredits === 299));
  const before = (await request('/api/wallet', { headers: auth(users.buyer) })).body.data.wallet.balance; const key = idem('rose');
  const sent = await json('/api/gifts/send', 'POST', users.buyer, { recipientId: users.recipient.id, giftId: 'rose_ritual', priceCredits: 1, idempotencyKey: key }); assert.equal(sent.status, 201); assert.equal(sent.body.data.giftTransaction.priceAtPurchase, 299);
  const retried = await json('/api/gifts/send', 'POST', users.buyer, { recipientId: users.recipient.id, giftId: 'rose_ritual', idempotencyKey: key }); assert.equal(retried.status, 201); assert.equal(retried.body.data.wallet.balance, before - 299); assert.equal(await models.GiftTransaction.count({ where: { senderId: users.buyer.id, idempotencyKey: key } }), 1);
  await models.Block.create({ blockerUserId: users.recipient.id, blockedUserId: users.buyer.id }); assert.equal((await json('/api/gifts/send', 'POST', users.buyer, { recipientId: users.recipient.id, giftId: 'rose_ritual', idempotencyKey: idem('blocked') })).status, 403);
});

test('concurrent gift retries and boost activations cannot double-spend value', async () => {
  await models.Block.destroy({ where: { blockerUserId: users.recipient.id, blockedUserId: users.buyer.id } });
  const giftKey = idem('gift-concurrent'); const before = (await request('/api/wallet', { headers: auth(users.buyer) })).body.data.wallet.balance;
  const gifts = await Promise.all([json('/api/gifts/send', 'POST', users.buyer, { recipientId: users.recipient.id, giftId: 'heart_burst', idempotencyKey: giftKey }), json('/api/gifts/send', 'POST', users.buyer, { recipientId: users.recipient.id, giftId: 'heart_burst', idempotencyKey: giftKey })]);
  assert.deepEqual(gifts.map((item) => item.status), [201, 201]); assert.equal((await request('/api/wallet', { headers: auth(users.buyer) })).body.data.wallet.balance, before - 99); assert.equal(await models.GiftTransaction.count({ where: { senderId: users.buyer.id, idempotencyKey: giftKey } }), 1);

  const entitlement = await models.BoostEntitlement.create({ userId: users.empty.id, productId: 'boost_starter_30', source: 'admin', quantity: 1, remainingQuantity: 1, durationMinutes: 30, status: 'active', idempotencyKey: idem('concurrent-entitlement') });
  const activations = await Promise.all([json('/api/discover/boost', 'POST', users.empty, { idempotencyKey: idem('activate-a') }), json('/api/discover/boost', 'POST', users.empty, { idempotencyKey: idem('activate-b') })]);
  assert.ok(activations.every((item) => [200, 402].includes(item.status))); await entitlement.reload(); assert.equal(entitlement.remainingQuantity, 0); assert.equal(await models.Boost.count({ where: { userId: users.empty.id, boostEntitlementId: entitlement.id } }), 1);
});

test('webhook signatures and provider event ids prevent replay', async () => {
  const invalid = await request('/api/payments/webhook', { method: 'POST', headers: { 'content-type': 'application/json', 'x-razorpay-signature': 'bad', 'x-razorpay-event-id': 'evt_p5_bad' }, body: JSON.stringify({ event: 'payment.failed' }) }); assert.equal(invalid.status, 400);
  const payload = { event: 'payment.failed', payload: { payment: { entity: { id: 'pay_unknown', order_id: 'order_unknown', status: 'failed' } } } }; const headers = { 'content-type': 'application/json', 'x-razorpay-signature': 'valid-webhook', 'x-razorpay-event-id': 'evt_p5_once' };
  const first = await request('/api/payments/webhook', { method: 'POST', headers, body: JSON.stringify(payload) }); const second = await request('/api/payments/webhook', { method: 'POST', headers, body: JSON.stringify(payload) }); assert.equal(first.status, 200); assert.equal(second.body.data.duplicate, true); assert.equal(await models.PaymentEvent.count({ where: { providerEventId: 'evt_p5_once' } }), 1);
});

test('captured and refund webhooks atomically credit then reverse wallet value', async () => {
  const created = await json('/api/wallet/top-up/orders', 'POST', users.other, { productId: 'credits_100', idempotencyKey: idem('webhook-topup') }); const order = created.body.data.order;
  const captured = { event: 'payment.captured', payload: { payment: { entity: { id: 'pay_p5_webhook', order_id: order.providerOrderId, amount: order.amountMinor, currency: order.currency, status: 'captured' } } } };
  const capturedHeaders = { 'content-type': 'application/json', 'x-razorpay-signature': 'valid-webhook', 'x-razorpay-event-id': 'evt_p5_captured' };
  assert.equal((await request('/api/payments/webhook', { method: 'POST', headers: capturedHeaders, body: JSON.stringify(captured) })).status, 200);
  assert.equal((await request('/api/wallet', { headers: auth(users.other) })).body.data.wallet.balance, 100);
  const refund = { event: 'refund.processed', payload: { refund: { entity: { id: 'rfnd_p5', payment_id: 'pay_p5_webhook', amount: order.amountMinor, currency: order.currency, status: 'processed' } } } };
  assert.equal((await request('/api/payments/webhook', { method: 'POST', headers: { ...capturedHeaders, 'x-razorpay-event-id': 'evt_p5_refund' }, body: JSON.stringify(refund) })).status, 200);
  const wallet = await request('/api/wallet', { headers: auth(users.other) }); assert.equal(wallet.body.data.wallet.balance, 0);
  const payment = await models.Payment.findOne({ where: { providerPaymentId: 'pay_p5_webhook' } }); assert.equal(payment.status, 'refunded');
});
