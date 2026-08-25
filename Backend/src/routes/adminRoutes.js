const router = require('express').Router();
const { query } = require('express-validator');
const authRoutes = require('./adminAuthRoutes');
const requireAdminAuth = require('../middleware/adminAuthMiddleware');
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

router.use(auditContext);
router.get('/health', (_req, res) => res.json({
  success: true,
  message: 'AMORAA Admin API is healthy.',
  data: { status: 'available' },
}));
router.use('/auth', authRoutes);

router.use(requireAdminAuth);
router.use('/users', adminUserRoutes);
router.use('/profiles', adminProfileRoutes);
router.use('/verifications', adminVerificationRoutes);
router.use('/', adminFinancialRoutes);
router.use('/', adminManagementRoutes);
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
  query('from').optional().isISO8601(),
  query('to').optional().isISO8601(),
  query('sortBy').optional().isIn(['createdAt', 'action', 'targetType']),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
], validate, requireAdminPermission('auditLogs.view'), catalog.auditLogs);

module.exports = router;
