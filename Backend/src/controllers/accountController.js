const { getModels } = require('../models');
const accountDeletionService = require('../services/immediateAccountDeletionService');
const photoStorage = require('../utils/photoStorage');
const identityStorage = require('../utils/identityVerificationStorage');
const chatMediaStorage = require('../utils/chatMediaStorage');
const {
  createEmailOtp,
  createPhoneOtp,
  deliverEmailOtp,
  deliverPhoneOtp,
  verifyEmailOtp,
  verifyPhoneOtp,
} = require('../services/otpService');

const ACCOUNT_DELETION_PURPOSE = 'account_deletion';
const emailOf = (value) => String(value || '').trim().toLowerCase();
const phoneOf = (value) => {
  const digits = String(value || '').replace(/\D/g, '');
  const national = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits;
  return /^\d{10}$/.test(national) ? `+91${national}` : '';
};
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

const ownProfile = (user) => ({ id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, isVerified: user.isVerified, accountStatus: user.accountStatus });

exports.deactivate = async (req, res, next) => {
  try {
    const bcrypt = require('bcrypt');
    const { User, RefreshToken, UserDevice } = getModels();
    const userId = Number(req.user.sub);
    const outcome = await User.sequelize.transaction(async (transaction) => {
      const current = await User.findByPk(userId, {
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!current || current.accountStatus !== 'active') return { unavailable: true };
      if (current.authProvider !== 'local' || !current.passwordHash) return { passwordUnavailable: true };
      if (!(await bcrypt.compare(req.body.password, current.passwordHash))) return { incorrectPassword: true };
      current.accountStatus = 'deactivated';
      current.deactivatedAt = new Date();
      current.tokenVersion += 1;
      await current.save({ transaction });
      await RefreshToken.destroy({ where: { userId }, transaction });
      await UserDevice.destroy({ where: { userId }, transaction });
      return { user: current };
    });
    if (outcome.unavailable) {
      return res.status(409).json({ success: false, message: 'This account cannot be deactivated.', code: 'ACCOUNT_STATE_INVALID', errors: [] });
    }
    if (outcome.passwordUnavailable) {
      return res.status(409).json({ success: false, message: 'Password verification is not available for this account.', code: 'DEACTIVATION_REAUTH_UNAVAILABLE', errors: [] });
    }
    if (outcome.incorrectPassword) {
      return res.status(401).json({ success: false, message: 'Incorrect password. Please try again.', code: 'CURRENT_PASSWORD_INCORRECT', errors: [] });
    }
    return res.json({ success: true, message: 'Account deactivated.', data: { user: ownProfile(outcome.user) } });
  } catch (error) {
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
    console.error(`[Account deletion] ${channel} OTP delivery failed:`, error.code || error.name);
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
      const result = await accountDeletionService.execute({ user, transaction });
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
