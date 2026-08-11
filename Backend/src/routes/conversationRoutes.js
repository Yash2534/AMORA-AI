const router = require('express').Router();
const { body, param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const conversationController = require('../controllers/conversationController');
const messageController = require('../controllers/messageController');
const { chatMessageLimiter, chatMediaLimiter } = require('../middleware/rateLimiter');
const { upload } = require('../utils/chatMediaStorage');

const conversationId = param('conversationId').isInt({ min: 1 }).withMessage('conversationId must be valid.').toInt();
const page = query('page').optional().isInt({ min: 1, max: 100000 }).withMessage('page must be valid.').toInt();
const listLimit = query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('limit must be between 1 and 50.').toInt();
const historyLimit = query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100.').toInt();

const uploadMedia = (req, res, next) => upload.single('media')(req, res, (error) => {
  if (!error) return next();
  const code = error.code === 'LIMIT_FILE_SIZE'
    ? 'MEDIA_TOO_LARGE'
    : error.code === 'INVALID_MEDIA_TYPE'
      ? 'INVALID_MEDIA_TYPE'
      : 'VALIDATION_ERROR';
  return res.status(400).json({
    success: false,
    message: error.message || 'Media upload failed.',
    code,
    errors: [{ field: 'media', message: error.message || 'Media upload failed.' }],
  });
});

router.use(requireAuth);
router.get('/', [page, listLimit], validate, conversationController.list);
router.post('/', [
  body('targetUserId').isInt({ min: 1 }).withMessage('targetUserId must be valid.').toInt(),
], validate, conversationController.create);
router.get('/:conversationId/messages', [conversationId, historyLimit,
  query('beforeId').optional().isInt({ min: 1 }).withMessage('beforeId must be valid.').toInt(),
], validate, messageController.history);
router.post('/:conversationId/messages', chatMessageLimiter, [conversationId,
  body('text').isString().trim().isLength({ min: 1, max: 4000 }).withMessage('text must be between 1 and 4000 characters.'),
  body('context').optional({ nullable: true }).isObject().withMessage('context must be an object.'),
], validate, messageController.send);
router.put('/:conversationId/read', [conversationId,
  body('messageId').optional({ nullable: true }).isInt({ min: 1 }).withMessage('messageId must be valid.').toInt(),
], validate, messageController.read);
router.post('/:conversationId/media', chatMediaLimiter, [conversationId], validate, uploadMedia, [
  body('caption').optional({ nullable: true }).isString().trim().isLength({ max: 4000 }).withMessage('caption must be 4000 characters or less.'),
], validate, messageController.media);
router.put('/:conversationId/draft', [conversationId,
  body('text').isString().trim().isLength({ max: 4000 }).withMessage('text must be 4000 characters or less.'),
], validate, messageController.saveDraft);
router.delete('/:conversationId/draft', [conversationId], validate, messageController.clearDraft);
router.put('/:conversationId/mute', [conversationId,
  body('mutedUntil').optional({ nullable: true }).isISO8601().withMessage('mutedUntil must be an ISO date.'),
], validate, conversationController.mute);
router.delete('/:conversationId/mute', [conversationId], validate, conversationController.unmute);

module.exports = router;
