const jwt = require('jsonwebtoken');
const { getModels } = require('../models');

function authenticationMiddleware({ allowDeactivated = false } = {}) {
  return async (req, res, next) => {
    const value = req.headers.authorization || '';
    const token = value.startsWith('Bearer ') ? value.slice(7) : null;
    if (!token) return res.status(401).json({ success: false, message: 'Access token is required.', code: 'TOKEN_INVALID', errors: [] });
    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      return res.status(401).json({ success: false, message: error.name === 'TokenExpiredError' ? 'Access token has expired.' : 'Invalid access token.', code: error.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID', errors: [] });
    }
    try {
      const { User } = getModels();
      const user = await User.findByPk(payload.sub);
      if (!user || user.accountStatus === 'deleted' || Number(payload.ver || 0) !== Number(user.tokenVersion || 0)) {
        return res.status(401).json({ success: false, message: 'This session is no longer valid.', code: 'TOKEN_INVALID', errors: [] });
      }
      if (user.accountStatus === 'deactivated' && !allowDeactivated) {
        return res.status(403).json({ success: false, message: 'Reactivate your account before continuing.', code: 'ACCOUNT_DEACTIVATED', errors: [] });
      }
      req.user = payload;
      req.authUser = user;
      return next();
    } catch (error) {
      return next(error);
    }
  };
}

const requireAuth = authenticationMiddleware();
requireAuth.allowDeactivated = authenticationMiddleware({ allowDeactivated: true });
module.exports = requireAuth;
