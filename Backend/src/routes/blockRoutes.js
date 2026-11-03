const router = require('express').Router();
const { param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/blockController');

const userId = param('userId').isInt({ min: 1 }).withMessage('userId must be a valid user id.').toInt();
router.use(requireAuth);
router.get('/', [query('page').optional().isInt({ min: 1, max: 10000 }).toInt(), query('limit').optional().isInt({ min: 1, max: 50 }).toInt()], validate, controller.list);
router.post('/:userId', [userId], validate, controller.create);
router.delete('/:userId', [userId], validate, controller.remove);
module.exports = router;
