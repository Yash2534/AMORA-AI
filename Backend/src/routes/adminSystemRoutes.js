const router = require('express').Router();
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminSystemController');
const requireRecentAdminMfa = require('../middleware/adminMfaMiddleware');

router.get('/system/health', requireAdminPermission('systemSettings.view'), controller.health);
router.get('/system/jobs', requireAdminPermission('systemSettings.view'), controller.jobs);
router.post('/system/jobs/:jobId/retry', requireAdminPermission('systemSettings.update'), requireRecentAdminMfa, controller.retryJob);

module.exports = router;
