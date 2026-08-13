const router = require('express').Router();
const { param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/eventController');
const { eventActionLimiter } = require('../middleware/rateLimiter');

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

module.exports = router;
