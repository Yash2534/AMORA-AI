const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_auth_onboarding`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Auth integration tests require an isolated TEST_DB_NAME containing "test".');
}
const originalEnvironment = Object.fromEntries(
  ['DB_NAME', 'NODE_ENV', 'TEST_FIXED_OTP_ENABLED', 'TEST_FIXED_OTP', 'TEST_OTP_SKIP_DELIVERY']
    .map((key) => [key, process.env[key]]),
);
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
process.env.TEST_FIXED_OTP_ENABLED = 'true';
process.env.TEST_FIXED_OTP = '111111';
process.env.TEST_OTP_SKIP_DELIVERY = 'false';

const verificationCode = '246810';
const otpModule = require.resolve('../src/utils/generateOtp');
const smsModule = require.resolve('../src/utils/sendSms');
const emailModule = require.resolve('../src/utils/sendEmail');
require(otpModule);
require(smsModule);
require(emailModule);
const originalOtpExport = require.cache[otpModule].exports;
const originalSmsExport = require.cache[smsModule].exports;
const originalEmailExport = require.cache[emailModule].exports;
require.cache[otpModule].exports = () => verificationCode;
let smsDeliveryFailure = false;
require.cache[smsModule].exports = async () => {
  if (smsDeliveryFailure) throw new Error('SMS provider delivery failed.');
};
const sentEmails = [];
let emailDeliveryFailure = false;
require.cache[emailModule].exports = async (to, subject, html, meta) => {
  if (emailDeliveryFailure) throw new Error('Email provider delivery failed.');
  sentEmails.push({ to, subject, html, meta });
};

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
let email;
let secondaryUser;
let secondaryPhoneNumber;
let termsDocument;
let privacyDocument;
const uploadedFiles = [];
const legalDocumentIds = [];
const deliveryFailureUserIds = [];
const deliveryFailureEmails = [];
const deliveryFailurePhones = [];
const documentHash = (value) => crypto.createHash('sha256').update(value).digest('hex');
const signupLegalDocuments = () => [
  { documentKey: 'TERMS_OF_SERVICE', documentVersionId: termsDocument.id },
  { documentKey: 'PRIVACY_POLICY', documentVersionId: privacyDocument.id },
];

async function request(pathname, {
  method = 'GET',
  body,
  form,
  token = accessToken,
  forwardedFor,
} = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
      ...(forwardedFor ? { 'x-forwarded-for': forwardedFor } : {}),
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
  const now = new Date(Date.now() - 1000);
  termsDocument = await models.LegalDocumentVersion.create({
    documentKey: 'TERMS_OF_SERVICE',
    version: `auth-test-${Date.now()}`,
    contentHash: documentHash('auth onboarding test terms'),
    publishedAt: now,
    effectiveAt: now,
    status: 'ACTIVE',
  });
  privacyDocument = await models.LegalDocumentVersion.create({
    documentKey: 'PRIVACY_POLICY',
    version: `auth-test-${Date.now()}`,
    contentHash: documentHash('auth onboarding test privacy'),
    publishedAt: now,
    effectiveAt: now,
    status: 'ACTIVE',
  });
  legalDocumentIds.push(termsDocument.id, privacyDocument.id);
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
    await models.ConsentEvent.destroy({ where: { userId: user.id } });
    await models.RefreshToken.destroy({ where: { userId: user.id } });
    await models.OnboardingProfile.destroy({ where: { userId: user.id } });
    await models.OtpToken.destroy({ where: { phoneNumber } });
    await models.OtpToken.destroy({ where: { email } });
    await models.User.destroy({ where: { id: user.id } });
  }
  if (models && secondaryUser) {
    await models.ConsentEvent.destroy({ where: { userId: secondaryUser.id } });
    await models.RefreshToken.destroy({ where: { userId: secondaryUser.id } });
    await models.OnboardingProfile.destroy({ where: { userId: secondaryUser.id } });
    await models.OtpToken.destroy({ where: { phoneNumber: secondaryPhoneNumber } });
    await models.User.destroy({ where: { id: secondaryUser.id } });
  }
  if (models && deliveryFailureUserIds.length) {
    await models.ConsentEvent.destroy({ where: { userId: deliveryFailureUserIds } });
    await models.RefreshToken.destroy({ where: { userId: deliveryFailureUserIds } });
    await models.OtpToken.destroy({ where: { phoneNumber: deliveryFailurePhones } });
    await models.OtpToken.destroy({ where: { email: deliveryFailureEmails } });
    await models.User.destroy({ where: { id: deliveryFailureUserIds } });
  }
  if (models) await models.LegalDocumentVersion.destroy({ where: { id: legalDocumentIds } });
  try { await getSequelize().close(); } catch (_) {}
  require.cache[otpModule].exports = originalOtpExport;
  require.cache[smsModule].exports = originalSmsExport;
  require.cache[emailModule].exports = originalEmailExport;
  for (const [key, value] of Object.entries(originalEnvironment)) {
    if (value === undefined) delete process.env[key]; else process.env[key] = value;
  }
});

test('registration provider failure rolls back the account and returns a safe delivery failure', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const failedEmail = `delivery-failure-${suffix}@auth-flow.test`;
  const failedPhone = `+917${suffix.slice(-9)}`;
  smsDeliveryFailure = true;
  try {
    const response = await request('/api/auth/signup', {
      method: 'POST',
      token: null,
      body: {
        name: 'Delivery Failure',
        email: failedEmail,
        phoneNumber: failedPhone,
        password: 'ProviderFailure123!',
        confirmPassword: 'ProviderFailure123!',
        acceptedTerms: true,
        acceptedLegalDocuments: signupLegalDocuments(),
        platform: 'WEB',
      },
    });
    assert.equal(response.status, 503);
    assert.equal(response.body.code, 'OTP_DELIVERY_FAILED');
    assert.equal(Object.hasOwn(response.body, 'devOtp'), false);
    assert.equal(JSON.stringify(response.body).includes(verificationCode), false);
    assert.equal(await models.User.count({ where: { email: failedEmail } }), 0);
  } finally {
    smsDeliveryFailure = false;
  }
});

test('fresh account verifies, completes a persisted profile, reloads it, and logs out', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  phoneNumber = `+919${suffix.slice(-9)}`;
  email = `fresh-${suffix}@auth-flow.test`;
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
      acceptedLegalDocuments: signupLegalDocuments(),
      platform: 'WEB',
    },
  });
  assert.equal(signup.status, 200, JSON.stringify(signup.body));
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
      acceptedLegalDocuments: signupLegalDocuments(),
      platform: 'WEB',
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

  const resend = await request('/api/auth/resend-verification-code', {
    method: 'POST',
    token: null,
    body: { phoneNumber },
  });
  assert.equal(resend.status, 200, JSON.stringify(resend.body));
  assert.equal(resend.body.success, true);
  assert.deepEqual(resend.body.data, { phoneNumber });

  const verification = await request('/api/auth/verify-account', {
    method: 'POST',
    token: null,
    body: { phoneNumber, code: '111111' },
  });
  assert.equal(verification.status, 200);
  accessToken = verification.body.data.accessToken;
  refreshToken = verification.body.data.refreshToken;
  assert.ok(accessToken);
  assert.ok(refreshToken);
  assert.match(refreshToken, /^[a-f0-9]{32}\.[a-f0-9]{128}$/);
  const storedRefresh = await models.RefreshToken.findOne({ where: { userId: user.id } });
  assert.equal(storedRefresh.tokenSelector, refreshToken.split('.')[0]);
  assert.equal(storedRefresh.tokenHash.includes(refreshToken), false);

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

  const invalidCompletion = await request('/api/onboarding/profile-completion', {
    method: 'PUT',
    body: { prompts: [] },
  });
  assert.equal(invalidCompletion.status, 400);
  assert.equal(invalidCompletion.body.message, 'Profile completion failed.');
  assert.deepEqual(invalidCompletion.body.errors, [{
    field: 'prompts',
    message: 'Prompts must be an object.',
  }]);

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

  const fourMore = new FormData();
  for (let index = 0; index < 4; index++) {
    fourMore.append('photos', new Blob([png], { type: 'image/png' }), `more-${index}.png`);
  }
  const sixPhotos = await request('/api/onboarding/photos', { method: 'POST', form: fourMore });
  assert.equal(sixPhotos.status, 200, JSON.stringify(sixPhotos.body));
  assert.equal(sixPhotos.body.data.onboarding.photos.length, 6);
  uploadedFiles.push(...sixPhotos.body.data.onboarding.photos.slice(2).map((url) => path.basename(url)));

  const seventhForm = new FormData();
  seventhForm.append('photos', new Blob([png], { type: 'image/png' }), 'seventh.png');
  const seventh = await request('/api/onboarding/photos', { method: 'POST', form: seventhForm });
  assert.equal(seventh.status, 400);
  assert.equal(seventh.body.code, 'PHOTO_LIMIT_REACHED');
  const afterSeventh = await request('/api/onboarding/status');
  assert.equal(afterSeventh.body.data.onboarding.photos.length, 6);

  const removed = await request('/api/onboarding/photos/2', { method: 'DELETE' });
  assert.equal(removed.status, 200);
  assert.equal(removed.body.data.onboarding.photos.length, 5);
  const afterDelete = await request('/api/me/profile');
  assert.equal(afterDelete.body.data.profile.photos.length, 5);

  const reversed = [...afterDelete.body.data.profile.photos].reverse();
  const reordered = await request('/api/me/profile', {
    method: 'PUT',
    body: { photos: reversed, primaryPhotoIndex: 4 },
  });
  assert.equal(reordered.status, 200, JSON.stringify(reordered.body));
  const afterReorder = await request('/api/me/profile');
  assert.deepEqual(afterReorder.body.data.profile.photos, reversed);
  assert.equal(afterReorder.body.data.profile.primaryPhotoIndex, 4);
  const duplicateOrder = await request('/api/me/profile', {
    method: 'PUT',
    body: { photos: reversed.map(() => reversed[0]), primaryPhotoIndex: 0 },
  });
  assert.equal(duplicateOrder.status, 400);
  const afterDuplicateOrder = await request('/api/me/profile');
  assert.deepEqual(afterDuplicateOrder.body.data.profile.photos, reversed);

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

  const relogin = await request('/api/auth/login', {
    method: 'POST',
    token: null,
    body: { email, password },
  });
  assert.equal(relogin.status, 200);
  const reloadedSession = await request('/api/onboarding/status', {
    token: relogin.body.data.accessToken,
  });
  assert.equal(reloadedSession.status, 200);
  assert.equal(reloadedSession.body.data.onboarding.onboardingCompleted, true);
  assert.equal(reloadedSession.body.data.onboarding.photos.length, 5);

  const concurrentRefreshes = await Promise.all([
    request('/api/auth/refresh-token', {
      method: 'POST',
      token: null,
      body: { refreshToken: relogin.body.data.refreshToken },
    }),
    request('/api/auth/refresh-token', {
      method: 'POST',
      token: null,
      body: { refreshToken: relogin.body.data.refreshToken },
    }),
  ]);
  assert.deepEqual(
    concurrentRefreshes.map((response) => response.status).sort(),
    [200, 401],
  );

  secondaryPhoneNumber = `+918${suffix.slice(-9)}`;
  const secondaryEmail = `isolated-${suffix}@auth-flow.test`;
  const secondarySignup = await request('/api/auth/signup', {
    method: 'POST',
    token: null,
    body: {
      name: 'Isolated Account',
      email: secondaryEmail,
      phoneNumber: secondaryPhoneNumber,
      password,
      confirmPassword: password,
      acceptedTerms: true,
      acceptedLegalDocuments: signupLegalDocuments(),
      platform: 'WEB',
    },
  });
  assert.equal(secondarySignup.status, 200, JSON.stringify(secondarySignup.body));
  secondaryUser = await models.User.findOne({ where: { email: secondaryEmail } });

  const missingChallenge = await request('/api/auth/verify-account', {
    method: 'POST',
    token: null,
    body: { phoneNumber: '+917000000001', code: '111111' },
  });
  assert.equal(missingChallenge.status, 400);
  assert.equal(missingChallenge.body.code, 'OTP_INVALID');

  const secondaryVerification = await request('/api/auth/verify-account', {
    method: 'POST',
    token: null,
    body: { phoneNumber: secondaryPhoneNumber, code: verificationCode },
  });
  assert.equal(secondaryVerification.status, 200);
  const secondaryStatus = await request('/api/onboarding/status', {
    token: secondaryVerification.body.data.accessToken,
  });
  assert.equal(secondaryStatus.status, 200);
  assert.equal(secondaryStatus.body.data.onboarding.userId, secondaryUser.id);
  assert.deepEqual(secondaryStatus.body.data.onboarding.photos, []);
});

test('password recovery is email-based, non-enumerating, and single-use', async () => {
  const beforeUnknown = sentEmails.length;
  const unknownEmail = `unknown-${Date.now()}@auth-flow.test`;
  const unknown = await request('/api/auth/forgot-password', {
    method: 'POST',
    token: null,
    body: { email: unknownEmail },
  });
  assert.equal(unknown.status, 200);
  assert.equal(sentEmails.length, beforeUnknown);
  assert.equal(Object.hasOwn(unknown.body, 'devOtp'), false);

  const unknownVerification = await request('/api/auth/verify-reset-code', {
    method: 'POST',
    token: null,
    body: { email: unknownEmail, code: '111111' },
  });
  assert.equal(unknownVerification.status, 400);
  assert.equal(unknownVerification.body.code, 'OTP_EXPIRED');

  const requested = await request('/api/auth/forgot-password', {
    method: 'POST',
    token: null,
    body: { email },
  });
  assert.equal(requested.status, 200);
  assert.equal(sentEmails.length, beforeUnknown + 1);
  assert.equal(sentEmails.at(-1).to, email);
  assert.equal(sentEmails.at(-1).meta.code, verificationCode);
  assert.equal(Object.hasOwn(requested.body, 'devOtp'), false);

  const duplicateRequest = await request('/api/auth/forgot-password', {
    method: 'POST',
    token: null,
    body: { email },
  });
  assert.equal(duplicateRequest.status, 429);
  assert.equal(duplicateRequest.body.code, 'RATE_LIMITED');
  assert.equal(sentEmails.length, beforeUnknown + 1);

  const wrongCode = await request('/api/auth/verify-reset-code', {
    method: 'POST',
    token: null,
    body: { email, code: '000000' },
  });
  assert.equal(wrongCode.status, 400);
  assert.equal(wrongCode.body.code, 'OTP_INVALID');

  const verified = await request('/api/auth/verify-reset-code', {
    method: 'POST',
    token: null,
    body: { email, code: '111111' },
  });
  assert.equal(verified.status, 200);
  const recoveryToken = verified.body.data.recoveryToken;
  assert.ok(recoveryToken);

  const mismatched = await request('/api/auth/reset-password', {
    method: 'POST',
    token: null,
    body: {
      email: 'someone-else@auth-flow.test',
      recoveryToken,
      newPassword: 'ChangedPass123!',
    },
  });
  assert.equal(mismatched.status, 401);

  const reset = await request('/api/auth/reset-password', {
    method: 'POST',
    token: null,
    body: { email, recoveryToken, newPassword: 'ChangedPass123!' },
  });
  assert.equal(reset.status, 200);

  const replay = await request('/api/auth/reset-password', {
    method: 'POST',
    token: null,
    body: { email, recoveryToken, newPassword: 'ReplayPass123!' },
  });
  assert.equal(replay.status, 401);
  assert.equal(replay.body.code, 'TOKEN_INVALID');

  const oldPassword = await request('/api/auth/login', {
    method: 'POST',
    token: null,
    body: { email, password: 'ProductionPass123!' },
  });
  assert.equal(oldPassword.status, 401);
  const newPassword = await request('/api/auth/login', {
    method: 'POST',
    token: null,
    body: { email, password: 'ChangedPass123!' },
  });
  assert.equal(newPassword.status, 200);
});

test('resend and password-reset delivery failures return controlled errors and consume unusable challenges', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const resendEmail = `resend-failure-${suffix}@auth-flow.test`;
  const resendPhone = `+916${suffix.slice(-9)}`;
  const signup = await request('/api/auth/signup', {
    method: 'POST',
    token: null,
    body: {
      name: 'Resend Delivery Failure',
      email: resendEmail,
      phoneNumber: resendPhone,
      password: 'ProviderFailure123!',
      confirmPassword: 'ProviderFailure123!',
      acceptedTerms: true,
      acceptedLegalDocuments: signupLegalDocuments(),
      platform: 'WEB',
    },
  });
  assert.equal(signup.status, 200, JSON.stringify(signup.body));
  const resendUser = await models.User.findOne({ where: { email: resendEmail } });
  deliveryFailureUserIds.push(resendUser.id);
  deliveryFailureEmails.push(resendEmail);
  deliveryFailurePhones.push(resendPhone);
  await models.OtpToken.update(
    { createdAt: new Date(Date.now() - 46_000) },
    { where: { phoneNumber: resendPhone, purpose: 'account_verification' } },
  );

  const logged = [];
  const originalError = console.error;
  console.error = (...args) => logged.push(args.join(' '));
  smsDeliveryFailure = true;
  let resend;
  try {
    resend = await request('/api/auth/resend-verification-code', {
      method: 'POST',
      token: null,
      body: { phoneNumber: resendPhone },
      forwardedFor: '198.51.100.20',
    });
  } finally {
    smsDeliveryFailure = false;
    console.error = originalError;
  }
  assert.equal(resend.status, 503);
  assert.equal(resend.body.code, 'OTP_DELIVERY_FAILED');
  assert.equal(JSON.stringify(resend.body).includes(verificationCode), false);
  const failedResendOtp = await models.OtpToken.findOne({
    where: { phoneNumber: resendPhone, purpose: 'account_verification' },
    order: [['createdAt', 'DESC']],
  });
  assert.equal(failedResendOtp.consumed, true);
  assert.equal(logged.some((entry) => entry.includes(verificationCode)), false);

  await models.OtpToken.update(
    { createdAt: new Date(Date.now() - 46_000) },
    { where: { email, purpose: 'password_reset' } },
  );
  const beforeFailures = sentEmails.length;
  emailDeliveryFailure = true;
  let forgot;
  try {
    forgot = await request('/api/auth/forgot-password', {
      method: 'POST',
      token: null,
      body: { email },
      forwardedFor: '198.51.100.21',
    });
  } finally {
    emailDeliveryFailure = false;
  }
  assert.equal(forgot.status, 503);
  assert.equal(forgot.body.code, 'OTP_DELIVERY_FAILED');
  assert.equal(JSON.stringify(forgot.body).includes(verificationCode), false);
  assert.equal(sentEmails.length, beforeFailures);
  const failedResetOtp = await models.OtpToken.findOne({
    where: { email, purpose: 'password_reset' },
    order: [['createdAt', 'DESC']],
  });
  assert.equal(failedResetOtp.consumed, true);
});
