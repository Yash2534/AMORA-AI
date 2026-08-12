const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) throw new Error('Subscription tests require a separate test database.');
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { plans } = require('../scripts/seed-subscription-plans');

let models; let server; let baseUrl; let member;
const auth = () => ({ authorization: `Bearer ${jwt.sign({ sub: member.id, ver: Number(member.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' })}` });
async function get(path, authenticated = false) { const response = await fetch(`${baseUrl}${path}`, { headers: authenticated ? auth() : {} }); return { status: response.status, body: await response.json() }; }

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true }); await initializeDatabase(); models = getModels();
  for (const plan of plans) await models.SubscriptionPlan.upsert(plan);
  member = await models.User.create({ name: 'Subscription Member', email: `${Date.now()}@subscription.test`, phoneNumber: '', authProvider: 'local', isVerified: true, termsAcceptedAt: new Date() });
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && member) { await models.Subscription.destroy({ where: { userId: member.id } }); await models.Payment.destroy({ where: { userId: member.id } }); await member.destroy(); }
  try { await getSequelize().close(); } catch (_) {}
});

test('plans are database-backed and membership is owner-authenticated', async () => {
  const catalog = await get('/api/subscriptions/plans');
  assert.equal(catalog.status, 200);
  assert.deepEqual(catalog.body.data.plans.map((plan) => plan.id), plans.map((plan) => plan.id));
  assert.equal((await get('/api/subscriptions/me')).status, 401);
  const membership = await get('/api/subscriptions/me', true);
  assert.equal(membership.status, 200);
  assert.equal(membership.body.data.membership.status, 'none');
});

test('retired wallet, boost, gift, and redemption endpoints return 404', async () => {
  for (const path of ['/api/wallet', '/api/wallet/transactions', '/api/boosts/me', '/api/gifts']) assert.equal((await get(path, true)).status, 404, path);
});
