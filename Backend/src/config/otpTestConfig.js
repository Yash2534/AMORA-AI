const crypto = require('crypto');

const APPROVED_ENVIRONMENTS = new Set(['development', 'test', 'qa', 'staging']);
const OTP_PATTERN = /^\d{6}$/;

function booleanValue(env, key) {
  const raw = String(env[key] || '').trim().toLowerCase();
  if (!raw) return false;
  if (raw === 'true') return true;
  if (raw === 'false') return false;
  throw new Error(`${key} must be either true or false.`);
}

function resolveOtpTestConfig(env = process.env) {
  const environment = String(env.NODE_ENV || '').trim().toLowerCase();
  const enabled = booleanValue(env, 'TEST_FIXED_OTP_ENABLED');
  const skipDelivery = booleanValue(env, 'TEST_OTP_SKIP_DELIVERY');
  const fixedOtp = String(env.TEST_FIXED_OTP || '').trim();

  if (environment === 'production' && (enabled || skipDelivery || fixedOtp)) {
    throw new Error(
      'Production must not configure TEST_FIXED_OTP_ENABLED, TEST_FIXED_OTP, or TEST_OTP_SKIP_DELIVERY.',
    );
  }
  if (enabled && !APPROVED_ENVIRONMENTS.has(environment)) {
    throw new Error(
      `Fixed test OTP mode is not permitted when NODE_ENV is '${environment || 'unset'}'.`,
    );
  }
  if (enabled && !OTP_PATTERN.test(fixedOtp)) {
    throw new Error('TEST_FIXED_OTP must contain exactly six numeric digits when test OTP mode is enabled.');
  }
  if (skipDelivery && !enabled) {
    throw new Error('TEST_OTP_SKIP_DELIVERY requires TEST_FIXED_OTP_ENABLED=true.');
  }

  return Object.freeze({ environment, enabled, fixedOtp, skipDelivery });
}

function matchesFixedOtp(submittedOtp, env = process.env) {
  const config = resolveOtpTestConfig(env);
  if (!config.enabled || !OTP_PATTERN.test(String(submittedOtp || ''))) return false;
  return crypto.timingSafeEqual(
    Buffer.from(String(submittedOtp)),
    Buffer.from(config.fixedOtp),
  );
}

module.exports = {
  APPROVED_ENVIRONMENTS,
  OTP_PATTERN,
  matchesFixedOtp,
  resolveOtpTestConfig,
};
