const { getModels } = require('../models');
const { areUsersBlocked } = require('../services/accessControlService');
const { idempotencyKey, publicError } = require('../services/paymentService');
const { createNotification } = require('../services/notificationService');

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

    const { User, OnboardingProfile, RoseTransaction, ConversationParticipant } = getModels();
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

    let row;
    let notification;
    let created = false;
    await RoseTransaction.sequelize.transaction(async (transaction) => {
      row = await RoseTransaction.findOne({
        where: { senderId, idempotencyKey: key },
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (row) {
        assertRetryMatches(row, { recipientId, conversationId, note });
      } else {
        row = await RoseTransaction.create({
          senderId,
          recipientId,
          conversationId,
          idempotencyKey: key,
          status: 'sent',
          note,
        }, { transaction });
        created = true;
      }
      notification = await createNotification({
        userId: recipientId,
        actorUserId: senderId,
        type: 'rose_received',
        category: 'Messages',
        title: 'You received a Rose',
        message: `${req.authUser.name} sent you a Rose.`,
        data: {
          route: conversationId ? '/chat-detail' : '/profile-detail',
          targetUserId: String(senderId),
          roseTransactionId: String(row.id),
          ...(conversationId ? { conversationId: String(conversationId) } : {}),
        },
        conversationId,
        dedupeKey: `rose:${row.id}`,
        transaction,
      });
    });

    return res.status(created ? 201 : 200).json({
      success: true,
      message: created ? 'Rose sent successfully.' : 'Rose was already sent.',
      data: {
        roseTransaction: roseJson(row),
        notification: notification ? { id: String(notification.id) } : null,
      },
    });
  } catch (error) {
    return next(error);
  }
};

exports._json = { roseJson };
