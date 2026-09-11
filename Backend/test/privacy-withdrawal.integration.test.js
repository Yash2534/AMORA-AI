const assert = require('node:assert/strict');
const { before, after, test } = require('node:test');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { Sequelize } = require('sequelize');

require('../src/config/bootstrapEnv');
const base = process.env.TEST_DB_NAME || `${process.env.DB_NAME}_test`;
const databaseName = `${base}_privacy_withdrawal`;
process.env.DB_NAME = databaseName;
process.env.NODE_ENV = 'test';
const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { PrivacyRequestService } = require('../src/services/privacyRequestService');
const { createNotification } = require('../src/services/notificationService');

let models; let server; let baseUrl;
const userIds = []; const documentIds = [];
const token = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '5m' });
const headers = (user, extra = {}) => ({ authorization: `Bearer ${token(user)}`, 'content-type': 'application/json', ...extra });
const request = async (path, options = {}) => { const response = await fetch(`${baseUrl}${path}`, options); return { status: response.status, body: await response.json() }; };
const post = (user, path, body = {}, extraHeaders = {}) => request(path, { method: 'POST', headers: headers(user, extraHeaders), body: JSON.stringify(body) });
const createWithdrawal = (user, purposes = ['OFFERS_NOTIFICATIONS'], extra = {}) => post(user, '/api/privacy-requests', { requestType: 'WITHDRAWAL', purposes, ...extra });
const getConsentState = (user) => request('/api/privacy-requests/withdrawable-consents', { headers: headers(user) });

async function createUser(label, { offers = true } = {}) {
  const user = await models.User.create({ name: label, email: `withdraw-${label.replace(/\W/g, '')}-${Date.now()}-${userIds.length}@test.invalid`, phoneNumber: '', authProvider: 'local', passwordHash: await bcrypt.hash('WithdrawPass1!', 4), isVerified: true });
  userIds.push(user.id);
  await models.NotificationPreference.create({ userId: user.id, offers, newMatches: true });
  return user;
}

async function issue(user, id) {
  const result = await post(user, `/api/privacy-requests/${id}/step-up/confirmations`, { password: 'WithdrawPass1!' });
  assert.equal(result.status, 200, JSON.stringify(result.body));
  return result.body.data.confirmation;
}
async function verify(user, id, confirmation = null) {
  const secret = confirmation || await issue(user, id);
  return request(`/api/privacy-requests/${id}/step-up/verify`, { method: 'POST', headers: headers(user), body: JSON.stringify({ confirmation: secret }) });
}
async function verifiedWithdrawal(user) {
  const created = await createWithdrawal(user); assert.equal(created.status, 201, JSON.stringify(created.body));
  const id = Number(created.body.data.request.id); const confirmation = await issue(user, id);
  const verified = await verify(user, id, confirmation); assert.equal(verified.status, 200, JSON.stringify(verified.body));
  return { id, confirmation };
}
async function optionalGrant(user, occurredAt = new Date()) {
  return models.ConsentEvent.create({ userId: user.id, documentVersionId: null, purpose: 'OFFERS_NOTIFICATIONS', action: 'ACCEPTED', source: 'SETTINGS', platform: 'WEB', occurredAt });
}
async function legalEvidence(user) {
  const now = new Date();
  const terms = await models.LegalDocumentVersion.create({ documentKey: 'TERMS_OF_SERVICE', version: `withdraw-terms-${Date.now()}-${documentIds.length}`, contentHash: 'a'.repeat(64), publishedAt: now, effectiveAt: now, status: 'ACTIVE' });
  const privacy = await models.LegalDocumentVersion.create({ documentKey: 'PRIVACY_POLICY', version: `withdraw-privacy-${Date.now()}-${documentIds.length}`, contentHash: 'b'.repeat(64), publishedAt: now, effectiveAt: now, status: 'ACTIVE' });
  documentIds.push(terms.id, privacy.id);
  await models.ConsentEvent.bulkCreate([
    { userId: user.id, documentVersionId: terms.id, purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'ACCEPTED', source: 'SIGNUP', platform: 'WEB', occurredAt: now },
    { userId: user.id, documentVersionId: privacy.id, purpose: 'PRIVACY_POLICY_ACKNOWLEDGEMENT', action: 'ACKNOWLEDGED', source: 'SIGNUP', platform: 'WEB', occurredAt: now },
  ]);
  return { terms, privacy };
}

