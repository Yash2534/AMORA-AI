const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/reportController');
const { REPORT_REASONS, REPORT_TARGET_TYPES } = require('../constants/reportOptions');
const { reportCreateLimiter } = require('../middleware/rateLimiter');

router.use(requireAuth);
router.post('/', reportCreateLimiter, [
  body('targetType').optional().isIn(REPORT_TARGET_TYPES).withMessage('targetType is invalid.'),
  body('targetUserId').if(body('targetType').not().exists()).isInt({ min: 1 }).withMessage('targetUserId must be a valid user id.').toInt(),
  body('targetUserId').if(body('targetType').equals('profile')).isInt({ min: 1 }).withMessage('targetUserId must be a valid user id.').toInt(),
  body('targetId').if(body('targetType').isIn(['event', 'message'])).isString().trim().isLength({ min: 1, max: 255 }).withMessage('targetId is required and must be 255 characters or less.'),
  body('conversationId').optional().isInt({ min: 1 }).withMessage('conversationId must be a valid conversation id.').toInt(),
  body('reason').isIn(REPORT_REASONS).withMessage('reason is invalid.'),
  body('notes').optional({ nullable: true }).isString().trim().isLength({ max: 2000 }).withMessage('notes must be 2000 characters or less.'),
], validate, controller.create);
module.exports = router;
