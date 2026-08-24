const router = require('express').Router();
const { body, param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminProfileController');
const { upload } = require('../utils/photoStorage');

const profileId = () => param('profileId').isInt({ min: 1 }).withMessage('A valid profile ID is required.').toInt();
const photoId = () => param('photoId').isString().matches(/^[A-Za-z0-9_-]{32}$/).withMessage('A valid photo ID is required.');
const page = () => [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
];
const uploadOne = (req, res, next) => upload.single('file')(req, res, (error) => {
  if (!error) return next();
  const code = error.code === 'LIMIT_FILE_SIZE' ? 'PHOTO_TOO_LARGE'
    : error.code === 'INVALID_PHOTO_TYPE' ? 'INVALID_PHOTO_TYPE' : 'VALIDATION_ERROR';
  return res.status(400).json({ success: false, message: error.message || 'Profile photo upload failed.', code, errors: [], meta: { requestId: req.adminCorrelationId || null } });
});

router.get('/', [
  ...page(),
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('profileStatus').optional().isString().isLength({ min: 1, max: 40 }),
  query('verificationStatus').optional().isIn(['pending', 'under_review', 'verified', 'rejected', 'not_submitted']),
  query('completionFrom').optional().isInt({ min: 0, max: 100 }).toInt(),
  query('completionTo').optional().isInt({ min: 0, max: 100 }).toInt(),
  query('hasPhotos').optional().isBoolean(),
  query('registeredFrom').optional().isISO8601(),
  query('registeredTo').optional().isISO8601(),
  query('updatedFrom').optional().isISO8601(),
  query('updatedTo').optional().isISO8601(),
  query('sortBy').optional().isIn(['displayName', 'completionPercentage', 'verificationStatus', 'createdAt', 'updatedAt', 'photoCount']),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
], validate, requireAdminPermission('profiles.view'), controller.list);
router.get('/options/:category', [param('category').isString().isLength({ min: 1, max: 80 })], validate, requireAdminPermission('profiles.view'), controller.taxonomy);
router.get('/:profileId', [profileId()], validate, requireAdminPermission('profiles.details.view'), controller.details);
router.patch('/:profileId', [profileId(), body().isObject()], validate, requireAdminPermission('profiles.edit'), controller.update);
router.get('/:profileId/preview', [profileId()], validate, requireAdminPermission('profiles.preview'), controller.preview);
router.get('/:profileId/photos', [profileId()], validate, requireAdminPermission('profiles.photos.view'), controller.photos);
router.post('/:profileId/photos', [profileId()], validate, requireAdminPermission('profiles.photos.manage'), uploadOne, controller.uploadPhoto);
router.patch('/:profileId/photos/reorder', [profileId(), body('photoIds').isArray({ min: 1, max: 6 })], validate, requireAdminPermission('profiles.photos.manage'), controller.reorderPhotos);
router.delete('/:profileId/photos/:photoId', [profileId(), photoId()], validate, requireAdminPermission('profiles.photos.manage'), controller.removePhoto);
router.patch('/:profileId/photos/:photoId', [profileId(), photoId(), body('isPrimary').isBoolean().custom((value) => value === true)], validate, requireAdminPermission('profiles.photos.manage'), controller.setPrimaryPhoto);
router.get('/:profileId/audit-history', [profileId(), ...page()], validate, requireAdminPermission('profiles.audit.view'), controller.audit);

module.exports = router;
