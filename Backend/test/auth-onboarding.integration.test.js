const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Auth integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const verificationCode = '246810';
const otpModule = require.resolve('../src/utils/generateOtp');
const smsModule = require.resolve('../src/utils/sendSms');
require(otpModule);
require(smsModule);
require.cache[otpModule].exports = () => verificationCode;
require.cache[smsModule].exports = async () => {};

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server;
let baseUrl;
let models;
let user;
let accessToken;
let refreshToken;
let phoneNumber;
const uploadedFiles = [];

async function request(pathname, {
  method = 'GET',
  body,
  form,
  token = accessToken,
} = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    ...(form ? { body: form } : {}),
  });
  return { status: response.status, body: await response.json() };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  for (const filename of uploadedFiles) {
    await fs.unlink(path.join(__dirname, '..', 'uploads', 'onboarding-photos', filename)).catch(() => {});
  }
  if (models && user) {
    await models.RefreshToken.destroy({ where: { userId: user.id } });
    await models.OnboardingProfile.destroy({ where: { userId: user.id } });
    await models.OtpToken.destroy({ where: { phoneNumber } });
    await models.User.destroy({ where: { id: user.id } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('fresh account verifies, completes a persisted profile, reloads it, and logs out', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  phoneNumber = `+919${suffix.slice(-9)}`;
  const email = `fresh-${suffix}@auth-flow.test`;
  const password = 'ProductionPass123!';

  const signup = await request('/api/auth/signup', {
    method: 'POST',
    token: null,
    body: {
      name: 'Fresh Account',
      email,
      phoneNumber,
      password,
      confirmPassword: password,
      acceptedTerms: true,
    },
  });
  assert.equal(signup.status, 200);
  user = await models.User.findOne({ where: { email } });
  assert.ok(user);
  assert.equal(user.isVerified, false);

  const duplicatePhone = await request('/api/auth/signup', {
    method: 'POST',
    token: null,
    body: {
      name: 'Duplicate Phone',
      email: `other-${suffix}@auth-flow.test`,
      phoneNumber,
      password,
      confirmPassword: password,
      acceptedTerms: true,
    },
  });
  assert.equal(duplicatePhone.status, 409);
  assert.equal(duplicatePhone.body.code, 'PHONE_EXISTS');

  const beforeVerification = await request('/api/auth/login', {
    method: 'POST',
    token: null,
    body: { email, password },
  });
  assert.equal(beforeVerification.status, 403);

  const verification = await request('/api/auth/verify-account', {
    method: 'POST',
    token: null,
    body: { phoneNumber, code: verificationCode },
  });
  assert.equal(verification.status, 200);
  accessToken = verification.body.data.accessToken;
  refreshToken = verification.body.data.refreshToken;
  assert.ok(accessToken);
  assert.ok(refreshToken);

  const steps = [
    ['/api/onboarding/age', { birthDate: '1998-02-14' }],
    ['/api/onboarding/gender', { gender: 'Female' }],
    ['/api/onboarding/interested-in', { interestedIn: ['Male'] }],
    ['/api/onboarding/relationship-goal', { relationshipGoals: ['Long-Term Relationship'] }],
    ['/api/onboarding/location', { city: 'Ahmedabad', preferredDistance: 50 }],
    ['/api/onboarding/starter-profile', { profession: 'Engineer', company: 'AMORAA Test', education: 'Graduate' }],
    ['/api/onboarding/profile-completion', {
      bio: 'A freshly persisted profile used by the end-to-end integration test.',
      interests: ['Coffee', 'Music'],
      prompts: { 'A perfect day': 'Coffee and a walk.' },
      lifestyle: { Exercise: 'Often' },
      communicationStyle: 'calls',
    }],
  ];
  for (const [pathname, body] of steps) {
    const response = await request(pathname, { method: 'PUT', body });
    assert.equal(response.status, 200, `${pathname}: ${response.body.message}`);
  }

  const invalidForm = new FormData();
  invalidForm.append(
    'photos',
    new Blob([Uint8Array.from([1, 2, 3])], { type: 'image/png' }),
    'not-really-a-photo.png',
  );
  const invalidPhoto = await request('/api/onboarding/photos', {
    method: 'POST',
    form: invalidForm,
  });
  assert.equal(invalidPhoto.status, 400);
  assert.equal(invalidPhoto.body.code, 'INVALID_PHOTO_TYPE');

  const png = Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0]);
  const form = new FormData();
  form.append('photos', new Blob([png], { type: 'image/png' }), 'first.png');
  form.append('photos', new Blob([png], { type: 'image/png' }), 'second.png');
  const photos = await request('/api/onboarding/photos', { method: 'POST', form });
  assert.equal(photos.status, 200);
  const photoUrls = photos.body.data.onboarding.photos;
  assert.equal(photoUrls.length, 2);
  uploadedFiles.push(...photoUrls.map((url) => path.basename(url)));

  const completed = await request('/api/onboarding/complete', { method: 'POST' });
  assert.equal(completed.status, 200);
  assert.equal(completed.body.data.onboarding.onboardingCompleted, true);

  const update = await request('/api/me/profile', {
    method: 'PUT',
    body: { bio: 'Updated once and persisted to MySQL.', location: 'Gandhinagar' },
  });
  assert.equal(update.status, 200);
  const reload = await request('/api/me/profile');
  assert.equal(reload.status, 200);
  assert.equal(reload.body.data.profile.bio, 'Updated once and persisted to MySQL.');
  assert.equal(reload.body.data.profile.location, 'Gandhinagar');
  assert.deepEqual(
    reload.body.data.profile.photos.map((url) => new URL(url).pathname),
    photoUrls,
  );

  const logout = await request('/api/auth/logout', {
    method: 'POST',
    body: { refreshToken },
  });
  assert.equal(logout.status, 200);
  const refreshAfterLogout = await request('/api/auth/refresh-token', {
    method: 'POST',
    token: null,
    body: { refreshToken },
  });
  assert.equal(refreshAfterLogout.status, 401);
});
