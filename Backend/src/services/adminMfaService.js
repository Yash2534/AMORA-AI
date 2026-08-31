const crypto = require('crypto');
const { Op } = require('sequelize');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');

const BASE32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const RECOVERY_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const now = () => new Date();
const challengeMinutes = () => Math.max(2, Math.min(10, Number(process.env.ADMIN_MFA_CHALLENGE_TTL_MINUTES || 5)));
const stepUpMinutes = () => Math.max(2, Math.min(30, Number(process.env.ADMIN_MFA_STEP_UP_TTL_MINUTES || 10)));

function serviceError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function encryptionKey() {
  const configured = String(process.env.ADMIN_MFA_ENCRYPTION_KEY || '').trim();
  if (/^[a-f0-9]{64}$/i.test(configured)) return Buffer.from(configured, 'hex');
  if (configured) {
    const decoded = Buffer.from(configured, 'base64');
    if (decoded.length === 32) return decoded;
  }
  if (process.env.NODE_ENV === 'production') {
    throw serviceError(503, 'MFA_NOT_CONFIGURED', 'Administrator MFA encryption is not configured.');
  }
  return crypto.createHash('sha256').update(`development-only:${process.env.ADMIN_JWT_SECRET}`).digest();
}

function tokenHash(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function recoveryHash(value) {
  return crypto.createHmac('sha256', encryptionKey()).update(normalizeRecoveryCode(value)).digest('hex');
}

function safeEqualHex(actual, expected) {
  const left = Buffer.from(String(actual || ''), 'hex');
  const right = Buffer.from(String(expected || ''), 'hex');
  return left.length === right.length && crypto.timingSafeEqual(left, right);
}

function encodeBase32(buffer) {
  let bits = 0;
  let value = 0;
  let result = '';
  for (const byte of buffer) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      result += BASE32[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) result += BASE32[(value << (5 - bits)) & 31];
  return result;
}

function decodeBase32(value) {
  const normalized = String(value || '').toUpperCase().replace(/=+$/g, '').replace(/\s+/g, '');
  let bits = 0;
  let accumulator = 0;
  const output = [];
  for (const character of normalized) {
    const index = BASE32.indexOf(character);
    if (index < 0) throw serviceError(500, 'MFA_SECRET_INVALID', 'The stored MFA credential is invalid.');
    accumulator = (accumulator << 5) | index;
    bits += 5;
    if (bits >= 8) {
      output.push((accumulator >>> (bits - 8)) & 255);
      bits -= 8;
    }
  }
  return Buffer.from(output);
}

function encryptSecret(secret) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', encryptionKey(), iv);
  const encrypted = Buffer.concat([cipher.update(secret, 'utf8'), cipher.final()]);
  return {
    encryptedSecret: encrypted.toString('base64'),
    secretIv: iv.toString('hex'),
    secretTag: cipher.getAuthTag().toString('hex'),
  };
}

function decryptSecret(credential) {
  try {
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm', encryptionKey(), Buffer.from(credential.secretIv, 'hex'),
    );
    decipher.setAuthTag(Buffer.from(credential.secretTag, 'hex'));
    return Buffer.concat([
      decipher.update(Buffer.from(credential.encryptedSecret, 'base64')),
      decipher.final(),
    ]).toString('utf8');
  } catch (_) {
    throw serviceError(503, 'MFA_CREDENTIAL_UNAVAILABLE', 'The MFA credential cannot be decrypted with the configured key.');
  }
}

function totpFor(secret, counter) {
  const counterBuffer = Buffer.alloc(8);
  counterBuffer.writeBigUInt64BE(BigInt(counter));
  const digest = crypto.createHmac('sha1', decodeBase32(secret)).update(counterBuffer).digest();
  const offset = digest[digest.length - 1] & 15;
  const binary = ((digest[offset] & 127) << 24)
    | ((digest[offset + 1] & 255) << 16)
    | ((digest[offset + 2] & 255) << 8)
    | (digest[offset + 3] & 255);
  return String(binary % 1000000).padStart(6, '0');
}

function matchingCounter(secret, code, timestamp = Date.now()) {
  if (!/^\d{6}$/.test(String(code || ''))) return null;
  const current = Math.floor(timestamp / 30000);
  for (const counter of [current - 1, current, current + 1]) {
    const actual = Buffer.from(totpFor(secret, counter));
    const supplied = Buffer.from(String(code));
    if (actual.length === supplied.length && crypto.timingSafeEqual(actual, supplied)) return counter;
  }
  return null;
}

