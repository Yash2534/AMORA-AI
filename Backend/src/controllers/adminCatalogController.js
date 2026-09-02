const { Op } = require('sequelize');
const { getModels } = require('../models');
const { pagination, sort } = require('../admin/query');

const label = (value) => String(value || 'unknown')
  .replace(/^admin\./, '')
  .replace(/[._-]+/g, ' ')
  .replace(/\b\w/g, (character) => character.toUpperCase());
const code = (value, fallback = 'unknown') => String(value || fallback)
  .replace(/[^A-Za-z0-9._:-]/g, '_')
  .slice(0, 140) || fallback;
const value = (raw, permitted) => permitted
  ? { redactionState: 'visible', value: raw }
  : { redactionState: 'restricted' };

function summary(entry, granted) {
  const raw = entry.toJSON ? entry.toJSON() : entry;
  const action = code(raw.action);
  const module = code(action.replace(/^admin\./, '').split('.')[0]);
  const actor = granted.has('auditLogs.actorDetails.view') && raw.administrator
    ? {
      actorId: String(raw.administrator.id), actorType: { code: 'administrator', label: 'Administrator', known: true },
      displayName: raw.administrator.name, maskedEmail: raw.administrator.email.replace(/^(.).+(@.*)$/, '$1***$2'),
    }
    : { actorType: { code: 'administrator', label: 'Administrator', known: true }, displayName: 'Restricted administrator' };
  return {
    auditId: String(raw.id), occurredAt: raw.createdAt, receivedAt: raw.createdAt,
    module: { code: module, label: label(module), known: true },
    action: { code: action, label: label(action), known: true },
    outcome: { code: 'success', label: 'Success', known: true },
    severity: { code: 'info', label: 'Info', known: true }, actor,
    entity: {
      entityType: { code: code(raw.targetType), label: label(raw.targetType), known: Boolean(raw.targetType) },
      entityId: raw.targetId == null ? null : String(raw.targetId),
      displayReference: raw.targetId == null ? 'No target' : `${label(raw.targetType)} ${raw.targetId}`,
      owningModule: module,
    },
    changedFieldCount: raw.oldValue || raw.newValue ? Object.keys(raw.newValue || raw.oldValue || {}).length : 0,
    correlationId: granted.has('auditLogs.requestContext.view') ? raw.correlationId : null,
    requestId: granted.has('auditLogs.requestContext.view') ? raw.correlationId : null,
    source: 'admin_api', integrityStatus: 'unverified', schemaVersion: 1,
  };
}

function details(entry, granted, include) {
  const raw = entry.toJSON();
  const event = summary(entry, granted);
  const wants = (section) => include.has(section);
  const result = { event, reason: raw.reason || null, partialSections: [] };
  if (wants('changes')) {
    if (granted.has('auditLogs.changes.view')) {
      result.changes = Object.keys(raw.newValue || raw.oldValue || {}).map((path, index) => ({
        path, label: label(path), changeType: 'modified', beforeValue: value(raw.oldValue?.[path], true),
        afterValue: value(raw.newValue?.[path], true), displayOrder: index,
      }));
    } else result.partialSections.push('changes');
  }
  if (wants('requestContext')) {
    if (granted.has('auditLogs.requestContext.view')) result.requestContext = {
      requestId: raw.correlationId, correlationId: raw.correlationId, source: 'admin_api',
      maskedIp: raw.ipAddress ? raw.ipAddress.replace(/(\d+\.\d+\.\d+)\.\d+$/, '$1.*') : null,
      userAgentSummary: raw.userAgent || null,
    };
    else result.partialSections.push('requestContext');
  }
  if (wants('metadata')) {
    if (granted.has('auditLogs.metadata.view')) result.metadata = raw.metadata || null;
    else result.partialSections.push('metadata');
  }
  if (wants('integrity')) result.integrity = { status: 'not_supported' };
  return result;
}

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
    const sortBy = { occurredAt: 'createdAt', module: 'action', entityType: 'targetType' }[req.query.sortBy] || req.query.sortBy;
    const order = sort({ ...req.query, sortBy }, ['createdAt', 'action', 'targetType'], ['createdAt', 'DESC']);
    const granted = req.adminPermissions || new Set();
    const canViewChanges = granted.has('auditLogs.changes.view');
    const canViewMetadata = granted.has('auditLogs.metadata.view');
    const canViewContext = granted.has('auditLogs.requestContext.view');
    const canViewActor = granted.has('auditLogs.actorDetails.view');
    const where = {};
    if (req.query.action) where.action = String(req.query.action).slice(0, 160);
    if (req.query.administratorId) where.administratorId = req.query.administratorId;
    if (req.query.targetType) where.targetType = String(req.query.targetType).slice(0, 80);
    if (req.query.entityType) where.targetType = String(req.query.entityType).slice(0, 80);
    if (req.query.targetId) where.targetId = String(req.query.targetId).slice(0, 191);
    if (req.query.module) where.action = { [Op.like]: `admin.${String(req.query.module).slice(0, 80)}.%` };
    if (req.query.search) where[Op.or] = [
      { action: { [Op.like]: `%${String(req.query.search).slice(0, 160)}%` } },
      { targetId: { [Op.like]: `%${String(req.query.search).slice(0, 160)}%` } },
      { correlationId: { [Op.like]: `%${String(req.query.search).slice(0, 160)}%` } },
    ];
    if (req.query.requestId || req.query.correlationId) where.correlationId = String(req.query.requestId || req.query.correlationId).slice(0, 80);
    if (req.query.ipAddress && canViewContext) where.ipAddress = String(req.query.ipAddress).slice(0, 64);
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
        items: result.rows.map((entry) => summary(entry, granted)),
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

exports.auditMetadata = async (_req, res, next) => {
  try {
    const { AdminAuditLog } = getModels();
    const actions = await AdminAuditLog.findAll({ attributes: ['action'], group: ['action'], order: [['action', 'ASC']], limit: 500 });
    const entityTypes = await AdminAuditLog.findAll({ attributes: ['targetType'], where: { targetType: { [Op.ne]: null } }, group: ['targetType'], order: [['targetType', 'ASC']], limit: 100 });
    const modules = [...new Set(actions.map((item) => code(item.action).replace(/^admin\./, '').split('.')[0]))];
    const option = (item) => ({ code: item, label: label(item) });
    return res.json({ success: true, data: {
      modules: modules.map(option), actions: actions.map((item) => option(item.action)), entityTypes: entityTypes.map((item) => option(item.targetType)),
      actorTypes: [option('administrator')], outcomes: [option('success')], severities: [option('info')], sources: [option('admin_api')],
      integrityStatuses: [option('not_supported')], sortFields: ['occurredAt', 'module', 'action', 'entityType'].map(option), pageSizes: [10, 20, 50, 100],
    } });
  } catch (error) { return next(error); }
};

exports.auditLog = async (req, res, next) => {
  try {
    const { AdminAuditLog, Administrator } = getModels();
    const entry = await AdminAuditLog.findByPk(req.params.auditId, { include: [{ model: Administrator, as: 'administrator', attributes: ['id', 'name', 'email'], required: false }] });
    if (!entry) return res.status(404).json({ success: false, code: 'NOT_FOUND', message: 'Audit event not found.', errors: [] });
    const include = new Set(Array.isArray(req.query.include) ? req.query.include : String(req.query.include || 'summary').split(','));
    return res.json({ success: true, data: details(entry, req.adminPermissions || new Set(), include) });
  } catch (error) { return next(error); }
};
