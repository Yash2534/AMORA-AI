const { getModels } = require('../models');
const accountDeletionService = require('../services/immediateAccountDeletionService');
const photoStorage = require('../utils/photoStorage');
const identityStorage = require('../utils/identityVerificationStorage');
const logger = require('../utils/logger');
const chatMediaStorage = require('../utils/chatMediaStorage');
const {
  createEmailOtp,
  createPhoneOtp,
  deliverEmailOtp,
  deliverPhoneOtp,
  verifyEmailOtp,
  verifyPhoneOtp,
} = require('../services/otpService');
const { ACCOUNT_DELETION_REASON_CODES } = require('../constants/accountDeletionReasons');
const { verifyProviderReauthentication } = require('../services/providerReauthenticationService');
const { recordAudit } = require('../services/adminAuditService');
const { normalizeIndianMobile, phoneReference } = require('../utils/phoneNumber');
const sendEmail = require('../utils/sendEmail');

const ACCOUNT_DELETION_PURPOSE = 'account_deletion';
const emailOf = (value) => String(value || '').trim().toLowerCase();
const phoneOf = normalizeIndianMobile;
const maskEmail = (email) => {
  const [local, domain] = email.split('@');
  if (!local || !domain) return '';
  return `${local[0]}${'*'.repeat(Math.max(3, local.length - 1))}@${domain}`;
};
const maskPhone = (phone) => `${phone.slice(0, 3)} ${'*'.repeat(6)}${phone.slice(-4)}`;
const deletionMethods = (user) => {
  if (!user?.isVerified) return [];
  const methods = [];
  const email = emailOf(user.email);
  const phone = phoneOf(user.phoneNumber);
  if (email && email.includes('@')) methods.push({ channel: 'EMAIL', destination: email, maskedDestination: maskEmail(email) });
  if (phone) methods.push({ channel: 'PHONE', destination: phone, maskedDestination: maskPhone(phone) });
  return methods;
};
const methodFor = (user, channel) => deletionMethods(user).find((method) => method.channel === channel);
const otpFailure = (res, checked) => res.status(400).json({
  success: false,
  message: checked.error[1],
  code: checked.error[0],
  errors: checked.error[2] === undefined ? [] : [{ remainingAttempts: checked.error[2] }],
});
const normalizeDeletionReason = (body) => {
  const reasonCode = typeof body.reasonCode === 'string' && ACCOUNT_DELETION_REASON_CODES.includes(body.reasonCode)
    ? body.reasonCode
    : null;
  if (reasonCode !== 'OTHER') return { reasonCode, reasonText: null };
  const reasonText = typeof body.reasonText === 'string' ? body.reasonText.trim() : '';
  return { reasonCode, reasonText: reasonText || null };
};

const ownProfile = (user) => ({ id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, isVerified: user.isVerified, accountStatus: user.accountStatus });

