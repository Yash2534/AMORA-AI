const router = require('express').Router();
const { body, param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/eventController');
const { eventActionLimiter, eventMessageLimiter, eventFeedbackLimiter } = require('../middleware/rateLimiter');
const { upload: feedbackUpload } = require('../utils/eventFeedbackMediaStorage');

const eventId = param('eventId').isInt({ min: 1 }).withMessage('eventId must be valid.').toInt();
const page = query('page').optional().isInt({ min: 1, max: 100000 }).withMessage('page must be valid.').toInt();
const limit = query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100.').toInt();

router.use(requireAuth);
router.get('/', [page, limit,
  query('search').optional().isString().trim().isLength({ max: 120 }).withMessage('search must be 120 characters or less.'),
  query('category').optional().isString().trim().isLength({ min: 1, max: 80 }).withMessage('category is invalid.'),
  query('city').optional().isString().trim().isLength({ min: 1, max: 100 }).withMessage('city is invalid.'),
  query('dateFrom').optional().isISO8601().withMessage('dateFrom must be an ISO date.'),
  query('dateTo').optional().isISO8601().withMessage('dateTo must be an ISO date.'),
  query('timing').optional().isIn(['upcoming', 'past', 'all']).withMessage('timing is invalid.'),
  query('past').optional().isBoolean().withMessage('past must be true or false.').toBoolean(),
  query('available').optional().isBoolean().withMessage('available must be true or false.').toBoolean(),
], validate, controller.list);
router.get('/me', [page, limit, query('category').optional().isIn(['all', 'upcoming', 'past', 'waitlist', 'cancelled']).withMessage('category is invalid.')], validate, controller.myEvents);
router.get('/:eventId', [eventId], validate, controller.detail);
router.post('/:eventId/registration', eventActionLimiter, [eventId], validate, controller.register);
router.delete('/:eventId/registration', eventActionLimiter, [eventId], validate, controller.cancelRegistration);
router.post('/:eventId/waitlist', eventActionLimiter, [eventId], validate, controller.joinWaitlist);
router.delete('/:eventId/waitlist', eventActionLimiter, [eventId], validate, controller.leaveWaitlist);
router.post('/:eventId/check-in', eventActionLimiter, [eventId], validate, controller.checkIn);
const uploadFeedback = (req, res, next) => feedbackUpload.single('media')(req, res, (error) => {
  if (!error) return next();
  const code = error.code === 'LIMIT_FILE_SIZE' ? 'MEDIA_TOO_LARGE' : error.code === 'INVALID_MEDIA_TYPE' ? 'INVALID_MEDIA_TYPE' : 'VALIDATION_ERROR';
  return res.status(400).json({ success: false, message: error.message || 'Feedback photo upload failed.', code, errors: [{ field: 'media', message: error.message || 'Feedback photo upload failed.' }] });
});

router.post('/:eventId/feedback', eventFeedbackLimiter, uploadFeedback, [eventId,
  body('rating').isInt({ min: 1, max: 5 }).withMessage('rating must be between 1 and 5.').toInt(),
  ...['venueRating', 'hostRating', 'safetyRating', 'experienceRating'].map((field) => body(field).optional({ nullable: true }).isInt({ min: 1, max: 5 }).withMessage(`${field} must be between 1 and 5.`).toInt()),
  body('feedbackText').optional({ nullable: true }).isString().trim().isLength({ max: 2000 }).withMessage('feedbackText must be 2000 characters or less.'),
  body('recommend').optional().isBoolean().withMessage('recommend must be true or false.').toBoolean(),
], validate, controller.feedback);
router.get('/:eventId/group-chat/messages', [eventId, limit, query('beforeId').optional().isInt({ min: 1 }).withMessage('beforeId must be valid.').toInt()], validate, controller.groupMessages);
router.post('/:eventId/group-chat/messages', eventMessageLimiter, [eventId, body('text').isString().trim().isLength({ min: 1, max: 2000 }).withMessage('text must be between 1 and 2000 characters.')], validate, controller.sendGroupMessage);

module.exports = router;
