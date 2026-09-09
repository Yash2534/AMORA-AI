const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

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
const { app } = require('../src/server');

let models; let server; let baseUrl; let owner; let other;
const tokenFor = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
const headers = (user) => ({ authorization: `Bearer ${tokenFor(user)}`, 'content-type': 'application/json' });
const request = async (path, options = {}) => { const response = await fetch(`${baseUrl}${path}`, options); return { status: response.status, body: await response.json() }; };
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
    await models.PrivacyRequest.destroy({ where: { userId: [owner?.id, other?.id] } });
    await models.User.destroy({ where: { id: [owner?.id, other?.id] } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('privacy request migration supports up, down, and up on the disposable test database', async () => {
  const reverted = await undo({ databaseName: testDatabase, quiet: true });
  assert.equal(reverted, '202609100001-create-privacy-request-p12.js');
  const applied = await migrate({ databaseName: testDatabase, quiet: true });
  assert.deepEqual(applied, ['202609100001-create-privacy-request-p12.js']);
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
