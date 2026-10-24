const router = require('express').Router();
const { param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/matchController');

const matchId = param('matchId').isInt({ min: 1 }).withMessage('matchId must be valid.').toInt();
router.use(requireAuth);
const listPage = [query('page').optional().isInt({ min: 1, max: 10000 }).toInt(), query('limit').optional().isInt({ min: 1, max: 50 }).toInt()];
router.get('/', listPage, validate, controller.list);
router.get('/:matchId', [matchId], validate, controller.detail);
router.delete('/:matchId', [matchId], validate, controller.remove);
module.exports = router;
