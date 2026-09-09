const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const crypto = require('crypto');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_consent`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) throw new Error('Consent tests require a separate TEST_DB_NAME containing "test".');
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { ConsentService } = require('../src/services/consentService');

let models; let server; let baseUrl; let terms; let privacy; let user; let retiredTerms;
const documentIds = [];
const hash = (value) => crypto.createHash('sha256').update(value).digest('hex');
const request = async (path, options = {}) => { const response = await fetch(`${baseUrl}${path}`, options); return { status: response.status, body: await response.json() }; };
const legalDocuments = () => [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id }, { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id }];

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase(); models = getModels();
  // This suite owns a dedicated schema. Clear fixtures left by an interrupted prior
  // run so the active-document invariant always starts from a known state.
  await models.ConsentEvent.destroy({ where: {} });
  await models.LegalDocumentVersion.destroy({ where: {} });
  const now = new Date(Date.now() - 1000);
  terms = await models.LegalDocumentVersion.create({ documentKey: 'TERMS_OF_SERVICE', version: `test-${Date.now()}`, contentHash: hash('terms canonical content'), publishedAt: now, effectiveAt: now, status: 'ACTIVE' });
  privacy = await models.LegalDocumentVersion.create({ documentKey: 'PRIVACY_POLICY', version: `test-${Date.now()}`, contentHash: hash('privacy canonical content'), publishedAt: now, effectiveAt: now, status: 'ACTIVE' });
  documentIds.push(terms.id, privacy.id);
  user = await models.User.create({ name: 'Consent user', email: `consent-${Date.now()}@test.invalid`, phoneNumber: '', authProvider: 'local', isVerified: true });
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    await models.ConsentEvent.destroy({ where: {} });
    await models.User.destroy({ where: { id: user?.id } });
    await models.LegalDocumentVersion.destroy({ where: { id: documentIds } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('legal document versions validate immutable identity fields and uniqueness', async () => {
  await assert.rejects(() => models.LegalDocumentVersion.create({ documentKey: 'TERMS_OF_SERVICE', version: terms.version, contentHash: hash('other'), publishedAt: new Date(), effectiveAt: new Date(), status: 'ACTIVE' }));
  await assert.rejects(() => models.LegalDocumentVersion.create({ documentKey: 'TERMS_OF_SERVICE', version: 'missing-hash', publishedAt: new Date(), effectiveAt: new Date(), status: 'DRAFT' }));
  await assert.rejects(() => models.LegalDocumentVersion.create({ documentKey: 'TERMS_OF_SERVICE', version: 'bad-status', contentHash: hash('x'), publishedAt: new Date(), effectiveAt: new Date(), status: 'INVALID' }));
});

test('consent events are append-only and preserve withdrawal and re-consent history', async () => {
  const service = new ConsentService();
  const accepted = await service.recordEvent({ userId: user.id, documentVersionId: terms.id, purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'ACCEPTED', source: 'SIGNUP_EMAIL', platform: 'ANDROID' });
  await service.recordEvent({ userId: user.id, documentVersionId: terms.id, purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'WITHDRAWN', source: 'SETTINGS', platform: 'ANDROID' });
  await service.recordEvent({ userId: user.id, documentVersionId: terms.id, purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'RECONSENTED', source: 'RECONSENT_FLOW', platform: 'ANDROID' });
  const history = await models.ConsentEvent.findAll({ where: { userId: user.id, documentVersionId: terms.id }, order: [['occurredAt', 'ASC'], ['id', 'ASC']] });
  assert.deepEqual(history.map((event) => event.action), ['ACCEPTED', 'WITHDRAWN', 'RECONSENTED']);
  assert.equal((await models.ConsentEvent.findByPk(accepted.id)).action, 'ACCEPTED');
  terms.contentHash = hash('mutated terms');
  await assert.rejects(() => terms.save());
  await terms.reload();
  await assert.rejects(() => service.recordEvent({ userId: user.id, documentVersionId: terms.id, purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'INVALID', source: 'SETTINGS', platform: 'ANDROID' }));
});

test('active versions are validated and determine re-consent requirements', async () => {
  const service = new ConsentService();
  const result = await service.recordRequiredSignupConsent({ userId: user.id, acceptedLegalDocuments: legalDocuments(), source: 'SIGNUP_GOOGLE', platform: 'IOS' });
  assert.equal(result.length, 2);
  assert.deepEqual(result.map((event) => event.action).sort(), ['ACCEPTED', 'ACKNOWLEDGED']);
  assert.equal((await service.requiresReconsent(user.id)).requiresLegalAction, false);
  const nextTerms = await models.LegalDocumentVersion.create({ documentKey: 'TERMS_OF_SERVICE', version: `next-${Date.now()}`, contentHash: hash('new terms'), publishedAt: new Date(), effectiveAt: new Date(), status: 'DRAFT' });
  documentIds.push(nextTerms.id);
  await assert.rejects(() => service.recordRequiredSignupConsent({ userId: user.id, acceptedLegalDocuments: [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: nextTerms.id }, { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id }], source: 'RECONSENT_FLOW', platform: 'WEB' }));
  retiredTerms = terms;
  await terms.update({ status: 'RETIRED', retiredAt: new Date() }); await nextTerms.update({ status: 'ACTIVE' }); terms = nextTerms;
  assert.equal((await service.requiresReconsent(user.id)).requiresLegalAction, true);
});

test('signup rejects missing, stale, draft, future, and invalid legal versions atomically', async () => {
  const base = () => ({ name: 'Rejected Consent', email: `rejected-${Date.now()}-${Math.random()}@test.invalid`, phoneNumber: `9${String(Date.now()).slice(-9)}`, password: 'StrongPass1!', confirmPassword: 'StrongPass1!', acceptedTerms: true, platform: 'WEB' });
  const submit = (body) => request('/api/auth/signup', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) });
  const duplicatePrivacy = [{ documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id }, { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id }];
  const missingTerms = await submit({ ...base(), acceptedLegalDocuments: duplicatePrivacy });
  assert.equal(missingTerms.status, 422); assert.equal(missingTerms.body.code, 'TERMS_ACCEPTANCE_REQUIRED');
  const missingPrivacy = await submit({ ...base(), acceptedLegalDocuments: [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id }, { documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id }] });
  assert.equal(missingPrivacy.status, 422); assert.equal(missingPrivacy.body.code, 'PRIVACY_ACKNOWLEDGEMENT_REQUIRED');
  const stale = await submit({ ...base(), acceptedLegalDocuments: [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: retiredTerms.id }, { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id }] });
  assert.equal(stale.status, 422); assert.equal(stale.body.code, 'LEGAL_DOCUMENT_VERSION_OUTDATED');
  const draft = await models.LegalDocumentVersion.create({ documentKey: 'PRIVACY_POLICY', version: `draft-${Date.now()}`, contentHash: hash('draft privacy'), publishedAt: new Date(), effectiveAt: new Date(), status: 'DRAFT' }); documentIds.push(draft.id);
  const draftAttempt = await submit({ ...base(), acceptedLegalDocuments: [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id }, { documentKey: 'PRIVACY_POLICY', documentVersionId: draft.id }] });
  assert.equal(draftAttempt.status, 422); assert.equal(draftAttempt.body.code, 'LEGAL_DOCUMENT_VERSION_OUTDATED');
  const future = await models.LegalDocumentVersion.create({ documentKey: 'PRIVACY_POLICY', version: `future-${Date.now()}`, contentHash: hash('future privacy'), publishedAt: new Date(), effectiveAt: new Date(Date.now() + 86400000), status: 'ACTIVE' }); documentIds.push(future.id);
  const futureAttempt = await submit({ ...base(), acceptedLegalDocuments: [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id }, { documentKey: 'PRIVACY_POLICY', documentVersionId: future.id }] });
  assert.equal(futureAttempt.status, 422); assert.equal(futureAttempt.body.code, 'LEGAL_DOCUMENT_VERSION_OUTDATED');
  const invalid = await submit({ ...base(), acceptedLegalDocuments: [{ documentKey: 'TERMS_OF_SERVICE', documentVersionId: 999999999 }, { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id }] });
  assert.equal(invalid.status, 422); assert.equal(invalid.body.code, 'LEGAL_DOCUMENT_VERSION_OUTDATED');
  assert.equal(await models.User.count({ where: { name: 'Rejected Consent' } }), 0);
});

test('email signup creates separate versioned legal events atomically', async () => {
  const legal = await request('/api/auth/legal-documents/signup');
  assert.equal(legal.status, 200);
  const email = `signup-${Date.now()}@test.invalid`;
  const signup = await request('/api/auth/signup', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ name: 'Signup Consent', email, phoneNumber: `9${String(Date.now()).slice(-9)}`, password: 'StrongPass1!', confirmPassword: 'StrongPass1!', acceptedTerms: true, acceptedLegalDocuments: legal.body.data.documents.map((item) => ({ documentKey: item.documentKey, documentVersionId: Number(item.documentVersionId) })), platform: 'WEB' }) });
  assert.equal(signup.status, 200, JSON.stringify(signup.body));
  const created = await models.User.findOne({ where: { email } });
  const events = await models.ConsentEvent.findAll({ where: { userId: created.id }, order: [['id', 'ASC']] });
  assert.deepEqual(events.map((event) => event.action), ['ACCEPTED', 'ACKNOWLEDGED']);
  assert.deepEqual(events.map((event) => event.source), ['SIGNUP_EMAIL', 'SIGNUP_EMAIL']);
  assert.equal(created.termsAcceptedAt, null);
  const duplicate = await request('/api/auth/signup', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ name: 'Signup Consent', email, phoneNumber: `9${String(Date.now()).slice(-9)}`, password: 'StrongPass1!', confirmPassword: 'StrongPass1!', acceptedTerms: true, acceptedLegalDocuments: legalDocuments(), platform: 'WEB' }) });
  assert.equal(duplicate.status, 409);
  assert.equal(await models.ConsentEvent.count({ where: { userId: created.id } }), 2);
  await models.ConsentEvent.destroy({ where: { userId: created.id } }); await models.User.destroy({ where: { id: created.id } });
});
