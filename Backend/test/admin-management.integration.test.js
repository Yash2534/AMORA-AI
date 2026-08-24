const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Administrator-management tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
require('../src/config/env');
const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server;
let baseUrl;
let actor;
let actorPassword;
let actorRole;
let limited;
let limitedPassword;
let limitedRole;
const createdAdministratorIds = [];
const createdRoleIds = [];

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      ...(options.accessToken ? { authorization: `Bearer ${options.accessToken}` } : {}),
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
    ...(options.body ? { body: JSON.stringify(options.body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

async function login(administrator, password) {
  const response = await request('/api/admin/v1/auth/login', {
    method: 'POST', body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(response.status, 200, JSON.stringify(response.body));
  return response.body.data.accessToken;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  const { Administrator, AdminRole, AdminPermission } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  actorPassword = `Management!${suffix}Aa1`;
  limitedPassword = `Limited!${suffix}Aa1`;
  actorRole = await AdminRole.create({
    key: `management_actor_${suffix}`, name: 'Management Integration Actor', isActive: true,
  });
  const allPermissions = await AdminPermission.findAll();
  await actorRole.setPermissions(allPermissions);
  actor = await Administrator.create({
    name: 'Management Integration Actor',
    email: `management.actor.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(actorPassword, 12), status: 'active', activatedAt: new Date(),
  });
  await actor.setRoles([actorRole]);

  limitedRole = await AdminRole.create({
    key: `management_limited_${suffix}`, name: 'Management Limited Actor', isActive: true,
  });
  const viewPermission = await AdminPermission.findOne({ where: { key: 'administrators.view' } });
  await limitedRole.setPermissions([viewPermission]);
  limited = await Administrator.create({
    name: 'Management Limited Actor',
    email: `management.limited.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(limitedPassword, 12), status: 'active', activatedAt: new Date(),
  });
  await limited.setRoles([limitedRole]);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const {
    AdminAuditLog, AdminIdempotencyKey, AdminInvitation, AdminPasswordResetToken,
    AdminRefreshToken, Administrator, AdminRole,
  } = getModels();
  const administratorIds = [...createdAdministratorIds, actor?.id, limited?.id].filter(Boolean);
  await AdminAuditLog.destroy({ where: { [require('sequelize').Op.or]: [
    { administratorId: administratorIds },
    { targetType: 'administrator', targetId: administratorIds.map(String) },
    { targetType: 'admin_role', targetId: [...createdRoleIds, actorRole?.id, limitedRole?.id].filter(Boolean).map(String) },
  ] } });
  await AdminIdempotencyKey.destroy({ where: { administratorId: administratorIds } });
  await AdminInvitation.destroy({ where: { administratorId: administratorIds } });
  await AdminPasswordResetToken.destroy({ where: { administratorId: administratorIds } });
  await AdminRefreshToken.destroy({ where: { administratorId: administratorIds }, force: true });
  for (const id of administratorIds) {
    const administrator = await Administrator.findByPk(id);
    if (administrator) await administrator.setRoles([]);
  }
  await Administrator.destroy({ where: { id: administratorIds } });
  for (const id of [...createdRoleIds, actorRole?.id, limitedRole?.id].filter(Boolean)) {
    const role = await AdminRole.findByPk(id);
    if (role) {
      await role.setPermissions([]);
      await role.destroy();
    }
  }
  await getSequelize().close();
});

test('administrator creation is committed, audited, idempotent, and denied without RBAC', async () => {
  const token = await login(actor, actorPassword);
  const limitedToken = await login(limited, limitedPassword);
  const configuration = await request('/api/admin/v1/administrator-management/configuration', { accessToken: token });
  assert.equal(configuration.status, 200);
  assert.equal(configuration.body.data.mfaAvailable, false);

  const createRole = await request('/api/admin/v1/roles', {
    method: 'POST', accessToken: token,
    headers: { 'idempotency-key': `role-${crypto.randomUUID()}` },
    body: {
      key: `support_${crypto.randomUUID().replaceAll('-', '').slice(0, 20)}`,
      name: 'Support Integration Role',
      description: 'Integration-test role persisted in the isolated database.',
      permissionIds: [(await getModels().AdminPermission.findOne({ where: { key: 'users.view' } })).id],
    },
  });
  assert.equal(createRole.status, 201, JSON.stringify(createRole.body));
  const roleId = createRole.body.data.role.roleId;
  createdRoleIds.push(Number(roleId));

  const key = `create-${crypto.randomUUID()}`;
  const body = {
    name: 'Invited Integration Administrator',
    email: `invited.${crypto.randomUUID()}@example.test`,
    roleIds: [roleId], locale: 'en-IN', timezone: 'Asia/Kolkata',
    sendInvitationNow: false,
  };
  const denied = await request('/api/admin/v1/administrators', {
    method: 'POST', accessToken: limitedToken, headers: { 'idempotency-key': key }, body,
  });
  assert.equal(denied.status, 403);
  assert.equal(denied.body.code, 'ACCESS_DENIED');

  const created = await request('/api/admin/v1/administrators', {
    method: 'POST', accessToken: token, headers: { 'idempotency-key': key }, body,
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  assert.equal(created.body.data.administrator.status.code, 'disabled');
  assert.equal(created.body.data.administrator.invitationStatus.code, 'pending');
  assert.equal(created.body.data.invitationDelivery.status, 'not_requested');
  assert.equal(created.body.data._invitationToken, undefined);
  const administratorId = Number(created.body.data.administrator.adminId);
  createdAdministratorIds.push(administratorId);

  const replay = await request('/api/admin/v1/administrators', {
    method: 'POST', accessToken: token, headers: { 'idempotency-key': key }, body,
  });
  assert.equal(replay.status, 201);
  assert.equal(replay.body.data.administrator.adminId, String(administratorId));
  assert.equal(await getModels().Administrator.count({ where: { email: body.email } }), 1);

  const stored = await getModels().Administrator.findByPk(administratorId);
  assert.equal(stored.passwordHash, null);
  assert.equal(stored.status, 'disabled');
  assert.equal(await getModels().AdminInvitation.count({ where: { administratorId } }), 1);
  assert.equal(await getModels().AdminAuditLog.count({ where: { action: 'admin.administrator.created', targetId: String(administratorId) } }), 1);

  const deliveryAttempt = await request('/api/admin/v1/administrators', {
    method: 'POST', accessToken: token,
    headers: { 'idempotency-key': `delivery-${crypto.randomUUID()}` },
    body: {
      ...body,
      email: `delivery.${crypto.randomUUID()}@example.test`,
      sendInvitationNow: true,
    },
  });
  assert.equal(deliveryAttempt.status, 201, JSON.stringify(deliveryAttempt.body));
  assert.equal(deliveryAttempt.body.data.invitationDelivery.status, 'pending');
  assert.equal(deliveryAttempt.body.data.invitationDelivery.providerAccepted, false);
  const deliveryAdministratorId = Number(deliveryAttempt.body.data.administrator.adminId);
  createdAdministratorIds.push(deliveryAdministratorId);
  assert.equal(await getModels().AdminAuditLog.count({
    where: { action: 'admin.invitation.delivery_updated', targetId: String(deliveryAdministratorId) },
  }), 1);
});

test('invitation acceptance validates state, hashes the password, and activates the administrator', async () => {
  const { Administrator, AdminInvitation, AdminAuditLog } = getModels();
  const token = `${crypto.randomBytes(16).toString('hex')}.${crypto.randomBytes(32).toString('hex')}`;
  const invited = await Administrator.create({
    name: 'Invitation Acceptance Integration',
    email: `accept.${crypto.randomUUID()}@example.test`, passwordHash: null,
    status: 'disabled', invitationStatus: 'pending',
  });
  createdAdministratorIds.push(invited.id);
  await invited.setRoles([limitedRole]);
  await AdminInvitation.create({
    administratorId: invited.id, invitedByAdministratorId: actor.id,
    selector: token.split('.')[0], tokenHash: crypto.createHash('sha256').update(token).digest('hex'),
    expiresAt: new Date(Date.now() + 60_000), deliveryStatus: 'provider_accepted',
  });
  const valid = await request('/api/admin/v1/auth/validate-invitation', { method: 'POST', body: { token } });
  assert.equal(valid.status, 200);
  assert.equal(valid.body.data.valid, true);
  const password = `Accepted!${crypto.randomUUID()}Aa1`;
  const accepted = await request('/api/admin/v1/auth/accept-invitation', {
    method: 'POST', body: { token, newPassword: password, confirmPassword: password },
  });
  assert.equal(accepted.status, 200, JSON.stringify(accepted.body));
  await invited.reload();
  assert.equal(invited.status, 'active');
  assert.equal(invited.invitationStatus, 'accepted');
  assert.ok(await bcrypt.compare(password, invited.passwordHash));
  assert.equal(await AdminAuditLog.count({ where: { action: 'admin.invitation.accepted', targetId: String(invited.id) } }), 1);
  const reused = await request('/api/admin/v1/auth/accept-invitation', {
    method: 'POST', body: { token, newPassword: password, confirmPassword: password },
  });
  assert.equal(reused.status, 409);
  assert.equal(reused.body.code, 'INVITATION_USED');
});

test('role assignment, suspension, reactivation, session revocation, and matrix changes are transactional', async () => {
  const token = await login(actor, actorPassword);
  const targetPassword = `Target!${crypto.randomUUID()}Aa1`;
  const target = await getModels().Administrator.create({
    name: 'Lifecycle Target', email: `target.${crypto.randomUUID()}@example.test`,
    passwordHash: await bcrypt.hash(targetPassword, 12), status: 'active', activatedAt: new Date(),
  });
  createdAdministratorIds.push(target.id);
  await target.setRoles([limitedRole]);
  const targetToken = await login(target, targetPassword);

  const detail = await request(`/api/admin/v1/administrators/${target.id}`, { accessToken: token });
  assert.equal(detail.status, 200);
  const matrix = await request('/api/admin/v1/permission-matrix', { accessToken: token });
  assert.equal(matrix.status, 200);
  const customRole = matrix.body.data.roles.find((item) => item.roleId === String(limitedRole.id));
  assert.ok(customRole);
  const dashboardPermission = matrix.body.data.permissions.find((item) => item.permissionKey === 'dashboard.view');
  assert.ok(dashboardPermission);
  const updatedMatrix = await request(`/api/admin/v1/roles/${limitedRole.id}/permissions`, {
    method: 'PATCH', accessToken: token,
    headers: { 'idempotency-key': `matrix-${crypto.randomUUID()}`, 'if-match': matrix.body.data.version },
    body: { updates: [{ roleId: String(limitedRole.id), permissionId: dashboardPermission.permissionId, assigned: true }] },
  });
  assert.equal(updatedMatrix.status, 200, JSON.stringify(updatedMatrix.body));
  assert.ok((await limitedRole.getPermissions()).some((permission) => permission.key === 'dashboard.view'));
  const revokedByPermissionChange = await request('/api/admin/v1/auth/me', { accessToken: targetToken });
  assert.equal(revokedByPermissionChange.status, 401);

  await target.reload();
  const assignPreview = await request(`/api/admin/v1/administrators/${target.id}/role-change-preview`, {
    method: 'POST', accessToken: token,
    headers: { 'idempotency-key': `preview-${crypto.randomUUID()}`, 'if-match': `admin-${target.version}` },
    body: { roleIds: [String(limitedRole.id)] },
  });
  assert.equal(assignPreview.status, 200);
  const assigned = await request(`/api/admin/v1/administrators/${target.id}/assign-roles`, {
    method: 'PATCH', accessToken: token,
    headers: { 'idempotency-key': `assign-${crypto.randomUUID()}`, 'if-match': `admin-${target.version}` },
    body: { roleIds: [String(limitedRole.id)] },
  });
  assert.equal(assigned.status, 200, JSON.stringify(assigned.body));
  const assignedVersion = assigned.body.data.administrator.version;
  const suspended = await request(`/api/admin/v1/administrators/${target.id}/suspend`, {
    method: 'POST', accessToken: token,
    headers: { 'idempotency-key': `suspend-${crypto.randomUUID()}`, 'if-match': assignedVersion },
    body: { reasonCode: 'access_review', reasonDetail: 'Integration test access review.', revokeSessions: true },
  });
  assert.equal(suspended.status, 200, JSON.stringify(suspended.body));
  assert.equal(suspended.body.data.administrator.status.code, 'suspended');
  const reactivated = await request(`/api/admin/v1/administrators/${target.id}/reactivate`, {
    method: 'POST', accessToken: token,
    headers: { 'idempotency-key': `reactivate-${crypto.randomUUID()}`, 'if-match': suspended.body.data.administrator.version },
    body: {},
  });
  assert.equal(reactivated.status, 200, JSON.stringify(reactivated.body));
  assert.equal(reactivated.body.data.administrator.status.code, 'active');
  const targetTokenTwo = await login(target, targetPassword);
  const revoked = await request(`/api/admin/v1/administrators/${target.id}/revoke-sessions`, {
    method: 'POST', accessToken: token,
    headers: { 'idempotency-key': `revoke-${crypto.randomUUID()}`, 'if-match': reactivated.body.data.administrator.version },
    body: {},
  });
  assert.equal(revoked.status, 200);
  assert.ok(revoked.body.data.sessionImpact.sessionsRevoked >= 1);
  assert.equal((await request('/api/admin/v1/auth/me', { accessToken: targetTokenTwo })).status, 401);
});
