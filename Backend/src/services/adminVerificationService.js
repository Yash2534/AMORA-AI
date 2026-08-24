const crypto = require('crypto');
const fs = require('fs');
const { Op } = require('sequelize');
const { getModels } = require('../models');
const { absolutePathFor } = require('../utils/identityVerificationStorage');

function apiError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

const imageTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);

function mediaId(verificationId, kind) {
  const expiresAt = Math.floor(Date.now() / 1000) + 5 * 60;
  const value = `${verificationId}.${kind}.${expiresAt}`;
  const signature = crypto.createHmac('sha256', process.env.ADMIN_JWT_SECRET).update(value).digest('base64url').slice(0, 32);
  return `${value}.${signature}`;
}

function parseMediaId(value) {
  const match = String(value || '').match(/^(\d+)\.(aadhaar|selfie)\.(\d{10})\.([A-Za-z0-9_-]{32})$/);
  if (!match) return null;
  const expiresAt = Number(match[3]);
  if (expiresAt < Math.floor(Date.now() / 1000)) return null;
  const signedValue = `${match[1]}.${match[2]}.${expiresAt}`;
  const expected = crypto.createHmac('sha256', process.env.ADMIN_JWT_SECRET).update(signedValue).digest('base64url').slice(0, 32);
  const actualBuffer = Buffer.from(match[4]);
  const expectedBuffer = Buffer.from(expected);
  if (actualBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(actualBuffer, expectedBuffer)) return null;
  return { verificationId: Number(match[1]), kind: match[2], expiresAt };
}

const apiStatus = (status) => status === 'verified'
  ? 'approved'
  : status === 'resubmission_requested' ? 'rejected' : status;
const databaseStatuses = (status) => {
  if (status === 'pending') return ['pending', 'under_review'];
  if (status === 'approved') return ['verified'];
  if (status === 'rejected') return ['rejected', 'resubmission_requested'];
  throw apiError(422, 'VALIDATION_ERROR', 'Unsupported verification queue.');
};

function allowedActions(request, row) {
  if (!['pending', 'under_review'].includes(row.status)) return [];
  const granted = request.adminPermissions || new Set();
  return [
    granted.has('verifications.approve') ? 'approve' : null,
    granted.has('verifications.reject') ? 'reject' : null,
    granted.has('verifications.resubmit') ? 'request_resubmission' : null,
  ].filter(Boolean);
}

function summary(request, row) {
  const user = row.user;
  return {
    verificationId: String(row.id),
    userId: String(row.userId),
    profileId: user?.OnboardingProfile ? String(user.OnboardingProfile.id) : null,
    displayName: user?.name || 'Unavailable profile',
    status: apiStatus(row.status),
    documentType: 'aadhaar',
    submittedAt: row.submittedAt,
    updatedAt: row.updatedAt,
    reviewedAt: row.reviewedAt,
    reviewerName: row.reviewer?.name || null,
    reviewVersion: `verification-${row.id}-v${Number(row.reviewVersion || 1)}`,
    allowedActions: allowedActions(request, row),
  };
}

function includeReviewer() {
  const { Administrator } = getModels();
  return { model: Administrator, as: 'reviewer', attributes: ['id', 'name'], required: false };
}

function includeUser(options = {}) {
  const { User, OnboardingProfile } = getModels();
  return {
    model: User,
    as: 'user',
    required: true,
    where: options.userWhere,
    include: [{ model: OnboardingProfile, required: false }],
  };
}

async function listRows(request, page) {
  const { IdentityVerification, User } = getModels();
  if (request.query.documentType && request.query.documentType !== 'aadhaar') {
    throw apiError(422, 'FILTER_NOT_SUPPORTED', 'Only Aadhaar identity submissions exist in the current schema.');
  }
  if (request.query.comparisonStatus) {
    throw apiError(422, 'FILTER_NOT_SUPPORTED', 'Automated comparison data does not exist in the current schema.');
  }
  const where = { status: { [Op.in]: databaseStatuses(request.query.status) } };
  if (request.query.submittedFrom || request.query.submittedTo) {
    where.submittedAt = {};
    if (request.query.submittedFrom) where.submittedAt[Op.gte] = new Date(request.query.submittedFrom);
    if (request.query.submittedTo) where.submittedAt[Op.lte] = new Date(request.query.submittedTo);
  }
  const userWhere = request.query.search
    ? { name: { [Op.like]: `%${String(request.query.search).trim()}%` } }
    : undefined;
  const sortBy = request.query.sortBy || 'submittedAt';
  const direction = String(request.query.sortDirection || 'desc').toUpperCase();
  const order = sortBy === 'displayName'
    ? [[User, 'name', direction], ['id', 'DESC']]
    : [[sortBy, direction], ['id', 'DESC']];
  const result = await IdentityVerification.findAndCountAll({
    where,
    include: [includeUser({ userWhere }), includeReviewer()],
    distinct: true,
    limit: page.pageSize,
    offset: page.offset,
    order,
  });
  return {
    items: result.rows.map((row) => summary(request, row)),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function find(verificationId, options = {}) {
  const { IdentityVerification } = getModels();
  return IdentityVerification.findByPk(verificationId, {
    ...options,
    include: [includeUser(), includeReviewer()],
  });
}

async function storedEvidence(row, kind) {
  const prefix = kind === 'aadhaar' ? 'aadhaar' : 'selfie';
  const storagePath = row[`${prefix}StoragePath`];
  const mimeType = row[`${prefix}MimeType`];
  const sizeBytes = Number(row[`${prefix}SizeBytes`]);
  const absolutePath = absolutePathFor(storagePath);
  if (!absolutePath || !imageTypes.has(mimeType) || !Number.isSafeInteger(sizeBytes) || sizeBytes <= 0) return null;
  const stat = await fs.promises.stat(absolutePath).catch(() => null);
  return stat?.isFile() && stat.size === sizeBytes ? { absolutePath, mimeType, sizeBytes } : null;
}

async function evidenceReady(row) {
  const [aadhaar, selfie] = await Promise.all([storedEvidence(row, 'aadhaar'), storedEvidence(row, 'selfie')]);
  return Boolean(aadhaar && selfie);
}

async function details(request, row) {
  const granted = request.adminPermissions || new Set();
  const evidence = [];
  if (granted.has('verifications.aadhaar.view')) evidence.push({
    mediaId: mediaId(row.id, 'aadhaar'),
    kind: 'aadhaar',
    label: 'Aadhaar submission',
  });
  if (granted.has('verifications.selfie.view')) evidence.push({
    mediaId: mediaId(row.id, 'selfie'),
    kind: 'selfie',
    label: 'Selfie submission',
  });
  return {
    summary: summary(request, row),
    evidence,
    evidenceReadyForDecision: await evidenceReady(row),
  };
}

async function media(value) {
  const parsed = parseMediaId(value);
  if (!parsed) return null;
  const { IdentityVerification } = getModels();
  const row = await IdentityVerification.findByPk(parsed.verificationId);
  if (!row) return null;
  const stored = await storedEvidence(row, parsed.kind);
  return stored ? { ...parsed, ...stored } : null;
}

module.exports = { listRows, find, details, media, parseMediaId, evidenceReady };
