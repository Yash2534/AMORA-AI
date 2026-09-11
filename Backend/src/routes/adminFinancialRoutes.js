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
  query('sortBy').optional().isIn(['updatedAt', 'createdAt', 'name', 'priceMinor', 'status', 'displayOrder', 'sortOrder']),
], validate, requireAdminPermission('membership.plans.view'), controller.plans);
router.get('/membership-plans/:planId', [
  param('planId').isString().trim().matches(/^[A-Za-z0-9][A-Za-z0-9._:-]{0,159}$/),
], validate, requireAdminPermission('membership.plans.view'), controller.plan);

router.post('/membership-plans', requireAdminPermission('membership.plans.create'), controller.createPlan);
router.put('/membership-plans/:planId', requireAdminPermission('membership.plans.update'), controller.updatePlan);
router.patch('/membership-plans/:planId/status', requireAdminPermission('membership.plans.update'), controller.updatePlanStatus);
router.delete('/membership-plans/:planId', requireAdminPermission('membership.plans.delete'), controller.deletePlan);

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
  param('transactionId').isString().trim().matches(/^[A-Za-z0-9][A-Za-z0-9._:-]{0,159}$/),
  ...transactionProjection(),
], validate, requireAdminPermission('payments.transactions.view'), enforceProjection, controller.transaction);
router.get('/membership-offers', [
  ...common(),
], validate, requireAdminPermission('membership.offers.view'), controller.offers);
router.get('/membership-offers/:offerId', [
  param('offerId').isString().trim(),
], validate, requireAdminPermission('membership.offers.view'), controller.offer);

router.post('/membership-offers', requireAdminPermission('membership.offers.create'), controller.createOffer);
router.patch('/membership-offers/:offerId', requireAdminPermission('membership.offers.update'), controller.updateOffer);
router.put('/membership-offers/:offerId', requireAdminPermission('membership.offers.update'), controller.updateOffer);
router.post('/membership-offers/:offerId/activate', requireAdminPermission('membership.offers.activate'), controller.activateOffer);
router.post('/membership-offers/:offerId/deactivate', requireAdminPermission('membership.offers.update'), controller.deactivateOffer);
router.delete('/membership-offers/:offerId', requireAdminPermission('membership.offers.delete'), controller.deleteOffer);

router.get('/membership-subscriptions', [
  ...common(),
  query('status').optional().isIn(['active', 'trialing', 'past_due', 'canceled', 'unpaid', 'expired']),
  query('planId').optional().isString().trim(),
], validate, requireAdminPermission('membership.plans.view'), controller.subscriptions);

router.get('/membership-subscriptions/:subscriptionId', [
  param('subscriptionId').isString().trim(),
], validate, requireAdminPermission('membership.plans.view'), controller.subscription);

router.get('/membership-plans/:planId/subscribers', [
  ...page(),
  param('planId').isString().trim(),
], validate, requireAdminPermission('membership.plans.view'), controller.planSubscribers);

router.post('/payment-transactions/:transactionId/refund', [
  param('transactionId').isString().trim(),
], validate, requireAdminPermission('payments.refund'), controller.processRefund);

router.get('/membership-offers/:offerId/usage', [
  ...page(),
  param('offerId').isString().trim(),
], validate, requireAdminPermission('membership.offers.view'), controller.offerUsage);

router.get('/membership-offers/:offerId/analytics', [
  param('offerId').isString().trim(),
], validate, requireAdminPermission('membership.offers.view'), controller.offerAnalytics);

router.get('/analytics/revenue/overview', [
  query('range').optional().isIn(['today', 'yesterday', '7d', '30d', '90d', 'custom']),
  query('from').optional().isISO8601(),
  query('to').optional().isISO8601(),
], validate, requireAdminPermission('payments.transactions.view'), controller.revenueOverview);

router.get('/analytics/revenue/trace/:targetId', [
  param('targetId').isString().trim(),
], validate, requireAdminPermission('payments.transactions.view'), controller.revenueTrace);

router.get('/finance/reconciliation', [
  ...page(),
], validate, requireAdminPermission('payments.audit.view'), controller.reconciliation);

router.post('/finance/reconciliation/:transactionId/investigate', [
  param('transactionId').isString().trim(),
], validate, requireAdminPermission('payments.audit.view'), controller.investigateMismatch);

module.exports = router;

