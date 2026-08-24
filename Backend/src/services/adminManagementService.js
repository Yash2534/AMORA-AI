const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { Op } = require('sequelize');
const { getModels } = require('../models');
const { pagination, sort } = require('../admin/query');
const { recordAudit } = require('./adminAuditService');
const { sendAdminInvitation } = require('./adminInvitationMailer');

const now = () => new Date();
const tokenHash = (value) => crypto.createHash('sha256').update(value).digest('hex');
const normalizeEmail = (value) => String(value || '').trim().toLowerCase();
const activeSessionWhere = () => ({ revokedAt: null, expiresAt: { [Op.gt]: now() } });

function serviceError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function codeValue(code, labels) {
  return { code, label: labels[code] || String(code).replaceAll('_', ' '), known: Object.hasOwn(labels, code) };
}

function statusValue(code) {
  return codeValue(code, { active: 'Active', suspended: 'Suspended', disabled: 'Disabled' });
}

function invitationValue(code) {
  return codeValue(code, {
    not_required: 'Not required', pending: 'Pending', accepted: 'Accepted',
    expired: 'Expired', revoked: 'Revoked',
  });
}

function riskFor(key) {
  if (/^(administrators|roles|permissions)\./.test(key) || /sensitive|delete|refunds\.create/i.test(key)) return 'critical';
  if (/\.(manage|suspend|resolve|publish|launch|cancel|escalate|retry|create|update)$/i.test(key)) return 'high';
  if (/\.details\.|\.content\.|\.metadata\./i.test(key)) return 'medium';
  return 'low';
}

function roleRisk(role) {
  const risks = (role.permissions || []).map((permission) => riskFor(permission.key));
  if (risks.includes('critical')) return 'critical';
  if (risks.includes('high')) return 'high';
  if (risks.includes('medium')) return 'medium';
  return 'low';
}

function versionFor(prefix, value) {
  return `${prefix}-${Number(value || 1)}`;
}

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (!value || typeof value !== 'object') return value;
  return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable(value[key])]));
}

function requestHash(value) {
  return tokenHash(JSON.stringify(stable(value)));
}

function storedResponse(value) {
  if (typeof value !== 'string') return value;
  try { return JSON.parse(value); } catch (_) { return {}; }
}

async function idempotent(req, scope, body, work) {
  const key = String(req.headers['idempotency-key'] || '').trim();
  if (!/^[A-Za-z0-9._:-]{8,160}$/.test(key)) {
    throw serviceError(400, 'IDEMPOTENCY_KEY_REQUIRED', 'A valid Idempotency-Key header is required.');
  }
  const { AdminIdempotencyKey, Administrator } = getModels();
  const hash = requestHash({ body, ifMatch: req.headers['if-match'] || null });
  const existing = await AdminIdempotencyKey.findOne({
    where: { administratorId: req.admin.id, scope, idempotencyKey: key },
  });
  if (existing) {
    if (existing.requestHash !== hash) throw serviceError(409, 'IDEMPOTENCY_KEY_REUSED', 'The idempotency key was already used for a different request.');
    return { ...storedResponse(existing.responseBody), replayed: true };
  }
  try {
    return await Administrator.sequelize.transaction(async (transaction) => {
      const responseBody = await work(transaction);
      await AdminIdempotencyKey.create({
        administratorId: req.admin.id,
        scope,
        idempotencyKey: key,
        requestHash: hash,
        responseStatus: 200,
        responseBody,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      }, { transaction });
      return responseBody;
    });
  } catch (error) {
    if (error.name !== 'SequelizeUniqueConstraintError') throw error;
    const raced = await AdminIdempotencyKey.findOne({
      where: { administratorId: req.admin.id, scope, idempotencyKey: key },
    });
    if (!raced || raced.requestHash !== hash) throw serviceError(409, 'IDEMPOTENCY_KEY_REUSED', 'The idempotency key is unavailable.');
    return { ...storedResponse(raced.responseBody), replayed: true };
  }
}

