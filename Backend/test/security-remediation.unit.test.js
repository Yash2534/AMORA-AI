const assert = require('node:assert/strict');
const { test } = require('node:test');
const cors = require('cors');

const { configuredOrigins, corsOrigin } = require('../src/config/originPolicy');
const { developmentSeedConfig } = require('../src/config/seedDefaultAdmin');
const logger = require('../src/utils/logger');
const { adultBirthDate } = require('../src/policies/agePolicy');
const { filenameFromReference, protectedPath } = require('../src/utils/photoStorage');
const { ttlMinutes } = require('../src/services/privacyExportArtifactService');
const { coarseDistanceKm } = require('../src/services/publicProfileService');
const { resolveTrustProxy } = require('../src/config/trustProxy');
const { databaseDialectOptions } = require('../src/config/db');
const { databaseName } = require('../src/migrations/run');
const { sanitize: sanitizeAudit } = require('../src/services/adminAuditService');
const { classifySecurityEvent, deviceReference } = require('../src/middleware/securityEventMiddleware')._test;

function preflight(origin, env) {
  return new Promise((resolve, reject) => {
    const headers = {};
    const request = {
      method: 'OPTIONS',
      headers: {
        origin,
        'access-control-request-method': 'GET',
      },
    };
    const response = {
      statusCode: 200,
      setHeader: (name, value) => { headers[name.toLowerCase()] = value; },
      getHeader: (name) => headers[name.toLowerCase()],
      removeHeader: (name) => { delete headers[name.toLowerCase()]; },
      end: () => resolve({ status: response.statusCode, headers }),
    };
    cors({ origin: (value, callback) => corsOrigin(value, callback, env) })(
      request,
      response,
      (error) => (error ? reject(error) : resolve({ status: response.statusCode, headers })),
    );
  });
}

test('development administrator seed requires explicit development-only credentials', () => {
  assert.equal(developmentSeedConfig({ NODE_ENV: 'production', DEV_ADMIN_SEED_EMAIL: 'admin@example.test', DEV_ADMIN_SEED_PASSWORD: 'NeverUsedPassword!' }), null);
  assert.equal(developmentSeedConfig({ NODE_ENV: 'development' }), null);
  assert.throws(() => developmentSeedConfig({ NODE_ENV: 'development', DEV_ADMIN_SEED_EMAIL: 'admin@example.test', DEV_ADMIN_SEED_PASSWORD: 'short' }), /14 characters/);
  assert.deepEqual(developmentSeedConfig({ NODE_ENV: 'development', DEV_ADMIN_SEED_EMAIL: 'Admin@Example.Test', DEV_ADMIN_SEED_PASSWORD: 'ExplicitPassword!' }), { email: 'admin@example.test', password: 'ExplicitPassword!' });
});

test('recursive logger redacts credentials, tokens, MFA data, cookies, and identity numbers', () => {
  const marker = 'security-marker-value';
  const sanitized = logger.sanitizeValue({
    nested: [{ password: marker }, { authorization: `Bearer ${marker}` }],
    cookie: marker,
    apiKey: marker,
    refresh_token: marker,
    accessToken: marker,
    mfaSecret: marker,
    identityDocumentNumber: marker,
  });
  assert.equal(JSON.stringify(sanitized).includes(marker), false);
});

test('logger output never includes a supplied credential value', () => {
  const marker = 'credential-never-log-9f4d';
  const original = console.log;
  const output = [];
  console.log = (...args) => output.push(JSON.stringify(args));
  try { logger.info('seed result', { password: marker, token: marker }); } finally { console.log = original; }
  assert.equal(output.join('').includes(marker), false);
});

test('administrator audit metadata recursively redacts sensitive fields and raw identity numbers', () => {
  const marker = 'audit-sensitive-marker';
  const output = sanitizeAudit({ nested: [{ refreshToken: marker }], documentNumber: marker, note: `identity 123456789012` });
  assert.equal(JSON.stringify(output).includes(marker), false);
  assert.equal(JSON.stringify(output).includes('123456789012'), false);
});

