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

function attachRecordScopeFilter(moduleName) {
  return (req, res, next) => {
    const role = req.adminRole?.code || 'super_admin';
    const isSuper = role === 'super_admin';

    req.recordScope = {
      role,
      isSuper,
      assignedOnly: role === 'support_agent',
      verificationOnly: role === 'verification_officer',
      financeOnly: role === 'finance_admin',
      filterFor(userIdKey = 'assignedAdminId') {
        if (isSuper) return {};
        if (this.assignedOnly) return { [userIdKey]: req.admin.id };
        return {};
      },
    };
    next();
  };
}

module.exports = { requireAdminPermission, requireAllAdminPermissions, attachRecordScopeFilter };
