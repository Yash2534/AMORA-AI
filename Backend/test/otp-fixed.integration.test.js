const assert = require('node:assert/strict');
const { once } = require('node:events');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Fixed OTP integration tests require an isolated TEST_DB_NAME containing "test".');
}

process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
process.env.TEST_FIXED_OTP_ENABLED = 'true';
process.env.TEST_FIXED_OTP = '111111';
process.env.TEST_OTP_SKIP_DELIVERY = 'true';

const generatedOtp = '246810';
const generatePath = require.resolve('../src/utils/generateOtp');
const smsPath = require.resolve('../src/utils/sendSms');
const emailPath = require.resolve('../src/utils/sendEmail');
require.cache[generatePath] = {
  id: generatePath,
  filename: generatePath,
  loaded: true,
  exports: () => generatedOtp,
};
let smsDeliveries = 0;
let emailDeliveries = 0;
require.cache[smsPath] = {
  id: smsPath,
  filename: smsPath,
  loaded: true,
  exports: async () => { smsDeliveries += 1; },
};
require.cache[emailPath] = {
  id: emailPath,
  filename: emailPath,
  loaded: true,
  exports: async () => { emailDeliveries += 1; },
};

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server;
let baseUrl;
let models;
const createdUserIds = [];
const createdEmails = [];
const createdPhones = [];

async function request(pathname, body) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: response.status, body: await response.json() };
}

async function signUp(suffix, phonePrefix = '9') {
  const email = `fixed-otp-${suffix}@auth-flow.test`;
  const phoneNumber = `+91${phonePrefix}${String(suffix).slice(-9).padStart(9, '0')}`;
  const password = 'FixedOtpPass123!';
  const response = await request('/api/auth/signup', {
    name: 'Fixed OTP Test',
    email,
    phoneNumber,
    password,
    confirmPassword: password,
    acceptedTerms: true,
  });
  assert.equal(response.status, 200, JSON.stringify(response.body));
  const user = await models.User.findOne({ where: { email } });
  assert.ok(user);
  createdUserIds.push(user.id);
  createdEmails.push(email);
  createdPhones.push(phoneNumber);
  return { email, phoneNumber, password, user };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  server = app.listen(0);
  if (!server.listening) await once(server, 'listening');
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (models) {
    await models.RefreshToken.destroy({ where: { userId: createdUserIds } });
    await models.OtpToken.destroy({ where: { phoneNumber: createdPhones } });
    await models.OtpToken.destroy({ where: { email: createdEmails } });
    await models.User.destroy({ where: { id: createdUserIds } });
  }
  if (server) {
    server.closeIdleConnections?.();
    server.closeAllConnections?.();
    await new Promise((resolve) => server.close(resolve));
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('fixed OTP covers registration, resend, normal fallback, and challenge guards', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const primary = await signUp(suffix, '9');

  const wrong = await request('/api/auth/verify-account', {
    phoneNumber: primary.phoneNumber,
    code: '123456',
  });
  assert.equal(wrong.status, 400);
  assert.equal(wrong.body.code, 'OTP_INVALID');

  const resend = await request('/api/auth/resend-verification-code', {
    phoneNumber: primary.phoneNumber,
  });
  assert.equal(resend.status, 200, JSON.stringify(resend.body));
  assert.equal(resend.body.success, true);
  assert.deepEqual(resend.body.data, { phoneNumber: primary.phoneNumber });

  const verified = await request('/api/auth/verify-account', {
    phoneNumber: primary.phoneNumber,
    code: '111111',
  });
  assert.equal(verified.status, 200, JSON.stringify(verified.body));
  assert.ok(verified.body.data.accessToken);
  assert.equal((await primary.user.reload()).isVerified, true);

  const secondary = await signUp(`${Number(suffix.slice(-10)) + 1}`, '8');
  const normalFallback = await request('/api/auth/verify-account', {
    phoneNumber: secondary.phoneNumber,
    code: generatedOtp,
  });
  assert.equal(normalFallback.status, 200, JSON.stringify(normalFallback.body));

  const unknown = await request('/api/auth/verify-account', {
    phoneNumber: '+917000000001',
    code: '111111',
  });
  assert.equal(unknown.status, 400);
  assert.equal(unknown.body.code, 'OTP_INVALID');
  assert.equal(smsDeliveries, 0);
});

test('fixed OTP covers forgot-password verification without bypassing unknown users', async () => {
  const email = createdEmails[0];
  const unknownEmail = `missing-${Date.now()}@auth-flow.test`;

  const unknownRequest = await request('/api/auth/forgot-password', { email: unknownEmail });
  assert.equal(unknownRequest.status, 200);
  const unknownVerification = await request('/api/auth/verify-reset-code', {
    email: unknownEmail,
    code: '111111',
  });
  assert.equal(unknownVerification.status, 400);
  assert.equal(unknownVerification.body.code, 'OTP_EXPIRED');

  const requested = await request('/api/auth/forgot-password', { email });
  assert.equal(requested.status, 200, JSON.stringify(requested.body));
  const verified = await request('/api/auth/verify-reset-code', {
    email,
    code: '111111',
  });
  assert.equal(verified.status, 200, JSON.stringify(verified.body));
  assert.ok(verified.body.data.recoveryToken);

  const reset = await request('/api/auth/reset-password', {
    email,
    recoveryToken: verified.body.data.recoveryToken,
    newPassword: 'FixedOtpReset456!',
  });
  assert.equal(reset.status, 200, JSON.stringify(reset.body));
  assert.equal(emailDeliveries, 0);
});