function requireVersion(req, expected) {
  const value = String(req.headers['if-match'] || '').replace(/^W\//, '').replaceAll('"', '').trim();
  if (!value) throw serviceError(428, 'PRECONDITION_REQUIRED', 'If-Match is required.');
  if (value !== expected) throw serviceError(412, 'VERSION_CONFLICT', 'The resource changed. Refresh and retry.');
}

async function administratorWithRoles(id, options = {}) {
  const { Administrator, AdminRole, AdminPermission } = getModels();
  return Administrator.findByPk(id, {
    ...options,
    include: [{
      model: AdminRole, as: 'roles', through: { attributes: [] }, required: false,
      include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
    }],
  });
}

function rolePermissionKeys(role) {
  return new Set((role.permissions || []).map((permission) => permission.key));
}

function actorIsSuper(req) {
  return (req.admin.roles || []).some((role) => role.key === 'super_admin');
}

async function activeSuperAdminCount(transaction) {
  const { Administrator, AdminRole } = getModels();
  return Administrator.count({
    where: { status: 'active' },
    include: [{ model: AdminRole, as: 'roles', where: { key: 'super_admin', isActive: true }, through: { attributes: [] } }],
    distinct: true,
    transaction,
  });
}

async function isLastActiveSuper(administrator, transaction) {
  if (administrator.status !== 'active' || !(administrator.roles || []).some((role) => role.key === 'super_admin')) return false;
  return (await activeSuperAdminCount(transaction)) <= 1;
}

function allowedAdministratorActions(req, administrator, lastSuper) {
  const granted = req.adminPermissions || new Set();
  const self = String(req.admin.id) === String(administrator.id);
  const actions = [];
  if (!self && granted.has('administrators.assignRoles') && granted.has('roles.assign')) actions.push('assignRoles');
  if (!self && administrator.status === 'active' && !lastSuper && granted.has('administrators.suspend')) actions.push('suspend');
  if (!self && administrator.status === 'suspended' && granted.has('administrators.reactivate')) actions.push('reactivate');
  if (!self && granted.has('administrators.sessions.revoke')) actions.push('revokeSessions');
  return actions;
}

async function serializeAdministrator(req, administrator, options = {}) {
  const { AdminRefreshToken } = getModels();
  const lastSuper = options.lastSuper ?? await isLastActiveSuper(administrator, options.transaction);
  const roles = (administrator.roles || []).map((role) => ({
    roleId: String(role.id), roleKey: role.key, name: role.name,
    riskLevel: roleRisk(role), protected: role.isSystem === true,
  }));
  const activeSessionCount = options.includeSessionCount === false ? undefined : await AdminRefreshToken.count({
    where: { administratorId: administrator.id, ...activeSessionWhere() },
    transaction: options.transaction,
  });
  return {
    adminId: String(administrator.id),
    name: administrator.name,
    email: administrator.email,
    roles,
    status: statusValue(administrator.status),
    invitationStatus: invitationValue(administrator.invitationStatus || 'not_required'),
    mfaStatus: codeValue('not_available', { not_available: 'Not available' }),
    version: versionFor('admin', administrator.version),
    allowedActions: allowedAdministratorActions(req, administrator, lastSuper),
    activeSessionCount,
    lastLoginAt: administrator.lastLoginAt,
    createdAt: administrator.createdAt,
    isProtected: false,
    isLastActiveSuperAdmin: lastSuper,
  };
}

function serializePermission(permission, req, order = 0) {
  const riskLevel = riskFor(permission.key);
  const delegable = (req.adminPermissions || new Set()).has(permission.key);
  return {
    permissionId: String(permission.id),
    permissionKey: permission.key,
    label: permission.name,
    description: permission.description,
    module: permission.module,
    group: permission.key.split('.')[1] || 'general',
    riskLevel,
    delegable,
    systemOnly: false,
    deprecated: false,
    dependencies: [],
    conflicts: [],
    displayOrder: order,
    allowedActions: delegable ? ['assign'] : [],
  };
}

async function serializeRole(req, role, options = {}) {
  const { Administrator } = getModels();
  const permissions = role.permissions || [];
  const administratorCount = options.includeCounts === false ? undefined : await Administrator.count({
    include: [{ model: role.sequelize.models.AdminRole, as: 'roles', where: { id: role.id }, through: { attributes: [] } }],
    distinct: true,
    transaction: options.transaction,
  });
  const protectedRole = role.isSystem === true;
  const assignable = role.isActive === true
    && (!protectedRole || actorIsSuper(req))
    && permissions.every((permission) => (req.adminPermissions || new Set()).has(permission.key));
  return {
    roleId: String(role.id), roleKey: role.key, name: role.name,
    description: role.description || '',
    type: codeValue(protectedRole ? 'system' : 'custom', { system: 'System', custom: 'Custom' }),
    status: codeValue(role.isActive ? 'active' : 'inactive', { active: 'Active', inactive: 'Inactive' }),
    riskLevel: roleRisk(role),
    administratorCount,
    permissionCount: permissions.length,
    highRiskPermissionCount: permissions.filter((permission) => ['high', 'critical'].includes(riskFor(permission.key))).length,
    createdAt: role.createdAt,
    updatedAt: role.updatedAt,
    version: versionFor('role', role.version),
    allowedActions: protectedRole ? [] : ['update', 'permissions'],
    protected: protectedRole,
    assignable,
  };
}

async function configuration() {
  return {
    roleAssignmentMode: 'multipleRoles', minimumRoleCount: 1, maximumRoleCount: 10,
    statuses: ['active', 'suspended', 'disabled'].map((code) => statusValue(code)),
    invitationStatuses: ['pending', 'accepted', 'expired', 'revoked'].map((code) => invitationValue(code)),
    mfaStatuses: [codeValue('not_available', { not_available: 'Not available' })],
    roleTypes: [codeValue('system', { system: 'System' }), codeValue('custom', { custom: 'Custom' })],
    roleStatuses: [codeValue('active', { active: 'Active' }), codeValue('inactive', { inactive: 'Inactive' })],
    suspensionReasons: [
      { code: 'security_incident', label: 'Security incident' },
      { code: 'policy_violation', label: 'Policy violation' },
      { code: 'access_review', label: 'Access review' },
      { code: 'employment_change', label: 'Employment change' },
    ],
    locales: [{ code: 'en-IN', label: 'English (India)' }],
    timezones: [{ code: 'Asia/Kolkata', label: 'Asia/Kolkata' }],
    supportsRolePreview: true,
    supportsPermissionPreview: true,
    supportsInvitationMessage: true,
    mfaAvailable: false,
  };
}

async function listAdministrators(req) {
  const { Administrator, AdminRole, AdminPermission } = getModels();
  const { page, pageSize, offset } = pagination(req.query, { defaultSize: 20 });
  const order = sort(req.query, ['createdAt', 'lastLoginAt', 'name', 'status'], ['createdAt', 'DESC']);
  const where = {};
  if (req.query.status) where.status = req.query.status;
  if (req.query.invitationStatus) where.invitationStatus = req.query.invitationStatus;
  if (req.query.search) {
    const search = String(req.query.search).slice(0, 160);
    where[Op.or] = [{ name: { [Op.like]: `%${search}%` } }, { email: { [Op.like]: `%${search}%` } }];
  }
  const roleWhere = req.query.roleId ? { id: req.query.roleId } : undefined;
  const result = await Administrator.findAndCountAll({
    where,
    include: [{
      model: AdminRole, as: 'roles', where: roleWhere, required: Boolean(roleWhere), through: { attributes: [] },
      include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
    }],
    distinct: true, limit: pageSize, offset, order: [order, ['id', 'DESC']],
  });
  return {
    items: await Promise.all(result.rows.map((administrator) => serializeAdministrator(req, administrator))),
    pagination: { page, pageSize, totalItems: result.count, totalPages: Math.ceil(result.count / pageSize) },
  };
}

async function getAdministrator(req, id) {
  const administrator = await administratorWithRoles(id);
  if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
  const { AdminRefreshToken, Administrator } = getModels();
  const [serialized, creator, sessions] = await Promise.all([
    serializeAdministrator(req, administrator),
    administrator.createdByAdministratorId ? Administrator.findByPk(administrator.createdByAdministratorId, { attributes: ['name'] }) : null,
    (req.adminPermissions || new Set()).has('administrators.sessions.view')
      ? AdminRefreshToken.findAll({ where: { administratorId: id }, order: [['createdAt', 'DESC']], limit: 50 })
      : [],
  ]);
  const permissionMap = new Map();
  for (const role of administrator.roles || []) for (const permission of role.permissions || []) {
    if (!permissionMap.has(permission.key)) permissionMap.set(permission.key, {
      permissionKey: permission.key, label: permission.name,
      source: role.name, riskLevel: riskFor(permission.key),
    });
  }
  return {
    administrator: serialized,
    effectivePermissions: [...permissionMap.values()].sort((a, b) => a.permissionKey.localeCompare(b.permissionKey)),
    sessions: sessions.map((session) => ({
      sessionId: String(session.id),
      status: codeValue(session.revokedAt ? 'revoked' : session.expiresAt <= now() ? 'expired' : 'active', {
        active: 'Active', revoked: 'Revoked', expired: 'Expired',
      }),
      createdAt: session.createdAt,
      lastSeenAt: session.lastUsedAt,
      deviceLabel: session.userAgent ? String(session.userAgent).slice(0, 160) : null,
      locationLabel: null,
    })),
    createdByLabel: creator?.name || null,
    activatedAt: administrator.activatedAt,
    lastActivityAt: administrator.lastActiveAt,
    suspensionReasonLabel: administrator.suspensionReasonCode || null,
  };
}

async function administratorAudit(req, id) {
  const { AdminAuditLog, Administrator } = getModels();
  const exists = await Administrator.findByPk(id, { attributes: ['id'] });
  if (!exists) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
  const items = await AdminAuditLog.findAll({
    where: { targetType: 'administrator', targetId: String(id) },
    include: [{ model: Administrator, as: 'administrator', attributes: ['name'], required: false }],
    order: [['createdAt', 'DESC'], ['id', 'DESC']], limit: 100,
  });
  return { items: items.map((entry) => ({
    auditEventId: String(entry.id), eventType: entry.action,
    summary: entry.reason || entry.action.replaceAll('.', ' '),
    actorLabel: entry.administrator?.name || 'System', occurredAt: entry.createdAt,
  })) };
}

async function roles(req) {
  const { AdminRole, AdminPermission } = getModels();
  const { page, pageSize, offset } = pagination(req.query, { defaultSize: 20 });
  const aggregateSort = ['administratorCount', 'permissionCount'].includes(req.query.sortBy);
  const order = aggregateSort
    ? ['updatedAt', 'DESC']
    : sort(req.query, ['updatedAt', 'name'], ['updatedAt', 'DESC']);
  const where = {};
  if (req.query.search) where[Op.or] = [
    { name: { [Op.like]: `%${String(req.query.search).slice(0, 160)}%` } },
    { key: { [Op.like]: `%${String(req.query.search).slice(0, 80)}%` } },
  ];
  if (req.query.type === 'system') where.isSystem = true;
  if (req.query.type === 'custom') where.isSystem = false;
  if (req.query.status === 'active') where.isActive = true;
  if (req.query.status === 'inactive') where.isActive = false;
  const result = await AdminRole.findAndCountAll({
    where,
    include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
    distinct: true,
    ...(!aggregateSort ? { limit: pageSize, offset } : {}),
    order: [order, ['id', 'DESC']],
  });
  let items = await Promise.all(result.rows.map((role) => serializeRole(req, role)));
  if (aggregateSort) {
    const direction = String(req.query.sortDirection || 'desc') === 'asc' ? 1 : -1;
    const field = req.query.sortBy;
    items.sort((left, right) => direction * (Number(left[field] || 0) - Number(right[field] || 0)));
    items = items.slice(offset, offset + pageSize);
  }
  return {
    items,
    pagination: { page, pageSize, totalItems: result.count, totalPages: Math.ceil(result.count / pageSize) },
  };
}

async function role(req, id) {
  const { AdminRole, AdminPermission } = getModels();
  const value = await AdminRole.findByPk(id, { include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }] });
  if (!value) throw serviceError(404, 'NOT_FOUND', 'Administrator role not found.');
  return { role: await serializeRole(req, value) };
}

