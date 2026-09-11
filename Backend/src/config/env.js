const required = [
  'DB_HOST',
  'DB_PORT',
  'DB_NAME',
  'DB_USER',
  'JWT_SECRET',
  'JWT_REFRESH_SECRET',
  'ADMIN_JWT_SECRET',
];

const { resolveOtpTestConfig } = require('./otpTestConfig');
const { configuredOrigins } = require('./originPolicy');

function validateEnvironment(env = process.env) {
  const otp = resolveOtpTestConfig(env);

  // Required backend environment variables.
  for (const key of required) {
    if (!env[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }

  // JWT secrets must be sufficiently strong.
  for (const key of [
    'JWT_SECRET',
    'JWT_REFRESH_SECRET',
    'ADMIN_JWT_SECRET',
  ]) {
    if (String(env[key]).length < 32) {
      throw new Error(`${key} must contain at least 32 characters.`);
    }
  }

  // Each JWT secret must be unique.
  if (
    new Set([
      env.JWT_SECRET,
      env.JWT_REFRESH_SECRET,
      env.ADMIN_JWT_SECRET,
    ]).size !== 3
  ) {
    throw new Error(
      'JWT_SECRET, JWT_REFRESH_SECRET, and ADMIN_JWT_SECRET must be distinct.',
    );
  }

  // SMTP is currently optional.
  // The production backend is allowed to start while SMTP setup is pending.
  const smtp = [
    'EMAIL_HOST',
    'EMAIL_USER',
    'EMAIL_PASS',
  ].every((key) => Boolean(String(env[key] || '').trim()));

  if (env.NODE_ENV === 'production' && !smtp) {
    console.warn(
      '[Environment] SMTP is not configured. Email delivery features are temporarily unavailable.',
    );
  }

  // Production security requirements.
  if (env.NODE_ENV === 'production') {
    const mfaKey = String(
      env.ADMIN_MFA_ENCRYPTION_KEY || '',
    ).trim();

    const validMfaKey =
      /^[a-f0-9]{64}$/i.test(mfaKey) ||
      (() => {
        try {
          return Buffer.from(mfaKey, 'base64').length === 32;
        } catch (_) {
          return false;
        }
      })();

    if (!validMfaKey) {
      throw new Error(
        'Production requires ADMIN_MFA_ENCRYPTION_KEY to be a 256-bit hex or base64 key.',
      );
    }

    const adminResetUrl = String(
      env.ADMIN_WEB_RESET_URL || '',
    ).trim();

    if (
      adminResetUrl &&
      !adminResetUrl.startsWith('https://')
    ) {
      throw new Error(
        'Production ADMIN_WEB_RESET_URL must use HTTPS when configured.',
      );
    }

    configuredOrigins(env);
  }

  return {
    smtpConfigured: smtp,
    otpTestConfig: otp,
  };
}

const {
  smtpConfigured,
  otpTestConfig,
} = validateEnvironment(process.env);

module.exports = {
  port: Number(process.env.PORT || 5000),
  smtpConfigured,
  otpTestConfig,
  validateEnvironment,
};