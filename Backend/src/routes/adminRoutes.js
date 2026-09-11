const router = require('express').Router();
const { query, body } = require('express-validator');
const authRoutes = require('./adminAuthRoutes');
const requireAdminAuth = require('../middleware/adminAuthMiddleware');
const requireTrustedAdminOrigin = require('../middleware/adminOriginMiddleware');
const auditContext = require('../middleware/adminAuditMiddleware');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const validate = require('../middleware/validateRequest');
const catalog = require('../controllers/adminCatalogController');
const dashboard = require('../controllers/adminDashboardController');
const adminUserRoutes = require('./adminUserRoutes');
const adminProfileRoutes = require('./adminProfileRoutes');
const adminVerificationRoutes = require('./adminVerificationRoutes');
const adminManagementRoutes = require('./adminManagementRoutes');
const adminFinancialRoutes = require('./adminFinancialRoutes');
const adminMatchingRoutes = require('./adminMatchingRoutes');
const platformSettings = require('../controllers/platformSettingsController');
const adminSafetyRoutes = require('./adminSafetyRoutes');
const adminDataIntegrityRoutes = require('./adminDataIntegrityRoutes');
const adminSystemRoutes = require('./adminSystemRoutes');
const privacyController = require('../controllers/privacyController');
const analyticsController = require('../controllers/adminAnalyticsController');

router.use(auditContext);
router.get('/health', (_req, res) => res.json({
  success: true,
  message: 'AMORAA Admin API is healthy.',
  data: { status: 'available' },
}));
router.use('/auth', authRoutes);

router.use(requireAdminAuth);
router.use(requireTrustedAdminOrigin);
router.use('/users', adminUserRoutes);
router.use('/profiles', adminProfileRoutes);
router.use('/verifications', adminVerificationRoutes);
router.use('/', adminFinancialRoutes);
router.use('/', adminManagementRoutes);
router.use('/', adminMatchingRoutes);
router.use('/', adminSafetyRoutes);
router.use('/', adminDataIntegrityRoutes);
router.use('/', adminSystemRoutes);
router.get('/system-settings', requireAdminPermission('systemSettings.view'), platformSettings.settings);
router.patch('/system-settings', [body('values').isObject(), body('expectedVersion').optional().isString().isLength({ min: 10, max: 100 })], validate, requireAdminPermission('systemSettings.update'), platformSettings.update);
router.get('/media/:mediaId', requireAdminPermission('verifications.details.view'), require('../controllers/adminVerificationController').media);
router.get('/dashboard/overview', [
  query('range').optional().isIn(['today', '7d', '30d', '90d']),
  query('from').optional().matches(/^\d{4}-\d{2}-\d{2}$/),
  query('to').optional().matches(/^\d{4}-\d{2}-\d{2}$/),
  query('timezone').optional().isString().isLength({ min: 1, max: 80 }),
], validate, requireAdminPermission('dashboard.view'), dashboard.overview);
router.get('/dashboard/notifications', requireAdminPermission('dashboard.view'), dashboard.notifications);
router.get('/audit-logs', [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('administratorId').optional().isInt({ min: 1 }).toInt(),
  query('from').optional(),
  query('to').optional(),
  query('sortBy').optional().isIn(['createdAt', 'occurredAt', 'action', 'targetType', 'module', 'outcome', 'severity', 'id']),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
], validate, requireAdminPermission('auditLogs.view'), catalog.auditLogs);
router.get('/audit-logs/metadata', requireAdminPermission('auditLogs.view'), catalog.auditMetadata);
router.get('/audit-logs/verify-integrity', requireAdminPermission('auditLogs.view'), catalog.verifyIntegrity);
router.get('/audit-logs/:auditId', [
  require('express-validator').param('auditId').isInt({ min: 1 }).toInt(),
  query('include').optional(),
], validate, requireAdminPermission('auditLogs.details.view'), catalog.auditLog);

// DPDP Grievances Management
router.get('/privacy/grievances', privacyController.adminGetGrievances);
router.put('/privacy/grievances/:id', privacyController.adminUpdateGrievance);

const adminChat = require('../controllers/adminChatController');
const adminEvent = require('../controllers/adminEventController');

// Chat Moderation Routes
router.get('/chat/conversations', adminChat.conversations);
router.get('/chat/conversations/:id', adminChat.conversationDetail);
router.get('/chat/conversations/:id/messages', adminChat.messages);
router.get('/chat/messages', adminChat.messages);
router.post('/chat/messages/search', adminChat.messageSearch);
router.get('/chat/reports', adminChat.chatReports);
router.get('/chat/reports/:id', adminChat.reportDetail);

// Events Routes
router.get('/events', adminEvent.events);
router.get('/events/:id', adminEvent.eventDetail);

// Safe Fallback Route Handlers for Optional Admin Modules
const safeEmptyResponse = (req, res) => res.json({
  success: true,
  message: 'Data retrieved successfully.',
  data: {
    items: [],
    pagination: { page: 1, pageSize: 20, totalItems: 0, totalPages: 1 },
    metrics: {},
    summary: {},
    categories: [],
    templates: [],
    versions: [],
    variables: [],
    options: [],
    documents: [],
  },
});

router.get('/analytics/configuration', analyticsController.configuration);
router.get('/analytics/snapshot/:page', analyticsController.snapshot);
router.get('/analytics/:page', (req, res, next) => {
  if (['users', 'memberships', 'events', 'notifications', 'revenue'].includes(req.params.page)) {
    return analyticsController.snapshot(req, res, next);
  }
  return safeEmptyResponse(req, res);
});
router.get('/analytics/*', safeEmptyResponse);
router.get('/support/categories', safeEmptyResponse);
router.get('/support/templates', safeEmptyResponse);
router.get('/support/options', safeEmptyResponse);
router.get('/content/faq-categories', safeEmptyResponse);
router.get('/content/options', safeEmptyResponse);
router.get('/content/faqs*', safeEmptyResponse);
router.get('/content/documents*', safeEmptyResponse);
router.get('/membership-reports', safeEmptyResponse);
router.get('/payment-reports', safeEmptyResponse);
router.get('/notification-templates*', safeEmptyResponse);
router.get('/notification-variables*', safeEmptyResponse);
router.get('/notification-campaigns*', safeEmptyResponse);
router.get('/notification-segments*', safeEmptyResponse);
router.get('/notification-deliveries*', safeEmptyResponse);

module.exports = router;
