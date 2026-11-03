const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/privacyController');
const { grievanceLimiter } = require('../middleware/rateLimiter');

// Public DPDP Notice
router.get('/notice', controller.getPrivacyNotice);

// Public/Optional User Grievance Submission
router.post(
  '/grievances',
  requireAuth,
  grievanceLimiter,
  [
    body('name').trim().notEmpty().withMessage('name is required.'),
    body('email').isEmail().withMessage('valid email is required.'),
    body('category').isIn([
      'DATA_ACCESS',
      'DATA_CORRECTION',
      'CONSENT_WITHDRAWAL',
      'DATA_ERASURE',
      'UNAUTHORIZED_PROCESSING',
      'GENERAL_PRIVACY'
    ]).withMessage('valid category is required.'),
    body('subject').trim().notEmpty().withMessage('subject is required.'),
    body('description').trim().notEmpty().withMessage('description is required.')
  ],
  validate,
  controller.submitGrievance
);

// Track Grievance Status
router.get('/grievances/:ticketNumber', requireAuth, grievanceLimiter, controller.getGrievanceStatus);

// Authenticated Privacy Management
router.all('/consents', requireAuth, controller.legacyPrivacyFlowDisabled);
router.all('/consents/update', requireAuth, controller.legacyPrivacyFlowDisabled);
router.all('/consents/withdraw', requireAuth, controller.legacyPrivacyFlowDisabled);
router.all('/data-export', requireAuth, controller.legacyPrivacyFlowDisabled);

module.exports = router;
