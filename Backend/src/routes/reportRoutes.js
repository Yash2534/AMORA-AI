const router = require('express').Router();
const { body, param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/reportController');
const { REPORT_REASONS, REPORT_TARGET_TYPES } = require('../constants/reportOptions');
const { reportCreateLimiter, reportEvidenceLimiter } = require('../middleware/rateLimiter');
const { upload } = require('../utils/reportEvidenceStorage');

const uploadEvidence = (req, res, next) => upload.single('evidence')(req, res, (error) => {
  if (!error) return next();
  const code = error.code === 'LIMIT_FILE_SIZE' ? 'EVIDENCE_TOO_LARGE' : error.code === 'INVALID_EVIDENCE_TYPE' ? 'INVALID_EVIDENCE_TYPE' : 'VALIDATION_ERROR';
  return res.status(400).json({ success: false, message: error.message || 'Evidence upload failed.', code, errors: [{ field: 'evidence', message: error.message || 'Evidence upload failed.' }] });
});

router.use(requireAuth);
router.post('/', reportCreateLimiter, [
  body('targetType').optional().isIn(REPORT_TARGET_TYPES).withMessage('targetType is invalid.'),
  body('targetUserId').if(body('targetType').not().exists()).isInt({ min: 1 }).withMessage('targetUserId must be a valid user id.').toInt(),
  body('targetUserId').if(body('targetType').equals('profile')).isInt({ min: 1 }).withMessage('targetUserId must be a valid user id.').toInt(),
  body('targetId').if(body('targetType').isIn(['event', 'message'])).isString().trim().isLength({ min: 1, max: 255 }).withMessage('targetId is required and must be 255 characters or less.'),
  body('reason').isIn(REPORT_REASONS).withMessage('reason is invalid.'),
  body('notes').optional({ nullable: true }).isString().trim().isLength({ max: 2000 }).withMessage('notes must be 2000 characters or less.'),
], validate, controller.create);
router.post('/:reportId/evidence', reportEvidenceLimiter, [param('reportId').isInt({ min: 1 }).withMessage('reportId must be valid.').toInt()], validate, uploadEvidence, controller.addEvidence);
module.exports = router;
