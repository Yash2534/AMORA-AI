const express = require('express');
const requireAuth = require('../middleware/authMiddleware');
const controller = require('../controllers/subscriptionController');
const router = express.Router();
router.get('/plans', controller.plans);
router.get('/me', requireAuth, controller.me);
router.post('/cancel', requireAuth, controller.cancel);
router.post('/restore', requireAuth, controller.restore);
module.exports = router;