exports.deactivate = async (req, res, next) => {
  try {
    const { User, RefreshToken, UserDevice } = getModels();
    const userId = Number(req.user.sub);
    const reauthentication = await verifyProviderReauthentication(req.authUser, req.body);
    if (!reauthentication.ok) {
      const incorrect = reauthentication.code === 'CURRENT_PASSWORD_INCORRECT';
      return res.status(401).json({
        success: false,
        message: incorrect ? 'Incorrect password. Please try again.' : 'Sign in with your account provider again to continue.',
        code: reauthentication.code,
        errors: [],
      });
    }
    const outcome = await User.sequelize.transaction(async (transaction) => {
      const current = await User.findByPk(userId, {
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!current || current.accountStatus !== 'active') return { unavailable: true };
      if (current.authProvider !== req.authUser.authProvider) return { unavailable: true };
      current.accountStatus = 'deactivated';
      current.deactivatedAt = new Date();
      current.tokenVersion += 1;
      await current.save({ transaction });
      await RefreshToken.destroy({ where: { userId }, transaction });
      await UserDevice.destroy({ where: { userId }, transaction });
      await recordAudit({
        request: req,
        action: 'user.account.deactivated',
        targetType: 'user',
        targetId: userId,
        oldValue: { accountStatus: 'active' },
        newValue: { accountStatus: 'deactivated' },
        metadata: { actorType: 'user', actorUserId: userId, reauthenticationMethod: reauthentication.method },
        transaction,
      });
      return { user: current };
    });
    if (outcome.unavailable) {
      return res.status(409).json({ success: false, message: 'This account cannot be deactivated.', code: 'ACCOUNT_STATE_INVALID', errors: [] });
    }
    return res.json({ success: true, message: 'Account deactivated.', data: { user: ownProfile(outcome.user) } });
  } catch (error) {
    return next(error);
  }
};

exports.requestPhoneChange = async (req, res, next) => {
  const userId = Number(req.user.sub);
  const phoneNumber = phoneOf(req.body.phoneNumber);
  try {
    const reauthentication = await verifyProviderReauthentication(req.authUser, req.body);
    if (!reauthentication.ok) {
      return res.status(401).json({
        success: false,
        message: reauthentication.code === 'CURRENT_PASSWORD_INCORRECT'
          ? 'Incorrect password. Please try again.'
          : 'Sign in with your account provider again to continue.',
        code: reauthentication.code,
        errors: [],
      });
    }
    const { User, OtpToken } = getModels();
    let pending;
    const result = await User.sequelize.transaction(async (transaction) => {
      const current = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!current || current.accountStatus !== 'active') return { unavailable: true };
      if (current.phoneNumber === phoneNumber) return { unchanged: true };
      const owner = await User.findOne({ where: { phoneNumber }, transaction, lock: transaction.LOCK.UPDATE });
      if (owner && Number(owner.id) !== userId) {
        await recordAudit({
          request: req,
          action: 'user.phone.duplicate_claim_blocked',
          targetType: 'user',
          targetId: userId,
          metadata: { actorType: 'user', actorUserId: userId, phoneReference: phoneReference(phoneNumber), outcome: 'failed' },
          transaction,
        });
        return { conflict: true };
      }
      await OtpToken.update(
        { consumed: true },
        { where: { userId, purpose: 'phone_change', consumed: false }, transaction },
      );
      pending = await createPhoneOtp(phoneNumber, 'phone_change', { userId, transaction, deliver: false });
      return { ready: true, reauthenticationMethod: reauthentication.method };
    });
    if (result.unavailable) return res.status(409).json({ success: false, message: 'Phone change is unavailable for this account.', code: 'ACCOUNT_STATE_INVALID', errors: [] });
    if (result.unchanged) return res.status(409).json({ success: false, message: 'This phone number is already assigned to your account.', code: 'PHONE_UNCHANGED', errors: [] });
    if (result.conflict) return res.status(409).json({ success: false, message: 'This phone number is unavailable.', code: 'PHONE_UNAVAILABLE', errors: [] });
    try {
      await deliverPhoneOtp(phoneNumber, 'phone_change', pending.code, pending.expiresAt, { correlationId: req.adminCorrelationId });
    } catch (error) {
      await OtpToken.update({ consumed: true }, { where: { id: pending.otp.id } }).catch(() => {});
      logger.error('Phone change OTP delivery failed.', { errorCode: error.code || error.name });
      return res.status(503).json({ success: false, message: 'We could not send the verification code. Please try again.', code: 'OTP_DELIVERY_FAILED', errors: [] });
    }
    return res.json({
      success: true,
      message: 'Verification code sent to the new phone number.',
      data: { expiresAt: pending.expiresAt },
    });
  } catch (error) {
    return next(error);
  }
};

