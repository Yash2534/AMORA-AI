const router = require('express').Router();
const { body, param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminMatchingController');
const discover = require('../controllers/adminDiscoverConfigurationController');
const { actionPermission } = require('../services/adminMatchingService');

const matchId = () => param('matchId').isInt({ min: 1 }).toInt();
const page = [query('page').optional().isInt({ min: 1, max: 100000 }).toInt(), query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt()];
const dates = [query('createdFrom').optional().matches(/^\d{4}-\d{2}-\d{2}$/), query('createdTo').optional().matches(/^\d{4}-\d{2}-\d{2}$/)];
const actionAccess = (req, res, next) => {
  const permission = actionPermission[req.query.type];
  const permissions = req.adminPermissions || new Set();
  if (permission && permissions.has(permission)) {
    if (req.query.includeFailureDetails === 'true' && !permissions.has('matching.actions.failed.view')) {
      return res.status(403).json({ success: false, message: 'Failed-action permission is required.', code: 'PERMISSION_DENIED', errors: [], meta: { requestId: req.adminCorrelationId || null } });
    }
    return next();
  }
  return res.status(403).json({ success: false, message: 'Matching action permission is required.', code: 'PERMISSION_DENIED', errors: [], meta: { requestId: req.adminCorrelationId || null } });
};

router.get('/discover/settings', requireAdminPermission('discover.settings.view'), discover.settings);
router.patch('/discover/settings', [body('expectedVersion').isString().isLength({ min: 10, max: 100 }), body('values').isObject()], validate, requireAdminPermission('discover.settings.manage'), discover.updateSettings);
router.get('/discover/filter-configuration', [query('includeSensitive').optional().isBoolean()], validate, requireAdminPermission('discover.filters.view'), (req, res, next) => {
  if (req.query.includeSensitive === 'true' && !(req.adminPermissions || new Set()).has('matching.sensitiveFields.view')) return res.status(403).json({ success: false, message: 'Sensitive matching-field permission is required.', code: 'PERMISSION_DENIED', errors: [], meta: { requestId: req.adminCorrelationId || null } });
  return discover.filters(req, res, next);
});
router.patch('/discover/filter-configuration/:fieldId', [param('fieldId').matches(/^[a-z][a-z0-9_]{1,79}$/)], validate, requireAdminPermission('discover.filters.manage'), discover.updateFilter);

router.get('/matching/actions', [
  query('type').isIn(['like', 'super_like', 'rose']), ...page,
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('status').optional().matches(/^[a-z][a-z0-9_]{0,39}$/),
  query('result').optional().matches(/^[a-z][a-z0-9_]{0,39}$/),
  query('failureCode').optional().matches(/^[a-z][a-z0-9_]{0,79}$/),
  ...dates,
  query('sortBy').optional().isIn(['createdAt', 'processedAt']),
  query('sortDirection').optional().isIn(['asc', 'desc']),
  query('includeFailureDetails').optional().isBoolean(),
], validate, actionAccess, controller.actions);
router.get('/matching/actions/:actionId', [
  param('actionId').matches(/^(discover|rose|failure)_[1-9][0-9]*$/),
  query('includeFailureDetails').optional().isBoolean(),
], validate, requireAdminPermission('matching.actions.details.view'), controller.action);
router.get('/matches', [
  ...page,
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('source').optional().matches(/^[a-z][a-z0-9_]{0,39}$/),
  query('status').optional().matches(/^[a-z][a-z0-9_]{0,39}$/),
  query('conversationCreated').optional().isBoolean(),
  ...dates,
  query('sortBy').optional().isIn(['createdAt', 'updatedAt', 'status', 'aiScore']),
  query('sortDirection').optional().isIn(['asc', 'desc']),
], validate, requireAdminPermission('matching.matches.view'), controller.matches);
router.get('/matches/:matchId', [matchId()], validate, requireAdminPermission('matching.matches.view'), controller.match);
router.get('/matches/:matchId/ai-score', [matchId(), query('includeExplanation').optional().isBoolean()], validate, requireAdminPermission('matching.aiScore.view'), (req, res, next) => {
  if (req.query.includeExplanation === 'true' && !(req.adminPermissions || new Set()).has('matching.aiScore.explanation.view')) return failureResponse(req, res);
  return controller.aiScore(req, res, next);
});
router.get('/matches/:matchId/history', [matchId()], validate, requireAdminPermission('matching.audit.view'), controller.history);

function failureResponse(req, res) {
  return res.status(403).json({ success: false, message: 'Matching score explanation permission is required.', code: 'PERMISSION_DENIED', errors: [], meta: { requestId: req.adminCorrelationId || null } });
}

module.exports = router;
