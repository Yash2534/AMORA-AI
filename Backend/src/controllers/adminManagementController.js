const management = require('../services/adminManagementService');
const { success } = require('../admin/responses');

const handle = (fn, message, status = 200) => async (req, res, next) => {
  try {
    const data = await fn(req);
    return success(req, res, message, data, status);
  } catch (error) {
    return next(error);
  }
};

exports.configuration = handle(() => management.configuration(), 'Administrator configuration retrieved.');
exports.administrators = handle((req) => management.listAdministrators(req), 'Administrators retrieved.');
exports.administrator = handle((req) => management.getAdministrator(req, req.params.adminId), 'Administrator retrieved.');
exports.audit = handle((req) => management.administratorAudit(req, req.params.adminId), 'Administrator audit history retrieved.');
exports.assignableRoles = handle((req) => management.assignableRoles(req, req.params.adminId), 'Assignable roles retrieved.');
exports.roles = handle((req) => management.roles(req), 'Administrator roles retrieved.');
exports.role = handle((req) => management.role(req, req.params.roleId), 'Administrator role retrieved.');
exports.permissions = handle((req) => management.permissions(req), 'Administrator permissions retrieved.');
exports.matrix = handle((req) => management.permissionMatrix(req), 'Permission matrix retrieved.');
exports.createAdministrator = handle((req) => management.createAdministrator(req), 'Administrator creation committed.', 201);
exports.previewRoles = handle((req) => management.roleAssignmentPreview(req, req.params.adminId), 'Role change preview retrieved.');
exports.assignRoles = handle((req) => management.assignRoles(req, req.params.adminId), 'Administrator roles updated.');
exports.suspend = handle((req) => management.suspend(req, req.params.adminId), 'Administrator suspended.');
exports.reactivate = handle((req) => management.reactivate(req, req.params.adminId), 'Administrator reactivated.');
exports.revokeSessions = handle((req) => management.revokeSessions(req, req.params.adminId), 'Administrator sessions revoked.');
exports.previewPermissions = handle((req) => management.permissionPreview(req, req.params.roleId), 'Permission change preview retrieved.');
exports.savePermissions = handle((req) => management.savePermissions(req, req.params.roleId), 'Role permissions updated.');
exports.createRole = handle((req) => management.createRole(req), 'Administrator role created.', 201);

exports.invitationStatus = handle((req) => management.invitationStatus(req.body.token), 'Administrator invitation status retrieved.');
exports.acceptInvitation = handle((req) => management.acceptInvitation(req.body.token, req.body.newPassword, req), 'Administrator invitation accepted.');