async function permissions(req) {
  const { AdminPermission } = getModels();
  const where = {};
  if (req.query.module) where.module = String(req.query.module).slice(0, 80);
  if (req.query.search) where[Op.or] = [
    { key: { [Op.like]: `%${String(req.query.search).slice(0, 160)}%` } },
    { name: { [Op.like]: `%${String(req.query.search).slice(0, 160)}%` } },
  ];
  const rows = await AdminPermission.findAll({ where, order: [['module', 'ASC'], ['key', 'ASC']] });
  let items = rows.map((permission, index) => serializePermission(permission, req, index));
  if (req.query.risk) items = items.filter((item) => item.riskLevel === req.query.risk);
  if (req.query.delegable != null) items = items.filter((item) => item.delegable === (String(req.query.delegable) === 'true'));
  return { items };
}

async function matrixVersion(transaction) {
  const { AdminRole } = getModels();
  const roles = await AdminRole.findAll({ attributes: ['id', 'version'], order: [['id', 'ASC']], transaction });
  return `matrix-${tokenHash(roles.map((role) => `${role.id}:${role.version}`).join('|')).slice(0, 16)}`;
}

async function permissionMatrix(req, transaction) {
  const { AdminRole, AdminPermission } = getModels();
  const [roleRows, permissionRows, version] = await Promise.all([
    AdminRole.findAll({
      include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
      order: [['name', 'ASC']], transaction,
    }),
    AdminPermission.findAll({ order: [['module', 'ASC'], ['key', 'ASC']], transaction }),
    matrixVersion(transaction),
  ]);
  const rolesPayload = await Promise.all(roleRows.map((item) => serializeRole(req, item, { transaction })));
  const permissionsPayload = permissionRows.map((item, index) => serializePermission(item, req, index));
  const cells = [];
  for (const roleRow of roleRows) {
    const assigned = new Set((roleRow.permissions || []).map((permission) => String(permission.id)));
    for (const permission of permissionsPayload) {
      const isAssigned = assigned.has(permission.permissionId);
      const protectedCell = roleRow.isSystem === true;
      cells.push({
        roleId: String(roleRow.id), permissionId: permission.permissionId,
        state: protectedCell && isAssigned ? 'protected' : isAssigned ? 'assigned' : protectedCell ? 'restricted' : 'notAssigned',
        canGrant: !protectedCell && permission.delegable,
        canRevoke: !protectedCell && permission.delegable,
        restrictionReason: protectedCell ? 'System role permissions are immutable.' : !permission.delegable ? 'You cannot delegate a permission you do not hold.' : null,
      });
    }
  }
  return {
    matrixId: 'administrator-permission-matrix', version,
    roles: rolesPayload, permissions: permissionsPayload, cells,
    allowedActions: (req.adminPermissions || new Set()).has('permissions.matrix.manage') ? ['update'] : [],
    warnings: ['MFA permissions are unavailable until the MFA product decision is approved.'],
  };
}

