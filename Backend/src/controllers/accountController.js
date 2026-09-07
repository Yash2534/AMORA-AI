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
    const token = String(req.body.deletionConfirmation || '');
    const [selector] = token.split('.', 1);
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    const deletionRequest = await User.sequelize.transaction(async (transaction) => {
      const confirmation = await AccountDeletionConfirmation.findOne({ where: { userId, tokenSelector: selector, purpose: 'account_deletion', consumedAt: null }, transaction, lock: transaction.LOCK.UPDATE });
      if (!confirmation || confirmation.expiresAt <= new Date() || !crypto.timingSafeEqual(Buffer.from(confirmation.tokenHash, 'hex'), Buffer.from(tokenHash, 'hex'))) return null;
      confirmation.consumedAt = new Date();
      await confirmation.save({ transaction });
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user || user.accountStatus === 'deleted') return null;
      return AccountDeletionRequest.create({
        userId,
        status: 'VERIFIED',
        requestedAt: new Date(),
        verifiedAt: new Date(),
      }, { transaction });
    });
    if (!deletionRequest) return res.status(401).json({ success: false, message: 'This deletion confirmation is no longer valid. Please authenticate again.', code: 'DELETION_CONFIRMATION_INVALID', errors: [] });
    const result = await accountDeletionService.execute({
      userId,
      deletionRequestId: deletionRequest.id,
      correlationId: deletionRequest.correlationId,
      deletionReason: req.body.reason,
      deletionDetails: req.body.details,
    });
    if (result.notVerified || result.invalid) {
      return res.status(409).json({ success: false, message: 'Account deletion cannot be processed in its current state.', code: 'DELETION_REQUEST_NOT_EXECUTABLE', errors: [] });
    }
    if (result.blocked) {
      return res.status(202).json({
        success: true,
        message: 'Account deletion request requires additional review.',
        data: {
          deletionRequestId: deletionRequest.id,
          deletionStatus: result.status,
          canRetry: false,
        },
      });
    }
    if (result.alreadyProcessing) {
      return res.status(202).json({ success: true, message: 'Account deletion is already being processed.', data: { deletionRequestId: deletionRequest.id, deletionStatus: result.status, canRetry: false } });
    }
    if (result.status === 'FAILED') return res.status(500).json({ success: false, message: 'Account deletion could not be completed. Please contact support.', code: result.failureCode, errors: [] });
    return res.json({ success: true, message: result.alreadyCompleted ? 'Account deletion was already completed.' : 'Account deleted.', data: { deletionRequestId: deletionRequest.id, deletionStatus: result.status, canRetry: false } });
  } catch (error) {
    return next(error);
  }
};
