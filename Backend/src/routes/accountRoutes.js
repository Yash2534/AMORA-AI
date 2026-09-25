const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/accountController');
const { accountDeletionOtpLimiter, accountDeletionReauthLimiter } = require('../middleware/rateLimiter');

router.post('/deactivate', requireAuth, accountDeletionReauthLimiter, [
  body('password').isString().notEmpty().withMessage('Current password is required.'),
], validate, controller.deactivate);
router.get('/delete/methods', requireAuth, controller.deletionMethods);
router.post('/delete/send-otp', requireAuth, accountDeletionOtpLimiter, [
  body('channel').isIn(['EMAIL', 'PHONE']).withMessage('channel must be EMAIL or PHONE.'),
], validate, controller.sendDeletionOtp);
router.post('/delete/confirm', requireAuth, accountDeletionReauthLimiter, [
  body('channel').isIn(['EMAIL', 'PHONE']).withMessage('channel must be EMAIL or PHONE.'),
  body('otp').isString().trim().matches(/^\d{6}$/).withMessage('otp must contain six digits.'),
], validate, controller.confirmDeletion);
module.exports = router;