async function validateAssignableRoles(req, roleIds, transaction) {
  const { AdminRole, AdminPermission } = getModels();
  const unique = [...new Set(roleIds.map(String))];
  const roles = await AdminRole.findAll({
    where: { id: unique, isActive: true }, transaction,
    include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
  });
  if (!unique.length || unique.length > 10 || roles.length !== unique.length) throw serviceError(422, 'ROLE_NOT_ASSIGNABLE', 'One or more roles cannot be assigned.');
  const actorPermissions = req.adminPermissions || new Set();
  if (roles.some((role) => role.key === 'super_admin') && !actorIsSuper(req)) throw serviceError(403, 'ROLE_NOT_ASSIGNABLE', 'The system role cannot be delegated.');
  if (roles.some((role) => (role.permissions || []).some((permission) => !actorPermissions.has(permission.key)))) {
    throw serviceError(403, 'PRIVILEGE_ESCALATION_BLOCKED', 'You cannot grant permissions you do not hold.');
  }
  return roles;
}

function rolePermissionDiff(oldRoles, newRoles) {
  const oldKeys = new Set(oldRoles.flatMap((item) => [...rolePermissionKeys(item)]));
  const newPermissions = new Map(newRoles.flatMap((item) => (item.permissions || []).map((permission) => [permission.key, permission])));
  const gained = [...newPermissions.keys()].filter((key) => !oldKeys.has(key));
  const removed = [...oldKeys].filter((key) => !newPermissions.has(key));
  const highRisk = [...new Set([...gained, ...removed])].filter((key) => ['high', 'critical'].includes(riskFor(key)));
  return { oldKeys, newPermissions, gained, removed, highRisk };
}

function previewPayload(diff, affectedAdministratorCount = 1) {
  return {
    previewId: crypto.randomUUID(),
    permissionsGained: diff.gained.length,
    permissionsRemoved: diff.removed.length,
    criticalPermissionsGained: diff.gained.filter((key) => riskFor(key) === 'critical').length,
    highRiskChanges: diff.highRisk.map((key) => ({
      permissionKey: key, label: key.replaceAll('.', ' '), source: 'Direct role change', riskLevel: riskFor(key),
    })),
    warnings: diff.removed.length ? ['Affected administrators will be signed out and must authenticate again.'] : [],
    affectedAdministratorCount,
    sessionImpactLabel: 'All active sessions for affected administrators will be revoked when this change is committed.',
  };
}

