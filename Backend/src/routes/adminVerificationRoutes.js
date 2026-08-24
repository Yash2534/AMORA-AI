const router = require('express').Router();
const { param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminVerificationController');

const verificationId = () => param('verificationId').isInt({ min: 1 }).withMessage('A valid verification ID is required.').toInt();

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
router.get('/reasons', requireAdminPermission('verifications.view'), controller.reasons);
router.get('/:verificationId', [verificationId()], validate, requireAdminPermission('verifications.details.view'), controller.details);
router.get('/:verificationId/history', [verificationId()], validate, requireAdminPermission('verifications.history.view'), controller.history);
router.post('/:verificationId/approve', [verificationId()], validate, requireAdminPermission('verifications.approve'), controller.decide);
router.post('/:verificationId/reject', [verificationId()], validate, requireAdminPermission('verifications.reject'), controller.decide);
router.post('/:verificationId/request-resubmission', [verificationId()], validate, requireAdminPermission('verifications.resubmit'), controller.decide);

module.exports = router;
