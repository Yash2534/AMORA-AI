const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const { pairKeyFor } = require('../src/services/conversationAccessService');
const { QA_USERS, preferenceValues, profileValues } = require('./manual-qa-users-fixture');

const pairDirections = (firstId, secondId, firstKey, secondKey) => ({
  [Op.or]: [
    { [firstKey]: firstId, [secondKey]: secondId },
    { [firstKey]: secondId, [secondKey]: firstId },
  ],
});

async function upsertQaUser(models, definition, password, photos, now, transaction) {
  const passwordHash = await bcrypt.hash(password, 12);
  const userValues = {
    name: definition.name,
    email: definition.email,
    phoneNumber: definition.phoneNumber,
    passwordHash,
    authProvider: 'local',
    googleId: null,
    isVerified: true,
    termsAcceptedAt: now,
    accountStatus: 'active',
    deactivatedAt: null,
    deletedAt: null,
    deletionReason: null,
    deletionDetails: null,
    lastActiveAt: now,
  };
  let user = await models.User.findOne({
    where: { email: definition.email },
    transaction,
  });
  if (user) await user.update(userValues, { transaction });
  else user = await models.User.create(userValues, { transaction });

  const profile = profileValues(definition, photos, now);
  await models.OnboardingProfile.upsert(
    { userId: user.id, ...profile },
    { transaction },
  );
  await models.DiscoverFilterPreference.upsert(
    preferenceValues(user.id),
    { transaction },
  );
  return user;
}

async function findQaUsers(models, transaction) {
  const rows = await models.User.findAll({
    where: { email: Object.values(QA_USERS).map((user) => user.email) },
    transaction,
  });
  const byEmail = new Map(rows.map((row) => [row.email.toLowerCase(), row]));
  return {
    krupa: byEmail.get(QA_USERS.krupa.email),
    yashu: byEmail.get(QA_USERS.yashu.email),
  };
}

async function resetQaRelations(models, users, transaction) {
  if (!users.krupa || !users.yashu) {
    throw new Error('Both manual QA users must exist before relations can be reset.');
  }
  const firstId = Number(users.krupa.id);
  const secondId = Number(users.yashu.id);
  const directPair = pairDirections(firstId, secondId, 'actorUserId', 'targetUserId');
  const conversation = await models.Conversation.findOne({
    where: { pairKey: pairKeyFor(firstId, secondId), type: 'direct' },
    transaction,
  });

  if (conversation) {
    const participantUserIds = (await models.ConversationParticipant.findAll({
      where: { conversationId: conversation.id },
      attributes: ['userId'],
      transaction,
    })).map((row) => Number(row.userId));
    if (participantUserIds.some((id) => ![firstId, secondId].includes(id))) {
      throw new Error('Refusing to reset a conversation containing an unrelated user.');
    }
    const messageIds = (await models.Message.findAll({
      where: { conversationId: conversation.id },
      attributes: ['id'],
      transaction,
    })).map((row) => row.id);
    await conversation.update({ lastMessageId: null, lastMessageAt: null }, { transaction });
    await models.ConversationParticipant.update(
      { lastReadMessageId: null },
      { where: { conversationId: conversation.id }, transaction },
    );
    if (messageIds.length) {
      await models.MessageMedia.destroy({ where: { messageId: messageIds }, transaction });
      await models.Message.destroy({ where: { id: messageIds }, transaction });
    }
    await models.RoseTransaction.update(
      { conversationId: null },
      { where: { conversationId: conversation.id }, transaction },
    );
    await models.ConversationParticipant.destroy({
      where: { conversationId: conversation.id }, transaction,
    });
    await conversation.destroy({ transaction });
  }

  const reports = await models.Report.findAll({
    where: pairDirections(firstId, secondId, 'reporterUserId', 'reportedUserId'),
    attributes: ['id'],
    transaction,
  });
  const reportIds = reports.map((row) => row.id);
  if (reportIds.length) {
    await models.AdminReportNote.destroy({ where: { reportId: reportIds }, transaction });
    await models.AdminReportCase.destroy({ where: { reportId: reportIds }, transaction });
    await models.Report.destroy({ where: { id: reportIds }, transaction });
  }

  await Promise.all([
    models.DiscoverAction.destroy({ where: directPair, transaction }),
    models.Block.destroy({
      where: pairDirections(firstId, secondId, 'blockerUserId', 'blockedUserId'), transaction,
    }),
    models.SavedProfile.destroy({
      where: pairDirections(firstId, secondId, 'userId', 'savedUserId'), transaction,
    }),
    models.RoseTransaction.destroy({
      where: pairDirections(firstId, secondId, 'senderId', 'recipientId'), transaction,
    }),
    models.Match.destroy({
      where: {
        userOneId: Math.min(firstId, secondId),
        userTwoId: Math.max(firstId, secondId),
      },
      transaction,
    }),
    models.MatchingActionFailure.destroy({ where: directPair, transaction }),
    models.MatchRecommendationEvent.destroy({
      where: pairDirections(firstId, secondId, 'viewerUserId', 'candidateUserId'), transaction,
    }),
  ]);
  return { conversationRemoved: Boolean(conversation) };
}

async function seedQaUsers(models, config, mediaByUser, transaction, now = new Date()) {
  const users = {};
  for (const key of ['krupa', 'yashu']) {
    users[key] = await upsertQaUser(
      models,
      QA_USERS[key],
      config.passwords[key],
      mediaByUser[key],
      now,
      transaction,
    );
  }
  await resetQaRelations(models, users, transaction);
  return users;
}

module.exports = { findQaUsers, resetQaRelations, seedQaUsers };
