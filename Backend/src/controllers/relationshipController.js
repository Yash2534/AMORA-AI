const { Op } = require('sequelize');
const { getModels } = require('../models');
const { activeAccountWhere, areUsersBlocked, notBlockedUserSql } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');

const fail = (res, status, message, code) => res.status(status).json({ success: false, message, code, errors: [] });
const pagination = (req) => ({ page: Number(req.query.page || 1), limit: Number(req.query.limit || 20) });

async function visibleTarget(userId, targetUserId, transaction) {
  const { User, OnboardingProfile, Subscription } = getModels();
  const target = await User.findOne({
    where: activeAccountWhere({ id: targetUserId }),
    include: [
      { model: OnboardingProfile, required: true, where: { onboardingCompleted: true } },
      { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] },
    ],
    transaction,
  });
  if (!target || await areUsersBlocked(userId, targetUserId, { transaction })) return null;
  return target;
}

async function viewerProfile(userId) {
  return getModels().OnboardingProfile.findOne({ where: { userId } });
}

exports.listSaved = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { page, limit } = pagination(req);
    const { SavedProfile, User, OnboardingProfile, Subscription } = getModels();
    const rows = await SavedProfile.findAll({
      where: { userId },
      include: [{
        model: User,
        as: 'savedUser',
        required: true,
        where: { ...activeAccountWhere(), [Op.and]: [notBlockedUserSql(SavedProfile.sequelize, userId, 'savedUser')] },
        include: [
          { model: OnboardingProfile, required: true, where: { onboardingCompleted: true } },
          { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] },
        ],
      }],
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
      offset: (page - 1) * limit,
      limit: limit + 1,
      subQuery: false,
    });
    const hasMore = rows.length > limit;
    const selected = hasMore ? rows.slice(0, limit) : rows;
    const viewer = await viewerProfile(userId);
    return res.json({
      success: true,
      message: selected.length ? 'Saved profiles retrieved.' : 'No saved profiles found.',
      data: {
        profiles: selected.map((row) => serializePublicProfile(req, row.savedUser, row.savedUser.OnboardingProfile, {
          viewer,
          relationship: { saved: true, liked: false, superLiked: false, blocked: false, matched: false, matchId: null },
        })),
        pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
      },
    });
  } catch (error) { return next(error); }
};

exports.save = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const targetUserId = Number(req.params.userId);
    if (targetUserId === userId) return fail(res, 400, 'You cannot save your own profile.', 'INVALID_TARGET');
    const { SavedProfile } = getModels();
    let target;
    let created = false;
    await SavedProfile.sequelize.transaction(async (transaction) => {
      target = await visibleTarget(userId, targetUserId, transaction);
      if (!target) return;
      [, created] = await SavedProfile.findOrCreate({
        where: { userId, savedUserId: targetUserId },
        defaults: { userId, savedUserId: targetUserId },
        transaction,
      });
    });
    if (!target) return fail(res, 404, 'Profile is not available.', 'PROFILE_NOT_AVAILABLE');
    const viewer = await viewerProfile(userId);
    return res.status(created ? 201 : 200).json({
      success: true,
      message: created ? 'Profile saved.' : 'Profile was already saved.',
      data: { userId: String(targetUserId), saved: true, profile: serializePublicProfile(req, target, target.OnboardingProfile, { viewer, relationship: { saved: true } }) },
    });
  } catch (error) { return next(error); }
};

exports.unsave = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const savedUserId = Number(req.params.userId);
    const removed = await getModels().SavedProfile.destroy({ where: { userId, savedUserId } });
    return res.json({ success: true, message: removed ? 'Profile removed from saved profiles.' : 'Profile was already unsaved.', data: { userId: String(savedUserId), saved: false } });
  } catch (error) { return next(error); }
};

async function listReactions(req, res, next, action) {
  try {
    const userId = Number(req.user.sub);
    const { page, limit } = pagination(req);
    const { DiscoverAction, User, OnboardingProfile, Subscription } = getModels();
    const rows = await DiscoverAction.findAll({
      where: { actorUserId: userId, action },
      include: [{
        model: User,
        as: 'target',
        required: true,
        where: { ...activeAccountWhere(), [Op.and]: [notBlockedUserSql(DiscoverAction.sequelize, userId, 'target')] },
        include: [
          { model: OnboardingProfile, required: true, where: { onboardingCompleted: true } },
          { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] },
        ],
      }],
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
      offset: (page - 1) * limit,
      limit: limit + 1,
      subQuery: false,
    });
    const hasMore = rows.length > limit;
    const selected = hasMore ? rows.slice(0, limit) : rows;
    const viewer = await viewerProfile(userId);
    return res.json({
      success: true,
      message: selected.length ? 'Reactions retrieved.' : 'No reactions found.',
      data: {
        profiles: selected.map((row) => serializePublicProfile(req, row.target, row.target.OnboardingProfile, {
          viewer,
          relationship: { liked: true, superLiked: action === 'superLike', saved: false, blocked: false, matched: false, matchId: null },
        })),
        pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
      },
    });
  } catch (error) { return next(error); }
}

exports.listReactions = (req, res, next) => listReactions(req, res, next, req.query.type);
exports.listLikes = (req, res, next) => listReactions(req, res, next, 'like');
exports.listSuperLikes = (req, res, next) => listReactions(req, res, next, 'superLike');

exports.listReceivedLikes = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { page, limit } = pagination(req);
    const { DiscoverAction, User, OnboardingProfile, Subscription } = getModels();
    const rows = await DiscoverAction.findAll({
      where: {
        targetUserId: userId,
        action: { [Op.in]: ['like', 'superLike'] },
      },
      include: [{
        model: User,
        as: 'actor',
        required: true,
        where: {
          ...activeAccountWhere(),
          [Op.and]: [notBlockedUserSql(DiscoverAction.sequelize, userId, 'actor')],
        },
        include: [
          { model: OnboardingProfile, required: true, where: { onboardingCompleted: true } },
          { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] },
        ],
      }],
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
      offset: (page - 1) * limit,
      limit: limit + 1,
      subQuery: false,
    });
    const hasMore = rows.length > limit;
    const selected = hasMore ? rows.slice(0, limit) : rows;
    const viewer = await viewerProfile(userId);
    const total = await DiscoverAction.count({
      where: {
        targetUserId: userId,
        action: { [Op.in]: ['like', 'superLike'] },
      },
      include: [{
        model: User,
        as: 'actor',
        required: true,
        where: {
          ...activeAccountWhere(),
          [Op.and]: [notBlockedUserSql(DiscoverAction.sequelize, userId, 'actor')],
        },
        include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
      }],
      distinct: true,
    });
    return res.json({
      success: true,
      message: selected.length ? 'Received likes retrieved.' : 'No received likes found.',
      data: {
        profiles: selected.map((row) => serializePublicProfile(req, row.actor, row.actor.OnboardingProfile, {
          viewer,
          relationship: { receivedLike: true, receivedSuperLike: row.action === 'superLike' },
        })),
        total,
        pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
      },
    });
  } catch (error) { return next(error); }
};

exports.removeReaction = async (req, res, next) => {
  try {
    const actorUserId = Number(req.user.sub);
    const targetUserId = Number(req.params.userId);
    const removed = await getModels().DiscoverAction.destroy({
      where: { actorUserId, targetUserId, action: { [Op.in]: ['like', 'superLike'] } },
    });
    return res.json({ success: true, message: removed ? 'Reaction removed.' : 'Reaction was already unavailable.', data: { userId: String(targetUserId), liked: false, superLiked: false } });
  } catch (error) { return next(error); }
};
