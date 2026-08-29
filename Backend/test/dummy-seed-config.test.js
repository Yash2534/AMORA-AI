const test = require('node:test');
const assert = require('node:assert/strict');
const { resolveDummySeedConfig } = require('../scripts/dummy-seed/config');

const validEnv = {
  NODE_ENV: 'development', ALLOW_DUMMY_SEED: 'true', DB_NAME: 'amora_ai_test',
  DUMMY_SEED_DATABASES: 'amora_ai,amora_ai_test', SEED_USER_COUNT: '50',
  SEED_RANDOM_SEED: '12345', SEED_REFERENCE_DATE: '2026-08-29', SEED_TEST_PASSWORD: 'safe-development-password',
};

test('dummy seed config accepts an explicitly approved development database', () => {
  const config = resolveDummySeedConfig(validEnv, ['--confirm-development-db']);
  assert.equal(config.databaseName, 'amora_ai_test');
  assert.equal(config.userCount, 50);
  assert.equal(config.mode, 'seed');
});

test('dummy seed config always blocks production', () => {
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, NODE_ENV: 'production' }, ['--confirm-development-db']), /blocked in production/);
});

test('dummy seed config requires the opt-in, allowlist, and confirmation', () => {
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, ALLOW_DUMMY_SEED: 'false' }, ['--confirm-development-db']), /ALLOW_DUMMY_SEED/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, DUMMY_SEED_DATABASES: 'another_database' }, ['--confirm-development-db']), /explicitly listed/);
  assert.throws(() => resolveDummySeedConfig(validEnv, []), /confirm-development-db/);
});

test('dummy seed config validates count, reproducibility date, and password', () => {
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, SEED_USER_COUNT: '19' }, ['--confirm-development-db']), /SEED_USER_COUNT/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, SEED_REFERENCE_DATE: 'not-a-date' }, ['--confirm-development-db']), /SEED_REFERENCE_DATE/);
  assert.throws(() => resolveDummySeedConfig({ ...validEnv, SEED_TEST_PASSWORD: 'short' }, ['--confirm-development-db']), /SEED_TEST_PASSWORD/);
});
