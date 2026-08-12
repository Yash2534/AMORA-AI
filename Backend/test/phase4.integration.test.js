const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) throw new Error('Event tests require a separate test database.');
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let models; let server; let baseUrl; let organizer; let attendee; let other; let event;
const token = (user) => jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
async function request(path, method = 'GET', user) {
  const response = await fetch(`${baseUrl}${path}`, { method, headers: user ? { authorization: `Bearer ${token(user)}` } : {} });
  return { status: response.status, body: await response.json() };
}
async function user(name) {
  const row = await models.User.create({ name, email: `${Date.now()}_${Math.random()}@events.test`, phoneNumber: '', authProvider: 'local', isVerified: true, termsAcceptedAt: new Date() });
  await models.OnboardingProfile.create({ userId: row.id, birthDate: '1997-05-12', gender: 'Woman', interestedIn: ['Men'], relationshipGoals: ['long_term'], city: 'Ahmedabad', photos: ['/uploads/event.jpg'], stage: 'complete', onboardingCompleted: true });
  return row;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true }); await initializeDatabase(); models = getModels();
  organizer = await user('Event Organizer'); attendee = await user('Event Attendee'); other = await user('Other Attendee');
  event = await models.Event.create({ title: 'Retained Event', description: 'Browse and register', category: 'Social', city: 'Ahmedabad', venueName: 'Venue', startDateTime: new Date(Date.now() + 86400000), endDateTime: new Date(Date.now() + 90000000), capacity: 1, status: 'published', visibility: 'public', organizerId: organizer.id });
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    const ids = [organizer.id, attendee.id, other.id];
    await models.EventRegistration.destroy({ where: { eventId: event.id } });
    await models.Event.destroy({ where: { id: event.id } });
    await models.OnboardingProfile.destroy({ where: { userId: ids } });
    await models.User.destroy({ where: { id: ids } });
  }
  try { await getSequelize().close(); } catch (_) {}
});

test('events require authentication and return canonical organizer data', async () => {
  assert.equal((await request('/api/events')).status, 401);
  const listed = await request('/api/events', 'GET', attendee);
  assert.equal(listed.status, 200);
  const value = listed.body.data.events.find((item) => item.id === String(event.id));
  assert.equal(value.organizer.name, organizer.name);
  assert.equal(value.seatsLeft, 1);
});

test('registration persists, prevents overbooking, lists My Events, and cancels', async () => {
  assert.equal((await request(`/api/events/${event.id}/registration`, 'POST', attendee)).status, 201);
  assert.equal(await models.EventRegistration.count({ where: { eventId: event.id, userId: attendee.id, status: 'registered' } }), 1);
  assert.equal((await request(`/api/events/${event.id}/registration`, 'POST', attendee)).status, 201);
  assert.equal((await request(`/api/events/${event.id}/registration`, 'POST', other)).status, 409);
  const mine = await request('/api/events/me?category=upcoming', 'GET', attendee);
  assert.equal(mine.body.data.events.some((item) => item.id === String(event.id)), true);
  assert.equal((await request(`/api/events/${event.id}/registration`, 'DELETE', attendee)).status, 200);
  const row = await models.EventRegistration.findOne({ where: { eventId: event.id, userId: attendee.id } });
  assert.equal(row.status, 'cancelled');
});

test('retired event and host endpoints return 404', async () => {
  for (const [path, method] of [[`/api/events/${event.id}/waitlist`, 'POST'], [`/api/events/${event.id}/check-in`, 'POST'], [`/api/events/${event.id}/feedback`, 'POST'], [`/api/events/${event.id}/group-chat/messages`, 'GET'], ['/api/host/dashboard', 'GET']]) {
    assert.equal((await request(path, method, attendee)).status, 404, path);
  }
});
