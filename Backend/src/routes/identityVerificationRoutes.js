const router = require('express').Router();
const requireAuth = require('../middleware/authMiddleware');
const controller = require('../controllers/identityVerificationController');
const { identityVerificationLimiter } = require('../middleware/rateLimiter');
const { upload } = require('../utils/identityVerificationStorage');

const uploadSubmission = (req, res, next) => upload.fields([
  { name: 'aadhaar', maxCount: 1 },
  { name: 'selfie', maxCount: 1 },
])(req, res, (error) => {
  if (!error) return next();
  const code = error.code === 'LIMIT_FILE_SIZE' ? 'VERIFICATION_MEDIA_TOO_LARGE'
    : error.code === 'INVALID_VERIFICATION_MEDIA' ? error.code : 'VALIDATION_ERROR';
  return res.status(400).json({ success: false, message: error.message || 'Identity verification upload failed.', code, errors: [] });
});

router.use(requireAuth);
router.get('/me', controller.me);
router.post('/submissions', identityVerificationLimiter, uploadSubmission, controller.submit);

module.exports = router;
