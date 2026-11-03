const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const jwt = require('jsonwebtoken');

const { authenticateAccessToken } = require('../src/services/adminAuthService');
const { _test: auditSerializers } = require('../src/controllers/adminCatalogController');
const errorHandler = require('../src/middleware/errorHandler');

const originalAdminSecret = process.env.ADMIN_JWT_SECRET;
process.env.ADMIN_JWT_SECRET = 'r1-negative-security-secret-at-least-32-bytes';
process.on('exit', () => {
  if (originalAdminSecret === undefined) delete process.env.ADMIN_JWT_SECRET;
  else process.env.ADMIN_JWT_SECRET = originalAdminSecret;
});

function adminToken(claims, options = {}) {
  return jwt.sign(claims, process.env.ADMIN_JWT_SECRET, {
    algorithm: 'HS256',
    expiresIn: '5m',
    issuer: options.issuer || 'amoraa-backend',
    audience: options.audience || 'amoraa-admin-web',
  });
}

function accessOptions(administrator, session = { mfaVerifiedAt: null }) {
  return {
    loadAdministrator: async () => administrator,
    models: { AdminRefreshToken: { findOne: async () => session } },
    now: () => new Date('2026-10-12T00:00:00.000Z'),
  };
}

function activeAdministrator(overrides = {}) {
  return {
    id: 1,
    status: 'active',
    tokenVersion: 0,
    roles: [{ permissions: [{ key: 'dashboard.view' }] }],
    mfaCredential: null,
    ...overrides,
  };
}

test('admin access authentication rejects issuer and required-session claim bypasses before database access', async () => {
  await assert.rejects(
    () => authenticateAccessToken(adminToken({ sub: '1', sid: 'a'.repeat(32), typ: 'admin_access', ver: 0 }, { issuer: 'attacker' })),
    (error) => error.status === 401 && error.code === 'TOKEN_INVALID',
  );
  await assert.rejects(
    () => authenticateAccessToken(adminToken({ sub: '1', typ: 'admin_access', ver: 0 })),
    (error) => error.status === 401 && error.code === 'TOKEN_INVALID',
  );
  await assert.rejects(
    () => authenticateAccessToken(adminToken({ sub: '1', sid: 'a'.repeat(32), typ: 'user_access', ver: 0 })),
    (error) => error.status === 401 && error.code === 'TOKEN_INVALID',
  );
});

test('admin access authentication accepts a current active session and explicit role', async () => {
  const token = adminToken({ sub: '1', sid: 'a'.repeat(32), typ: 'admin_access', ver: 0, amr: ['pwd'] });
  const result = await authenticateAccessToken(token, accessOptions(activeAdministrator()));
  assert.equal(result.administrator.id, 1);
  assert.deepEqual([...result.permissions], ['dashboard.view']);
});

test('admin access authentication rejects expired tokens without database access', async () => {
  const token = jwt.sign(
    { sub: '1', sid: 'a'.repeat(32), typ: 'admin_access', ver: 0 },
    process.env.ADMIN_JWT_SECRET,
    { algorithm: 'HS256', expiresIn: -1, issuer: 'amoraa-backend', audience: 'amoraa-admin-web' },
  );
  await assert.rejects(
    () => authenticateAccessToken(token, accessOptions(activeAdministrator())),
    (error) => error.status === 401 && error.code === 'TOKEN_EXPIRED',
  );
});

test('admin access authentication rejects revoked session, disabled admin, and role removal', async () => {
  const token = adminToken({ sub: '1', sid: 'a'.repeat(32), typ: 'admin_access', ver: 0, amr: ['pwd'] });
  await assert.rejects(
    () => authenticateAccessToken(token, accessOptions(activeAdministrator(), null)),
    (error) => error.status === 401 && error.code === 'TOKEN_REVOKED',
  );
  await assert.rejects(
    () => authenticateAccessToken(token, accessOptions(activeAdministrator({ status: 'disabled' }))),
    (error) => error.status === 403 && error.code === 'ACCOUNT_DISABLED',
  );
  await assert.rejects(
    () => authenticateAccessToken(token, accessOptions(activeAdministrator({ roles: [] }))),
    (error) => error.status === 403 && error.code === 'ACCESS_DENIED',
  );
});

test('admin access authentication rejects missing MFA session state after enrollment', async () => {
  const token = adminToken({ sub: '1', sid: 'a'.repeat(32), typ: 'admin_access', ver: 0, amr: ['pwd'] });
  const administrator = activeAdministrator({
    mfaCredential: { enabledAt: new Date('2026-10-01T00:00:00.000Z'), disabledAt: null },
  });
  await assert.rejects(
    () => authenticateAccessToken(token, accessOptions(administrator)),
    (error) => error.status === 401 && error.code === 'TOKEN_REVOKED',
  );
});

test('audit detail sections remain restricted without each dedicated sub-permission', () => {
  const entry = {
    toJSON: () => ({
      id: 7,
      administratorId: 3,
      action: 'admin.users.updated',
      targetType: 'user',
      targetId: '9',
      oldValue: { email: 'before@example.test' },
      newValue: { email: 'after@example.test' },
      metadata: { internal: 'restricted' },
      ipAddress: '192.0.2.25',
      userAgent: 'restricted-agent',
      correlationId: 'request-12345678',
      createdAt: new Date('2026-10-12T00:00:00.000Z'),
    }),
  };
  const result = auditSerializers.details(
    entry,
    new Set(['auditLogs.details.view']),
    new Set(['changes', 'requestContext', 'metadata']),
  );
  assert.equal(result.changes, undefined);
  assert.equal(result.requestContext, undefined);
  assert.equal(result.metadata, undefined);
  assert.deepEqual(result.partialSections.sort(), ['changes', 'metadata', 'requestContext']);
});