async function createAdministrator(req) {
  const body = req.body;
  let invitationId;
  let invitationToken;
  const result = await idempotent(req, 'administrator:create', body, async (transaction) => {
    const { Administrator, AdminInvitation } = getModels();
    const existing = await Administrator.findOne({ where: { email: normalizeEmail(body.email) }, transaction, lock: transaction.LOCK.UPDATE });
    if (existing) throw serviceError(409, existing.invitationStatus === 'pending' ? 'INVITATION_PENDING' : 'ADMINISTRATOR_ALREADY_EXISTS', 'An administrator already uses this email.');
    const roles = await validateAssignableRoles(req, body.roleIds, transaction);
    const administrator = await Administrator.create({
      name: String(body.name).trim(), email: normalizeEmail(body.email), passwordHash: null,
      status: 'disabled', invitationStatus: 'pending', locale: body.locale,
      timezone: body.timezone, createdByAdministratorId: req.admin.id,
    }, { transaction });
    await administrator.setRoles(roles, { transaction });
    const selector = crypto.randomBytes(16).toString('hex');
    const token = `${selector}.${crypto.randomBytes(32).toString('hex')}`;
    const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000);
    const invitation = await AdminInvitation.create({
      administratorId: administrator.id, invitedByAdministratorId: req.admin.id,
      selector, tokenHash: tokenHash(token), expiresAt,
      deliveryStatus: body.sendInvitationNow ? 'pending' : 'not_requested',
    }, { transaction });
    invitationId = String(invitation.id);
    invitationToken = token;
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.administrator.created',
      targetType: 'administrator', targetId: administrator.id,
      newValue: { name: administrator.name, email: administrator.email, status: administrator.status, roleIds: roles.map((role) => String(role.id)) },
      metadata: { invitationId: String(invitation.id), sendInvitationNow: body.sendInvitationNow === true }, transaction,
    });
    const loaded = await administratorWithRoles(administrator.id, { transaction });
    return {
      administrator: await serializeAdministrator(req, loaded, { transaction }),
      sessionImpact: { sessionsRevoked: 0, sessionsRefreshRequired: false, reauthenticationRequired: false },
      currentAdministratorAffected: false,
      invitationDelivery: { status: invitation.deliveryStatus, providerAccepted: false },
      message: body.sendInvitationNow ? 'Administrator created; invitation delivery is pending.' : 'Administrator created; invitation delivery was not requested.',
    };
  });
  if (!body.sendInvitationNow || result.replayed) return result;
  const { AdminInvitation, AdminIdempotencyKey } = getModels();
  const invitation = await AdminInvitation.findByPk(invitationId);
  if (!invitation || invitation.deliveryStatus !== 'pending') return result;
  let delivery;
  let deliveryUpdate;
  try {
    const provider = await sendAdminInvitation({
      email: body.email, name: body.name, token: invitationToken,
      expiresAt: invitation.expiresAt, invitationMessage: body.invitationMessage,
    });
    delivery = provider.accepted
      ? { status: 'provider_accepted', providerAccepted: true, providerMessageId: provider.messageId || null }
      : { status: 'pending', providerAccepted: false };
    deliveryUpdate = {
      deliveryStatus: delivery.status, deliveryAttempts: Number(invitation.deliveryAttempts) + 1,
      providerMessageId: delivery.providerMessageId || null, deliveryAttemptedAt: now(), deliveryErrorCode: null,
    };
  } catch (error) {
    const safeCode = /^[A-Z0-9_]{1,80}$/.test(String(error.code || '')) ? error.code : 'INVITATION_DELIVERY_FAILED';
    delivery = { status: 'failed', providerAccepted: false, errorCode: safeCode };
    deliveryUpdate = {
      deliveryStatus: 'failed', deliveryAttempts: Number(invitation.deliveryAttempts) + 1,
      deliveryAttemptedAt: now(), deliveryErrorCode: safeCode,
    };
  }
  const publicResult = { ...result, invitationDelivery: delivery, message: delivery.providerAccepted ? 'Administrator created; the email provider accepted the invitation.' : 'Administrator created; invitation delivery is not confirmed.' };
  const key = String(req.headers['idempotency-key']);
  await AdminInvitation.sequelize.transaction(async (transaction) => {
    await invitation.update(deliveryUpdate, { transaction });
    await recordAudit({
      request: req,
      administratorId: req.admin.id,
      action: 'admin.invitation.delivery_updated',
      targetType: 'administrator',
      targetId: result.administrator.adminId,
      newValue: { deliveryStatus: delivery.status, providerAccepted: delivery.providerAccepted },
      metadata: { invitationId: String(invitation.id), deliveryAttempts: deliveryUpdate.deliveryAttempts },
      transaction,
    });
    await AdminIdempotencyKey.update({ responseBody: publicResult }, {
      where: { administratorId: req.admin.id, scope: 'administrator:create', idempotencyKey: key },
      transaction,
    });
  });
  return publicResult;
}

async function roleAssignmentPreview(req, id) {
  return idempotent(req, `administrator:${id}:role-preview`, req.body, async (transaction) => {
    const administrator = await administratorWithRoles(id, { transaction });
    if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
    if (String(req.admin.id) === String(id)) throw serviceError(409, 'SELF_MANAGEMENT_PROHIBITED', 'Use a separate privileged administrator for role changes.');
    requireVersion(req, versionFor('admin', administrator.version));
    const newRoles = await validateAssignableRoles(req, req.body.roleIds, transaction);
    const removingSuper = (administrator.roles || []).some((role) => role.key === 'super_admin') && !newRoles.some((role) => role.key === 'super_admin');
    if (removingSuper && await isLastActiveSuper(administrator, transaction)) throw serviceError(409, 'LAST_ACTIVE_SUPER_ADMINISTRATOR', 'The last active super administrator cannot lose that role.');
    return { preview: previewPayload(rolePermissionDiff(administrator.roles || [], newRoles)) };
  });
}

