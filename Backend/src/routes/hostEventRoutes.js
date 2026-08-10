const router = require('express').Router();
const { body, param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/hostEventController');
const { eventActionLimiter } = require('../middleware/rateLimiter');

const requiredString = (field, max) => body(field).isString().trim().isLength({ min: 1, max }).withMessage(`${field} is required and must be ${max} characters or less.`);
const optionalString = (field, max) => body(field).optional({ nullable: true }).isString().trim().isLength({ max }).withMessage(`${field} must be ${max} characters or less.`);
const optionalRequiredString = (field, max) => body(field).optional().isString().trim().isLength({ min: 1, max }).withMessage(`${field} must be between 1 and ${max} characters.`);
const optionalFields = [
  optionalString('address', 255), optionalString('heroImageUrl', 500), optionalString('dressCode', 120), optionalString('language', 160),
  body('latitude').optional({ nullable: true }).isFloat({ min: -90, max: 90 }).withMessage('latitude is invalid.').toFloat(),
  body('longitude').optional({ nullable: true }).isFloat({ min: -180, max: 180 }).withMessage('longitude is invalid.').toFloat(),
  body('waitlistCapacity').optional().isInt({ min: 0, max: 100000 }).withMessage('waitlistCapacity is invalid.').toInt(),
  body('price').optional().isFloat({ min: 0, max: 10000000 }).withMessage('price is invalid.').toFloat(),
  body('status').optional().isIn(['draft', 'published', 'cancelled', 'completed']).withMessage('status is invalid.'),
  body('visibility').optional().isIn(['public', 'private']).withMessage('visibility is invalid.'),
  body('registrationOpen').optional().isBoolean().withMessage('registrationOpen must be true or false.').toBoolean(),
  body('waitlistEnabled').optional().isBoolean().withMessage('waitlistEnabled must be true or false.').toBoolean(),
  body('minAge').optional({ nullable: true }).isInt({ min: 18, max: 120 }).withMessage('minAge is invalid.').toInt(),
  body('maxAge').optional({ nullable: true }).isInt({ min: 18, max: 120 }).withMessage('maxAge is invalid.').toInt(),
  body('agenda').optional().isArray({ max: 50 }).withMessage('agenda must be an array.'),
  body('facilities').optional().isArray({ max: 50 }).withMessage('facilities must be an array.'),
  body('interests').optional().isArray({ max: 50 }).withMessage('interests must be an array.'),
  body('checkInOpensAt').optional({ nullable: true }).isISO8601().withMessage('checkInOpensAt is invalid.'),
  body('checkInClosesAt').optional({ nullable: true }).isISO8601().withMessage('checkInClosesAt is invalid.'),
];

router.use(requireAuth);
router.get('/dashboard', controller.dashboard);
router.post('/events', eventActionLimiter, [
  requiredString('title', 160), requiredString('description', 10000), requiredString('category', 80), requiredString('city', 100), requiredString('venueName', 160),
  body('startDateTime').isISO8601().withMessage('startDateTime is required.'), body('endDateTime').isISO8601().withMessage('endDateTime is required.'),
  body('capacity').isInt({ min: 1, max: 100000 }).withMessage('capacity is invalid.').toInt(), ...optionalFields,
], validate, controller.create);
router.put('/events/:eventId', eventActionLimiter, [
  param('eventId').isInt({ min: 1 }).withMessage('eventId must be valid.').toInt(),
  optionalRequiredString('title', 160), optionalRequiredString('description', 10000), optionalRequiredString('category', 80), optionalRequiredString('city', 100), optionalRequiredString('venueName', 160),
  body('startDateTime').optional().isISO8601().withMessage('startDateTime is invalid.'), body('endDateTime').optional().isISO8601().withMessage('endDateTime is invalid.'),
  body('capacity').optional().isInt({ min: 1, max: 100000 }).withMessage('capacity is invalid.').toInt(), ...optionalFields,
], validate, controller.update);

module.exports = router;
