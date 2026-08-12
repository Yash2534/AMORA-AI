require('../src/config/bootstrapEnv');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { createHttpServer } = require('../src/server');

if (!process.argv.includes('--confirm-development-db') || process.env.NODE_ENV === 'production') {
  throw new Error('Pass --confirm-development-db and run only against the development schema.');
}

let server;
let models;
const userIds = [];

function tokenFor(user) {
  return jwt.sign({ sub: user.id, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' });
}

async function createUser(name) {
  const suffix = `${Date.now()}_${Math.random().toString(36).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@like-flow-verification.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    termsAcceptedAt: new Date(),
  });
  userIds.push(user.id);
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: '1997-04-03',
    gender: 'Female',
    interestedIn: ['Male'],
    relationshipGoals: ['Meaningful Dating'],
    city: 'Ahmedabad',
    profession: 'Engineer',
    education: 'Graduate',
    photos: ['/uploads/notification.jpg'],
    primaryPhotoIndex: 0,
    stage: 'complete',
    onboardingCompleted: true,
  });
  return user;
}

async function api(baseUrl, path, { method = 'GET', bearer, body } = {}) {
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

async function cleanup() {
  if (!models || !userIds.length) return;
  await models.Notification.destroy({ where: { [Op.or]: [{ userId: userIds }, { actorUserId: userIds }] }, force: true });
  await models.NotificationPreference.destroy({ where: { userId: userIds } });
  await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userIds }, { targetUserId: userIds }] } });
  await models.OnboardingProfile.destroy({ where: { userId: userIds } });
  await models.User.destroy({ where: { id: userIds } });
}

async function main() {
  await initializeDatabase();
  models = getModels();
  const priya = await createUser('Priya');
  const rahul = await createUser('Rahul');
  const userC = await createUser('User C');
  server = createHttpServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  const like = await api(baseUrl, '/api/discover/swipe', {
    method: 'POST',
    bearer: tokenFor(priya),
    body: { targetUserId: rahul.id, action: 'like' },
  });
  assert.equal(like.status, 200, JSON.stringify(like.body));

  const action = await models.DiscoverAction.findOne({ where: { actorUserId: priya.id, targetUserId: rahul.id } });
  assert.equal(action.action, 'like');
  const notification = await models.Notification.findOne({ where: { userId: rahul.id, actorUserId: priya.id, type: 'new_like' } });
  assert.ok(notification);

  const receiver = await api(baseUrl, '/api/notifications', { bearer: tokenFor(rahul) });
  const received = receiver.body.data.notifications.find((item) => item.id === String(notification.id));
  assert.equal(received.actor.name, 'Priya');
  assert.equal(received.actor.userId, String(priya.id));
  assert.ok(received.actor.photoUrl.endsWith('/uploads/notification.jpg'));

  for (const user of [priya, userC]) {
    const isolated = await api(baseUrl, `/api/notifications?userId=${rahul.id}`, { bearer: tokenFor(user) });
    assert.equal(isolated.body.data.notifications.some((item) => item.id === String(notification.id)), false);
  }
  assert.equal((await api(baseUrl, `/api/notifications/${notification.id}/read`, { method: 'PUT', bearer: tokenFor(userC) })).status, 404);
  assert.equal((await api(baseUrl, `/api/notifications/${notification.id}`, { method: 'DELETE', bearer: tokenFor(userC) })).status, 404);

  await priya.update({ name: 'Priya Shah' });
  const freshSession = await api(baseUrl, '/api/notifications', { bearer: tokenFor(rahul) });
  const refreshed = freshSession.body.data.notifications.find((item) => item.id === String(notification.id));
  assert.equal(refreshed.actor.name, 'Priya Shah');

  assert.equal((await api(baseUrl, '/api/discover/swipe', {
    method: 'POST',
    bearer: tokenFor(priya),
    body: { targetUserId: rahul.id, action: 'like' },
  })).status, 200);
  assert.equal(await models.Notification.count({ where: { userId: rahul.id, actorUserId: priya.id, type: 'new_like' } }), 1);

  console.log(JSON.stringify({
    database: process.env.DB_NAME,
    like: { actorUserId: action.actorUserId, targetUserId: action.targetUserId, action: action.action },
    notification: { id: String(notification.id), recipientUserId: notification.userId, actorUserId: notification.actorUserId, type: notification.type },
    apiActor: refreshed.actor,
    isolatedFromSenderAndThirdUser: true,
    duplicateRetryCount: 1,
  }, null, 2));
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (server) await new Promise((resolve) => server.close(resolve));
    await cleanup().catch((error) => {
      console.error('[Cleanup]', error.message);
      process.exitCode = 1;
    });
    await getSequelize().close().catch(() => {});
  });