exports.confirmPhoneChange = async (req, res, next) => {
  const userId = Number(req.user.sub);
  const phoneNumber = phoneOf(req.body.phoneNumber);
  try {
    const { User, RefreshToken, UserDevice } = getModels();
    const outcome = await User.sequelize.transaction(async (transaction) => {
      const current = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!current || current.accountStatus !== 'active') return { unavailable: true };
      const checked = await verifyPhoneOtp(phoneNumber, req.body.code, 'phone_change', { userId, transaction, correlationId: req.adminCorrelationId });
      if (checked.error) {
        await recordAudit({
          request: req,
          action: 'user.phone.otp_failed',
          targetType: 'user',
          targetId: userId,
          metadata: { actorType: 'user', actorUserId: userId, phoneReference: phoneReference(phoneNumber), outcome: 'failed', failureCode: checked.error[0] },
          transaction,
        });
        return { checked };
      }
      const owner = await User.findOne({ where: { phoneNumber }, transaction, lock: transaction.LOCK.UPDATE });
      if (owner && Number(owner.id) !== userId) return { conflict: true };
      const priorReference = phoneReference(current.phoneNumber);
      current.phoneNumber = phoneNumber;
      current.isVerified = true;
      current.tokenVersion = Number(current.tokenVersion || 0) + 1;
      await current.save({ transaction });
      await RefreshToken.destroy({ where: { userId }, transaction });
      await UserDevice.destroy({ where: { userId }, transaction });
      await recordAudit({
        request: req,
        action: 'user.phone.ownership_changed',
        targetType: 'user',
        targetId: userId,
        oldValue: { phoneReference: priorReference },
        newValue: { phoneReference: phoneReference(phoneNumber) },
        metadata: { actorType: 'user', actorUserId: userId, sessionsRevoked: true },
        transaction,
      });
      return { user: current, notificationEmail: current.email };
    });
    if (outcome.unavailable) return res.status(409).json({ success: false, message: 'Phone change is unavailable for this account.', code: 'ACCOUNT_STATE_INVALID', errors: [] });
    if (outcome.checked?.error) return otpFailure(res, outcome.checked);
    if (outcome.conflict) return res.status(409).json({ success: false, message: 'This phone number is unavailable.', code: 'PHONE_UNAVAILABLE', errors: [] });
    if (outcome.notificationEmail) {
      sendEmail(
        outcome.notificationEmail,
        'Your AMORAA phone number was changed',
        '<p>The phone number on your AMORAA account was changed and existing sessions were signed out.</p><p>If this was not you, contact support through the approved account-recovery channel.</p>',
        { purpose: 'phone_change_security_notice' },
      ).catch((error) => logger.error('Phone change security notice delivery failed.', { errorCode: error.code || error.name }));
    }
    return res.json({ success: true, message: 'Phone number updated. Please sign in again.', data: { user: ownProfile(outcome.user), sessionsRevoked: true } });
  } catch (error) {
    const databaseCode = error.original?.code || error.parent?.code;
    if (databaseCode === 'ER_LOCK_DEADLOCK' || databaseCode === 'ER_LOCK_WAIT_TIMEOUT') {
      return res.status(409).json({ success: false, message: 'This phone number is unavailable or another ownership claim is in progress.', code: 'PHONE_OWNERSHIP_CONFLICT', errors: [] });
    }
    // The unique phone index is the authoritative ownership boundary. A concurrent
    // verified claim that loses the race surfaces here; map it without a racy re-read.
    if (error.name === 'SequelizeUniqueConstraintError' || databaseCode === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'This phone number is unavailable.', code: 'PHONE_UNAVAILABLE', errors: [] });
    }
    logger.error('Phone ownership transaction failed.', {
      errorName: error.name,
      databaseCode,
      sqlState: error.original?.sqlState || error.parent?.sqlState,
    });
    return next(error);
  }
};

exports.deletionMethods = async (req, res) => {
  const methods = deletionMethods(req.authUser).map(({ channel, maskedDestination }) => ({
    channel,
    maskedDestination,
  }));
  if (!methods.length) {
    return res.status(409).json({
      success: false,
      message: 'No verified email or phone number is available for account deletion verification.',
      code: 'DELETION_VERIFICATION_UNAVAILABLE',
      errors: [],
    });
  }
  return res.json({ success: true, message: 'Account deletion verification methods.', data: { methods } });
};

