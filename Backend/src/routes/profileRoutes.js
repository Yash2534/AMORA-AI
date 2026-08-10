const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/profileController');

router.get('/:userId', requireAuth, [param('userId').isInt({ min: 1 }).withMessage('userId must be a valid user id.').toInt()], validate, controller.getPublicProfile);
module.exports = router;
