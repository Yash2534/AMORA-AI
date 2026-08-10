const { Op } = require('sequelize');
const { getModels } = require('../models');
const { activeAccountWhere, areUsersBlocked, matchPairWhere } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');

const unavailable = (res) => res.status(404).json({ success: false, message: 'Profile is not available.', code: 'PROFILE_NOT_AVAILABLE', errors: [] });

exports.getPublicProfile = async (req, res, next) => {
  try {
    const viewerUserId = Number(req.user.sub);
    const targetUserId = Number(req.params.userId);
    const { User, OnboardingProfile, DiscoverAction, Match, Subscription } = getModels();
    const target = await User.findOne({
      where: activeAccountWhere({ id: targetUserId }),
      include: [
        { model: OnboardingProfile, required: true, where: { onboardingCompleted: true } },
        { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] },
      ],
    });
    if (!target || await areUsersBlocked(viewerUserId, targetUserId)) return unavailable(res);

    const [action, match, viewer] = await Promise.all([
      DiscoverAction.findOne({ where: { actorUserId: viewerUserId, targetUserId }, attributes: ['action'] }),
      Match.findOne({ where: matchPairWhere(viewerUserId, targetUserId), attributes: ['id'] }),
      OnboardingProfile.findOne({ where: { userId: viewerUserId } }),
    ]);
    const relationship = {
      liked: ['like', 'superLike'].includes(action?.action),
      superLiked: action?.action === 'superLike',
      blocked: false,
      matched: Boolean(match),
      matchId: match ? String(match.id) : null,
    };
    return res.json({
      success: true,
      message: 'Public profile retrieved.',
      data: { profile: serializePublicProfile(req, target, target.OnboardingProfile, { viewer, relationship }) },
    });
  } catch (error) {
    return next(error);
  }
};
