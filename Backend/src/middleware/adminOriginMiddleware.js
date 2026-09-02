const { failure } = require('../admin/responses');

module.exports = function requireTrustedAdminOrigin(request, response, next) {
  // CSRF boundary: browser state-changing requests must present the configured
  // Admin Web origin in production. Read-only requests and non-browser tooling
  // are intentionally not rejected solely because Origin is absent.
  if (['GET', 'HEAD', 'OPTIONS'].includes(request.method)) return next();
  const origin = String(request.headers.origin || '').trim();
  const fetchSite = String(request.headers['sec-fetch-site'] || '').trim().toLowerCase();
  if (!origin) {
    if (process.env.NODE_ENV === 'production' && fetchSite) {
      return failure(request, response, 403, 'ORIGIN_REQUIRED', 'Administrator requests must include a trusted origin.');
    }
    return next();
  }
  const allowed = String(process.env.CORS_ORIGIN || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  if (allowed.includes(origin)) return next();
  return failure(request, response, 403, 'ORIGIN_DENIED', 'The request origin is not allowed.');
};
