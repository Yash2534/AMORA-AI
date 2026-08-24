const { getModels } = require('../models');
const service = require('../services/adminProfileService');
const { pagination } = require('../admin/query');
const { success, failure } = require('../admin/responses');

const notFound = (req, res) => failure(req, res, 404, 'NOT_FOUND', 'Profile not found.');

exports.list = async (req, res, next) => {
  try {
    return success(req, res, 'Profiles retrieved.', await service.profiles(req, pagination(req.query, { defaultSize: 20 })));
  } catch (error) { return next(error); }
};

exports.details = async (req, res, next) => {
  try {
    const profile = await service.findProfile(req, req.params.profileId);
    return profile ? success(req, res, 'Profile retrieved.', service.details(req, profile)) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.preview = async (req, res, next) => {
  try {
    const profile = await service.findProfile(req, req.params.profileId);
    return profile ? success(req, res, 'Profile preview retrieved.', { profile: service.details(req, profile) }) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.photos = async (req, res, next) => {
  try {
    const profile = await service.findProfile(req, req.params.profileId);
    return profile ? success(req, res, 'Profile photos retrieved.', { items: service.photoRows(req, profile) }) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.update = async (req, res, next) => {
  try {
    const profile = await service.update(req, req.params.profileId, req.body, req.headers['if-match']);
    return profile ? success(req, res, 'Profile updated.', service.details(req, profile)) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.uploadPhoto = async (req, res, next) => {
  try {
    if (!req.file) return failure(req, res, 400, 'VALIDATION_ERROR', 'A profile photo is required.', [{ field: 'file', message: 'A profile photo is required.' }]);
    const profile = await service.uploadPhoto(req, req.params.profileId, req.file);
    return profile ? success(req, res, 'Profile photo uploaded.', { items: service.photoRows(req, profile) }, 201) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.removePhoto = async (req, res, next) => {
  try {
    const profile = await service.removePhoto(req, req.params.profileId, req.params.photoId);
    return profile ? success(req, res, 'Profile photo removed.', { items: service.photoRows(req, profile) }) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.reorderPhotos = async (req, res, next) => {
  try {
    const profile = await service.reorderPhotos(req, req.params.profileId, req.body.photoIds);
    return profile ? success(req, res, 'Profile photos reordered.', { items: service.photoRows(req, profile) }) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.setPrimaryPhoto = async (req, res, next) => {
  try {
    if (req.body.isPrimary !== true) return failure(req, res, 422, 'VALIDATION_ERROR', 'isPrimary must be true.');
    const profile = await service.setPrimaryPhoto(req, req.params.profileId, req.params.photoId);
    return profile ? success(req, res, 'Primary profile photo updated.', { items: service.photoRows(req, profile) }) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.audit = async (req, res, next) => {
  try {
    const profile = await service.findProfile(req, req.params.profileId);
    if (!profile) return notFound(req, res);
    const { AdminAuditLog } = getModels();
    const page = pagination(req.query);
    const result = await AdminAuditLog.findAndCountAll({
      where: { targetType: 'profile', targetId: String(profile.id) },
      attributes: ['id', 'administratorId', 'action', 'oldValue', 'newValue', 'reason', 'correlationId', 'createdAt'],
      limit: page.pageSize,
      offset: page.offset,
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
    });
    const allowed = new Set(['bio', 'city', 'education', 'profession', 'religion', 'iceBreaker', 'communicationStyle']);
    const items = result.rows.map((entry) => {
      const before = entry.oldValue || {};
      const after = entry.newValue || {};
      const fields = [...new Set([...Object.keys(before), ...Object.keys(after)])].filter((key) => allowed.has(key));
      return {
        id: String(entry.id),
        actionType: entry.action,
        occurredAt: entry.createdAt,
        actorReference: entry.administratorId == null ? null : String(entry.administratorId),
        source: 'admin',
        reason: entry.reason,
        requestId: entry.correlationId,
        changes: fields.map((field) => ({ field, before: before[field], after: after[field] })),
      };
    });
    return success(req, res, 'Profile audit history retrieved.', {
      items,
      pagination: {
        page: page.page,
        pageSize: page.pageSize,
        totalItems: result.count,
        totalPages: Math.ceil(result.count / page.pageSize),
      },
    });
  } catch (error) { return next(error); }
};

exports.taxonomy = (req, res) => failure(req, res, 501, 'SCHEMA_NOT_AVAILABLE',
  'Profile taxonomy requires approved option tables and stable option identifiers.');