test('security-event classifier covers critical lifecycle events without copying request bodies', () => {
  const request = (method, originalUrl, body = {}) => ({ method, originalUrl, body, headers: {} });
  assert.equal(classifySecurityEvent(request('POST', '/api/auth/logout'), 200).action, 'user.auth.logout');
  assert.equal(classifySecurityEvent(request('POST', '/api/auth/verify-account', { code: '123456' }), 400).metadata.outcome, 'failed');
  assert.equal(classifySecurityEvent(request('POST', '/api/account/delete/confirm', { otp: '123456' }), 200).action, 'user.account.deleted');
  assert.equal(classifySecurityEvent(request('POST', '/api/account/deactivate', { password: 'not-recorded' }), 401).metadata.intendedAction, 'user.account.deactivated');
  assert.equal(classifySecurityEvent(request('POST', '/api/account/phone-change/request', { providerIdToken: 'not-recorded' }), 200).action, 'user.phone.change_requested');
  assert.equal(classifySecurityEvent(request('POST', '/api/account/phone-change/confirm', { code: '123456' }), 400).action, 'user.phone.change_confirmed');
  assert.equal(classifySecurityEvent(request('POST', '/api/privacy-requests/42/export'), 200).targetId, '42');
  assert.equal(classifySecurityEvent(request('POST', '/api/reports'), 201).action, 'user.safety.report_submitted');
  assert.equal(classifySecurityEvent(request('DELETE', '/api/blocks/8'), 200).action, 'user.safety.user_unblocked');
  assert.equal(classifySecurityEvent(request('POST', '/api/identity-verification/submissions'), 202).action, 'user.identity.submitted');
  assert.equal(JSON.stringify(classifySecurityEvent(request('POST', '/api/auth/verify-account', { code: '123456' }), 400)).includes('123456'), false);
  assert.equal(JSON.stringify(classifySecurityEvent(request('POST', '/api/account/phone-change/request', { providerIdToken: 'not-recorded' }), 200)).includes('not-recorded'), false);
});

test('security-event classifier records rate limits and denied sensitive/admin access', () => {
  const request = (method, originalUrl) => ({ method, originalUrl, headers: {} });
  assert.equal(classifySecurityEvent(request('POST', '/api/auth/login'), 429).action, 'security.rate_limit_triggered');
  assert.equal(classifySecurityEvent(request('GET', '/api/privacy-requests/7'), 401).action, 'security.sensitive_access_denied');
  assert.equal(classifySecurityEvent(request('PATCH', '/api/admin/v1/system-settings'), 403).action, 'security.admin_access_denied');
  assert.equal(classifySecurityEvent(request('PATCH', '/api/admin/v1/system-settings'), 200).action, 'admin.sensitive_action_completed');
  assert.equal(classifySecurityEvent(request('GET', '/api/admin/v1/media/11'), 200).action, 'admin.sensitive_data_accessed');
});

test('security-event device references are bounded one-way hashes', () => {
  const raw = 'device-secret-reference';
  const reference = deviceReference({ headers: { 'x-device-id': raw } });
  assert.equal(reference.length, 24);
  assert.equal(reference.includes(raw), false);
  assert.equal(deviceReference({ headers: {} }), null);
});

test('production CORS permits listed HTTPS and rejects HTTP, wildcard, and unlisted origins', () => {
  const env = { NODE_ENV: 'production', CORS_ORIGIN: 'https://admin.example' };
  assert.deepEqual(configuredOrigins(env), ['https://admin.example']);
  assert.throws(() => configuredOrigins({ NODE_ENV: 'production', CORS_ORIGIN: 'http://admin.example' }), /HTTPS/);
  assert.throws(() => configuredOrigins({ NODE_ENV: 'production', CORS_ORIGIN: '*' }), /wildcard/);
  corsOrigin('https://admin.example', (error, value) => { assert.equal(error, null); assert.equal(value, 'https://admin.example'); }, env);
  corsOrigin('https://unlisted.example', (error, value) => { assert.equal(error, null); assert.equal(value, false); }, env);
});

