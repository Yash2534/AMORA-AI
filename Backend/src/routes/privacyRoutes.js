const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/privacyController');

// Public DPDP Notice
router.get('/notice', controller.getPrivacyNotice);

// Public/Optional User Grievance Submission
router.post(
  '/grievances',
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
router.get('/grievances/:ticketNumber', controller.getGrievanceStatus);

// Authenticated Privacy Management
router.get('/consents', requireAuth, controller.getConsents);
router.post('/consents/update', requireAuth, controller.updateConsent);
router.post('/consents/withdraw', requireAuth, controller.withdrawConsent);
router.post('/data-export', requireAuth, controller.requestDataExport);

module.exports = router;
