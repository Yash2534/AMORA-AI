const fs = require('fs');
const { Op } = require('sequelize');
const { getModels } = require('../models');
const { conversationAccess } = require('../services/conversationAccessService');
const { _summaryFor: conversationSummaryFor } = require('./conversationController');
const { serializePublicProfile } = require('../services/publicProfileService');
const { emitConversationEvent, isUserOnline } = require('../realtime/realtimeHub');
const { createNotification } = require('../services/notificationService');
const { storeMedia, removeStoredMedia, absolutePathFor } = require('../utils/chatMediaStorage');

const unavailable = (res) => res.status(404).json({ success: false, message: 'Conversation is not available.', code: 'CONVERSATION_NOT_AVAILABLE', errors: [] });
const mediaFor = (message) => (message.media || []).map((item) => ({
  id: String(item.id),
  type: item.mediaType,
  mimeType: item.mimeType,
  sizeBytes: item.sizeBytes,
  url: `/api/messages/${message.id}/media/${item.id}`,
}));
const messageJson = (message, viewerUserId, otherLastReadMessageId) => ({
  id: String(message.id),
  conversationId: String(message.conversationId),
  senderId: String(message.senderId),
  mine: Number(message.senderId) === Number(viewerUserId),
  type: message.type,
  text: message.deletedAt ? null : message.text,
  context: message.deletedAt ? null : message.context,
  deleted: Boolean(message.deletedAt),
  createdAt: message.createdAt,
  updatedAt: message.updatedAt,
  status: message.status === 'read'
    || (Number(message.senderId) === Number(viewerUserId) && Number(otherLastReadMessageId || 0) >= Number(message.id))
    ? 'read'
    : message.status === 'delivered' ? 'delivered' : 'sent',
  deliveredAt: message.deliveredAt,
  readAt: message.readAt,
  media: message.deletedAt ? [] : mediaFor(message),
});

async function includedMessage(messageId, transaction) {
  const { Message, MessageMedia } = getModels();
  return Message.findByPk(messageId, {
    include: [{ model: MessageMedia, as: 'media', required: false }],
    transaction,
  });
}

exports.history = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const conversationId = Number(req.params.conversationId);
    const access = await conversationAccess(conversationId, userId);
    if (!access) {
      const conversation = await conversationSummaryFor(req, conversationId, userId);
      if (!conversation || conversation.canMessage) return unavailable(res);
      return res.json({
        success: true,
        message: 'Conversation availability retrieved.',
        data: {
          conversation,
          messages: [],
          pagination: { hasMore: false, nextCursor: null },
        },
      });
    }
    const { Message, MessageMedia } = getModels();
    const deliveredAt = new Date();
    const [deliveredCount] = await Message.update(
      { status: 'delivered', deliveredAt },
      { where: { conversationId, senderId: { [Op.ne]: userId }, status: 'sent' } },
    );
    const limit = Number(req.query.limit || 30);
    const where = { conversationId };
    if (req.query.beforeId) where.id = { [Op.lt]: Number(req.query.beforeId) };
    const rows = await Message.findAll({
      where,
      include: [{ model: MessageMedia, as: 'media', required: false }],
      order: [['id', 'DESC']],
      limit: limit + 1,
      subQuery: false,
    });
    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const otherProfile = access.otherUser.OnboardingProfile;
    const participant = serializePublicProfile(req, access.otherUser, otherProfile);
    participant.online = isUserOnline(access.otherUser.id);
    if (deliveredCount > 0) {
      const lastDelivered = await Message.findOne({
        where: { conversationId, senderId: { [Op.ne]: userId }, deliveredAt },
        attributes: ['id'],
        order: [['id', 'DESC']],
      });
      if (lastDelivered) {
        await emitConversationEvent(conversationId, 'message.delivered', {
          conversationId: String(conversationId),
          userId: String(userId),
          lastDeliveredMessageId: String(lastDelivered.id),
        });
      }
    }
    return res.json({
      success: true,
      message: pageRows.length ? 'Messages retrieved.' : 'No messages found.',
      data: {
        conversation: {
          id: String(conversationId),
          participant,
          canMessage: true,
          draft: access.member.draftText || '',
          muted: Boolean(access.member.mutedAt)
            && (!access.member.mutedUntil || new Date(access.member.mutedUntil) > new Date()),
          mutedUntil: access.member.mutedUntil,
        },
        messages: pageRows.reverse().map((message) => messageJson(message, userId, access.other.lastReadMessageId)),
        pagination: { limit, hasMore, nextCursor: hasMore ? String(pageRows[0].id) : null },
      },
    });
  } catch (error) {
    return next(error);
  }
};

