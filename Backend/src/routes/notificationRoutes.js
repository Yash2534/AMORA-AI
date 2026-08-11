const router = require('express').Router();
const { param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/notificationController');

const id = param('notificationId').isInt({ min: 1 }).withMessage('notificationId must be valid.').toInt();
const categories = ['Matches', 'Messages', 'Likes', 'Super Likes', 'Events', 'Profile Views', 'Verification', 'Security', 'Payments', 'Offers'];

router.use(requireAuth);
router.get('/', [
  query('page').optional().isInt({ min: 1, max: 100000 }).withMessage('page is invalid.').toInt(),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('limit is invalid.').toInt(),
  query('unread').optional().isBoolean().withMessage('unread must be a boolean.'),
  query('category').optional().isIn(categories).withMessage('category is invalid.'),
], validate, controller.list);
router.put('/read-all', controller.readAll);
router.put('/:notificationId/read', [id], validate, controller.read);
router.delete('/:notificationId', [id], validate, controller.remove);

module.exports = router;
