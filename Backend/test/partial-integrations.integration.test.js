const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Partial integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let server; let baseUrl; let models; let viewer; let recent; let eventUser; let old; let token;
const userIds = [];

async function user(name, values = {}) {
  const suffix = `${Date.now()}_${Math.random()}`;
  const row = await models.User.create({ name, email: `${suffix}@partial.test`, phoneNumber: '', authProvider: 'local', isVerified: true, identityVerifiedAt: new Date(), termsAcceptedAt: new Date(), ...values });
  userIds.push(row.id);
  await models.OnboardingProfile.create({ userId: row.id, birthDate: '1998-02-14', gender: 'Woman', interestedIn: ['Men'], relationshipGoals: ['long_term'], city: 'Ahmedabad', profession: 'Engineer', education: 'Graduate', interests: ['events'], lifestyle: { drinking: 'never' }, prompts: { date: 'Coffee' }, photos: ['/uploads/one.jpg', '/uploads/two.jpg'], stage: 'complete', onboardingCompleted: true });
  return row;
}

async function call(path, method = 'GET', body) {
  const response = await fetch(`${baseUrl}${path}`, { method, headers: { authorization: `Bearer ${token}`, ...(body ? { 'content-type': 'application/json' } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}) });
  return { status: response.status, headers: response.headers, body: await response.json() };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  viewer = await user('Partial Viewer');
  recent = await user('Recently Active', { lastActiveAt: new Date() });
  eventUser = await user('Event Interested', { lastActiveAt: new Date() });
  old = await user('Inactive', { lastActiveAt: new Date(Date.now() - 60 * 60 * 1000) });
  token = jwt.sign({ sub: viewer.id, ver: 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
  const event = await models.Event.create({ title: 'Partial Event', description: 'Integration fixture', category: 'Social', city: 'Ahmedabad', venueName: 'Venue', startDateTime: new Date(Date.now() + 86400000), endDateTime: new Date(Date.now() + 90000000), capacity: 20, status: 'published', visibility: 'public', organizerId: viewer.id });
  await models.EventRegistration.create({ eventId: event.id, userId: eventUser.id, status: 'registered', registeredAt: new Date() });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  await models.SavedProfile.destroy({ where: { [Op.or]: [{ userId: userIds }, { savedUserId: userIds }] } });
  await models.NotificationPreference.destroy({ where: { userId: userIds } });
  await models.EventRegistration.destroy({ where: { userId: userIds } });
  await models.Event.destroy({ where: { organizerId: userIds } });
  await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
  await models.DiscoverFilterPreference.destroy({ where: { userId: userIds } });
  await models.OnboardingProfile.destroy({ where: { userId: userIds } });
  await models.User.destroy({ where: { id: userIds } });
  await getSequelize().close();
});

test('onlineNow and event-interest use server data before pagination', async () => {
  const online = await call('/api/discover/feed?onlineNow=true&verifiedOnly=true&minScore=0&limit=30');
  assert.equal(online.status, 200);
  assert.ok(online.body.data.profiles.some((profile) => profile.id === String(recent.id)));
  assert.ok(online.body.data.profiles.every((profile) => profile.id !== String(old.id)));

  const interested = await call('/api/discover/feed?hasEventInterest=true&verifiedOnly=true&minScore=0&limit=30');
  assert.equal(interested.status, 200);
  assert.ok(interested.body.data.profiles.some((profile) => profile.id === String(eventUser.id)));
});

test('own profile is canonical, persists, rejects mass assignment, and excludes secrets', async () => {
  const initial = await call('/api/me/profile');
  assert.equal(initial.status, 200);
  assert.equal(initial.body.data.profile.name, 'Partial Viewer');
  assert.equal('passwordHash' in initial.body.data.profile, false);
  const updated = await call('/api/me/profile', 'PUT', { name: 'Canonical Name', bio: 'Persisted bio', iceBreaker: 'Hello there', communicationStyle: 'calls' });
  assert.equal(updated.status, 200);
  assert.equal(updated.body.data.profile.bio, 'Persisted bio');
  const reloaded = await call('/api/me/profile');
  assert.equal(reloaded.body.data.profile.iceBreaker, 'Hello there');
  const rejected = await call('/api/me/profile', 'PUT', { role: 'admin' });
  assert.equal(rejected.status, 400);
  await viewer.reload();
  assert.equal('role' in viewer.get({ plain: true }), false);

  const legacy = await call('/api/profiles/me');
  assert.equal(legacy.status, 404);
});

test('saved profiles and sent reactions are authenticated, idempotent, and persistent', async () => {
  assert.equal((await call(`/api/saved-profiles/${recent.id}`, 'POST')).status, 201);
  assert.equal((await call(`/api/saved-profiles/${recent.id}`, 'POST')).status, 200);
  const saved = await call('/api/saved-profiles');
  assert.deepEqual(saved.body.data.profiles.map((profile) => profile.id), [String(recent.id)]);
  assert.equal(await models.SavedProfile.count({ where: { userId: viewer.id, savedUserId: recent.id } }), 1);
  assert.equal((await call(`/api/saved-profiles/${viewer.id}`, 'POST')).status, 400);
  await models.Block.create({ blockerUserId: recent.id, blockedUserId: viewer.id });
  assert.deepEqual((await call('/api/saved-profiles')).body.data.profiles, []);
  assert.equal((await call(`/api/saved-profiles/${recent.id}`, 'POST')).status, 404);
  await models.Block.destroy({ where: { blockerUserId: recent.id, blockedUserId: viewer.id } });
  assert.equal((await call(`/api/saved-profiles/${recent.id}`, 'DELETE')).body.data.saved, false);
  assert.equal((await call(`/api/saved-profiles/${recent.id}`, 'DELETE')).body.data.saved, false);

  assert.equal((await call('/api/discover/swipe', 'POST', { targetUserId: old.id, action: 'superLike' })).status, 200);
  const superLikes = await call('/api/reactions?type=superLike');
  assert.deepEqual(superLikes.body.data.profiles.map((profile) => profile.id), [String(old.id)]);
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: viewer.id, targetUserId: old.id, action: 'superLike' } }), 1);
  await models.Block.create({ blockerUserId: old.id, blockedUserId: viewer.id });
  assert.deepEqual((await call('/api/reactions?type=superLike')).body.data.profiles, []);
  await models.Block.destroy({ where: { blockerUserId: old.id, blockedUserId: viewer.id } });
  assert.equal((await call(`/api/reactions/${old.id}`, 'DELETE')).status, 200);
  assert.equal((await call(`/api/reactions/${old.id}`, 'DELETE')).status, 200);
});

test('notification preferences validate and persist for the authenticated user', async () => {
  const initial = await call('/api/notification-preferences');
  assert.equal(initial.body.data.preferences.safetyUpdates, true);
  const updated = await call('/api/notification-preferences', 'PUT', { newMatches: false, pushEnabled: true, quietStart: '21:30', quietEnd: '06:15' });
  assert.equal(updated.status, 200);
  assert.equal(updated.body.data.preferences.newMatches, false);
  const reloaded = await call('/api/notification-preferences');
  assert.equal(reloaded.body.data.preferences.quietStart, '21:30');
  assert.equal((await call('/api/notification-preferences', 'PUT', { quietStart: '99:99' })).status, 400);
  assert.equal((await call('/api/notification-preferences', 'PUT', { role: 'admin' })).status, 400);
});
