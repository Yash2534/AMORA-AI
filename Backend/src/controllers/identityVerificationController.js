const fs = require('fs');
const { getModels } = require('../models');
const { storeSubmission, removeStored, absolutePathFor } = require('../utils/identityVerificationStorage');
const { createNotification } = require('../services/notificationService');

const statusJson = (row) => row ? {
  id: String(row.id),
  status: row.status,
  submittedAt: row.submittedAt,
  reviewedAt: row.reviewedAt,
  rejectionReason: row.status === 'rejected' ? row.rejectionReason : null,
} : { id: null, status: 'not_started', submittedAt: null, reviewedAt: null, rejectionReason: null };

const requireAdmin = (req, res) => {
  if (req.authUser?.role === 'admin') return true;
  res.status(403).json({ success: false, message: 'Administrator access is required.', code: 'FORBIDDEN', errors: [] });
  return false;
};

exports.me = async (req, res, next) => {
  try {
    const row = await getModels().IdentityVerification.findOne({ where: { userId: req.user.sub } });
    return res.json({ success: true, message: 'Identity verification status retrieved.', data: { verification: statusJson(row) } });
  } catch (error) { return next(error); }
};

exports.submit = async (req, res, next) => {
  let stored;
  let previousPaths = [];
  try {
    const aadhaar = req.files?.aadhaar?.[0];
    const selfie = req.files?.selfie?.[0];
    if (!aadhaar || !selfie) {
      return res.status(400).json({ success: false, message: 'Both Aadhaar and selfie images are required.', code: 'VALIDATION_ERROR', errors: [
        ...(!aadhaar ? [{ field: 'aadhaar', message: 'Aadhaar image is required.' }] : []),
        ...(!selfie ? [{ field: 'selfie', message: 'Selfie image is required.' }] : []),
      ] });
    }
    stored = await storeSubmission(req.user.sub, aadhaar, selfie);
    const { IdentityVerification, User } = getModels();
    let row;
    await IdentityVerification.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(req.user.sub, { transaction, lock: transaction.LOCK.UPDATE });
      const existing = await IdentityVerification.findOne({ where: { userId: req.user.sub }, transaction, lock: transaction.LOCK.UPDATE });
      if (existing && ['pending', 'under_review', 'verified'].includes(existing.status)) {
        const error = new Error(existing.status === 'verified' ? 'Identity is already verified.' : 'An identity verification is already awaiting review.');
        error.status = 409;
        error.code = existing.status === 'verified' ? 'IDENTITY_ALREADY_VERIFIED' : 'IDENTITY_REVIEW_PENDING';
        throw error;
      }
      const values = {
        userId: req.user.sub,
        status: 'pending',
        aadhaarStoragePath: stored.aadhaar.storagePath,
        aadhaarMimeType: stored.aadhaar.mimeType,
        aadhaarSizeBytes: stored.aadhaar.sizeBytes,
        selfieStoragePath: stored.selfie.storagePath,
        selfieMimeType: stored.selfie.mimeType,
        selfieSizeBytes: stored.selfie.sizeBytes,
        submittedAt: new Date(),
        reviewedAt: null,
        reviewerUserId: null,
        reviewNote: null,
        rejectionReason: null,
      };
      if (existing) {
        previousPaths = [existing.aadhaarStoragePath, existing.selfieStoragePath];
        row = await existing.update(values, { transaction });
      } else {
        row = await IdentityVerification.create(values, { transaction });
      }
      if (user.identityVerifiedAt) await user.update({ identityVerifiedAt: null }, { transaction });
    });
    await Promise.all(previousPaths.map(removeStored));
    return res.status(202).json({ success: true, message: 'Identity verification submitted for review.', data: { verification: statusJson(row) } });
  } catch (error) {
    if (stored) await Promise.all([removeStored(stored.aadhaar.storagePath), removeStored(stored.selfie.storagePath)]);
    if (error.code === 'INVALID_VERIFICATION_MEDIA') {
      return res.status(400).json({ success: false, message: error.message, code: error.code, errors: [] });
    }
    return next(error);
  }
};