function normalizeRecoveryCode(value) {
  return String(value || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

function newRecoveryCode() {
  let value = '';
  const bytes = crypto.randomBytes(8);
  for (const byte of bytes) value += RECOVERY_ALPHABET[byte % RECOVERY_ALPHABET.length];
  return `${value.slice(0, 4)}-${value.slice(4)}`;
}

function publicStatus(credential, remainingRecoveryCodes = 0) {
  const enabled = Boolean(credential?.enabledAt && !credential.disabledAt);
  return {
    enabled,
    status: enabled ? 'enabled' : credential ? 'pending_enrollment' : 'disabled',
    enabledAt: enabled ? credential.enabledAt : null,
    recoveryCodesRemaining: enabled ? remainingRecoveryCodes : 0,
    stepUpWindowMinutes: stepUpMinutes(),
  };
}

async function credentialFor(administratorId, options = {}) {
  const { AdminMfaCredential } = getModels();
  return AdminMfaCredential.findOne({ where: { administratorId }, ...options });
}

async function isEnabled(administratorId, options = {}) {
  const credential = await credentialFor(administratorId, options);
  return Boolean(credential?.enabledAt && !credential.disabledAt);
}

async function status(administratorId) {
  const { AdminMfaRecoveryCode } = getModels();
  const credential = await credentialFor(administratorId);
  const remaining = credential?.enabledAt && !credential.disabledAt
    ? await AdminMfaRecoveryCode.count({
      where: { administratorId, generation: credential.recoveryCodeGeneration, consumedAt: null },
    }) : 0;
  return publicStatus(credential, remaining);
}

async function beginEnrollment(administrator, request) {
  const { AdminMfaCredential, AdminMfaRecoveryCode } = getModels();
  const secret = encodeBase32(crypto.randomBytes(20));
  const encrypted = encryptSecret(secret);
  const credential = await AdminMfaCredential.findOne({ where: { administratorId: administrator.id } });
  if (credential?.enabledAt && !credential.disabledAt) {
    throw serviceError(409, 'MFA_ALREADY_ENABLED', 'Multi-factor authentication is already enabled.');
  }
  await AdminMfaCredential.sequelize.transaction(async (transaction) => {
    if (credential) {
      await credential.update({ ...encrypted, enabledAt: null, disabledAt: null, lastUsedCounter: null }, { transaction });
    } else {
      await AdminMfaCredential.create({ administratorId: administrator.id, ...encrypted }, { transaction });
    }
    await AdminMfaRecoveryCode.destroy({ where: { administratorId: administrator.id }, transaction });
    await recordAudit({
      request, administratorId: administrator.id, action: 'admin.auth.mfa_enrollment_started',
      targetType: 'administrator', targetId: administrator.id, transaction,
    });
  });
  const label = encodeURIComponent(`AMORAA:${administrator.email}`);
  return {
    secret,
    provisioningUri: `otpauth://totp/${label}?secret=${secret}&issuer=AMORAA&algorithm=SHA1&digits=6&period=30`,
    algorithm: 'SHA1', digits: 6, periodSeconds: 30,
  };
}

async function verifyFactor(administratorId, input, options = {}) {
  const { AdminMfaCredential, AdminMfaRecoveryCode } = getModels();
  const credential = await AdminMfaCredential.findOne({
    where: { administratorId }, transaction: options.transaction,
    lock: options.transaction ? options.transaction.LOCK.UPDATE : undefined,
  });
  if (!credential || !credential.enabledAt || credential.disabledAt) {
    throw serviceError(409, 'MFA_NOT_ENABLED', 'Multi-factor authentication is not enabled.');
  }
  if (input.code) {
    const counter = matchingCounter(decryptSecret(credential), input.code);
    if (counter == null || (credential.lastUsedCounter != null && counter <= Number(credential.lastUsedCounter))) {
      throw serviceError(401, 'MFA_CODE_INVALID', 'The authentication code is invalid or has already been used.');
    }
    await credential.update({ lastUsedCounter: counter }, { transaction: options.transaction });
    return { method: 'totp' };
  }
  const normalized = normalizeRecoveryCode(input.recoveryCode);
  if (normalized.length !== 8) throw serviceError(401, 'MFA_CODE_INVALID', 'The recovery code is invalid.');
  const hash = recoveryHash(normalized);
  const recovery = await AdminMfaRecoveryCode.findOne({
    where: {
      administratorId, generation: credential.recoveryCodeGeneration,
      codeHash: hash, consumedAt: null,
    },
    transaction: options.transaction,
    lock: options.transaction ? options.transaction.LOCK.UPDATE : undefined,
  });
  if (!recovery || !safeEqualHex(hash, recovery.codeHash)) {
    throw serviceError(401, 'MFA_CODE_INVALID', 'The recovery code is invalid.');
  }
  await recovery.update({ consumedAt: now() }, { transaction: options.transaction });
  return { method: 'recovery_code' };
}

async function createRecoveryCodes(administratorId, credential, transaction) {
  const { AdminMfaRecoveryCode } = getModels();
  const generation = Number(credential.recoveryCodeGeneration || 0) + 1;
  const codes = Array.from({ length: 10 }, newRecoveryCode);
  await AdminMfaRecoveryCode.destroy({ where: { administratorId }, transaction });
  await AdminMfaRecoveryCode.bulkCreate(codes.map((code) => ({
    administratorId, generation, codeHash: recoveryHash(code), createdAt: now(),
  })), { transaction });
  await credential.update({ recoveryCodeGeneration: generation }, { transaction });
  return codes;
}

async function confirmEnrollment(administrator, code, request) {
  const { AdminMfaCredential } = getModels();
  return AdminMfaCredential.sequelize.transaction(async (transaction) => {
    const credential = await AdminMfaCredential.findOne({
      where: { administratorId: administrator.id }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if (!credential || credential.enabledAt || credential.disabledAt) {
      throw serviceError(409, 'MFA_ENROLLMENT_NOT_STARTED', 'Start MFA enrollment before confirming it.');
    }
    const counter = matchingCounter(decryptSecret(credential), code);
    if (counter == null) throw serviceError(401, 'MFA_CODE_INVALID', 'The authentication code is invalid.');
    const enabledAt = now();
    await credential.update({ enabledAt, lastUsedCounter: counter }, { transaction });
    const recoveryCodes = await createRecoveryCodes(administrator.id, credential, transaction);
    await recordAudit({
      request, administratorId: administrator.id, action: 'admin.auth.mfa_enabled',
      targetType: 'administrator', targetId: administrator.id, transaction,
    });
    return { ...publicStatus(credential, recoveryCodes.length), enabled: true, enabledAt, recoveryCodes };
  });
}

async function createLoginChallenge(administrator, rememberMe, request) {
  const { AdminMfaChallenge } = getModels();
  const selector = crypto.randomBytes(16).toString('hex');
  const token = `${selector}.${crypto.randomBytes(32).toString('hex')}`;
  const expiresAt = new Date(Date.now() + challengeMinutes() * 60000);
  await AdminMfaChallenge.sequelize.transaction(async (transaction) => {
    await AdminMfaChallenge.update({ consumedAt: now() }, {
      where: { administratorId: administrator.id, consumedAt: null }, transaction,
    });
    await AdminMfaChallenge.create({
      administratorId: administrator.id, selector, tokenHash: tokenHash(token),
      rememberMe: rememberMe === true, expiresAt, requestedByIp: request.ip || null,
      userAgent: String(request.headers['user-agent'] || '').slice(0, 500) || null,
    }, { transaction });
    await recordAudit({
      request, administratorId: administrator.id, action: 'admin.auth.mfa_challenge_issued',
      targetType: 'administrator', targetId: administrator.id, transaction,
    });
  });
  return { challengeToken: token, expiresAt, methods: ['totp', 'recovery_code'] };
}

function parseChallengeToken(value) {
  const match = /^([a-f0-9]{32})\.([a-f0-9]{64})$/.exec(String(value || ''));
  return match ? { selector: match[1], token: match[0] } : null;
}

async function consumeLoginChallenge(challengeToken, input, request) {
  const parsed = parseChallengeToken(challengeToken);
  if (!parsed) throw serviceError(401, 'MFA_CHALLENGE_INVALID', 'The MFA challenge is invalid or expired.');
  const { AdminMfaChallenge, Administrator } = getModels();
  return AdminMfaChallenge.sequelize.transaction(async (transaction) => {
    const challenge = await AdminMfaChallenge.findOne({
      where: { selector: parsed.selector }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if (!challenge || !safeEqualHex(tokenHash(parsed.token), challenge.tokenHash)
      || challenge.consumedAt || challenge.expiresAt <= now() || challenge.attempts >= 5) {
      throw serviceError(401, 'MFA_CHALLENGE_INVALID', 'The MFA challenge is invalid or expired.');
    }
    try {
      const factor = await verifyFactor(challenge.administratorId, input, { transaction });
      await challenge.update({ consumedAt: now() }, { transaction });
      const administrator = await Administrator.findByPk(challenge.administratorId, {
        transaction, lock: transaction.LOCK.UPDATE,
      });
      if (!administrator || administrator.status !== 'active') {
        throw serviceError(403, 'ACCESS_DENIED', 'Administrator access is unavailable.');
      }
      await recordAudit({
        request, administratorId: administrator.id, action: 'admin.auth.mfa_challenge_succeeded',
        targetType: 'administrator', targetId: administrator.id,
        metadata: { method: factor.method }, transaction,
      });
      return { administrator, rememberMe: challenge.rememberMe, method: factor.method, transaction };
    } catch (error) {
      if (error.code === 'MFA_CODE_INVALID') {
        await challenge.increment('attempts', { by: 1, transaction });
        await recordAudit({
          request, administratorId: challenge.administratorId, action: 'admin.auth.mfa_challenge_failed',
          targetType: 'administrator', targetId: challenge.administratorId, transaction,
        });
      }
      throw error;
    }
  });
}

async function stepUp(administrator, session, input, request) {
  const factor = await verifyFactor(administrator.id, input);
  const verifiedAt = now();
  await session.update({ mfaVerifiedAt: verifiedAt });
  await recordAudit({
    request, administratorId: administrator.id, action: 'admin.auth.mfa_step_up_succeeded',
    targetType: 'administrator', targetId: administrator.id, metadata: { method: factor.method },
  });
  return { verifiedAt, expiresAt: new Date(verifiedAt.getTime() + stepUpMinutes() * 60000) };
}

async function regenerateRecoveryCodes(administrator, request) {
  const { AdminMfaCredential } = getModels();
  return AdminMfaCredential.sequelize.transaction(async (transaction) => {
    const credential = await AdminMfaCredential.findOne({
      where: { administratorId: administrator.id, enabledAt: { [Op.ne]: null }, disabledAt: null },
      transaction, lock: transaction.LOCK.UPDATE,
    });
    if (!credential) throw serviceError(409, 'MFA_NOT_ENABLED', 'Multi-factor authentication is not enabled.');
    const recoveryCodes = await createRecoveryCodes(administrator.id, credential, transaction);
    await recordAudit({
      request, administratorId: administrator.id, action: 'admin.auth.mfa_recovery_codes_regenerated',
      targetType: 'administrator', targetId: administrator.id, transaction,
    });
    return { recoveryCodes };
  });
}

async function disable(administrator, input, request) {
  const { AdminMfaCredential, AdminMfaRecoveryCode, AdminRefreshToken, Administrator } = getModels();
  return Administrator.sequelize.transaction(async (transaction) => {
    await verifyFactor(administrator.id, input, { transaction });
    const credential = await AdminMfaCredential.findOne({
      where: { administratorId: administrator.id }, transaction, lock: transaction.LOCK.UPDATE,
    });
    const disabledAt = now();
    await credential.update({ ...encryptSecret(encodeBase32(crypto.randomBytes(20))), disabledAt }, { transaction });
    await AdminMfaRecoveryCode.destroy({ where: { administratorId: administrator.id }, transaction });
    await AdminRefreshToken.update({ revokedAt: disabledAt, revokedReason: 'mfa_disabled' }, {
      where: { administratorId: administrator.id, revokedAt: null }, transaction,
    });
    await Administrator.increment('tokenVersion', { by: 1, where: { id: administrator.id }, transaction });
    await recordAudit({
      request, administratorId: administrator.id, action: 'admin.auth.mfa_disabled',
      targetType: 'administrator', targetId: administrator.id, transaction,
    });
    return { disabled: true, sessionInvalidated: true, requiresLogin: true };
  });
}

function hasRecentStepUp(session) {
  return Boolean(session?.mfaVerifiedAt
    && new Date(session.mfaVerifiedAt).getTime() >= Date.now() - stepUpMinutes() * 60000);
}

module.exports = {
  beginEnrollment, confirmEnrollment, consumeLoginChallenge, createLoginChallenge,
  disable, hasRecentStepUp, isEnabled, regenerateRecoveryCodes, status, stepUp,
  totpFor, matchingCounter,
};
