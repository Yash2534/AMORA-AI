const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');
const { sendAdminPasswordReset } = require('./adminPasswordMailer');
const mfa = require('./adminMfaService');

const accessMinutes = () => Math.max(5, Math.min(60, Number(process.env.ADMIN_ACCESS_TOKEN_TTL_MINUTES || 15)));
const refreshDays = () => Math.max(1, Math.min(90, Number(process.env.ADMIN_REFRESH_TOKEN_TTL_DAYS || 30)));
const resetMinutes = () => Math.max(5, Math.min(120, Number(process.env.ADMIN_PASSWORD_RESET_TTL_MINUTES || 30)));
const tokenHash = (token) => crypto.createHash('sha256').update(token).digest('hex');
const normalizeEmail = (value) => String(value || '').trim().toLowerCase();
const now = () => new Date();

function tokenMatches(token, hash) {
  const actual = Buffer.from(tokenHash(token), 'hex');
  const expected = Buffer.from(String(hash || ''), 'hex');
  return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
}

function authError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

async function administratorWithAccess(id, options = {}) {
  const { Administrator, AdminRole, AdminPermission, AdminMfaCredential } = getModels();
  return Administrator.findByPk(id, {
    ...options,
    include: [{
      model: AdminRole,
      as: 'roles',
      where: { isActive: true },
      required: false,
      through: { attributes: [] },
      include: [{
        model: AdminPermission,
        as: 'permissions',
        through: { attributes: [] },
      }],
    }, {
      model: AdminMfaCredential,
      as: 'mfaCredential',
      required: false,
      attributes: ['id', 'enabledAt', 'disabledAt'],
    }],
  });
}

function permissionsFor(administrator) {
  return [...new Set((administrator.roles || [])
    .flatMap((role) => (role.permissions || []).map((permission) => permission.key)))]
    .sort();
}

function serializeAdministrator(administrator) {
  const roles = (administrator.roles || []).map((role) => ({
    id: String(role.id),
    key: role.key,
    name: role.name,
  }));
  const primary = roles[0] || { id: '', key: 'unassigned', name: 'Unassigned' };
  return {
    id: String(administrator.id),
    name: administrator.name,
    email: administrator.email,
    isActive: administrator.status === 'active',
    status: administrator.status,
    role: primary,
    roles,
    permissions: permissionsFor(administrator),
    lastLoginAt: administrator.lastLoginAt,
    mfaEnabled: Boolean(administrator.mfaCredential?.enabledAt && !administrator.mfaCredential?.disabledAt),
  };
}

function accessTokenFor(administrator, session) {
  const expiresIn = accessMinutes() * 60;
  return {
    accessToken: jwt.sign({
      sub: String(administrator.id),
      sid: session.selector,
      typ: 'admin_access',
      ver: Number(administrator.tokenVersion || 0),
      amr: session.mfaVerifiedAt ? ['pwd', 'otp'] : ['pwd'],
    }, process.env.ADMIN_JWT_SECRET, {
      expiresIn,
      issuer: 'amoraa-backend',
      audience: 'amoraa-admin-web',
    }),
    expiresIn,
  };
}

async function createRefreshSession(administrator, request, options = {}) {
  const { AdminRefreshToken } = getModels();
  const selector = crypto.randomBytes(16).toString('hex');
  const token = selector + '.' + crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + refreshDays() * 24 * 60 * 60 * 1000);
  const row = await AdminRefreshToken.create({
    administratorId: administrator.id,
    sessionFamilyId: options.sessionFamilyId || crypto.randomUUID(),
    selector,
    tokenHash: tokenHash(token),
    expiresAt,
    createdByIp: request.ip || null,
    userAgent: String(request.headers['user-agent'] || '').slice(0, 500) || null,
    persistent: options.persistent === true,
    mfaVerifiedAt: options.mfaVerifiedAt || null,
  }, { transaction: options.transaction });
  return { row, token, expiresAt, persistent: row.persistent };
}

