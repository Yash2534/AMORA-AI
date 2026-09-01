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
const profileListQueryKeys = new Set([
  'page', 'pageSize', 'search', 'profileStatus', 'verificationStatus',
  'hasPhotos', 'registeredFrom', 'registeredTo', 'updatedFrom', 'updatedTo',
  'sortBy', 'sortDirection',
]);
function rejectUnsupportedProfileListQuery(req, res, next) {
  const unsupported = Object.keys(req.query).filter((key) => !profileListQueryKeys.has(key));
  if (!unsupported.length) return next();
  return res.status(422).json({
    success: false,
    message: `Unsupported profile-list query parameter${unsupported.length === 1 ? '' : 's'}: ${unsupported.join(', ')}.`,
    code: 'UNSUPPORTED_QUERY_PARAMETER',
    errors: [],
    meta: { requestId: req.adminCorrelationId || null },
  });
}
const uploadOne = (req, res, next) => upload.single('file')(req, res, (error) => {
  if (!error) return next();
  const code = error.code === 'LIMIT_FILE_SIZE' ? 'PHOTO_TOO_LARGE'
    : error.code === 'INVALID_PHOTO_TYPE' ? 'INVALID_PHOTO_TYPE' : 'VALIDATION_ERROR';
  return res.status(400).json({ success: false, message: error.message || 'Profile photo upload failed.', code, errors: [], meta: { requestId: req.adminCorrelationId || null } });
});
const taxonomySelection = (field) => body(field).optional({ nullable: true }).custom((value) => {
  if (value === null) return true;
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error(`${field} must be a taxonomy selection.`);
  const keys = Object.keys(value);
  if (keys.some((key) => !['optionId', 'customValue'].includes(key))) throw new Error(`${field} contains unsupported fields.`);
  if (typeof value.optionId !== 'string' || !/^[A-Za-z0-9_-]{3,80}$/.test(value.optionId)) throw new Error(`${field}.optionId is invalid.`);
  if (value.customValue != null && (typeof value.customValue !== 'string' || !value.customValue.trim() || value.customValue.trim().length > 255)) {
    throw new Error(`${field}.customValue is invalid.`);
  }
  return true;
});

router.get('/', [
  rejectUnsupportedProfileListQuery,
  ...page(),
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('profileStatus').optional().isIn(['complete', 'incomplete']),
  query('verificationStatus').optional().isIn(['pending', 'under_review', 'verified', 'rejected', 'not_submitted']),
  query('hasPhotos').optional().isBoolean(),
  query('registeredFrom').optional().isISO8601(),
  query('registeredTo').optional().isISO8601(),
  query('updatedFrom').optional().isISO8601(),
  query('updatedTo').optional().isISO8601(),
  query('sortBy').optional().isIn(['displayName', 'createdAt', 'updatedAt']),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
], validate, requireAdminPermission('profiles.view'), controller.list);
router.get('/options/:category', [param('category').isIn(['education', 'occupations', 'religions', 'languages', 'interests'])], validate, requireAdminPermission('profiles.view'), controller.taxonomy);
router.get('/:profileId', [profileId()], validate, requireAdminPermission('profiles.details.view'), controller.details);
router.patch('/:profileId', [
  profileId(),
  body().isObject(),
  taxonomySelection('education'),
  taxonomySelection('occupation'),
  taxonomySelection('religion'),
  body('languageIds').optional().isArray({ max: 10 }),
  body('languageIds.*').optional().isString().matches(/^[A-Za-z0-9_-]{3,80}$/),
  body('interestIds').optional().isArray({ max: 20 }),
  body('interestIds.*').optional().isString().matches(/^[A-Za-z0-9_-]{3,80}$/),
], validate, requireAdminPermission('profiles.edit'), controller.update);
router.get('/:profileId/preview', [profileId()], validate, requireAdminPermission('profiles.preview'), controller.preview);
router.get('/:profileId/photos', [profileId()], validate, requireAdminPermission('profiles.photos.view'), controller.photos);
router.post('/:profileId/photos', [profileId()], validate, requireAdminPermission('profiles.photos.manage'), uploadOne, controller.uploadPhoto);
router.patch('/:profileId/photos/reorder', [profileId(), body('photoIds').isArray({ min: 1, max: 6 })], validate, requireAdminPermission('profiles.photos.manage'), controller.reorderPhotos);
router.delete('/:profileId/photos/:photoId', [profileId(), photoId()], validate, requireAdminPermission('profiles.photos.manage'), controller.removePhoto);
router.patch('/:profileId/photos/:photoId', [profileId(), photoId(), body('isPrimary').isBoolean().custom((value) => value === true)], validate, requireAdminPermission('profiles.photos.manage'), controller.setPrimaryPhoto);
router.get('/:profileId/audit-history', [profileId(), ...page()], validate, requireAdminPermission('profiles.audit.view'), controller.audit);

module.exports = router;
