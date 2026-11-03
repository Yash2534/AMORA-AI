const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const { profilePhoto } = require('../controllers/mediaController');
const { mediaDownloadLimiter } = require('../middleware/rateLimiter');

router.get(
  '/profile/:userId/:filename',
  requireAuth,
  mediaDownloadLimiter,
  [
    param('userId').isInt({ min: 1 }).toInt(),
    param('filename').matches(/^[a-zA-Z0-9._-]{1,180}$/),
  ],
  validate,
  profilePhoto,
);

module.exports = router;
