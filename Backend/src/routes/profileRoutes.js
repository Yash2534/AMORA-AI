const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/profileController');
const { profileUpdateValidation } = require('../middleware/profileValidation');

router.use(requireAuth);
const deprecatedOwnProfile = (_req, res, next) => {
  res.set('Deprecation', 'true');
  res.set('Sunset', 'Wed, 31 Dec 2026 23:59:59 GMT');
  res.set('Link', '</api/me/profile>; rel="successor-version"');
  next();
};
router.get('/me', deprecatedOwnProfile, controller.getOwnProfile);
router.put('/me', deprecatedOwnProfile, profileUpdateValidation, validate, controller.updateOwnProfile);

router.get('/:userId', [param('userId').isInt({ min: 1 }).withMessage('userId must be a valid user id.').toInt()], validate, controller.getPublicProfile);
module.exports = router;
