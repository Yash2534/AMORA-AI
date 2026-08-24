const { getModels } = require('../models');
const { storeSubmission, removeStored } = require('../utils/identityVerificationStorage');

const statusJson = (row) => row ? {
  id: String(row.id),
  status: row.status,
  submittedAt: row.submittedAt,
  reviewedAt: row.reviewedAt,
  rejectionReason: ['rejected', 'resubmission_requested'].includes(row.status) ? row.rejectionReason : null,
} : { id: null, status: 'not_started', submittedAt: null, reviewedAt: null, rejectionReason: null };

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
        reviewerAdministratorId: null,
        reviewReasonCode: null,
        resubmissionItems: null,
        rejectionReason: null,
      };
      if (existing) {
        previousPaths = [existing.aadhaarStoragePath, existing.selfieStoragePath];
        row = await existing.update({
          ...values,
          reviewVersion: Number(existing.reviewVersion || 1) + 1,
          submissionVersion: Number(existing.submissionVersion || 1) + 1,
        }, { transaction });
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

exports._test = { statusJson };
