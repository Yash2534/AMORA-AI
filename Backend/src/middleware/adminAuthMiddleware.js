const { authenticateAccessToken } = require('../services/adminAuthService');
const { failure } = require('../admin/responses');

module.exports = async function adminAuthMiddleware(req, res, next) {
  const authorization = String(req.headers.authorization || '');
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : '';
  if (!token) {
    return failure(req, res, 401, 'TOKEN_INVALID', 'Administrator access token is required.');
  }
  try {
    const access = await authenticateAccessToken(token);
    req.adminToken = access.payload;
    req.admin = access.administrator;
    req.adminSession = access.session;
    req.adminPermissions = access.permissions;
    const now = new Date();
    if (!access.administrator.lastActiveAt
        || now.getTime() - new Date(access.administrator.lastActiveAt).getTime() >= 30000) {
      await access.administrator.update({ lastActiveAt: now });
    }
    return next();
  } catch (error) {
    if (error.status && error.code) {
      return failure(req, res, error.status, error.code, error.message);
    }
    return next(error);
  }
};
