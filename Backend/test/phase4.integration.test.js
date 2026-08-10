const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { io: socketClient } = require('socket.io-client');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Phase 4 integration tests require a separate TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');
const { closeRealtimeServer } = require('../src/realtime/realtimeHub');

let models;
let server;
let baseUrl;
const users = {};
const userIds = [];
const eventIds = [];
const sockets = [];
const now = Date.now();

const tokenFor = (user) => jwt.sign({ sub: user.id, ver: user.tokenVersion || 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });
const at = (hours) => new Date(now + hours * 60 * 60 * 1000);

async function createUser(key, role = 'user', birthDate = '1997-05-12') {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `P4 ${key}`,
    email: `${suffix}@phase4.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
    role,
  });
  userIds.push(user.id);
  users[key] = user;
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate,
    gender: 'Woman',
    interestedIn: ['Men'],
    relationshipGoals: ['long_term'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    hometown: 'Ahmedabad',
    interests: ['music'],
    lifestyle: {},
    prompts: { idealDate: 'Coffee' },
    pronouns: ['she/her'],
    valuedQualities: ['kindness'],
    loveLanguages: ['quality_time'],
    preferredTalkingHours: ['evening'],
    communicationStyle: 'calls',
    photos: ['/uploads/phase4-profile.jpg'],
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function createEvent(key, values = {}) {
  const event = await models.Event.create({
    title: values.title || `P4 ${key}`,
    description: values.description || `Canonical ${key} event description`,
    category: values.category || 'Coffee Meetup',
    city: values.city || 'Ahmedabad',
    venueName: values.venueName || 'AMORAA Test Venue',
    address: 'Test address',
    startDateTime: values.startDateTime || at(48 + eventIds.length),
    endDateTime: values.endDateTime || at(51 + eventIds.length),
    capacity: values.capacity ?? 3,
    waitlistCapacity: values.waitlistCapacity ?? 3,
    status: values.status || 'published',
    visibility: values.visibility || 'public',
    registrationOpen: values.registrationOpen ?? true,
    waitlistEnabled: values.waitlistEnabled ?? true,
    heroImageUrl: `/uploads/events/${key}.jpg`,
    hostId: users.host.id,
    price: 599,
    dressCode: 'Smart casual',
    minAge: values.minAge ?? null,
    maxAge: values.maxAge ?? null,
    language: 'English, Gujarati',
    agenda: [{ time: '18:00', title: 'Welcome' }],
    facilities: ['Parking'],
    interests: ['Coffee'],
    checkInOpensAt: values.checkInOpensAt ?? null,
    checkInClosesAt: values.checkInClosesAt ?? null,
  });
  eventIds.push(event.id);
  return event;
}

async function request(url, options = {}) {
  const response = await fetch(`${baseUrl}${url}`, options);
  return { status: response.status, body: await response.json() };
}

function jsonRequest(url, method, user, body) {
  return request(url, {
    method,
    headers: { ...auth(user), ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function feedbackUpload(eventId, user, bytes, type = 'image/png', name = 'event.png') {
  const form = new FormData();
  form.append('rating', '5');
  form.append('recommend', 'true');
  form.append('media', new Blob([bytes], { type }), name);
  return request(`/api/events/${eventId}/feedback`, { method: 'POST', headers: auth(user), body: form });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await createUser('host', 'host');
  await createUser('attendee');
  await createUser('other');
  await createUser('waitlisted');
  await createUser('outsider');
  await createUser('young', 'user', '2010-05-12');
  await createUser('normal');
  users.catalog = await createEvent('catalog', { title: 'Sunrise Coffee Circle', category: 'Coffee Meetup', city: 'Ahmedabad', capacity: 2 });
  users.travel = await createEvent('travel', { title: 'Surat Travel Social', category: 'Travel', city: 'Surat' });
  users.eligible = await createEvent('eligible', { title: 'Adults Evening', minAge: 21, maxAge: 45 });
  users.full = await createEvent('full', { title: 'Full Capacity Night', capacity: 1, waitlistCapacity: 2 });
  users.concurrent = await createEvent('concurrent', { title: 'One Seat Event', capacity: 1 });
  users.checkin = await createEvent('checkin', { title: 'Live Check-in Event', startDateTime: at(-0.5), endDateTime: at(0.5), checkInOpensAt: at(-1), checkInClosesAt: at(1) });
  users.past = await createEvent('past', { title: 'Past Event', startDateTime: at(-72), endDateTime: at(-70), status: 'completed' });
  users.closed = await createEvent('closed', { title: 'Closed Event', registrationOpen: false });
  users.private = await createEvent('private', { title: 'Private Host Event', visibility: 'private' });
  users.draft = await createEvent('draft', { title: 'Draft Host Event', status: 'draft' });
  await models.EventRegistration.bulkCreate([
    { eventId: users.full.id, userId: users.other.id, status: 'registered', registeredAt: new Date() },
    { eventId: users.checkin.id, userId: users.attendee.id, status: 'registered', registeredAt: new Date() },
    { eventId: users.past.id, userId: users.attendee.id, status: 'registered', registeredAt: at(-80) },
  ]);
  server = createHttpServer();
  server.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  for (const socket of sockets) socket.disconnect();
  await closeRealtimeServer();
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models) {
    const feedbackMedia = await models.EventFeedback.findAll({ where: { eventId: eventIds, mediaStoragePath: { [Op.ne]: null } }, attributes: ['mediaStoragePath'] });
    for (const row of feedbackMedia) await fs.unlink(path.join(__dirname, '..', 'private-uploads', 'event-feedback', row.mediaStoragePath)).catch(() => {});
    await models.EventGroupMessage.destroy({ where: { eventId: eventIds } });
    await models.EventFeedback.destroy({ where: { eventId: eventIds } });
    await models.EventCheckIn.destroy({ where: { eventId: eventIds } });
    await models.EventWaitlist.destroy({ where: { eventId: eventIds } });
    await models.EventRegistration.destroy({ where: { eventId: eventIds } });
    await models.Event.destroy({ where: { id: eventIds } });
    await models.OnboardingProfile.destroy({ where: { userId: userIds } });
    await models.RefreshToken.destroy({ where: { userId: userIds } });
    await models.User.destroy({ where: { id: userIds } });
  }
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

async function connectEventSocket(user) {
  const token = await jsonRequest('/api/realtime/token', 'POST', user);
  assert.equal(token.status, 200, JSON.stringify(token.body));
  const socket = socketClient(baseUrl, {
    auth: { token: token.body.data.token },
    transports: ['websocket'],
    forceNew: true,
    reconnection: false,
  });
  sockets.push(socket);
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Event socket timed out.')), 5000);
    socket.once('connect', () => { clearTimeout(timer); resolve(); });
    socket.once('connect_error', reject);
  });
  return socket;
}

function acknowledge(socket, event, value) {
  return new Promise((resolve) => socket.emit(event, value, resolve));
}

function nextSocketEvent(socket, event) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${event}.`)), 5000);
    socket.once(event, (value) => { clearTimeout(timer); resolve(value); });
  });
}