async function assignRoles(req, id) {
  return idempotent(req, `administrator:${id}:assign-roles`, req.body, async (transaction) => {
    const { AdminRefreshToken } = getModels();
    const administrator = await administratorWithRoles(id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
    if (String(req.admin.id) === String(id)) throw serviceError(409, 'SELF_MANAGEMENT_PROHIBITED', 'Use a separate privileged administrator for role changes.');
    requireVersion(req, versionFor('admin', administrator.version));
    const newRoles = await validateAssignableRoles(req, req.body.roleIds, transaction);
    const removingSuper = (administrator.roles || []).some((role) => role.key === 'super_admin') && !newRoles.some((role) => role.key === 'super_admin');
    if (removingSuper && await isLastActiveSuper(administrator, transaction)) throw serviceError(409, 'LAST_ACTIVE_SUPER_ADMINISTRATOR', 'The last active super administrator cannot lose that role.');
    const oldRoleIds = (administrator.roles || []).map((role) => String(role.id));
    const activeSessions = await AdminRefreshToken.count({ where: { administratorId: id, ...activeSessionWhere() }, transaction });
    await administrator.setRoles(newRoles, { transaction });
    const changedAt = now();
    await AdminRefreshToken.update({ revokedAt: changedAt, revokedReason: 'roles_changed' }, { where: { administratorId: id, revokedAt: null }, transaction });
    await administrator.update({ version: Number(administrator.version) + 1, tokenVersion: Number(administrator.tokenVersion) + 1 }, { transaction });
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.administrator.roles_changed',
      targetType: 'administrator', targetId: id, oldValue: { roleIds: oldRoleIds },
      newValue: { roleIds: newRoles.map((role) => String(role.id)) }, transaction,
    });
    const loaded = await administratorWithRoles(id, { transaction });
    return {
      administrator: await serializeAdministrator(req, loaded, { transaction }),
      sessionImpact: { sessionsRevoked: activeSessions, sessionsRefreshRequired: true, reauthenticationRequired: true, takesEffectAt: changedAt },
      currentAdministratorAffected: false,
      message: 'Administrator roles updated and active sessions revoked.',
    };
  });
}

async function suspend(req, id) {
  return idempotent(req, `administrator:${id}:suspend`, req.body, async (transaction) => {
    const { AdminRefreshToken } = getModels();
    const administrator = await administratorWithRoles(id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
    if (String(req.admin.id) === String(id)) throw serviceError(409, 'SELF_MANAGEMENT_PROHIBITED', 'You cannot suspend your own account.');
    requireVersion(req, versionFor('admin', administrator.version));
    if (administrator.status === 'suspended') throw serviceError(409, 'ALREADY_SUSPENDED', 'Administrator is already suspended.');
    if (administrator.status !== 'active') throw serviceError(409, 'INVALID_STATE_TRANSITION', 'Only an active administrator can be suspended.');
    if (await isLastActiveSuper(administrator, transaction)) throw serviceError(409, 'LAST_ACTIVE_SUPER_ADMINISTRATOR', 'The last active super administrator cannot be suspended.');
    const changedAt = now();
    const activeSessions = await AdminRefreshToken.count({ where: { administratorId: id, ...activeSessionWhere() }, transaction });
    await administrator.update({
      status: 'suspended', suspendedAt: changedAt, suspendedByAdministratorId: req.admin.id,
      suspensionReasonCode: req.body.reasonCode, suspensionReasonDetail: req.body.reasonDetail || null,
      suspensionEndsAt: null, version: Number(administrator.version) + 1,
      tokenVersion: Number(administrator.tokenVersion) + 1,
    }, { transaction });
    await AdminRefreshToken.update({ revokedAt: changedAt, revokedReason: 'administrator_suspended' }, { where: { administratorId: id, revokedAt: null }, transaction });
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.administrator.suspended',
      targetType: 'administrator', targetId: id,
      oldValue: { status: 'active' }, newValue: { status: 'suspended' },
      reason: req.body.reasonCode, metadata: { reasonDetail: req.body.reasonDetail || null }, transaction,
    });
    const loaded = await administratorWithRoles(id, { transaction });
    return {
      administrator: await serializeAdministrator(req, loaded, { transaction }),
      sessionImpact: { sessionsRevoked: activeSessions, sessionsRefreshRequired: true, reauthenticationRequired: true, takesEffectAt: changedAt },
      currentAdministratorAffected: false, message: 'Administrator suspended and active sessions revoked.',
    };
  });
}

async function reactivate(req, id) {
  return idempotent(req, `administrator:${id}:reactivate`, req.body, async (transaction) => {
    const administrator = await administratorWithRoles(id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
    requireVersion(req, versionFor('admin', administrator.version));
    if (administrator.status !== 'suspended') throw serviceError(409, 'INVALID_STATE_TRANSITION', 'Only a suspended administrator can be reactivated.');
    const changedAt = now();
    await administrator.update({
      status: 'active', suspendedAt: null, suspendedByAdministratorId: null,
      suspensionReasonCode: null, suspensionReasonDetail: null, suspensionEndsAt: null,
      version: Number(administrator.version) + 1,
    }, { transaction });
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.administrator.reactivated',
      targetType: 'administrator', targetId: id,
      oldValue: { status: 'suspended' }, newValue: { status: 'active' }, transaction,
    });
    const loaded = await administratorWithRoles(id, { transaction });
    return {
      administrator: await serializeAdministrator(req, loaded, { transaction }),
      sessionImpact: { sessionsRevoked: 0, sessionsRefreshRequired: false, reauthenticationRequired: true, takesEffectAt: changedAt },
      currentAdministratorAffected: String(req.admin.id) === String(id), message: 'Administrator reactivated.',
    };
  });
}

async function revokeSessions(req, id) {
  return idempotent(req, `administrator:${id}:revoke-sessions`, req.body, async (transaction) => {
    const { AdminRefreshToken } = getModels();
    const administrator = await administratorWithRoles(id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
    if (String(req.admin.id) === String(id)) throw serviceError(409, 'SELF_MANAGEMENT_PROHIBITED', 'Use session security controls to revoke your own sessions.');
    requireVersion(req, versionFor('admin', administrator.version));
    const changedAt = now();
    const activeSessions = await AdminRefreshToken.count({ where: { administratorId: id, ...activeSessionWhere() }, transaction });
    await AdminRefreshToken.update({ revokedAt: changedAt, revokedReason: 'administrator_forced_logout' }, { where: { administratorId: id, revokedAt: null }, transaction });
    await administrator.update({ version: Number(administrator.version) + 1, tokenVersion: Number(administrator.tokenVersion) + 1 }, { transaction });
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.administrator.sessions_revoked',
      targetType: 'administrator', targetId: id, metadata: { sessionsRevoked: activeSessions }, transaction,
    });
    const loaded = await administratorWithRoles(id, { transaction });
    return {
      administrator: await serializeAdministrator(req, loaded, { transaction }),
      sessionImpact: { sessionsRevoked: activeSessions, sessionsRefreshRequired: true, reauthenticationRequired: true, takesEffectAt: changedAt },
      currentAdministratorAffected: false, message: 'Administrator sessions revoked.',
    };
  });
}

