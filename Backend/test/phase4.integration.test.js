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

let models; let server; let baseUrl; let organizer; let attendee; let other; let waitlisted; let event; let waitlistEvent; let noWaitlistEvent;
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
  organizer = await user('Event Organizer'); attendee = await user('Event Attendee'); other = await user('Other Attendee'); waitlisted = await user('Waitlisted Attendee');
  event = await models.Event.create({ title: 'Retained Event', description: 'Browse and register', category: 'Social', city: 'Ahmedabad', venueName: 'Venue', startDateTime: new Date(Date.now() + 86400000), endDateTime: new Date(Date.now() + 90000000), capacity: 1, waitlistCapacity: 2, waitlistEnabled: true, status: 'published', visibility: 'public', organizerId: organizer.id });
  waitlistEvent = await models.Event.create({ title: 'Waitlist Event', description: 'Full event with waitlist', category: 'Social', city: 'Ahmedabad', venueName: 'Venue', startDateTime: new Date(Date.now() + 172800000), endDateTime: new Date(Date.now() + 176400000), capacity: 1, waitlistCapacity: 2, waitlistEnabled: true, status: 'published', visibility: 'public', organizerId: organizer.id });
  noWaitlistEvent = await models.Event.create({ title: 'No Waitlist Event', description: 'Full event without waitlist', category: 'Social', city: 'Ahmedabad', venueName: 'Venue', startDateTime: new Date(Date.now() + 259200000), endDateTime: new Date(Date.now() + 262800000), capacity: 1, waitlistCapacity: 0, waitlistEnabled: false, status: 'published', visibility: 'public', organizerId: organizer.id });
  await models.EventRegistration.bulkCreate([
    { eventId: waitlistEvent.id, userId: attendee.id, status: 'registered', registeredAt: new Date() },
    { eventId: noWaitlistEvent.id, userId: attendee.id, status: 'registered', registeredAt: new Date() },
  ]);
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    const ids = [organizer.id, attendee.id, other.id, waitlisted.id];
    const eventIds = [event.id, waitlistEvent.id, noWaitlistEvent.id];
    await models.EventWaitlist.destroy({ where: { eventId: eventIds } });
    await models.EventRegistration.destroy({ where: { eventId: eventIds } });
    await models.Event.destroy({ where: { id: eventIds } });
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

test('waitlist persists per user and event, rejects invalid states, and promotes without duplicates', async () => {
  const available = await request(`/api/events/${waitlistEvent.id}`, 'GET', other);
  assert.equal(available.status, 200);
  assert.equal(available.body.data.event.waitlistAvailable, true);

  const joined = await request(`/api/events/${waitlistEvent.id}/waitlist`, 'POST', other);
  assert.equal(joined.status, 201, JSON.stringify(joined.body));
  assert.equal(joined.body.data.participation.waitlisted, true);
  assert.equal(joined.body.data.participation.waitlistStatus, 'waiting');
  const row = await models.EventWaitlist.findOne({ where: { eventId: waitlistEvent.id, userId: other.id } });
  assert.equal(row.status, 'waiting');
  assert.ok(row.joinedAt instanceof Date);
  assert.equal(await models.EventWaitlist.count({ where: { eventId: waitlistEvent.id, userId: other.id } }), 1);

  assert.equal((await request(`/api/events/${waitlistEvent.id}/waitlist`, 'POST', other)).status, 201);
  assert.equal(await models.EventWaitlist.count({ where: { eventId: waitlistEvent.id, userId: other.id } }), 1);
  assert.equal((await request(`/api/events/${waitlistEvent.id}/waitlist`, 'POST', waitlisted)).status, 201);
  assert.equal((await request(`/api/events/${waitlistEvent.id}/waitlist`, 'DELETE', waitlisted)).status, 200);
  assert.equal((await models.EventWaitlist.findOne({ where: { eventId: waitlistEvent.id, userId: waitlisted.id } })).status, 'left');
  const afterLeave = await request('/api/events/me?category=waitlist', 'GET', waitlisted);
  assert.equal(afterLeave.body.data.events.some((item) => item.id === String(waitlistEvent.id)), false);
  assert.equal((await request(`/api/events/${waitlistEvent.id}/waitlist`, 'POST', waitlisted)).status, 201);
  assert.equal(await models.EventWaitlist.count({ where: { eventId: waitlistEvent.id, userId: waitlisted.id } }), 1);
  const registeredFailure = await request(`/api/events/${waitlistEvent.id}/waitlist`, 'POST', attendee);
  assert.equal(registeredFailure.status, 409);
  assert.equal(registeredFailure.body.code, 'ALREADY_REGISTERED');
  const disabledFailure = await request(`/api/events/${noWaitlistEvent.id}/waitlist`, 'POST', waitlisted);
  assert.equal(disabledFailure.status, 409);
  assert.equal(disabledFailure.body.code, 'WAITLIST_CLOSED');
  const capacityFailure = await request(`/api/events/${event.id}/waitlist`, 'POST', waitlisted);
  assert.equal(capacityFailure.status, 409);
  assert.equal(capacityFailure.body.code, 'EVENT_HAS_CAPACITY');
  assert.equal((await request('/api/events/999999999/waitlist', 'POST', waitlisted)).status, 404);

  const mine = await request('/api/events/me?category=waitlist', 'GET', other);
  assert.equal(mine.status, 200);
  const waitlistedEvent = mine.body.data.events.find((item) => item.id === String(waitlistEvent.id));
  assert.equal(waitlistedEvent.participation.waitlisted, true);
  assert.equal(waitlistedEvent.waitlistAvailable, false);
  const afterRelogin = await request('/api/events/me?category=waitlist', 'GET', other);
  assert.equal(afterRelogin.body.data.events.some((item) => item.id === String(waitlistEvent.id)), true);
  const anotherUsersEvents = await request('/api/events/me?category=waitlist', 'GET', organizer);
  assert.equal(anotherUsersEvents.body.data.events.some((item) => item.id === String(waitlistEvent.id)), false);

  const cancelled = await request(`/api/events/${waitlistEvent.id}/registration`, 'DELETE', attendee);
  assert.equal(cancelled.status, 200);
  assert.equal(cancelled.body.data.promoted, true);
  const promotedRegistration = await models.EventRegistration.findOne({ where: { eventId: waitlistEvent.id, userId: other.id } });
  const promotedWaitlist = await models.EventWaitlist.findOne({ where: { eventId: waitlistEvent.id, userId: other.id } });
  assert.equal(promotedRegistration.status, 'promoted');
  assert.equal(promotedWaitlist.status, 'promoted');
  assert.ok(promotedWaitlist.endedAt instanceof Date);
  const afterPromotion = await request('/api/events/me?category=upcoming', 'GET', other);
  assert.equal(afterPromotion.body.data.events.some((item) => item.id === String(waitlistEvent.id) && item.participation.registered), true);
  assert.equal((await request(`/api/events/${waitlistEvent.id}/waitlist`, 'POST', other)).body.code, 'ALREADY_REGISTERED');
});

test('other retired event and host endpoints remain unavailable', async () => {
  for (const [path, method] of [[`/api/events/${event.id}/check-in`, 'POST'], [`/api/events/${event.id}/feedback`, 'POST'], [`/api/events/${event.id}/group-chat/messages`, 'GET'], ['/api/host/dashboard', 'GET']]) {
    assert.equal((await request(path, method, attendee)).status, 404, path);
  }
});
