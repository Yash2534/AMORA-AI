const { Op } = require('sequelize');
const { getModels } = require('../models');
const { activeAccountWhere } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');

exports.list = async (req, res, next) => {
  try {
    const { Block, User, OnboardingProfile } = getModels();
    const rows = await Block.findAll({
      where: { blockerUserId: req.user.sub },
      include: [{
        model: User,
        as: 'blockedUser',
        required: true,
        where: { accountStatus: { [Op.ne]: 'deleted' } },
        attributes: ['id', 'name', 'identityVerifiedAt'],
        include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
      }],
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
    });
    return res.json({
      success: true,
      message: rows.length ? 'Blocked profiles retrieved.' : 'No blocked profiles found.',
      data: { blocks: rows.map((row) => ({ id: String(row.id), blockedAt: row.createdAt, profile: serializePublicProfile(req, row.blockedUser, row.blockedUser.OnboardingProfile) })) },
    });
  } catch (error) {
    return next(error);
  }
};

exports.create = async (req, res, next) => {
  try {
    const blockerUserId = Number(req.user.sub);
    const blockedUserId = Number(req.params.userId);
    if (blockerUserId === blockedUserId) {
      return res.status(400).json({ success: false, message: 'You cannot block your own account.', code: 'SELF_BLOCK_NOT_ALLOWED', errors: [] });
    }
    const { User, Block } = getModels();
    const target = await User.findOne({ where: activeAccountWhere({ id: blockedUserId }), attributes: ['id'] });
    if (!target) return res.status(404).json({ success: false, message: 'Profile is not available.', code: 'PROFILE_NOT_AVAILABLE', errors: [] });

    let block;
    let created;
    await User.sequelize.transaction(async (transaction) => {
      [block, created] = await Block.findOrCreate({
        where: { blockerUserId, blockedUserId },
        defaults: { blockerUserId, blockedUserId },
        transaction,
      });
    });
    return res.json({
      success: true,
      message: created ? 'Profile blocked.' : 'Profile is already blocked.',
      data: { blockId: String(block.id), userId: String(blockedUserId), blocked: true, created, unmatched: false },
    });
  } catch (error) {
    return next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const { Block, Conversation, Match } = getModels();
    const blockerUserId = Number(req.user.sub);
    const blockedUserId = Number(req.params.userId);
    let removed = 0;
    let restoredMatch = false;
    await Block.sequelize.transaction(async (transaction) => {
      removed = await Block.destroy({ where: { blockerUserId, blockedUserId }, transaction });
      if (!removed) return;
      const userOneId = Math.min(blockerUserId, blockedUserId);
      const userTwoId = Math.max(blockerUserId, blockedUserId);
      const conversation = await Conversation.findOne({
        where: { pairKey: `${userOneId}:${userTwoId}`, type: 'direct' },
        attributes: ['id', 'createdAt'],
        transaction,
      });
      if (!conversation) return;
      const [, created] = await Match.findOrCreate({
        where: { userOneId, userTwoId },
        defaults: { userOneId, userTwoId, matchedAt: conversation.createdAt || new Date() },
        transaction,
      });
      restoredMatch = created;
    });
    return res.json({
      success: true,
      message: removed ? 'Profile unblocked.' : 'Profile was not blocked.',
      data: { userId: String(blockedUserId), blocked: false, removed: removed > 0, restoredMatch },
    });
  } catch (error) {
    return next(error);
  }
};
