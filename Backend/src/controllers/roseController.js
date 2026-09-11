const { getModels } = require('../models');
const { UniqueConstraintError } = require('sequelize');
const { areUsersBlocked } = require('../services/accessControlService');
const { idempotencyKey, publicError } = require('../services/paymentService');
const { createNotification } = require('../services/notificationService');
const { activeMatch, ensureDirectConversation } = require('../services/conversationAccessService');
const { emitConversationEvent } = require('../realtime/realtimeHub');

const isRetryableTransactionError = (error) => ['ER_LOCK_DEADLOCK', 'ER_LOCK_WAIT_TIMEOUT'].includes(error?.code)
  || [1213, 1205].includes(Number(error?.errno));
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function withTransactionRetry(operation, attempts = 3) {
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try { return await operation(); } catch (error) {
      if (!isRetryableTransactionError(error) || attempt === attempts) throw error;
      await sleep(25 * attempt);
    }
  }
}

function roseJson(row) {
  return {
    id: String(row.id),
    senderId: String(row.senderId),
    recipientId: String(row.recipientId),
    conversationId: row.conversationId == null ? null : String(row.conversationId),
    status: row.status,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function assertRetryMatches(row, expected) {
  if (Number(row.recipientId) !== expected.recipientId
      || (row.conversationId == null ? null : Number(row.conversationId)) !== expected.conversationId
      || (row.note || null) !== expected.note) {
    throw publicError(
      'The idempotency key was already used for another Rose.',
      'IDEMPOTENCY_CONFLICT',
      409,
    );
  }
}

exports.send = async (req, res, next) => {
  try {
    const senderId = Number(req.user.sub);
    const recipientId = Number(req.body.recipientId);
    const conversationId = req.body.conversationId ? Number(req.body.conversationId) : null;
    const note = req.body.note?.trim() || null;
    const key = idempotencyKey(req);
    if (senderId === recipientId) {
      throw publicError('You cannot send a Rose to yourself.', 'SELF_ROSE_NOT_ALLOWED');
    }

    const { User, OnboardingProfile, RoseTransaction, ConversationParticipant, Conversation, Message } = getModels();
    const recipient = await User.findOne({
      where: { id: recipientId, accountStatus: 'active' },
      include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
    });
    if (!recipient) throw publicError('The recipient is not available.', 'RECIPIENT_NOT_AVAILABLE', 404);
    if (await areUsersBlocked(senderId, recipientId)) {
      throw publicError('Rose sending is not available for this relationship.', 'ROSE_NOT_ALLOWED', 403);
    }
    if (conversationId) {
      const memberships = await ConversationParticipant.count({
        where: { conversationId, userId: [senderId, recipientId] },
      });
      if (memberships !== 2) {
        throw publicError('The conversation is not available for this Rose.', 'CONVERSATION_NOT_ALLOWED', 403);
      }
    }
    // Chat is a matched-member surface. Roses may not create a messaging
    // bypass; a valid active match is required before a Rose chat event is
    // persisted.
    if (!(await activeMatch(senderId, recipientId))) {
      throw publicError('A Rose can be sent in an existing match conversation.', 'CONVERSATION_NOT_ALLOWED', 403);
    }

    let row;
    let notification;
    let message;
    let resolvedConversationId;
    let created = false;
    try {
      await withTransactionRetry(() => RoseTransaction.sequelize.transaction(async (transaction) => {
        const conversation = conversationId
          ? { conversation: { id: conversationId } }
          : await ensureDirectConversation(senderId, recipientId, { transaction });
        resolvedConversationId = Number(conversation.conversation.id);
        row = await RoseTransaction.findOne({
          where: { senderId, idempotencyKey: key },
          transaction,
          lock: transaction.LOCK.UPDATE,
        });
        if (row) {
          assertRetryMatches(row, { recipientId, conversationId: resolvedConversationId, note });
        } else {
          row = await RoseTransaction.create({
            senderId,
            recipientId,
            conversationId: resolvedConversationId,
            idempotencyKey: key,
            status: 'sent',
            note,
          }, { transaction });
          created = true;
        }
        message = await Message.findOne({ where: { roseTransactionId: row.id }, transaction, lock: transaction.LOCK.UPDATE });
        if (!message) {
          message = await Message.create({
            conversationId: resolvedConversationId,
            senderId,
            type: 'rose',
            text: note,
            roseTransactionId: row.id,
            context: { type: 'rose', title: 'Rose', detail: 'A special AMORAA Rose' },
            status: 'sent',
          }, { transaction });
          await Conversation.update({ lastMessageId: message.id, lastMessageAt: message.createdAt }, { where: { id: resolvedConversationId }, transaction });
        }
        notification = await createNotification({
          userId: recipientId,
          actorUserId: senderId,
          type: 'rose_received',
          category: 'Messages',
          title: 'You received a Rose',
          message: `${req.authUser.name} sent you a Rose.`,
          data: {
            route: '/chat-detail',
            targetUserId: String(senderId),
            roseTransactionId: String(row.id),
            conversationId: String(resolvedConversationId),
          },
          conversationId,
          dedupeKey: `rose:${row.id}`,
          transaction,
        });
      }));
    } catch (error) {
      if (!(error instanceof UniqueConstraintError)) throw error;
      row = await RoseTransaction.findOne({ where: { senderId, idempotencyKey: key } });
      if (!row) throw error;
      assertRetryMatches(row, { recipientId, conversationId: resolvedConversationId, note });
      created = false;
    }

    const messageData = {
      id: String(message.id), conversationId: String(message.conversationId), senderId: String(message.senderId),
      mine: true, type: 'rose', text: message.text, context: message.context,
      roseTransactionId: String(row.id), status: message.status, createdAt: message.createdAt,
    };
    await emitConversationEvent(resolvedConversationId, 'message.created', { conversationId: String(resolvedConversationId), message: messageData }).catch(() => {});

    return res.status(created ? 201 : 200).json({
      success: true,
      message: created ? 'Rose sent successfully.' : 'Rose was already sent.',
      data: {
        roseTransaction: roseJson(row),
        conversationId: String(resolvedConversationId),
        message: messageData,
        notification: notification ? { id: String(notification.id) } : null,
      },
    });
  } catch (error) {
    if (Number(error.status || 500) < 500) {
      await require('../services/matchingActionFailureService').recordFailure({
        actionType: 'rose', actorUserId: req.user?.sub, targetUserId: req.body?.recipientId,
        code: error.code || 'ROSE_NOT_ALLOWED', stage: error.code === 'CONVERSATION_NOT_ALLOWED' ? 'conversation' : 'eligibility',
        retryable: false,
      }).catch(() => {});
    }
    return next(error);
  }
};

exports._json = { roseJson, isRetryableTransactionError, withTransactionRetry };
