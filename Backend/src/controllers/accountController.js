const { Op } = require('sequelize');
const { getModels } = require('../models');

const ownProfile = (user) => ({ id: user.id, name: user.name, email: user.email, phoneNumber: user.phoneNumber, isVerified: user.isVerified, accountStatus: user.accountStatus });

exports.deactivate = async (req, res, next) => {
  try {
    const user = req.authUser;
    if (user.accountStatus === 'active') {
      user.accountStatus = 'deactivated';
      user.deactivatedAt = new Date();
      await user.save();
    }
    return res.json({ success: true, message: 'Account deactivated.', data: { user: ownProfile(user) } });
  } catch (error) {
    return next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const { User, RefreshToken, Match } = getModels();
    const userId = Number(req.user.sub);
    await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user || user.accountStatus === 'deleted') return;
      user.accountStatus = 'deleted';
      user.deletedAt = new Date();
      user.deactivatedAt = null;
      user.tokenVersion += 1;
      user.deletionReason = req.body.reason;
      user.deletionDetails = req.body.details || null;
      await user.save({ transaction });
      await RefreshToken.destroy({ where: { userId }, transaction });
      await Match.destroy({ where: { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] }, transaction });
    });
    return res.json({ success: true, message: 'Account deleted.', data: {} });
  } catch (error) {
    return next(error);
  }
};
