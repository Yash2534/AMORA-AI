const router = require('express').Router();
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminDataIntegrityController');

router.get('/data-integrity', requireAdminPermission('systemSettings.view'), controller.overview);
router.post('/data-integrity/run-check', requireAdminPermission('systemSettings.update'), controller.runCheck);

module.exports = router;
