const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Own-profile integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server;
let baseUrl;
let models;
let owner;
let token;

async function request(path, { method = 'GET', body, authenticated = true } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(authenticated ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  const suffix = `${Date.now()}_${Math.random()}`;
  owner = await models.User.create({
    name: 'Own Profile User',
    email: `${suffix}@profile.test`,
    phoneNumber: '+910000000000',
    passwordHash: 'never-return-this',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
  });
  await models.OnboardingProfile.create({
    userId: owner.id,
    birthDate: '1997-04-03',
    gender: 'Female',
    interestedIn: ['Male'],
    relationshipGoals: ['Meaningful Dating'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    company: 'AMORAA Test',
    education: 'Graduate',
    bio: 'A canonical profile bio long enough for completion checks.',
    interests: ['Music', 'Coffee', 'Travel', 'Reading', 'Fitness'],
    lifestyle: {
      Height: '165 cm',
      Languages: 'Gujarati & English',
      Religion: 'Hindu',
      Smoking: 'Never',
    },
    prompts: { 'A perfect day': 'Coffee and a long walk.' },
    photos: ['/uploads/own-one.jpg', '/uploads/own-two.jpg'],
    primaryPhotoIndex: 1,
    communicationStyle: 'calls',
    stage: 'complete',
    onboardingCompleted: true,
  });
  token = jwt.sign({ sub: owner.id, ver: owner.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '15m' });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  await models.OnboardingProfile.destroy({ where: { userId: owner.id } });
  await models.User.destroy({ where: { id: owner.id } });
  await getSequelize().close();
});

test('GET /api/me/profile requires Bearer authentication', async () => {
  const response = await request('/api/me/profile', { authenticated: false });
  assert.equal(response.status, 401);
  assert.equal(response.body.code, 'TOKEN_INVALID');
});

test('PUT /api/me/profile requires Bearer authentication', async () => {
  const response = await request('/api/me/profile', {
    method: 'PUT',
    body: { bio: 'unauthorized' },
    authenticated: false,
  });
  assert.equal(response.status, 401);
});

test('GET returns the complete editable canonical profile without private fields', async () => {
  const response = await request('/api/me/profile');
  assert.equal(response.status, 200);
  const profile = response.body.data.profile;
  assert.equal(profile.name, 'Own Profile User');
  assert.equal(profile.email, owner.email);
  assert.equal(profile.birthdate, '03/04/1997');
  assert.equal(profile.customGender, '');
  assert.deepEqual(profile.photos, [
    `${baseUrl}/uploads/own-one.jpg`,
    `${baseUrl}/uploads/own-two.jpg`,
  ]);
  assert.deepEqual(profile.prompts, { 'A perfect day': 'Coffee and a long walk.' });
  assert.deepEqual(profile.interests, ['Music', 'Coffee', 'Travel', 'Reading', 'Fitness']);
  assert.equal(profile.communicationStyle, 'calls');
  assert.equal(typeof profile.profileCompletion.percentage, 'number');
  for (const key of ['passwordHash', 'tokenVersion', 'role', 'accountStatus', 'isVerified', 'deletedAt']) {
    assert.equal(Object.hasOwn(profile, key), false, `${key} must not be exposed`);
  }
});

test('PUT persists canonical relations and public profile reads the same records', async () => {
  const update = await request('/api/me/profile', {
    method: 'PUT',
    body: {
      name: 'Canonical Edited Name',
      bio: 'Updated server-backed biography that remains visible after reload.',
      profession: 'Product Engineer',
      education: 'Masters',
      interests: ['Coffee', 'Design', 'Travel'],
      prompts: { 'My simple pleasure': 'Fresh filter coffee.' },
      iceBreaker: 'What is your favorite hidden cafe?',
      lifestyle: {
        Height: '170 cm',
        Languages: 'Hindi & English',
        Religion: 'Jain',
        Exercise: 'Daily',
      },
      communicationStyle: 'voice_notes',
    },
  });
  assert.equal(update.status, 200, JSON.stringify(update.body));
  assert.equal(update.body.data.profile.name, 'Canonical Edited Name');
  assert.equal(update.body.data.profile.communicationStyle, 'voice_notes');

  const reloaded = await request('/api/me/profile');
  assert.equal(reloaded.body.data.profile.bio, 'Updated server-backed biography that remains visible after reload.');
  assert.deepEqual(reloaded.body.data.profile.prompts, { 'My simple pleasure': 'Fresh filter coffee.' });
  assert.deepEqual(reloaded.body.data.profile.interests, ['Coffee', 'Design', 'Travel']);

  const publicResponse = await request(`/api/profiles/${owner.id}`);
  assert.equal(publicResponse.status, 200, JSON.stringify(publicResponse.body));
  const publicProfile = publicResponse.body.data.profile;
  assert.equal(publicProfile.name, 'Canonical Edited Name');
  assert.equal(publicProfile.bio, reloaded.body.data.profile.bio);
  assert.deepEqual(publicProfile.promptAnswers, reloaded.body.data.profile.prompts);
  assert.deepEqual(publicProfile.interests, reloaded.body.data.profile.interests);
  assert.equal(publicProfile.iceBreaker, reloaded.body.data.profile.iceBreaker);
  assert.equal(publicProfile.height, '170 cm');
  assert.deepEqual(publicProfile.languages, ['Hindi', 'English']);
  assert.equal(publicProfile.religion, 'Jain');
  assert.equal(publicProfile.communicationStyle, 'voice_notes');

  const storedUser = await models.User.findByPk(owner.id);
  const storedProfile = await models.OnboardingProfile.findOne({ where: { userId: owner.id } });
  assert.equal(storedUser.name, 'Canonical Edited Name');
  assert.equal(storedProfile.bio, reloaded.body.data.profile.bio);
  assert.deepEqual(storedProfile.prompts, reloaded.body.data.profile.prompts);
  assert.equal(storedProfile.iceBreaker, 'What is your favorite hidden cafe?');
  assert.equal(await models.OnboardingProfile.count({ where: { userId: owner.id } }), 1);
});

test('partial update preserves omitted editable fields', async () => {
  const before = await request('/api/me/profile');
  const response = await request('/api/me/profile', { method: 'PUT', body: { bio: 'Only the biography changed and all omitted fields remain.' } });
  assert.equal(response.status, 200);
  assert.equal(response.body.data.profile.bio, 'Only the biography changed and all omitted fields remain.');
  assert.equal(response.body.data.profile.company, before.body.data.profile.company);
  assert.equal(response.body.data.profile.education, before.body.data.profile.education);
  assert.equal(response.body.data.profile.communicationStyle, before.body.data.profile.communicationStyle);
  assert.deepEqual(response.body.data.profile.interests, before.body.data.profile.interests);
  assert.deepEqual(response.body.data.profile.prompts, before.body.data.profile.prompts);

  const reloaded = await request('/api/me/profile');
  assert.equal(reloaded.body.data.profile.bio, 'Only the biography changed and all omitted fields remain.');
  assert.equal(reloaded.body.data.profile.company, before.body.data.profile.company);
  assert.deepEqual(reloaded.body.data.profile.interests, before.body.data.profile.interests);
});

test('partial update persists multiple submitted fields and preserves every omitted field', async () => {
  const before = await request('/api/me/profile');
  const response = await request('/api/me/profile', {
    method: 'PUT',
    body: {
      bio: 'Two submitted profile values changed together.',
      communicationStyle: 'frequent_texting',
      lifestyle: { ...before.body.data.profile.lifestyle, Height: '172 cm' },
    },
  });
  assert.equal(response.status, 200, JSON.stringify(response.body));
  assert.equal(response.body.data.profile.bio, 'Two submitted profile values changed together.');
  assert.equal(response.body.data.profile.communicationStyle, 'frequent_texting');
  assert.equal(response.body.data.profile.lifestyle.Height, '172 cm');
  assert.equal(response.body.data.profile.name, before.body.data.profile.name);
  assert.equal(response.body.data.profile.education, before.body.data.profile.education);
  assert.deepEqual(response.body.data.profile.interests, before.body.data.profile.interests);

  const storedProfile = await models.OnboardingProfile.findOne({ where: { userId: owner.id } });
  assert.equal(storedProfile.bio, 'Two submitted profile values changed together.');
  assert.equal(storedProfile.communicationStyle, 'frequent_texting');
  assert.equal(storedProfile.lifestyle.Height, '172 cm');
});

test('custom education persists unchanged through API, database, and reload', async () => {
  const education = 'Diploma in Fashion Design';
  const response = await request('/api/me/profile', {
    method: 'PUT',
    body: { education },
  });
  assert.equal(response.status, 200, JSON.stringify(response.body));
  assert.equal(response.body.data.profile.education, education);

  const storedProfile = await models.OnboardingProfile.findOne({ where: { userId: owner.id } });
  assert.equal(storedProfile.education, education);

  const reloaded = await request('/api/me/profile');
  assert.equal(reloaded.status, 200, JSON.stringify(reloaded.body));
  assert.equal(reloaded.body.data.profile.education, education);
});

test('gender uses the canonical enum and clears an obsolete custom label', async () => {
  await models.OnboardingProfile.update(
    { gender: 'Other', customGender: 'Non-binary' },
    { where: { userId: owner.id } },
  );
  const response = await request('/api/me/profile', {
    method: 'PUT',
    body: { gender: 'Male' },
  });
  assert.equal(response.status, 200, JSON.stringify(response.body));
  assert.equal(response.body.data.profile.gender, 'Male');
  assert.equal(response.body.data.profile.customGender, '');
});

test('validation rejects invalid values, underage dates, and mass assignment', async () => {
  const cases = [
    { body: { communicationStyle: 'telepathy' }, field: 'communicationStyle' },
    { body: { gender: 'forged' }, field: 'gender' },
    { body: { bio: 'x'.repeat(2001) }, field: 'bio' },
    { body: { birthdate: '2015-01-01' }, field: 'birthdate' },
    { body: { role: 'admin', isVerified: false }, field: '' },
  ];
  for (const item of cases) {
    const response = await request('/api/me/profile', { method: 'PUT', body: item.body });
    assert.equal(response.status, 400, JSON.stringify(response.body));
  }
  await owner.reload();
  assert.equal('role' in owner.get({ plain: true }), false);
  assert.equal(owner.isVerified, true);
});

test('transaction rolls back User changes when a related profile update fails', async () => {
  const before = await models.User.findByPk(owner.id);
  const response = await request('/api/me/profile', {
    method: 'PUT',
    body: {
      name: 'Must Roll Back',
      bio: 'This must also roll back.',
      photos: [`${baseUrl}/uploads/not-owned.jpg`],
      primaryPhotoIndex: 0,
    },
  });
  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'VALIDATION_ERROR');
  const afterUser = await models.User.findByPk(owner.id);
  const afterProfile = await models.OnboardingProfile.findOne({ where: { userId: owner.id } });
  assert.equal(afterUser.name, before.name);
  assert.notEqual(afterProfile.bio, 'This must also roll back.');
  assert.deepEqual(afterProfile.photos, ['/uploads/own-one.jpg', '/uploads/own-two.jpg']);
});
