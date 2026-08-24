const router = require('express').Router();
const { body, param, query } = require('express-validator');
const controller = require('../controllers/adminManagementController');
const validate = require('../middleware/validateRequest');
const { requireAdminPermission, requireAllAdminPermissions } = require('../middleware/adminRbacMiddleware');

const adminId = param('adminId').isInt({ min: 1 }).toInt();
const roleId = param('roleId').isInt({ min: 1 }).toInt();
const roleIds = [
  body('roleIds').isArray({ min: 1, max: 10 }),
  body('roleIds.*').isInt({ min: 1 }).toInt(),
];
const administratorListQuery = [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isIn(['10', '20', '50', '100']).toInt(),
  query('search').optional().trim().isLength({ min: 1, max: 160 }),
  query('status').optional().isIn(['active', 'suspended', 'disabled']),
  query('roleId').optional().isInt({ min: 1 }).toInt(),
  query('invitationStatus').optional().isIn(['not_required', 'pending', 'accepted', 'expired', 'revoked']),
  query('mfaStatus').optional().equals('not_available'),
  query('sortBy').optional().isIn(['createdAt', 'lastLoginAt', 'name', 'status']),
  query('sortDirection').optional().isIn(['asc', 'desc']),
];
const roleListQuery = [
  query('page').optional().isInt({ min: 1, max: 100000 }).toInt(),
  query('pageSize').optional().isIn(['10', '20', '50']).toInt(),
  query('search').optional().trim().isLength({ min: 1, max: 160 }),
  query('type').optional().isIn(['system', 'custom']),
  query('status').optional().isIn(['active', 'inactive']),
  query('sortBy').optional().isIn(['updatedAt', 'name', 'administratorCount', 'permissionCount']),
  query('sortDirection').optional().isIn(['asc', 'desc']),
];
const permissionQuery = [
  query('search').optional().trim().isLength({ min: 1, max: 160 }),
  query('module').optional().matches(/^[A-Za-z][A-Za-z0-9_-]{0,79}$/),
  query('group').optional().matches(/^[A-Za-z][A-Za-z0-9_-]{0,79}$/),
  query('risk').optional().isIn(['low', 'medium', 'high', 'critical']),
  query('delegable').optional().isBoolean().toBoolean(),
];

router.get('/administrator-management/configuration',
  requireAdminPermission('administrators.view', 'roles.view', 'permissions.matrix.view', 'permissions.catalog.view'),
  controller.configuration);
router.get('/administrators', administratorListQuery, validate,
  requireAdminPermission('administrators.view'), controller.administrators);
router.post('/administrators', [
  body('name').trim().isLength({ min: 2, max: 120 }),
  body('email').trim().isEmail().normalizeEmail(),
  ...roleIds,
  body('locale').isIn(['en-IN']),
  body('timezone').isIn(['Asia/Kolkata']),
  body('sendInvitationNow').isBoolean().toBoolean(),
  body('invitationMessage').optional().trim().isLength({ min: 1, max: 500 }),
], validate, requireAdminPermission('administrators.create'), controller.createAdministrator);
router.get('/administrators/:adminId', [adminId], validate,
  requireAdminPermission('administrators.details.view'), controller.administrator);
router.get('/administrators/:adminId/audit-history', [adminId], validate,
  requireAdminPermission('administrators.audit.view'), controller.audit);
router.get('/administrators/:adminId/assignable-roles', [adminId], validate,
  requireAllAdminPermissions('administrators.assignRoles', 'roles.assign'), controller.assignableRoles);
router.post('/administrators/:adminId/role-change-preview', [adminId, ...roleIds], validate,
  requireAllAdminPermissions('administrators.assignRoles', 'roles.assign'), controller.previewRoles);
router.patch('/administrators/:adminId/assign-roles', [adminId, ...roleIds], validate,
  requireAllAdminPermissions('administrators.assignRoles', 'roles.assign'), controller.assignRoles);
router.post('/administrators/:adminId/suspend', [
  adminId,
  body('reasonCode').isIn(['security_incident', 'policy_violation', 'access_review', 'employment_change']),
  body('reasonDetail').optional().trim().isLength({ min: 1, max: 500 }),
  body('durationCode').optional().isIn(['indefinite']),
  body('revokeSessions').isBoolean().toBoolean(),
], validate, requireAdminPermission('administrators.suspend'), controller.suspend);
router.post('/administrators/:adminId/reactivate', [adminId], validate,
  requireAdminPermission('administrators.reactivate'), controller.reactivate);
router.post('/administrators/:adminId/revoke-sessions', [adminId], validate,
  requireAdminPermission('administrators.sessions.revoke'), controller.revokeSessions);

router.get('/roles', roleListQuery, validate, requireAdminPermission('roles.view'), controller.roles);
router.post('/roles', [
  body('key').matches(/^[a-z][a-z0-9_]{2,79}$/),
  body('name').trim().isLength({ min: 2, max: 120 }),
  body('description').optional().trim().isLength({ min: 1, max: 500 }),
  body('permissionIds').isArray({ min: 1, max: 263 }),
  body('permissionIds.*').isInt({ min: 1 }).toInt(),
], validate, requireAllAdminPermissions('roles.manage', 'permissions.matrix.manage'), controller.createRole);
router.get('/roles/:roleId', [roleId], validate, requireAdminPermission('roles.details.view'), controller.role);
router.post('/roles/:roleId/permissions/preview', [
  roleId,
  body('updates').isArray({ min: 1, max: 263 }),
  body('updates.*.roleId').isInt({ min: 1 }).toInt(),
  body('updates.*.permissionId').isInt({ min: 1 }).toInt(),
  body('updates.*.assigned').isBoolean().toBoolean(),
], validate, requireAdminPermission('permissions.matrix.manage'), controller.previewPermissions);
router.patch('/roles/:roleId/permissions', [
  roleId,
  body('updates').isArray({ min: 1, max: 263 }),
  body('updates.*.roleId').isInt({ min: 1 }).toInt(),
  body('updates.*.permissionId').isInt({ min: 1 }).toInt(),
  body('updates.*.assigned').isBoolean().toBoolean(),
], validate, requireAdminPermission('permissions.matrix.manage'), controller.savePermissions);

router.get('/permissions', permissionQuery, validate,
  requireAdminPermission('permissions.view', 'permissions.catalog.view'), controller.permissions);
router.get('/permission-matrix', requireAdminPermission('permissions.matrix.view'), controller.matrix);

module.exports = router;
