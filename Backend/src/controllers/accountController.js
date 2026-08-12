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
    const { User, OtpToken, RefreshToken, Match } = getModels();
    const userId = Number(req.user.sub);
    await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user || user.accountStatus === 'deleted') return;
      const previousEmail = user.email;
      const previousPhoneNumber = user.phoneNumber;
      const deletedIdentity = `deleted-${user.id}-${Date.now()}`;
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
      await RefreshToken.destroy({ where: { userId }, transaction });
      await OtpToken.destroy({
        where: { [Op.or]: [{ email: previousEmail }, { phoneNumber: previousPhoneNumber }] },
        transaction,
      });
      await Match.destroy({ where: { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] }, transaction });
    });
    return res.json({ success: true, message: 'Account deleted.', data: {} });
  } catch (error) {
    return next(error);
  }
};
