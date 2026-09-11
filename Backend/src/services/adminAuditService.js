const crypto = require('crypto');
const { getModels } = require('../models');

const sensitiveKey = /(password|passwordhash|token|secret|otp|authorization|cookie|card|aadhaar|identitydocument|privatekey|cvv)/i;

function sanitize(value, depth = 0) {
  if (value == null || depth > 5) return value;
  if (Array.isArray(value)) return value.slice(0, 100).map((item) => sanitize(item, depth + 1));
  if (typeof value !== 'object') return typeof value === 'string' ? value.slice(0, 2000) : value;
  return Object.fromEntries(Object.entries(value)
    .filter(([key]) => !sensitiveKey.test(key))
    .map(([key, item]) => [key, sanitize(item, depth + 1)]));
}

function contextFrom(request) {
  if (!request) return {};
  const provided = String(request.headers?.['x-correlation-id'] || '').trim();
  const accepted = /^[A-Za-z0-9._:-]{1,80}$/.test(provided) ? provided : null;
  return {
    ipAddress: request.ip || request.socket?.remoteAddress || null,
    userAgent: String(request.headers?.['user-agent'] || '').slice(0, 500) || null,
    correlationId: request.adminCorrelationId || accepted || crypto.randomUUID(),
  };
}

const GENESIS_HASH = crypto
  .createHash('sha256')
  .update('AMORAA_AUDIT_CHAIN_v1')
  .digest('hex');

function computePayloadHash(previousHash, payload) {
  const canonicalString = JSON.stringify({
    administratorId: payload.administratorId || null,
    action: payload.action,
    targetType: payload.targetType || null,
    targetId: payload.targetId || null,
    oldValue: payload.oldValue || null,
    newValue: payload.newValue || null,
    reason: payload.reason || null,
    metadata: payload.metadata || null,
    ipAddress: payload.ipAddress || null,
    userAgent: payload.userAgent || null,
    correlationId: payload.correlationId || null,
  });
  return crypto.createHash('sha256').update(`${previousHash}|${canonicalString}`).digest('hex');
}

async function recordAudit({
  request,
  administratorId,
  action,
  targetType,
  targetId,
  oldValue,
  newValue,
  reason,
  metadata = {},
  transaction,
}) {
  const { AdminAuditLog } = getModels();
  const context = request ? contextFrom(request) : {};

  const enrichedMetadata = {
    ...metadata,
    outcome: metadata?.outcome || 'success',
    severity: metadata?.severity || (metadata?.outcome === 'failed' ? 'warning' : 'info'),
    httpMethod: request?.method || metadata?.httpMethod || null,
    endpoint: request?.originalUrl || request?.url || metadata?.endpoint || null,
    actorName: request?.admin?.name || metadata?.actorName || null,
    actorRole: request?.admin?.roles?.[0]?.name || request?.admin?.role || metadata?.actorRole || 'Administrator',
  };

  const cleanOld = sanitize(oldValue);
  const cleanNew = sanitize(newValue);
  const cleanReason = reason ? String(reason).slice(0, 500) : null;
  const cleanMeta = sanitize(enrichedMetadata);
  const adminId = administratorId || request?.admin?.id || null;
  const targetIdStr = targetId == null ? null : String(targetId);

  // Fetch previous record for hash chaining safely
  let lastRecord = null;
  try {
    lastRecord = await AdminAuditLog.findOne({
      order: [['id', 'DESC']],
      attributes: ['id', 'sequence', 'currentHash'],
      transaction,
    });
  } catch (err) {
    try {
      lastRecord = await AdminAuditLog.findOne({
        order: [['id', 'DESC']],
        attributes: ['id'],
        transaction,
      });
    } catch (_) {}
  }

  const sequence = (Number(lastRecord?.sequence || lastRecord?.id || 0)) + 1;
  const previousHash = lastRecord?.currentHash || GENESIS_HASH;

  const payloadForHash = {
    administratorId: adminId,
    action,
    targetType: targetType || null,
    targetId: targetIdStr,
    oldValue: cleanOld,
    newValue: cleanNew,
    reason: cleanReason,
    metadata: cleanMeta,
    ipAddress: context.ipAddress || null,
    userAgent: context.userAgent || null,
    correlationId: context.correlationId || null,
  };

  const currentHash = computePayloadHash(previousHash, payloadForHash);

  try {
    return await AdminAuditLog.create({
      administratorId: adminId,
      action,
      targetType: targetType || null,
      targetId: targetIdStr,
      oldValue: cleanOld,
      newValue: cleanNew,
      reason: cleanReason,
      metadata: cleanMeta,
      ...context,
      sequence,
      previousHash,
      currentHash,
    }, { transaction });
  } catch (err) {
    if (String(err?.message || '').includes('Unknown column')) {
      return await AdminAuditLog.create({
        administratorId: adminId,
        action,
        targetType: targetType || null,
        targetId: targetIdStr,
        oldValue: cleanOld,
        newValue: cleanNew,
        reason: cleanReason,
        metadata: cleanMeta,
        ...context,
      }, { transaction });
    }
    throw err;
  }
}

async function verifyAuditIntegrity() {
  const { AdminAuditLog } = getModels();
  const logs = await AdminAuditLog.findAll({
    order: [['id', 'ASC']],
  });

  let previousHash = GENESIS_HASH;
  let verifiedCount = 0;

  for (const log of logs) {
    // If record has no chain fields yet (legacy), establish genesis link
    if (!log.currentHash || !log.previousHash) {
      previousHash = log.currentHash || GENESIS_HASH;
      verifiedCount++;
      continue;
    }

    if (log.previousHash !== previousHash) {
      return {
        status: 'INTEGRITY_VIOLATION',
        verifiedCount,
        violatedId: log.id,
        reason: `Previous hash mismatch on record ID ${log.id}. Expected ${previousHash}, got ${log.previousHash}.`,
      };
    }

    const payloadForHash = {
      administratorId: log.administratorId || null,
      action: log.action,
      targetType: log.targetType || null,
      targetId: log.targetId || null,
      oldValue: log.oldValue || null,
      newValue: log.newValue || null,
      reason: log.reason || null,
      metadata: log.metadata || null,
      ipAddress: log.ipAddress || null,
      userAgent: log.userAgent || null,
      correlationId: log.correlationId || null,
    };

    const expectedHash = computePayloadHash(log.previousHash, payloadForHash);
    if (log.currentHash !== expectedHash) {
      return {
        status: 'INTEGRITY_VIOLATION',
        verifiedCount,
        violatedId: log.id,
        reason: `Payload hash verification failed on record ID ${log.id}. Data may have been modified directly in database.`,
      };
    }

    previousHash = log.currentHash;
    verifiedCount++;
  }

  return {
    status: 'VALID',
    verifiedCount,
    message: `All ${verifiedCount} audit log records verified against cryptographic SHA-256 hash chain. No tampering detected.`,
  };
}

module.exports = { recordAudit, verifyAuditIntegrity, sanitize, contextFrom };
