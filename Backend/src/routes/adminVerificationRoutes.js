const router = require('express').Router();
const { body, header, param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminVerificationController');

const verificationId = () => param('verificationId').isInt({ min: 1 }).withMessage('A valid verification ID is required.').toInt();
const decisionValidation = () => [
  verificationId(),
  header('Idempotency-Key').isString().matches(/^[A-Za-z0-9._:-]{8,160}$/),
  header('If-Match').isString().isLength({ min: 8, max: 160 }),
  body('expectedVersion').isString().isLength({ min: 8, max: 160 }),
  body('idempotencyKey').isString().matches(/^[A-Za-z0-9._:-]{8,160}$/),
  body('reasonCode').optional().isString().trim().matches(/^[a-z0-9_:-]{2,80}$/),
  body('detail').optional({ nullable: true }).isString().trim().isLength({ min: 1, max: 500 }),
  body('note').optional({ nullable: true }).isString().trim().isLength({ min: 1, max: 500 }),
  body('items').optional().isArray({ min: 1, max: 2 }),
  body('items.*').optional().isIn(['aadhaar', 'selfie']),
];

router.get('/', [
  query('status').isIn(['pending', 'approved', 'rejected']),
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('documentType').optional().isString().isLength({ min: 1, max: 80 }),
  query('comparisonStatus').optional().isString().isLength({ min: 1, max: 80 }),
  query('submittedFrom').optional().isISO8601(),
  query('submittedTo').optional().isISO8601(),
  query('sortBy').optional().isIn(['submittedAt', 'updatedAt', 'displayName', 'status']),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
], validate, requireAdminPermission('verifications.view'), controller.list);
router.get('/reasons', [
  query('action').isIn(['reject', 'request_resubmission']),
], validate, requireAdminPermission('verifications.view'), controller.reasons);
router.get('/:verificationId', [verificationId()], validate, requireAdminPermission('verifications.details.view'), controller.details);
router.get('/:verificationId/history', [verificationId()], validate, requireAdminPermission('verifications.history.view'), controller.history);
router.post('/:verificationId/approve', decisionValidation(), validate, requireAdminPermission('verifications.approve'), controller.approve);
router.post('/:verificationId/reject', decisionValidation(), validate, requireAdminPermission('verifications.reject'), controller.reject);
router.post('/:verificationId/request-resubmission', decisionValidation(), validate, requireAdminPermission('verifications.resubmit'), controller.requestResubmission);

module.exports = router;
