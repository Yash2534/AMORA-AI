const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Admin integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
require('../src/config/env');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { migrate } = require('../src/migrations/run');
const { app } = require('../src/server');
const { getModels } = require('../src/models');
const adminAuthService = require('../src/services/adminAuthService');
const adminMfaService = require('../src/services/adminMfaService');

let server;
let baseUrl;
let administrator;
let role;
let password;

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      ...(options.accessToken ? { authorization: `Bearer ${options.accessToken}` } : {}),
      ...(options.cookie ? { cookie: options.cookie } : {}),
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
    ...(options.body ? { body: JSON.stringify(options.body) } : {}),
  });
  const body = await response.json();
  const setCookie = response.headers.get('set-cookie');
  return {
    status: response.status,
    body,
    cookie: setCookie ? setCookie.split(';')[0] : null,
  };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  const { Administrator, AdminRole, AdminPermission } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  password = `Integration!${suffix}Aa1`;
  role = await AdminRole.create({
    key: `integration_${suffix}`,
    name: 'Integration Test Role',
    description: 'Temporary role created by the admin integration test.',
    isActive: true,
  });
  const dashboardPermission = await AdminPermission.findOne({ where: { key: 'dashboard.view' } });
  const usersPermission = await AdminPermission.findOne({ where: { key: 'users.view' } });
  const auditPermission = await AdminPermission.findOne({ where: { key: 'auditLogs.view' } });
  assert.ok(dashboardPermission);
  assert.ok(usersPermission);
  assert.ok(auditPermission);
  await role.addPermissions([dashboardPermission, usersPermission, auditPermission]);
  administrator = await Administrator.create({
    name: 'Admin Integration Test',
    email: `admin.integration.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(password, 12),
  });
  await administrator.addRole(role);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (administrator && role) {
    const { AdminAuditLog, AdminRefreshToken, AdminPasswordResetToken, Administrator, AdminRole } = getModels();
    await AdminAuditLog.destroy({ where: { administratorId: administrator.id } });
    await AdminPasswordResetToken.destroy({ where: { administratorId: administrator.id } });
    await AdminRefreshToken.destroy({ where: { administratorId: administrator.id }, force: true });
    await administrator.setRoles([]);
    await Administrator.destroy({ where: { id: administrator.id } });
    await role.setPermissions([]);
    await AdminRole.destroy({ where: { id: role.id } });
  }
  await getSequelize().close();
});

test('admin auth, refresh rotation, logout, RBAC, dashboard, and audit flow', async () => {
  const consumerToken = jwt.sign({ sub: String(administrator.id), ver: 0 }, process.env.JWT_SECRET, { expiresIn: '5m' });
  const consumerDenied = await request('/api/admin/v1/auth/me', { accessToken: consumerToken });
  assert.equal(consumerDenied.status, 401);

  const login = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(login.status, 200);
  assert.ok(login.cookie?.startsWith('amoraa_admin_refresh='));
  assert.equal(login.body.data.user.email, administrator.email);
  assert.deepEqual(login.body.data.user.permissions, ['auditLogs.view', 'dashboard.view', 'users.view']);
  assert.ok(login.body.data.accessToken);
  assert.equal(login.body.data.refreshToken, undefined);
  assert.ok(login.body.data.session.id);
  assert.ok(login.body.data.session.expiresAt);
  assert.equal(login.body.data.session.persistent, false);

  const me = await request('/api/admin/v1/auth/me', { accessToken: login.body.data.accessToken });
  assert.equal(me.status, 200);
  assert.equal(me.body.data.user.id, String(administrator.id));

  const dashboard = await request('/api/admin/v1/dashboard/overview', { accessToken: login.body.data.accessToken });
  assert.equal(dashboard.status, 200);
  assert.equal(typeof dashboard.body.data.metrics.totalUsers.value, 'number');

  const denied = await request('/api/admin/v1/permissions', { accessToken: login.body.data.accessToken });
  assert.equal(denied.status, 403);
  assert.equal(denied.body.code, 'ACCESS_DENIED');

  const audit = await request('/api/admin/v1/audit-logs?page=1&pageSize=10', {
    accessToken: login.body.data.accessToken,
  });
  assert.equal(audit.status, 200);
  assert.ok(audit.body.data.items.length > 0);
  assert.equal(audit.body.data.items[0].oldValue, undefined);
  assert.equal(audit.body.data.items[0].newValue, undefined);
  assert.equal(audit.body.data.items[0].metadata, undefined);
  assert.equal(audit.body.data.items[0].ipAddress, undefined);
  assert.equal(audit.body.data.items[0].userAgent, undefined);
  assert.equal(audit.body.data.items[0].administrator, undefined);

  const refresh = await request('/api/admin/v1/auth/refresh', { method: 'POST', cookie: login.cookie });
  assert.equal(refresh.status, 200);
  assert.ok(refresh.cookie);
  assert.notEqual(refresh.cookie, login.cookie);
  assert.notEqual(refresh.body.data.session.id, login.body.data.session.id);

  const replay = await request('/api/admin/v1/auth/refresh', { method: 'POST', cookie: login.cookie });
  assert.equal(replay.status, 401);
  assert.equal(replay.body.code, 'TOKEN_REUSED');

  const refreshedMe = await request('/api/admin/v1/auth/me', { accessToken: refresh.body.data.accessToken });
  assert.equal(refreshedMe.status, 401);
  assert.equal(refreshedMe.body.code, 'TOKEN_REVOKED');

  const relogin = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(relogin.status, 200);

  const logout = await request('/api/admin/v1/auth/logout', { method: 'POST', cookie: relogin.cookie });
  assert.equal(logout.status, 200);

  const afterLogout = await request('/api/admin/v1/auth/refresh', { method: 'POST', cookie: relogin.cookie });
  assert.equal(afterLogout.status, 401);

  const { AdminAuditLog } = getModels();
  const actions = (await AdminAuditLog.findAll({
    where: { administratorId: administrator.id },
    attributes: ['action'],
  })).map((entry) => entry.action);
  assert.ok(actions.includes('admin.auth.login_succeeded'));
  assert.ok(actions.includes('admin.auth.session_refreshed'));
  assert.ok(actions.includes('admin.auth.refresh_replay_detected'));
  assert.ok(actions.includes('admin.auth.logout'));
});

test('admin password recovery, password change, and session revocation are database-backed', async () => {
  const first = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  const second = await adminAuthService.login(administrator.email, password, true, {
    ip: '127.0.0.1',
    headers: { 'user-agent': 'admin-integration-test-secondary' },
    socket: {},
  });
  assert.equal(first.status, 200);
  assert.ok(second.accessToken);

  const sessions = await request('/api/admin/v1/auth/sessions', {
    accessToken: first.body.data.accessToken,
  });
  assert.equal(sessions.status, 200);
  assert.equal(sessions.body.data.items.length, 2);
  const otherSession = sessions.body.data.items.find((item) => !item.current);
  assert.ok(otherSession);

  const enrollment = await request('/api/admin/v1/auth/mfa/enroll', {
    method: 'POST', accessToken: first.body.data.accessToken,
  });
  assert.equal(enrollment.status, 201);
  const counter = Math.floor(Date.now() / 30000);
  const confirmation = await request('/api/admin/v1/auth/mfa/confirm', {
    method: 'POST',
    accessToken: first.body.data.accessToken,
    body: { code: adminMfaService.totpFor(enrollment.body.data.secret, counter) },
  });
  assert.equal(confirmation.status, 200);
  const recoveryCodes = confirmation.body.data.recoveryCodes;
  const stepUp = await request('/api/admin/v1/auth/mfa/step-up', {
    method: 'POST', accessToken: first.body.data.accessToken,
    body: { recoveryCode: recoveryCodes[0] },
  });
  assert.equal(stepUp.status, 200);

  const revoked = await request(`/api/admin/v1/auth/sessions/${otherSession.id}/revoke`, {
    method: 'POST',
    accessToken: first.body.data.accessToken,
  });
  assert.equal(revoked.status, 200);
  const revokedAccess = await request('/api/admin/v1/auth/me', {
    accessToken: second.accessToken,
  });
  assert.equal(revokedAccess.status, 401);
  assert.equal(revokedAccess.body.code, 'TOKEN_REVOKED');

  const unknownRecovery = await request('/api/admin/v1/auth/forgot-password', {
    method: 'POST',
    body: { email: 'does-not-exist@example.test' },
  });
  assert.equal(unknownRecovery.status, 200);

  const reset = await adminAuthService.requestPasswordReset(administrator.email, {
    ip: '127.0.0.1',
    headers: {},
    socket: {},
  });
  assert.ok(reset?.token);
  const valid = await request('/api/admin/v1/auth/validate-reset-token', {
    method: 'POST',
    body: { token: reset.token },
  });
  assert.equal(valid.status, 200);
  assert.equal(valid.body.data.status, 'valid');

  const resetPassword = `Reset!${crypto.randomUUID()}Aa1`;
  const resetResponse = await request('/api/admin/v1/auth/reset-password', {
    method: 'POST',
    body: {
      token: reset.token,
      newPassword: resetPassword,
      confirmPassword: resetPassword,
    },
  });
  assert.equal(resetResponse.status, 200);
  const firstRevoked = await request('/api/admin/v1/auth/me', {
    accessToken: first.body.data.accessToken,
  });
  assert.equal(firstRevoked.status, 401);

  const used = await request('/api/admin/v1/auth/validate-reset-token', {
    method: 'POST',
    body: { token: reset.token },
  });
  assert.equal(used.status, 200);
  assert.equal(used.body.data.status, 'used');

  await assert.rejects(
    adminAuthService.login(administrator.email, password, false, {
      ip: '127.0.0.1', headers: {}, socket: {},
    }),
    (error) => error.code === 'INVALID_CREDENTIALS',
  );
  const resetLogin = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password: resetPassword, rememberMe: false },
  });
  assert.equal(resetLogin.status, 202);
  const verifiedResetLogin = await request('/api/admin/v1/auth/mfa/verify-login', {
    method: 'POST',
    body: { challengeToken: resetLogin.body.data.challengeToken, recoveryCode: recoveryCodes[1] },
  });
  assert.equal(verifiedResetLogin.status, 200);

  const changedPassword = `Changed!${crypto.randomUUID()}Aa1`;
  const changed = await request('/api/admin/v1/auth/change-password', {
    method: 'POST',
    accessToken: verifiedResetLogin.body.data.accessToken,
    body: {
      currentPassword: resetPassword,
      newPassword: changedPassword,
      confirmPassword: changedPassword,
    },
  });
  assert.equal(changed.status, 200);
  assert.equal(changed.body.data.sessionInvalidated, true);
  const changedAccess = await request('/api/admin/v1/auth/me', {
    accessToken: verifiedResetLogin.body.data.accessToken,
  });
  assert.equal(changedAccess.status, 401);
  const finalLogin = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password: changedPassword, rememberMe: false },
  });
  assert.equal(finalLogin.status, 202);
  const verifiedFinalLogin = await request('/api/admin/v1/auth/mfa/verify-login', {
    method: 'POST',
    body: { challengeToken: finalLogin.body.data.challengeToken, recoveryCode: recoveryCodes[2] },
  });
  assert.equal(verifiedFinalLogin.status, 200);
  const disabledMfa = await request('/api/admin/v1/auth/mfa', {
    method: 'DELETE',
    accessToken: verifiedFinalLogin.body.data.accessToken,
    body: { recoveryCode: recoveryCodes[3] },
  });
  assert.equal(disabledMfa.status, 200);
  assert.equal(disabledMfa.body.data.sessionInvalidated, true);
  password = changedPassword;
});

test('expired administrator refresh sessions are rejected and revoked', async () => {
  const result = await adminAuthService.login(administrator.email, password, false, {
    ip: '127.0.0.1',
    headers: { 'user-agent': 'admin-integration-test-expired-session' },
    socket: {},
  });
  await result.session.row.update({ expiresAt: new Date(Date.now() - 1000) });

  const expired = await request('/api/admin/v1/auth/refresh', {
    method: 'POST',
    cookie: `amoraa_admin_refresh=${result.session.token}`,
  });
  assert.equal(expired.status, 401);
  assert.equal(expired.body.code, 'TOKEN_INVALID');

  await result.session.row.reload();
  assert.ok(result.session.row.revokedAt);
  assert.equal(result.session.row.revokedReason, 'expired');
});

test('administrator MFA enrollment, challenge, recovery, replay protection, and step-up are database-backed', async () => {
  const initial = await request('/api/admin/v1/auth/login', {
    method: 'POST', body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(initial.status, 200);

  const enrollment = await request('/api/admin/v1/auth/mfa/enroll', {
    method: 'POST', accessToken: initial.body.data.accessToken,
  });
  assert.equal(enrollment.status, 201);
  assert.match(enrollment.body.data.secret, /^[A-Z2-7]+$/);
  const currentCounter = Math.floor(Date.now() / 30000);
  const enrollmentCode = adminMfaService.totpFor(enrollment.body.data.secret, currentCounter);
  const confirmed = await request('/api/admin/v1/auth/mfa/confirm', {
    method: 'POST', accessToken: initial.body.data.accessToken, body: { code: enrollmentCode },
  });
  assert.equal(confirmed.status, 200);
  assert.equal(confirmed.body.data.enabled, true);
  assert.equal(confirmed.body.data.recoveryCodes.length, 10);

  const mfaLogin = await request('/api/admin/v1/auth/login', {
    method: 'POST', body: { email: administrator.email, password, rememberMe: true },
  });
  assert.equal(mfaLogin.status, 202);
  assert.equal(mfaLogin.body.data.mfaRequired, true);
  const nextCode = adminMfaService.totpFor(enrollment.body.data.secret, currentCounter + 1);
  const verified = await request('/api/admin/v1/auth/mfa/verify-login', {
    method: 'POST', body: { challengeToken: mfaLogin.body.data.challengeToken, code: nextCode },
  });
  assert.equal(verified.status, 200);
  assert.ok(verified.body.data.accessToken);

  const replay = await request('/api/admin/v1/auth/mfa/step-up', {
    method: 'POST', accessToken: verified.body.data.accessToken, body: { code: nextCode },
  });
  assert.equal(replay.status, 401);
  assert.equal(replay.body.code, 'MFA_CODE_INVALID');

  const recoveryCode = confirmed.body.data.recoveryCodes[0];
  const stepUp = await request('/api/admin/v1/auth/mfa/step-up', {
    method: 'POST', accessToken: verified.body.data.accessToken, body: { recoveryCode },
  });
  assert.equal(stepUp.status, 200);
  const reusedRecoveryCode = await request('/api/admin/v1/auth/mfa/step-up', {
    method: 'POST', accessToken: verified.body.data.accessToken, body: { recoveryCode },
  });
  assert.equal(reusedRecoveryCode.status, 401);
  assert.equal(reusedRecoveryCode.body.code, 'MFA_CODE_INVALID');

  const recoveryRegeneration = await request('/api/admin/v1/auth/mfa/recovery-codes', {
    method: 'POST', accessToken: verified.body.data.accessToken,
  });
  assert.equal(recoveryRegeneration.status, 200);
  assert.equal(recoveryRegeneration.body.data.recoveryCodes.length, 10);
});

test('production Admin mutation CSRF boundary accepts trusted origins, rejects cross-site browsers, and permits non-browser tooling', async () => {
  const previousNodeEnv = process.env.NODE_ENV;
  const previousOrigin = process.env.CORS_ORIGIN;
  const { Administrator, AdminRole, AdminPermission, AdminAuditLog, AdminRefreshToken } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  const toolingPassword = `Security!${suffix}Aa1`;
  let toolingAdministrator;
  let toolingRole;
  process.env.NODE_ENV = 'production';
  process.env.CORS_ORIGIN = 'https://admin.example.test';
  try {
    const trusted = await request('/api/admin/v1/auth/login', {
      method: 'POST',
      headers: { origin: 'https://admin.example.test', 'sec-fetch-site': 'same-origin' },
      body: { email: administrator.email, password, rememberMe: false },
    });
    assert.ok([200, 202].includes(trusted.status));

    const denied = await request('/api/admin/v1/auth/login', {
      method: 'POST',
      headers: { origin: 'https://attacker.example.test', 'sec-fetch-site': 'cross-site' },
      body: { email: administrator.email, password, rememberMe: false },
    });
    assert.equal(denied.status, 403);
    assert.equal(denied.body.code, 'ORIGIN_DENIED');

    const missingBrowserOrigin = await request('/api/admin/v1/auth/login', {
      method: 'POST',
      headers: { 'sec-fetch-site': 'cross-site' },
      body: { email: administrator.email, password, rememberMe: false },
    });
    assert.equal(missingBrowserOrigin.status, 403);
    assert.equal(missingBrowserOrigin.body.code, 'ORIGIN_DENIED');

    const tooling = await request('/api/admin/v1/auth/login', {
      method: 'POST',
      body: { email: administrator.email, password, rememberMe: false },
    });
    assert.ok([200, 202].includes(tooling.status));

    // Exercise the protected-route ordering with a distinct, non-MFA test
    // administrator: authentication runs before origin checks and RBAC after
    // them. The role deliberately lacks users.manage.
    toolingRole = await AdminRole.create({
      key: `security_${suffix}`,
      name: 'Security Boundary Test Role',
      description: 'Temporary role used to verify Admin mutation security.',
      isActive: true,
    });
    const usersView = await AdminPermission.findOne({ where: { key: 'users.view' } });
    await toolingRole.addPermission(usersView);
    toolingAdministrator = await Administrator.create({
      name: 'Security Boundary Test Admin',
      email: `security.${suffix}@example.test`,
      passwordHash: await bcrypt.hash(toolingPassword, 12),
      status: 'active',
      activatedAt: new Date(),
    });
    await toolingAdministrator.addRole(toolingRole);
    const authenticated = await request('/api/admin/v1/auth/login', {
      method: 'POST',
      headers: { origin: 'https://admin.example.test', 'sec-fetch-site': 'same-origin' },
      body: { email: toolingAdministrator.email, password: toolingPassword, rememberMe: false },
    });
    assert.equal(authenticated.status, 200);

    const unauthenticatedMutation = await request('/api/admin/v1/users/1/force-logout', {
      method: 'POST',
      headers: { origin: 'https://admin.example.test', 'sec-fetch-site': 'same-origin' },
    });
    assert.equal(unauthenticatedMutation.status, 401);

    const invalidOriginMutation = await request('/api/admin/v1/users/1/force-logout', {
      method: 'POST',
      accessToken: authenticated.body.data.accessToken,
      headers: { origin: 'https://attacker.example.test', 'sec-fetch-site': 'cross-site' },
    });
    assert.equal(invalidOriginMutation.status, 403);
    assert.equal(invalidOriginMutation.body.code, 'ORIGIN_DENIED');

    const insufficientPermissionMutation = await request('/api/admin/v1/users/1/force-logout', {
      method: 'POST',
      accessToken: authenticated.body.data.accessToken,
      headers: { origin: 'https://admin.example.test', 'sec-fetch-site': 'same-origin' },
    });
    assert.equal(insufficientPermissionMutation.status, 403);
    assert.equal(insufficientPermissionMutation.body.code, 'ACCESS_DENIED');
  } finally {
    if (toolingAdministrator) {
      await AdminAuditLog.destroy({ where: { administratorId: toolingAdministrator.id } });
      await AdminRefreshToken.destroy({ where: { administratorId: toolingAdministrator.id }, force: true });
      await toolingAdministrator.setRoles([]);
      await Administrator.destroy({ where: { id: toolingAdministrator.id } });
    }
    if (toolingRole) {
      await toolingRole.setPermissions([]);
      await AdminRole.destroy({ where: { id: toolingRole.id } });
    }
    process.env.NODE_ENV = previousNodeEnv;
    process.env.CORS_ORIGIN = previousOrigin;
  }
});
