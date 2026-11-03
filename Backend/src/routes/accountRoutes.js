const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/accountController');
const { accountDeletionOtpLimiter, accountDeletionReauthLimiter } = require('../middleware/rateLimiter');
const {
  ACCOUNT_DELETION_REASON_CODES,
  ACCOUNT_DELETION_REASON_TEXT_MAX_LENGTH,
} = require('../constants/accountDeletionReasons');
const { normalizeIndianMobile } = require('../utils/phoneNumber');

const providerReauthentication = body().custom((_value, { req }) => {
  const password = typeof req.body.password === 'string' && req.body.password.length > 0;
  const providerIdToken = typeof req.body.providerIdToken === 'string' && req.body.providerIdToken.trim().length > 0;
  if (!password && !providerIdToken) throw new Error('Current password or provider reauthentication is required.');
  return true;
});
const newPhoneNumber = body('phoneNumber')
  .customSanitizer(normalizeIndianMobile)
  .matches(/^\+91[6-9]\d{9}$/)
  .withMessage('Phone number must be a valid Indian mobile number.');

router.post('/deactivate', requireAuth, accountDeletionReauthLimiter, [
  providerReauthentication,
], validate, controller.deactivate);
router.post('/phone-change/request', requireAuth, accountDeletionReauthLimiter, [
  newPhoneNumber,
  providerReauthentication,
], validate, controller.requestPhoneChange);
router.post('/phone-change/confirm', requireAuth, accountDeletionReauthLimiter, [
  newPhoneNumber,
  body('code').isString().trim().matches(/^\d{6}$/).withMessage('code must contain six digits.'),
], validate, controller.confirmPhoneChange);
router.get('/delete/methods', requireAuth, controller.deletionMethods);
router.post('/delete/send-otp', requireAuth, accountDeletionOtpLimiter, [
  body('channel').isIn(['EMAIL', 'PHONE']).withMessage('channel must be EMAIL or PHONE.'),
], validate, controller.sendDeletionOtp);
router.post('/delete/confirm', requireAuth, accountDeletionReauthLimiter, [
  body('channel').isIn(['EMAIL', 'PHONE']).withMessage('channel must be EMAIL or PHONE.'),
  body('otp').isString().trim().matches(/^\d{6}$/).withMessage('otp must contain six digits.'),
  body('reasonCode')
    .optional({ nullable: true })
    .isIn(ACCOUNT_DELETION_REASON_CODES)
    .withMessage('reasonCode must be a supported account deletion reason.'),
  body('reasonText')
    .optional({ nullable: true })
    .isString()
    .trim()
    .isLength({ max: ACCOUNT_DELETION_REASON_TEXT_MAX_LENGTH })
    .withMessage(`reasonText must not exceed ${ACCOUNT_DELETION_REASON_TEXT_MAX_LENGTH} characters.`),
], validate, controller.confirmDeletion);
module.exports = router;
