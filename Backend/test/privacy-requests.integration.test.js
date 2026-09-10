const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const fs = require('fs');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_privacy_requests`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) throw new Error('Privacy request tests require a separate TEST_DB_NAME containing "test".');
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate, undo } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { PrivacyRequestService, TRANSITIONS } = require('../src/services/privacyRequestService');
const { PrivacyExportArtifactService } = require('../src/services/privacyExportArtifactService');
const { app } = require('../src/server');

let models; let server; let baseUrl; let owner; let other;
const tokenFor = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
const headers = (user) => ({ authorization: `Bearer ${tokenFor(user)}`, 'content-type': 'application/json' });
const request = async (path, options = {}) => { const response = await fetch(`${baseUrl}${path}`, options); return { status: response.status, body: await response.json() }; };
const download = async (user, id, suffix = '') => { const response = await fetch(`${baseUrl}/api/privacy-requests/${id}/export/download${suffix}`, { headers: user ? headers(user) : {} }); const bytes = Buffer.from(await response.arrayBuffer()); return { status: response.status, headers: response.headers, bytes, text: bytes.toString('utf8') }; };
const post = (user, body) => request('/api/privacy-requests', { method: 'POST', headers: headers(user), body: JSON.stringify(body) });

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  owner = await models.User.create({ name: 'Privacy owner', email: `privacy-owner-${Date.now()}@test.invalid`, phoneNumber: '', authProvider: 'local', passwordHash: await bcrypt.hash('PrivacyPass1!', 4), isVerified: true });
  other = await models.User.create({ name: 'Privacy other', email: `privacy-other-${Date.now()}@test.invalid`, phoneNumber: '', authProvider: 'local', passwordHash: await bcrypt.hash('PrivacyPass1!', 4), isVerified: true });
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    const artifacts = await models.PrivacyExportArtifact.findAll({ where: { userId: [owner?.id, other?.id] } });
    const artifactService = new PrivacyExportArtifactService();
    await Promise.all(artifacts.map((artifact) => fs.promises.unlink(artifactService.resolve(artifact.storageKey)).catch(() => {})));
    await models.PrivacyRequest.destroy({ where: { userId: [owner?.id, other?.id] } });
    await models.OtpToken.destroy({ where: { email: [owner?.email, other?.email] } });
    await models.IdentityVerification.destroy({ where: { userId: [owner?.id, other?.id] } });
    await models.User.destroy({ where: { id: [owner?.id, other?.id] } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('privacy request migration supports up, down, and up on the disposable test database', async () => {
  const queryInterface = getSequelize().getQueryInterface();
  const artifactSchemaBefore = await queryInterface.describeTable('PrivacyExportArtifacts');
  for (const field of ['privacyRequestId', 'userId', 'status', 'storageKey', 'filename', 'mimeType', 'byteSize', 'checksum', 'generatedAt', 'failureCode']) assert.ok(Object.hasOwn(artifactSchemaBefore, field));
  const indexes = await queryInterface.showIndex('PrivacyExportArtifacts');
  assert.ok(indexes.some((index) => index.name === 'privacyRequestId' && index.unique));
  assert.ok(indexes.some((index) => index.name === 'privacy_export_artifacts_user_created'));
  assert.ok(indexes.some((index) => index.name === 'privacy_export_artifacts_status_created'));
  const foreignKeys = await queryInterface.getForeignKeyReferencesForTable('PrivacyExportArtifacts');
  assert.ok(foreignKeys.some((key) => key.referencedTableName.toLowerCase() === 'privacyrequests'));
  assert.ok(foreignKeys.some((key) => key.referencedTableName.toLowerCase() === 'users'));
  const reverted = await undo({ databaseName: testDatabase, quiet: true });
  assert.equal(reverted, '202609110001-create-privacy-export-artifacts.js');
  await assert.rejects(() => queryInterface.describeTable('PrivacyExportArtifacts'));
  await queryInterface.describeTable('PrivacyRequests');
  await queryInterface.describeTable('PrivacyRequestConfirmations');
  await queryInterface.describeTable('PrivacyAccessResults');
  await queryInterface.describeTable('PrivacyCorrectionDetails');
  const applied = await migrate({ databaseName: testDatabase, quiet: true });
  assert.deepEqual(applied, ['202609110001-create-privacy-export-artifacts.js']);
  const schema = await getSequelize().getQueryInterface().describeTable('PrivacyRequests');
  for (const field of ['id', 'userId', 'requestType', 'status', 'requestedAt', 'identityVerifiedAt', 'processingStartedAt', 'completedAt', 'failedAt', 'failureCode', 'assignedAdminId', 'correlationId', 'metadata']) assert.ok(Object.hasOwn(schema, field));
  for (const forbidden of ['password', 'otp', 'token', 'authToken', 'aadhaar', 'kycDocument', 'smtpPassword']) assert.equal(Object.hasOwn(schema, forbidden), false);
});

test('authenticated user creates each supported privacy request with only server-controlled evidence', async () => {
  const created = {};
  for (const type of ['ACCESS', 'EXPORT', 'CORRECTION', 'WITHDRAWAL']) {
    const result = await post(owner, { requestType: type });
    assert.equal(result.status, 201, JSON.stringify(result.body));
    const row = result.body.data.request;
    created[type] = row;
    assert.equal(row.requestType, type);
    assert.equal(row.status, 'IDENTITY_VERIFICATION_REQUIRED');
    assert.match(row.correlationId, /^[0-9a-f-]{36}$/i);
    assert.ok(row.requestedAt);
    assert.equal(row.identityVerifiedAt, null);
    assert.equal(row.completedAt, null);
    for (const unsafe of ['userId', 'assignedAdminId', 'metadata']) assert.equal(Object.hasOwn(row, unsafe), false);
  }
  assert.notEqual(created.ACCESS.correlationId, created.EXPORT.correlationId);
});

test('creation requires authentication, validates the allowlist, and rejects client lifecycle control', async () => {
  assert.equal((await request('/api/privacy-requests', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ requestType: 'ACCESS' }) })).status, 401);
  const unsupported = await post(other, { requestType: 'DELETE_EVERYTHING' });
  assert.equal(unsupported.status, 400); assert.equal(unsupported.body.code, 'VALIDATION_ERROR');
  for (const payload of [
    { requestType: 'ACCESS', userId: other.id },
    { requestType: 'ACCESS', status: 'COMPLETED' },
    { requestType: 'ACCESS', completedAt: '2020-01-01T00:00:00.000Z' },
    { requestType: 'ACCESS', correlationId: 'client-controlled' },
    { requestType: 'ACCESS', metadata: { otp: 'sensitive' } },
  ]) {
    const result = await post(other, payload);
    assert.equal(result.status, 400, JSON.stringify(result.body));
    assert.equal(result.body.code, 'PRIVACY_REQUEST_FIELDS_FORBIDDEN');
  }
  assert.equal(await models.PrivacyRequest.count({ where: { userId: other.id } }), 0);
});

test('users can list and read only their own requests without IDOR disclosure', async () => {
  const ownList = await request('/api/privacy-requests', { headers: headers(owner) });
  assert.equal(ownList.status, 200);
  assert.equal(ownList.body.data.requests.length, 4);
  const ownId = ownList.body.data.requests[0].id;
  assert.equal((await request(`/api/privacy-requests/${ownId}`, { headers: headers(owner) })).status, 200);
  assert.equal((await request(`/api/privacy-requests/${ownId}`, { headers: headers(other) })).status, 404);
  assert.equal((await request('/api/privacy-requests', { headers: headers(other) })).body.data.requests.length, 0);
});

test('duplicate rule returns the same active request and allows a new request after completion', async () => {
  const duplicate = await post(owner, { requestType: 'ACCESS' });
  assert.equal(duplicate.status, 409); assert.equal(duplicate.body.code, 'PRIVACY_REQUEST_ALREADY_ACTIVE');
  const original = await models.PrivacyRequest.findByPk(duplicate.body.data.request.id);
  const service = new PrivacyRequestService();
  assert.deepEqual(TRANSITIONS.IDENTITY_VERIFICATION_REQUIRED, ['VERIFIED', 'FAILED']);
  await service.transition({ requestId: original.id, nextStatus: 'VERIFIED' });
  await service.transition({ requestId: original.id, nextStatus: 'PROCESSING' });
  await service.transition({ requestId: original.id, nextStatus: 'COMPLETED' });
  await original.reload();
  assert.equal(original.status, 'COMPLETED'); assert.ok(original.identityVerifiedAt); assert.ok(original.processingStartedAt); assert.ok(original.completedAt);
  const replacement = await post(owner, { requestType: 'ACCESS' });
  assert.equal(replacement.status, 201, JSON.stringify(replacement.body));
  assert.notEqual(replacement.body.data.request.id, String(original.id));
});

test('failed historical requests also permit a new request and AccountDeletionRequest remains separate', async () => {
  const service = new PrivacyRequestService();
  const first = await post(other, { requestType: 'EXPORT' });
  assert.equal(first.status, 201);
  await service.transition({ requestId: first.body.data.request.id, nextStatus: 'FAILED', failureCode: 'TEST_ONLY_CONTROLLED_FAILURE' });
  const replacement = await post(other, { requestType: 'EXPORT' });
  assert.equal(replacement.status, 201);
  assert.equal(await models.AccountDeletionRequest.count({ where: { userId: [owner.id, other.id] } }), 0);
  assert.notEqual(models.PrivacyRequest.tableName, models.AccountDeletionRequest.tableName);
});

test('P1.2 step-up, bounded access, and manual DOB correction are owner-scoped', async () => {
  const access = await post(other, { requestType: 'ACCESS' }); assert.equal(access.status, 201);
  const id = access.body.data.request.id;
  assert.equal((await request(`/api/privacy-requests/${id}/access`, { method:'POST', headers: headers(other) })).status, 409);
  const issued = await request(`/api/privacy-requests/${id}/step-up/confirmations`, { method:'POST', headers:headers(other), body:JSON.stringify({password:'PrivacyPass1!'}) }); assert.equal(issued.status, 200);
  const stored = await models.PrivacyRequestConfirmation.findOne({where:{privacyRequestId:id}}); assert.notEqual(stored.tokenHash, issued.body.data.confirmation); assert.equal(stored.purpose,'privacy_request_step_up');
  assert.equal((await request(`/api/privacy-requests/${id}/step-up/verify`, {method:'POST',headers:headers(owner),body:JSON.stringify({confirmation:issued.body.data.confirmation})})).status,404);
  const verified=await request(`/api/privacy-requests/${id}/step-up/verify`, {method:'POST',headers:headers(other),body:JSON.stringify({confirmation:issued.body.data.confirmation})}); assert.equal(verified.status,200); assert.equal(verified.body.data.request.status,'VERIFIED'); assert.ok(verified.body.data.request.identityVerifiedAt);
  assert.equal((await request(`/api/privacy-requests/${id}/step-up/verify`, {method:'POST',headers:headers(other),body:JSON.stringify({confirmation:issued.body.data.confirmation})})).status,401);
  const completed=await request(`/api/privacy-requests/${id}/access`, {method:'POST',headers:headers(other)});assert.equal(completed.status,200); const data=completed.body.data.result; assert.equal(completed.body.data.request.status,'COMPLETED');assert.ok(completed.body.data.request.processingStartedAt);assert.ok(completed.body.data.request.completedAt);assert.equal(Object.hasOwn(data.account,'passwordHash'),false);assert.equal(Object.hasOwn(data.account,'tokenVersion'),false);assert.equal(JSON.stringify(data).includes('PrivacyPass1!'),false);
  assert.equal((await request(`/api/privacy-requests/${id}/access-result`,{headers:headers(owner)})).status,404);
  const correction=await post(owner,{requestType:'CORRECTION'});const cid=correction.body.data.request.id;const conf=await request(`/api/privacy-requests/${cid}/step-up/confirmations`,{method:'POST',headers:headers(owner),body:JSON.stringify({password:'PrivacyPass1!'})});await request(`/api/privacy-requests/${cid}/step-up/verify`,{method:'POST',headers:headers(owner),body:JSON.stringify({confirmation:conf.body.data.confirmation})});const before=(await models.OnboardingProfile.findOne({where:{userId:owner.id}}))?.birthDate;const detail=await request(`/api/privacy-requests/${cid}/correction`,{method:'POST',headers:headers(owner),body:JSON.stringify({category:'DATE_OF_BIRTH',requestedBirthDate:'1990-01-01'})});assert.equal(detail.status,201);assert.equal(detail.body.data.request.status,'VERIFIED');assert.equal((await request(`/api/privacy-requests/${cid}/correction`,{method:'POST',headers:headers(owner),body:JSON.stringify({category:'DATE_OF_BIRTH',requestedBirthDate:'2015-01-01'})})).status,400);assert.equal((await request(`/api/privacy-requests/${cid}/correction`,{method:'POST',headers:headers(owner),body:JSON.stringify({category:'DATE_OF_BIRTH',requestedBirthDate:'1990-01-01',userId:other.id})})).status,400);assert.equal((await models.OnboardingProfile.findOne({where:{userId:owner.id}}))?.birthDate,before);
});

test('P1.3A export artifact foundation is private, owner-bound, EXPORT-only, and idempotent', async () => {
  await models.PrivacyRequest.update({ status: 'FAILED', failedAt: new Date() }, { where: { userId: owner.id, requestType: 'EXPORT' } });
  const exportRequest = await post(owner, { requestType: 'EXPORT' }); assert.equal(exportRequest.status, 201);
  const service = new PrivacyExportArtifactService();
  const artifact = await service.create({ userId: owner.id, privacyRequestId: exportRequest.body.data.request.id });
  assert.match(artifact.storageKey, /^[a-f0-9-]{36}\.json$/i); assert.match(artifact.filename, /^amoraa-data-export-[a-f0-9-]+\.json$/i);
  assert.equal(await models.PrivacyExportArtifact.count({ where: { privacyRequestId: artifact.privacyRequestId } }), 1);
  assert.equal((await service.create({ userId: owner.id, privacyRequestId: artifact.privacyRequestId })).id, artifact.id);
  await assert.rejects(() => service.create({ userId: other.id, privacyRequestId: artifact.privacyRequestId }));
  const access = await models.PrivacyRequest.findOne({ where: { userId: other.id, requestType: 'ACCESS' } }); await assert.rejects(() => service.create({ userId: other.id, privacyRequestId: access.id }));
  for (const key of ['../x.json', '..\\x.json', 'C:\\x.json', '/tmp/x.json']) assert.throws(() => service.resolve(key));
  assert.match(service.resolve(artifact.storageKey), /private-exports/); assert.equal(service.resolve(artifact.storageKey).includes('uploads'), false);
  await exportRequest; const request = await models.PrivacyRequest.findByPk(artifact.privacyRequestId); assert.equal(request.status, 'IDENTITY_VERIFICATION_REQUIRED');
});

test('P1.3B generates a bounded private JSON export once and safely returns the same artifact', async () => {
  await models.PrivacyRequest.update({ status: 'FAILED', failedAt: new Date() }, { where: { userId: owner.id, requestType: 'EXPORT' } });
  await models.OtpToken.create({ email: owner.email, codeHash: 'OTP_HASH_EXPORT_SENTINEL', purpose: 'password_reset', expiresAt: new Date(Date.now() + 60_000) });
  await models.IdentityVerification.create({ userId: owner.id, status: 'pending', aadhaarStoragePath: 'KYC_AADHAAR_PATH_SENTINEL', aadhaarMimeType: 'image/jpeg', aadhaarSizeBytes: 1, selfieStoragePath: 'KYC_SELFIE_PATH_SENTINEL', selfieMimeType: 'image/jpeg', selfieSizeBytes: 1, submittedAt: new Date() });
  const created = await post(owner, { requestType: 'EXPORT' });
  const id = created.body.data.request.id;
  assert.equal((await request(`/api/privacy-requests/${id}/export`, { method: 'POST' })).status, 401);
  assert.equal((await request(`/api/privacy-requests/${id}/export`, { method: 'POST', headers: headers(owner), body: JSON.stringify({ status: 'COMPLETED', storageKey: '../unsafe.json', filename: 'unsafe.json', mimeType: 'text/plain' }) })).status, 409);
  const issued = await request(`/api/privacy-requests/${id}/step-up/confirmations`, { method: 'POST', headers: headers(owner), body: JSON.stringify({ password: 'PrivacyPass1!' }) });
  assert.equal(issued.status, 200);
  const verified = await request(`/api/privacy-requests/${id}/step-up/verify`, { method: 'POST', headers: headers(owner), body: JSON.stringify({ confirmation: issued.body.data.confirmation }) });
  assert.equal(verified.status, 200); assert.equal(verified.body.data.request.status, 'VERIFIED');
  assert.equal((await request(`/api/privacy-requests/${id}/export`, { method: 'POST', headers: headers(other) })).status, 404);
  const first = await request(`/api/privacy-requests/${id}/export`, { method: 'POST', headers: headers(owner), body: JSON.stringify({ path: 'C:\\unsafe.json', filename: 'unsafe.json', storageKey: '../unsafe.json', mimeType: 'text/plain', status: 'COMPLETED' }) });
  assert.equal(first.status, 200, JSON.stringify(first.body));
  const safe = first.body.data.artifact;
  for (const forbidden of ['storageKey', 'path', 'publicUrl', 'absolutePath']) assert.equal(Object.hasOwn(safe, forbidden), false);
  assert.equal(safe.status, 'GENERATED'); assert.equal(safe.mimeType, 'application/json'); assert.ok(safe.generatedAt);
  const artifact = await models.PrivacyExportArtifact.findByPk(safe.id);
  const service = new PrivacyExportArtifactService(); const file = service.resolve(artifact.storageKey);
  const filesAfterFirst = (await fs.promises.readdir(require('path').dirname(file))).filter((name) => name.endsWith('.json')).sort();
  const text = await fs.promises.readFile(file, 'utf8'); const json = JSON.parse(text);
  assert.deepEqual(Object.keys(json), ['exportMetadata', 'account', 'profile', 'preferences', 'consents', 'privacyRequests']);
  assert.equal(json.account.id, owner.id); assert.equal(json.account.email, owner.email);
  assert.equal(json.account.passwordHash, undefined); assert.equal(json.account.password, undefined); assert.equal(json.account.tokenVersion, undefined);
  assert.equal(text.includes('PrivacyPass1!'), false); assert.equal(text.includes(owner.passwordHash), false); assert.equal(text.includes('OTP_HASH_EXPORT_SENTINEL'), false); assert.equal(text.includes('KYC_AADHAAR_PATH_SENTINEL'), false); assert.equal(text.includes('KYC_SELFIE_PATH_SENTINEL'), false); assert.equal(text.includes(other.email), false); assert.equal(text.includes(other.name), false);
  assert.equal(text.includes(artifact.storageKey), false); assert.equal(text.includes(file), false); assert.equal(text.includes('private-exports'), false);
  assert.equal(Number(artifact.byteSize), Buffer.byteLength(text));
  const originalGeneratedAt = new Date(artifact.generatedAt).getTime(); const originalChecksum = artifact.checksum;
  const second = await request(`/api/privacy-requests/${id}/export`, { method: 'POST', headers: headers(owner) });
  assert.equal(second.status, 200, JSON.stringify(second.body));
  assert.equal(second.body.data.artifact.id, safe.id); assert.equal(second.body.data.artifact.filename, safe.filename);
  assert.equal(second.body.data.artifact.checksum, originalChecksum); assert.equal(new Date(second.body.data.artifact.generatedAt).getTime(), originalGeneratedAt);
  assert.equal(await models.PrivacyExportArtifact.count({ where: { privacyRequestId: id } }), 1);
  assert.deepEqual((await fs.promises.readdir(require('path').dirname(file))).filter((name) => name.endsWith('.json')).sort(), filesAfterFirst);
  const completed = await models.PrivacyRequest.findByPk(id); assert.equal(completed.status, 'COMPLETED');
  assert.equal((await request(`/api/privacy-requests/${id}/export`, { method: 'POST', headers: headers(other) })).status, 404);
  const access = await models.PrivacyRequest.findOne({ where: { userId: other.id, requestType: 'ACCESS' } });
  assert.equal((await request(`/api/privacy-requests/${access.id}/export`, { method: 'POST', headers: headers(other) })).status, 404);
  const correction = await models.PrivacyRequest.findOne({ where: { userId: owner.id, requestType: 'CORRECTION' } });
  const withdrawal = await models.PrivacyRequest.findOne({ where: { userId: owner.id, requestType: 'WITHDRAWAL' } });
  assert.equal((await request(`/api/privacy-requests/${correction.id}/export`, { method: 'POST', headers: headers(owner) })).status, 404);
  assert.equal((await request(`/api/privacy-requests/${withdrawal.id}/export`, { method: 'POST', headers: headers(owner) })).status, 404);
});

test('P1.3B write failures are controlled, leave no private file, and mark the request failed', async () => {
  await models.PrivacyRequest.update({ status: 'FAILED', failedAt: new Date() }, { where: { userId: other.id, requestType: 'EXPORT' } });
  const created = await post(other, { requestType: 'EXPORT' }); const id = created.body.data.request.id;
  const issued = await request(`/api/privacy-requests/${id}/step-up/confirmations`, { method: 'POST', headers: headers(other), body: JSON.stringify({ password: 'PrivacyPass1!' }) });
  await request(`/api/privacy-requests/${id}/step-up/verify`, { method: 'POST', headers: headers(other), body: JSON.stringify({ confirmation: issued.body.data.confirmation }) });
  const originalWriteFile = fs.promises.writeFile;
  const originalConsoleError = console.error; const logs = [];
  fs.promises.writeFile = async () => { throw new Error('controlled export write failure'); };
  console.error = (...args) => logs.push(args.join(' '));
  try {
    const failed = await request(`/api/privacy-requests/${id}/export`, { method: 'POST', headers: headers(other) });
    assert.equal(failed.status, 500); assert.equal(JSON.stringify(failed.body).includes('controlled export write failure'), false); assert.equal(JSON.stringify(failed.body).includes(' at '), false);
    assert.equal(logs.join(' ').includes('PrivacyPass1!'), false); assert.equal(logs.join(' ').includes('controlled export write failure'), false);
  } finally { fs.promises.writeFile = originalWriteFile; console.error = originalConsoleError; }
  const failedRequest = await models.PrivacyRequest.findByPk(id); const artifact = await models.PrivacyExportArtifact.findOne({ where: { privacyRequestId: id } });
  assert.equal(failedRequest.status, 'FAILED'); assert.equal(failedRequest.completedAt, null); assert.equal(artifact.status, 'FAILED');
  await assert.rejects(() => fs.promises.access(new PrivacyExportArtifactService().resolve(artifact.storageKey)));
});

test('P1.3C serves only a completed owner artifact through a private, stable JSON download', async () => {
  const requestRow = await models.PrivacyRequest.findOne({ where: { userId: owner.id, requestType: 'EXPORT', status: 'COMPLETED' }, order: [['id', 'DESC']] });
  const artifact = await models.PrivacyExportArtifact.findOne({ where: { privacyRequestId: requestRow.id, userId: owner.id } });
  const service = new PrivacyExportArtifactService(); const filePath = service.resolve(artifact.storageKey); const originalBytes = await fs.promises.readFile(filePath);
  const original = { storageKey: artifact.storageKey, filename: artifact.filename, status: artifact.status, userId: artifact.userId, generatedAt: new Date(artifact.generatedAt).getTime(), checksum: artifact.checksum, completedAt: new Date(requestRow.completedAt).getTime() };
  const beforeCount = await models.PrivacyExportArtifact.count({ where: { privacyRequestId: requestRow.id } });
  const beforeFiles = (await fs.promises.readdir(require('path').dirname(filePath))).filter((name) => name.endsWith('.json')).sort();
  assert.equal((await download(null, requestRow.id)).status, 401);
  const first = await download(owner, requestRow.id, '?filename=client.json&storageKey=client.json&path=C:%5Cunsafe.json');
  assert.equal(first.status, 200); assert.match(first.headers.get('content-type'), /^application\/json/); assert.equal(first.headers.get('cache-control'), 'private, no-store'); assert.match(first.headers.get('content-disposition'), new RegExp(`^attachment; filename="${artifact.filename.replace('.', '\\.')}`));
  assert.deepEqual(first.bytes, originalBytes); assert.doesNotThrow(() => JSON.parse(first.text)); assert.equal(first.text.includes(filePath), false); assert.equal(first.text.includes(artifact.storageKey), false);
  assert.equal((await download(other, requestRow.id)).status, 404);
  const access = await models.PrivacyRequest.findOne({ where: { userId: other.id, requestType: 'ACCESS' } }); const correction = await models.PrivacyRequest.findOne({ where: { userId: owner.id, requestType: 'CORRECTION' } }); const withdrawal = await models.PrivacyRequest.findOne({ where: { userId: owner.id, requestType: 'WITHDRAWAL' } });
  assert.equal((await download(other, access.id)).status, 404); assert.equal((await download(owner, correction.id)).status, 404); assert.equal((await download(owner, withdrawal.id)).status, 404);
  await artifact.update({ status: 'PENDING' }); assert.equal((await download(owner, requestRow.id)).status, 409); await artifact.update({ status: original.status });
  await artifact.update({ userId: other.id }); assert.equal((await download(owner, requestRow.id)).status, 409); await artifact.update({ userId: original.userId });
  for (const storageKey of ['../outside.json', '..\\outside.json', 'C:\\outside.json', '/tmp/outside.json']) { await artifact.update({ storageKey }); const blocked = await download(owner, requestRow.id); assert.equal(blocked.status, 409); assert.equal(blocked.text.includes('outside.json'), false); }
  await artifact.update({ storageKey: original.storageKey, filename: 'bad\r\nX-Injected: yes' }); assert.equal((await download(owner, requestRow.id)).status, 409); await artifact.update({ filename: original.filename });
  await fs.promises.unlink(filePath); const originalConsoleError = console.error; const logs = []; console.error = (...args) => logs.push(args.join(' ')); let missing; try { missing = await download(owner, requestRow.id); } finally { console.error = originalConsoleError; } assert.equal(missing.status, 409); assert.equal(missing.text.includes(filePath), false); assert.equal(missing.text.includes('ENOENT'), false); assert.equal(logs.join(' ').includes(filePath), false); assert.equal(logs.join(' ').includes(originalBytes.toString('utf8')), false); await fs.promises.writeFile(filePath, originalBytes, { mode: 0o600 });
  const pending = await post(owner, { requestType: 'EXPORT' }); const pendingRow = await models.PrivacyRequest.findByPk(pending.body.data.request.id);
  assert.equal((await download(owner, pendingRow.id)).status, 409); await pendingRow.update({ status: 'VERIFIED' }); assert.equal((await download(owner, pendingRow.id)).status, 409); await pendingRow.update({ status: 'PROCESSING' }); assert.equal((await download(owner, pendingRow.id)).status, 409); await pendingRow.update({ status: 'FAILED', failedAt: new Date() }); assert.equal((await download(owner, pendingRow.id)).status, 409); await pendingRow.update({ status: 'COMPLETED', completedAt: new Date() }); assert.equal((await download(owner, pendingRow.id)).status, 409);
  const second = await download(owner, requestRow.id); assert.equal(second.status, 200); assert.deepEqual(second.bytes, originalBytes); assert.equal(await models.PrivacyExportArtifact.count({ where: { privacyRequestId: requestRow.id } }), beforeCount); assert.deepEqual((await fs.promises.readdir(require('path').dirname(filePath))).filter((name) => name.endsWith('.json')).sort(), beforeFiles);
  await artifact.reload(); await requestRow.reload(); assert.equal(new Date(artifact.generatedAt).getTime(), original.generatedAt); assert.equal(artifact.checksum, original.checksum); assert.equal(requestRow.status, 'COMPLETED'); assert.equal(new Date(requestRow.completedAt).getTime(), original.completedAt);
});
