const { UniqueConstraintError, ValidationError } = require('sequelize');
const logger = require('../utils/logger');
module.exports = (err, req, res, _next) => {
  const meta = String(req.originalUrl || '').startsWith('/api/admin/')
    ? { meta: { requestId: req.adminCorrelationId || null } }
    : {};
  if (err.type === 'entity.parse.failed' || (err.status === 400 && err instanceof SyntaxError && 'body' in err)) {
    return res.status(400).json({ success: false, message: 'Request body is not valid JSON.', code: 'MALFORMED_JSON', errors: [], ...meta });
  }
  if (err instanceof UniqueConstraintError) return res.status(409).json({ success: false, message: 'A record with that value already exists.', code: 'CONFLICT', errors: err.errors.map((e) => ({ field: e.path, message: e.message })), ...meta });
  if (err instanceof ValidationError) return res.status(422).json({ success: false, message: 'Validation failed.', code: 'VALIDATION_ERROR', errors: err.errors.map((e) => ({ field: e.path, message: e.message })), ...meta });
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') return res.status(401).json({ success: false, message: 'Invalid or expired token.', code: err.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID', errors: [], ...meta });
  if (Number.isInteger(err.status) && err.status >= 400 && err.status < 500) return res.status(err.status).json({ success: false, message: err.message, code: err.code || 'REQUEST_FAILED', errors: [], ...meta });
  // Server-side failures stay generic unless the error was explicitly curated
  // with expose=true, a static public message, and a domain code.
  if (err.expose === true && typeof err.code === 'string' && Number.isInteger(err.status) && err.status >= 500 && err.status < 600) {
    logger.error('[Request] Domain server error.', { error: err, requestId: req.adminCorrelationId || null });
    return res.status(err.status).json({ success: false, message: err.message, code: err.code, errors: [], ...meta });
  }
  logger.error('[Request] Unexpected server error.', { error: err, requestId: req.adminCorrelationId || null });
  const isAdminRequest = String(req.originalUrl || '').startsWith('/api/admin/');
const isDevOrTest = ['development', 'test'].includes(process.env.NODE_ENV);
  return res.status(500).json({ success: false, message: isDevOrTest && !isAdminRequest ? err.message : 'An unexpected server error occurred.', code: 'INTERNAL_ERROR', errors: [], ...meta });
};
