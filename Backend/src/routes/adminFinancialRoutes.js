const router = require('express').Router();
const { param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const { failure } = require('../admin/responses');
const controller = require('../controllers/adminFinancialController');

const page = () => [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
];
const common = () => [
  ...page(),
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('currency').optional().matches(/^[A-Za-z]{3}$/).toUpperCase(),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
];
const transactionProjection = () => [
  query('includeSensitive').optional().isBoolean().toBoolean(),
  query('includeReconciliation').optional().isBoolean().toBoolean(),
];

function enforceProjection(req, res, next) {
  const permissions = req.adminPermissions || new Set();
  if (req.query.includeSensitive === true && !permissions.has('payments.transactions.sensitiveFields.view')) {
    return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to view provider references.');
  }
  if (req.query.includeReconciliation === true && !permissions.has('payments.audit.view')) {
    return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to view payment reconciliation history.');
  }
  if (req.query.providerReference && !permissions.has('payments.transactions.sensitiveFields.view')) {
    return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to filter by provider reference.');
  }
  return next();
}

router.get('/membership-plans', [
  ...common(),
  query('status').optional().isIn(['active', 'inactive']),
  query('sortBy').optional().isIn(['updatedAt', 'createdAt', 'name', 'priceMinor', 'status']),
], validate, requireAdminPermission('membership.plans.view'), controller.plans);
router.get('/membership-plans/:planId', [
  param('planId').isString().trim().matches(/^[A-Za-z0-9][A-Za-z0-9._:-]{0,159}$/),
], validate, requireAdminPermission('membership.plans.view'), controller.plan);

router.get('/payment-transactions', [
  ...common(),
  ...transactionProjection(),
  query('status').optional().isIn(['created', 'authorized', 'paid', 'failed', 'cancelled', 'refunded', 'chargeback']),
  query('planId').optional().isString().trim().matches(/^[A-Za-z0-9][A-Za-z0-9._:-]{0,159}$/),
  query('hasRefund').optional().isBoolean().toBoolean(),
  query('from').optional().isISO8601(),
  query('to').optional().isISO8601(),
  query('providerReference').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('sortBy').optional().isIn(['updatedAt', 'createdAt', 'status', 'amountMinor', 'currency', 'paidAt']),
], validate, requireAdminPermission('payments.transactions.view'), enforceProjection, controller.transactions);
router.get('/payment-transactions/:transactionId', [
  param('transactionId').isInt({ min: 1 }),
  ...transactionProjection(),
], validate, requireAdminPermission('payments.transactions.details.view'), enforceProjection, controller.transaction);

module.exports = router;