exports.sendDeletionOtp = async (req, res, next) => {
  const channel = String(req.body.channel || '').toUpperCase();
  const method = methodFor(req.authUser, channel);
  if (!method) {
    return res.status(409).json({
      success: false,
      message: 'The selected verification method is not available for this account.',
      code: 'DELETION_CHANNEL_UNAVAILABLE',
      errors: [],
    });
  }
  const create = channel === 'EMAIL' ? createEmailOtp : createPhoneOtp;
  const deliver = channel === 'EMAIL' ? deliverEmailOtp : deliverPhoneOtp;
  let pending;
  try {
    const { User } = getModels();
    await User.sequelize.transaction(async (transaction) => {
      pending = await create(method.destination, ACCOUNT_DELETION_PURPOSE, {
        userId: Number(req.user.sub), transaction, deliver: false,
      });
    });
    await deliver(method.destination, ACCOUNT_DELETION_PURPOSE, pending.code, pending.expiresAt);
    return res.json({
      success: true,
      message: 'Verification code sent.',
      data: {
        channel,
        maskedDestination: method.maskedDestination,
        expiresAt: pending.expiresAt,
      },
    });
  } catch (error) {
    if (pending?.otp?.id) {
      const { OtpToken } = getModels();
      await OtpToken.update({ consumed: true }, { where: { id: pending.otp.id } }).catch(() => {});
    }
    if (error.code === 'OTP_CONFIG_ERROR') {
      return res.status(502).json({ success: false, message: 'The verification provider is not configured.', code: 'OTP_PROVIDER_AUTH_ERROR', errors: [] });
    }
    logger.error('Account deletion OTP delivery failed.', { channel, errorCode: error.code || error.name });
    return res.status(503).json({
      success: false,
      message: 'We could not send the verification code. Please try again.',
      code: 'OTP_DELIVERY_FAILED',
      errors: [],
    });
  }
};

exports.confirmDeletion = async (req, res, next) => {
  const userId = Number(req.user.sub);
  const channel = String(req.body.channel || '').toUpperCase();
  const { reasonCode, reasonText } = normalizeDeletionReason(req.body);
  try {
    const { User } = getModels();
    const outcome = await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user || user.accountStatus !== 'active') return { unavailable: true };
      const method = methodFor(user, channel);
      if (!method) return { unavailable: true };
      const verify = channel === 'EMAIL' ? verifyEmailOtp : verifyPhoneOtp;
      const checked = await verify(
        method.destination,
        req.body.otp,
        ACCOUNT_DELETION_PURPOSE,
        { userId, transaction },
      );
      if (checked.error) return { checked };
      const result = await accountDeletionService.execute({
        user,
        transaction,
        deletionReasonCode: reasonCode,
        deletionReasonText: reasonText,
      });
      return { result };
    });
    if (outcome.unavailable) {
      return res.status(409).json({ success: false, message: 'Account deletion verification is unavailable.', code: 'DELETION_VERIFICATION_UNAVAILABLE', errors: [] });
    }
    if (outcome.checked?.error) return otpFailure(res, outcome.checked);
    if (!outcome.result?.completed) {
      return res.status(409).json({ success: false, message: 'This account has already been deleted.', code: 'ACCOUNT_ALREADY_DELETED', errors: [] });
    }
    const cleanup = outcome.result.storageCleanup;
    for (const photo of cleanup.profilePhotos) photoStorage.remove(photo);
    await Promise.allSettled([
      ...cleanup.identityFiles.map((file) => identityStorage.removeStored(file)),
      ...cleanup.chatMedia.map((file) =>
        chatMediaStorage.removeStoredMedia(chatMediaStorage.absolutePathFor(file))),
    ]);
    return res.json({
      success: true,
      message: 'Your account has been deleted.',
      data: { deleted: true },
    });
  } catch (error) {
    return next(error);
  }
};
