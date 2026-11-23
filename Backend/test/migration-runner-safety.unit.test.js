const assert = require('node:assert/strict');
const { test } = require('node:test');

const { validateTestMigrationSafety } = require('../src/migrations/run');

function validTestEnv(overrides = {}) {
  return {
    NODE_ENV: 'test',
    DB_HOST: '127.0.0.1',
    DB_NAME: 'amora_ai_test',
    TEST_DB_NAME: 'amora_ai_test',
    APPLICATION_DB_NAME: 'amora_ai',
    ...overrides,
  };
}

test('valid local test database configuration passes', () => {
  for (const host of ['127.0.0.1', 'localhost', '::1']) {
    const env = validTestEnv({ DB_HOST: host });
    assert.equal(
      validateTestMigrationSafety('amora_ai_test', env),
      'amora_ai_test',
    );
  }
});

test('missing TEST_DB_NAME fails closed', () => {
  const env = validTestEnv();
  delete env.TEST_DB_NAME;
  assert.throws(
    () => validateTestMigrationSafety('amora_ai_test', env),
    /TEST_MIGRATION_BLOCKED.*TEST_DB_NAME/,
  );
});

test('test database equal to the development/application database fails closed', () => {
  const env = validTestEnv({
    DB_NAME: 'amora_ai_test',
    TEST_DB_NAME: 'amora_ai_test',
    APPLICATION_DB_NAME: 'amora_ai_test',
  });
  assert.throws(
    () => validateTestMigrationSafety('amora_ai_test', env),
    /TEST_MIGRATION_BLOCKED.*differ/,
  );
});

test('database name without test fails closed', () => {
  const env = validTestEnv({
    TEST_DB_NAME: 'amora_database',
  });
  assert.throws(
    () => validateTestMigrationSafety('amora_database', env),
    /TEST_MIGRATION_BLOCKED.*contain "test"/,
  );
});

test('migration database must match the configured test database', () => {
  const env = validTestEnv();
  assert.throws(
    () => validateTestMigrationSafety('another_test_database', env),
    /TEST_MIGRATION_BLOCKED.*match TEST_DB_NAME/,
  );
});

test('non-loopback database host fails closed', () => {
  const env = validTestEnv({ DB_HOST: 'db.production.internal' });
  assert.throws(
    () => validateTestMigrationSafety('amora_ai_test', env),
    /TEST_MIGRATION_BLOCKED.*loopback/,
  );
});

test('missing or incorrect NODE_ENV fails closed', () => {
  for (const nodeEnv of [undefined, 'development', 'production']) {
    const env = validTestEnv();
    if (nodeEnv === undefined) delete env.NODE_ENV;
    else env.NODE_ENV = nodeEnv;
    assert.throws(
      () => validateTestMigrationSafety('amora_ai_test', env),
      /TEST_MIGRATION_BLOCKED.*NODE_ENV=test/,
    );
  }
});

test('attempted production database configuration fails closed', () => {
  const env = validTestEnv({
    NODE_ENV: 'production',
    DB_HOST: 'primary-db.example.internal',
    DB_NAME: 'amora_ai',
    TEST_DB_NAME: 'amora_ai_test',
  });
  assert.throws(
    () => validateTestMigrationSafety('amora_ai', env),
    /TEST_MIGRATION_BLOCKED/,
  );
});