exports.reviewQueue = async (req, res, next) => {
  if (!requireAdmin(req, res)) return;
  try {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const where = req.query.status ? { status: req.query.status } : { status: ['pending', 'under_review'] };
    const { rows, count } = await getModels().IdentityVerification.findAndCountAll({
      where,
      order: [['submittedAt', 'ASC'], ['id', 'ASC']],
      offset: (page - 1) * limit,
      limit,
    });
    return res.json({ success: true, message: 'Identity verification review queue retrieved.', data: {
      verifications: rows.map(statusJson),
      pagination: { page, limit, total: count, hasMore: page * limit < count },
    } });
  } catch (error) { return next(error); }
};

exports.document = async (req, res, next) => {
  if (!requireAdmin(req, res)) return;
  try {
    const row = await getModels().IdentityVerification.findByPk(req.params.verificationId);
    if (!row) return res.status(404).json({ success: false, message: 'Identity verification is not available.', code: 'IDENTITY_VERIFICATION_NOT_FOUND', errors: [] });
    const kind = req.params.kind;
    const storagePath = kind === 'aadhaar' ? row.aadhaarStoragePath : row.selfieStoragePath;
    const mimeType = kind === 'aadhaar' ? row.aadhaarMimeType : row.selfieMimeType;
    const absolute = absolutePathFor(storagePath);
    if (!absolute || !fs.existsSync(absolute)) return res.status(404).json({ success: false, message: 'Verification document is unavailable.', code: 'VERIFICATION_DOCUMENT_NOT_FOUND', errors: [] });
    res.type(mimeType);
    res.set('Cache-Control', 'private, no-store');
    return res.sendFile(absolute);
  } catch (error) { return next(error); }
};

exports.review = async (req, res, next) => {
  if (!requireAdmin(req, res)) return;
  try {
    const { IdentityVerification, User } = getModels();
    let row;
    await IdentityVerification.sequelize.transaction(async (transaction) => {
      row = await IdentityVerification.findByPk(req.params.verificationId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!row) {
        const error = new Error('Identity verification is not available.');
        error.status = 404;
        error.code = 'IDENTITY_VERIFICATION_NOT_FOUND';
        throw error;
      }
      if (!['pending', 'under_review'].includes(row.status)) {
        const error = new Error('This identity verification has already been finalized.');
        error.status = 409;
        error.code = 'IDENTITY_REVIEW_FINALIZED';
        throw error;
      }
      const status = req.body.status;
      const now = new Date();
      await row.update({
        status,
        reviewerUserId: req.user.sub,
        reviewNote: req.body.reviewNote?.trim() || null,
        rejectionReason: status === 'rejected' ? req.body.rejectionReason.trim() : null,
        reviewedAt: status === 'under_review' ? null : now,
      }, { transaction });
      if (status !== 'under_review') {
        await User.update({ identityVerifiedAt: status === 'verified' ? now : null }, { where: { id: row.userId }, transaction });
      }
    });
    if (row.status !== 'under_review') {
      await createNotification({
        userId: Number(row.userId),
        type: row.status === 'verified' ? 'identity_verified' : 'identity_rejected',
        category: 'verification',
        title: row.status === 'verified' ? 'Identity verified' : 'Identity review update',
        message: row.status === 'verified' ? 'Your verified trust signal is now active.' : 'Your identity submission needs new images. Open verification to review the reason.',
        data: { verificationId: String(row.id), status: row.status },
        dedupeKey: `identity:${row.id}:${row.status}`,
      });
    }
    return res.json({ success: true, message: `Identity verification marked ${row.status.replace('_', ' ')}.`, data: { verification: statusJson(row) } });
  } catch (error) { return next(error); }
};

exports._test = { statusJson };
