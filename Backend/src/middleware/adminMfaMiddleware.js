const { failure } = require('../admin/responses');
const { hasRecentStepUp, isEnabled } = require('../services/adminMfaService');

module.exports = async function requireRecentAdminMfa(request, response, next) {
  try {
    if (!(await isEnabled(request.admin.id))) {
      return failure(request, response, 428, 'MFA_ENROLLMENT_REQUIRED',
        'Enable multi-factor authentication before performing this sensitive action.');
    }
    if (!hasRecentStepUp(request.adminSession)) {
      return failure(request, response, 428, 'MFA_STEP_UP_REQUIRED',
        'Recent multi-factor authentication is required for this sensitive action.');
    }
    return next();
  } catch (error) {
    return next(error);
  }
};
