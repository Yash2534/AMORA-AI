const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Notification integration tests require an isolated TEST_DB_NAME containing "test".');
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
let other;
let candidate;
let token;
let otherToken;
const userIds = [];

async function createUser(name, birthDate = '1997-04-03') {
  const suffix = `${Date.now()}_${Math.random()}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@notification.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
  });
  userIds.push(user.id);
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate,
    gender: 'Female',
    interestedIn: ['Male'],
    relationshipGoals: ['Meaningful Dating'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    photos: ['/uploads/notification.jpg', '/uploads/notification-two.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function request(path, { method = 'GET', body, bearer = token } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(bearer ? { authorization: `Bearer ${bearer}` } : {}),
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
  owner = await createUser('Notification Owner');
  other = await createUser('Other Owner');
  candidate = await createUser('Discover Candidate', '1998-05-04');
  token = jwt.sign({ sub: owner.id, ver: 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
  otherToken = jwt.sign({ sub: other.id, ver: 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
  const now = Date.now();
  await models.Notification.bulkCreate([
    { userId: owner.id, type: 'like', category: 'Likes', title: 'Old like', message: 'Old notification', isRead: false, data: { targetUserId: candidate.id }, createdAt: new Date(now - 3000), updatedAt: new Date(now - 3000) },
    { userId: owner.id, type: 'message', category: 'Messages', title: 'Middle message', message: 'Middle notification', isRead: false, data: { conversationId: '44' }, createdAt: new Date(now - 2000), updatedAt: new Date(now - 2000) },
    { userId: owner.id, type: 'event', category: 'Events', title: 'Newest event', message: 'Newest notification', isRead: false, data: { eventId: '8' }, createdAt: new Date(now - 1000), updatedAt: new Date(now - 1000) },
    { userId: other.id, type: 'security', category: 'Security', title: 'Other private notification', message: 'Must remain private', isRead: false, data: {}, createdAt: new Date(now), updatedAt: new Date(now) },
  ]);
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  await models.Notification.destroy({ where: { userId: userIds } });
  await models.NotificationPreference.destroy({ where: { userId: userIds } });
  await models.DiscoverFilterPreference.destroy({ where: { userId: userIds } });
  await models.OnboardingProfile.destroy({ where: { userId: userIds } });
  await models.User.destroy({ where: { id: userIds } });
  await getSequelize().close();
});

test('notification and preference APIs require Bearer authentication', async () => {
  for (const path of ['/api/notifications', '/api/notification-preferences', '/api/me/preferences']) {
    assert.equal((await request(path, { bearer: null })).status, 401);
  }
});

test('GET notifications is owner-scoped, newest-first, filtered, and paginated', async () => {
  const first = await request('/api/notifications?page=1&limit=2');
  assert.equal(first.status, 200);
  assert.deepEqual(first.body.data.notifications.map((item) => item.title), ['Newest event', 'Middle message']);
  assert.equal(first.body.data.pagination.hasMore, true);
  assert.equal(first.body.data.pagination.nextPage, 2);
  assert.equal(first.body.data.unreadCount, 3);
  assert.equal(first.body.data.notifications.some((item) => item.title.includes('Other')), false);

  const second = await request('/api/notifications?page=2&limit=2');
  assert.deepEqual(second.body.data.notifications.map((item) => item.title), ['Old like']);
  const events = await request('/api/notifications?category=Events');
  assert.deepEqual(events.body.data.notifications.map((item) => item.category), ['Events']);
  const unread = await request('/api/notifications?unread=true');
  assert.equal(unread.body.data.notifications.length, 3);
});

test('mark read is idempotent and cannot modify another user notification', async () => {
  const own = await models.Notification.findOne({ where: { userId: owner.id, title: 'Middle message' } });
  const foreign = await models.Notification.findOne({ where: { userId: other.id } });
  const first = await request(`/api/notifications/${own.id}/read`, { method: 'PUT' });
  assert.equal(first.status, 200);
  assert.equal(first.body.data.notification.isRead, true);
  assert.ok(first.body.data.notification.readAt);
  const readAt = first.body.data.notification.readAt;
  const repeated = await request(`/api/notifications/${own.id}/read`, { method: 'PUT' });
  assert.equal(repeated.body.data.notification.readAt, readAt);
  assert.equal((await request(`/api/notifications/${foreign.id}/read`, { method: 'PUT' })).status, 404);
  await own.reload();
  assert.equal(own.isRead, true);
  assert.ok(own.readAt);
});

test('read-all updates only the authenticated user', async () => {
  const response = await request('/api/notifications/read-all', { method: 'PUT' });
  assert.equal(response.status, 200);
  assert.equal(response.body.data.updatedCount, 2);
  assert.equal(response.body.data.unreadCount, 0);
  assert.equal(await models.Notification.count({ where: { userId: owner.id, isRead: false } }), 0);
  assert.equal(await models.Notification.count({ where: { userId: other.id, isRead: false } }), 1);
});

test('delete is owner-scoped, idempotent, persisted, and excluded from reload', async () => {
  const own = await models.Notification.findOne({ where: { userId: owner.id, title: 'Old like' } });
  const foreign = await models.Notification.findOne({ where: { userId: other.id } });
  assert.equal((await request(`/api/notifications/${own.id}`, { method: 'DELETE' })).status, 200);
  assert.equal((await request(`/api/notifications/${own.id}`, { method: 'DELETE' })).status, 200);
  assert.equal((await request(`/api/notifications/${foreign.id}`, { method: 'DELETE' })).status, 404);
  await own.reload();
  assert.ok(own.deletedAt);
  const list = await request('/api/notifications');
  assert.equal(list.body.data.notifications.some((item) => item.id === String(own.id)), false);
});

test('notification preferences retain defaults, whitelist fields, and persist', async () => {
  const defaults = await request('/api/notification-preferences');
  assert.equal(defaults.status, 200);
  assert.equal(defaults.body.data.preferences.newMatches, true);
  const updated = await request('/api/notification-preferences', {
    method: 'PUT',
    body: { newMatches: false, quietHoursEnabled: true, quietStart: '21:30' },
  });
  assert.equal(updated.body.data.preferences.newMatches, false);
  assert.equal(updated.body.data.preferences.quietStart, '21:30');
  assert.equal((await request('/api/notification-preferences', { method: 'PUT', body: { role: 'admin' } })).status, 400);
  assert.equal((await request('/api/notification-preferences', { method: 'PUT', body: { newMatches: 'no' } })).status, 400);
  assert.equal((await request('/api/notification-preferences')).body.data.preferences.newMatches, false);
});

test('account preferences persist, reject unsupported values, and enforce Discover filters', async () => {
  const initial = await request('/api/me/preferences');
  assert.equal(initial.status, 200);
  assert.equal(initial.body.data.preferences.minAge, 18);
  const hidden = await request('/api/me/preferences', { method: 'PUT', body: { minAge: 35, maxAge: 45, maxDistanceKm: 25 } });
  assert.equal(hidden.status, 200, JSON.stringify(hidden.body));
  assert.equal(hidden.body.data.preferences.minAge, 35);
  assert.equal((await request('/api/me/preferences', { method: 'PUT', body: { minAge: 60, maxAge: 30 } })).status, 400);
  assert.equal((await request('/api/me/preferences', { method: 'PUT', body: { role: 'admin' } })).status, 400);
  assert.equal((await request('/api/me/preferences', { method: 'PUT', body: { onlineNow: 'sometimes' } })).status, 400);

  const excluded = await request('/api/discover/feed?limit=30&verifiedOnly=true&minScore=0');
  assert.equal(excluded.body.data.profiles.some((profile) => profile.id === String(candidate.id)), false);
  await request('/api/me/preferences', { method: 'PUT', body: { minAge: 18, maxAge: 45 } });
  const included = await request('/api/discover/feed?limit=30&verifiedOnly=true&minScore=0');
  assert.equal(included.body.data.profiles.some((profile) => profile.id === String(candidate.id)), true);

  const otherPreferences = await request('/api/me/preferences', { bearer: otherToken });
  assert.equal(otherPreferences.body.data.preferences.minAge, 18);
  assert.equal((await request('/api/me/preferences')).body.data.preferences.minAge, 18);
});
