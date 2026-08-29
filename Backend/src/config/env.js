const required = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'JWT_SECRET', 'JWT_REFRESH_SECRET', 'ADMIN_JWT_SECRET'];
const { resolveOtpTestConfig } = require('./otpTestConfig');

const otpTestConfig = resolveOtpTestConfig();
for (const key of required) {
  if (!process.env[key]) throw new Error(`Missing required environment variable: ${key}`);
}
for (const key of ['JWT_SECRET', 'JWT_REFRESH_SECRET', 'ADMIN_JWT_SECRET']) {
  if (String(process.env[key]).length < 32) throw new Error(`${key} must contain at least 32 characters.`);
}
if (new Set([process.env.JWT_SECRET, process.env.JWT_REFRESH_SECRET, process.env.ADMIN_JWT_SECRET]).size !== 3) {
  throw new Error('JWT_SECRET, JWT_REFRESH_SECRET, and ADMIN_JWT_SECRET must be distinct.');
}
const smtpConfigured = ['EMAIL_HOST', 'EMAIL_USER', 'EMAIL_PASS'].every((key) => Boolean(process.env[key]));
if (process.env.NODE_ENV === 'production' && !smtpConfigured) {
  throw new Error('Production requires EMAIL_HOST, EMAIL_USER, and EMAIL_PASS to be configured.');
}
if (process.env.NODE_ENV === 'production') {
  if (!process.env.ADMIN_WEB_RESET_URL || !String(process.env.ADMIN_WEB_RESET_URL).startsWith('https://')) {
    throw new Error('Production requires an HTTPS ADMIN_WEB_RESET_URL.');
  }
  if (!process.env.CORS_ORIGIN || process.env.CORS_ORIGIN === '*') {
    throw new Error('Production requires an explicit CORS_ORIGIN for credentialed administrator sessions.');
  }
}
module.exports = { port: Number(process.env.PORT || 5000), smtpConfigured, otpTestConfig };
