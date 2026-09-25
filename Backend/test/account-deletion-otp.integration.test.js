const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_account_deletion_otp`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Account-deletion OTP tests require an isolated test database.');
}
const original = {
  DB_NAME: process.env.DB_NAME,
  NODE_ENV: process.env.NODE_ENV,
  TEST_FIXED_OTP_ENABLED: process.env.TEST_FIXED_OTP_ENABLED,
  TEST_FIXED_OTP: process.env.TEST_FIXED_OTP,
  TEST_OTP_SKIP_DELIVERY: process.env.TEST_OTP_SKIP_DELIVERY,
};
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
process.env.TEST_FIXED_OTP_ENABLED = 'true';
process.env.TEST_FIXED_OTP = '111111';
process.env.TEST_OTP_SKIP_DELIVERY = 'true';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { issueTokens } = require('../src/utils/generateTokens');

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

async function fixture({ verified = true, email = true, phone = true } = {}) {
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
  const password = `Delete-${suffix}!`;
  const user = await models.User.create({
    name: 'Deletion Test',
    email: email ? `delete-${suffix}@test.invalid` : `missing-${suffix}@test.invalid`,
    phoneNumber: phone ? `+919${String(Date.now() + userIds.length).slice(-9)}` : '',
    authProvider: 'local',
    passwordHash: await bcrypt.hash(password, 4),
    isVerified: verified,
    accountStatus: 'active',
  });
  userIds.push(user.id);
  const tokens = await issueTokens(user, '127.0.0.1');
  return { user, password, originalEmail: user.email, ...tokens };
}

async function sendOtp(fixtureValue, channel, extra = {}) {
  return request('/api/account/delete/send-otp', {
    method: 'POST',
    token: fixtureValue.accessToken,
    body: { channel, ...extra },
  });
}

async function confirm(fixtureValue, channel = 'EMAIL', otp = '111111') {
  return request('/api/account/delete/confirm', {
    method: 'POST',
    token: fixtureValue.accessToken,
    body: { channel, otp },
  });
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
    await models.OtpToken.destroy({ where: { userId: userIds } });
    await models.RefreshToken.destroy({ where: { userId: userIds } });
    await models.UserDevice.destroy({ where: { userId: userIds } });
    await models.DeletedUser.destroy({ where: { originalUserId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  if (server) await new Promise((resolve) => server.close(resolve));
  try { await getSequelize().close(); } catch (_) {}
  for (const [key, value] of Object.entries(original)) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
});

test('deletion OTP endpoints require authentication and reject invalid channels', async () => {
  assert.equal((await request('/api/account/delete/methods')).status, 401);
  assert.equal((await request('/api/account/delete/send-otp', {
    method: 'POST', body: { channel: 'EMAIL' },
  })).status, 401);
  const member = await fixture();
  const invalid = await sendOtp(member, 'OTHER');
  assert.equal(invalid.status, 400);
  assert.equal(invalid.body.code, 'VALIDATION_ERROR');
});

test('registered email and phone methods are masked and arbitrary destinations are ignored', async () => {
  const member = await fixture();
  const methods = await request('/api/account/delete/methods', { token: member.accessToken });
  assert.equal(methods.status, 200);
  assert.deepEqual(methods.body.data.methods.map((item) => item.channel), ['EMAIL', 'PHONE']);
  for (const method of methods.body.data.methods) {
    assert.equal(method.maskedDestination.includes(member.user.email), false);
    assert.equal(method.maskedDestination.includes(member.user.phoneNumber), false);
  }
  const sent = await sendOtp(member, 'EMAIL', { email: 'attacker@example.com' });
  assert.equal(sent.status, 200, JSON.stringify(sent.body));
  const otp = await models.OtpToken.findOne({ where: { userId: member.user.id, purpose: 'account_deletion' } });
  assert.equal(otp.email, member.user.email);
  assert.equal(otp.phoneNumber, null);
});

test('phone deletion OTP uses the registered phone and is purpose/user/channel bound', async () => {
  const member = await fixture();
  const sent = await sendOtp(member, 'PHONE');
  assert.equal(sent.status, 200, JSON.stringify(sent.body));
  const otp = await models.OtpToken.findOne({ where: { userId: member.user.id, purpose: 'account_deletion' } });
  assert.equal(otp.phoneNumber, member.user.phoneNumber);
  assert.equal(otp.email, null);
  const wrongChannel = await confirm(member, 'EMAIL');
  assert.equal(wrongChannel.status, 400);
  assert.equal(wrongChannel.body.code, 'OTP_EXPIRED');
  await member.user.reload();
  assert.equal(member.user.accountStatus, 'active');
});

test('missing or unverified destinations fail closed', async () => {
  const member = await fixture({ verified: false, phone: false });
  const methods = await request('/api/account/delete/methods', { token: member.accessToken });
  assert.equal(methods.status, 409);
  assert.equal(methods.body.code, 'DELETION_VERIFICATION_UNAVAILABLE');
  const sent = await sendOtp(member, 'EMAIL');
  assert.equal(sent.status, 409);
  await member.user.reload();
  assert.equal(member.user.accountStatus, 'active');
});

test('wrong, expired, other-purpose, and another-user OTPs are rejected', async () => {
  const wrong = await fixture();
  await sendOtp(wrong, 'EMAIL');
  const wrongResult = await confirm(wrong, 'EMAIL', '222222');
  assert.equal(wrongResult.status, 400);
  assert.equal(wrongResult.body.code, 'OTP_INVALID');

  const expired = await fixture();
  await sendOtp(expired, 'EMAIL');
  await models.OtpToken.update(
    { expiresAt: new Date(Date.now() - 1000) },
    { where: { userId: expired.user.id, purpose: 'account_deletion' } },
  );
  const expiredResult = await confirm(expired);
  assert.equal(expiredResult.body.code, 'OTP_EXPIRED');

  const otherPurpose = await fixture();
  await models.OtpToken.create({
    userId: otherPurpose.user.id,
    email: otherPurpose.user.email,
    purpose: 'password_reset',
    codeHash: await bcrypt.hash('111111', 4),
    expiresAt: new Date(Date.now() + 60000),
  });
  assert.equal((await confirm(otherPurpose)).body.code, 'OTP_EXPIRED');

  const owner = await fixture();
  const other = await fixture();
  await sendOtp(owner, 'EMAIL');
  assert.equal((await confirm(other)).body.code, 'OTP_EXPIRED');
  await owner.user.reload();
  await other.user.reload();
  assert.equal(owner.user.accountStatus, 'active');
  assert.equal(other.user.accountStatus, 'active');
});

test('attempt limit consumes the deletion OTP and prevents replay', async () => {
  const member = await fixture();
  await sendOtp(member, 'EMAIL');
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    const result = await confirm(member, 'EMAIL', '222222');
    assert.equal(result.body.code, attempt === 5 ? 'OTP_MAX_ATTEMPTS' : 'OTP_INVALID');
  }
  assert.equal((await confirm(member)).body.code, 'RATE_LIMITED');
});

test('successful OTP immediately archives and removes the account from active state', async () => {
  const member = await fixture();
  await models.UserDevice.create({
    userId: member.user.id,
    pushToken: `push-token-${member.user.id}-abcdefghijklmnopqrstuvwxyz`,
    platform: 'android',
    active: true,
    lastSeenAt: new Date(),
  });
  const requestCount = await models.AccountDeletionRequest.count();
  await sendOtp(member, 'EMAIL');
  const deleted = await confirm(member);
  assert.equal(deleted.status, 200, JSON.stringify(deleted.body));
  assert.equal(deleted.body.message, 'Your account has been deleted.');
  await member.user.reload();
  assert.equal(member.user.accountStatus, 'deleted');
  assert.equal(member.user.passwordHash, null);
  assert.equal(member.user.isVerified, false);
  const archive = await models.DeletedUser.findOne({ where: { originalUserId: member.user.id } });
  assert.equal(archive.deletionMechanism, 'USER_INITIATED_OTP');
  assert.equal(await models.RefreshToken.count({ where: { userId: member.user.id } }), 0);
  assert.equal(await models.UserDevice.count({ where: { userId: member.user.id } }), 0);
  assert.equal(await models.AccountDeletionRequest.count(), requestCount);
  assert.equal((await request('/api/auth/me', { token: member.accessToken })).status, 401);
  assert.equal((await request('/api/auth/refresh-token', {
    method: 'POST', body: { refreshToken: member.refreshToken },
  })).status, 401);
  assert.equal((await request('/api/auth/login', {
    method: 'POST', body: { email: member.originalEmail, password: member.password },
  })).status, 401);
  assert.equal((await confirm(member)).status, 401);
  assert.equal(await models.DeletedUser.count({ where: { originalUserId: member.user.id } }), 1);
});

test('archive failure rolls back OTP consumption and active-user mutation', async () => {
  const member = await fixture();
  await sendOtp(member, 'EMAIL');
  const originalCreate = models.DeletedUser.create;
  models.DeletedUser.create = async () => { throw new Error('forced archive failure'); };
  const failed = await confirm(member);
  models.DeletedUser.create = originalCreate;
  assert.equal(failed.status, 500);
  await member.user.reload();
  assert.equal(member.user.accountStatus, 'active');
  const otp = await models.OtpToken.findOne({
    where: { userId: member.user.id, purpose: 'account_deletion' },
  });
  assert.equal(otp.consumed, false);
  assert.equal(await models.DeletedUser.count({ where: { originalUserId: member.user.id } }), 0);
});
