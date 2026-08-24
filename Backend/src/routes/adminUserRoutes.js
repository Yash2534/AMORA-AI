const router = require('express').Router();
const { body, param, query } = require('express-validator');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission } = require('../middleware/adminRbacMiddleware');
const controller = require('../controllers/adminUserController');

const userId = () => param('userId').isInt({ min: 1 }).withMessage('A valid user ID is required.').toInt();
const page = () => [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isInt({ min: 1, max: 100 }).toInt(),
];

router.get('/', [
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
router.post('/:userId/suspend', [userId(), body('reason').optional().isString().trim().isLength({ max: 500 })], validate, requireAdminPermission('users.suspend'), controller.suspend);
router.post('/:userId/deactivate', [userId(), body('reason').optional().isString().trim().isLength({ max: 500 })], validate, requireAdminPermission('users.manage'), controller.deactivate);
router.post('/:userId/activate', [userId()], validate, requireAdminPermission('users.activate'), controller.activate);
router.post('/:userId/force-logout', [userId()], validate, requireAdminPermission('users.forceLogout'), controller.forceLogout);
router.post('/:userId/reset-password', [userId()], validate, requireAdminPermission('users.resetPassword'), controller.resetPassword);

module.exports = router;
