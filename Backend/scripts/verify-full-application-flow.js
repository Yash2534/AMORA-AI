require('../src/config/bootstrapEnv');

const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const fs = require('node:fs/promises');
const path = require('node:path');
const { Op } = require('sequelize');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');

if (!process.argv.includes('--confirm-development-db') || process.env.NODE_ENV === 'production') {
  throw new Error('Pass --confirm-development-db and run only against the development schema.');
}
if (process.env.DB_NAME !== 'amora_ai') {
  throw new Error(`This verification must use the normal amora_ai database, not '${process.env.DB_NAME}'.`);
}

const password = 'ProductionFlow123!';
const userIds = [];
const accountEmails = [];
const accountPhoneNumbers = [];
const profilePhotoPaths = [];
const privateUploadPaths = [];
let models;
let server;
let baseUrl;
let createdEventId;
let conversationId;

async function startHttpServer() {
  server = createHttpServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
}

async function stopHttpServer() {
  if (!server) return;
  await new Promise((resolve) => server.close(resolve));
  server = null;
}

async function api(pathname, { method = 'GET', bearer, body, form } = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    method,
    headers: {
      ...(bearer ? { authorization: `Bearer ${bearer}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    ...(form ? { body: form } : {}),
  });
  const contentType = response.headers.get('content-type') || '';
  return {
    status: response.status,
    body: contentType.includes('application/json') ? await response.json() : null,
  };
}

function requireStatus(response, expected, label) {
  assert.equal(response.status, expected, `${label}: ${JSON.stringify(response.body)}`);
  return response.body;
}

function tinyPng() {
  return Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0]);
}

async function createAccount(index, name, gender, interestedIn) {
  const runId = `${Date.now()}${Math.floor(Math.random() * 100000)}`;
  const email = `full-flow-${index}-${runId}@amora-development.test`;
  const phoneNumber = `+917${index}${runId.slice(-8)}`;
  const signup = requireStatus(await api('/api/auth/signup', {
    method: 'POST',
    body: {
      name,
      email,
      phoneNumber,
      password,
      confirmPassword: password,
      acceptedTerms: true,
    },
  }), 200, `${name} signup`);
  assert.ok(signup.devOtp, 'Development signup must expose its OTP for this guarded local verification.');
  const verified = requireStatus(await api('/api/auth/verify-account', {
    method: 'POST',
    body: { phoneNumber, code: signup.devOtp },
  }), 200, `${name} verification`);
  const account = {
    id: Number(verified.data.user.id),
    email,
    phoneNumber,
    accessToken: verified.data.accessToken,
    refreshToken: verified.data.refreshToken,
  };
  userIds.push(account.id);
  accountEmails.push(email);
  accountPhoneNumbers.push(phoneNumber);

  const steps = [
    ['/api/onboarding/age', { birthDate: `199${index}-0${index + 1}-14` }],
    ['/api/onboarding/gender', { gender }],
    ['/api/onboarding/interested-in', { interestedIn: [interestedIn] }],
    ['/api/onboarding/relationship-goal', { relationshipGoals: ['Long-Term Relationship'] }],
    ['/api/onboarding/location', { city: 'Ahmedabad', preferredDistance: 80 }],
    ['/api/onboarding/starter-profile', { profession: `${name} Engineer`, company: 'AMORAA Audit', education: 'Graduate' }],
    ['/api/onboarding/profile-completion', {
      bio: `${name} persisted production-flow profile.`,
      interests: ['Coffee', 'Music', 'Travel'],
      prompts: { 'A perfect day': 'Coffee, conversation, and a walk.' },
      lifestyle: { Exercise: 'Often' },
      valuedQualities: ['Kindness', 'Honesty'],
      languages: ['English'],
      communicationStyle: 'calls',
    }],
  ];
  for (const [pathname, body] of steps) {
    requireStatus(await api(pathname, { method: 'PUT', bearer: account.accessToken, body }), 200, `${name} ${pathname}`);
  }
  const form = new FormData();
  form.append('photos', new Blob([tinyPng()], { type: 'image/png' }), `${index}-one.png`);
  form.append('photos', new Blob([tinyPng()], { type: 'image/png' }), `${index}-two.png`);
  const photos = requireStatus(await api('/api/onboarding/photos', {
    method: 'POST', bearer: account.accessToken, form,
  }), 200, `${name} photos`);
  profilePhotoPaths.push(...photos.data.onboarding.photos);
  requireStatus(await api('/api/onboarding/complete', {
    method: 'POST', bearer: account.accessToken,
  }), 200, `${name} onboarding completion`);
  return account;
}

async function login(account) {
  const response = requireStatus(await api('/api/auth/login', {
    method: 'POST', body: { email: account.email, password },
  }), 200, `${account.email} login`);
  account.accessToken = response.data.accessToken;
  account.refreshToken = response.data.refreshToken;
  return response.data;
}

async function cleanup() {
  if (!models || !userIds.length) return;
  const userWhere = { [Op.in]: userIds };
  const eitherUser = (first, second) => ({ [Op.or]: [{ [first]: userWhere }, { [second]: userWhere }] });
  const notificationIds = (await models.Notification.findAll({
    attributes: ['id'],
    where: { [Op.or]: [{ userId: userWhere }, { actorUserId: userWhere }] },
    paranoid: false,
  })).map((row) => row.id);
  if (notificationIds.length) await models.NotificationDelivery.destroy({ where: { notificationId: notificationIds } });
  await models.Notification.destroy({ where: { [Op.or]: [{ userId: userWhere }, { actorUserId: userWhere }] }, force: true });
  await models.UserDevice.destroy({ where: { userId: userWhere } });
  await models.IdentityVerification.destroy({ where: { userId: userWhere } });
  await models.RoseTransaction.destroy({ where: eitherUser('senderId', 'recipientId') });
  const conversationIds = (await models.ConversationParticipant.findAll({
    attributes: ['conversationId'], where: { userId: userWhere }, group: ['conversationId'],
  })).map((row) => row.conversationId);
  if (conversationIds.length) {
    const messageIds = (await models.Message.findAll({ attributes: ['id'], where: { conversationId: conversationIds }, paranoid: false })).map((row) => row.id);
    if (messageIds.length) await models.MessageMedia.destroy({ where: { messageId: messageIds } });
    await models.Conversation.update({ lastMessageId: null }, { where: { id: conversationIds } });
    await models.ConversationParticipant.update({ lastReadMessageId: null }, { where: { conversationId: conversationIds } });
    await models.Message.destroy({ where: { conversationId: conversationIds }, force: true });
    await models.ConversationParticipant.destroy({ where: { conversationId: conversationIds } });
    await models.Conversation.destroy({ where: { id: conversationIds } });
  }
  if (createdEventId) {
    await models.EventRegistration.destroy({ where: { eventId: createdEventId } });
    await models.Event.destroy({ where: { id: createdEventId } });
  }
  await models.EventRegistration.destroy({ where: { userId: userWhere } });
  await models.Report.destroy({ where: eitherUser('reporterUserId', 'reportedUserId') });
  await models.Block.destroy({ where: eitherUser('blockerUserId', 'blockedUserId') });
  await models.SavedProfile.destroy({ where: eitherUser('userId', 'savedUserId') });
  await models.Match.destroy({ where: eitherUser('userOneId', 'userTwoId') });
  await models.DiscoverAction.destroy({ where: eitherUser('actorUserId', 'targetUserId') });
  await models.DiscoverFilterPreference.destroy({ where: { userId: userWhere } });
  await models.NotificationPreference.destroy({ where: { userId: userWhere } });
  await models.Subscription.destroy({ where: { userId: userWhere } });
  const paymentIds = (await models.Payment.findAll({ attributes: ['id'], where: { userId: userWhere } })).map((row) => row.id);
  if (paymentIds.length) await models.PaymentEvent.destroy({ where: { paymentId: paymentIds } });
  await models.Payment.destroy({ where: { userId: userWhere } });
  await models.RefreshToken.destroy({ where: { userId: userWhere } });
  await models.OnboardingProfile.destroy({ where: { userId: userWhere } });
  await models.OtpToken.destroy({ where: { [Op.or]: [{ phoneNumber: accountPhoneNumbers }, { email: accountEmails }] } });
  await models.User.destroy({ where: { id: userWhere } });

  for (const publicPath of profilePhotoPaths) {
    const relative = publicPath.replace(/^\/uploads\//, '');
    await fs.rm(path.join(__dirname, '..', 'uploads', relative), { force: true });
  }
  for (const storagePath of privateUploadPaths) {
    await fs.rm(path.join(__dirname, '..', 'private-uploads', storagePath), { force: true });
  }
}

async function main() {
  await initializeDatabase();
  models = getModels();
  await startHttpServer();

  assert.equal((await api('/api/me/profile')).status, 401);
  const a = await createAccount(1, 'Audit Alice', 'Female', 'Male');
  const b = await createAccount(2, 'Audit Bob', 'Male', 'Female');
  const c = await createAccount(3, 'Audit Charlie', 'Male', 'Female');

  requireStatus(await api('/api/me/profile', {
    method: 'PUT', bearer: a.accessToken, body: { bio: 'Alice profile update persisted across restart.', location: 'Gandhinagar' },
  }), 200, 'own profile update');
  const aProfile = requireStatus(await api('/api/me/profile', { bearer: a.accessToken }), 200, 'Alice profile read');
  const bProfile = requireStatus(await api('/api/me/profile', { bearer: b.accessToken }), 200, 'Bob profile read');
  assert.equal(aProfile.data.profile.location, 'Gandhinagar');
  assert.equal(bProfile.data.profile.location, 'Ahmedabad');

  requireStatus(await api('/api/me/preferences', {
    method: 'PUT', bearer: a.accessToken, body: { minAge: 22, maxAge: 45, maxDistanceKm: 100, verifiedOnly: false },
  }), 200, 'Discover preference update');
  assert.equal((await api('/api/me/preferences', { bearer: b.accessToken })).body.data.preferences.minAge, 18);
  const feed = requireStatus(await api('/api/discover/feed?limit=30&minScore=0', { bearer: a.accessToken }), 200, 'Discover feed');
  assert.ok(feed.data.profiles.some((profile) => profile.id === String(b.id)));
  assert.ok(feed.data.profiles.every((profile) => profile.id !== String(a.id)));

  requireStatus(await api(`/api/me/saved-profiles/${b.id}`, { method: 'PUT', bearer: a.accessToken }), 201, 'save profile');
  requireStatus(await api(`/api/me/saved-profiles/${b.id}`, { method: 'PUT', bearer: a.accessToken }), 200, 'idempotent save profile');
  assert.ok((await api('/api/me/saved-profiles', { bearer: a.accessToken })).body.data.profiles.some((profile) => profile.id === String(b.id)));
  assert.equal((await api('/api/me/saved-profiles', { bearer: b.accessToken })).body.data.profiles.length, 0);

  requireStatus(await api('/api/discover/swipe', { method: 'POST', bearer: a.accessToken, body: { targetUserId: c.id, action: 'pass' } }), 200, 'pass');
  requireStatus(await api('/api/discover/rewind', { method: 'POST', bearer: a.accessToken }), 200, 'rewind');
  assert.equal(await models.DiscoverAction.count({ where: { actorUserId: a.id, targetUserId: c.id } }), 0);
  requireStatus(await api('/api/discover/swipe', { method: 'POST', bearer: a.accessToken, body: { targetUserId: b.id, action: 'like' } }), 200, 'Alice likes Bob');
  const reciprocal = requireStatus(await api('/api/discover/swipe', { method: 'POST', bearer: b.accessToken, body: { targetUserId: a.id, action: 'like' } }), 200, 'Bob likes Alice');
  assert.equal(reciprocal.data.matched, true);
  assert.ok((await api('/api/me/received-likes', { bearer: b.accessToken })).body.data.profiles.some((profile) => profile.id === String(a.id)));
  assert.equal((await api('/api/me/received-likes', { bearer: c.accessToken })).body.data.profiles.length, 0);
  assert.equal((await api('/api/matches', { bearer: c.accessToken })).body.data.matches.length, 0);

  const conversationResponse = await api('/api/conversations', {
    method: 'POST', bearer: a.accessToken, body: { targetUserId: b.id },
  });
  assert.ok([200, 201].includes(conversationResponse.status), `conversation creation: ${JSON.stringify(conversationResponse.body)}`);
  const conversation = conversationResponse.body;
  conversationId = conversation.data.conversation.id;
  const sent = requireStatus(await api(`/api/conversations/${conversationId}/messages`, {
    method: 'POST', bearer: a.accessToken, body: { text: 'Persisted hello from Alice.' },
  }), 201, 'message send');
  assert.equal((await api(`/api/conversations/${conversationId}/messages`, { bearer: c.accessToken })).status, 404);
  const bHistory = requireStatus(await api(`/api/conversations/${conversationId}/messages`, { bearer: b.accessToken }), 200, 'Bob message history');
  assert.ok(bHistory.data.messages.some((message) => message.id === sent.data.message.id && message.mine === false));
  requireStatus(await api(`/api/conversations/${conversationId}/read`, {
    method: 'PUT', bearer: b.accessToken, body: { messageId: Number(sent.data.message.id) },
  }), 200, 'read receipt');
  assert.equal((await models.Message.findByPk(sent.data.message.id)).status, 'read');

  const bNotifications = requireStatus(await api('/api/notifications', { bearer: b.accessToken }), 200, 'Bob notifications');
  assert.ok(bNotifications.data.notifications.some((item) => item.actor?.userId === String(a.id)));
  const cNotifications = requireStatus(await api('/api/notifications', { bearer: c.accessToken }), 200, 'Charlie notifications');
  assert.equal(cNotifications.data.notifications.some((item) => item.actor?.userId === String(a.id)), false);
  requireStatus(await api('/api/notification-preferences', {
    method: 'PUT', bearer: a.accessToken, body: { offers: false, quietHoursEnabled: true, quietStart: '22:00', quietEnd: '07:00' },
  }), 200, 'notification preferences');

  createdEventId = (await models.Event.create({
    title: 'Full Flow Development Event', description: 'Temporary live audit event.', category: 'Social', city: 'Ahmedabad',
    venueName: 'Audit Venue', startDateTime: new Date(Date.now() + 86400000), endDateTime: new Date(Date.now() + 90000000),
    capacity: 2, status: 'published', visibility: 'public', registrationOpen: true, organizerId: c.id,
  })).id;
  requireStatus(await api(`/api/events/${createdEventId}/registration`, { method: 'POST', bearer: a.accessToken }), 201, 'event registration');
  const eventDetail = requireStatus(await api(`/api/events/${createdEventId}`, { bearer: a.accessToken }), 200, 'event detail after registration');
  assert.equal(eventDetail.data.event.registeredCount, 1);
  assert.ok(eventDetail.data.event.organizer.imageUrl);
  assert.ok((await api('/api/events/me?category=upcoming', { bearer: a.accessToken })).body.data.events.some((event) => event.id === String(createdEventId)));
  assert.equal((await api('/api/events/me?category=upcoming', { bearer: b.accessToken })).body.data.events.some((event) => event.id === String(createdEventId)), false);

  const roseKey = `full-flow-rose-${Date.now()}`;
  requireStatus(await api('/api/roses/send', { method: 'POST', bearer: a.accessToken, body: { recipientId: b.id, conversationId: Number(conversationId), note: 'A real persisted rose.', idempotencyKey: roseKey } }), 201, 'rose send');
  requireStatus(await api('/api/roses/send', { method: 'POST', bearer: a.accessToken, body: { recipientId: b.id, conversationId: Number(conversationId), note: 'A real persisted rose.', idempotencyKey: roseKey } }), 200, 'rose idempotency');
  assert.equal(await models.RoseTransaction.count({ where: { senderId: a.id, recipientId: b.id, idempotencyKey: roseKey } }), 1);

  requireStatus(await api(`/api/blocks/${c.id}`, { method: 'POST', bearer: a.accessToken }), 200, 'block Charlie');
  assert.equal((await api(`/api/profiles/${c.id}`, { bearer: a.accessToken })).status, 404);
  assert.equal((await api(`/api/profiles/${c.id}`, { bearer: b.accessToken })).status, 200);
  requireStatus(await api(`/api/blocks/${c.id}`, { method: 'DELETE', bearer: a.accessToken }), 200, 'unblock Charlie');
  requireStatus(await api(`/api/profiles/${c.id}`, { bearer: a.accessToken }), 200, 'Charlie profile after unblock');

  requireStatus(await api(`/api/blocks/${b.id}`, { method: 'POST', bearer: a.accessToken }), 200, 'Alice blocks Bob');
  const blockedConversation = (await api('/api/conversations?limit=20', { bearer: a.accessToken })).body.data.conversations.find((item) => item.id === String(conversationId));
  assert.equal(blockedConversation.canMessage, false);
  assert.equal(blockedConversation.availabilityReason, 'you_blocked_profile');
  requireStatus(await api(`/api/blocks/${b.id}`, { method: 'DELETE', bearer: a.accessToken }), 200, 'Alice unblocks Bob');
  const restoredConversation = (await api('/api/conversations?limit=20', { bearer: a.accessToken })).body.data.conversations.find((item) => item.id === String(conversationId));
  assert.equal(restoredConversation.canMessage, true);
  assert.equal(restoredConversation.availabilityReason, null);
  requireStatus(await api(`/api/profiles/${b.id}`, { bearer: a.accessToken }), 200, 'Bob profile after unblock');

  requireStatus(await api(`/api/blocks/${a.id}`, { method: 'POST', bearer: b.accessToken }), 200, 'Bob blocks Alice');
  const reverseBlockedConversation = (await api('/api/conversations?limit=20', { bearer: a.accessToken })).body.data.conversations.find((item) => item.id === String(conversationId));
  assert.equal(reverseBlockedConversation.availabilityReason, 'profile_blocked_you');
  requireStatus(await api(`/api/blocks/${a.id}`, { method: 'DELETE', bearer: b.accessToken }), 200, 'Bob unblocks Alice');

  requireStatus(await api('/api/reports', {
    method: 'POST', bearer: a.accessToken, body: { targetType: 'profile', targetUserId: b.id, conversationId: Number(conversationId), reason: 'other', notes: 'Temporary chat audit report.' },
  }), 201, 'Alice chat report creation');
  assert.equal((await api('/api/reports', {
    method: 'POST', bearer: a.accessToken, body: { targetType: 'profile', targetUserId: c.id, conversationId: Number(conversationId), reason: 'other' },
  })).status, 403);
  requireStatus(await api('/api/reports', {
    method: 'POST', bearer: b.accessToken, body: { targetType: 'profile', targetUserId: a.id, conversationId: Number(conversationId), reason: 'spam' },
  }), 201, 'Bob reverse chat report creation');

  const plans = requireStatus(await api('/api/subscriptions/plans'), 200, 'plans');
  assert.ok(plans.data.plans.length > 0);
  assert.equal((await api('/api/subscriptions/me', { bearer: a.accessToken })).body.data.membership.status, 'none');
  const deviceToken = `full-flow-device-${Date.now()}-${a.id}`;
  requireStatus(await api('/api/devices', { method: 'POST', bearer: a.accessToken, body: { pushToken: deviceToken, platform: 'android', installationId: `audit-${a.id}` } }), 201, 'device registration');

  const verificationForm = new FormData();
  verificationForm.append('aadhaar', new Blob([tinyPng()], { type: 'image/png' }), 'aadhaar.png');
  verificationForm.append('selfie', new Blob([tinyPng()], { type: 'image/png' }), 'selfie.png');
  requireStatus(await api('/api/identity-verification/submissions', { method: 'POST', bearer: c.accessToken, form: verificationForm }), 202, 'identity submission');
  const identityRow = await models.IdentityVerification.findOne({ where: { userId: c.id } });
  privateUploadPaths.push(identityRow.aadhaarStoragePath, identityRow.selfieStoragePath);

  const oldAccess = c.accessToken;
  const oldRefresh = c.refreshToken;
  requireStatus(await api('/api/account/deactivate', { method: 'POST', bearer: oldAccess }), 200, 'account deactivation');
  assert.equal((await api('/api/auth/me', { bearer: oldAccess })).status, 401);
  assert.equal((await api('/api/auth/refresh-token', { method: 'POST', body: { refreshToken: oldRefresh } })).status, 401);
  const reactivated = await login(c);
  assert.equal(reactivated.reactivated, true);

  const preLogoutRefresh = a.refreshToken;
  requireStatus(await api('/api/auth/logout', { method: 'POST', bearer: a.accessToken, body: { refreshToken: a.refreshToken } }), 200, 'logout');
  assert.equal((await api('/api/auth/refresh-token', { method: 'POST', body: { refreshToken: preLogoutRefresh } })).status, 401);
  await login(a);

  await stopHttpServer();
  await startHttpServer();
  await Promise.all([login(a), login(b), login(c)]);

  assert.equal((await api('/api/me/profile', { bearer: a.accessToken })).body.data.profile.bio, 'Alice profile update persisted across restart.');
  assert.equal((await api('/api/me/preferences', { bearer: a.accessToken })).body.data.preferences.minAge, 22);
  assert.ok((await api('/api/me/saved-profiles', { bearer: a.accessToken })).body.data.profiles.some((profile) => profile.id === String(b.id)));
  assert.ok((await api('/api/matches', { bearer: a.accessToken })).body.data.matches.some((match) => match.profile.id === String(b.id)));
  assert.ok((await api(`/api/conversations/${conversationId}/messages`, { bearer: a.accessToken })).body.data.messages.some((message) => message.id === sent.data.message.id && message.status === 'read'));
  assert.ok((await api('/api/events/me?category=upcoming', { bearer: a.accessToken })).body.data.events.some((event) => event.id === String(createdEventId)));
  assert.equal(await models.RoseTransaction.count({ where: { idempotencyKey: roseKey } }), 1);
  assert.equal((await api('/api/notification-preferences', { bearer: a.accessToken })).body.data.preferences.offers, false);
  assert.equal(await models.UserDevice.count({ where: { userId: a.id, pushToken: deviceToken } }), 1);

  requireStatus(await api(`/api/events/${createdEventId}/registration`, { method: 'DELETE', bearer: a.accessToken }), 200, 'event registration cancellation');
  requireStatus(await api(`/api/me/saved-profiles/${b.id}`, { method: 'DELETE', bearer: a.accessToken }), 200, 'saved profile removal');
  requireStatus(await api(`/api/reactions/${b.id}`, { method: 'DELETE', bearer: a.accessToken }), 200, 'like removal');
  const ownNotification = (await api('/api/notifications', { bearer: b.accessToken })).body.data.notifications[0];
  if (ownNotification) {
    requireStatus(await api(`/api/notifications/${ownNotification.id}/read`, { method: 'PUT', bearer: b.accessToken }), 200, 'notification read');
    requireStatus(await api(`/api/notifications/${ownNotification.id}`, { method: 'DELETE', bearer: b.accessToken }), 200, 'notification delete');
  }
  requireStatus(await api(`/api/messages/${sent.data.message.id}`, { method: 'DELETE', bearer: a.accessToken }), 200, 'message delete');
  requireStatus(await api('/api/devices', { method: 'DELETE', bearer: a.accessToken, body: { pushToken: deviceToken } }), 200, 'device removal');

  const cTokenBeforeDelete = c.accessToken;
  requireStatus(await api('/api/account', { method: 'DELETE', bearer: c.accessToken, body: { reason: 'other', details: 'Temporary account lifecycle audit.' } }), 200, 'account deletion');
  assert.equal((await api('/api/auth/me', { bearer: cTokenBeforeDelete })).status, 401);
  assert.equal((await api('/api/auth/login', { method: 'POST', body: { email: c.email, password } })).status, 401);
  assert.equal((await api(`/api/profiles/${c.id}`, { bearer: b.accessToken })).status, 404);

  const counts = {
    users: await models.User.count({ where: { id: userIds } }),
    profiles: await models.OnboardingProfile.count({ where: { userId: userIds } }),
    matches: await models.Match.count({ where: { [Op.or]: [{ userOneId: userIds }, { userTwoId: userIds }] } }),
    messages: await models.Message.count({ where: { conversationId }, paranoid: false }),
    eventRegistrations: await models.EventRegistration.count({ where: { eventId: createdEventId } }),
    roses: await models.RoseTransaction.count({ where: { idempotencyKey: roseKey } }),
  };
  console.log(JSON.stringify({
    database: process.env.DB_NAME,
    accountsCreatedThroughSignupAndOtp: 3,
    frontendApiContractsExercised: true,
    accountIsolation: true,
    backendHttpRestartPersistence: true,
    lifecycle: { logout: true, deactivateReactivate: true, delete: true },
    persistedRowsBeforeCleanup: counts,
  }, null, 2));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await stopHttpServer().catch(() => {});
    await cleanup().catch((error) => {
      console.error('[Cleanup]', error);
      process.exitCode = 1;
    });
    await getSequelize().close().catch(() => {});
  });