async function login(email, password, rememberMe, request) {
  const { Administrator } = getModels();
  const normalized = normalizeEmail(email);
  const administrator = await Administrator.findOne({ where: { email: normalized } });
  const locked = administrator?.lockedUntil && new Date(administrator.lockedUntil) > now();
  const passwordMatches = administrator?.passwordHash
    ? await bcrypt.compare(password, administrator.passwordHash)
    : false;

  if (!administrator || !passwordMatches || locked) {
    if (administrator && !locked) {
      const failedLoginAttempts = Number(administrator.failedLoginAttempts || 0) + 1;
      await administrator.update({
        failedLoginAttempts,
        lockedUntil: failedLoginAttempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : null,
      });
    }
    await recordAudit({
      request,
      administratorId: administrator?.id,
      action: 'admin.auth.login_failed',
      targetType: 'administrator',
      targetId: administrator?.id,
      metadata: { email: normalized, reason: locked ? 'locked' : 'invalid_credentials' },
    });
    throw authError(401, 'INVALID_CREDENTIALS', 'Invalid administrator email or password.');
  }
  if (administrator.status !== 'active') {
    await recordAudit({
      request,
      administratorId: administrator.id,
      action: 'admin.auth.login_denied',
      targetType: 'administrator',
      targetId: administrator.id,
      metadata: { status: administrator.status },
    });
    throw authError(
      403,
      administrator.status === 'disabled' ? 'ACCOUNT_DISABLED' : 'ACCESS_DENIED',
      administrator.status === 'disabled'
        ? 'This administrator account has been disabled.'
        : 'This administrator account is suspended.',
    );
  }

  const loaded = await administratorWithAccess(administrator.id);
  if (!loaded?.roles?.length) throw authError(403, 'ACCESS_DENIED', 'No active administrator role is assigned.');
  if (await mfa.isEnabled(administrator.id)) {
    const challenge = await mfa.createLoginChallenge(administrator, rememberMe, request);
    return { mfaRequired: true, ...challenge };
  }
  const session = await Administrator.sequelize.transaction(async (transaction) => {
    const signedInAt = now();
    await administrator.update({
      failedLoginAttempts: 0,
      lockedUntil: null,
      lastLoginAt: signedInAt,
      lastActiveAt: signedInAt,
    }, { transaction });
    const created = await createRefreshSession(administrator, request, {
      transaction,
      persistent: rememberMe === true,
    });
    await recordAudit({
      request,
      administratorId: administrator.id,
      action: 'admin.auth.login_succeeded',
      targetType: 'administrator',
      targetId: administrator.id,
      transaction,
    });
    return created;
  });
  return { ...accessTokenFor(administrator, session.row), user: serializeAdministrator(loaded), session };
}

async function completeMfaLogin(challengeToken, input, request) {
  const verified = await mfa.consumeLoginChallenge(challengeToken, input, request);
  const administrator = verified.administrator;
  const loaded = await administratorWithAccess(administrator.id);
  if (!loaded?.roles?.length) throw authError(403, 'ACCESS_DENIED', 'No active administrator role is assigned.');
  const verifiedAt = now();
  const session = await administrator.sequelize.transaction(async (transaction) => {
    await administrator.update({
      failedLoginAttempts: 0,
      lockedUntil: null,
      lastLoginAt: verifiedAt,
      lastActiveAt: verifiedAt,
    }, { transaction });
    const created = await createRefreshSession(administrator, request, {
      transaction,
      persistent: verified.rememberMe,
      mfaVerifiedAt: verifiedAt,
    });
    await recordAudit({
      request,
      administratorId: administrator.id,
      action: 'admin.auth.login_succeeded',
      targetType: 'administrator',
      targetId: administrator.id,
      metadata: { mfa: true, method: verified.method },
      transaction,
    });
    return created;
  });
  return { ...accessTokenFor(administrator, session.row), user: serializeAdministrator(loaded), session };
}

function splitOpaqueToken(token) {
  if (typeof token !== 'string') return null;
  const [selector, secret, ...extra] = token.split('.');
  if (extra.length || !/^[a-f0-9]{32}$/.test(selector || '') || !/^[a-f0-9]{64}$/.test(secret || '')) return null;
  return { selector, token: selector + '.' + secret };
}

