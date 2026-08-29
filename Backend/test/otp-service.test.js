const assert = require('node:assert/strict');
const { after, afterEach, beforeEach, test } = require('node:test');

const bcrypt = require('bcrypt');

const modelsPath = require.resolve('../src/models');
const smsPath = require.resolve('../src/utils/sendSms');
const emailPath = require.resolve('../src/utils/sendEmail');
const servicePath = require.resolve('../src/services/otpService');

const modelsModule = require(modelsPath);

const originalGetModels = modelsModule.getModels;
const originalSmsModule = require.cache[smsPath];
const originalEmailModule = require.cache[emailPath];
const originalEnvironment = Object.fromEntries(
  ['NODE_ENV', 'TEST_FIXED_OTP_ENABLED', 'TEST_FIXED_OTP', 'TEST_OTP_SKIP_DELIVERY']
    .map((key) => [key, process.env[key]]),
);

let challenge;
let smsDeliveries;
let emailDeliveries;

modelsModule.getModels = () => ({
  OtpToken: {
    findOne: async ({ where }) => {
      if (!challenge || challenge.consumed) return null;
      if (where.phoneNumber !== undefined && where.phoneNumber !== challenge.phoneNumber) return null;
      if (where.email !== undefined && where.email !== challenge.email) return null;
      if (where.purpose !== challenge.purpose) return null;
      return challenge;
    },
  },
});
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
delete require.cache[servicePath];
const {
  deliverEmailOtp,
  deliverPhoneOtp,
  verifyEmailOtp,
  verifyPhoneOtp,
} = require(servicePath);

function setEnvironment({
  nodeEnv = 'test',
  enabled = 'true',
  fixedOtp = '111111',
  skipDelivery = 'true',
} = {}) {
  process.env.NODE_ENV = nodeEnv;
  process.env.TEST_FIXED_OTP_ENABLED = enabled;
  process.env.TEST_FIXED_OTP = fixedOtp;
  process.env.TEST_OTP_SKIP_DELIVERY = skipDelivery;
}

async function makeChallenge({
  phoneNumber,
  email,
  purpose,
  realCode = '246810',
  expiresAt = new Date(Date.now() + 60_000),
  attempts = 0,
} = {}) {
  challenge = {
    phoneNumber,
    email,
    purpose,
    codeHash: await bcrypt.hash(realCode, 4),
    expiresAt,
    attempts,
    consumed: false,
    saveCount: 0,
    async save() { this.saveCount += 1; },
  };
  return challenge;
}

beforeEach(() => {
  challenge = null;
  smsDeliveries = 0;
  emailDeliveries = 0;
  setEnvironment();
});

afterEach(() => {
  for (const [key, value] of Object.entries(originalEnvironment)) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
});

after(() => {
  modelsModule.getModels = originalGetModels;
  if (originalSmsModule) require.cache[smsPath] = originalSmsModule;
  else delete require.cache[smsPath];
  if (originalEmailModule) require.cache[emailPath] = originalEmailModule;
  else delete require.cache[emailPath];
  delete require.cache[servicePath];
});

test('fixed OTP verifies an active registration challenge and consumes it', async () => {
  const active = await makeChallenge({
    phoneNumber: '+919876543210',
    purpose: 'account_verification',
  });

  const result = await verifyPhoneOtp('+919876543210', '111111', 'account_verification');

  assert.equal(result.otp, active);
  assert.equal(active.consumed, true);
  assert.equal(active.saveCount, 1);
});

test('an incorrect fixed value falls back to normal verification and attempt handling', async () => {
  const active = await makeChallenge({
    phoneNumber: '+919876543210',
    purpose: 'account_verification',
  });

  const incorrect = await verifyPhoneOtp('+919876543210', '123456', 'account_verification');
  assert.equal(incorrect.error[0], 'OTP_INVALID');
  assert.equal(active.attempts, 1);
  assert.equal(active.consumed, false);

  const realOtp = await verifyPhoneOtp('+919876543210', '246810', 'account_verification');
  assert.equal(realOtp.otp, active);
  assert.equal(active.consumed, true);
});

test('fixed OTP verifies an active forgot-password email challenge', async () => {
  const active = await makeChallenge({
    email: 'member@example.com',
    purpose: 'password_reset',
  });

  const result = await verifyEmailOtp('member@example.com', '111111', 'password_reset');

  assert.equal(result.otp, active);
  assert.equal(active.consumed, true);
});

test('fixed OTP cannot bypass challenge identity, purpose, expiry, or attempt limits', async () => {
  let result = await verifyPhoneOtp('+919876543210', '111111', 'account_verification');
  assert.equal(result.error[0], 'OTP_EXPIRED');

  await makeChallenge({ phoneNumber: '+919876543210', purpose: 'account_verification' });
  result = await verifyPhoneOtp('+919000000000', '111111', 'account_verification');
  assert.equal(result.error[0], 'OTP_EXPIRED');

  const expired = await makeChallenge({
    phoneNumber: '+919876543210',
    purpose: 'account_verification',
    expiresAt: new Date(Date.now() - 1_000),
  });
  result = await verifyPhoneOtp('+919876543210', '111111', 'account_verification');
  assert.equal(result.error[0], 'OTP_EXPIRED');
  assert.equal(expired.consumed, true);

  const exhausted = await makeChallenge({
    phoneNumber: '+919876543210',
    purpose: 'account_verification',
    attempts: 5,
  });
  result = await verifyPhoneOtp('+919876543210', '111111', 'account_verification');
  assert.equal(result.error[0], 'OTP_MAX_ATTEMPTS');
  assert.equal(exhausted.consumed, false);
});

test('production gives the configured test value no special treatment', async () => {
  setEnvironment({
    nodeEnv: 'production',
    enabled: 'false',
    fixedOtp: '',
    skipDelivery: 'false',
  });
  const active = await makeChallenge({
    phoneNumber: '+919876543210',
    purpose: 'account_verification',
  });

  const result = await verifyPhoneOtp('+919876543210', '111111', 'account_verification');

  assert.equal(result.error[0], 'OTP_INVALID');
  assert.equal(active.attempts, 1);
  assert.equal(active.consumed, false);
});

test('test delivery skipping preserves success without calling SMS or email providers', async () => {
  const expiresAt = new Date(Date.now() + 60_000);
  const smsResult = await deliverPhoneOtp(
    '+919876543210',
    'account_verification',
    '246810',
    expiresAt,
  );
  const emailResult = await deliverEmailOtp(
    'member@example.com',
    'password_reset',
    '246810',
    expiresAt,
  );

  assert.deepEqual(smsResult, { skipped: true });
  assert.deepEqual(emailResult, { skipped: true });
  assert.equal(smsDeliveries, 0);
  assert.equal(emailDeliveries, 0);

  process.env.TEST_OTP_SKIP_DELIVERY = 'false';
  assert.deepEqual(
    await deliverPhoneOtp('+919876543210', 'account_verification', '246810', expiresAt),
    { skipped: false },
  );
  assert.deepEqual(
    await deliverEmailOtp('member@example.com', 'password_reset', '246810', expiresAt),
    { skipped: false },
  );
  assert.equal(smsDeliveries, 1);
  assert.equal(emailDeliveries, 1);
});
