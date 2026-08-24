const crypto = require('crypto');
const { getModels } = require('../models');

const sensitiveKey = /(password|token|secret|otp|authorization|cookie|card|aadhaar|identitydocument)/i;

function sanitize(value, depth = 0) {
  if (value == null || depth > 5) return value;
  if (Array.isArray(value)) return value.slice(0, 100).map((item) => sanitize(item, depth + 1));
  if (typeof value !== 'object') return typeof value === 'string' ? value.slice(0, 2000) : value;
  return Object.fromEntries(Object.entries(value)
    .filter(([key]) => !sensitiveKey.test(key))
    .map(([key, item]) => [key, sanitize(item, depth + 1)]));
}

function contextFrom(request) {
  const provided = String(request.headers['x-correlation-id'] || '').trim();
  const accepted = /^[A-Za-z0-9._:-]{1,80}$/.test(provided) ? provided : null;
  return {
    ipAddress: request.ip || request.socket?.remoteAddress || null,
    userAgent: String(request.headers['user-agent'] || '').slice(0, 500) || null,
    correlationId: request.adminCorrelationId || accepted || crypto.randomUUID(),
  };
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
  metadata,
  transaction,
}) {
  const { AdminAuditLog } = getModels();
  const context = request ? contextFrom(request) : {};
  return AdminAuditLog.create({
    administratorId: administratorId || null,
    action,
    targetType: targetType || null,
    targetId: targetId == null ? null : String(targetId),
    oldValue: sanitize(oldValue),
    newValue: sanitize(newValue),
    reason: reason ? String(reason).slice(0, 500) : null,
    metadata: sanitize(metadata),
    ...context,
  }, { transaction });
}

module.exports = { recordAudit, sanitize, contextFrom };
