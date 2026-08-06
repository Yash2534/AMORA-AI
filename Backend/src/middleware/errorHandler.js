const { UniqueConstraintError, ValidationError } = require('sequelize');
module.exports = (err, _req, res, _next) => {
  if (err instanceof UniqueConstraintError) return res.status(409).json({ success: false, message: 'A record with that value already exists.', code: 'EMAIL_EXISTS', errors: err.errors.map((e) => ({ field: e.path, message: e.message })) });
  if (err instanceof ValidationError) return res.status(400).json({ success: false, message: 'Validation failed.', code: 'VALIDATION_ERROR', errors: err.errors.map((e) => ({ field: e.path, message: e.message })) });
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') return res.status(401).json({ success: false, message: 'Invalid or expired token.', code: err.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID', errors: [] });
  console.error('[Error]', err.message);
  return res.status(500).json({ success: false, message: process.env.NODE_ENV === 'production' ? 'An unexpected error occurred.' : err.message, code: 'INTERNAL_ERROR', errors: [] });
};
