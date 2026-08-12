const { getModels } = require('../models');
const pushProvider = require('./firebasePushProvider');

const preferenceField = {
  like: 'newMatches',
  likes: 'newMatches',
  'super likes': 'newMatches',
  match: 'newMatches',
  message: 'messages',
  event: 'eventReminders',
  payment: 'paymentsAndMembership',
  membership: 'paymentsAndMembership',
  offer: 'offers',
  safety: 'safetyUpdates',
  verification: 'safetyUpdates',
  gift: 'messages',
};

async function conversationIsMuted(userId, conversationId, transaction = null) {
  if (!conversationId) return false;
  const { ConversationParticipant } = getModels();
  const row = await ConversationParticipant.findOne({ where: { userId, conversationId }, attributes: ['mutedAt', 'mutedUntil'], transaction });
  return Boolean(row?.mutedAt) && (!row.mutedUntil || new Date(row.mutedUntil) > new Date());
}

async function deliverPush(notification, preferences) {
  if (!preferences?.pushEnabled) return;
  const { UserDevice, NotificationDelivery } = getModels();
  const devices = await UserDevice.findAll({ where: { userId: notification.userId, active: true } });
  for (const device of devices) {
    const [delivery] = await NotificationDelivery.findOrCreate({
      where: { notificationId: notification.id, userDeviceId: device.id, channel: 'push' },
      defaults: { notificationId: notification.id, userDeviceId: device.id, channel: 'push', status: 'pending' },
    });
    if (delivery.status === 'sent') continue;
    if (!pushProvider.isConfigured()) {
      await delivery.update({ status: 'credentials_required', errorCode: 'PUSH_CREDENTIALS_REQUIRED' });
      continue;
    }
    try {
      const result = await pushProvider.send({ token: device.pushToken, title: notification.title, body: notification.message, data: notification.data || {} });
      await delivery.update({ status: 'sent', providerMessageId: result.messageId, attemptCount: Number(delivery.attemptCount) + 1, lastAttemptAt: new Date(), errorCode: null });
    } catch (error) {
      await delivery.update({ status: 'failed', attemptCount: Number(delivery.attemptCount) + 1, lastAttemptAt: new Date(), errorCode: String(error.code || 'PUSH_DELIVERY_FAILED').slice(0, 100) });
      if (error.invalidToken) await device.update({ active: false, invalidatedAt: new Date() });
    }
  }
}

async function createNotification({ userId, actorUserId = null, type, category, title, message, data = {}, conversationId = null, dedupeKey = null, transaction = null }) {
  const { Notification, NotificationPreference, User } = getModels();
  const user = await User.findOne({ where: { id: userId, accountStatus: 'active' }, attributes: ['id'], transaction });
  if (!user || await conversationIsMuted(userId, conversationId, transaction)) return null;
  const [preferences] = await NotificationPreference.findOrCreate({ where: { userId }, defaults: { userId }, transaction });
  const field = preferenceField[String(category).trim().toLowerCase()];
  if (field && preferences[field] === false) return null;
  const values = { userId, actorUserId, type, category, title, message, data, isRead: false };
  const [notification, created] = dedupeKey
    ? await Notification.findOrCreate({ where: { userId, dedupeKey }, defaults: { ...values, dedupeKey }, transaction })
    : [await Notification.create(values, { transaction }), true];
  if (created) {
    const push = () => deliverPush(notification, preferences).catch((error) => console.error('[Push]', error.message));
    if (transaction) transaction.afterCommit(push);
    else await push();
  }
  return notification;
}

module.exports = { createNotification, deliverPush, conversationIsMuted };