before(async () => {
  await migrate({ databaseName, quiet: true }); await initializeDatabase(); models = getModels();
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});
after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    if (models.Notification) await models.Notification.destroy({ where: { userId: userIds } });
    await models.ConsentEvent.destroy({ where: { userId: userIds } });
    await models.PrivacyRequestConfirmation.destroy({ where: { userId: userIds } });
    await models.PrivacyRequest.destroy({ where: { userId: userIds } });
    await models.NotificationPreference.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
    await models.LegalDocumentVersion.destroy({ where: { id: documentIds } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('P1.4 migrations support disposable UP to DOWN to UP without withdrawal evidence', async () => {
  const qi = getSequelize().getQueryInterface(); const first = require('../src/migrations/202609120001-add-offers-withdrawal-consent'); const second = require('../src/migrations/202609120002-fix-offers-consent-nullability');
  assert.equal((await qi.describeTable('ConsentEvents')).documentVersionId.allowNull, true);
  await second.down(qi, Sequelize); await first.down(qi, Sequelize); assert.equal((await qi.describeTable('ConsentEvents')).documentVersionId.allowNull, false);
  await first.up(qi, Sequelize); await second.up(qi, Sequelize); assert.equal((await qi.describeTable('ConsentEvents')).documentVersionId.allowNull, true);
  const user = await createUser('migration-read-write'); await optionalGrant(user); assert.equal(await models.ConsentEvent.count({ where: { userId: user.id, purpose: 'OFFERS_NOTIFICATIONS' } }), 1);
});

test('withdrawal requires authentication and server allowlists the only actual purpose', async () => {
  const unauth = await request('/api/privacy-requests', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ requestType: 'WITHDRAWAL', purposes: ['OFFERS_NOTIFICATIONS'] }) }); assert.equal(unauth.status, 401);
  const user = await createUser('scope');
  for (const payload of [{ requestType: 'WITHDRAWAL', purposes: [] }, { requestType: 'WITHDRAWAL', purposes: null }, { requestType: 'WITHDRAWAL', purposes: [''] }, { requestType: 'WITHDRAWAL', purposes: ['UNKNOWN'] }, { requestType: 'WITHDRAWAL', purposes: ['OFFERS_NOTIFICATIONS', 'OFFERS_NOTIFICATIONS'] }, { requestType: 'WITHDRAWAL', purposes: ['TERMS_OF_SERVICE_ACCEPTANCE'] }, { requestType: 'WITHDRAWAL', purposes: ['PRIVACY_POLICY_ACKNOWLEDGEMENT'] }, { requestType: 'WITHDRAWAL', purposes: ['OFFERS_NOTIFICATIONS'], status: 'COMPLETED' }]) assert.equal((await post(user, '/api/privacy-requests', payload)).status, 400, JSON.stringify(payload));
  const created = await createWithdrawal(user); assert.equal(created.status, 201); assert.equal(created.body.data.request.status, 'IDENTITY_VERIFICATION_REQUIRED');
});

test('step-up is exact-purpose, request-bound, user-bound, expired and single-use', async () => {
  const a = await createUser('binding-a'); const b = await createUser('binding-b');
  const first = await createWithdrawal(a); const firstId = Number(first.body.data.request.id); const confirmation = await issue(a, firstId);
  const stored = await models.PrivacyRequestConfirmation.findOne({ where: { privacyRequestId: firstId } }); assert.equal(stored.purpose, 'privacy_withdrawal_step_up'); assert.notEqual(stored.tokenHash, confirmation);
  assert.equal((await verify(b, firstId, confirmation)).status, 404); await stored.update({ expiresAt: new Date(Date.now() - 1000) }); assert.equal((await verify(a, firstId, confirmation)).status, 401); assert.equal((await post(a, `/api/privacy-requests/${firstId}/withdrawal`)).status, 409); assert.equal(await models.ConsentEvent.count({ where: { userId: a.id, action: 'WITHDRAWN' } }), 0);
  const mismatch = await createWithdrawal(b); const mismatchId = Number(mismatch.body.data.request.id); const generic = PrivacyRequestService.confirmationToken();
  await models.PrivacyRequestConfirmation.create({ privacyRequestId: mismatchId, userId: b.id, tokenSelector: generic.selector, tokenHash: generic.hash, purpose: 'privacy_request_step_up', expiresAt: new Date(Date.now() + 60000) });
  assert.equal((await verify(b, mismatchId, generic.token)).status, 401); assert.equal((await post(b, `/api/privacy-requests/${mismatchId}/withdrawal`)).status, 409);
  await models.PrivacyRequest.update({ status: 'FAILED' }, { where: { id: mismatchId } }); const second = await createWithdrawal(b); const secondId = Number(second.body.data.request.id); assert.equal((await verify(b, secondId, generic.token)).status, 401);
});

