const { Op } = require('sequelize');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');
const { calculateProfileCompletion } = require('./profileCompletionService');
const { ageFor } = require('./publicProfileService');
const { createEmailOtp, deliverEmailOtp } = require('./otpService');

const list = (value) => (Array.isArray(value) ? value : []);
const can = (request, permission) => (request.adminPermissions || new Set()).has(permission);

function maskEmail(value) {
  const [local, domain] = String(value || '').split('@');
  if (!local || !domain) return null;
  return `${local.slice(0, 1)}***@${domain}`;
}

function maskPhone(value) {
  const digits = String(value || '').replace(/\D/g, '');
  return digits ? `******${digits.slice(-4)}` : null;
}

function mediaUrl(request, value) {
  if (!value) return null;
  if (/^https?:\/\//i.test(value)) return value;
  return `${request.protocol}://${request.get('host')}${value}`;
}

function verificationStatus(user) {
  return user.identityVerification?.status || (user.identityVerifiedAt ? 'verified' : 'not_submitted');
}

function summary(request, user) {
  const profile = user.OnboardingProfile;
  const photos = list(profile?.photos);
  const primaryIndex = Math.min(Number(profile?.primaryPhotoIndex || 0), Math.max(0, photos.length - 1));
  const subscription = user.subscription;
  return {
    id: String(user.id),
    displayName: user.name,
    email: maskEmail(user.email),
    phone: maskPhone(user.phoneNumber),
    profileImageUrl: mediaUrl(request, photos[primaryIndex] || photos[0]),
    status: user.accountStatus,
    verificationStatus: verificationStatus(user),
    ...(can(request, 'membership.view') && subscription?.plan ? {
      membership: { name: subscription.plan.displayName, status: subscription.status },
    } : {}),
    ...(can(request, 'presence.view') ? {
      isOnline: Boolean(user.lastActiveAt && Date.now() - new Date(user.lastActiveAt).getTime() <= 5 * 60 * 1000),
    } : {}),
    lastActiveAt: user.lastActiveAt,
    createdAt: user.createdAt,
  };
}

function includes(request) {
  const { OnboardingProfile, IdentityVerification, Subscription, SubscriptionPlan } = getModels();
  return [
    { model: OnboardingProfile, required: false },
    { model: IdentityVerification, as: 'identityVerification', required: false },
    ...(can(request, 'membership.view') ? [{
      model: Subscription,
      as: 'subscription',
      required: false,
      include: [{ model: SubscriptionPlan, as: 'plan', required: false }],
    }] : []),
  ];
}

async function users(request, page) {
  const { User } = getModels();
  const where = {};
  if (request.query.search) {
    const search = String(request.query.search).trim();
    where[Op.or] = [
      { name: { [Op.like]: `%${search}%` } },
      ...( /^\d+$/.test(search) ? [{ id: Number(search) }] : []),
    ];
  }
  if (request.query.status) where.accountStatus = request.query.status;
  if (request.query.registeredFrom || request.query.registeredTo) {
    where.createdAt = {};
    if (request.query.registeredFrom) where.createdAt[Op.gte] = new Date(request.query.registeredFrom);
    if (request.query.registeredTo) where.createdAt[Op.lte] = new Date(request.query.registeredTo);
  }
  if (request.query.onlineStatus) {
    const threshold = new Date(Date.now() - 5 * 60 * 1000);
    if (request.query.onlineStatus === 'online') where.lastActiveAt = { [Op.gte]: threshold };
    else where[Op.and] = [{
      [Op.or]: [{ lastActiveAt: { [Op.lt]: threshold } }, { lastActiveAt: { [Op.is]: null } }],
    }];
  }
  const sortMap = { displayName: 'name', status: 'accountStatus', lastActiveAt: 'lastActiveAt', createdAt: 'createdAt' };
  const sortField = sortMap[request.query.sortBy] || 'createdAt';
  const sortDirection = String(request.query.sortDirection || 'desc').toUpperCase();
  const result = await User.findAndCountAll({
    where,
    include: includes(request),
    distinct: true,
    limit: page.pageSize,
    offset: page.offset,
    order: [[sortField, sortDirection], ['id', 'DESC']],
  });
  return {
    items: result.rows.map((user) => summary(request, user)),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function userById(request, userId) {
  const { User } = getModels();
  return User.findByPk(userId, { include: includes(request) });
}

async function details(request, userId) {
  const { Report, RefreshToken } = getModels();
  const user = await userById(request, userId);
  if (!user) return null;
  const [openReportCount, activeSessionCount] = await Promise.all([
    can(request, 'reports.view')
      ? Report.count({ where: { reportedUserId: userId, status: { [Op.in]: ['open', 'reviewing'] } } })
      : null,
    can(request, 'users.sessions.view')
      ? RefreshToken.count({ where: { userId, expiresAt: { [Op.gt]: new Date() } } })
      : null,
  ]);
  return {
    user: summary(request, user),
    updatedAt: user.updatedAt,
    emailVerified: user.isVerified,
    onboardingStatus: user.OnboardingProfile?.stage || null,
    ...(can(request, 'profiles.verification.view') ? {
      verification: user.identityVerification ? {
        verificationId: String(user.identityVerification.id),
        submittedAt: user.identityVerification.submittedAt,
        reviewedAt: user.identityVerification.reviewedAt,
        reasonSummary: user.identityVerification.status === 'rejected'
          ? user.identityVerification.rejectionReason : null,
      } : null,
    } : {}),
    ...(can(request, 'membership.view') && user.subscription ? {
      membership: {
        startedAt: user.subscription.startedAt,
        expiresAt: user.subscription.currentPeriodEnd,
      },
    } : {}),
    ...(openReportCount == null ? {} : { openReportCount }),
    ...(activeSessionCount == null ? {} : { activity: { activeSessionCount } }),
  };
}

async function profile(request, userId) {
  const { User, OnboardingProfile } = getModels();
  const user = await User.findByPk(userId, { include: [{ model: OnboardingProfile, required: false }] });
  if (!user) return null;
  const item = user.OnboardingProfile;
  if (!item) return { displayName: user.name, photos: [], isComplete: false, completionPercent: 0 };
  return {
    displayName: user.name,
    age: ageFor(item.birthDate),
    gender: item.gender,
    city: item.city,
    locationSummary: item.city,
    about: item.bio,
    occupation: item.profession,
    education: item.education,
    height: item.height,
    languages: list(item.languages),
    religion: item.religion,
    lifestyle: item.lifestyle || {},
    communicationStyle: item.communicationStyle,
    iceBreaker: item.iceBreaker,
    photos: list(item.photos).map((value) => mediaUrl(request, value)).filter(Boolean),
    isComplete: item.onboardingCompleted,
    completionPercent: calculateProfileCompletion(user, item).percentage,
  };
}

async function sessions(request, userId, page) {
  const { RefreshToken } = getModels();
  const result = await RefreshToken.findAndCountAll({
    where: { userId },
    limit: page.pageSize,
    offset: page.offset,
    order: [['createdAt', 'DESC'], ['id', 'DESC']],
  });
  return {
    items: result.rows.map((session) => ({
      id: String(session.id),
      status: session.expiresAt > new Date() ? 'active' : 'expired',
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      ...(can(request, 'auditLogs.requestContext.view') ? { ipAddress: session.createdByIp } : {}),
    })),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function activate(request, userId) {
  const { User } = getModels();
  return User.sequelize.transaction(async (transaction) => {
    const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) return null;
    if (user.accountStatus === 'deleted') {
      const error = new Error('Deleted accounts cannot be activated by this operation.');
      error.status = 409;
      error.code = 'INVALID_STATE';
      throw error;
    }
    const previous = user.accountStatus;
    if (previous !== 'active') await user.update({ accountStatus: 'active', deactivatedAt: null }, { transaction });
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.users.activate',
      targetType: 'user',
      targetId: user.id,
      oldValue: { accountStatus: previous },
      newValue: { accountStatus: user.accountStatus },
      transaction,
    });
    return user;
  });
}

async function deactivate(request, userId, reason) {
  const { User, RefreshToken } = getModels();
  return User.sequelize.transaction(async (transaction) => {
    const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) return null;
    if (user.accountStatus === 'deleted') {
      const error = new Error('Deleted accounts cannot be deactivated.');
      error.status = 409;
      error.code = 'INVALID_STATE';
      throw error;
    }
    const previous = user.accountStatus;
    if (previous === 'active') {
      await user.update({
        accountStatus: 'deactivated',
        deactivatedAt: new Date(),
        tokenVersion: Number(user.tokenVersion || 0) + 1,
      }, { transaction });
      await RefreshToken.destroy({ where: { userId }, transaction });
    }
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.users.deactivate',
      targetType: 'user',
      targetId: user.id,
      reason,
      oldValue: { accountStatus: previous },
      newValue: { accountStatus: user.accountStatus },
      transaction,
    });
    return user;
  });
}

