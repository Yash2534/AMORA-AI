const bcrypt = require('bcrypt'); const jwt = require('jsonwebtoken'); const { Op } = require('sequelize'); const { OAuth2Client } = require('google-auth-library');
const { getModels } = require('../models'); const { issueTokens, accessToken } = require('../utils/generateTokens');
const { createPhoneOtp, createEmailOtp, deliverPhoneOtp, deliverEmailOtp, verifyPhoneOtp, verifyEmailOtp } = require('../services/otpService');
const googleIds = (process.env.GOOGLE_CLIENT_IDS || '').split(',').map((id) => id.trim()).filter((id) => id && id !== 'skip-for-now');
const googleClient = googleIds.length ? new OAuth2Client() : null;
const OTP_RESEND_COOLDOWN_MS = 45 * 1000;
const profile = (user) => ({ id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, isVerified: user.isVerified, accountStatus: user.accountStatus });
const emailOf = (value) => String(value || '').trim().toLowerCase();
const phoneOf = (value) => { const digits = String(value || '').replace(/\D/g, ''); const national = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits; return /^\d{10}$/.test(national) ? `+91${national}` : ''; };
const refreshSelectorOf = (value) => {
  const selector = String(value || '').split('.', 1)[0];
  return /^[a-f0-9]{32}$/.test(selector) && String(value).includes('.') ? selector : null;
};
function success(res, message, data, devOtp) { const body = { success: true, message, data }; if (process.env.NODE_ENV === 'development' && devOtp) body.devOtp = devOtp; return res.json(body); }
exports.signup = async (req, res, next) => {
  const { User } = getModels();
  const email = emailOf(req.body.email);
  const phoneNumber = phoneOf(req.body.phoneNumber);
  let user;
  let code;
  try {
    await User.sequelize.transaction(async (transaction) => {
      const existing = await User.findOne({
        where: { [Op.or]: [{ email }, { phoneNumber }] },
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (existing) {
        const phoneConflict = existing.phoneNumber === phoneNumber;
        const error = new Error(
          phoneConflict
            ? 'An account with this phone number already exists.'
            : 'An account with this email already exists.',
        );
        error.status = 409;
        error.code = phoneConflict ? 'PHONE_EXISTS' : 'EMAIL_EXISTS';
        throw error;
      }
      user = await User.create({
        name: req.body.name.trim(),
        email,
        phoneNumber,
        passwordHash: await bcrypt.hash(req.body.password, 12),
        termsAcceptedAt: new Date(),
      }, { transaction });
      ({ code } = await createPhoneOtp(phoneNumber, 'account_verification', { transaction }));
    });
  } catch (error) {
    if (!error.status && /SMS|Twilio/i.test(error.message || '')) {
      error.status = 503;
      error.code = 'OTP_DELIVERY_FAILED';
    }
    return next(error);
  }
  return success(res, 'Account created. Verification code sent.', {
    userId: user.id,
    email,
    phoneNumber,
  }, code);
};
exports.verifyAccount = async (req, res) => {
  const { User } = getModels();
  const phoneNumber = phoneOf(req.body.phoneNumber);
  const user = await User.findOne({
    where: { phoneNumber, authProvider: 'local', isVerified: false },
    order: [['createdAt', 'DESC']],
  });
  if (!user) return res.status(400).json({ success: false, message: 'Account not found.', code: 'OTP_INVALID', errors: [] });
  const checked = await verifyPhoneOtp(phoneNumber, req.body.code, 'account_verification');
  if (checked.error) return res.status(400).json({ success: false, message: checked.error[1], code: checked.error[0], errors: checked.error[2] !== undefined ? [{ remainingAttempts: checked.error[2] }] : [] });
  user.isVerified = true;
  await user.save();
  const tokens = await issueTokens(user, req.ip);
  return success(res, 'Account verified.', { ...tokens, user: profile(user) });
};
exports.resendVerification = async (req, res) => {
  const phoneNumber = phoneOf(req.body.phoneNumber);
  const { User, OtpToken } = getModels();
  let pendingOtp = null;
  await User.sequelize.transaction(async (transaction) => {
    const user = await User.findOne({
      where: { phoneNumber, authProvider: 'local', isVerified: false },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!user) return;
    const recentOtp = await OtpToken.findOne({
      where: {
        phoneNumber,
        purpose: 'account_verification',
        createdAt: { [Op.gte]: new Date(Date.now() - OTP_RESEND_COOLDOWN_MS) },
      },
      order: [['createdAt', 'DESC']],
      transaction,
    });
    if (recentOtp) return;
    pendingOtp = await createPhoneOtp(phoneNumber, 'account_verification', { transaction, deliver: false });
  });

  let deliveredCode;
  if (pendingOtp) {
    try {
      await deliverPhoneOtp(phoneNumber, 'account_verification', pendingOtp.code, pendingOtp.expiresAt);
      deliveredCode = pendingOtp.code;
    } catch (error) {
      await OtpToken.update({ consumed: true }, { where: { id: pendingOtp.otp.id } }).catch(() => {});
      console.error('[OTP] Verification resend delivery failed.');
    }
  }
  return success(
    res,
    'If an eligible account exists, a verification code has been sent.',
    { phoneNumber },
    deliveredCode,
  );
};
exports.login = async (req, res) => { const { User } = getModels(); const user = await User.findOne({ where: { email: emailOf(req.body.email) } }); if (!user || user.authProvider !== 'local' || !(await bcrypt.compare(req.body.password, user.passwordHash || '')) || user.accountStatus === 'deleted') { const provider = user && user.authProvider === 'google'; return res.status(401).json({ success: false, message: provider ? 'This account uses Google Sign-In. Please sign in with Google.' : 'Invalid email or password.', code: 'INVALID_CREDENTIALS', errors: [] }); } if (!user.isVerified) return res.status(403).json({ success: false, message: 'Please verify your account before logging in.', code: 'ACCOUNT_NOT_VERIFIED', errors: [] }); const reactivated = user.accountStatus === 'deactivated'; if (reactivated) { user.accountStatus = 'active'; user.deactivatedAt = null; await user.save(); } return success(res, reactivated ? 'Account reactivated and logged in.' : 'Logged in.', { ...(await issueTokens(user, req.ip)), user: profile(user), reactivated }); };
exports.google = async (req, res) => { if (!googleClient) return res.status(503).json({ success: false, message: 'Google Sign-In is not configured on this server yet.', code: 'GOOGLE_AUTH_NOT_CONFIGURED', errors: [] }); let payload; try { payload = (await googleClient.verifyIdToken({ idToken: req.body.idToken, audience: googleIds })).getPayload(); } catch (_) { return res.status(401).json({ success: false, message: 'Invalid Google ID token.', code: 'TOKEN_INVALID', errors: [] }); } if (!payload.email || !payload.sub) return res.status(401).json({ success: false, message: 'Google token is missing required profile information.', code: 'TOKEN_INVALID', errors: [] }); const { User } = getModels(); const email = emailOf(payload.email); let user = await User.findOne({ where: { email } }); let isNewUser = false; if (user?.accountStatus === 'deleted') return res.status(401).json({ success: false, message: 'This account is unavailable.', code: 'INVALID_CREDENTIALS', errors: [] }); if (user && user.authProvider === 'local') return res.status(409).json({ success: false, message: 'An account with this email uses password login. Please log in with your password first.', code: 'INVALID_CREDENTIALS', errors: [] }); if (!user) { user = await User.create({ name: payload.name || email.split('@')[0], email, googleId: payload.sub, phoneNumber: '', authProvider: 'google', isVerified: true }); isNewUser = true; } const reactivated = user.accountStatus === 'deactivated'; if (reactivated) { user.accountStatus = 'active'; user.deactivatedAt = null; await user.save(); } return success(res, reactivated ? 'Account reactivated and signed in.' : 'Google Sign-In successful.', { ...(await issueTokens(user, req.ip)), user: profile(user), isNewUser, reactivated }); };
exports.forgotPassword = async (req, res) => {
  const email = emailOf(req.body.email);
  const { User, OtpToken } = getModels();
  let pendingOtp = null;
  await User.sequelize.transaction(async (transaction) => {
    const user = await User.findOne({
      where: { email, authProvider: 'local', accountStatus: { [Op.ne]: 'deleted' } },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!user) return;
    const recentOtp = await OtpToken.findOne({
      where: {
        email,
        purpose: 'password_reset',
        createdAt: { [Op.gte]: new Date(Date.now() - OTP_RESEND_COOLDOWN_MS) },
      },
      order: [['createdAt', 'DESC']],
      transaction,
    });
    if (recentOtp) return;
    pendingOtp = await createEmailOtp(email, 'password_reset', { transaction, deliver: false });
  });
  let deliveredCode;
  if (pendingOtp) {
    try {
      await deliverEmailOtp(email, 'password_reset', pendingOtp.code, pendingOtp.expiresAt);
      deliveredCode = pendingOtp.code;
    } catch (_) {
      await OtpToken.update({ consumed: true }, { where: { id: pendingOtp.otp.id } }).catch(() => {});
      console.error('[OTP] Password reset email delivery failed.');
    }
  }
  return success(res, 'If an eligible account exists, a password reset code has been sent.', {}, deliveredCode);
};
exports.verifyResetCode = async (req, res) => {
  const email = emailOf(req.body.email);
  const checked = await verifyEmailOtp(email, req.body.code, 'password_reset');
  if (checked.error) return res.status(400).json({ success: false, message: checked.error[1], code: checked.error[0], errors: checked.error[2] !== undefined ? [{ remainingAttempts: checked.error[2] }] : [] });
  const recoveryToken = jwt.sign({ email, otpId: checked.otp.id, purpose: 'password_reset' }, process.env.JWT_SECRET, { expiresIn: '10m' });
  return success(res, 'Reset code verified.', { recoveryToken });
};
exports.resetPassword = async (req, res) => {
  let payload;
  try { payload = jwt.verify(req.body.recoveryToken, process.env.JWT_SECRET); } catch (e) { return res.status(401).json({ success: false, message: 'Invalid or expired recovery token.', code: e.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID', errors: [] }); }
  const email = emailOf(req.body.email);
  if (payload.email !== email || !Number.isInteger(payload.otpId) || payload.purpose !== 'password_reset') return res.status(401).json({ success: false, message: 'Recovery token does not match this request.', code: 'TOKEN_INVALID', errors: [] });
  const { User, RefreshToken, OtpToken } = getModels();
  const result = await User.sequelize.transaction(async (transaction) => {
    const otp = await OtpToken.findOne({ where: { id: payload.otpId, email, purpose: 'password_reset', consumed: true }, transaction, lock: transaction.LOCK.UPDATE });
    if (!otp || otp.recoveryUsedAt) return false;
    const user = await User.findOne({ where: { email, authProvider: 'local', accountStatus: { [Op.ne]: 'deleted' } }, transaction, lock: transaction.LOCK.UPDATE });
    if (!user) return false;
    user.passwordHash = await bcrypt.hash(req.body.newPassword, 12);
    await user.save({ transaction });
    otp.recoveryUsedAt = new Date();
    await otp.save({ transaction });
    await RefreshToken.destroy({ where: { userId: user.id }, transaction });
    return true;
  });
  if (!result) return res.status(401).json({ success: false, message: 'Invalid or already used recovery token.', code: 'TOKEN_INVALID', errors: [] });
  return success(res, 'Password updated. Please log in again.', {});
};
exports.refreshToken = async (req, res) => {
  const { RefreshToken, User } = getModels();
  const token = req.body.refreshToken;
  const selector = refreshSelectorOf(token);
  const candidates = await RefreshToken.findAll({
    where: {
      expiresAt: { [Op.gt]: new Date() },
      ...(selector ? { tokenSelector: selector } : { tokenSelector: null }),
    },
  });
  let candidateId;
  for (const item of candidates) {
    if (await bcrypt.compare(token, item.tokenHash)) {
      candidateId = item.id;
      break;
    }
  }
  if (!candidateId) {
    return res.status(401).json({ success: false, message: 'Invalid or expired refresh token.', code: 'TOKEN_INVALID', errors: [] });
  }
  const tokens = await User.sequelize.transaction(async (transaction) => {
    const match = await RefreshToken.findByPk(candidateId, {
      include: [User],
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!match || !match.User || match.expiresAt <= new Date() || match.User.accountStatus !== 'active') return null;
    const user = match.User;
    await match.destroy({ transaction });
    return issueTokens(user, req.ip, { transaction });
  });
  if (!tokens) {
    return res.status(401).json({ success: false, message: 'Invalid or expired refresh token.', code: 'TOKEN_INVALID', errors: [] });
  }
  return success(res, 'Token refreshed.', tokens);
};
exports.logout = async (req, res) => { const { RefreshToken } = getModels(); const selector = refreshSelectorOf(req.body.refreshToken); const candidates = await RefreshToken.findAll({ where: { userId: req.user.sub, ...(selector ? { tokenSelector: selector } : { tokenSelector: null }) } }); for (const item of candidates) if (await bcrypt.compare(req.body.refreshToken, item.tokenHash)) { await item.destroy(); break; } return success(res, 'Logged out', {}); };
exports.me = async (req, res) => { const { User } = getModels(); const user = await User.findByPk(req.user.sub); if (!user) return res.status(404).json({ success: false, message: 'User not found.', code: 'TOKEN_INVALID', errors: [] }); return success(res, 'Profile retrieved.', { user: profile(user) }); };
exports.logGoogleStatus = () => console.log(googleClient ? '[Google Auth] Active' : '[Google Auth] Disabled — set GOOGLE_CLIENT_IDS in .env to enable');
