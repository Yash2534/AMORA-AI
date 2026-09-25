const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');

const modelsModule = require('../src/models');
const provider = require('../src/services/firebasePushProvider');
const originalGetModels = modelsModule.getModels;
const originalIsConfigured = provider.isConfigured;
const originalSend = provider.send;

let devices;
let deliveries;
let service;
let deviceController;
let activeModels;

function fakeModels() {
  return {
    UserDevice: {
      async findAll({ where }) {
        return devices.filter(
          (device) => device.userId === where.userId && device.active === where.active,
        );
      },
    },
    NotificationDelivery: {
      async findOrCreate({ where, defaults }) {
        let delivery = deliveries.find(
          (item) => item.notificationId === where.notificationId
            && item.userDeviceId === where.userDeviceId,
        );
        if (!delivery) {
          delivery = {
            ...defaults,
            attemptCount: 0,
            async update(values) { Object.assign(this, values); },
          };
          deliveries.push(delivery);
        }
        return [delivery, delivery === deliveries.at(-1)];
      },
    },
  };
}

before(() => {
  modelsModule.getModels = () => activeModels;
  delete require.cache[require.resolve('../src/services/notificationService')];
  service = require('../src/services/notificationService');
  delete require.cache[require.resolve('../src/controllers/deviceController')];
  deviceController = require('../src/controllers/deviceController');
});

after(() => {
  modelsModule.getModels = originalGetModels;
  provider.isConfigured = originalIsConfigured;
  provider.send = originalSend;
});

test('delivery targets only active devices owned by the notification user', async () => {
  const sent = [];
  devices = [
    { id: 1, userId: 10, active: true, pushToken: 'owner-token', async update(values) { Object.assign(this, values); } },
    { id: 2, userId: 11, active: true, pushToken: 'other-token', async update(values) { Object.assign(this, values); } },
    { id: 3, userId: 10, active: false, pushToken: 'inactive-token', async update(values) { Object.assign(this, values); } },
  ];
  deliveries = [];
  activeModels = fakeModels();
  provider.isConfigured = () => true;
  provider.send = async (message) => { sent.push(message); return { messageId: 'provider-1' }; };

  await service.deliverPush({
    id: 20,
    userId: 10,
    actorUserId: 11,
    type: 'new_message',
    category: 'Messages',
    title: 'New message',
    message: 'Hello',
    data: { conversationId: '7' },
  }, { pushEnabled: true });

  assert.deepEqual(sent.map((item) => item.token), ['owner-token']);
  assert.equal(sent[0].data.type, 'new_message');
  assert.equal(sent[0].data.targetUserId, '11');
  assert.equal(deliveries[0].status, 'sent');
});

test('provider failure is recorded without throwing the business action', async () => {
  devices = [{ id: 1, userId: 10, active: true, pushToken: 'owner-token', async update(values) { Object.assign(this, values); } }];
  deliveries = [];
  activeModels = fakeModels();
  provider.isConfigured = () => true;
  provider.send = async () => { const error = new Error('provider unavailable'); error.code = 'UNAVAILABLE'; throw error; };

  await service.deliverPush({ id: 21, userId: 10, type: 'new_match', category: 'Matches', title: 'Match', message: 'Matched', data: {} }, { pushEnabled: true });
  assert.equal(deliveries[0].status, 'failed');
  assert.equal(deliveries[0].errorCode, 'UNAVAILABLE');
});

test('invalid provider token is deactivated and unavailable credentials stay mocked', async () => {
  const device = { id: 1, userId: 10, active: true, pushToken: 'invalid-token', async update(values) { Object.assign(this, values); } };
  devices = [device];
  deliveries = [];
  activeModels = fakeModels();
  provider.isConfigured = () => true;
  provider.send = async () => { const error = new Error('unregistered'); error.code = 'NOT_FOUND'; error.invalidToken = true; throw error; };
  await service.deliverPush({ id: 22, userId: 10, type: 'new_like', category: 'Likes', title: 'Like', message: 'Liked', data: {} }, { pushEnabled: true });
  assert.equal(device.active, false);
  assert.ok(device.invalidatedAt instanceof Date);

  devices = [{ id: 2, userId: 10, active: true, pushToken: 'no-real-send', async update(values) { Object.assign(this, values); } }];
  deliveries = [];
  activeModels = fakeModels();
  provider.isConfigured = () => false;
  provider.send = async () => { throw new Error('must not send'); };
  await service.deliverPush({ id: 23, userId: 10, type: 'new_like', category: 'Likes', title: 'Like', message: 'Liked', data: {} }, { pushEnabled: true });
  assert.equal(deliveries[0].status, 'credentials_required');
});

test('device registration is idempotent, transfers token ownership, and unregisters only the owner', async () => {
  const rows = [];
  const UserDevice = {
    async findOrCreate({ where, defaults }) {
      let row = rows.find((item) => item.pushToken === where.pushToken);
      const created = !row;
      if (!row) {
        row = { id: rows.length + 1, ...defaults, async update(values) { Object.assign(this, values); } };
        rows.push(row);
      }
      return [row, created];
    },
    async findOne({ where }) {
      return rows.find((item) => item.userId === where.userId && item.pushToken === where.pushToken) || null;
    },
  };
  activeModels = { UserDevice };
  const responses = [];
  const response = () => ({
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { responses.push({ status: this.statusCode, body }); return body; },
  });
  const next = (error) => { throw error; };
  const token = 'shared-device-token-12345678901234567890';

  await deviceController.register({ user: { sub: 1 }, body: { pushToken: token, platform: 'android', installationId: 'install-1' } }, response(), next);
  await deviceController.register({ user: { sub: 1 }, body: { pushToken: token, platform: 'android', installationId: 'install-1' } }, response(), next);
  assert.equal(rows.length, 1);
  assert.deepEqual(responses.map((item) => item.status), [201, 200]);

  await deviceController.register({ user: { sub: 2 }, body: { pushToken: token, platform: 'android', installationId: 'install-1' } }, response(), next);
  assert.equal(rows[0].userId, 2);
  assert.equal(rows[0].active, true);

  await deviceController.remove({ user: { sub: 1 }, body: { pushToken: token } }, response(), next);
  assert.equal(rows[0].active, true);
  await deviceController.remove({ user: { sub: 2 }, body: { pushToken: token } }, response(), next);
  assert.equal(rows[0].active, false);
});
