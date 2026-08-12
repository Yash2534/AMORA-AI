const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/roseController');
const { roseSendLimiter } = require('../middleware/rateLimiter');

router.post('/send', requireAuth, roseSendLimiter, [
  body('recipientId').isInt({ min: 1 }).withMessage('recipientId must be a valid user id.').toInt(),
  body('conversationId').optional().isInt({ min: 1 }).withMessage('conversationId must be valid.').toInt(),
  body('note').optional().isString().trim().isLength({ max: 280 }).withMessage('note must be 280 characters or less.'),
  body('idempotencyKey').optional().isString().isLength({ min: 8, max: 100 }),
], validate, controller.send);

module.exports = router;
