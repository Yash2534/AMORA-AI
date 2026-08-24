const { failure } = require('../admin/responses');

module.exports = function requireTrustedAdminOrigin(request, response, next) {
  const origin = String(request.headers.origin || '').trim();
  if (!origin) return next();
  const allowed = String(process.env.CORS_ORIGIN || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  if (allowed.includes(origin)) return next();
  return failure(request, response, 403, 'ORIGIN_DENIED', 'The request origin is not allowed.');
};
