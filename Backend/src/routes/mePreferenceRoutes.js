const router = require('express').Router();
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/mePreferenceController');
const { discoverPreferenceValidation } = require('../middleware/discoverPreferenceValidation');

router.use(requireAuth);
router.get('/', controller.get);
router.put('/', discoverPreferenceValidation, validate, controller.update);

module.exports = router;
