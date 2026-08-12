const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Identity verification integration tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let models;
let server;
let baseUrl;
const users = {};
const userIds = [];
const storedFiles = [];

const tokenFor = (user) => jwt.sign(
  { sub: user.id, ver: user.tokenVersion || 0 },
  process.env.JWT_SECRET,
  { expiresIn: '15m' },
);
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });

async function createUser(key, role = 'user') {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `KYC ${key}`,
    email: `${suffix}@identity.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
    role,
  });
  userIds.push(user.id);
  users[key] = user;
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1997-05-12',
    gender: 'Woman',
    interestedIn: ['Men'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    interests: ['music'],
    lifestyle: {},
    prompts: { idealDate: 'Coffee' },
    photos: ['/uploads/identity.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function request(route, options = {}) {
  const response = await fetch(`${baseUrl}${route}`, options);
  const contentType = response.headers.get('content-type') || '';
  return {
    status: response.status,
    body: contentType.includes('application/json') ? await response.json() : Buffer.from(await response.arrayBuffer()),
    contentType,
  };
}

async function json(route, method, user, body) {
  return request(route, {
    method,
    headers: { ...auth(user), 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

const png = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
]);

async function submit(user) {
  const data = new FormData();
  data.append('aadhaar', new Blob([png], { type: 'image/png' }), 'aadhaar.png');
  data.append('selfie', new Blob([png], { type: 'image/png' }), 'selfie.png');
  return request('/api/identity-verification/submissions', {
    method: 'POST',
    headers: auth(user),
    body: data,
  });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await Promise.all([
    createUser('member'),
    createUser('resubmit'),
    createUser('viewer'),
    createUser('admin', 'admin'),
  ]);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    const rows = await models.IdentityVerification.findAll({ where: { userId: userIds } });
    for (const row of rows) {
      storedFiles.push(
        path.join(__dirname, '..', 'private-uploads', row.aadhaarStoragePath),
        path.join(__dirname, '..', 'private-uploads', row.selfieStoragePath),
      );
    }
    await models.IdentityVerification.destroy({ where: { userId: userIds } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  await Promise.all(storedFiles.map((file) => fs.rm(file, { force: true })));
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

test('identity submission is private, owner-scoped, and admin APIs are removed', async () => {
  assert.equal((await request('/api/identity-verification/me')).status, 401);
  const initial = await request('/api/identity-verification/me', { headers: auth(users.member) });
  assert.equal(initial.status, 200);
  assert.equal(initial.body.data.verification.status, 'not_started');

  const submitted = await submit(users.member);
  assert.equal(submitted.status, 202);
  assert.equal(submitted.body.data.verification.status, 'pending');
  const row = await models.IdentityVerification.findOne({ where: { userId: users.member.id } });
  assert.equal(row.status, 'pending');
  assert.equal(row.aadhaarStoragePath.includes('identity-verification/'), true);
  assert.equal('aadhaarStoragePath' in submitted.body.data.verification, false);
  await users.member.reload();
  assert.equal(users.member.identityVerifiedAt, null);

  assert.equal((await submit(users.member)).status, 409);
  assert.equal((await json(`/api/identity-verification/${row.id}/review`, 'PUT', users.viewer, { status: 'verified' })).status, 404);

  const privateDenied = await request(`/api/identity-verification/${row.id}/documents/aadhaar`, { headers: auth(users.viewer) });
  assert.equal(privateDenied.status, 404);
  const privateAllowed = await request(`/api/identity-verification/${row.id}/documents/aadhaar`, { headers: auth(users.admin) });
  assert.equal(privateAllowed.status, 404);
  assert.equal((await json(`/api/identity-verification/${row.id}/review`, 'PUT', users.admin, { status: 'verified' })).status, 404);
  await users.member.reload();
  assert.equal(users.member.identityVerifiedAt, null);

  const publicProfile = await request(`/api/profiles/${users.member.id}`, { headers: auth(users.viewer) });
  assert.equal(publicProfile.status, 200);
  assert.notEqual(publicProfile.body.data.profile.verification, 'Verified');
  assert.equal((await submit(users.member)).status, 409);
});

test('pending submissions cannot be mutated through a removed review API', async () => {
  const submitted = await submit(users.resubmit);
  assert.equal(submitted.status, 202);
  const row = await models.IdentityVerification.findOne({ where: { userId: users.resubmit.id } });
  const rejected = await json(`/api/identity-verification/${row.id}/review`, 'PUT', users.admin, {
    status: 'rejected',
    rejectionReason: 'Selfie is not clear enough.',
  });
  assert.equal(rejected.status, 404);
  const status = await request('/api/identity-verification/me', { headers: auth(users.resubmit) });
  assert.equal(status.body.data.verification.status, 'pending');
  await users.resubmit.reload();
  assert.equal(users.resubmit.identityVerifiedAt, null);

  const resubmitted = await submit(users.resubmit);
  assert.equal(resubmitted.status, 409);
  assert.equal(await models.IdentityVerification.count({ where: { userId: users.resubmit.id } }), 1);
});
