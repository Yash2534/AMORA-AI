const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/deviceController');

const token = body('pushToken').isString().trim().isLength({ min: 20, max: 512 }).withMessage('pushToken is invalid.');
router.use(requireAuth);
router.post('/', [token, body('platform').isIn(['android', 'ios', 'web']), body('installationId').optional().isString().trim().isLength({ max: 160 })], validate, controller.register);
router.delete('/', [token], validate, controller.remove);
module.exports = router;
