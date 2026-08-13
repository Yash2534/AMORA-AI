const { Op } = require('sequelize');
const { getModels } = require('../models');
const { areUsersBlocked, matchPairWhere } = require('./accessControlService');

const pairKeyFor = (firstUserId, secondUserId) => {
  const values = [Number(firstUserId), Number(secondUserId)].sort((a, b) => a - b);
  return `${values[0]}:${values[1]}`;
};

async function activeMatch(firstUserId, secondUserId, options = {}) {
  const { Match } = getModels();
  return Match.findOne({
    where: matchPairWhere(Number(firstUserId), Number(secondUserId)),
    attributes: ['id'],
    transaction: options.transaction,
  });
}

async function conversationAccess(conversationId, userId, options = {}) {
  const { Conversation, ConversationParticipant, User, OnboardingProfile } = getModels();
  const conversation = await Conversation.findByPk(conversationId, {
    include: [{
      model: ConversationParticipant,
      as: 'participants',
      required: true,
      include: [{
        model: User,
        as: 'user',
        required: true,
        attributes: ['id', 'name', 'identityVerifiedAt', 'accountStatus'],
        include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
      }],
    }],
    transaction: options.transaction,
    lock: options.lock,
  });
  if (!conversation) return null;
  const member = conversation.participants.find((item) => Number(item.userId) === Number(userId));
  const other = conversation.participants.find((item) => Number(item.userId) !== Number(userId));
  if (!member || !other || conversation.participants.length !== 2) return null;
  if (other.user?.accountStatus !== 'active') return null;
  if (await areUsersBlocked(userId, other.userId, { transaction: options.transaction })) return null;
  if (!(await activeMatch(userId, other.userId, { transaction: options.transaction }))) return null;
  return { conversation, member, other, otherUser: other.user };
}

async function eligibleTarget(targetUserId, transaction) {
  const { User, OnboardingProfile } = getModels();
  return User.findOne({
    where: { id: Number(targetUserId), accountStatus: 'active' },
    attributes: ['id', 'name', 'identityVerifiedAt', 'accountStatus'],
    include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
    transaction,
  });
}

async function ensureDirectConversation(firstUserId, secondUserId, options = {}) {
  const userIds = [Number(firstUserId), Number(secondUserId)].sort((a, b) => a - b);
  if (!userIds[0] || userIds[0] === userIds[1]) {
    throw new Error('A direct conversation requires two different users.');
  }
  const { Conversation, ConversationParticipant } = getModels();
  const pairKey = pairKeyFor(userIds[0], userIds[1]);
  const [conversation, created] = await Conversation.findOrCreate({
    where: { pairKey },
    defaults: { pairKey, type: 'direct' },
    transaction: options.transaction,
  });
  await ConversationParticipant.bulkCreate([
    { conversationId: conversation.id, userId: userIds[0], joinedAt: new Date() },
    { conversationId: conversation.id, userId: userIds[1], joinedAt: new Date() },
  ], { ignoreDuplicates: true, transaction: options.transaction });
  const participants = await ConversationParticipant.findAll({
    where: { conversationId: conversation.id },
    attributes: ['userId'],
    transaction: options.transaction,
  });
  const participantIds = participants.map((item) => Number(item.userId)).sort((a, b) => a - b);
  if (participantIds.length !== 2 || participantIds[0] !== userIds[0] || participantIds[1] !== userIds[1]) {
    throw new Error('The direct conversation participant mapping is invalid.');
  }
  return { conversation, created };
}

module.exports = {
  pairKeyFor,
  activeMatch,
  conversationAccess,
  eligibleTarget,
  ensureDirectConversation,
};