test('Events require authentication and browse through SQL filters/pagination', async () => {
  assert.equal((await request('/api/events')).status, 401);
  const first = await request('/api/events?category=Coffee%20Meetup&city=Ahmedabad&timing=upcoming&page=1&limit=2', { headers: auth(users.attendee) });
  assert.equal(first.status, 200, JSON.stringify(first.body));
  assert.equal(first.body.data.events.length, 2);
  assert.ok(first.body.data.events.every((event) => event.category === 'Coffee Meetup' && event.city === 'Ahmedabad'));
  const second = await request('/api/events?category=Coffee%20Meetup&city=Ahmedabad&timing=upcoming&page=2&limit=2', { headers: auth(users.attendee) });
  const firstIds = new Set(first.body.data.events.map((event) => event.id));
  assert.ok(second.body.data.events.every((event) => !firstIds.has(event.id)));
  const search = await request('/api/events?search=Sunrise&limit=20', { headers: auth(users.attendee) });
  assert.deepEqual(search.body.data.events.map((event) => event.id), [String(users.catalog.id)]);
  const past = await request('/api/events?timing=past&limit=20', { headers: auth(users.attendee) });
  assert.ok(past.body.data.events.some((event) => event.id === String(users.past.id)));
  const futureOnly = await request(`/api/events?dateFrom=${encodeURIComponent(at(500).toISOString())}&limit=20`, { headers: auth(users.attendee) });
  assert.equal(futureOnly.body.data.events.length, 0);
  const available = await request('/api/events?available=true&limit=100', { headers: auth(users.attendee) });
  assert.equal(available.body.data.events.some((event) => event.id === String(users.full.id)), false);
});

