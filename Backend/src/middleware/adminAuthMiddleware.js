const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { administratorWithAccess, permissionsFor } = require('../services/adminAuthService');
const { getModels } = require('../models');
const { failure } = require('../admin/responses');

module.exports = async function adminAuthMiddleware(req, res, next) {
  const authorization = String(req.headers.authorization || '');
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : '';
  if (!token) {
    return failure(req, res, 401, 'TOKEN_INVALID', 'Administrator access token is required.');
  }
  let payload;
  try {
    payload = jwt.verify(token, process.env.ADMIN_JWT_SECRET, {
      issuer: 'amoraa-backend',
      audience: 'amoraa-admin-web',
    });
  } catch (error) {
    return failure(req, res, 401,
      error.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID',
      error.name === 'TokenExpiredError'
        ? 'Your administrator session has expired. Please sign in again.'
        : 'Invalid administrator access token.',
    );
  }
  if (payload.typ !== 'admin_access') {
    return failure(req, res, 401, 'TOKEN_INVALID', 'Invalid administrator access token.');
  }
  try {
    const { AdminRefreshToken } = getModels();
    const [administrator, session] = await Promise.all([
      administratorWithAccess(payload.sub),
      payload.sid ? AdminRefreshToken.findOne({
        where: {
          administratorId: payload.sub,
          selector: payload.sid,
          revokedAt: null,
          expiresAt: { [Op.gt]: new Date() },
        },
      }) : null,
    ]);
    if (!administrator || !session || Number(payload.ver || 0) !== Number(administrator.tokenVersion || 0)) {
      return failure(req, res, 401, 'TOKEN_REVOKED', 'This administrator session is no longer valid.');
    }
    if (administrator.status !== 'active') {
      return failure(req, res, 403,
        administrator.status === 'disabled' ? 'ACCOUNT_DISABLED' : 'ACCESS_DENIED',
        administrator.status === 'disabled'
          ? 'This administrator account has been disabled.'
          : 'This administrator account is suspended.',
      );
    }
    if (!administrator.roles?.length) {
      return failure(req, res, 403, 'ACCESS_DENIED', 'No active administrator role is assigned.');
    }
    req.adminToken = payload;
    req.admin = administrator;
    req.adminSession = session;
    req.adminPermissions = new Set(permissionsFor(administrator));
    const now = new Date();
    if (!administrator.lastActiveAt || now.getTime() - new Date(administrator.lastActiveAt).getTime() >= 30000) {
      await administrator.update({ lastActiveAt: now });
    }
    return next();
  } catch (error) {
    return next(error);
  }
};
