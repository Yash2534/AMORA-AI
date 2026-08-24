const { Op } = require('sequelize');
const { getModels } = require('../models');
const { pagination, sort } = require('../admin/query');

exports.permissions = async (_req, res, next) => {
  try {
    const { AdminPermission } = getModels();
    const items = await AdminPermission.findAll({ order: [['module', 'ASC'], ['key', 'ASC']] });
    return res.json({ success: true, data: { items: items.map((item) => item.toJSON()) } });
  } catch (error) {
    return next(error);
  }
};

exports.roles = async (_req, res, next) => {
  try {
    const { AdminRole, AdminPermission } = getModels();
    const items = await AdminRole.findAll({
      include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
      order: [['name', 'ASC']],
    });
    return res.json({
      success: true,
      data: {
        items: items.map((role) => ({
          id: String(role.id),
          key: role.key,
          name: role.name,
          description: role.description,
          isSystem: role.isSystem,
          isActive: role.isActive,
          permissions: role.permissions.map((permission) => permission.key).sort(),
        })),
      },
    });
  } catch (error) {
    return next(error);
  }
};

exports.auditLogs = async (req, res, next) => {
  try {
    const { AdminAuditLog, Administrator } = getModels();
    const { page, pageSize, offset } = pagination(req.query);
    const order = sort(req.query, ['createdAt', 'action', 'targetType'], ['createdAt', 'DESC']);
    const granted = req.adminPermissions || new Set();
    const canViewChanges = granted.has('auditLogs.changes.view');
    const canViewMetadata = granted.has('auditLogs.metadata.view');
    const canViewContext = granted.has('auditLogs.requestContext.view');
    const canViewActor = granted.has('auditLogs.actorDetails.view');
    const where = {};
    if (req.query.action) where.action = String(req.query.action).slice(0, 160);
    if (req.query.administratorId) where.administratorId = req.query.administratorId;
    if (req.query.targetType) where.targetType = String(req.query.targetType).slice(0, 80);
    if (req.query.from || req.query.to) {
      where.createdAt = {};
      if (req.query.from) where.createdAt[Op.gte] = new Date(req.query.from);
      if (req.query.to) where.createdAt[Op.lte] = new Date(req.query.to);
    }
    const result = await AdminAuditLog.findAndCountAll({
      where,
      attributes: [
        'id', 'administratorId', 'action', 'targetType', 'targetId', 'reason', 'createdAt',
        ...(canViewChanges ? ['oldValue', 'newValue'] : []),
        ...(canViewMetadata ? ['metadata'] : []),
        ...(canViewContext ? ['ipAddress', 'userAgent', 'correlationId'] : []),
      ],
      limit: pageSize,
      offset,
      order: [order, ['id', 'DESC']],
      include: canViewActor
        ? [{ model: Administrator, as: 'administrator', attributes: ['id', 'name', 'email'], required: false }]
        : [],
    });
    return res.json({
      success: true,
      data: {
        items: result.rows.map((entry) => ({
          ...entry.toJSON(),
          id: String(entry.id),
          administratorId: entry.administratorId == null ? null : String(entry.administratorId),
        })),
        pagination: {
          page,
          pageSize,
          totalItems: result.count,
          totalPages: Math.ceil(result.count / pageSize),
        },
      },
    });
  } catch (error) {
    return next(error);
  }
};
