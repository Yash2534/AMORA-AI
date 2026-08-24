const crypto = require('crypto');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');
const verificationService = require('./adminVerificationService');

const actionableStatuses = new Set(['pending', 'under_review']);
const allowedResubmissionItems = new Set(['aadhaar', 'selfie']);

function serviceError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (!value || typeof value !== 'object') return value;
  return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable(value[key])]));
}

const requestHash = (value) => crypto.createHash('sha256').update(JSON.stringify(stable(value))).digest('hex');
const versionFor = (row) => `verification-${row.id}-v${Number(row.reviewVersion || 1)}`;

function reasonItems(row) {
  let value = row.allowedItems;
  if (typeof value === 'string') {
    try { value = JSON.parse(value); } catch (_) { value = []; }
  }
  return Array.isArray(value)
    ? value.filter((item) => allowedResubmissionItems.has(item))
    : [];
}

async function reasons(action) {
  const { IdentityVerificationReason } = getModels();
  const rows = await IdentityVerificationReason.findAll({
    where: { action, isActive: true },
    order: [['sortOrder', 'ASC'], ['id', 'ASC']],
  });
  return { items: rows.map((row) => ({
    code: row.code,
    label: row.label,
    action: row.action,
    allowsDetail: row.allowsDetail,
    requiresDetail: row.requiresDetail,
    allowedItems: reasonItems(row),
  })) };
}

const apiStatus = (status) => status === 'verified'
  ? 'approved'
  : status === 'resubmission_requested' ? 'rejected' : status;

async function history(verificationId) {
  const { IdentityVerificationDecisionEvent, Administrator } = getModels();
  const rows = await IdentityVerificationDecisionEvent.findAll({
    where: { verificationId },
    include: [{ model: Administrator, as: 'administrator', attributes: ['name'], required: false }],
    order: [['createdAt', 'DESC'], ['id', 'DESC']],
    limit: 100,
  });
  return { items: rows.map((row) => ({
    eventId: String(row.id),
    action: row.action,
    occurredAt: row.createdAt,
    actorName: row.administrator?.name || null,
    reasonLabel: row.reasonLabelSnapshot,
    note: row.internalNote,
    previousStatus: apiStatus(row.fromStatus),
    newStatus: apiStatus(row.toStatus),
    submissionVersion: row.submissionVersion,
  })) };
}

function safeDecisionText(value, field) {
  if (value == null || String(value).trim() === '') return null;
  const text = String(value).trim();
  if (text.length > 500) throw serviceError(422, 'VALIDATION_ERROR', `${field} must not exceed 500 characters.`);
  if (text.includes('@')
    || /(?:^|\s)\+?[\d\s()-]{7,}(?:\s|$)/.test(text)
    || /\d{4}[\s-]?\d{4}[\s-]?\d{4}/.test(text)) {
    throw serviceError(422, 'SENSITIVE_TEXT_NOT_ALLOWED', `${field} must not contain identity or contact data.`);
  }
  return text;
}

function normalizeItems(value) {
  if (value == null) return [];
  if (!Array.isArray(value)) throw serviceError(422, 'VALIDATION_ERROR', 'items must be an array.');
  const items = [...new Set(value.map((item) => String(item).trim()))];
  if (items.some((item) => !allowedResubmissionItems.has(item))) {
    throw serviceError(422, 'VALIDATION_ERROR', 'An unsupported resubmission item was supplied.');
  }
  return items;
}

