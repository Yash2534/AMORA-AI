const assert = require('node:assert/strict');
const { afterEach, test } = require('node:test');

const smsPath = require.resolve('../src/utils/sendSms');
const emailPath = require.resolve('../src/utils/sendEmail');
const mailerPath = require.resolve('../src/config/mailer');
const originalMailerModule = require.cache[mailerPath];
const originalEnvironment = Object.fromEntries(
  ['NODE_ENV', 'SMS_PROVIDER', 'TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN', 'TWILIO_FROM_NUMBER']
    .map((key) => [key, process.env[key]]),
);

function restoreEnvironment() {
  for (const [key, value] of Object.entries(originalEnvironment)) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
}

afterEach(() => {
  restoreEnvironment();
  if (originalMailerModule) require.cache[mailerPath] = originalMailerModule;
  else delete require.cache[mailerPath];
  delete require.cache[emailPath];
});

test('production SMS delivery fails without configuration and never logs the OTP', async () => {
  process.env.NODE_ENV = 'production';
  delete process.env.SMS_PROVIDER;
  delete process.env.TWILIO_ACCOUNT_SID;
  delete process.env.TWILIO_AUTH_TOKEN;
  delete process.env.TWILIO_FROM_NUMBER;
  const sendSms = require(smsPath);
  const logged = [];
  const originalLog = console.log;
  console.log = (...args) => logged.push(args);

  try {
    await assert.rejects(
      () => sendSms('+919876543210', 'Your verification code is 246810.', { code: '246810' }),
      /SMS is not configured/,
    );
  } finally {
    console.log = originalLog;
  }

  assert.deepEqual(logged, []);
});

test('production email delivery fails without configuration and never logs the OTP', async () => {
  process.env.NODE_ENV = 'production';
  require.cache[mailerPath] = {
    id: mailerPath,
    filename: mailerPath,
    loaded: true,
    exports: { getTransport: () => null },
  };
  delete require.cache[emailPath];
  const sendEmail = require(emailPath);
  const logged = [];
  const originalLog = console.log;
  console.log = (...args) => logged.push(args);

  try {
    await assert.rejects(
      () => sendEmail('member@example.com', 'Verification', '246810', { code: '246810' }),
      /Email is not configured/,
    );
  } finally {
    console.log = originalLog;
  }

  assert.deepEqual(logged, []);
});
