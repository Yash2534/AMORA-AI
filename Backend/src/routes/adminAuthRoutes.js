const router = require('express').Router();
const { body, param } = require('express-validator');
const rateLimit = require('express-rate-limit');
const controller = require('../controllers/adminAuthController');
const managementController = require('../controllers/adminManagementController');
const validate = require('../middleware/validateRequest');
const requireAdminAuth = require('../middleware/adminAuthMiddleware');
const requireTrustedOrigin = require('../middleware/adminOriginMiddleware');

const adminLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `${req.ip}:${String(req.body.email || '').trim().toLowerCase()}`,
  handler: (_req, res) => res.status(429).json({
    success: false,
    message: 'Too many administrator login attempts. Please try again later.',
    code: 'RATE_LIMITED',
    errors: [],
  }),
});

const refreshLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, res) => res.status(429).json({
    success: false,
    message: 'Too many session refresh attempts. Please try again later.',
    code: 'RATE_LIMITED',
    errors: [],
  }),
});

const recoveryLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => res.status(429).json({
    success: false,
    message: 'Too many password recovery attempts. Please try again later.',
    code: 'RATE_LIMITED',
    errors: [],
    meta: { requestId: req.adminCorrelationId || null },
  }),
});

const passwordFields = () => [
  body('newPassword').isString().isLength({ min: 8, max: 128 })
    .withMessage('New password must contain between 8 and 128 characters.'),
  body('confirmPassword').custom((value, { req }) => value === req.body.newPassword)
    .withMessage('Password confirmation does not match.'),
];

router.use(requireTrustedOrigin);

router.post('/login', adminLoginLimiter, [
  body('email').trim().isEmail().withMessage('A valid administrator email is required.').normalizeEmail(),
  body('password').isString().isLength({ min: 8, max: 128 }).withMessage('Password must contain between 8 and 128 characters.'),
  body('rememberMe').optional().isBoolean().withMessage('rememberMe must be a boolean.').toBoolean(),
], validate, controller.login);
router.post('/refresh', refreshLimiter, controller.refresh);
router.post('/logout', controller.logout);
router.post('/forgot-password', recoveryLimiter, [
  body('email').trim().isEmail().withMessage('A valid administrator email is required.').normalizeEmail(),
], validate, controller.forgotPassword);
router.post('/validate-reset-token', recoveryLimiter, [
  body('token').matches(/^[a-f0-9]{32}\.[a-f0-9]{64}$/).withMessage('A valid reset token is required.'),
], validate, controller.validateResetToken);
router.post('/reset-password', recoveryLimiter, [
  body('token').matches(/^[a-f0-9]{32}\.[a-f0-9]{64}$/).withMessage('A valid reset token is required.'),
  ...passwordFields(),
], validate, controller.resetPassword);
router.post('/validate-invitation', recoveryLimiter, [
  body('token').matches(/^[a-f0-9]{32}\.[a-f0-9]{64}$/).withMessage('A valid invitation token is required.'),
], validate, managementController.invitationStatus);
router.post('/accept-invitation', recoveryLimiter, [
  body('token').matches(/^[a-f0-9]{32}\.[a-f0-9]{64}$/).withMessage('A valid invitation token is required.'),
  ...passwordFields(),
], validate, managementController.acceptInvitation);
router.get('/me', requireAdminAuth, controller.me);
router.post('/change-password', requireAdminAuth, [
  body('currentPassword').isString().isLength({ min: 8, max: 128 }).withMessage('Current password is required.'),
  ...passwordFields(),
], validate, controller.changePassword);
router.get('/sessions', requireAdminAuth, controller.sessions);
router.post('/sessions/:sessionId/revoke', requireAdminAuth, [
  param('sessionId').isInt({ min: 1 }).withMessage('A valid session ID is required.').toInt(),
], validate, controller.revokeSession);

module.exports = router;
