const router = require('express').Router();
const { body, param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const requireRecentAdminMfa = require('../middleware/adminMfaMiddleware');
const { failure } = require('../admin/responses');
const controller = require('../controllers/adminUserController');

const userId = () => param('userId').isInt({ min: 1 }).withMessage('A valid user ID is required.').toInt();
const noteId = () => param('noteId').isInt({ min: 1 }).withMessage('A valid note ID is required.').toInt();
const deletionReasons = ['found_someone', 'taking_a_break', 'not_finding_matches', 'privacy_concerns', 'too_many_notifications', 'app_experience_issues', 'other'];
const page = () => [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
];

const userListQueryKeys = new Set([
  'page', 'pageSize', 'search', 'status', 'onlineStatus', 'registeredFrom',
  'registeredTo', 'sortBy', 'sortDirection',
]);

function rejectUnsupportedUserListQuery(request, response, next) {
  const unsupported = Object.keys(request.query).filter((key) => !userListQueryKeys.has(key));
  if (unsupported.length) {
    return failure(
      request,
      response,
      422,
      'UNSUPPORTED_QUERY_PARAMETER',
      `Unsupported user-list query parameter${unsupported.length === 1 ? '' : 's'}: ${unsupported.join(', ')}.`,
    );
  }
  return next();
}

router.get('/', [
  rejectUnsupportedUserListQuery,
  ...page(),
  query('search').optional().isString().trim().isLength({ min: 1, max: 160 }),
  query('status').optional().isIn(['active', 'deactivated', 'deleted']),
  query('onlineStatus').optional().isIn(['online', 'offline']),
  query('registeredFrom').optional().isISO8601(),
  query('registeredTo').optional().isISO8601(),
  query('sortBy').optional().isIn(['displayName', 'status', 'lastActiveAt', 'createdAt']),
  query('sortDirection').optional().isIn(['asc', 'desc', 'ASC', 'DESC']),
], validate, requireAdminPermission('users.view'), controller.list);
router.get('/:userId', [userId()], validate, requireAdminPermission('users.details.view'), controller.details);
router.get('/:userId/profile', [userId()], validate, requireAdminPermission('users.profile.view'), controller.profile);
router.get('/:userId/sessions', [userId(), ...page()], validate, requireAdminPermission('users.sessions.view'), controller.sessions);
router.get('/:userId/login-history', [userId(), ...page()], validate, requireAdminPermission('users.loginHistory.view'), controller.loginHistory);
router.get('/:userId/notes', [userId(), ...page()], validate, requireAdminPermission('users.notes.view'), controller.notes);
router.post('/:userId/notes', [
  userId(),
  body('text').isString().trim().isLength({ min: 1, max: 2000 }).withMessage('Note text must be between 1 and 2000 characters.'),
], validate, requireAdminPermission('users.notes.manage'), controller.addNote);
router.put('/:userId/notes/:noteId', [
  userId(), noteId(),
  body('text').isString().trim().isLength({ min: 1, max: 2000 }).withMessage('Note text must be between 1 and 2000 characters.'),
], validate, requireAdminPermission('users.notes.manage'), controller.editNote);
router.delete('/:userId/notes/:noteId', [userId(), noteId()], validate, requireAdminPermission('users.notes.manage'), controller.deleteNote);
router.get('/:userId/timeline', [userId(), ...page()], validate, requireAdminPermission('users.timeline.view'), controller.timeline);
router.post('/:userId/suspend', [userId(), body('reason').optional().isString().trim().isLength({ max: 500 })], validate, requireAdminPermission('users.suspend'), controller.suspend);
router.post('/:userId/deactivate', [userId(), body('reason').optional().isString().trim().isLength({ max: 500 })], validate, requireAdminPermission('users.manage'), controller.deactivate);
router.post('/:userId/activate', [userId()], validate, requireAdminPermission('users.activate'), controller.activate);
router.post('/:userId/force-logout', [userId()], validate, requireAdminPermission('users.forceLogout'), controller.forceLogout);
router.delete('/:userId', [
  userId(),
  body('reason').isIn(deletionReasons).withMessage('A valid deletion reason is required.'),
  body('details').optional({ nullable: true }).isString().trim().isLength({ max: 240 }),
  body('details').if(body('reason').equals('other')).notEmpty().withMessage('Details are required when the reason is other.'),
], validate, requireRecentAdminMfa, requireAdminPermission('users.delete'), controller.remove);
router.post('/:userId/reset-password', [userId()], validate, requireRecentAdminMfa, requireAdminPermission('users.resetPassword'), controller.resetPassword);

module.exports = router;
