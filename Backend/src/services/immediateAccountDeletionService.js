const { Op } = require('sequelize');
const { getModels } = require('../models');

const DELETION_MECHANISM = 'USER_INITIATED_OTP';

class ImmediateAccountDeletionService {
  constructor({ models = getModels } = {}) {
    this.models = models;
  }

  async execute({ user, transaction }) {
    const models = this.models();
    const userId = Number(user.id);
    const deletedAt = new Date();
    const profile = await models.OnboardingProfile.findOne({
      where: { userId }, attributes: ['photos'], transaction,
    });
    const identity = await models.IdentityVerification.findOne({
      where: { userId },
      attributes: ['aadhaarStoragePath', 'selfieStoragePath'],
      transaction,
    });
    const storageCleanup = {
      profilePhotos: [...(profile?.photos || [])],
      identityFiles: [identity?.aadhaarStoragePath, identity?.selfieStoragePath].filter(Boolean),
      chatMedia: [],
    };
    const existingArchive = await models.DeletedUser.findOne({
      where: { originalUserId: userId }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if (existingArchive || user.accountStatus === 'deleted') {
      return { alreadyDeleted: true, archive: existingArchive };
    }

    const archive = await models.DeletedUser.create({
      originalUserId: userId,
      deletionMechanism: DELETION_MECHANISM,
      accountCreatedAt: user.createdAt,
      deletedAt,
    }, { transaction });

    const messages = await models.Message.findAll({
      where: { senderId: userId }, attributes: ['id'], transaction,
      lock: transaction.LOCK.UPDATE,
    });
    const messageIds = messages.map((message) => message.id);
    if (messageIds.length) {
      const media = await models.MessageMedia.findAll({
        where: { messageId: messageIds }, attributes: ['storagePath'], transaction,
      });
      storageCleanup.chatMedia = media.map((item) => item.storagePath);
      await models.MessageMedia.destroy({ where: { messageId: messageIds }, transaction });
      await models.Message.update({
        text: null, context: null, roseTransactionId: null, deletedAt,
      }, { where: { id: messageIds }, transaction });
    }

    await models.RefreshToken.destroy({ where: { userId }, transaction });
    await models.UserDevice.destroy({ where: { userId }, transaction });
    await models.AccountDeletionConfirmation.destroy({ where: { userId }, transaction });
    await models.PrivacyRequestConfirmation.destroy({ where: { userId }, transaction });
    await models.OtpToken.destroy({
      where: { [Op.or]: [{ userId }, { email: user.email }, { phoneNumber: user.phoneNumber }] },
      transaction,
    });

    await models.OnboardingProfile.destroy({ where: { userId }, transaction });
    await models.DiscoverFilterPreference.destroy({ where: { userId }, transaction });
    await models.NotificationPreference.destroy({ where: { userId }, transaction });
    await models.IdentityVerification.destroy({ where: { userId }, transaction });
    await models.PrivacyExportArtifact.destroy({ where: { userId }, transaction });
    await models.DiscoverAction.destroy({
      where: { [Op.or]: [{ actorUserId: userId }, { targetUserId: userId }] }, transaction,
    });
    await models.SavedProfile.destroy({
      where: { [Op.or]: [{ userId }, { savedUserId: userId }] }, transaction,
    });
    await models.Match.destroy({
      where: { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] }, transaction,
    });
    await models.Block.destroy({
      where: { [Op.or]: [{ blockerUserId: userId }, { blockedUserId: userId }] }, transaction,
    });
    await models.ConversationParticipant.destroy({ where: { userId }, transaction });
    await models.EventRegistration.destroy({ where: { userId }, transaction });
    await models.EventWaitlist.destroy({ where: { userId }, transaction });
    const roseTransactions = await models.RoseTransaction.findAll({
      where: { [Op.or]: [{ senderId: userId }, { recipientId: userId }] },
      attributes: ['id'], transaction, lock: transaction.LOCK.UPDATE,
    });
    const roseTransactionIds = roseTransactions.map((rose) => rose.id);
    if (roseTransactionIds.length) {
      await models.Message.update(
        { roseTransactionId: null },
        { where: { roseTransactionId: roseTransactionIds }, transaction },
      );
      await models.RoseTransaction.destroy({
        where: { id: roseTransactionIds }, transaction,
      });
    }
    await models.MatchRecommendationEvent.destroy({
      where: { [Op.or]: [{ viewerUserId: userId }, { candidateUserId: userId }] }, transaction,
    });
    await models.Notification.destroy({ where: { userId }, transaction });
    await models.Notification.update(
      { actorUserId: null }, { where: { actorUserId: userId }, transaction },
    );
    await models.MatchingActionFailure.update(
      { actorUserId: null }, { where: { actorUserId: userId }, transaction },
    );
    await models.MatchingActionFailure.update(
      { targetUserId: null }, { where: { targetUserId: userId }, transaction },
    );

    const anonymizedIdentity = `deleted-${userId}-${deletedAt.getTime()}`;
    Object.assign(user, {
      accountStatus: 'deleted', deletedAt, deactivatedAt: null,
      tokenVersion: Number(user.tokenVersion || 0) + 1,
      deletionReason: null, deletionDetails: null, name: 'Deleted Member',
      email: `${anonymizedIdentity}@deleted.amora.invalid`,
      phoneNumber: anonymizedIdentity, passwordHash: null, googleId: null,
      isVerified: false, lastActiveAt: null, identityVerifiedAt: null,
    });
    await user.save({ transaction });
    return { completed: true, archive, storageCleanup };
  }
}

module.exports = new ImmediateAccountDeletionService();
module.exports.ImmediateAccountDeletionService = ImmediateAccountDeletionService;
module.exports.DELETION_MECHANISM = DELETION_MECHANISM;
