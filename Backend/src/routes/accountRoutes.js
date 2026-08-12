const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/accountController');

const deletionReasons = ['found_someone', 'taking_a_break', 'not_finding_matches', 'privacy_concerns', 'too_many_notifications', 'app_experience_issues', 'other'];
router.post('/deactivate', requireAuth, controller.deactivate);
router.delete('/', requireAuth, [
  body('reason').isIn(deletionReasons).withMessage('reason is invalid.'),
  body('details').optional({ nullable: true }).isString().trim().isLength({ max: 240 }).withMessage('details must be 240 characters or less.'),
  body('details').if(body('reason').equals('other')).notEmpty().withMessage('details is required when reason is other.'),
], validate, controller.remove);
module.exports = router;
