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

module.exports = { pairKeyFor, activeMatch, conversationAccess, eligibleTarget };
