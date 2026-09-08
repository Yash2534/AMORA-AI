const assert = require('node:assert/strict');
const { test } = require('node:test');
require('../src/config/bootstrapEnv');
const { configuredOrigins, isAllowedOrigin } = require('../src/config/originPolicy');
const { _parsed } = require('../src/services/platformSettingsService');
const { _json } = require('../src/controllers/roseController');
const { validateEnvironment } = require('../src/config/env');
const { sendAdminPasswordReset } = require('../src/services/adminPasswordMailer');

const productionEnv = () => ({ NODE_ENV: 'production', DB_HOST: 'db', DB_PORT: '3306', DB_NAME: 'db', DB_USER: 'user', JWT_SECRET: 'a'.repeat(32), JWT_REFRESH_SECRET: 'b'.repeat(32), ADMIN_JWT_SECRET: 'c'.repeat(32), ADMIN_MFA_ENCRYPTION_KEY: 'd'.repeat(64), EMAIL_HOST: 'smtp.example', EMAIL_USER: 'user', EMAIL_PASS: 'pass' });

test('production startup keeps SMTP mandatory but does not require admin reset URL or CORS origin', () => {
  assert.doesNotThrow(() => validateEnvironment(productionEnv()));
  for (const key of ['EMAIL_HOST', 'EMAIL_USER', 'EMAIL_PASS']) {
    const env = productionEnv(); delete env[key];
    assert.throws(() => validateEnvironment(env), /EMAIL_HOST, EMAIL_USER, and EMAIL_PASS/);
  }
});

test('production validates optional admin reset URL and preserves OTP production guards', () => {
  const insecure = productionEnv(); insecure.ADMIN_WEB_RESET_URL = 'http://admin.example/reset';
  assert.throws(() => validateEnvironment(insecure), /ADMIN_WEB_RESET_URL/);
  const secure = productionEnv(); secure.ADMIN_WEB_RESET_URL = 'https://admin.example/reset';
  assert.doesNotThrow(() => validateEnvironment(secure));
  const unsafeOtp = productionEnv(); unsafeOtp.TEST_FIXED_OTP = '111111';
  assert.throws(() => validateEnvironment(unsafeOtp), /Production must not configure/);
});

test('administrator reset fails closed when no reset URL is configured', async () => {
  const previous = { NODE_ENV: process.env.NODE_ENV, ADMIN_WEB_RESET_URL: process.env.ADMIN_WEB_RESET_URL };
  process.env.NODE_ENV = 'production'; delete process.env.ADMIN_WEB_RESET_URL;
  await assert.rejects(() => sendAdminPasswordReset({ email: 'admin@example.test', token: 'token', expiresAt: new Date() }), /ADMIN_WEB_RESET_URL/);
  Object.assign(process.env, previous);
});

test('production origin policy permits native requests and fails closed for untrusted browser origins', () => {
  const env = { NODE_ENV: 'production' };
  assert.deepEqual(configuredOrigins(env), []);
  assert.equal(isAllowedOrigin('https://evil.example', env), false);
});

test('production origin policy rejects wildcard and HTTP origins and accepts explicit HTTPS origins', () => {
  assert.throws(() => configuredOrigins({ NODE_ENV: 'production', CORS_ORIGIN: '*' }), /wildcard/);
  assert.throws(() => configuredOrigins({ NODE_ENV: 'production', CORS_ORIGIN: 'http://admin.example' }), /HTTPS/);
  const env = { NODE_ENV: 'production', CORS_ORIGIN: 'https://admin.example, https://web.example' };
  assert.deepEqual(configuredOrigins(env), ['https://admin.example', 'https://web.example']);
  assert.equal(isAllowedOrigin('https://admin.example', env), true);
});

test('persisted platform setting values normalize booleans and emails', () => {
  assert.equal(_parsed({ key: 'maintenance_mode_enabled', value: '1' }), true);
  assert.equal(_parsed({ key: 'maintenance_mode_enabled', value: 'false' }), false);
  assert.equal(_parsed({ key: 'registration_enabled', value: 0 }), false);
  assert.equal(_parsed({ key: 'support_email', value: null }), '');
  assert.equal(_parsed({ key: 'support_email', value: '"support@example.test"' }), 'support@example.test');
});

test('rose retry classification retries only lock failures', () => {
  assert.equal(_json.isRetryableTransactionError({ code: 'ER_LOCK_DEADLOCK' }), true);
  assert.equal(_json.isRetryableTransactionError({ errno: 1205 }), true);
  assert.equal(_json.isRetryableTransactionError({ code: 'ER_DUP_ENTRY' }), false);
});

test('rose transaction retry retries bounded lock failures and immediately propagates others', async () => {
  let attempts = 0;
  const result = await _json.withTransactionRetry(async () => {
    attempts += 1;
    if (attempts < 3) throw Object.assign(new Error('locked'), { errno: 1213 });
    return 'ok';
  });
  assert.equal(result, 'ok');
  assert.equal(attempts, 3);
  await assert.rejects(() => _json.withTransactionRetry(async () => { throw Object.assign(new Error('no'), { code: 'ER_DUP_ENTRY' }); }), /no/);
});
