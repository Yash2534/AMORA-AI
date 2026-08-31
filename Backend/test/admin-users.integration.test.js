const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const fs = require('node:fs');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Admin user integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
require('../src/config/env');
const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { absolutePathFor } = require('../src/utils/identityVerificationStorage');
const adminMfaService = require('../src/services/adminMfaService');

let server;
let baseUrl;
let administrator;
let role;
let consumer;
let consumerProfile;
let verification;
let verificationStoragePath;
let password;

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      ...(options.accessToken ? { authorization: `Bearer ${options.accessToken}` } : {}),
      ...(options.cookie ? { cookie: options.cookie } : {}),
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
    ...(options.body ? { body: JSON.stringify(options.body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  const { Administrator, AdminRole, AdminPermission, User, OnboardingProfile } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  password = `AdminUsers!${suffix}Aa1`;
  role = await AdminRole.create({
    key: `admin_users_${suffix}`,
    name: 'Admin Users Integration Role',
    isActive: true,
  });
  const keys = [
    'users.view', 'users.details.view', 'users.profile.view', 'users.sessions.view',
    'users.manage', 'users.activate', 'users.forceLogout', 'users.delete', 'users.resetPassword',
    'profiles.view', 'profiles.details.view', 'profiles.preview', 'profiles.edit',
    'profiles.photos.view', 'profiles.photos.manage', 'profiles.audit.view',
    'verifications.view', 'verifications.pending.view', 'verifications.details.view',
    'verifications.aadhaar.view', 'verifications.selfie.view', 'verifications.history.view',
    'verifications.approve',
  ];
  const permissions = await AdminPermission.findAll({ where: { key: keys } });
  assert.equal(permissions.length, keys.length);
  await role.addPermissions(permissions);
  administrator = await Administrator.create({
    name: 'Admin Users Integration',
    email: `admin.users.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(password, 12),
  });
  await administrator.addRole(role);
  consumer = await User.create({
    name: `Real Client ${suffix}`,
    email: `real.client.${suffix}@example.test`,
    phoneNumber: `+9199${suffix.slice(0, 8).replace(/[^0-9]/g, '7')}`,
    passwordHash: await bcrypt.hash(`Client!${suffix}Aa1`, 12),
    isVerified: true,
    accountStatus: 'active',
  });
  consumerProfile = await OnboardingProfile.create({
    userId: consumer.id,
    birthDate: '1995-04-20',
    gender: 'Woman',
    city: 'Pune',
    bio: 'A real integration profile persisted in the isolated test database.',
    interests: ['music', 'travel'],
    languages: ['English', 'Hindi'],
    photos: ['/uploads/integration-profile.jpg'],
    primaryPhotoIndex: 0,
    onboardingCompleted: true,
    stage: 'complete',
  });
  const { IdentityVerification } = getModels();
  const evidenceBytes = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');
  verificationStoragePath = `identity-verification/${consumer.id}-admin-integration.png`;
  const evidencePath = absolutePathFor(verificationStoragePath);
  await fs.promises.writeFile(evidencePath, evidenceBytes, { flag: 'w', mode: 0o600 });
  verification = await IdentityVerification.create({
    userId: consumer.id,
    status: 'pending',
    aadhaarStoragePath: verificationStoragePath,
    aadhaarMimeType: 'image/png',
    aadhaarSizeBytes: evidenceBytes.length,
    selfieStoragePath: verificationStoragePath,
    selfieMimeType: 'image/png',
    selfieSizeBytes: evidenceBytes.length,
    submittedAt: new Date(),
  });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const { AdminAuditLog, AdminRefreshToken, Administrator, AdminRole, RefreshToken, OnboardingProfile, IdentityVerification, User } = getModels();
  if (administrator) {
    await AdminAuditLog.destroy({ where: { administratorId: administrator.id } });
    await AdminRefreshToken.destroy({ where: { administratorId: administrator.id }, force: true });
    await administrator.setRoles([]);
    await Administrator.destroy({ where: { id: administrator.id } });
  }
  if (role) {
    await role.setPermissions([]);
    await AdminRole.destroy({ where: { id: role.id } });
  }
  if (consumer) {
    await IdentityVerification.destroy({ where: { userId: consumer.id } });
    await RefreshToken.destroy({ where: { userId: consumer.id } });
    await OnboardingProfile.destroy({ where: { userId: consumer.id } });
    await User.destroy({ where: { id: consumer.id } });
  }
  if (verificationStoragePath) await fs.promises.unlink(absolutePathFor(verificationStoragePath)).catch(() => {});
  await getSequelize().close();
});

test('admin user reads and lifecycle mutations commit to the client-authoritative database', async () => {
  const login = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(login.status, 200);
  const adminToken = login.body.data.accessToken;

  const users = await request(`/api/admin/v1/users?search=${consumer.id}&page=1&pageSize=20`, {
    accessToken: adminToken,
  });
  assert.equal(users.status, 200);
  const listed = users.body.data.items.find((item) => item.id === String(consumer.id));
  assert.ok(listed);
  assert.equal(listed.displayName, consumer.name);
  assert.notEqual(listed.email, consumer.email);
  assert.equal(listed.verificationStatus, 'pending');

  const supportedListContract = await request(
    `/api/admin/v1/users?status=active&onlineStatus=offline&sortBy=displayName&sortDirection=asc&page=1&pageSize=20`,
    { accessToken: adminToken },
  );
  assert.equal(supportedListContract.status, 200);
  const unsupportedListQuery = await request(
    '/api/admin/v1/users?verificationStatus=pending&page=1&pageSize=20',
    { accessToken: adminToken },
  );
  assert.equal(unsupportedListQuery.status, 422);
  assert.equal(unsupportedListQuery.body.code, 'UNSUPPORTED_QUERY_PARAMETER');

  const details = await request(`/api/admin/v1/users/${consumer.id}`, { accessToken: adminToken });
  assert.equal(details.status, 200);
  assert.equal(details.body.data.user.id, String(consumer.id));
  const profile = await request(`/api/admin/v1/users/${consumer.id}/profile`, { accessToken: adminToken });
  assert.equal(profile.status, 200);
  assert.equal(profile.body.data.city, 'Pune');
  assert.equal(profile.body.data.about, 'A real integration profile persisted in the isolated test database.');

  const originalClientToken = jwt.sign({ sub: String(consumer.id), ver: 0 }, process.env.JWT_SECRET, { expiresIn: '5m' });
  const before = await request('/api/auth/me', { accessToken: originalClientToken });
  assert.equal(before.status, 200);
  assert.equal(before.body.data.user.accountStatus, 'active');

  const profiles = await request(`/api/admin/v1/profiles?search=${encodeURIComponent(consumer.name)}&page=1&pageSize=20`, {
    accessToken: adminToken,
  });
  assert.equal(profiles.status, 200);
  const listedProfile = profiles.body.data.items.find((item) => item.profileId === String(consumerProfile.id));
  assert.ok(listedProfile);
  assert.equal(listedProfile.city, 'Pune');

  const profileDetails = await request(`/api/admin/v1/profiles/${consumerProfile.id}`, { accessToken: adminToken });
  assert.equal(profileDetails.status, 200);
  assert.equal(profileDetails.body.data.about, 'A real integration profile persisted in the isolated test database.');
  assert.equal(profileDetails.body.data.photos.length, 1);

  const updatedBio = 'This profile bio was committed by an authorized administrator integration test.';
  const profileUpdate = await request(`/api/admin/v1/profiles/${consumerProfile.id}`, {
    method: 'PATCH',
    accessToken: adminToken,
    headers: { 'if-match': profileDetails.body.data.version },
    body: { about: updatedBio, city: 'Bengaluru' },
  });
  assert.equal(profileUpdate.status, 200);
  assert.equal(profileUpdate.body.data.about, updatedBio);
  const clientProfile = await request('/api/me/profile', { accessToken: originalClientToken });
  assert.equal(clientProfile.status, 200);
  assert.equal(clientProfile.body.data.profile.bio, updatedBio);
  assert.equal(clientProfile.body.data.profile.location, 'Bengaluru');

  const photoId = profileUpdate.body.data.photos[0].photoId;
  const primary = await request(`/api/admin/v1/profiles/${consumerProfile.id}/photos/${photoId}`, {
    method: 'PATCH',
    accessToken: adminToken,
    body: { isPrimary: true },
  });
  assert.equal(primary.status, 200);
  const reordered = await request(`/api/admin/v1/profiles/${consumerProfile.id}/photos/reorder`, {
    method: 'PATCH',
    accessToken: adminToken,
    body: { photoIds: [photoId] },
  });
  assert.equal(reordered.status, 200);
  const profileAudit = await request(`/api/admin/v1/profiles/${consumerProfile.id}/audit-history`, {
    accessToken: adminToken,
  });
  assert.equal(profileAudit.status, 200);
  assert.ok(profileAudit.body.data.items.some((item) => item.actionType === 'admin.profiles.update'));

  const verificationList = await request('/api/admin/v1/verifications?status=pending&page=1&pageSize=20', {
    accessToken: adminToken,
  });
  assert.equal(verificationList.status, 200);
  assert.ok(verificationList.body.data.items.some((item) => item.verificationId === String(verification.id)));
  const verificationDetails = await request(`/api/admin/v1/verifications/${verification.id}`, {
    accessToken: adminToken,
  });
  assert.equal(verificationDetails.status, 200);
  assert.deepEqual(verificationDetails.body.data.summary.allowedActions, ['approve']);
  assert.equal(verificationDetails.body.data.evidenceReadyForDecision, true);
  assert.equal(verificationDetails.body.data.aadhaarStoragePath, undefined);
  assert.equal(verificationDetails.body.data.evidence.length, 2);
  const mediaResponse = await fetch(`${baseUrl}/api/admin/v1/media/${verificationDetails.body.data.evidence[0].mediaId}`, {
    headers: { authorization: `Bearer ${adminToken}` },
  });
  assert.equal(mediaResponse.status, 200);
  assert.equal(mediaResponse.headers.get('cache-control'), 'no-store, private, max-age=0');
  assert.deepEqual(Buffer.from(await mediaResponse.arrayBuffer()), Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex'));
  const decisionKey = crypto.randomUUID();
  const approved = await request(`/api/admin/v1/verifications/${verification.id}/approve`, {
    method: 'POST',
    accessToken: adminToken,
    headers: {
      'idempotency-key': decisionKey,
      'if-match': verificationDetails.body.data.summary.reviewVersion,
    },
    body: { expectedVersion: verificationDetails.body.data.summary.reviewVersion, idempotencyKey: decisionKey },
  });
  assert.equal(approved.status, 200);
  assert.equal(approved.body.data.summary.status, 'approved');
  await verification.reload();
  await consumer.reload();
  assert.equal(verification.status, 'verified');
  assert.equal(String(verification.reviewerAdministratorId), String(administrator.id));
  assert.ok(consumer.identityVerifiedAt);
  const clientVerification = await request('/api/identity-verification/me', { accessToken: originalClientToken });
  assert.equal(clientVerification.status, 200);
  assert.equal(clientVerification.body.data.verification.status, 'verified');
  const verificationHistory = await request(`/api/admin/v1/verifications/${verification.id}/history`, {
    accessToken: adminToken,
  });
  assert.equal(verificationHistory.status, 200);
  assert.equal(verificationHistory.body.data.items[0].action, 'approve');
  assert.equal(verificationHistory.body.data.items[0].actorName, administrator.name);

  const deactivated = await request(`/api/admin/v1/users/${consumer.id}/deactivate`, {
    method: 'POST',
    accessToken: adminToken,
    body: { reason: 'Integration lifecycle verification' },
  });
  assert.equal(deactivated.status, 200);
  assert.equal(deactivated.body.data.user.status, 'deactivated');
  await consumer.reload();
  assert.equal(consumer.accountStatus, 'deactivated');
  const revokedClient = await request('/api/auth/me', { accessToken: originalClientToken });
  assert.equal(revokedClient.status, 401);

  const activated = await request(`/api/admin/v1/users/${consumer.id}/activate`, {
    method: 'POST',
    accessToken: adminToken,
  });
  assert.equal(activated.status, 200);
  assert.equal(activated.body.data.user.status, 'active');
  await consumer.reload();
  const currentClientToken = jwt.sign({ sub: String(consumer.id), ver: consumer.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '5m' });
  const clientAfter = await request('/api/auth/me', { accessToken: currentClientToken });
  assert.equal(clientAfter.status, 200);
  assert.equal(clientAfter.body.data.user.accountStatus, 'active');

  const { RefreshToken } = getModels();
  await RefreshToken.create({
    userId: consumer.id,
    tokenSelector: crypto.randomBytes(16).toString('hex'),
    tokenHash: await bcrypt.hash('integration-refresh-token', 4),
    expiresAt: new Date(Date.now() + 60_000),
    createdByIp: '127.0.0.1',
  });
  const forced = await request(`/api/admin/v1/users/${consumer.id}/force-logout`, {
    method: 'POST',
    accessToken: adminToken,
  });
  assert.equal(forced.status, 200);
  assert.equal(forced.body.data.revokedSessions, 1);
  assert.equal(await RefreshToken.count({ where: { userId: consumer.id } }), 0);
  const afterForceLogout = await request('/api/auth/me', { accessToken: currentClientToken });
  assert.equal(afterForceLogout.status, 401);

  const enrollment = await request('/api/admin/v1/auth/mfa/enroll', {
    method: 'POST', accessToken: adminToken,
  });
  assert.equal(enrollment.status, 201);
  const confirmed = await request('/api/admin/v1/auth/mfa/confirm', {
    method: 'POST',
    accessToken: adminToken,
    body: { code: adminMfaService.totpFor(enrollment.body.data.secret, Math.floor(Date.now() / 30000)) },
  });
  assert.equal(confirmed.status, 200);
  const stepUp = await request('/api/admin/v1/auth/mfa/step-up', {
    method: 'POST',
    accessToken: adminToken,
    body: { recoveryCode: confirmed.body.data.recoveryCodes[0] },
  });
  assert.equal(stepUp.status, 200);

  const reset = await request(`/api/admin/v1/users/${consumer.id}/reset-password`, {
    method: 'POST', accessToken: adminToken,
  });
  assert.equal(reset.status, 200);
  const deleted = await request(`/api/admin/v1/users/${consumer.id}`, {
    method: 'DELETE',
    accessToken: adminToken,
    body: { reason: 'privacy_concerns' },
  });
  assert.equal(deleted.status, 200);
  await consumer.reload();
  assert.equal(consumer.accountStatus, 'deleted');
  assert.equal(consumer.passwordHash, null);
  assert.match(consumer.email, /@deleted\.amora\.invalid$/);
});
