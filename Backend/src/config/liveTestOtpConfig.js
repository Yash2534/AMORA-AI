const crypto = require('crypto');

const OTP_PATTERN = /^\d{6}$/;

function booleanValue(env, key) {
  const raw = String(env[key] || '').trim().toLowerCase();
  return raw === 'true';
}

function normalizeIndianPhone(value) {
  const digits = String(value || '').replace(/\D/g, '');
  const national = digits.length === 12 && digits.startsWith('91')
    ? digits.slice(2)
    : digits;
  return /^[6-9]\d{9}$/.test(national) ? `+91${national}` : null;
}

function parseAllowlist(value) {
  const entries = String(value || '').split(',').map((item) => item.trim()).filter(Boolean);
  const normalized = entries.map(normalizeIndianPhone);
  if (normalized.some((phone) => !phone)) return null;
  return new Set(normalized);
}

function resolveLiveTestOtpConfig(env = process.env, now = new Date()) {
  const production = String(env.NODE_ENV || '').trim().toLowerCase() === 'production';
  const requested = booleanValue(env, 'LIVE_TEST_OTP_ENABLED');
  if (!production || !requested) {
    return Object.freeze({ enabled: false, allowlist: new Set(), expiresAt: null, value: '' });
  }

  const value = String(env.LIVE_TEST_OTP_VALUE || '').trim();
  const allowlist = parseAllowlist(env.LIVE_TEST_OTP_PHONE_ALLOWLIST);
  const expiresAt = new Date(String(env.LIVE_TEST_OTP_EXPIRES_AT || '').trim());
  const valid = OTP_PATTERN.test(value)
    && allowlist?.size > 0
    && !Number.isNaN(expiresAt.getTime())
    && expiresAt > now;

  // A malformed or elapsed temporary configuration must fail closed without
  // interrupting normal production authentication.
  if (!valid) {
    return Object.freeze({ enabled: false, allowlist: new Set(), expiresAt: null, value: '' });
  }
  return Object.freeze({ enabled: true, allowlist, expiresAt, value });
}

function matchesLiveTestOtp(phoneNumber, submittedOtp, env = process.env, now = new Date()) {
  const config = resolveLiveTestOtpConfig(env, now);
  const phone = normalizeIndianPhone(phoneNumber);
  const submitted = String(submittedOtp || '');
  if (!config.enabled || !phone || !config.allowlist.has(phone) || !OTP_PATTERN.test(submitted)) {
    return false;
  }
  return crypto.timingSafeEqual(Buffer.from(submitted), Buffer.from(config.value));
}

function skipsLiveTestOtpDelivery(phoneNumber, env = process.env, now = new Date()) {
  const config = resolveLiveTestOtpConfig(env, now);
  const phone = normalizeIndianPhone(phoneNumber);
  return Boolean(config.enabled && phone && config.allowlist.has(phone));
}

function maskedPhone(phoneNumber) {
  const normalized = normalizeIndianPhone(phoneNumber);
  return normalized ? `${normalized.slice(0, 3)}******${normalized.slice(-3)}` : 'invalid-phone';
}

module.exports = {
  matchesLiveTestOtp,
  maskedPhone,
  normalizeIndianPhone,
  resolveLiveTestOtpConfig,
  skipsLiveTestOtpDelivery,
};
