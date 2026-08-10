const router = require('express').Router();
const requireAuth = require('../middleware/authMiddleware');
const { realtimeTokenLimiter } = require('../middleware/rateLimiter');
const controller = require('../controllers/realtimeController');

router.post('/token', requireAuth, realtimeTokenLimiter, controller.token);

module.exports = router;
