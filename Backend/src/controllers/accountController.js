const { Op } = require('sequelize');
const { getModels } = require('../models');

const ownProfile = (user) => ({ id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, isVerified: user.isVerified, accountStatus: user.accountStatus });

exports.deactivate = async (req, res, next) => {
  try {
    const { User, RefreshToken } = getModels();
    const userId = Number(req.user.sub);
    const user = await User.sequelize.transaction(async (transaction) => {
      const current = await User.findByPk(userId, {
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!current) return null;
      if (current.accountStatus === 'active') {
        current.accountStatus = 'deactivated';
        current.deactivatedAt = new Date();
        current.tokenVersion += 1;
        await current.save({ transaction });
      }
      await RefreshToken.destroy({ where: { userId }, transaction });
      return current;
    });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.', code: 'NOT_FOUND', errors: [] });
    }
    return res.json({ success: true, message: 'Account deactivated.', data: { user: ownProfile(user) } });
  } catch (error) {
    return next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const {
      User, OtpToken, RefreshToken, Match, OnboardingProfile, IdentityVerification,
      UserDevice, SavedProfile, DiscoverAction, DiscoverFilterPreference, Notification,
      NotificationPreference, UserConsent
    } = getModels();
    const userId = Number(req.user.sub || req.user.id);
    await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user || user.accountStatus === 'deleted') return;

      const previousEmail = user.email;
      const previousPhoneNumber = user.phoneNumber;
      const deletedIdentity = `deleted-${user.id}-${Date.now()}`;

      // 1. Anonymize User Core Record
      user.accountStatus = 'deleted';
      user.deletedAt = new Date();
      user.deactivatedAt = null;
      user.tokenVersion += 1;
      user.deletionReason = req.body.reason;
      user.deletionDetails = req.body.details || null;
      user.name = 'Deleted Member';
      user.email = `${deletedIdentity}@deleted.amora.invalid`;
      user.phoneNumber = deletedIdentity;
      user.passwordHash = null;
      user.googleId = null;
      user.isVerified = false;
      await user.save({ transaction });

      // 2. DPDP Section 12 Cascade Purge of Personal Data & Verification Assets
      await RefreshToken.destroy({ where: { userId }, transaction });
      await OtpToken.destroy({
        where: { [Op.or]: [{ email: previousEmail }, { phoneNumber: previousPhoneNumber }] },
        transaction,
      });
      await Match.destroy({ where: { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] }, transaction });
      
      // Purge Onboarding Profile (bio, photos, DOB, location)
      if (OnboardingProfile) {
        await OnboardingProfile.destroy({ where: { userId }, transaction });
      }
      
      // Purge Identity Verification (selfies, Aadhaar tokens, ID docs)
      if (IdentityVerification) {
        await IdentityVerification.destroy({ where: { userId }, transaction });
      }

      // Purge Device Tokens
      if (UserDevice) {
        await UserDevice.destroy({ where: { userId }, transaction });
      }

      // Purge Saved Profiles & Preferences
      if (SavedProfile) {
        await SavedProfile.destroy({ where: { [Op.or]: [{ userId }, { savedUserId: userId }] }, transaction });
      }
      if (DiscoverAction) {
        await DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: userId }, { targetUserId: userId }] }, transaction });
      }
      if (DiscoverFilterPreference) {
        await DiscoverFilterPreference.destroy({ where: { userId }, transaction });
      }
      if (Notification) {
        await Notification.destroy({ where: { [Op.or]: [{ userId }, { actorUserId: userId }] }, transaction });
      }
      if (NotificationPreference) {
        await NotificationPreference.destroy({ where: { userId }, transaction });
      }
      if (UserConsent) {
        await UserConsent.destroy({ where: { userId }, transaction });
      }
    });
    return res.json({
      success: true,
      message: 'Account and associated personal data erased in compliance with DPDP Act 2023 Section 12.',
      data: {}
    });
  } catch (error) {
    return next(error);
  }
};
