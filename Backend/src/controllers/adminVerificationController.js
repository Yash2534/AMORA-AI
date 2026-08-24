const fs = require('fs');
const service = require('../services/adminVerificationService');
const { getModels } = require('../models');
const { pagination } = require('../admin/query');
const { success, failure } = require('../admin/responses');

const notFound = (req, res) => failure(req, res, 404, 'NOT_FOUND', 'Verification submission not found.');
const schemaUnavailable = (req, res) => failure(req, res, 501, 'SCHEMA_NOT_AVAILABLE',
  'Verification decisions require administrator reviewer attribution, decision history, reason taxonomy, versioning, and idempotency persistence.');

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
    return row ? success(req, res, 'Verification details retrieved.', service.details(req, row)) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.history = async (req, res, next) => {
  try {
    const row = await service.find(req.params.verificationId);
    if (!row) return notFound(req, res);
    const { AdminAuditLog, Administrator } = getModels();
    const entries = await AdminAuditLog.findAll({
      where: { targetType: 'verification', targetId: String(row.id) },
      attributes: ['id', 'action', 'administratorId', 'reason', 'createdAt'],
      include: [{ model: Administrator, as: 'administrator', attributes: ['name'], required: false }],
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
      limit: 100,
    });
    return success(req, res, 'Verification history retrieved.', {
      items: entries.map((entry) => ({
        eventId: String(entry.id),
        action: entry.action,
        occurredAt: entry.createdAt,
        actorName: entry.administrator?.name || null,
        reasonLabel: entry.reason,
      })),
    });
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
    return fs.createReadStream(item.absolutePath).on('error', next).pipe(res);
  } catch (error) { return next(error); }
};

exports.reasons = schemaUnavailable;
exports.decide = schemaUnavailable;
