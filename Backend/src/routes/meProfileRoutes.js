const router = require('express').Router();
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/profileController');
const { profileUpdateValidation } = require('../middleware/profileValidation');

router.use(requireAuth);
router.get('/', controller.getOwnProfile);
router.put('/', profileUpdateValidation, validate, controller.updateOwnProfile);

module.exports = router;
