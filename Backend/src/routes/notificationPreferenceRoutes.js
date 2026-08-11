const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/notificationPreferenceController');

const booleanFields = ['newMatches', 'messages', 'eventReminders', 'paymentsAndMembership', 'offers', 'pushEnabled', 'emailEnabled', 'smsEnabled', 'quietHoursEnabled'];
const validators = booleanFields.map((field) => body(field).optional().isBoolean().withMessage(`${field} must be a boolean.`).toBoolean());
const time = (field) => body(field).optional().matches(/^([01]\d|2[0-3]):[0-5]\d$/).withMessage(`${field} must use 24-hour HH:mm format.`);
router.use(requireAuth);
router.get('/', controller.get);
router.put('/', [...validators, time('quietStart'), time('quietEnd'), body().custom((value) => {
  const allowed = new Set([...booleanFields, 'quietStart', 'quietEnd']);
  if (Object.keys(value || {}).some((key) => !allowed.has(key))) throw new Error('Request contains an unsupported notification preference.');
  return true;
})], validate, controller.update);
module.exports = router;
