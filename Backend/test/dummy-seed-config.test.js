const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { resolveDummySeedConfig } = require('../scripts/dummy-seed/config');

const testPassword = 'runtime-demo-password';
const options = { expectedDemoPasswordHash: crypto.createHash('sha256').update(testPassword).digest('hex') };

const validEnv = {
  NODE_ENV: 'development', ALLOW_DUMMY_SEED: 'true', DB_NAME: 'amora_ai_test',
  DUMMY_SEED_DATABASES: 'amora_ai,amora_ai_test', AMORAA_DEMO_USER_COUNT: '25',
  SEED_RANDOM_SEED: '12345', SEED_REFERENCE_DATE: '2026-08-29', AMORAA_DEMO_PASSWORD: testPassword,
};

test('dummy seed config accepts an explicitly approved development database', () => {
  const config = resolveDummySeedConfig(validEnv, ['--confirm-development-db'], options);
  assert.equal(config.databaseName, 'amora_ai_test');
  assert.equal(config.userCount, 25);
  assert.equal(config.demoEmail, 'demo.walkthrough@amoraa.test');
  assert.equal(config.mode, 'seed');
  assert.equal(resolveDummySeedConfig(validEnv, ['--confirm-development-db', '--reset'], options).mode, 'reset');
});

test('dummy seed config always blocks production', () => {
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, NODE_ENV: 'production' }, ['--confirm-development-db'], options), /blocked in production/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, DB_NAME: 'amora_ai_prod' }, ['--confirm-development-db'], options), /production-like database names/);
});

test('dummy seed config requires the opt-in, allowlist, and confirmation', () => {
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, ALLOW_DUMMY_SEED: 'false' }, ['--confirm-development-db'], options), /ALLOW_DUMMY_SEED/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, DUMMY_SEED_DATABASES: 'another_database' }, ['--confirm-development-db'], options), /explicitly listed/);
  assert.throws(() => resolveDummySeedConfig(validEnv, [], options), /confirm-development-db/);
});

test('dummy seed config validates count, reproducibility date, and password', () => {
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, AMORAA_DEMO_USER_COUNT: '24' }, ['--confirm-development-db'], options), /AMORAA_DEMO_USER_COUNT/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, SEED_REFERENCE_DATE: 'not-a-date' }, ['--confirm-development-db'], options), /SEED_REFERENCE_DATE/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, AMORAA_DEMO_PASSWORD: 'wrong' }, ['--confirm-development-db'], options), /AMORAA_DEMO_PASSWORD/);
});
