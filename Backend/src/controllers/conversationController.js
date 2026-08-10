const { QueryTypes } = require('sequelize');
const { getModels } = require('../models');
const { areUsersBlocked } = require('../services/accessControlService');
const { pairKeyFor, activeMatch, eligibleTarget } = require('../services/conversationAccessService');
const { serializePublicProfile } = require('../services/publicProfileService');
const { isUserOnline } = require('../realtime/realtimeHub');

async function summaryRows(userId, options = {}) {
  const { Conversation } = getModels();
  const sequelize = Conversation.sequelize;
  const limit = Number(options.limit || 20);
  const offset = Number(options.offset || 0);
  const rows = await sequelize.query(`
    SELECT c.id, c.createdAt, c.updatedAt, c.lastMessageAt,
      other.userId AS participantUserId,
      lm.id AS lastMessageId, lm.type AS lastMessageType, lm.text AS lastMessageText,
      lm.createdAt AS lastMessageCreatedAt, lm.deletedAt AS lastMessageDeletedAt,
      (SELECT COUNT(*) FROM Messages unread
        WHERE unread.conversationId = c.id
          AND unread.senderId <> :userId
          AND unread.deletedAt IS NULL
          AND unread.id > COALESCE(me.lastReadMessageId, 0)) AS unreadCount
    FROM Conversations c
    INNER JOIN ConversationParticipants me ON me.conversationId = c.id AND me.userId = :userId
    INNER JOIN ConversationParticipants other ON other.conversationId = c.id AND other.userId <> :userId
    INNER JOIN Users otherUser ON otherUser.id = other.userId AND otherUser.accountStatus = 'active'
    INNER JOIN OnboardingProfiles otherProfile ON otherProfile.userId = other.userId AND otherProfile.onboardingCompleted = 1
    INNER JOIN Matches matchRow ON
      (matchRow.userOneId = LEAST(:userId, other.userId) AND matchRow.userTwoId = GREATEST(:userId, other.userId))
    LEFT JOIN Messages lm ON lm.id = c.lastMessageId
    WHERE NOT EXISTS (
      SELECT 1 FROM Blocks visibilityBlock
      WHERE (visibilityBlock.blockerUserId = :userId AND visibilityBlock.blockedUserId = other.userId)
         OR (visibilityBlock.blockedUserId = :userId AND visibilityBlock.blockerUserId = other.userId)
    )
    ${options.conversationId ? 'AND c.id = :conversationId' : ''}
    ORDER BY COALESCE(c.lastMessageAt, c.createdAt) DESC, c.id DESC
    LIMIT :limit OFFSET :offset
  `, {
    replacements: { userId: Number(userId), conversationId: Number(options.conversationId || 0), limit, offset },
    type: QueryTypes.SELECT,
  });
  return rows;
}

async function serializeRows(req, rows) {
  const { User, OnboardingProfile } = getModels();
  const ids = [...new Set(rows.map((row) => Number(row.participantUserId)))];
  const users = ids.length ? await User.findAll({
    where: { id: ids },
    attributes: ['id', 'name', 'isVerified'],
    include: [{ model: OnboardingProfile, required: true }],
  }) : [];
  const byId = new Map(users.map((user) => [Number(user.id), user]));
  return rows.map((row) => {
    const user = byId.get(Number(row.participantUserId));
    const participant = serializePublicProfile(req, user, user.OnboardingProfile);
    participant.online = isUserOnline(user.id);
    const lastMessage = row.lastMessageId ? {
      id: String(row.lastMessageId),
      type: row.lastMessageType,
      text: row.lastMessageDeletedAt ? null : row.lastMessageText,
      deleted: Boolean(row.lastMessageDeletedAt),
      createdAt: row.lastMessageCreatedAt,
    } : null;
    return {
      id: String(row.id),
      participant,
      lastMessage,
      unreadCount: Number(row.unreadCount || 0),
      updatedAt: row.lastMessageAt || row.updatedAt || row.createdAt,
    };
  });
}

async function summaryFor(req, conversationId, userId) {
  const rows = await summaryRows(userId, { conversationId, limit: 1, offset: 0 });
  return rows.length ? (await serializeRows(req, rows))[0] : null;
}

exports.create = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const targetUserId = Number(req.body.targetUserId);
    if (userId === targetUserId) return res.status(400).json({ success: false, message: 'You cannot start a conversation with yourself.', code: 'SELF_CONVERSATION_NOT_ALLOWED', errors: [] });
    const { User, Conversation, ConversationParticipant } = getModels();
    let conversation;
    let created = false;
    let denialCode = 'CONVERSATION_NOT_ALLOWED';
    await User.sequelize.transaction(async (transaction) => {
      const target = await eligibleTarget(targetUserId, transaction);
      if (!target) {
        denialCode = 'TARGET_NOT_AVAILABLE';
        return;
      }
      if (await areUsersBlocked(userId, targetUserId, { transaction })) {
        denialCode = 'CONVERSATION_NOT_ALLOWED';
        return;
      }
      if (!(await activeMatch(userId, targetUserId, { transaction }))) return;
      const pairKey = pairKeyFor(userId, targetUserId);
      [conversation, created] = await Conversation.findOrCreate({
        where: { pairKey },
        defaults: { pairKey, type: 'direct' },
        transaction,
      });
      await ConversationParticipant.bulkCreate([
        { conversationId: conversation.id, userId, joinedAt: new Date() },
        { conversationId: conversation.id, userId: targetUserId, joinedAt: new Date() },
      ], { ignoreDuplicates: true, transaction });
    });
    if (!conversation) {
      const targetUnavailable = denialCode === 'TARGET_NOT_AVAILABLE';
      return res.status(targetUnavailable ? 404 : 403).json({
        success: false,
        message: targetUnavailable ? 'The target profile is not available.' : 'A current active match is required to start this conversation.',
        code: denialCode,
        errors: [],
      });
    }
    const value = await summaryFor(req, conversation.id, userId);
    return res.status(created ? 201 : 200).json({ success: true, message: created ? 'Conversation created.' : 'Conversation retrieved.', data: { conversation: value, created } });
  } catch (error) {
    return next(error);
  }
};

exports.list = async (req, res, next) => {
  try {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const rows = await summaryRows(req.user.sub, { limit: limit + 1, offset: (page - 1) * limit });
    const hasMore = rows.length > limit;
    const selected = hasMore ? rows.slice(0, limit) : rows;
    return res.json({
      success: true,
      message: selected.length ? 'Conversations retrieved.' : 'No conversations found.',
      data: {
        conversations: await serializeRows(req, selected),
        pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
      },
    });
  } catch (error) {
    return next(error);
  }
};

exports._summaryFor = summaryFor;