async function assignableRoles(req, id) {
  const administrator = await administratorWithRoles(id);
  if (!administrator) throw serviceError(404, 'NOT_FOUND', 'Administrator not found.');
  const result = await roles({ ...req, query: { page: 1, pageSize: 100, sortBy: 'name', sortDirection: 'asc', status: 'active' } });
  return { items: result.items.filter((item) => item.assignable) };
}

async function permissionPreview(req, roleId) {
  return idempotent(req, `role:${roleId}:permission-preview`, req.body, async (transaction) => {
    const matrix = await permissionMatrix(req, transaction);
    requireVersion(req, matrix.version);
    const role = matrix.roles.find((item) => item.roleId === String(roleId));
    if (!role) throw serviceError(404, 'NOT_FOUND', 'Administrator role not found.');
    if (role.protected) throw serviceError(409, 'PROTECTED_ROLE', 'System role permissions cannot be changed.');
    const changes = validatePermissionUpdates(req, roleId, req.body.updates, matrix);
    const gained = changes.filter((item) => item.assigned).map((item) => item.permission.permissionKey);
    const removed = changes.filter((item) => !item.assigned).map((item) => item.permission.permissionKey);
    const diff = { gained, removed, highRisk: [...gained, ...removed].filter((key) => ['high', 'critical'].includes(riskFor(key))) };
    return { preview: previewPayload(diff, role.administratorCount || 0) };
  });
}

function validatePermissionUpdates(req, roleId, updates, matrix) {
  const unique = new Set();
  return updates.map((update) => {
    if (String(update.roleId) !== String(roleId) || unique.has(String(update.permissionId))) throw serviceError(422, 'VALIDATION_ERROR', 'Permission updates must be unique and target the selected role.');
    unique.add(String(update.permissionId));
    const permission = matrix.permissions.find((item) => item.permissionId === String(update.permissionId));
    const cell = matrix.cells.find((item) => item.roleId === String(roleId) && item.permissionId === String(update.permissionId));
    if (!permission || !cell) throw serviceError(422, 'VALIDATION_ERROR', 'Unknown permission update.');
    if (!permission.delegable) throw serviceError(403, 'PERMISSION_NOT_DELEGABLE', 'You cannot delegate a permission you do not hold.');
    if (['high', 'critical'].includes(permission.riskLevel) && !(req.adminPermissions || new Set()).has('permissions.highRisk.manage')) {
      throw serviceError(403, 'PERMISSION_NOT_DELEGABLE', 'High-risk permission management is required.');
    }
    return { update, permission, cell, assigned: update.assigned === true };
  });
}

async function savePermissions(req, roleId) {
  return idempotent(req, `role:${roleId}:permissions`, req.body, async (transaction) => {
    const { AdminRole, AdminPermission, Administrator, AdminRefreshToken } = getModels();
    const currentMatrix = await permissionMatrix(req, transaction);
    requireVersion(req, currentMatrix.version);
    const role = await AdminRole.findByPk(roleId, {
      transaction, lock: transaction.LOCK.UPDATE,
      include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }],
    });
    if (!role) throw serviceError(404, 'NOT_FOUND', 'Administrator role not found.');
    if (role.isSystem) throw serviceError(409, 'PROTECTED_ROLE', 'System role permissions cannot be changed.');
    const changes = validatePermissionUpdates(req, roleId, req.body.updates, currentMatrix);
    const current = new Map((role.permissions || []).map((permission) => [String(permission.id), permission]));
    for (const change of changes) {
      if (change.assigned) current.set(change.permission.permissionId, await AdminPermission.findByPk(change.permission.permissionId, { transaction }));
      else current.delete(change.permission.permissionId);
    }
    if (!current.size) throw serviceError(422, 'PERMISSION_DEPENDENCY', 'A role must retain at least one permission.');
    const affected = await Administrator.findAll({
      include: [{ model: AdminRole, as: 'roles', where: { id: roleId }, through: { attributes: [] } }],
      transaction, lock: transaction.LOCK.UPDATE,
    });
    const changedAt = now();
    await role.setPermissions([...current.values()], { transaction });
    await role.update({ version: Number(role.version) + 1 }, { transaction });
    const affectedIds = affected.map((item) => item.id);
    let sessionsRevoked = 0;
    if (affectedIds.length) {
      sessionsRevoked = await AdminRefreshToken.count({ where: { administratorId: affectedIds, ...activeSessionWhere() }, transaction });
      await AdminRefreshToken.update({ revokedAt: changedAt, revokedReason: 'role_permissions_changed' }, { where: { administratorId: affectedIds, revokedAt: null }, transaction });
      await Administrator.increment(['tokenVersion', 'version'], { by: 1, where: { id: affectedIds }, transaction });
    }
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.role.permissions_changed',
      targetType: 'admin_role', targetId: roleId,
      oldValue: { permissionIds: (role.permissions || []).map((permission) => String(permission.id)) },
      newValue: { permissionIds: [...current.keys()] },
      metadata: { affectedAdministratorCount: affected.length, sessionsRevoked }, transaction,
    });
    return permissionMatrix(req, transaction);
  });
}

