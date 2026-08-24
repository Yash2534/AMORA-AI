const { failure } = require('../admin/responses');

function requireAdminPermission(...required) {
  return (req, res, next) => {
    const granted = req.adminPermissions || new Set();
    if (required.some((permission) => granted.has(permission))) return next();
    return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to perform this action.');
  };
}

function requireAllAdminPermissions(...required) {
  return (req, res, next) => {
    const granted = req.adminPermissions || new Set();
    if (required.every((permission) => granted.has(permission))) return next();
    return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to perform this action.');
  };
}

module.exports = { requireAdminPermission, requireAllAdminPermissions };
