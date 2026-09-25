const bcrypt = require('bcrypt'); const crypto = require('crypto'); const jwt = require('jsonwebtoken'); const { Op } = require('sequelize'); const { OAuth2Client } = require('google-auth-library');
const { getModels } = require('../models'); const { issueTokens, accessToken } = require('../utils/generateTokens');
const { createPhoneOtp, createEmailOtp, deliverPhoneOtp, deliverEmailOtp, verifyPhoneOtp, verifyEmailOtp } = require('../services/otpService');
const { recordLoginEvent } = require('../services/userActivityService');
const { runtimeConfiguration } = require('../services/platformSettingsService');
const consentService = require('../services/consentService');
const googleIds = (process.env.GOOGLE_CLIENT_IDS || '').split(',').map((id) => id.trim()).filter((id) => id && id !== 'skip-for-now');
const googleClient = googleIds.length ? new OAuth2Client() : null;
const OTP_RESEND_COOLDOWN_MS = 45 * 1000;
const otpCorrelationId = (req) => {
  const supplied = String(req.headers['x-request-id'] || '');
  return /^[A-Za-z0-9_-]{8,128}$/.test(supplied) ? supplied : crypto.randomUUID();
};
const profile = (user) => ({ id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, isVerified: user.isVerified, accountStatus: user.accountStatus, authProvider: user.authProvider });
const emailOf = (value) => String(value || '').trim().toLowerCase();
const phoneOf = (value) => { const digits = String(value || '').replace(/\D/g, ''); const national = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits; return /^\d{10}$/.test(national) ? `+91${national}` : ''; };
const refreshSelectorOf = (value) => {
  const selector = String(value || '').split('.', 1)[0];
  return /^[a-f0-9]{32}$/.test(selector) && String(value).includes('.') ? selector : null;
};
const REACTIVATION_ISSUER = 'amoraa-backend';
const REACTIVATION_AUDIENCE = 'amoraa-account-reactivation';
const reactivationChallenge = (user) => jwt.sign({
  sub: String(user.id),
  ver: Number(user.tokenVersion || 0),
  purpose: 'account_reactivation',
  jti: crypto.randomUUID(),
}, process.env.JWT_SECRET, {
  expiresIn: '10m',
  issuer: REACTIVATION_ISSUER,
  audience: REACTIVATION_AUDIENCE,
});
const deactivatedResponse = (res, user) => res.status(403).json({
  success: false,
  message: 'This account is deactivated. Confirm reactivation to continue.',
  code: 'ACCOUNT_DEACTIVATED',
  errors: [],
  data: { reactivationToken: reactivationChallenge(user), expiresInSeconds: 600 },
});
function success(res, message, data, devOtp) { const body = { success: true, message, data }; if (process.env.NODE_ENV === 'development' && devOtp) body.devOtp = devOtp; return res.json(body); }
exports.requiredSignupLegalDocuments = async (_req, res, next) => {
  try {
    const documents = await consentService.requiredSignupDocuments();
    return success(res, 'Required legal documents.', { documents });
  } catch (error) { return next(error); }
};
exports.signup = async (req, res, next) => {
  const configuration = await runtimeConfiguration();
  if (!configuration.registration_enabled) return res.status(403).json({ success: false, message: 'New registrations are currently unavailable.', code: 'REGISTRATION_DISABLED', errors: [] });
  const { User } = getModels();
  const email = emailOf(req.body.email);
  const phoneNumber = phoneOf(req.body.phoneNumber);
  let user;
  let pendingOtp;
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
      }, { transaction });
      await consentService.recordRequiredSignupConsent({
        userId: user.id,
        acceptedLegalDocuments: req.body.acceptedLegalDocuments,
        source: 'SIGNUP_EMAIL',
        platform: req.body.platform,
        // Version identity, document IDs, source, platform, and the server
        // timestamp are persisted by ConsentEvent itself.  Only pass optional
        // client metadata when it is actually supplied and schema-valid.
        metadata: req.body.consentMetadata,
        transaction,
      });
      // The database work must commit before calling an external provider.  The
      // OTP is deliberately created without delivery here; delivery below is
      // the acknowledgement gate for the successful signup response.
      pendingOtp = await createPhoneOtp(phoneNumber, 'account_verification', {
        transaction,
        deliver: false,
      });
    });
  } catch (error) {
    return next(error);
  }

  try {
    await deliverPhoneOtp(
      phoneNumber,
      'account_verification',
      pendingOtp.code,
      pendingOtp.expiresAt,
      { correlationId: otpCorrelationId(req) },
    );
  } catch (error) {
    // Do not leave an account that the user cannot verify after a provider
    // rejection.  This is compensating cleanup after the committed provider
    // boundary; it never turns a failed delivery into a successful response.
    await User.sequelize.transaction(async (transaction) => {
      const { ConsentEvent, OtpToken } = getModels();
      await OtpToken.destroy({ where: { id: pendingOtp.otp.id }, transaction });
      await ConsentEvent.destroy({ where: { userId: user.id }, transaction });
      await User.destroy({ where: { id: user.id }, transaction });
    }).catch(() => {});
    
    console.error(`[OTP] Registration SMS delivery failed for ${phoneNumber}:`, error.message, error.code, error.status);

    if (error.code === 'OTP_CONFIG_ERROR') {
      return res.status(502).json({
        success: false,
        message: "SMS Provider is not configured on the server.",
        code: 'OTP_PROVIDER_AUTH_ERROR',
        errors: [],
      });
    }
    if (error.status === 429) {
      return res.status(429).json({
        success: false,
        message: "Too many attempts. Please try again later.",
        code: 'RATE_LIMITED',
        errors: [],
      });
    }
    if (error.status === 400 && error.code === 21211) {
      return res.status(400).json({
        success: false,
        message: "Invalid phone number.",
        code: 'INVALID_PHONE_NUMBER',
        errors: [],
      });
    }

    return res.status(503).json({
      success: false,
      message: error.message || "We couldn't send the verification code. Please try again.",
      code: 'OTP_DELIVERY_FAILED',
      errors: [],
    });
  }

  return success(res, 'Account created. Verification code sent.', {
    userId: user.id,
    email,
    phoneNumber,
  }, pendingOtp.code);
};
exports.verifyAccount = async (req, res) => {
  const { User } = getModels();
  const phoneNumber = phoneOf(req.body.phoneNumber);
  const user = await User.findOne({
    where: { phoneNumber, authProvider: 'local', isVerified: false },
    order: [['createdAt', 'DESC']],
  });
  if (!user) return res.status(400).json({ success: false, message: 'Account not found.', code: 'OTP_INVALID', errors: [] });
  const checked = await verifyPhoneOtp(phoneNumber, req.body.code, 'account_verification', { correlationId: otpCorrelationId(req) });
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
      await deliverPhoneOtp(phoneNumber, 'account_verification', pendingOtp.code, pendingOtp.expiresAt, { correlationId: otpCorrelationId(req) });
      deliveredCode = pendingOtp.code;
    } catch (error) {
      await OtpToken.update({ consumed: true }, { where: { id: pendingOtp.otp.id } }).catch(() => {});
      console.error(`[OTP] Verification resend delivery failed for ${phoneNumber}:`, error.message, error.code, error.status);

      if (error.code === 'OTP_CONFIG_ERROR') {
        return res.status(502).json({
          success: false,
          message: "SMS Provider is not configured on the server.",
          code: 'OTP_PROVIDER_AUTH_ERROR',
          errors: [],
        });
      }
      if (error.status === 429) {
        return res.status(429).json({
          success: false,
          message: "Too many attempts. Please try again later.",
          code: 'RATE_LIMITED',
          errors: [],
        });
      }
      if (error.status === 400 && error.code === 21211) {
        return res.status(400).json({
          success: false,
          message: "Invalid phone number.",
          code: 'INVALID_PHONE_NUMBER',
          errors: [],
        });
      }

      return res.status(503).json({
        success: false,
        message: error.message || "We couldn't send the verification code. Please try again.",
        code: 'OTP_DELIVERY_FAILED',
        errors: [],
      });
    }
  }
  return success(
    res,
    'If an eligible account exists, a verification code has been sent.',
    { phoneNumber },
    deliveredCode,
  );
};
exports.login = async (req, res) => { const { User } = getModels(); const user = await User.findOne({ where: { email: emailOf(req.body.email) } }); if (!user || user.authProvider !== 'local' || !(await bcrypt.compare(req.body.password, user.passwordHash || '')) || user.accountStatus === 'deleted') { if (user && user.accountStatus !== 'deleted') await recordLoginEvent({ userId: user.id, result: 'failed', authenticationMethod: 'password', failureCategory: 'invalid_credentials', request: req }); const provider = user && user.authProvider === 'google'; return res.status(401).json({ success: false, message: provider ? 'This account uses Google Sign-In. Please sign in with Google.' : 'Invalid email or password.', code: 'INVALID_CREDENTIALS', errors: [] }); } if (!user.isVerified) { await recordLoginEvent({ userId: user.id, result: 'failed', authenticationMethod: 'password', failureCategory: 'account_not_verified', request: req }); return res.status(403).json({ success: false, message: 'Please verify your account before logging in.', code: 'ACCOUNT_NOT_VERIFIED', errors: [] }); } if (user.accountStatus === 'deactivated') { await recordLoginEvent({ userId: user.id, result: 'successful', authenticationMethod: 'password', request: req }); return deactivatedResponse(res, user); } await recordLoginEvent({ userId: user.id, result: 'successful', authenticationMethod: 'password', request: req }); return success(res, 'Logged in.', { ...(await issueTokens(user, req.ip)), user: profile(user) }); };
exports.google = async (req, res, next) => {
  if (!googleClient) return res.status(503).json({ success: false, message: 'Google Sign-In is not configured on this server yet.', code: 'GOOGLE_AUTH_NOT_CONFIGURED', errors: [] });
  let payload;
  try { payload = (await googleClient.verifyIdToken({ idToken: req.body.idToken, audience: googleIds })).getPayload(); } catch (_) { return res.status(401).json({ success: false, message: 'Invalid Google ID token.', code: 'TOKEN_INVALID', errors: [] }); }
  if (!payload.email || !payload.sub) return res.status(401).json({ success: false, message: 'Google token is missing required profile information.', code: 'TOKEN_INVALID', errors: [] });
  const { User } = getModels();
  const email = emailOf(payload.email);
  let user = await User.findOne({ where: { email } });
  let isNewUser = false;
  if (user?.accountStatus === 'deleted') return res.status(401).json({ success: false, message: 'This account is unavailable.', code: 'INVALID_CREDENTIALS', errors: [] });
  if (user && user.authProvider === 'local') return res.status(409).json({ success: false, message: 'An account with this email uses password login. Please log in with your password first.', code: 'INVALID_CREDENTIALS', errors: [] });
  if (!user) {
    if (!(await runtimeConfiguration()).registration_enabled) return res.status(403).json({ success: false, message: 'New registrations are currently unavailable.', code: 'REGISTRATION_DISABLED', errors: [] });
    try {
      user = await User.sequelize.transaction(async (transaction) => {
        const created = await User.create({ name: payload.name || email.split('@')[0], email, googleId: payload.sub, phoneNumber: '', authProvider: 'google', isVerified: true }, { transaction });
        await consentService.recordRequiredSignupConsent({ userId: created.id, acceptedLegalDocuments: req.body.acceptedLegalDocuments, source: 'SIGNUP_GOOGLE', platform: req.body.platform, metadata: req.body.consentMetadata, transaction });
        return created;
      });
      isNewUser = true;
    } catch (error) { return next(error); }
  }
  await recordLoginEvent({ userId: user.id, result: 'successful', authenticationMethod: 'google', request: req });
  if (user.accountStatus === 'deactivated') return deactivatedResponse(res, user);
  return success(res, 'Google Sign-In successful.', { ...(await issueTokens(user, req.ip)), user: profile(user), isNewUser });
};
exports.reactivate = async (req, res, next) => {
  let payload;
  try {
    payload = jwt.verify(req.body.reactivationToken, process.env.JWT_SECRET, {
      issuer: REACTIVATION_ISSUER,
      audience: REACTIVATION_AUDIENCE,
    });
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Reactivation authorization is invalid or has expired.', code: error.name === 'TokenExpiredError' ? 'REACTIVATION_EXPIRED' : 'REACTIVATION_INVALID', errors: [] });
  }
  if (payload.purpose !== 'account_reactivation' || !payload.sub) {
    return res.status(401).json({ success: false, message: 'Reactivation authorization is invalid or has expired.', code: 'REACTIVATION_INVALID', errors: [] });
  }
  try {
    const { User } = getModels();
    const outcome = await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(payload.sub, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user || user.accountStatus === 'deleted') return { invalid: true };
      if (user.accountStatus !== 'deactivated' || Number(payload.ver) !== Number(user.tokenVersion || 0)) return { used: true };
      user.accountStatus = 'active';
      user.deactivatedAt = null;
      user.tokenVersion += 1;
      await user.save({ transaction });
      const tokens = await issueTokens(user, req.ip, { transaction });
      return { user, tokens };
    });
    if (outcome.invalid) return res.status(401).json({ success: false, message: 'Reactivation authorization is invalid.', code: 'REACTIVATION_INVALID', errors: [] });
    if (outcome.used) return res.status(409).json({ success: false, message: 'This reactivation authorization has already been used.', code: 'REACTIVATION_ALREADY_USED', errors: [] });
    return success(res, 'Your account has been reactivated.', { ...outcome.tokens, user: profile(outcome.user) });
  } catch (error) { return next(error); }
};
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
    } catch (error) {
      await OtpToken.update({ consumed: true }, { where: { id: pendingOtp.otp.id } }).catch(() => {});
      console.error('[OTP] Password reset email delivery failed:', error.message);
      return res.status(503).json({
        success: false,
        message: error.message || "We couldn't send the verification code. Please try again.",
        code: 'OTP_DELIVERY_FAILED',
        errors: [],
      });
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
exports.changePassword = async (req, res, next) => {
  try {
    const { User } = getModels();
    const result = await User.sequelize.transaction(async (transaction) => {
      const user = await User.findOne({
        where: { id: req.user.sub, authProvider: 'local', accountStatus: 'active' },
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!user || !(await bcrypt.compare(req.body.currentPassword, user.passwordHash || ''))) {
        return 'CURRENT_PASSWORD_INCORRECT';
      }
      if (req.body.newPassword.length < 8) {
        return 'PASSWORD_POLICY_INVALID';
      }
      if (await bcrypt.compare(req.body.newPassword, user.passwordHash || '')) {
        return 'NEW_PASSWORD_SAME_AS_CURRENT';
      }
      user.passwordHash = await bcrypt.hash(req.body.newPassword, 12);
      await user.save({ transaction });
      return 'UPDATED';
    });
    if (result === 'CURRENT_PASSWORD_INCORRECT') {
      return res.status(401).json({ success: false, message: 'The current password you entered is incorrect.', code: 'CURRENT_PASSWORD_INCORRECT', errors: [] });
    }
    if (result === 'PASSWORD_POLICY_INVALID') {
      return res.status(400).json({ success: false, message: 'Validation failed.', code: 'VALIDATION_ERROR', errors: [{ field: 'newPassword', message: 'New password must contain at least 8 characters.' }] });
    }
    if (result === 'NEW_PASSWORD_SAME_AS_CURRENT') {
      return res.status(409).json({ success: false, message: 'New password cannot be the same as the current password.', code: 'NEW_PASSWORD_SAME_AS_CURRENT', errors: [] });
    }
    return success(res, 'Password updated.', {});
  } catch (error) { return next(error); }
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