async function rotate(refreshToken, request) {
  const parsed = splitOpaqueToken(refreshToken);
  if (!parsed) throw authError(401, 'TOKEN_INVALID', 'Invalid or expired administrator session.');
  const { AdminRefreshToken, Administrator } = getModels();
  const result = await Administrator.sequelize.transaction(async (transaction) => {
    const existing = await AdminRefreshToken.findOne({
      where: { selector: parsed.selector },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!existing || !tokenMatches(parsed.token, existing.tokenHash)) return { invalid: true };

    if (existing.revokedAt) {
      if (existing.revokedReason === 'rotated') {
        const replayedAt = now();
        await AdminRefreshToken.update({
          revokedAt: replayedAt,
          revokedReason: 'replay_detected',
        }, {
          where: { sessionFamilyId: existing.sessionFamilyId, revokedAt: null },
          transaction,
        });
        await Administrator.increment('tokenVersion', {
          by: 1,
          where: { id: existing.administratorId },
          transaction,
        });
        return { replay: true, administratorId: existing.administratorId };
      }
      return { invalid: true };
    }

    if (existing.expiresAt <= now()) {
      const expiredAt = now();
      await existing.update({ revokedAt: expiredAt, revokedReason: 'expired', lastUsedAt: expiredAt }, { transaction });
      return { invalid: true };
    }

    const administrator = await Administrator.findByPk(existing.administratorId, {
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!administrator || administrator.status !== 'active') {
      const revokedAt = now();
      await existing.update({ revokedAt, revokedReason: 'account_inactive', lastUsedAt: revokedAt }, { transaction });
      return { invalid: true };
    }

    const session = await createRefreshSession(administrator, request, {
      transaction,
      persistent: existing.persistent,
      sessionFamilyId: existing.sessionFamilyId,
      mfaVerifiedAt: existing.mfaVerifiedAt,
    });
    const rotatedAt = now();
    await existing.update({
      revokedAt: rotatedAt,
      revokedReason: 'rotated',
      lastUsedAt: rotatedAt,
      replacedByTokenId: session.row.id,
    }, { transaction });
    return { administrator, session };
  });

  if (result.replay) {
    await recordAudit({
      request,
      administratorId: result.administratorId,
      action: 'admin.auth.refresh_replay_detected',
      targetType: 'administrator',
      targetId: result.administratorId,
    });
    throw authError(401, 'TOKEN_REUSED', 'This administrator session was revoked because token reuse was detected.');
  }
  if (result.invalid) throw authError(401, 'TOKEN_INVALID', 'Invalid or expired administrator session.');

  const loaded = await administratorWithAccess(result.administrator.id);
  if (!loaded?.roles?.length) {
    await result.session.row.update({ revokedAt: now(), revokedReason: 'role_unassigned' });
    throw authError(403, 'ACCESS_DENIED', 'No active administrator role is assigned.');
  }
  await recordAudit({
    request,
    administratorId: result.administrator.id,
    action: 'admin.auth.session_refreshed',
    targetType: 'administrator',
    targetId: result.administrator.id,
  });
  return {
    ...accessTokenFor(result.administrator, result.session.row),
    user: serializeAdministrator(loaded),
    session: result.session,
  };
}

async function logout(refreshToken, request) {
  const parsed = splitOpaqueToken(refreshToken);
  if (!parsed) return null;
  const { AdminRefreshToken } = getModels();
  const session = await AdminRefreshToken.findOne({ where: { selector: parsed.selector } });
  if (!session || !tokenMatches(parsed.token, session.tokenHash)) return null;
  if (!session.revokedAt) {
    await session.update({ revokedAt: now(), revokedReason: 'logout', lastUsedAt: now() });
  }
  await recordAudit({
    request,
    administratorId: session.administratorId,
    action: 'admin.auth.logout',
    targetType: 'administrator',
    targetId: session.administratorId,
    metadata: { sessionId: String(session.id) },
  });
  return session.administratorId;
}

async function requestPasswordReset(email, request) {
  const { Administrator, AdminPasswordResetToken } = getModels();
  const administrator = await Administrator.findOne({
    where: { email: normalizeEmail(email), status: 'active' },
  });
  if (!administrator) {
    await recordAudit({
      request,
      action: 'admin.auth.password_reset_requested',
      targetType: 'administrator',
      metadata: { matched: false },
    });
    return null;
  }

  const selector = crypto.randomBytes(16).toString('hex');
  const token = selector + '.' + crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + resetMinutes() * 60 * 1000);
  await Administrator.sequelize.transaction(async (transaction) => {
    await AdminPasswordResetToken.update({ consumedAt: now() }, {
      where: { administratorId: administrator.id, consumedAt: null },
      transaction,
    });
    await AdminPasswordResetToken.create({
      administratorId: administrator.id,
      selector,
      tokenHash: tokenHash(token),
      expiresAt,
      requestedByIp: request.ip || null,
    }, { transaction });
    await recordAudit({
      request,
      administratorId: administrator.id,
      action: 'admin.auth.password_reset_requested',
      targetType: 'administrator',
      targetId: administrator.id,
      transaction,
    });
  });
  try {
    await sendAdminPasswordReset({ email: administrator.email, token, expiresAt });
  } catch (error) {
    await AdminPasswordResetToken.update({ consumedAt: now() }, {
      where: { selector, consumedAt: null },
    });
    throw error;
  }
  return { token, expiresAt };
}

async function passwordResetStatus(token) {
  const parsed = splitOpaqueToken(token);
  if (!parsed) return 'invalid';
  const { AdminPasswordResetToken } = getModels();
  const row = await AdminPasswordResetToken.findOne({ where: { selector: parsed.selector } });
  if (!row || !tokenMatches(parsed.token, row.tokenHash)) return 'invalid';
  if (row.consumedAt) return 'used';
  if (row.expiresAt <= now()) return 'expired';
  return 'valid';
}

function validateNewPassword(value) {
  if (typeof value !== 'string' || value.length < 8 || value.length > 128
      || !/[a-z]/.test(value) || !/[A-Z]/.test(value)
      || !/[0-9]/.test(value) || !/[^A-Za-z0-9]/.test(value)) {
    throw authError(422, 'PASSWORD_POLICY_FAILED', 'The new password does not satisfy the administrator password policy.');
  }
}

async function resetPassword(token, newPassword, request) {
  validateNewPassword(newPassword);
  const parsed = splitOpaqueToken(token);
  if (!parsed) throw authError(422, 'RESET_TOKEN_INVALID', 'The password reset token is invalid.');
  const { Administrator, AdminPasswordResetToken, AdminRefreshToken } = getModels();
  const passwordHash = await bcrypt.hash(newPassword, 12);
  const result = await Administrator.sequelize.transaction(async (transaction) => {
    const reset = await AdminPasswordResetToken.findOne({
      where: { selector: parsed.selector },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!reset || !tokenMatches(parsed.token, reset.tokenHash)) return { status: 'invalid' };
    if (reset.consumedAt) return { status: 'used' };
    if (reset.expiresAt <= now()) return { status: 'expired' };
    const administrator = await Administrator.findByPk(reset.administratorId, {
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!administrator || administrator.status === 'disabled') return { status: 'invalid' };
    const changedAt = now();
    await administrator.update({
      passwordHash,
      tokenVersion: Number(administrator.tokenVersion || 0) + 1,
      failedLoginAttempts: 0,
      lockedUntil: null,
    }, { transaction });
    await AdminRefreshToken.update({ revokedAt: changedAt, revokedReason: 'password_reset' }, {
      where: { administratorId: administrator.id, revokedAt: null },
      transaction,
    });
    await AdminPasswordResetToken.update({ consumedAt: changedAt }, {
      where: { administratorId: administrator.id, consumedAt: null },
      transaction,
    });
    await recordAudit({
      request,
      administratorId: administrator.id,
      action: 'admin.auth.password_reset_completed',
      targetType: 'administrator',
      targetId: administrator.id,
      transaction,
    });
    return { status: 'changed', administratorId: administrator.id };
  });
  if (result.status === 'expired') throw authError(410, 'RESET_TOKEN_EXPIRED', 'The password reset token has expired.');
  if (result.status === 'used') throw authError(409, 'RESET_TOKEN_USED', 'The password reset token has already been used.');
  if (result.status !== 'changed') throw authError(422, 'RESET_TOKEN_INVALID', 'The password reset token is invalid.');
  return result;
}

async function changePassword(administratorId, currentPassword, newPassword, request) {
  validateNewPassword(newPassword);
  if (currentPassword === newPassword) {
    throw authError(422, 'PASSWORD_POLICY_FAILED', 'The new password must be different from the current password.');
  }
  const { Administrator, AdminRefreshToken } = getModels();
  const administrator = await Administrator.findByPk(administratorId);
  if (!administrator || !await bcrypt.compare(currentPassword, administrator.passwordHash)) {
    throw authError(422, 'CURRENT_PASSWORD_INVALID', 'The current password is incorrect.');
  }
  const passwordHash = await bcrypt.hash(newPassword, 12);
  await Administrator.sequelize.transaction(async (transaction) => {
    const changedAt = now();
    await administrator.update({
      passwordHash,
      tokenVersion: Number(administrator.tokenVersion || 0) + 1,
      failedLoginAttempts: 0,
      lockedUntil: null,
    }, { transaction });
    await AdminRefreshToken.update({ revokedAt: changedAt, revokedReason: 'password_changed' }, {
      where: { administratorId: administrator.id, revokedAt: null },
      transaction,
    });
    await recordAudit({
      request,
      administratorId: administrator.id,
      action: 'admin.auth.password_changed',
      targetType: 'administrator',
      targetId: administrator.id,
      transaction,
    });
  });
  return { sessionInvalidated: true, requiresLogin: true };
}

function serializeSession(session, currentSelector) {
  return {
    id: String(session.id),
    createdAt: session.createdAt,
    expiresAt: session.expiresAt,
    lastUsedAt: session.lastUsedAt,
    userAgent: session.userAgent,
    ipAddress: session.createdByIp,
    persistent: session.persistent,
    current: session.selector === currentSelector,
    revokedAt: session.revokedAt,
  };
}

async function listSessions(administratorId, currentSelector) {
  const { AdminRefreshToken } = getModels();
  const sessions = await AdminRefreshToken.findAll({
    where: {
      administratorId,
      revokedAt: null,
      expiresAt: { [Op.gt]: now() },
    },
    order: [['createdAt', 'DESC']],
  });
  return sessions.map((session) => serializeSession(session, currentSelector));
}

async function revokeSession(administratorId, sessionId, currentSelector, request) {
  const { Administrator, AdminRefreshToken } = getModels();
  const result = await Administrator.sequelize.transaction(async (transaction) => {
    const session = await AdminRefreshToken.findOne({
      where: { id: sessionId, administratorId },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!session) return null;
    const revokedAt = now();
    if (!session.revokedAt) {
      await session.update({ revokedAt, revokedReason: 'session_revoked' }, { transaction });
    }
    if (session.selector === currentSelector) {
      await Administrator.increment('tokenVersion', {
        by: 1,
        where: { id: administratorId },
        transaction,
      });
    }
    await recordAudit({
      request,
      administratorId,
      action: 'admin.auth.session_revoked',
      targetType: 'admin_session',
      targetId: session.id,
      metadata: { current: session.selector === currentSelector },
      transaction,
    });
    return serializeSession(session, currentSelector);
  });
  if (!result) throw authError(404, 'NOT_FOUND', 'Administrator session not found.');
  return result;
}

async function clearExpiredSessions() {
  const { AdminRefreshToken, AdminPasswordResetToken } = getModels();
  const cutoff = now();
  const [sessions, resetTokens] = await Promise.all([
    AdminRefreshToken.destroy({ where: { expiresAt: { [Op.lte]: cutoff } } }),
    AdminPasswordResetToken.destroy({ where: { expiresAt: { [Op.lte]: cutoff } } }),
  ]);
  return { sessions, resetTokens };
}

module.exports = {
  authError,
  administratorWithAccess,
  permissionsFor,
  serializeAdministrator,
  accessTokenFor,
  login,
  completeMfaLogin,
  rotate,
  logout,
  requestPasswordReset,
  passwordResetStatus,
  resetPassword,
  changePassword,
  listSessions,
  revokeSession,
  clearExpiredSessions,
};