function sanitizedContext(value) {
  if (!value || typeof value !== 'object') return null;
  if (!['profilePrompt', 'rose'].includes(value.type)) return null;
  return {
    type: value.type,
    ...(value.promptId ? { promptId: String(value.promptId).slice(0, 100) } : {}),
    title: String(value.title || '').slice(0, 200),
    detail: String(value.detail || '').slice(0, 500),
  };
}

exports.send = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const conversationId = Number(req.params.conversationId);
    const text = req.body.text.trim();
    const access = await conversationAccess(conversationId, userId);
    if (!access) return unavailable(res);
    const { Conversation, Message } = getModels();
    let message;
    await Message.sequelize.transaction(async (transaction) => {
      const delivered = isUserOnline(access.other.userId);
      message = await Message.create({
        conversationId,
        senderId: userId,
        type: 'text',
        text,
        context: sanitizedContext(req.body.context),
        status: delivered ? 'delivered' : 'sent',
        deliveredAt: delivered ? new Date() : null,
      }, { transaction });
      await Conversation.update({ lastMessageId: message.id, lastMessageAt: message.createdAt }, { where: { id: conversationId }, transaction });
    });
    message = await includedMessage(message.id);
    const payload = messageJson(message, userId, access.other.lastReadMessageId);
    await emitConversationEvent(conversationId, 'message.created', { conversationId: String(conversationId), message: payload });
    await emitConversationEvent(conversationId, 'conversation.updated', { conversationId: String(conversationId), message: payload });
    await createNotification({ userId: Number(access.other.userId), actorUserId: userId, type: 'new_message', category: 'message', title: req.authUser.name, message: text.slice(0, 160), data: { conversationId: String(conversationId), messageId: String(message.id) }, conversationId, dedupeKey: `message:${message.id}` });
    return res.status(201).json({ success: true, message: 'Message sent.', data: { message: payload } });
  } catch (error) {
    return next(error);
  }
};

exports.read = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const conversationId = Number(req.params.conversationId);
    const access = await conversationAccess(conversationId, userId);
    if (!access) return unavailable(res);
    const { Message, ConversationParticipant } = getModels();
    let target;
    if (req.body.messageId) target = await Message.findOne({ where: { id: req.body.messageId, conversationId }, attributes: ['id'] });
    else target = await Message.findOne({ where: { conversationId }, attributes: ['id'], order: [['id', 'DESC']] });
    if (req.body.messageId && !target) return res.status(400).json({ success: false, message: 'messageId does not belong to this conversation.', code: 'INVALID_READ_POSITION', errors: [] });
    const nextId = Number(target?.id || 0);
    if (nextId > Number(access.member.lastReadMessageId || 0)) {
      await ConversationParticipant.update({ lastReadMessageId: nextId || null, lastReadAt: new Date() }, { where: { id: access.member.id } });
    }
    if (nextId) {
      const now = new Date();
      await Message.update(
        { status: 'read', deliveredAt: now, readAt: now },
        { where: { conversationId, senderId: { [Op.ne]: userId }, id: { [Op.lte]: nextId }, status: { [Op.ne]: 'read' } } },
      );
    }
    const unreadCount = nextId ? await Message.count({ where: { conversationId, senderId: { [Op.ne]: userId }, deletedAt: null, id: { [Op.gt]: nextId } } }) : 0;
    const payload = { conversationId: String(conversationId), userId: String(userId), lastReadMessageId: nextId ? String(nextId) : null, unreadCount };
    await emitConversationEvent(conversationId, 'message.read', payload);
    return res.json({ success: true, message: 'Read position updated.', data: payload });
  } catch (error) {
    return next(error);
  }
};

