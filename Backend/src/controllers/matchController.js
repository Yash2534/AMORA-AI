const { Op } = require('sequelize');
const { getModels } = require('../models');
const { activeAccountWhere, visibleMatchSql } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');

function matchIncludes(User, OnboardingProfile) {
  const userInclude = (as) => ({
    model: User,
    as,
    required: true,
    where: activeAccountWhere(),
    attributes: ['id', 'name', 'isVerified'],
    include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
  });
  return [userInclude('userOne'), userInclude('userTwo')];
}

function serializeMatch(req, row, viewerUserId, viewerProfile) {
  const other = Number(row.userOneId) === viewerUserId ? row.userTwo : row.userOne;
  return {
    id: String(row.id),
    matchedAt: row.matchedAt,
    profile: serializePublicProfile(req, other, other.OnboardingProfile, {
      viewer: viewerProfile,
      relationship: { liked: true, superLiked: false, blocked: false, matched: true, matchId: String(row.id) },
    }),
  };
}

exports.list = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { Match, User, OnboardingProfile } = getModels();
    const rows = await Match.findAll({
      where: {
        [Op.and]: [
          { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] },
          visibleMatchSql(Match.sequelize, userId),
        ],
      },
      include: matchIncludes(User, OnboardingProfile),
      order: [['matchedAt', 'DESC'], ['id', 'DESC']],
      subQuery: false,
    });
    const viewerProfile = await OnboardingProfile.findOne({ where: { userId } });
    return res.json({ success: true, message: rows.length ? 'Matches retrieved.' : 'No matches found.', data: { matches: rows.map((row) => serializeMatch(req, row, userId, viewerProfile)) } });
  } catch (error) {
    return next(error);
  }
};

exports.detail = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { Match, User, OnboardingProfile } = getModels();
    const row = await Match.findOne({
      where: {
        id: req.params.matchId,
        [Op.and]: [
          { [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] },
          visibleMatchSql(Match.sequelize, userId),
        ],
      },
      include: matchIncludes(User, OnboardingProfile),
      subQuery: false,
    });
    if (!row) return res.status(404).json({ success: false, message: 'Match is not available.', code: 'MATCH_NOT_AVAILABLE', errors: [] });
    const viewerProfile = await OnboardingProfile.findOne({ where: { userId } });
    return res.json({ success: true, message: 'Match retrieved.', data: { match: serializeMatch(req, row, userId, viewerProfile) } });
  } catch (error) {
    return next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const userId = Number(req.user.sub);
    const { Match } = getModels();
    const existing = await Match.findByPk(req.params.matchId, { attributes: ['id', 'userOneId', 'userTwoId'] });
    if (existing && ![Number(existing.userOneId), Number(existing.userTwoId)].includes(userId)) {
      return res.status(404).json({ success: false, message: 'Match is not available.', code: 'MATCH_NOT_AVAILABLE', errors: [] });
    }
    const removed = await Match.destroy({
      where: { id: req.params.matchId, [Op.or]: [{ userOneId: userId }, { userTwoId: userId }] },
    });
    return res.json({ success: true, message: removed ? 'Match removed.' : 'Match was already unavailable.', data: { matchId: String(req.params.matchId), matched: false, removed: removed > 0 } });
  } catch (error) {
    return next(error);
  }
};
