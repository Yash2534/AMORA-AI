const { validationResult } = require('express-validator');
module.exports = (req, res, next) => {
  const result = validationResult(req);
  if (result.isEmpty()) return next();
  return res.status(400).json({ success: false, message: 'Validation failed.', code: 'VALIDATION_ERROR', errors: result.array().map((e) => ({ field: e.path, message: e.msg })) });
};