function validatePreconditions(request, row) {
  const headerVersion = String(request.headers['if-match'] || '').replace(/^W\//, '').replaceAll('"', '').trim();
  const bodyVersion = String(request.body.expectedVersion || '').trim();
  if (!headerVersion || !bodyVersion) {
    throw serviceError(428, 'PRECONDITION_REQUIRED', 'If-Match and expectedVersion are required.');
  }
  if (headerVersion !== bodyVersion || headerVersion !== versionFor(row)) {
    throw serviceError(412, 'VERSION_CONFLICT', 'The verification changed. Refresh and retry.');
  }
}

async function validateReason(action, body, transaction) {
  const detail = safeDecisionText(body.detail, 'Decision detail');
  const note = safeDecisionText(body.note, 'Internal note');
  const items = normalizeItems(body.items);
  if (action === 'approve') {
    if (body.reasonCode != null || detail != null || items.length > 0) {
      throw serviceError(422, 'VALIDATION_ERROR', 'Approval does not accept rejection or resubmission fields.');
    }
    return { reason: null, detail: null, note, items: [] };
  }
  const code = String(body.reasonCode || '').trim();
  if (!code) throw serviceError(422, 'REASON_REQUIRED', 'An approved decision reason is required.');
  const { IdentityVerificationReason } = getModels();
  const reason = await IdentityVerificationReason.findOne({
    where: { code, action, isActive: true },
    transaction,
    lock: transaction.LOCK.SHARE,
  });
  if (!reason) throw serviceError(422, 'REASON_NOT_APPROVED', 'The decision reason is not active for this action.');
  if (reason.requiresDetail && !detail) throw serviceError(422, 'DETAIL_REQUIRED', 'This decision reason requires a detail.');
  if (!reason.allowsDetail && detail) throw serviceError(422, 'DETAIL_NOT_ALLOWED', 'This decision reason does not allow a detail.');
  if (action === 'reject' && items.length) throw serviceError(422, 'VALIDATION_ERROR', 'Rejection does not accept resubmission items.');
  if (action === 'request_resubmission') {
    const allowed = new Set(reasonItems(reason));
    if (!items.length) throw serviceError(422, 'RESUBMISSION_ITEMS_REQUIRED', 'At least one approved resubmission item is required.');
    if (items.some((item) => !allowed.has(item))) {
      throw serviceError(422, 'RESUBMISSION_ITEM_NOT_ALLOWED', 'A resubmission item is not allowed for this reason.');
    }
  }
  return { reason, detail, note, items };
}

const targetStatus = (action) => ({
  approve: 'verified',
  reject: 'rejected',
  request_resubmission: 'resubmission_requested',
})[action];

async function replayFor(key, hash) {
  const { IdentityVerificationDecisionEvent } = getModels();
  const event = await IdentityVerificationDecisionEvent.findOne({ where: { idempotencyKey: key } });
  if (!event) return null;
  if (event.requestHash !== hash) {
    throw serviceError(409, 'IDEMPOTENCY_KEY_REUSED', 'The idempotency key was used for a different request.');
  }
  if (!event.responseSnapshot) {
    throw serviceError(409, 'IDEMPOTENCY_RESPONSE_UNAVAILABLE', 'The original committed response is unavailable.');
  }
  return event.responseSnapshot;
}

async function decide(request, action) {
  if (!['approve', 'reject', 'request_resubmission'].includes(action)) {
    throw serviceError(422, 'VALIDATION_ERROR', 'Unsupported verification decision.');
  }
  const key = String(request.headers['idempotency-key'] || '').trim();
  if (!/^[A-Za-z0-9._:-]{8,160}$/.test(key) || key !== String(request.body.idempotencyKey || '').trim()) {
    throw serviceError(400, 'IDEMPOTENCY_KEY_REQUIRED', 'A matching valid idempotency key is required in the header and body.');
  }
  const hash = requestHash({
    action,
    verificationId: String(request.params.verificationId),
    expectedVersion: request.body.expectedVersion,
    reasonCode: request.body.reasonCode || null,
    detail: request.body.detail || null,
    items: request.body.items || [],
    note: request.body.note || null,
  });
  const replay = await replayFor(key, hash);
  if (replay) return { data: replay, replayed: true };

  const { IdentityVerification, IdentityVerificationDecisionEvent, User } = getModels();
  try {
    const data = await IdentityVerification.sequelize.transaction(async (transaction) => {
      const row = await IdentityVerification.findByPk(request.params.verificationId, {
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!row) throw serviceError(404, 'NOT_FOUND', 'Verification submission not found.');
      validatePreconditions(request, row);
      if (!actionableStatuses.has(row.status)) {
        throw serviceError(409, 'INVALID_STATE_TRANSITION', 'This verification no longer accepts a review decision.');
      }
      if (!(await verificationService.evidenceReady(row))) {
        throw serviceError(409, 'EVIDENCE_NOT_READY', 'Both stored evidence files must be available before a decision.');
      }
      const decision = await validateReason(action, request.body, transaction);
      const user = await User.findByPk(row.userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user) throw serviceError(409, 'USER_NOT_AVAILABLE', 'The verification user is unavailable.');
      const fromStatus = row.status;
      const previousVersion = Number(row.reviewVersion || 1);
      const reviewedAt = new Date();
      const toStatus = targetStatus(action);
      const userFacingReason = decision.reason ? decision.detail || decision.reason.label : null;
      await row.update({
        status: toStatus,
        reviewedAt,
        reviewerAdministratorId: request.admin.id,
        reviewVersion: previousVersion + 1,
        reviewReasonCode: decision.reason?.code || null,
        resubmissionItems: action === 'request_resubmission' ? decision.items : null,
        rejectionReason: userFacingReason,
      }, { transaction });
      await user.update({ identityVerifiedAt: action === 'approve' ? reviewedAt : null }, { transaction });
      const canonicalRow = await verificationService.find(row.id, { transaction });
      const responseSnapshot = await verificationService.details(request, canonicalRow);
      await IdentityVerificationDecisionEvent.create({
        verificationId: row.id,
        administratorId: request.admin.id,
        action,
        fromStatus,
        toStatus,
        reasonId: decision.reason?.id || null,
        reasonCodeSnapshot: decision.reason?.code || null,
        reasonLabelSnapshot: decision.reason?.label || null,
        reasonDetail: decision.detail,
        requiredItems: action === 'request_resubmission' ? decision.items : null,
        internalNote: decision.note,
        submissionVersion: row.submissionVersion,
        idempotencyKey: key,
        requestHash: hash,
        responseSnapshot,
      }, { transaction });
      await recordAudit({
        request,
        administratorId: request.admin.id,
        action: `verification.${action}`,
        targetType: 'verification',
        targetId: row.id,
        oldValue: { status: fromStatus, reviewVersion: previousVersion },
        newValue: {
          status: toStatus,
          reviewVersion: row.reviewVersion,
          submissionVersion: row.submissionVersion,
          reasonCode: decision.reason?.code || null,
          requiredItems: action === 'request_resubmission' ? decision.items : null,
        },
        reason: decision.reason?.code || action,
        transaction,
      });
      return responseSnapshot;
    });
    return { data, replayed: false };
  } catch (error) {
    const racedReplay = await replayFor(key, hash);
    if (racedReplay) return { data: racedReplay, replayed: true };
    throw error;
  }
}

module.exports = { reasons, history, decide };
