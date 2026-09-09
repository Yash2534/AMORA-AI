const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const baseTestDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
const testDatabase = `${baseTestDatabase}_google_signup_consent`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Google signup consent tests require an isolated TEST_DB_NAME containing "test".');
}
const originalEnvironment = Object.fromEntries(['DB_NAME', 'NODE_ENV', 'GOOGLE_CLIENT_IDS'].map((key) => [key, process.env[key]]));
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
process.env.GOOGLE_CLIENT_IDS = 'local-google-test-client';

let googlePayload;
const googleLibraryPath = require.resolve('google-auth-library');
const originalGoogleLibrary = require.cache[googleLibraryPath];
class MockOAuth2Client {
  async verifyIdToken() {
    if (!googlePayload) throw new Error('Invalid mocked Google token.');
    return { getPayload: () => googlePayload };
  }
}
require.cache[googleLibraryPath] = {
  id: googleLibraryPath,
  filename: googleLibraryPath,
  loaded: true,
  exports: { OAuth2Client: MockOAuth2Client },
};

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let models;
let server;
let baseUrl;
let terms;
let privacy;
const createdUserIds = [];
const legalDocumentIds = [];
const hash = (value) => crypto.createHash('sha256').update(value).digest('hex');
const legalDocuments = () => [
  { documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id },
  { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id },
];

async function request(body) {
  const response = await fetch(`${baseUrl}/api/auth/google`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ idToken: 'locally-mocked-google-id-token', platform: 'WEB', ...body }),
  });
  return { status: response.status, body: await response.json() };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  const now = new Date(Date.now() - 1000);
  terms = await models.LegalDocumentVersion.create({
    documentKey: 'TERMS_OF_SERVICE',
    version: `google-consent-${Date.now()}`,
    contentHash: hash('google signup terms'),
    publishedAt: now,
    effectiveAt: now,
    status: 'ACTIVE',
  });
  privacy = await models.LegalDocumentVersion.create({
    documentKey: 'PRIVACY_POLICY',
    version: `google-consent-${Date.now()}`,
    contentHash: hash('google signup privacy'),
    publishedAt: now,
    effectiveAt: now,
    status: 'ACTIVE',
  });
  legalDocumentIds.push(terms.id, privacy.id);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    await models.ConsentEvent.destroy({ where: { userId: createdUserIds } });
    await models.RefreshToken.destroy({ where: { userId: createdUserIds } });
    await models.User.destroy({ where: { id: createdUserIds } });
    await models.LegalDocumentVersion.destroy({ where: { id: legalDocumentIds } });
  }
  try { await getSequelize().close(); } catch (_) {}
  if (originalGoogleLibrary) require.cache[googleLibraryPath] = originalGoogleLibrary;
  else delete require.cache[googleLibraryPath];
  for (const [key, value] of Object.entries(originalEnvironment)) {
    if (value === undefined) delete process.env[key]; else process.env[key] = value;
  }
});

test('mocked Google signup records current Terms and Privacy evidence once', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const email = `google-consent-${suffix}@auth-flow.test`;
  googlePayload = { sub: `google-sub-${suffix}`, email, name: 'Mocked Google User' };

  const created = await request({ acceptedLegalDocuments: legalDocuments() });
  assert.equal(created.status, 200, JSON.stringify(created.body));
  assert.equal(created.body.data.isNewUser, true);
  const user = await models.User.findOne({ where: { email } });
  createdUserIds.push(user.id);
  assert.equal(user.authProvider, 'google');
  assert.equal(user.googleId, googlePayload.sub);

  const events = await models.ConsentEvent.findAll({
    where: { userId: user.id },
    order: [['id', 'ASC']],
  });
  assert.deepEqual(events.map((event) => event.documentVersionId), [terms.id, privacy.id]);
  assert.deepEqual(events.map((event) => event.action), ['ACCEPTED', 'ACKNOWLEDGED']);
  assert.deepEqual(events.map((event) => event.source), ['SIGNUP_GOOGLE', 'SIGNUP_GOOGLE']);
  assert.deepEqual(events.map((event) => event.platform), ['WEB', 'WEB']);

  const returning = await request({ acceptedLegalDocuments: legalDocuments() });
  assert.equal(returning.status, 200, JSON.stringify(returning.body));
  assert.equal(returning.body.data.isNewUser, false);
  assert.equal(await models.ConsentEvent.count({ where: { userId: user.id } }), 2);
});

test('mocked Google signup rejects missing Terms or Privacy without creating a user', async () => {
  const suffix = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  googlePayload = { sub: `google-missing-terms-${suffix}`, email: `google-missing-terms-${suffix}@auth-flow.test`, name: 'Missing Terms' };
  const missingTerms = await request({
    acceptedLegalDocuments: [
      { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id },
      { documentKey: 'PRIVACY_POLICY', documentVersionId: privacy.id },
    ],
  });
  assert.equal(missingTerms.status, 422);
  assert.equal(missingTerms.body.code, 'TERMS_ACCEPTANCE_REQUIRED');
  assert.equal(await models.User.count({ where: { email: googlePayload.email } }), 0);

  googlePayload = { sub: `google-missing-privacy-${suffix}`, email: `google-missing-privacy-${suffix}@auth-flow.test`, name: 'Missing Privacy' };
  const missingPrivacy = await request({
    acceptedLegalDocuments: [
      { documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id },
      { documentKey: 'TERMS_OF_SERVICE', documentVersionId: terms.id },
    ],
  });
  assert.equal(missingPrivacy.status, 422);
  assert.equal(missingPrivacy.body.code, 'PRIVACY_ACKNOWLEDGEMENT_REQUIRED');
  assert.equal(await models.User.count({ where: { email: googlePayload.email } }), 0);
});