async function forceLogout(request, userId) {
  const { User, RefreshToken } = getModels();
  return User.sequelize.transaction(async (transaction) => {
    const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) return null;
    const revokedSessions = await RefreshToken.destroy({ where: { userId }, transaction });
    await user.update({ tokenVersion: Number(user.tokenVersion || 0) + 1 }, { transaction });
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.users.force_logout',
      targetType: 'user',
      targetId: user.id,
      metadata: { revokedSessions },
      transaction,
    });
    return { user, revokedSessions };
  });
}

async function remove(request, userId, reason, details) {
  const { User, OtpToken, RefreshToken, Match } = getModels();
  return User.sequelize.transaction(async (transaction) => {
    const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) return null;
    if (user.accountStatus === 'deleted') {
      const error = new Error('This account has already been deleted.');
      error.status = 409;
      error.code = 'INVALID_STATE';
      throw error;
    }
    const previous = {
      accountStatus: user.accountStatus,
      email: maskEmail(user.email),
      phone: maskPhone(user.phoneNumber),
    };
    const previousEmail = user.email;
    const previousPhoneNumber = user.phoneNumber;
    const deletedIdentity = `deleted-${user.id}-${Date.now()}`;
    await user.update({
      accountStatus: 'deleted',
      deletedAt: new Date(),
      deactivatedAt: null,
      tokenVersion: Number(user.tokenVersion || 0) + 1,
      deletionReason: reason,
      deletionDetails: details || null,
      name: 'Deleted Member',
      email: `${deletedIdentity}@deleted.amora.invalid`,
      phoneNumber: deletedIdentity,
      passwordHash: null,
      googleId: null,
      isVerified: false,
    }, { transaction });
    await Promise.all([
      RefreshToken.destroy({ where: { userId }, transaction }),
      OtpToken.destroy({
        where: { [Op.or]: [{ email: previousEmail }, { phoneNumber: previousPhoneNumber }] },
        transaction,
      }),
      Match.destroy({ where: { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] }, transaction }),
    ]);
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.users.delete',
      targetType: 'user',
      targetId: user.id,
      reason,
      oldValue: previous,
      newValue: { accountStatus: 'deleted', identityAnonymized: true },
      transaction,
    });
    return user;
  });
}

