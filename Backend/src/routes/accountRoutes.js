const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/accountController');
const authController = require('../controllers/authController');
const { accountDeletionReauthLimiter } = require('../middleware/rateLimiter');

const deletionReasons = ['found_someone', 'taking_a_break', 'not_finding_matches', 'privacy_concerns', 'too_many_notifications', 'app_experience_issues', 'other'];
const requireDeletionConfirmation = (req, res, next) => {
  const confirmation = String(req.body?.deletionConfirmation || '');
  if (!/^[a-f0-9]{32}\.[a-f0-9]{64}$/.test(confirmation)) {
    return res.status(401).json({ success: false, message: 'Account deletion requires re-authentication.', code: 'REAUTHENTICATION_REQUIRED', errors: [] });
  }
  return next();
};
router.post('/deactivate', requireAuth, controller.deactivate);
router.post('/deletion/reauthenticate', requireAuth, accountDeletionReauthLimiter, [
  body('password').optional().isString().notEmpty().withMessage('Password is required.'),
  body('idToken').optional().isString().notEmpty().withMessage('Google ID token is required.'),
], validate, authController.reauthenticateForAccountDeletion);
router.delete('/', requireAuth, requireDeletionConfirmation, [
  body('deletionConfirmation').isString().trim().matches(/^[a-f0-9]{32}\.[a-f0-9]{64}$/).withMessage('A valid deletion confirmation is required.'),
  body('reason').isIn(deletionReasons).withMessage('reason is invalid.'),
  body('details').optional({ nullable: true }).isString().trim().isLength({ max: 240 }).withMessage('details must be 240 characters or less.'),
  body('details').if(body('reason').equals('other')).notEmpty().withMessage('details is required when reason is other.'),
], validate, controller.remove);
module.exports = router;
