const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const fs = require('node:fs');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Admin verification decision tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
require('../src/config/env');
const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { absolutePathFor } = require('../src/utils/identityVerificationStorage');

let server;
let baseUrl;
let reviewer;
let viewer;
let reviewerRole;
let viewerRole;
let password;
const users = [];
const verificationPaths = [];
const reasonCodes = [];

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      ...(options.accessToken ? { authorization: `Bearer ${options.accessToken}` } : {}),
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
    ...(options.body ? { body: JSON.stringify(options.body) } : {}),
  });
  return { status: response.status, headers: response.headers, body: await response.json() };
}

async function createVerification(suffix, status = 'pending') {
  const { User, IdentityVerification } = getModels();
  const user = await User.create({
    name: `KYC Consumer ${suffix}`,
    email: `kyc.consumer.${suffix}@example.test`,
    phoneNumber: `+9198${String(crypto.randomInt(10000000, 99999999))}`,
    passwordHash: await bcrypt.hash(`Client!${suffix}Aa1`, 4),
    isVerified: true,
    accountStatus: 'active',
  });
  users.push(user);
  const bytes = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');
  const storagePath = `identity-verification/${user.id}-${suffix}.png`;
  await fs.promises.writeFile(absolutePathFor(storagePath), bytes, { flag: 'w', mode: 0o600 });
  verificationPaths.push(storagePath);
  const verification = await IdentityVerification.create({
    userId: user.id,
    status,
    aadhaarStoragePath: storagePath,
    aadhaarMimeType: 'image/png',
    aadhaarSizeBytes: bytes.length,
    selfieStoragePath: storagePath,
    selfieMimeType: 'image/png',
    selfieSizeBytes: bytes.length,
    submittedAt: new Date(),
  });
  return { user, verification };
}

async function login(administrator) {
  const response = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(response.status, 200);
  return response.body.data.accessToken;
}

function decisionOptions(token, version, key, body = {}) {
  return {
    method: 'POST',
    accessToken: token,
    headers: { 'idempotency-key': key, 'if-match': version },
    body: { expectedVersion: version, idempotencyKey: key, ...body },
  };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  const {
    Administrator, AdminRole, AdminPermission, IdentityVerificationReason,
  } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  password = `KycAdmin!${suffix}Aa1`;
  reviewerRole = await AdminRole.create({ key: `kyc_reviewer_${suffix}`, name: 'KYC Reviewer Test', isActive: true });
  viewerRole = await AdminRole.create({ key: `kyc_viewer_${suffix}`, name: 'KYC Viewer Test', isActive: true });
  const readKeys = [
    'verifications.view', 'verifications.pending.view', 'verifications.rejected.view',
    'verifications.details.view', 'verifications.aadhaar.view', 'verifications.selfie.view',
    'verifications.history.view',
  ];
  const readPermissions = await AdminPermission.findAll({ where: { key: readKeys } });
  const mutationPermissions = await AdminPermission.findAll({
    where: { key: ['verifications.approve', 'verifications.reject', 'verifications.resubmit'] },
  });
  assert.equal(readPermissions.length, readKeys.length);
  assert.equal(mutationPermissions.length, 3);
  await reviewerRole.addPermissions([...readPermissions, ...mutationPermissions]);
  await viewerRole.addPermissions(readPermissions);
  reviewer = await Administrator.create({
    name: 'KYC Reviewer', email: `kyc.reviewer.${suffix}@example.test`, passwordHash: await bcrypt.hash(password, 12),
  });
  viewer = await Administrator.create({
    name: 'KYC Viewer', email: `kyc.viewer.${suffix}@example.test`, passwordHash: await bcrypt.hash(password, 12),
  });
  await reviewer.addRole(reviewerRole);
  await viewer.addRole(viewerRole);
  reasonCodes.push(`document_unreadable_${suffix}`, `selfie_unclear_${suffix}`);
  await IdentityVerificationReason.bulkCreate([
    {
      code: reasonCodes[0], action: 'reject', label: 'Test document unreadable',
      allowsDetail: false, requiresDetail: false, allowedItems: null, sortOrder: 1,
    },
    {
      code: reasonCodes[1], action: 'request_resubmission', label: 'Test selfie unclear',
      allowsDetail: true, requiresDetail: false, allowedItems: ['selfie'], sortOrder: 1,
    },
  ]);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const {
    AdminAuditLog, AdminRefreshToken, Administrator, AdminRole, IdentityVerification,
    IdentityVerificationReason, RefreshToken, User,
  } = getModels();
  for (const user of users) {
    await IdentityVerification.destroy({ where: { userId: user.id } });
    await RefreshToken.destroy({ where: { userId: user.id } });
    await User.destroy({ where: { id: user.id } });
  }
  await IdentityVerificationReason.destroy({ where: { code: reasonCodes }, hooks: false });
  for (const administrator of [reviewer, viewer]) {
    if (!administrator) continue;
    await AdminAuditLog.destroy({ where: { administratorId: administrator.id } });
    await AdminRefreshToken.destroy({ where: { administratorId: administrator.id }, force: true });
    await administrator.setRoles([]);
    await Administrator.destroy({ where: { id: administrator.id } });
  }
  for (const role of [reviewerRole, viewerRole]) {
    if (!role) continue;
    await role.setPermissions([]);
    await AdminRole.destroy({ where: { id: role.id } });
  }
  await Promise.all(verificationPaths.map((path) => fs.promises.unlink(absolutePathFor(path)).catch(() => {})));
  await getSequelize().close();
});

