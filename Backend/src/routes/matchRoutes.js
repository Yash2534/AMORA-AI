const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/matchController');

const matchId = param('matchId').isInt({ min: 1 }).withMessage('matchId must be valid.').toInt();
router.use(requireAuth);
router.get('/', controller.list);
router.get('/:matchId', [matchId], validate, controller.detail);
router.delete('/:matchId', [matchId], validate, controller.remove);
module.exports = router;
