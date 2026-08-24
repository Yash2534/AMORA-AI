const fs = require('fs');
const service = require('../services/adminVerificationService');
const decisionService = require('../services/adminVerificationDecisionService');
const { pagination } = require('../admin/query');
const { success, failure } = require('../admin/responses');

const notFound = (req, res) => failure(req, res, 404, 'NOT_FOUND', 'Verification submission not found.');
exports.list = async (req, res, next) => {
  try {
    const queuePermission = {
      pending: 'verifications.pending.view',
      approved: 'verifications.approved.view',
      rejected: 'verifications.rejected.view',
    }[req.query.status];
    if (!queuePermission || !req.adminPermissions.has(queuePermission)) {
      return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to view this verification queue.');
    }
    return success(req, res, 'Verification submissions retrieved.', await service.listRows(req, pagination(req.query, { defaultSize: 20 })));
  } catch (error) { return next(error); }
};

exports.details = async (req, res, next) => {
  try {
    const row = await service.find(req.params.verificationId);
    return row ? success(req, res, 'Verification details retrieved.', await service.details(req, row)) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.history = async (req, res, next) => {
  try {
    const row = await service.find(req.params.verificationId);
    if (!row) return notFound(req, res);
    return success(req, res, 'Verification history retrieved.', await decisionService.history(row.id));
  } catch (error) { return next(error); }
};

exports.media = async (req, res, next) => {
  try {
    const item = await service.media(req.params.mediaId);
    if (!item) return notFound(req, res);
    const permission = item.kind === 'aadhaar' ? 'verifications.aadhaar.view' : 'verifications.selfie.view';
    if (!req.adminPermissions.has(permission)) {
      return failure(req, res, 403, 'ACCESS_DENIED', 'You do not have permission to view this verification evidence.');
    }
    const stat = await fs.promises.stat(item.absolutePath).catch(() => null);
    if (!stat?.isFile() || stat.size !== Number(item.sizeBytes)) return notFound(req, res);
    res.setHeader('Content-Type', item.mimeType);
    res.setHeader('Content-Length', stat.size);
    res.setHeader('Cache-Control', 'no-store, private, max-age=0');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Disposition', 'inline');
    await req.recordAdminAudit({
      action: 'verification.evidence.viewed',
      targetType: 'verification',
      targetId: item.verificationId,
      newValue: { evidenceKind: item.kind },
      reason: 'authorized_review',
    });
    return fs.createReadStream(item.absolutePath).on('error', next).pipe(res);
  } catch (error) { return next(error); }
};

exports.reasons = async (req, res, next) => {
  try {
    return success(req, res, 'Verification decision reasons retrieved.', await decisionService.reasons(req.query.action));
  } catch (error) { return next(error); }
};

const decide = (action) => async (req, res, next) => {
  try {
    const result = await decisionService.decide(req, action);
    if (result.replayed) res.setHeader('Idempotency-Replayed', 'true');
    return success(req, res, 'Verification decision committed.', result.data);
  } catch (error) { return next(error); }
};

exports.approve = decide('approve');
exports.reject = decide('reject');
exports.requestResubmission = decide('request_resubmission');