test('Event eligibility and canonical detail are database-backed', async () => {
  const deniedList = await request('/api/events?search=Adults%20Evening', { headers: auth(users.young) });
  assert.equal(deniedList.body.data.events.length, 0);
  const detail = await request(`/api/events/${users.catalog.id}`, { headers: auth(users.attendee) });
  assert.equal(detail.status, 200, JSON.stringify(detail.body));
  assert.equal(detail.body.data.event.description, 'Canonical catalog event description');
  assert.equal(detail.body.data.event.venueName, 'AMORAA Test Venue');
  assert.equal(detail.body.data.event.participation.registered, false);
  assert.equal((await request(`/api/events/${users.private.id}`, { headers: auth(users.attendee) })).status, 404);
  assert.equal((await request(`/api/events/${users.private.id}`, { headers: auth(users.host) })).status, 200);
  assert.equal((await request(`/api/events/${users.draft.id}`, { headers: auth(users.attendee) })).status, 404);
  assert.equal((await request(`/api/events/${users.draft.id}`, { headers: auth(users.host) })).status, 200);
  assert.equal((await request('/api/events/99999999', { headers: auth(users.attendee) })).status, 404);
});

test('Registration is idempotent, rejects closed/full events, and prevents overbooking', async () => {
  const first = await jsonRequest(`/api/events/${users.catalog.id}/registration`, 'POST', users.attendee);
  assert.equal(first.status, 201, JSON.stringify(first.body));
  assert.equal(first.body.data.participation.registered, true);
  const duplicate = await jsonRequest(`/api/events/${users.catalog.id}/registration`, 'POST', users.attendee);
  assert.equal(duplicate.status, 201);
  assert.equal(await models.EventRegistration.count({ where: { eventId: users.catalog.id, userId: users.attendee.id } }), 1);
  assert.equal((await jsonRequest(`/api/events/${users.full.id}/registration`, 'POST', users.attendee)).body.code, 'EVENT_FULL');
  assert.equal((await jsonRequest(`/api/events/${users.closed.id}/registration`, 'POST', users.attendee)).body.code, 'EVENT_REGISTRATION_CLOSED');

  const attempts = await Promise.all([
    jsonRequest(`/api/events/${users.concurrent.id}/registration`, 'POST', users.attendee),
    jsonRequest(`/api/events/${users.concurrent.id}/registration`, 'POST', users.other),
  ]);
  assert.equal(attempts.filter((result) => result.status === 201).length, 1);
  assert.equal(await models.EventRegistration.count({ where: { eventId: users.concurrent.id, status: { [Op.in]: ['registered', 'promoted'] } } }), 1);
});

