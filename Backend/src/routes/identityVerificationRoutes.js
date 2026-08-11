const router = require('express').Router();
const { body, param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
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
router.get('/review', [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 50 }).toInt(),
  query('status').optional().isIn(['pending', 'under_review', 'verified', 'rejected']),
], validate, controller.reviewQueue);
router.get('/:verificationId/documents/:kind', [
  param('verificationId').isInt({ min: 1 }).toInt(),
  param('kind').isIn(['aadhaar', 'selfie']),
], validate, controller.document);
router.put('/:verificationId/review', [
  param('verificationId').isInt({ min: 1 }).toInt(),
  body('status').isIn(['under_review', 'verified', 'rejected']),
  body('reviewNote').optional({ nullable: true }).isString().trim().isLength({ max: 500 }),
  body('rejectionReason').if(body('status').equals('rejected')).isString().trim().isLength({ min: 3, max: 500 }),
], validate, controller.review);

module.exports = router;