async function requestPasswordReset(request, userId) {
  const { User, OtpToken } = getModels();
  const result = await User.sequelize.transaction(async (transaction) => {
    const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) return null;
    if (user.accountStatus === 'deleted' || user.authProvider !== 'local') {
      const error = new Error('This user is not eligible for a password reset.');
      error.status = 409;
      error.code = 'INVALID_STATE';
      throw error;
    }
    const recent = await OtpToken.findOne({
      where: {
        email: user.email,
        purpose: 'password_reset',
        consumed: false,
        createdAt: { [Op.gte]: new Date(Date.now() - 60 * 1000) },
      },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (recent) {
      const error = new Error('A password reset was requested recently.');
      error.status = 429;
      error.code = 'RESET_DELIVERY_COOLDOWN';
      throw error;
    }
    const pending = await createEmailOtp(user.email, 'password_reset', { transaction, deliver: false });
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.users.password_reset_requested',
      targetType: 'user',
      targetId: user.id,
      metadata: { delivery: 'email' },
      transaction,
    });
    return { user, pending };
  });
  if (!result) return null;
  try {
    await deliverEmailOtp(result.user.email, 'password_reset', result.pending.code, result.pending.expiresAt);
  } catch (cause) {
    await OtpToken.update({ consumed: true }, { where: { id: result.pending.otp.id } });
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.users.password_reset_delivery_failed',
      targetType: 'user',
      targetId: result.user.id,
      metadata: { delivery: 'email' },
    });
    const error = new Error('Password reset delivery failed. No reset code remains active.');
    error.status = 503;
    error.code = 'RESET_DELIVERY_FAILED';
    error.cause = cause;
    throw error;
  }
  return result.user;
}

module.exports = {
  summary,
  users,
  userById,
  details,
  profile,
  sessions,
  activate,
  deactivate,
  forceLogout,
  remove,
  requestPasswordReset,
};
