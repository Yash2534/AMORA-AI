const { UniqueConstraintError, ValidationError } = require('sequelize');
module.exports = (err, req, res, _next) => {
  const meta = String(req.originalUrl || '').startsWith('/api/admin/')
    ? { meta: { requestId: req.adminCorrelationId || null } }
    : {};
  if (err instanceof UniqueConstraintError) return res.status(409).json({ success: false, message: 'A record with that value already exists.', code: 'CONFLICT', errors: err.errors.map((e) => ({ field: e.path, message: e.message })), ...meta });
  if (err instanceof ValidationError) return res.status(422).json({ success: false, message: 'Validation failed.', code: 'VALIDATION_ERROR', errors: err.errors.map((e) => ({ field: e.path, message: e.message })), ...meta });
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') return res.status(401).json({ success: false, message: 'Invalid or expired token.', code: err.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID', errors: [], ...meta });
  if (Number.isInteger(err.status) && err.status >= 400 && err.status < 600) return res.status(err.status).json({ success: false, message: err.message, code: err.code || 'REQUEST_FAILED', errors: [], ...meta });
  console.error('[Error]', err.message);
  const isAdminRequest = String(req.originalUrl || '').startsWith('/api/admin/');
  return res.status(500).json({ success: false, message: process.env.NODE_ENV === 'production' || isAdminRequest ? 'An unexpected server error occurred.' : err.message, code: 'INTERNAL_ERROR', errors: [], ...meta });
};