test('production CORS preflight emits allow headers only for the listed HTTPS origin', async () => {
  const env = { NODE_ENV: 'production', CORS_ORIGIN: 'https://admin.example' };
  const allowed = await preflight('https://admin.example', env);
  assert.equal(allowed.status, 204);
  assert.equal(allowed.headers['access-control-allow-origin'], 'https://admin.example');

  const httpOrigin = await preflight('http://admin.example', env);
  assert.equal(httpOrigin.status, 200);
  assert.equal(httpOrigin.headers['access-control-allow-origin'], undefined);

  const unlisted = await preflight('https://unlisted.example', env);
  assert.equal(unlisted.status, 200);
  assert.equal(unlisted.headers['access-control-allow-origin'], undefined);
});

test('age policy enforces exact UTC birthday boundary and rejects invalid dates', () => {
  const today = new Date('2026-10-09T12:00:00.000Z');
  assert.equal(adultBirthDate('2008-10-09', today).allowed, true);
  assert.deepEqual(adultBirthDate('2008-10-10', today), { allowed: false, reason: 'UNDER_18' });
  assert.deepEqual(adultBirthDate('2027-01-01', today), { allowed: false, reason: 'FUTURE_DATE' });
  assert.deepEqual(adultBirthDate('2008-02-30', today), { allowed: false, reason: 'INVALID_DATE' });
  assert.deepEqual(adultBirthDate('not-a-date', today), { allowed: false, reason: 'INVALID_DATE' });
});

test('profile media references are reduced to safe basenames and protected routes', () => {
  assert.equal(filenameFromReference('../secret.txt'), null);
  assert.equal(filenameFromReference('/uploads/onboarding-photos/1-safe.jpg'), '1-safe.jpg');
  assert.equal(filenameFromReference('/uploads/legacy-safe.jpg'), 'legacy-safe.jpg');
  assert.equal(protectedPath(7, 'profile-media/1-safe.jpg'), '/api/media/profile/7/1-safe.jpg');
  assert.equal(protectedPath(undefined, 'profile-media/1-safe.jpg'), null);
  assert.equal(protectedPath('not-an-id', 'profile-media/1-safe.jpg'), null);
});

test('public distance is quantized and exact coordinates are not serialized by the helper', () => {
  assert.equal(coarseDistanceKm(0.4), 5);
  assert.equal(coarseDistanceKm(5.1), 10);
  assert.equal(coarseDistanceKm(12.2), 15);
  assert.equal(coarseDistanceKm(null), null);
});

test('privacy export TTL is bounded to fifteen minutes through one day', () => {
  assert.equal(ttlMinutes({ PRIVACY_EXPORT_TTL_MINUTES: '15' }), 15);
  assert.equal(ttlMinutes({ PRIVACY_EXPORT_TTL_MINUTES: '1440' }), 1440);
  assert.equal(ttlMinutes({ PRIVACY_EXPORT_TTL_MINUTES: '99999' }), 1440);
});

test('trusted proxy configuration fails closed and accepts only bounded explicit hops', () => {
  assert.equal(resolveTrustProxy({}), false);
  assert.equal(resolveTrustProxy({ TRUST_PROXY_HOPS: '1' }), 1);
  assert.equal(resolveTrustProxy({ TRUST_PROXY_HOPS: '0' }), false);
  assert.throws(() => resolveTrustProxy({ TRUST_PROXY_HOPS: 'all' }), /integer/);
  assert.throws(() => resolveTrustProxy({ TRUST_PROXY_HOPS: '4' }), /integer/);
});

test('production database configuration requires verified TLS material', () => {
  assert.deepEqual(databaseDialectOptions({ NODE_ENV: 'development' }), {});
  assert.throws(() => databaseDialectOptions({ NODE_ENV: 'production' }), /DB_SSL_CA_FILE/);
});

test('test database operations require NODE_ENV=test and a test-only database name', () => {
  assert.equal(
    databaseName('amoraa_security_test', { NODE_ENV: 'test', TEST_DB_NAME: 'amoraa_security_test' }),
    'amoraa_security_test',
  );
  assert.throws(
    () => databaseName('amoraa_security_test', { NODE_ENV: 'development', TEST_DB_NAME: 'amoraa_security_test' }),
    /NODE_ENV=test/,
  );
  assert.throws(
    () => databaseName('amoraa', { NODE_ENV: 'test', TEST_DB_NAME: 'amoraa_security_test' }),
    /containing "test"/,
  );
  assert.equal(databaseName('amoraa', { NODE_ENV: 'development' }), 'amoraa');
});