test('Waitlist is idempotent and cancellation atomically promotes the first user', async () => {
  const joined = await jsonRequest(`/api/events/${users.full.id}/waitlist`, 'POST', users.waitlisted);
  assert.equal(joined.status, 201, JSON.stringify(joined.body));
  assert.equal(joined.body.data.participation.waitlisted, true);
  assert.equal((await jsonRequest(`/api/events/${users.full.id}/waitlist`, 'POST', users.waitlisted)).status, 201);
  assert.equal(await models.EventWaitlist.count({ where: { eventId: users.full.id, userId: users.waitlisted.id } }), 1);
  assert.equal((await jsonRequest(`/api/events/${users.full.id}/waitlist`, 'POST', users.other)).body.code, 'ALREADY_REGISTERED');
  const cancelled = await jsonRequest(`/api/events/${users.full.id}/registration`, 'DELETE', users.other);
  assert.equal(cancelled.status, 200, JSON.stringify(cancelled.body));
  const promoted = await models.EventRegistration.findOne({ where: { eventId: users.full.id, userId: users.waitlisted.id } });
  assert.equal(promoted.status, 'promoted');
  assert.equal((await models.EventWaitlist.findOne({ where: { eventId: users.full.id, userId: users.waitlisted.id } })).status, 'promoted');
  assert.equal((await jsonRequest(`/api/events/${users.full.id}/registration`, 'DELETE', users.other)).status, 200);
});

test('Leaving a waitlist is safe and My Events categories come from MySQL', async () => {
  await models.EventWaitlist.create({ eventId: users.catalog.id, userId: users.outsider.id, status: 'waiting', joinedAt: new Date() });
  assert.equal((await jsonRequest(`/api/events/${users.catalog.id}/waitlist`, 'DELETE', users.outsider)).status, 200);
  assert.equal((await jsonRequest(`/api/events/${users.catalog.id}/waitlist`, 'DELETE', users.outsider)).status, 200);
  const upcoming = await request('/api/events/me?category=upcoming', { headers: auth(users.attendee) });
  assert.ok(upcoming.body.data.events.some((event) => event.id === String(users.catalog.id)));
  const past = await request('/api/events/me?category=past', { headers: auth(users.attendee) });
  assert.deepEqual(past.body.data.events.map((event) => event.id), [String(users.past.id)]);
  await jsonRequest(`/api/events/${users.catalog.id}/registration`, 'DELETE', users.attendee);
  const cancelled = await request('/api/events/me?category=cancelled', { headers: auth(users.attendee) });
  assert.ok(cancelled.body.data.events.some((event) => event.id === String(users.catalog.id)));
});

test('Check-in uses server time and feedback persists only for attendees', async () => {
  const checkIn = await jsonRequest(`/api/events/${users.checkin.id}/check-in`, 'POST', users.attendee);
  assert.equal(checkIn.status, 200, JSON.stringify(checkIn.body));
  assert.equal(checkIn.body.data.participation.checkedIn, true);
  assert.equal((await jsonRequest(`/api/events/${users.checkin.id}/check-in`, 'POST', users.attendee)).status, 200);
  assert.equal(await models.EventCheckIn.count({ where: { eventId: users.checkin.id, userId: users.attendee.id } }), 1);
  assert.equal((await jsonRequest(`/api/events/${users.checkin.id}/check-in`, 'POST', users.outsider)).status, 403);
  const feedback = await jsonRequest(`/api/events/${users.past.id}/feedback`, 'POST', users.attendee, { rating: 5, venueRating: 4, feedbackText: 'A real persisted review', recommend: true });
  assert.equal(feedback.status, 201, JSON.stringify(feedback.body));
  assert.equal((await models.EventFeedback.findOne({ where: { eventId: users.past.id, userId: users.attendee.id } })).feedbackText, 'A real persisted review');
  assert.equal((await jsonRequest(`/api/events/${users.past.id}/feedback`, 'POST', users.outsider, { rating: 5 })).status, 403);
  assert.equal((await jsonRequest(`/api/events/${users.past.id}/feedback`, 'POST', users.attendee, { rating: 7 })).status, 400);
});