async function createRole(req) {
  return idempotent(req, 'role:create', req.body, async (transaction) => {
    const { AdminRole, AdminPermission } = getModels();
    const existing = await AdminRole.findOne({ where: { key: req.body.key }, transaction });
    if (existing) throw serviceError(409, 'ROLE_ALREADY_EXISTS', 'A role with this key already exists.');
    const permissions = await AdminPermission.findAll({ where: { id: req.body.permissionIds }, transaction });
    if (!permissions.length || permissions.length !== new Set(req.body.permissionIds.map(String)).size) throw serviceError(422, 'VALIDATION_ERROR', 'One or more permissions are invalid.');
    if (permissions.some((permission) => !(req.adminPermissions || new Set()).has(permission.key))) throw serviceError(403, 'PRIVILEGE_ESCALATION_BLOCKED', 'You cannot grant permissions you do not hold.');
    if (permissions.some((permission) => ['high', 'critical'].includes(riskFor(permission.key))) && !(req.adminPermissions || new Set()).has('permissions.highRisk.manage')) throw serviceError(403, 'PERMISSION_NOT_DELEGABLE', 'High-risk permission management is required.');
    const role = await AdminRole.create({ key: req.body.key, name: req.body.name, description: req.body.description || null, isSystem: false, isActive: true }, { transaction });
    await role.setPermissions(permissions, { transaction });
    await recordAudit({
      request: req, administratorId: req.admin.id, action: 'admin.role.created',
      targetType: 'admin_role', targetId: role.id,
      newValue: { key: role.key, name: role.name, permissionIds: permissions.map((item) => String(item.id)) }, transaction,
    });
    const loaded = await AdminRole.findByPk(role.id, { transaction, include: [{ model: AdminPermission, as: 'permissions', through: { attributes: [] } }] });
    return { role: await serializeRole(req, loaded, { transaction }) };
  });
}

function splitInvitationToken(token) {
  if (typeof token !== 'string') return null;
  const [selector, secret, ...extra] = token.split('.');
  if (extra.length || !/^[a-f0-9]{32}$/.test(selector || '') || !/^[a-f0-9]{64}$/.test(secret || '')) return null;
  return { selector, token: `${selector}.${secret}` };
}

function invitationMatches(token, hash) {
  const actual = Buffer.from(tokenHash(token), 'hex');
  const expected = Buffer.from(String(hash || ''), 'hex');
  return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
}

async function invitationStatus(token) {
  const parsed = splitInvitationToken(token);
  if (!parsed) return { status: 'invalid', valid: false };
  const { AdminInvitation } = getModels();
  const invitation = await AdminInvitation.findOne({ where: { selector: parsed.selector } });
  if (!invitation || !invitationMatches(parsed.token, invitation.tokenHash)) return { status: 'invalid', valid: false };
  if (invitation.revokedAt) return { status: 'revoked', valid: false };
  if (invitation.consumedAt) return { status: 'used', valid: false };
  if (invitation.expiresAt <= now()) return { status: 'expired', valid: false };
  return { status: 'valid', valid: true, expiresAt: invitation.expiresAt };
}

async function acceptInvitation(token, password, request) {
  const parsed = splitInvitationToken(token);
  if (!parsed) throw serviceError(422, 'INVITATION_INVALID', 'The administrator invitation is invalid.');
  const { AdminInvitation, Administrator } = getModels();
  if (typeof password !== 'string' || password.length < 8 || password.length > 128
      || !/[a-z]/.test(password) || !/[A-Z]/.test(password)
      || !/[0-9]/.test(password) || !/[^A-Za-z0-9]/.test(password)) {
    throw serviceError(422, 'PASSWORD_POLICY_FAILED', 'The password does not satisfy the administrator password policy.');
  }
  const passwordHash = await bcrypt.hash(password, 12);
  return Administrator.sequelize.transaction(async (transaction) => {
    const invitation = await AdminInvitation.findOne({ where: { selector: parsed.selector }, transaction, lock: transaction.LOCK.UPDATE });
    if (!invitation || !invitationMatches(parsed.token, invitation.tokenHash)) throw serviceError(422, 'INVITATION_INVALID', 'The administrator invitation is invalid.');
    if (invitation.revokedAt) throw serviceError(410, 'INVITATION_REVOKED', 'The administrator invitation was revoked.');
    if (invitation.consumedAt) throw serviceError(409, 'INVITATION_USED', 'The administrator invitation was already used.');
    if (invitation.expiresAt <= now()) {
      throw serviceError(410, 'INVITATION_EXPIRED', 'The administrator invitation expired.');
    }
    const administrator = await Administrator.findByPk(invitation.administratorId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!administrator || administrator.invitationStatus !== 'pending' || administrator.status !== 'disabled') throw serviceError(409, 'INVALID_STATE_TRANSITION', 'This administrator cannot accept an invitation.');
    const acceptedAt = now();
    await administrator.update({
      passwordHash, status: 'active', invitationStatus: 'accepted', activatedAt: acceptedAt,
      version: Number(administrator.version) + 1, failedLoginAttempts: 0, lockedUntil: null,
    }, { transaction });
    await invitation.update({ consumedAt: acceptedAt }, { transaction });
    await recordAudit({
      request, administratorId: null, action: 'admin.invitation.accepted',
      targetType: 'administrator', targetId: administrator.id,
      newValue: { status: 'active', invitationStatus: 'accepted' },
      metadata: { invitationId: String(invitation.id) }, transaction,
    });
    return { status: 'accepted', requiresLogin: true };
  });
}

module.exports = {
  serviceError, configuration, listAdministrators, getAdministrator, administratorAudit,
  roles, role, permissions, permissionMatrix, createAdministrator,
  roleAssignmentPreview, assignRoles, suspend, reactivate, revokeSessions,
  assignableRoles, permissionPreview, savePermissions, createRole,
  invitationStatus, acceptInvitation,
};
