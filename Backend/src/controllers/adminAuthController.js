const auth = require('../services/adminAuthService');
const { refreshTokenFrom, cookieValue, clearCookieValue } = require('../admin/httpCookies');
const { success, failure } = require('../admin/responses');

const publicResult = (result) => ({
  accessToken: result.accessToken,
  expiresIn: result.expiresIn,
  user: result.user,
  session: {
    id: String(result.session.row.id),
    expiresAt: result.session.expiresAt,
    persistent: result.session.persistent,
  },
});

exports.login = async (req, res, next) => {
  try {
    const result = await auth.login(req.body.email, req.body.password, req.body.rememberMe, req);
    res.setHeader('Set-Cookie', cookieValue(result.session.token, result.session));
    return success(req, res, 'Administrator login successful.', publicResult(result));
  } catch (error) {
    return next(error);
  }
};

exports.refresh = async (req, res, next) => {
  try {
    const refreshToken = refreshTokenFrom(req);
    if (!refreshToken) {
      return failure(req, res, 401, 'TOKEN_INVALID', 'No administrator session is available.');
    }
    const result = await auth.rotate(refreshToken, req);
    res.setHeader('Set-Cookie', cookieValue(result.session.token, result.session));
    return success(req, res, 'Administrator session refreshed.', publicResult(result));
  } catch (error) {
    res.setHeader('Set-Cookie', clearCookieValue());
    return next(error);
  }
};

exports.logout = async (req, res, next) => {
  try {
    await auth.logout(refreshTokenFrom(req), req);
    res.setHeader('Set-Cookie', clearCookieValue());
    return success(req, res, 'Administrator logged out.', {});
  } catch (error) {
    res.setHeader('Set-Cookie', clearCookieValue());
    return next(error);
  }
};

exports.me = async (req, res) => success(req, res, 'Administrator profile retrieved.', {
  user: auth.serializeAdministrator(req.admin),
});

exports.forgotPassword = async (req, res, next) => {
  try {
    await auth.requestPasswordReset(req.body.email, req);
    return success(req, res, 'If an active administrator account matches that email, a password reset link has been sent.', {});
  } catch (error) {
    return next(error);
  }
};

exports.validateResetToken = async (req, res, next) => {
  try {
    const status = await auth.passwordResetStatus(req.body.token);
    return success(req, res, 'Password reset token status retrieved.', { status, valid: status === 'valid' });
  } catch (error) {
    return next(error);
  }
};

exports.resetPassword = async (req, res, next) => {
  try {
    await auth.resetPassword(req.body.token, req.body.newPassword, req);
    res.setHeader('Set-Cookie', clearCookieValue());
    return success(req, res, 'Administrator password reset completed.', { sessionInvalidated: true, requiresLogin: true });
  } catch (error) {
    return next(error);
  }
};

exports.changePassword = async (req, res, next) => {
  try {
    const result = await auth.changePassword(req.admin.id, req.body.currentPassword, req.body.newPassword, req);
    res.setHeader('Set-Cookie', clearCookieValue());
    return success(req, res, 'Administrator password changed.', result);
  } catch (error) {
    return next(error);
  }
};

exports.sessions = async (req, res, next) => {
  try {
    const items = await auth.listSessions(req.admin.id, req.adminSession.selector);
    return success(req, res, 'Administrator sessions retrieved.', { items });
  } catch (error) {
    return next(error);
  }
};

exports.revokeSession = async (req, res, next) => {
  try {
    const session = await auth.revokeSession(req.admin.id, req.params.sessionId, req.adminSession.selector, req);
    if (session.current) res.setHeader('Set-Cookie', clearCookieValue());
    return success(req, res, 'Administrator session revoked.', { session });
  } catch (error) {
    return next(error);
  }
};