test('KYC decisions enforce RBAC, transactions, idempotency, history, and consumer reflection', async () => {
  const reviewerToken = await login(reviewer);
  const viewerToken = await login(viewer);
  const { IdentityVerificationDecisionEvent, AdminAuditLog } = getModels();
  const suffix = crypto.randomUUID().slice(0, 8);
  const rejected = await createVerification(`${suffix}-reject`);
  const resubmitted = await createVerification(`${suffix}-resubmit`);
  const rollback = await createVerification(`${suffix}-rollback`);

  const rejectedDetails = await request(`/api/admin/v1/verifications/${rejected.verification.id}`, { accessToken: reviewerToken });
  assert.equal(rejectedDetails.status, 200);
  const rejectedVersion = rejectedDetails.body.data.summary.reviewVersion;
  const rejectReason = (await request('/api/admin/v1/verifications/reasons?action=reject', { accessToken: reviewerToken }))
    .body.data.items.find((item) => item.label === 'Test document unreadable');
  assert.ok(rejectReason);

  const deniedKey = crypto.randomUUID();
  const denied = await request(`/api/admin/v1/verifications/${rejected.verification.id}/reject`, decisionOptions(
    viewerToken, rejectedVersion, deniedKey, { reasonCode: rejectReason.code },
  ));
  assert.equal(denied.status, 403);
  await rejected.verification.reload();
  assert.equal(rejected.verification.status, 'pending');

  const rejectKey = crypto.randomUUID();
  const rejectRequest = decisionOptions(reviewerToken, rejectedVersion, rejectKey, {
    reasonCode: rejectReason.code,
    note: 'Reviewed in isolated integration coverage.',
  });
  const committedReject = await request(`/api/admin/v1/verifications/${rejected.verification.id}/reject`, rejectRequest);
  assert.equal(committedReject.status, 200);
  assert.equal(committedReject.body.data.summary.status, 'rejected');
  const replayedReject = await request(`/api/admin/v1/verifications/${rejected.verification.id}/reject`, rejectRequest);
  assert.equal(replayedReject.status, 200);
  assert.equal(replayedReject.headers.get('idempotency-replayed'), 'true');
  assert.equal(await IdentityVerificationDecisionEvent.count({ where: { verificationId: rejected.verification.id } }), 1);
  assert.equal(await AdminAuditLog.count({ where: { action: 'verification.reject', targetId: String(rejected.verification.id) } }), 1);
  const reused = await request(`/api/admin/v1/verifications/${rejected.verification.id}/reject`, decisionOptions(
    reviewerToken, rejectedVersion, rejectKey, { reasonCode: rejectReason.code, note: 'Different request.' },
  ));
  assert.equal(reused.status, 409);
  await rejected.verification.reload();
  assert.equal(rejected.verification.status, 'rejected');
  assert.equal(String(rejected.verification.reviewerAdministratorId), String(reviewer.id));
  const rejectHistory = await request(`/api/admin/v1/verifications/${rejected.verification.id}/history`, { accessToken: reviewerToken });
  assert.equal(rejectHistory.status, 200);
  assert.equal(rejectHistory.body.data.items[0].actorName, reviewer.name);
  assert.equal(rejectHistory.body.data.items[0].reasonLabel, 'Test document unreadable');

  const resubmitDetails = await request(`/api/admin/v1/verifications/${resubmitted.verification.id}`, { accessToken: reviewerToken });
  const resubmitVersion = resubmitDetails.body.data.summary.reviewVersion;
  const resubmitReason = (await request('/api/admin/v1/verifications/reasons?action=request_resubmission', { accessToken: reviewerToken }))
    .body.data.items.find((item) => item.label === 'Test selfie unclear');
  assert.deepEqual(resubmitReason.allowedItems, ['selfie']);
  const invalidItemKey = crypto.randomUUID();
  const invalidItem = await request(`/api/admin/v1/verifications/${resubmitted.verification.id}/request-resubmission`, decisionOptions(
    reviewerToken, resubmitVersion, invalidItemKey, { reasonCode: resubmitReason.code, items: ['aadhaar'] },
  ));
  assert.equal(invalidItem.status, 422);
  const resubmitKey = crypto.randomUUID();
  const committedResubmit = await request(`/api/admin/v1/verifications/${resubmitted.verification.id}/request-resubmission`, decisionOptions(
    reviewerToken, resubmitVersion, resubmitKey,
    { reasonCode: resubmitReason.code, items: ['selfie'], detail: 'Please provide a clearer selfie.' },
  ));
  assert.equal(committedResubmit.status, 200);
  await resubmitted.verification.reload();
  assert.equal(resubmitted.verification.status, 'resubmission_requested');
  assert.deepEqual(resubmitted.verification.resubmissionItems, ['selfie']);
  const consumerToken = jwt.sign(
    { sub: String(resubmitted.user.id), ver: resubmitted.user.tokenVersion },
    process.env.JWT_SECRET,
    { expiresIn: '5m' },
  );
  const clientState = await request('/api/identity-verification/me', { accessToken: consumerToken });
  assert.equal(clientState.status, 200);
  assert.equal(clientState.body.data.verification.status, 'resubmission_requested');
  assert.equal(clientState.body.data.verification.rejectionReason, 'Please provide a clearer selfie.');

  const rollbackDetails = await request(`/api/admin/v1/verifications/${rollback.verification.id}`, { accessToken: reviewerToken });
  const rollbackVersion = rollbackDetails.body.data.summary.reviewVersion;
  const originalCreate = IdentityVerificationDecisionEvent.create;
  IdentityVerificationDecisionEvent.create = async () => { throw new Error('forced decision-event write failure'); };
  const rollbackKey = crypto.randomUUID();
  const failed = await request(`/api/admin/v1/verifications/${rollback.verification.id}/approve`, decisionOptions(
    reviewerToken, rollbackVersion, rollbackKey,
  ));
  IdentityVerificationDecisionEvent.create = originalCreate;
  assert.equal(failed.status, 500);
  await rollback.verification.reload();
  await rollback.user.reload();
  assert.equal(rollback.verification.status, 'pending');
  assert.equal(rollback.user.identityVerifiedAt, null);
  assert.equal(await AdminAuditLog.count({ where: { action: 'verification.approve', targetId: String(rollback.verification.id) } }), 0);

  const event = await IdentityVerificationDecisionEvent.findOne({ where: { verificationId: rejected.verification.id } });
  await assert.rejects(
    IdentityVerificationDecisionEvent.update({ reasonLabelSnapshot: 'Changed' }, { where: { id: event.id } }),
    /immutable/,
  );
});
