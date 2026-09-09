const { getModels } = require('../models');
const { PrivacyRequestService, safeRequest } = require('../services/privacyRequestService');

const forbiddenFields = new Set(['userId', 'status', 'requestedAt', 'identityVerifiedAt', 'processingStartedAt', 'completedAt', 'failedAt', 'failureCode', 'assignedAdminId', 'correlationId', 'metadata']);
const hasForbiddenFields = (body) => Object.keys(body || {}).some((key) => forbiddenFields.has(key));

exports.create = async (req, res, next) => {
  try {
    if (hasForbiddenFields(req.body)) return res.status(400).json({ success: false, message: 'Privacy request contains server-controlled fields.', code: 'PRIVACY_REQUEST_FIELDS_FORBIDDEN', errors: [] });
    const result = await new PrivacyRequestService().create({ userId: Number(req.user.sub), requestType: req.body.requestType });
    if (result.duplicate) return res.status(409).json({ success: false, message: 'An active privacy request of this type already exists.', code: 'PRIVACY_REQUEST_ALREADY_ACTIVE', errors: [], data: { request: safeRequest(result.request) } });
    return res.status(201).json({ success: true, message: 'Privacy request recorded. Identity verification is required before processing.', data: { request: safeRequest(result.request) } });
  } catch (error) { return next(error); }
};

exports.listMine = async (req, res, next) => {
  try {
    const rows = await getModels().PrivacyRequest.findAll({ where: { userId: Number(req.user.sub) }, order: [['requestedAt', 'DESC'], ['id', 'DESC']] });
    return res.json({ success: true, message: 'Privacy requests retrieved.', data: { requests: rows.map(safeRequest) } });
  } catch (error) { return next(error); }
};

exports.getMine = async (req, res, next) => {
  try {
    const row = await getModels().PrivacyRequest.findOne({ where: { id: req.params.id, userId: Number(req.user.sub) } });
    if (!row) return res.status(404).json({ success: false, message: 'Privacy request not found.', code: 'NOT_FOUND', errors: [] });
    return res.json({ success: true, message: 'Privacy request retrieved.', data: { request: safeRequest(row) } });
  } catch (error) { return next(error); }
};
