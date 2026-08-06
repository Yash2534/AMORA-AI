const required = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'JWT_SECRET', 'JWT_REFRESH_SECRET'];
for (const key of required) {
  if (!process.env[key]) throw new Error(`Missing required environment variable: ${key}`);
}
const smtpConfigured = ['EMAIL_HOST', 'EMAIL_USER', 'EMAIL_PASS'].every((key) => Boolean(process.env[key]));
if (process.env.NODE_ENV === 'production' && !smtpConfigured) {
  throw new Error('Production requires EMAIL_HOST, EMAIL_USER, and EMAIL_PASS to be configured.');
}
module.exports = { port: Number(process.env.PORT || 5000), smtpConfigured };
