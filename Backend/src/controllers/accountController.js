const crypto = require('crypto');
const { getModels } = require('../models');
const accountDeletionService = require('../services/accountDeletionService');

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
    const { User, AccountDeletionConfirmation, AccountDeletionRequest } = getModels();
    const userId = Number(req.user.sub);
    const confirmation = String(req.body.deletionConfirmation || '');
    const [tokenSelector] = confirmation.split('.', 1);
    const tokenHash = crypto.createHash('sha256').update(confirmation).digest('hex');
    const deletionRequest = await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      const stored = await AccountDeletionConfirmation.findOne({
        where: { userId, tokenSelector, purpose: 'account_deletion', consumedAt: null },
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!user || user.accountStatus === 'deleted' || !stored || stored.expiresAt <= new Date()
        || !crypto.timingSafeEqual(Buffer.from(stored.tokenHash, 'hex'), Buffer.from(tokenHash, 'hex'))) {
        const error = new Error('Account deletion requires re-authentication.');
        error.status = 401;
        error.code = 'REAUTHENTICATION_REQUIRED';
        throw error;
      }
      stored.consumedAt = new Date();
      await stored.save({ transaction });
      return AccountDeletionRequest.create({
        userId,
        status: 'VERIFIED',
        requestedAt: new Date(),
        verifiedAt: new Date(),
      }, { transaction });
    });
    const result = await accountDeletionService.execute({
      userId,
      deletionRequestId: deletionRequest.id,
      correlationId: deletionRequest.correlationId,
      deletionReason: req.body.reason,
      deletionDetails: req.body.details,
    });
    return res.status(202).json({
      success: true,
      message: result.status === 'BLOCKED_BY_RETENTION_DECISION'
        ? 'Account deletion is pending retention review.'
        : 'Account deletion request processed.',
      data: { deletionStatus: result.status, canRetry: result.status === 'FAILED' },
    });
  } catch (error) {
    return next(error);
  }
};
