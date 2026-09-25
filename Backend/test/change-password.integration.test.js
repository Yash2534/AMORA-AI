const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_change_password`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Change-password tests require an isolated TEST_DB_NAME containing "test".');
}
const originalDatabase = process.env.DB_NAME;
const originalNodeEnv = process.env.NODE_ENV;
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server;
let baseUrl;
let models;
const userIds = [];

async function request(path, { method = 'GET', token, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

async function fixture() {
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 100000)}`;
  const currentPassword = `Current-${suffix}!`;
  const user = await models.User.create({
    name: 'Password Test',
    email: `password-${suffix}@test.invalid`,
    phoneNumber: `+919${String(Date.now()).slice(-9)}`,
    authProvider: 'local',
    passwordHash: await bcrypt.hash(currentPassword, 4),
    isVerified: true,
    accountStatus: 'active',
  });
  userIds.push(user.id);
  const login = await request('/api/auth/login', {
    method: 'POST',
    body: { email: user.email, password: currentPassword },
  });
  assert.equal(login.status, 200, JSON.stringify(login.body));
  return { user, currentPassword, token: login.body.data.accessToken };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (models && userIds.length) {
    await models.RefreshToken.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  if (server) await new Promise((resolve) => server.close(resolve));
  try { await getSequelize().close(); } catch (_) {}
  if (originalDatabase === undefined) delete process.env.DB_NAME;
  else process.env.DB_NAME = originalDatabase;
  if (originalNodeEnv === undefined) delete process.env.NODE_ENV;
  else process.env.NODE_ENV = originalNodeEnv;
});

test('correct current password changes to a valid different password', async () => {
  const { user, currentPassword, token } = await fixture();
  const nextPassword = `${currentPassword}-new`;
  const result = await request('/api/auth/change-password', {
    method: 'POST',
    token,
    body: { currentPassword, newPassword: nextPassword },
  });
  assert.equal(result.status, 200, JSON.stringify(result.body));
  await user.reload();
  assert.equal(await bcrypt.compare(nextPassword, user.passwordHash), true);
  assert.equal(await bcrypt.compare(currentPassword, user.passwordHash), false);
});

test('identical new password is rejected without mutating the hash', async () => {
  const { user, currentPassword, token } = await fixture();
  const originalHash = user.passwordHash;
  const result = await request('/api/auth/change-password', {
    method: 'POST',
    token,
    body: { currentPassword, newPassword: currentPassword },
  });
  assert.equal(result.status, 409);
  assert.equal(result.body.code, 'NEW_PASSWORD_SAME_AS_CURRENT');
  assert.equal(result.body.message, 'New password cannot be the same as the current password.');
  await user.reload();
  assert.equal(user.passwordHash, originalHash);
  assert.equal(await bcrypt.compare(currentPassword, user.passwordHash), true);
});

test('wrong current password keeps existing behavior and does not mutate', async () => {
  const { user, token } = await fixture();
  const originalHash = user.passwordHash;
  const result = await request('/api/auth/change-password', {
    method: 'POST',
    token,
    body: { currentPassword: 'WrongPassword123!', newPassword: 'DifferentPass123!' },
  });
  assert.equal(result.status, 401);
  assert.equal(result.body.code, 'CURRENT_PASSWORD_INCORRECT');
  await user.reload();
  assert.equal(user.passwordHash, originalHash);
});

test('password policy rejection does not mutate the stored hash', async () => {
  const { user, currentPassword, token } = await fixture();
  const originalHash = user.passwordHash;
  const result = await request('/api/auth/change-password', {
    method: 'POST',
    token,
    body: { currentPassword, newPassword: 'short' },
  });
  assert.equal(result.status, 400);
  assert.equal(result.body.code, 'VALIDATION_ERROR');
  assert.equal(
    result.body.errors[0].message,
    'New password must contain at least 8 characters.',
  );
  await user.reload();
  assert.equal(user.passwordHash, originalHash);
});
