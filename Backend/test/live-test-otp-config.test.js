const assert = require('node:assert/strict');
const { test } = require('node:test');

const {
  matchesLiveTestOtp,
  resolveLiveTestOtpConfig,
  skipsLiveTestOtpDelivery,
} = require('../src/config/liveTestOtpConfig');

const now = new Date('2026-09-14T10:00:00.000Z');
const allowedPhone = '+919876543210';
const enabled = {
  NODE_ENV: 'production',
  LIVE_TEST_OTP_ENABLED: 'true',
  LIVE_TEST_OTP_VALUE: '111111',
  LIVE_TEST_OTP_PHONE_ALLOWLIST: allowedPhone,
  LIVE_TEST_OTP_EXPIRES_AT: '2026-09-14T12:00:00.000Z',
};

test('disabled production configuration gives 111111 no special treatment', () => {
  const env = { NODE_ENV: 'production', LIVE_TEST_OTP_ENABLED: 'false' };
  assert.equal(matchesLiveTestOtp(allowedPhone, '111111', env, now), false);
  assert.equal(skipsLiveTestOtpDelivery(allowedPhone, env, now), false);
});

test('restricted live test OTP requires an exact normalized allowlisted phone and value', () => {
  assert.equal(matchesLiveTestOtp('9876543210', '111111', enabled, now), true);
  assert.equal(matchesLiveTestOtp('+919876543211', '111111', enabled, now), false);
  assert.equal(matchesLiveTestOtp(allowedPhone, '111112', enabled, now), false);
  assert.equal(skipsLiveTestOtpDelivery(allowedPhone, enabled, now), true);
  assert.equal(skipsLiveTestOtpDelivery('+919876543211', enabled, now), false);
});

test('expired, malformed, or empty live test configuration fails closed', () => {
  for (const env of [
    { ...enabled, LIVE_TEST_OTP_EXPIRES_AT: '2026-09-14T09:59:59.000Z' },
    { ...enabled, LIVE_TEST_OTP_EXPIRES_AT: 'not-a-date' },
    { ...enabled, LIVE_TEST_OTP_EXPIRES_AT: '' },
    { ...enabled, LIVE_TEST_OTP_PHONE_ALLOWLIST: '' },
    { ...enabled, LIVE_TEST_OTP_VALUE: 'not-an-otp' },
  ]) {
    assert.equal(resolveLiveTestOtpConfig(env, now).enabled, false);
    assert.equal(matchesLiveTestOtp(allowedPhone, '111111', env, now), false);
  }
});
