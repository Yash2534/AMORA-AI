const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/blockController');

const userId = param('userId').isInt({ min: 1 }).withMessage('userId must be a valid user id.').toInt();
router.use(requireAuth);
router.get('/', controller.list);
router.post('/:userId', [userId], validate, controller.create);
router.delete('/:userId', [userId], validate, controller.remove);
module.exports = router;