test('audit detail sections are released only by their matching sub-permissions', () => {
  const entry = {
    toJSON: () => ({
      id: 7,
      action: 'admin.users.updated',
      oldValue: { status: 'active' },
      newValue: { status: 'suspended' },
      metadata: { outcome: 'success' },
      ipAddress: '192.0.2.25',
      correlationId: 'request-12345678',
      createdAt: new Date('2026-10-12T00:00:00.000Z'),
    }),
  };
  const permissions = new Set([
    'auditLogs.changes.view',
    'auditLogs.requestContext.view',
    'auditLogs.metadata.view',
  ]);
  const result = auditSerializers.details(entry, permissions, new Set(['all']));
  assert.equal(result.changes.length, 1);
  assert.equal(result.requestContext.ipAddress, '192.0.2.25');
  assert.deepEqual(result.metadata, { outcome: 'success' });
  assert.deepEqual(result.partialSections, []);
});

test('audit integrity and detail routes use dedicated permissions', () => {
  const source = fs.readFileSync(path.resolve(__dirname, '../src/routes/adminRoutes.js'), 'utf8');
  assert.match(source, /audit-logs\/verify-integrity[^\n]+auditLogs\.integrity\.view/);
  assert.match(source, /audit-logs\/:auditId[\s\S]{0,240}auditLogs\.details\.view/);
});

test('admin realtime fanout has no global room and revalidates sessions for delivery', () => {
  const source = fs.readFileSync(path.resolve(__dirname, '../src/realtime/realtimeHub.js'), 'utf8');
  assert.equal(source.includes("admin:all"), false);
  assert.match(source, /authenticateAccessToken\(socket\.data\.adminAccessToken\)/);
  assert.match(source, /access\.permissions\.has\(requiredPermission\)/);
  assert.match(source, /const access = await authenticateAccessToken\(rawToken\)/);
});

test('user realtime subscription is server-authorized and cannot select arbitrary user or admin rooms', () => {
  const source = fs.readFileSync(path.resolve(__dirname, '../src/realtime/realtimeHub.js'), 'utf8');
  assert.match(source, /conversationAccess\(conversationId, userId\)/);
  assert.match(source, /socket\.join\(userRoom\(userId\)\)/);
  assert.equal(source.includes("socket.join(value.room)"), false);
  assert.equal(source.includes("socket.join('admin:"), false);
});

test('password reset increments token version before refresh-token destruction', () => {
  const source = fs.readFileSync(path.resolve(__dirname, '../src/controllers/authController.js'), 'utf8');
  const resetBody = source.slice(source.indexOf('exports.resetPassword'), source.indexOf('exports.changePassword'));
  assert.match(resetBody, /user\.tokenVersion\s*=\s*Number\(user\.tokenVersion\s*\|\|\s*0\)\s*\+\s*1/);
  assert.ok(resetBody.indexOf('user.tokenVersion') < resetBody.indexOf('RefreshToken.destroy'));
});

test('production error responses do not expose status-500 SQL or stack details', () => {
  const prior = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';
  const marker = 'SQL password=secret stack-marker';
  let body;
  const response = {
    status(code) { this.statusCode = code; return this; },
    json(value) { body = value; return value; },
  };
  const originalConsole = console.log;
  console.log = () => {};
  try {
    errorHandler(Object.assign(new Error(marker), { status: 500 }), { originalUrl: '/api/example' }, response, () => {});
  } finally {
    console.log = originalConsole;
    if (prior === undefined) delete process.env.NODE_ENV; else process.env.NODE_ENV = prior;
  }
  assert.equal(response.statusCode, 500);
  assert.equal(JSON.stringify(body).includes(marker), false);
  assert.equal(body.code, 'INTERNAL_ERROR');
});

test('curated domain 5xx errors keep their safe code only when explicitly exposed', () => {
  const prior = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';
  const run = (error) => {
    let body;
    const response = { status(code) { this.statusCode = code; return this; }, json(value) { body = value; return value; } };
    const originalConsole = console.log;
    console.log = () => {};
    try { errorHandler(error, { originalUrl: '/api/example' }, response, () => {}); } finally { console.log = originalConsole; }
    return { status: response.statusCode, body };
  };
  try {
    const curated = run(Object.assign(new Error('Withdrawal could not be completed.'), { status: 500, code: 'WITHDRAWAL_PROCESSING_FAILED', expose: true }));
    assert.equal(curated.status, 500);
    assert.equal(curated.body.code, 'WITHDRAWAL_PROCESSING_FAILED');
    const unexposed = run(Object.assign(new Error('SQL secret detail'), { status: 500, code: 'ER_ACCESS_DENIED' }));
    assert.equal(unexposed.body.code, 'INTERNAL_ERROR');
    assert.equal(JSON.stringify(unexposed.body).includes('SQL secret detail'), false);
    const truthyNotTrue = run(Object.assign(new Error('SQL secret detail'), { status: 500, code: 'X', expose: 'yes' }));
    assert.equal(truthyNotTrue.body.code, 'INTERNAL_ERROR');
  } finally {
    if (prior === undefined) delete process.env.NODE_ENV; else process.env.NODE_ENV = prior;
  }
});

test('importing the mailer does not run full startup environment validation', () => {
  const { execFileSync } = require('node:child_process');
  const output = execFileSync(process.execPath, ['-e', "require('./src/config/mailer'); require('./src/utils/sendEmail'); console.log('ok')"], {
    cwd: path.resolve(__dirname, '..'),
    env: { PATH: process.env.PATH, SystemRoot: process.env.SystemRoot },
    encoding: 'utf8',
  });
  assert.equal(output.trim(), 'ok');
});
