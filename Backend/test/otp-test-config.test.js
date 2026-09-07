const assert = require('node:assert/strict');
const { test } = require('node:test');

const {
  matchesFixedOtp,
  resolveOtpTestConfig,
} = require('../src/config/otpTestConfig');

const enabledTestEnvironment = {
  NODE_ENV: 'test',
  TEST_FIXED_OTP_ENABLED: 'true',
  TEST_FIXED_OTP: '111111',
  TEST_OTP_SKIP_DELIVERY: 'true',
};

test('approved test configuration accepts only the configured fixed OTP', () => {
  const config = resolveOtpTestConfig(enabledTestEnvironment);
  assert.equal(config.enabled, true);
  assert.equal(config.skipDelivery, true);
  assert.equal(matchesFixedOtp('111111', enabledTestEnvironment), true);
  assert.equal(matchesFixedOtp('123456', enabledTestEnvironment), false);
});

test('production gives the fixed OTP no special treatment when disabled', () => {
  const production = {
    NODE_ENV: 'production',
    TEST_FIXED_OTP_ENABLED: 'false',
    TEST_FIXED_OTP: '',
    TEST_OTP_SKIP_DELIVERY: 'false',
  };
  assert.equal(resolveOtpTestConfig(production).enabled, false);
  assert.equal(matchesFixedOtp('111111', production), false);
});

test('production permits a clean environment with no test OTP configuration', () => {
  const production = { NODE_ENV: 'production' };
  const config = resolveOtpTestConfig(production);

  assert.equal(config.enabled, false);
  assert.equal(config.fixedOtp, '');
  assert.equal(config.skipDelivery, false);
  assert.equal(matchesFixedOtp('111111', production), false);
});

test('production fails closed when fixed OTP mode is configured', () => {
  assert.throws(
    () => resolveOtpTestConfig({
      NODE_ENV: 'production',
      TEST_FIXED_OTP_ENABLED: 'true',
      TEST_FIXED_OTP: '111111',
      TEST_OTP_SKIP_DELIVERY: 'true',
    }),
    /Production must not configure/,
  );
});

test('production fails closed for each unsafe test OTP variable independently', () => {
  const unsafeConfigurations = [
    { TEST_FIXED_OTP_ENABLED: ' true ' },
    { TEST_FIXED_OTP: '111111' },
    { TEST_OTP_SKIP_DELIVERY: 'true' },
  ];

  for (const unsafeConfiguration of unsafeConfigurations) {
    assert.throws(
      () => resolveOtpTestConfig({ NODE_ENV: 'production', ...unsafeConfiguration }),
      /Production must not configure/,
    );
  }
});

test('enabled test OTP configuration validates environment, format, and delivery dependency', () => {
  assert.throws(
    () => resolveOtpTestConfig({
      TEST_FIXED_OTP_ENABLED: 'true',
      TEST_FIXED_OTP: '111111',
    }),
    /not permitted.*unset/,
  );
  assert.throws(
    () => resolveOtpTestConfig({
      NODE_ENV: 'production',
      TEST_FIXED_OTP_ENABLED: '1',
    }),
    /must be either true or false/,
  );
  assert.throws(
    () => resolveOtpTestConfig({
      NODE_ENV: 'preview',
      TEST_FIXED_OTP_ENABLED: 'true',
      TEST_FIXED_OTP: '111111',
    }),
    /not permitted/,
  );
  assert.throws(
    () => resolveOtpTestConfig({
      NODE_ENV: 'test',
      TEST_FIXED_OTP_ENABLED: 'true',
      TEST_FIXED_OTP: '11111a',
    }),
    /exactly six numeric digits/,
  );
  assert.throws(
    () => resolveOtpTestConfig({
      NODE_ENV: 'test',
      TEST_FIXED_OTP_ENABLED: 'false',
      TEST_FIXED_OTP: '',
      TEST_OTP_SKIP_DELIVERY: 'true',
    }),
    /requires TEST_FIXED_OTP_ENABLED=true/,
  );
});

test('a configured value is inert unless fixed OTP mode is explicitly enabled', () => {
  const disabled = {
    NODE_ENV: 'development',
    TEST_FIXED_OTP_ENABLED: 'false',
    TEST_FIXED_OTP: '111111',
    TEST_OTP_SKIP_DELIVERY: 'false',
  };
  assert.equal(resolveOtpTestConfig(disabled).enabled, false);
  assert.equal(matchesFixedOtp('111111', disabled), false);
});