test('a real withdrawal confirmation is bound to its exact request and cannot verify a later request', async () => {
  const user = await createUser('request-binding');
  const first = await createWithdrawal(user); const firstId = Number(first.body.data.request.id); const confirmation = await issue(user, firstId);
  await models.PrivacyRequest.update({ status: 'FAILED', failedAt: new Date(), failureCode: 'TEST_SUPERSEDED' }, { where: { id: firstId } });
  const second = await createWithdrawal(user); const secondId = Number(second.body.data.request.id);
  assert.equal((await verify(user, secondId, confirmation)).status, 401);
  assert.equal((await models.PrivacyRequest.findByPk(secondId)).status, 'IDENTITY_VERIFICATION_REQUIRED');
  assert.equal(await models.ConsentEvent.count({ where: { userId: user.id, purpose: 'OFFERS_NOTIFICATIONS', action: 'WITHDRAWN' } }), 0);
});

test('owner scope and client lifecycle tampering fail closed', async () => {
  const a = await createUser('owner-a'); const b = await createUser('owner-b'); const { id } = await verifiedWithdrawal(a);
  assert.equal((await request(`/api/privacy-requests/${id}`, { headers: headers(b) })).status, 404); assert.equal((await post(b, `/api/privacy-requests/${id}/withdrawal`, { userId: b.id, status: 'COMPLETED' })).status, 404);
  const tampered = await post(a, `/api/privacy-requests/${id}/withdrawal`, { status: 'COMPLETED', completedAt: '2000-01-01', userId: b.id, correlationId: 'client', action: 'ACCEPTED', occurredAt: '2000-01-01' }); assert.equal(tampered.status, 200, JSON.stringify(tampered.body));
  const row = await models.PrivacyRequest.findByPk(id); assert.equal(row.userId, a.id); assert.equal(row.status, 'COMPLETED'); assert.notEqual(new Date(row.completedAt).getFullYear(), 2000); assert.equal((await models.NotificationPreference.findByPk(a.id)).offers, false); assert.equal((await models.NotificationPreference.findByPk(b.id)).offers, true);
});

test('completed withdrawal is idempotent and a consumed confirmation cannot authorize another request', async () => {
  const user = await createUser('replay'); const { id, confirmation } = await verifiedWithdrawal(user); assert.equal((await post(user, `/api/privacy-requests/${id}/withdrawal`)).status, 200);
  const before = await models.ConsentEvent.count({ where: { userId: user.id, purpose: 'OFFERS_NOTIFICATIONS', action: 'WITHDRAWN' } }); assert.equal((await post(user, `/api/privacy-requests/${id}/withdrawal`)).status, 200); assert.equal(await models.ConsentEvent.count({ where: { userId: user.id, purpose: 'OFFERS_NOTIFICATIONS', action: 'WITHDRAWN' } }), before);
  const next = await createWithdrawal(user); const nextId = Number(next.body.data.request.id); assert.equal((await verify(user, nextId, confirmation)).status, 401); assert.equal((await post(user, `/api/privacy-requests/${nextId}/withdrawal`)).status, 409);
});

test('current consent state is append-only evidence first with truthful legacy preference fallback', async () => {
  const granted = await createUser('granted', { offers: true }); await optionalGrant(granted); assert.equal((await getConsentState(granted)).body.data.consents[0].status, 'granted');
  const { id } = await verifiedWithdrawal(granted); assert.equal((await post(granted, `/api/privacy-requests/${id}/withdrawal`)).status, 200); assert.equal((await getConsentState(granted)).body.data.consents[0].status, 'withdrawn'); assert.equal(await models.ConsentEvent.count({ where: { userId: granted.id, purpose: 'OFFERS_NOTIFICATIONS', action: 'ACCEPTED' } }), 1);
  const legacyEnabled = await createUser('legacy-enabled', { offers: true }); const legacyDisabled = await createUser('legacy-disabled', { offers: false }); assert.equal((await getConsentState(legacyEnabled)).body.data.consents[0].status, 'granted'); assert.equal((await getConsentState(legacyDisabled)).body.data.consents[0].status, 'withdrawn');
});

