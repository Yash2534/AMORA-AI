const { validationResult } = require('express-validator');

const validate = (message = 'Validation failed.') => (req, res, next) => {
  const result = validationResult(req);
  if (result.isEmpty()) return next();
  return res.status(400).json({
    success: false,
    message,
    code: 'VALIDATION_ERROR',
    errors: result.array().map((error) => ({
      field: error.path,
      message: error.msg,
    })),
  });
};

const defaultValidator = validate();
defaultValidator.withMessage = validate;

module.exports = defaultValidator;