test('Feedback media validates signature, size, authorization, and persists private metadata', async () => {
  const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
  const uploaded = await feedbackUpload(users.past.id, users.attendee, png);
  assert.equal(uploaded.status, 200, JSON.stringify(uploaded.body));
  const feedback = await models.EventFeedback.findOne({ where: { eventId: users.past.id, userId: users.attendee.id } });
  assert.equal(feedback.mediaMimeType, 'image/png');
  assert.ok(feedback.mediaStoragePath && !feedback.mediaStoragePath.includes('..'));
  assert.equal((await feedbackUpload(users.past.id, users.attendee, Buffer.from('not an image'))).body.code, 'INVALID_MEDIA_TYPE');
  assert.equal((await feedbackUpload(users.past.id, users.outsider, png)).status, 403);
  const oversized = await feedbackUpload(users.past.id, users.attendee, Buffer.alloc(5 * 1024 * 1024 + 1));
  assert.equal(oversized.body.code, 'MEDIA_TOO_LARGE');
});

test('Event group chat enforces membership, persists messages, and paginates', async () => {
  const denied = await request(`/api/events/${users.checkin.id}/group-chat/messages`, { headers: auth(users.outsider) });
  assert.equal(denied.status, 403);
  const sent = await jsonRequest(`/api/events/${users.checkin.id}/group-chat/messages`, 'POST', users.attendee, { text: 'Hello verified attendees' });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  assert.equal((await models.EventGroupMessage.findByPk(sent.body.data.message.id)).text, 'Hello verified attendees');
  await jsonRequest(`/api/events/${users.checkin.id}/group-chat/messages`, 'POST', users.host, { text: 'Host update' });
  const history = await request(`/api/events/${users.checkin.id}/group-chat/messages?limit=1`, { headers: auth(users.attendee) });
  assert.equal(history.status, 200);
  assert.equal(history.body.data.messages.length, 1);
  assert.equal(history.body.data.pagination.hasMore, true);
  assert.equal((await jsonRequest(`/api/events/${users.checkin.id}/group-chat/messages`, 'POST', users.attendee, { text: ' ' })).status, 400);
});

test('Event realtime room rechecks membership before subscription and delivery', async () => {
  const attendeeSocket = await connectEventSocket(users.attendee);
  const outsiderSocket = await connectEventSocket(users.outsider);
  assert.deepEqual(await acknowledge(attendeeSocket, 'event.subscribe', { eventId: users.checkin.id }), { success: true });
  assert.deepEqual(await acknowledge(outsiderSocket, 'event.subscribe', { eventId: users.checkin.id }), { success: false, code: 'EVENT_CHAT_NOT_ALLOWED' });
  const received = nextSocketEvent(attendeeSocket, 'event.message.created');
  const sent = await jsonRequest(`/api/events/${users.checkin.id}/group-chat/messages`, 'POST', users.host, { text: 'Realtime host notice' });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  assert.equal((await received).text, 'Realtime host notice');
});

test('Host APIs are role-checked and enforce ownership/capacity safety', async () => {
  assert.equal((await request('/api/host/dashboard', { headers: auth(users.normal) })).status, 403);
  const dashboard = await request('/api/host/dashboard', { headers: auth(users.host) });
  assert.equal(dashboard.status, 200, JSON.stringify(dashboard.body));
  assert.ok(dashboard.body.data.events.length >= eventIds.length);
  const created = await jsonRequest('/api/host/events', 'POST', users.host, {
    title: 'Host Created Event', description: 'Created through the authenticated host API', category: 'Workshop', city: 'Ahmedabad', venueName: 'Host Venue',
    startDateTime: at(120).toISOString(), endDateTime: at(123).toISOString(), capacity: 20, waitlistCapacity: 5, status: 'published',
  });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  eventIds.push(Number(created.body.data.event.id));
  const updated = await jsonRequest(`/api/host/events/${created.body.data.event.id}`, 'PUT', users.host, { title: 'Updated Host Event' });
  assert.equal(updated.status, 200, JSON.stringify(updated.body));
  assert.equal(updated.body.data.event.title, 'Updated Host Event');
  assert.equal((await jsonRequest(`/api/host/events/${created.body.data.event.id}`, 'PUT', users.normal, { title: 'Unauthorized' })).status, 403);
  assert.equal((await jsonRequest(`/api/host/events/${users.full.id}`, 'PUT', users.host, { capacity: 0 })).status, 400);
});
