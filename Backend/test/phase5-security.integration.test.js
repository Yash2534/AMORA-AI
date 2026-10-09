const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_phase5_security`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Phase 5 security tests require an isolated TEST_DB_NAME containing "test".');
}
const environmentKeys = ['DB_NAME', 'NODE_ENV', 'GOOGLE_CLIENT_IDS'];
const originalEnvironment = Object.fromEntries(environmentKeys.map((key) => [key, process.env[key]]));
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
process.env.GOOGLE_CLIENT_IDS = 'phase5-google-client';

let googlePayload;
const googleLibraryPath = require.resolve('google-auth-library');
const originalGoogleLibrary = require.cache[googleLibraryPath];
class MockOAuth2Client {
  async verifyIdToken() {
    if (!googlePayload) throw new Error('Invalid mocked Google token.');
    return { getPayload: () => googlePayload };
  }
}
require.cache[googleLibraryPath] = {
  id: googleLibraryPath,
  filename: googleLibraryPath,
  loaded: true,
  exports: { OAuth2Client: MockOAuth2Client },
};

const otpModule = require.resolve('../src/utils/generateOtp');
const smsModule = require.resolve('../src/utils/sendSms');
const emailModule = require.resolve('../src/utils/sendEmail');
require(otpModule); require(smsModule); require(emailModule);
const originalOtp = require.cache[otpModule].exports;
const originalSms = require.cache[smsModule].exports;
const originalEmail = require.cache[emailModule].exports;
const verificationCode = '246810';
const sentMessages = [];
const phoneSeed = Date.now() % 1000000000;
const testPhone = (offset) => `+919${String((phoneSeed + offset) % 1000000000).padStart(9, '0')}`;
require.cache[otpModule].exports = () => verificationCode;
require.cache[smsModule].exports = async (to, _message, metadata) => sentMessages.push({ to, metadata });
require.cache[emailModule].exports = async () => ({ accepted: true });

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { issueTokens } = require('../src/utils/generateTokens');
const { normalizeIndianMobile } = require('../src/utils/phoneNumber');

let models;
let server;
let baseUrl;
let localUser;
let localSession;
let googleUser;
let googleSession;
let otherUser;
const createdUserIds = [];

async function createUser(label, values = {}) {
  const user = await models.User.create({
    name: label,
    email: `${label.toLowerCase().replace(/\W/g, '-')}-${Date.now()}-${createdUserIds.length}@phase5.test`,
    phoneNumber: '',
    authProvider: 'local',
    passwordHash: await bcrypt.hash('LocalPass1!', 4),
    isVerified: true,
    termsAcceptedAt: new Date(),
    ...values,
  });
  createdUserIds.push(user.id);
  return user;
}

async function request(pathname, { method = 'GET', token, body } = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  localUser = await createUser('Local Owner', { phoneNumber: testPhone(1) });
  googleUser = await createUser('Google Owner', {
    email: `google-owner-${Date.now()}@phase5.test`,
    phoneNumber: '',
    authProvider: 'google',
    passwordHash: null,
    googleId: `google-owner-${Date.now()}`,
  });
  otherUser = await createUser('Other Owner', { phoneNumber: testPhone(2) });
  localSession = await issueTokens(localUser, '127.0.0.1');
  googleSession = await issueTokens(googleUser, '127.0.0.1');
  await models.UserDevice.bulkCreate([
    { userId: localUser.id, pushToken: `local-${Date.now()}`, platform: 'android', lastSeenAt: new Date() },
    { userId: googleUser.id, pushToken: `google-${Date.now()}`, platform: 'android', lastSeenAt: new Date() },
  ]);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve) => setTimeout(resolve, 100));
  if (server) await new Promise((resolve) => server.close(resolve));
  try { await getSequelize().close(); } catch (_) {}
  require.cache[otpModule].exports = originalOtp;
  require.cache[smsModule].exports = originalSms;
  require.cache[emailModule].exports = originalEmail;
  if (originalGoogleLibrary) require.cache[googleLibraryPath] = originalGoogleLibrary;
  else delete require.cache[googleLibraryPath];
  for (const [key, value] of Object.entries(originalEnvironment)) {
    if (value === undefined) delete process.env[key]; else process.env[key] = value;
  }
});

test('phone normalization canonicalizes supported Indian formatting and rejects invalid input', () => {
  assert.equal(normalizeIndianMobile('+91 98765-43210'), '+919876543210');
  assert.equal(normalizeIndianMobile('91 98765 43210'), '+919876543210');
  assert.equal(normalizeIndianMobile('9876543210'), '+919876543210');
  assert.equal(normalizeIndianMobile('+1 9876543210'), '');
  assert.equal(normalizeIndianMobile('12345'), '');
});

test('local deactivation requires password, revokes sessions/devices, and old credentials stay invalid after reactivation', async () => {
  const wrong = await request('/api/account/deactivate', {
    method: 'POST', token: localSession.accessToken, body: { password: 'WrongPass1!' },
  });
  assert.equal(wrong.status, 401);
  assert.equal(wrong.body.code, 'CURRENT_PASSWORD_INCORRECT');

  const deactivated = await request('/api/account/deactivate', {
    method: 'POST', token: localSession.accessToken, body: { password: 'LocalPass1!', userId: otherUser.id },
  });
  assert.equal(deactivated.status, 200, JSON.stringify(deactivated.body));
  await localUser.reload();
  await otherUser.reload();
  assert.equal(localUser.accountStatus, 'deactivated');
  assert.equal(otherUser.accountStatus, 'active');
  assert.equal(await models.RefreshToken.count({ where: { userId: localUser.id } }), 0);
  assert.equal(await models.UserDevice.count({ where: { userId: localUser.id } }), 0);
  assert.equal((await request('/api/auth/me', { token: localSession.accessToken })).status, 401);
  assert.equal((await request('/api/discover/swipe', { method: 'POST', token: localSession.accessToken, body: { targetUserId: otherUser.id, action: 'like' } })).status, 401);
  assert.equal((await request('/api/auth/refresh-token', { method: 'POST', body: { refreshToken: localSession.refreshToken } })).status, 401);

  const login = await request('/api/auth/login', { method: 'POST', body: { email: localUser.email, password: 'LocalPass1!' } });
  assert.equal(login.status, 403);
  assert.equal(login.body.code, 'ACCOUNT_DEACTIVATED');
  const reactivated = await request('/api/auth/reactivate', { method: 'POST', body: { reactivationToken: login.body.data.reactivationToken } });
  assert.equal(reactivated.status, 200, JSON.stringify(reactivated.body));
  assert.equal((await request('/api/auth/me', { token: reactivated.body.data.accessToken })).status, 200);
  assert.equal((await request('/api/auth/me', { token: localSession.accessToken })).status, 401);
  assert.equal((await request('/api/auth/reactivate', { method: 'POST', body: { reactivationToken: login.body.data.reactivationToken } })).status, 409);
  localSession = { accessToken: reactivated.body.data.accessToken, refreshToken: reactivated.body.data.refreshToken };
});

test('Google deactivation requires a freshly verified matching provider identity and supports reactivation', async () => {
  googlePayload = { sub: 'wrong-google-subject', email: googleUser.email };
  const mismatch = await request('/api/account/deactivate', {
    method: 'POST', token: googleSession.accessToken, body: { providerIdToken: 'mock-google-token' },
  });
  assert.equal(mismatch.status, 401);
  assert.equal(mismatch.body.code, 'PROVIDER_IDENTITY_MISMATCH');
  await googleUser.reload();
  assert.equal(googleUser.accountStatus, 'active');

  googlePayload = { sub: googleUser.googleId, email: googleUser.email };
  const deactivated = await request('/api/account/deactivate', {
    method: 'POST', token: googleSession.accessToken, body: { providerIdToken: 'mock-google-token' },
  });
  assert.equal(deactivated.status, 200, JSON.stringify(deactivated.body));
  assert.equal(await models.RefreshToken.count({ where: { userId: googleUser.id } }), 0);
  assert.equal(await models.UserDevice.count({ where: { userId: googleUser.id } }), 0);

  const login = await request('/api/auth/google', { method: 'POST', body: { idToken: 'mock-google-token' } });
  assert.equal(login.status, 403);
  assert.equal(login.body.code, 'ACCOUNT_DEACTIVATED');
  const reactivated = await request('/api/auth/reactivate', { method: 'POST', body: { reactivationToken: login.body.data.reactivationToken } });
  assert.equal(reactivated.status, 200);
  assert.equal((await request('/api/auth/me', { token: reactivated.body.data.accessToken })).status, 200);
});

test('phone change requires step-up, new-number OTP, uniqueness, and revokes existing sessions', async () => {
  const phoneUser = await createUser('Phone Change Owner', { phoneNumber: testPhone(6) });
  const phoneSession = await issueTokens(phoneUser, '127.0.0.1');
  const wrongPassword = await request('/api/account/phone-change/request', {
    method: 'POST', token: phoneSession.accessToken,
    body: { phoneNumber: testPhone(3), password: 'WrongPass1!' },
  });
  assert.equal(wrongPassword.status, 401);

  const owned = await request('/api/account/phone-change/request', {
    method: 'POST', token: phoneSession.accessToken,
    body: { phoneNumber: otherUser.phoneNumber, password: 'LocalPass1!' },
  });
  assert.equal(owned.status, 409);
  assert.equal(owned.body.code, 'PHONE_UNAVAILABLE');

  const requested = await request('/api/account/phone-change/request', {
    method: 'POST', token: phoneSession.accessToken,
    body: { phoneNumber: testPhone(3), password: 'LocalPass1!' },
  });
  assert.equal(requested.status, 200, JSON.stringify(requested.body));
  const pendingOtp = await models.OtpToken.findOne({
    where: { userId: phoneUser.id, phoneNumber: testPhone(3), purpose: 'phone_change', consumed: false },
  });
  assert.ok(pendingOtp);

  const wrongOtp = await request('/api/account/phone-change/confirm', {
    method: 'POST', token: phoneSession.accessToken,
    body: { phoneNumber: testPhone(3), code: '000000' },
  });
  assert.equal(wrongOtp.status, 400);
  assert.equal(wrongOtp.body.code, 'OTP_INVALID');

  const changed = await request('/api/account/phone-change/confirm', {
    method: 'POST', token: phoneSession.accessToken,
    body: { phoneNumber: testPhone(3), code: verificationCode },
  });
  assert.equal(changed.status, 200, JSON.stringify(changed.body));
  await phoneUser.reload();
  assert.equal(phoneUser.phoneNumber, testPhone(3));
  assert.equal(await models.RefreshToken.count({ where: { userId: phoneUser.id } }), 0);
  assert.equal((await request('/api/auth/me', { token: phoneSession.accessToken })).status, 401);
});

test('expired phone-change OTP is denied and the database is the final duplicate-ownership boundary', async () => {
  const session = await issueTokens(otherUser, '127.0.0.1');
  const requested = await request('/api/account/phone-change/request', {
    method: 'POST', token: session.accessToken,
    body: { phoneNumber: testPhone(4), password: 'LocalPass1!' },
  });
  assert.equal(requested.status, 200);
  await models.OtpToken.update(
    { expiresAt: new Date(Date.now() - 1000) },
    { where: { userId: otherUser.id, purpose: 'phone_change', consumed: false } },
  );
  const expired = await request('/api/account/phone-change/confirm', {
    method: 'POST', token: session.accessToken,
    body: { phoneNumber: testPhone(4), code: verificationCode },
  });
  assert.equal(expired.status, 400);
  assert.equal(expired.body.code, 'OTP_EXPIRED');

  await assert.rejects(
    () => models.User.create({
      name: 'Duplicate DB Boundary',
      email: `duplicate-${Date.now()}@phase5.test`,
      phoneNumber: localUser.phoneNumber,
      authProvider: 'local',
      passwordHash: 'unused',
      isVerified: false,
    }),
    (error) => error.name === 'SequelizeUniqueConstraintError',
  );
});

test('concurrent verified claims cannot create duplicate phone ownership', async () => {
  const first = await createUser('Concurrent First');
  const second = await createUser('Concurrent Second');
  const [firstSession, secondSession] = await Promise.all([
    issueTokens(first, '127.0.0.1'),
    issueTokens(second, '127.0.0.1'),
  ]);
  const phoneNumber = testPhone(5);
  const requested = await Promise.all([
    request('/api/account/phone-change/request', {
      method: 'POST', token: firstSession.accessToken,
      body: { phoneNumber, password: 'LocalPass1!' },
    }),
    request('/api/account/phone-change/request', {
      method: 'POST', token: secondSession.accessToken,
      body: { phoneNumber, password: 'LocalPass1!' },
    }),
  ]);
  assert.deepEqual(requested.map((result) => result.status), [200, 200]);

  const confirmed = await Promise.all([
    request('/api/account/phone-change/confirm', {
      method: 'POST', token: firstSession.accessToken,
      body: { phoneNumber, code: verificationCode },
    }),
    request('/api/account/phone-change/confirm', {
      method: 'POST', token: secondSession.accessToken,
      body: { phoneNumber, code: verificationCode },
    }),
  ]);
  assert.deepEqual(confirmed.map((result) => result.status).sort(), [200, 409]);
  assert.equal(await models.User.count({ where: { phoneNumber } }), 1);
});