test('withdrawal suppresses the real offer-notification path without disabling unrelated preferences', async () => {
  const user = await createUser('notification'); const before = await createNotification({ userId: user.id, type: 'offer', category: 'offer', title: 'Offer', message: 'before' }); assert.ok(before);
  const { id } = await verifiedWithdrawal(user); assert.equal((await post(user, `/api/privacy-requests/${id}/withdrawal`)).status, 200); assert.equal(await createNotification({ userId: user.id, type: 'offer', category: 'offer', title: 'Offer', message: 'after' }), null);
  const unrelated = await createNotification({ userId: user.id, type: 'like', category: 'likes', title: 'Like', message: 'unrelated' }); assert.ok(unrelated); const preference = await models.NotificationPreference.findByPk(user.id); assert.equal(preference.offers, false); assert.equal(preference.newMatches, true);
});

test('historical terms and privacy evidence remains immutable and withdrawal does not delete the account', async () => {
  const user = await createUser('history'); const docs = await legalEvidence(user); await optionalGrant(user); const before = await models.ConsentEvent.count({ where: { userId: user.id } }); const { id } = await verifiedWithdrawal(user); assert.equal((await post(user, `/api/privacy-requests/${id}/withdrawal`)).status, 200);
  assert.equal(await models.LegalDocumentVersion.count({ where: { id: [docs.terms.id, docs.privacy.id] } }), 2); assert.equal(await models.ConsentEvent.count({ where: { userId: user.id } }), before + 1); assert.equal(await models.ConsentEvent.count({ where: { userId: user.id, purpose: ['TERMS_OF_SERVICE_ACCEPTANCE', 'PRIVACY_POLICY_ACKNOWLEDGEMENT'] } }), 2); assert.equal(await models.User.count({ where: { id: user.id } }), 1); assert.equal(await models.AccountDeletionRequest.count({ where: { userId: user.id } }), 0);
});

test('concurrent real processing produces one preference transition and one withdrawal event', async () => {
  const user = await createUser('concurrent'); const { id } = await verifiedWithdrawal(user); const results = await Promise.all([post(user, `/api/privacy-requests/${id}/withdrawal`), post(user, `/api/privacy-requests/${id}/withdrawal`)]); assert.ok(results.every((result) => result.status === 200), JSON.stringify(results)); assert.equal(await models.ConsentEvent.count({ where: { userId: user.id, purpose: 'OFFERS_NOTIFICATIONS', action: 'WITHDRAWN' } }), 1); assert.equal((await models.NotificationPreference.findByPk(user.id)).offers, false); assert.equal((await models.PrivacyRequest.findByPk(id)).status, 'COMPLETED');
});

test('controlled persistence failure rolls back evidence and preference before safe failure state', async () => {
  const user = await createUser('rollback'); const { id } = await verifiedWithdrawal(user); const original = models.ConsentEvent.create; models.ConsentEvent.create = async () => { throw new Error('controlled persistence failure'); };
  try { const result = await post(user, `/api/privacy-requests/${id}/withdrawal`); assert.equal(result.status, 500); assert.equal(result.body.code, 'WITHDRAWAL_PROCESSING_FAILED'); } finally { models.ConsentEvent.create = original; }
  assert.equal((await models.NotificationPreference.findByPk(user.id)).offers, true); assert.equal(await models.ConsentEvent.count({ where: { userId: user.id, purpose: 'OFFERS_NOTIFICATIONS', action: 'WITHDRAWN' } }), 0); const row = await models.PrivacyRequest.findByPk(id); assert.equal(row.status, 'FAILED'); assert.notEqual(row.status, 'COMPLETED');
});

test('withdrawal responses contain no confirmation hash, credentials, other-user state, or internal preference object', async () => {
  const user = await createUser('redaction'); const other = await createUser('redaction-other'); const { id } = await verifiedWithdrawal(user); const result = await post(user, `/api/privacy-requests/${id}/withdrawal`); assert.equal(result.status, 200);
  const serialized = JSON.stringify(result.body); for (const secret of ['WithdrawPass1!', 'passwordHash', 'tokenHash', 'confirmation', String(other.id), 'accessToken', 'refreshToken']) assert.equal(serialized.includes(secret), false, secret); assert.equal((await getConsentState(other)).body.data.consents.length, 1);
});