exports.media = async (req, res, next) => {
  let stored;
  try {
    const userId = Number(req.user.sub);
    const conversationId = Number(req.params.conversationId);
    const access = await conversationAccess(conversationId, userId);
    if (!access) return unavailable(res);
    if (!req.file) return res.status(400).json({ success: false, message: 'An image is required.', code: 'VALIDATION_ERROR', errors: [] });
    const { Conversation, Message, MessageMedia } = getModels();
    let message;
    await Message.sequelize.transaction(async (transaction) => {
      const delivered = isUserOnline(access.other.userId);
      message = await Message.create({
        conversationId,
        senderId: userId,
        type: 'image',
        text: req.body.caption?.trim() || null,
        status: delivered ? 'delivered' : 'sent',
        deliveredAt: delivered ? new Date() : null,
      }, { transaction });
      stored = await storeMedia(message.id, req.file);
      await MessageMedia.create({ messageId: message.id, mediaType: 'image', originalName: stored.originalName, storagePath: stored.storagePath, mimeType: stored.mimeType, sizeBytes: stored.sizeBytes }, { transaction });
      await Conversation.update({ lastMessageId: message.id, lastMessageAt: message.createdAt }, { where: { id: conversationId }, transaction });
    });
    message = await includedMessage(message.id);
    const payload = messageJson(message, userId, access.other.lastReadMessageId);
    await emitConversationEvent(conversationId, 'message.created', { conversationId: String(conversationId), message: payload });
    await emitConversationEvent(conversationId, 'conversation.updated', { conversationId: String(conversationId), message: payload });
    await createNotification({ userId: Number(access.other.userId), actorUserId: userId, type: 'new_message', category: 'message', title: req.authUser.name, message: 'Sent you a photo.', data: { conversationId: String(conversationId), messageId: String(message.id) }, conversationId, dedupeKey: `message:${message.id}` });
    return res.status(201).json({ success: true, message: 'Image message sent.', data: { message: payload } });
  } catch (error) {
    if (stored?.absolutePath) await removeStoredMedia(stored.absolutePath);
    if (error.code === 'INVALID_MEDIA_TYPE') return res.status(400).json({ success: false, message: error.message, code: error.code, errors: [] });
    return next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { Message, Conversation, MessageMedia } = getModels();
    const message = await Message.findByPk(req.params.messageId, { include: [{ model: MessageMedia, as: 'media', required: false }] });
    if (!message) return res.json({ success: true, message: 'Message was already unavailable.', data: { messageId: String(req.params.messageId), deleted: true } });
    const access = await conversationAccess(message.conversationId, userId);
    if (!access) return unavailable(res);
    if (Number(message.senderId) !== userId) return res.status(403).json({ success: false, message: 'Only the sender can delete this message.', code: 'MESSAGE_DELETE_FORBIDDEN', errors: [] });
    if (!message.deletedAt) {
      await Message.sequelize.transaction(async (transaction) => {
        message.deletedAt = new Date();
        await message.save({ transaction });
        if (Number(access.conversation.lastMessageId) === Number(message.id)) {
          const previous = await Message.findOne({ where: { conversationId: message.conversationId, deletedAt: null, id: { [Op.ne]: message.id } }, order: [['id', 'DESC']], transaction });
          await Conversation.update({ lastMessageId: previous?.id || null, lastMessageAt: previous?.createdAt || null }, { where: { id: message.conversationId }, transaction });
        }
      });
      for (const media of message.media || []) {
        const file = absolutePathFor(media.storagePath);
        if (file) await removeStoredMedia(file);
      }
    }
    const payload = { conversationId: String(message.conversationId), messageId: String(message.id), deleted: true };
    await emitConversationEvent(message.conversationId, 'message.deleted', payload);
    await emitConversationEvent(message.conversationId, 'conversation.updated', payload);
    return res.json({ success: true, message: 'Message deleted.', data: payload });
  } catch (error) {
    return next(error);
  }
};

exports.downloadMedia = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { Message, MessageMedia } = getModels();
    const message = await Message.findByPk(req.params.messageId, { attributes: ['id', 'conversationId', 'deletedAt'] });
    if (!message || message.deletedAt || !(await conversationAccess(message.conversationId, userId))) return unavailable(res);
    const media = await MessageMedia.findOne({ where: { id: req.params.mediaId, messageId: message.id } });
    const file = media && absolutePathFor(media.storagePath);
    if (!media || !file || !fs.existsSync(file)) return res.status(404).json({ success: false, message: 'Media is not available.', code: 'MEDIA_NOT_AVAILABLE', errors: [] });
    res.type(media.mimeType);
    res.set('Cache-Control', 'private, max-age=300');
    return res.sendFile(file);
  } catch (error) {
    return next(error);
  }
};

exports.saveDraft = async (req, res, next) => {
  try {
    const access = await conversationAccess(req.params.conversationId, req.user.sub);
    if (!access) return unavailable(res);
    const text = req.body.text.trim();
    await access.member.update({ draftText: text || null });
    return res.json({ success: true, message: 'Draft saved.', data: { conversationId: String(access.conversation.id), draft: text } });
  } catch (error) { return next(error); }
};

exports.clearDraft = async (req, res, next) => {
  try {
    const access = await conversationAccess(req.params.conversationId, req.user.sub);
    if (!access) return unavailable(res);
    await access.member.update({ draftText: null });
    return res.json({ success: true, message: 'Draft cleared.', data: { conversationId: String(access.conversation.id), draft: '' } });
  } catch (error) { return next(error); }
};
