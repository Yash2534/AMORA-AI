const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/profileController');
const { profileUpdateValidation } = require('../middleware/profileValidation');

router.use(requireAuth);
router.get('/me', controller.getOwnProfile);
router.put('/me', profileUpdateValidation, validate, controller.updateOwnProfile);

router.get('/:userId', [param('userId').isInt({ min: 1 }).withMessage('userId must be a valid user id.').toInt()], validate, controller.getPublicProfile);
module.exports = router;
