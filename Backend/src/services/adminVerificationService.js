const crypto = require('crypto');
const { Op } = require('sequelize');
const { getModels } = require('../models');
const { absolutePathFor } = require('../utils/identityVerificationStorage');

function apiError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function mediaId(verificationId, kind) {
  const value = `${verificationId}.${kind}`;
  const signature = crypto.createHmac('sha256', process.env.ADMIN_JWT_SECRET).update(value).digest('base64url').slice(0, 32);
  return `${value}.${signature}`;
}

function parseMediaId(value) {
  const match = String(value || '').match(/^(\d+)\.(aadhaar|selfie)\.([A-Za-z0-9_-]{32})$/);
  if (!match) return null;
  const expected = mediaId(match[1], match[2]);
  const actualBuffer = Buffer.from(String(value));
  const expectedBuffer = Buffer.from(expected);
  if (actualBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(actualBuffer, expectedBuffer)) return null;
  return { verificationId: Number(match[1]), kind: match[2] };
}

const apiStatus = (status) => status === 'verified' ? 'approved' : status;
const databaseStatuses = (status) => {
  if (status === 'pending') return ['pending', 'under_review'];
  if (status === 'approved') return ['verified'];
  if (status === 'rejected') return ['rejected'];
  throw apiError(422, 'VALIDATION_ERROR', 'Unsupported verification queue.');
};

function summary(row) {
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
    reviewVersion: row.updatedAt.toISOString(),
    allowedActions: [],
  };
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
    include: [includeUser({ userWhere })],
    distinct: true,
    limit: page.pageSize,
    offset: page.offset,
    order,
  });
  return {
    items: result.rows.map(summary),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function find(verificationId) {
  const { IdentityVerification } = getModels();
  return IdentityVerification.findByPk(verificationId, { include: [includeUser()] });
}

function details(request, row) {
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
    summary: summary(row),
    evidence,
    evidenceReadyForDecision: false,
  };
}

async function media(value) {
  const parsed = parseMediaId(value);
  if (!parsed) return null;
  const { IdentityVerification } = getModels();
  const row = await IdentityVerification.findByPk(parsed.verificationId);
  if (!row) return null;
  const storagePath = parsed.kind === 'aadhaar' ? row.aadhaarStoragePath : row.selfieStoragePath;
  const mimeType = parsed.kind === 'aadhaar' ? row.aadhaarMimeType : row.selfieMimeType;
  const sizeBytes = parsed.kind === 'aadhaar' ? row.aadhaarSizeBytes : row.selfieSizeBytes;
  const absolutePath = absolutePathFor(storagePath);
  return absolutePath ? { ...parsed, absolutePath, mimeType, sizeBytes } : null;
}

module.exports = { listRows, find, details, media, parseMediaId };
