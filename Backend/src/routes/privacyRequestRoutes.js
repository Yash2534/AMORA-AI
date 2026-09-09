const router = require('express').Router();
const { body, param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/privacyRequestController');

const types = ['ACCESS', 'EXPORT', 'CORRECTION', 'WITHDRAWAL'];
router.use(requireAuth);
router.post('/', [body('requestType').isString().trim().isIn(types).withMessage('requestType is invalid.')], validate, controller.create);
router.get('/', controller.listMine);
router.get('/:id', [param('id').isInt({ min: 1 }).withMessage('Privacy request id is invalid.')], validate, controller.getMine);

module.exports = router;
