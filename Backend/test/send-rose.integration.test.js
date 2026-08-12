const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Send Rose integration tests require a separate TEST_DB_NAME containing "test".');
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
const users = [];
let sequence = 0;

const tokenFor = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
const key = (label) => `rose:${label}:${Date.now()}:${sequence += 1}`;

async function request(path, { user, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: {
      ...(user ? { authorization: `Bearer ${tokenFor(user)}` } : {}),
      'content-type': 'application/json',
    },
    body: JSON.stringify(body || {}),
  });
  return { status: response.status, body: await response.json() };
}

async function createUser(name) {
  const suffix = `${Date.now()}_${users.length}_${Math.random().toString(36).slice(2)}`;
  const user = await models.User.create({ name, email: `${suffix}@rose.test`, phoneNumber: '', authProvider: 'local', isVerified: true, termsAcceptedAt: new Date() });
  users.push(user);
  await models.OnboardingProfile.create({ userId: user.id, birthDate: '1997-05-12', gender: 'Woman', interestedIn: ['Men'], relationshipGoals: ['long_term'], city: 'Ahmedabad', photos: ['/uploads/rose-test.jpg'], stage: 'complete', onboardingCompleted: true });
  return user;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await createUser('Rose Sender');
  await createUser('Rose Recipient');
  await createUser('Other User');
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && users.length) {
    const ids = users.map((user) => user.id);
    await models.Notification.destroy({ where: { [Op.or]: [{ userId: ids }, { actorUserId: ids }] }, force: true });
    await models.RoseTransaction.destroy({ where: { [Op.or]: [{ senderId: ids }, { recipientId: ids }] } });
    await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: ids }, { blockedUserId: ids }] } });
    await models.OnboardingProfile.destroy({ where: { userId: ids } });
    await models.User.destroy({ where: { id: ids } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('Rose is authenticated, persisted, notified, and idempotent without commerce state', async () => {
  const idempotencyKey = key('success');
  assert.equal((await request('/api/roses/send', { body: { recipientId: users[1].id, idempotencyKey } })).status, 401);
  const sent = await request('/api/roses/send', { user: users[0], body: { recipientId: users[1].id, note: 'Hello', idempotencyKey } });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  assert.equal(sent.body.data.roseTransaction.senderId, String(users[0].id));
  assert.equal(sent.body.data.roseTransaction.recipientId, String(users[1].id));
  const persisted = await models.RoseTransaction.findByPk(sent.body.data.roseTransaction.id);
  assert.equal(persisted.note, 'Hello');
  assert.equal(await models.Notification.count({ where: { userId: users[1].id, actorUserId: users[0].id, type: 'rose_received', dedupeKey: `rose:${persisted.id}` } }), 1);
  const replay = await request('/api/roses/send', { user: users[0], body: { recipientId: users[1].id, note: 'Hello', idempotencyKey } });
  assert.equal(replay.status, 201);
  assert.equal(replay.body.data.roseTransaction.id, String(persisted.id));
  assert.equal(await models.RoseTransaction.count({ where: { senderId: users[0].id, idempotencyKey } }), 1);
});

test('Rose rejects invalid recipient relationships and conflicting retries', async () => {
  assert.equal((await request('/api/roses/send', { user: users[0], body: { recipientId: users[0].id, idempotencyKey: key('self') } })).status, 400);
  assert.equal((await request('/api/roses/send', { user: users[0], body: { recipientId: 2147483647, idempotencyKey: key('missing') } })).status, 404);
  await models.Block.create({ blockerUserId: users[1].id, blockedUserId: users[0].id });
  assert.equal((await request('/api/roses/send', { user: users[0], body: { recipientId: users[1].id, idempotencyKey: key('blocked') } })).status, 403);
  await models.Block.destroy({ where: { blockerUserId: users[1].id, blockedUserId: users[0].id } });
  const idempotencyKey = key('conflict');
  assert.equal((await request('/api/roses/send', { user: users[0], body: { recipientId: users[1].id, idempotencyKey } })).status, 201);
  assert.equal((await request('/api/roses/send', { user: users[0], body: { recipientId: users[2].id, idempotencyKey } })).status, 409);
});

test('retired commerce APIs return 404', async () => {
  for (const path of ['/api/wallet', '/api/boosts', '/api/gifts', '/api/realtime/token']) {
    const response = await fetch(`${baseUrl}${path}`, { headers: { authorization: `Bearer ${tokenFor(users[0])}` } });
    assert.equal(response.status, 404, path);
  }
});
