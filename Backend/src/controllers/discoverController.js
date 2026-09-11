const { Op, fn, col, where, cast, literal } = require('sequelize');
const { getModels } = require('../models');
const { SCORE_WEIGHTS } = require('../services/matchEngineService');
const { areUsersBlocked, notBlockedUserSql } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');
const { defaults, filtersFor, updateFilters: persistFilters } = require('../services/discoverPreferenceService');
const { createNotification } = require('../services/notificationService');
const { ensureDirectConversation } = require('../services/conversationAccessService');
const { emitConversationEvent } = require('../realtime/realtimeHub');
const { rankCandidates } = require('../services/aiMatchProvider');

const success = (res, message, data) => res.json({ success: true, message, data });
const fail = (res, status, message, code, errors = []) => res.status(status).json({ success: false, message, code, errors });
const list = (value) => (Array.isArray(value) ? value : []);
const lower = (value) => String(value || '').trim().toLowerCase();
const normalizedList = (value) => [...new Set(list(value).map(lower).filter(Boolean))];


function yearsAgoDate(years) {
  const now = new Date();
  const date = new Date(Date.UTC(now.getUTCFullYear() - years, now.getUTCMonth(), now.getUTCDate()));
  return date.toISOString().slice(0, 10);
}

async function profileFor(userId) {
  const { OnboardingProfile } = getModels();
  return OnboardingProfile.findOne({ where: { userId } });
}

async function requireCompleted(res, userId) {
  const profile = await profileFor(userId);
  if (!profile || !profile.onboardingCompleted) {
    fail(res, 403, 'Complete onboarding before using Discover.', 'ONBOARDING_REQUIRED');
    return null;
  }
  return profile;
}

function profileData(req, user, profile, viewer, score) {
  return serializePublicProfile(req, user, profile, { viewer, ...(score === undefined ? {} : { score }) });
}

function jsonContainsAny(columnName, values) {
  return normalizedList(values).map((value) => where(
    fn('JSON_CONTAINS', fn('LOWER', col(`OnboardingProfile.${columnName}`)), JSON.stringify(value)),
    1,
  ));
}

function caseInsensitiveEquals(columnName, value) {
  return where(fn('LOWER', col(`OnboardingProfile.${columnName}`)), lower(value));
}

function buildProfileWhere(filters) {
  const clauses = [];
  const minAge = Number.isFinite(filters.minAge) ? filters.minAge : defaults.minAge;
  const maxAge = Number.isFinite(filters.maxAge) ? filters.maxAge : defaults.maxAge;
  const whereValues = {
    onboardingCompleted: true,
    birthDate: {
      [Op.gt]: yearsAgoDate(maxAge + 1),
      [Op.lte]: yearsAgoDate(minAge),
    },
  };

  if (filters.city) clauses.push(caseInsensitiveEquals('city', filters.city));
  if (filters.minHeight) clauses.push(where(
    cast(col('OnboardingProfile.height'), 'DECIMAL(10,2)'),
    { [Op.gte]: Number.parseFloat(filters.minHeight) },
  ));
  if (normalizedList(filters.hometown).length) clauses.push(where(
    fn('LOWER', col('OnboardingProfile.hometown')),
    { [Op.in]: normalizedList(filters.hometown) },
  ));
  if (filters.education) clauses.push(caseInsensitiveEquals('education', filters.education));
  if (filters.profession) clauses.push(caseInsensitiveEquals('profession', filters.profession));
  if (filters.community) clauses.push(caseInsensitiveEquals('community', filters.community));
  if (filters.religion) clauses.push(caseInsensitiveEquals('religion', filters.religion));
  if (filters.sexuality) clauses.push(caseInsensitiveEquals('sexuality', filters.sexuality));
  if (filters.smoking) clauses.push(caseInsensitiveEquals('smoking', filters.smoking));
  if (filters.drinking) clauses.push(caseInsensitiveEquals('drinking', filters.drinking));
  if (filters.weed) clauses.push(caseInsensitiveEquals('weed', filters.weed));

  const arrayMappings = {
    datingIntentions: 'relationshipGoals',
    languages: 'languages',
    pronouns: 'pronouns',
    qualities: 'valuedQualities',
    preferredTalkingHours: 'preferredTalkingHours',
    loveLanguages: 'loveLanguages',
  };
  for (const [filterName, columnName] of Object.entries(arrayMappings)) {
    const matches = jsonContainsAny(columnName, filters[filterName]);
    if (matches.length) clauses.push({ [Op.or]: matches });
  }

  const lifestyleMatches = normalizedList(filters.lifestyleTags).map((value) => where(
    fn('JSON_SEARCH', fn('LOWER', col('OnboardingProfile.lifestyle')), 'one', value),
    { [Op.ne]: null },
  ));
  if (lifestyleMatches.length) clauses.push({ [Op.or]: lifestyleMatches });

  if (list(filters.communicationStyles).length) {
    whereValues.communicationStyle = { [Op.in]: filters.communicationStyles };
  }
  if (filters.hasPrompts) {
    clauses.push(where(fn('JSON_LENGTH', col('OnboardingProfile.prompts')), { [Op.gt]: 0 }));
  }

  if (clauses.length) whereValues[Op.and] = clauses;
  return whereValues;
}

function discoveryPreferenceClauses(viewer) {
  const clauses = [];
  const interestedIn = normalizedList(viewer.interestedIn);
  const viewerGender = lower(viewer.gender);

  // A member's onboarding "Interested in" selection is the primary
  // recommendation constraint. Do not infer orientation from profile text.
  if (interestedIn.length) {
    clauses.push(where(fn('LOWER', col('OnboardingProfile.gender')), { [Op.in]: interestedIn }));
  }
  // Respect a candidate's reciprocal preference when it is configured. Older
  // completed profiles may not have this field, so an empty preference remains
  // discoverable rather than making the feed unexpectedly empty.
  if (viewerGender) {
    const reciprocal = jsonContainsAny('interestedIn', [viewerGender]);
    clauses.push({ [Op.or]: [
      where(fn('JSON_LENGTH', col('OnboardingProfile.interestedIn')), 0),
      ...reciprocal,
    ] });
  }
  return clauses;
}

function compatibilityScoreSql(sequelize, viewer) {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const profileColumn = (name) => `${quote('OnboardingProfile')}.${quote(name)}`;
  const sharedCount = (name, values) => {
    const candidates = normalizedList(values);
    if (!candidates.length) return '0';
    return candidates.map((value) => (
      `CASE WHEN JSON_CONTAINS(LOWER(${profileColumn(name)}), ${sequelize.escape(JSON.stringify(value))}) = 1 THEN 1 ELSE 0 END`
    )).join(' + ');
  };
  const factor = (name, values, weight) => {
    const candidates = normalizedList(values);
    if (!candidates.length) return { numerator: '0', available: '0' };
    const column = profileColumn(name);
    return {
      numerator: `(${weight} * ((${sharedCount(name, values)}) / GREATEST(${candidates.length}, JSON_LENGTH(${column}))))`,
      available: `(CASE WHEN JSON_LENGTH(${column}) > 0 THEN ${weight} ELSE 0 END)`,
    };
  };
  const interests = factor('interests', viewer.interests, SCORE_WEIGHTS.interests);
  const goals = factor('relationshipGoals', viewer.relationshipGoals, SCORE_WEIGHTS.relationshipGoals);
  const languages = factor('languages', viewer.languages, SCORE_WEIGHTS.languages);
  const exact = (name, weight) => {
    const value = lower(viewer[name]);
    if (!value) return { numerator: '0', available: '0' };
    const column = profileColumn(name);
    return {
      numerator: `(CASE WHEN LOWER(${column}) = ${sequelize.escape(value)} THEN ${weight} ELSE 0 END)`,
      available: `(CASE WHEN ${column} IS NOT NULL AND ${column} <> '' THEN ${weight} ELSE 0 END)`,
    };
  };
  const style = String(viewer.communicationStyle || '').trim().toLowerCase();
  const styleAvailable = style ? `(CASE WHEN ${profileColumn('communicationStyle')} IS NOT NULL AND ${profileColumn('communicationStyle')} <> '' THEN ${SCORE_WEIGHTS.communicationStyle} ELSE 0 END)` : '0';
  const styleNumerator = style ? `(CASE WHEN LOWER(${profileColumn('communicationStyle')}) = ${sequelize.escape(style)} THEN ${SCORE_WEIGHTS.communicationStyle} ELSE 0 END)` : '0';
  const city = exact('city', SCORE_WEIGHTS.city);
  const smoking = exact('smoking', SCORE_WEIGHTS.smoking);
  const drinking = exact('drinking', SCORE_WEIGHTS.drinking);
  const weed = exact('weed', SCORE_WEIGHTS.weed);
  const numerator = `${interests.numerator} + ${goals.numerator} + ${styleNumerator} + ${languages.numerator} + ${city.numerator} + ${smoking.numerator} + ${drinking.numerator} + ${weed.numerator}`;
  const available = `${interests.available} + ${goals.available} + ${styleAvailable} + ${languages.available} + ${city.available} + ${smoking.available} + ${drinking.available} + ${weed.available}`;
  const raw = `(CASE WHEN (${available}) = 0 THEN 50 ELSE (100 * (${numerator}) / (${available})) END)`;
  return `LEAST(100, GREATEST(0, ROUND(50 + ((${raw}) - 50) * ((${available}) / 100))))`;
}

exports.getFeed = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    const { User, OnboardingProfile, DiscoverAction, Match, Subscription } = getModels();
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const filters = await filtersFor(req.user.sub, req.query);
    if (filters.minAge > filters.maxAge) {
      return fail(res, 400, 'Minimum age cannot exceed maximum age.', 'VALIDATION_ERROR', [
        { field: 'minAge', message: 'Minimum age cannot exceed maximum age.' },
      ]);
    }

    const sequelize = User.sequelize;
    const scoreSql = compatibilityScoreSql(sequelize, viewer);
    const excludedTargets = literal(`(SELECT ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier('targetUserId')} FROM ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier(DiscoverAction.getTableName())} WHERE ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier('actorUserId')} = ${sequelize.escape(Number(req.user.sub))})`);
    const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
    const viewerId = sequelize.escape(Number(req.user.sub));
    const matchedTargets = literal(`(SELECT CASE WHEN ${quote('userOneId')} = ${viewerId} THEN ${quote('userTwoId')} ELSE ${quote('userOneId')} END FROM ${quote(Match.getTableName())} WHERE ${quote('userOneId')} = ${viewerId} OR ${quote('userTwoId')} = ${viewerId})`);
    const userWhere = {
      id: { [Op.ne]: Number(req.user.sub), [Op.notIn]: excludedTargets },
      accountStatus: 'active',
      [Op.and]: [
        notBlockedUserSql(sequelize, req.user.sub),
        where(col('User.id'), { [Op.notIn]: matchedTargets }),
      ],
    };
    if (filters.verifiedOnly) userWhere.identityVerifiedAt = { [Op.ne]: null };
    if (filters.onlineNow) {
      const runtime = await require('../services/adminDiscoverConfigurationService').runtimeConfiguration();
      const thresholdMinutes = Math.max(1, Number(runtime.defaults.onlineWindowMinutes || process.env.ONLINE_NOW_WINDOW_MINUTES || 5));
      userWhere.lastActiveAt = { [Op.gte]: new Date(Date.now() - thresholdMinutes * 60 * 1000) };
    }
    if (filters.hasEventInterest) {
      const registrations = quote(getModels().EventRegistration.getTableName());
      const candidate = `${quote('User')}.${quote('id')}`;
      userWhere[Op.and].push(literal(`EXISTS (SELECT 1 FROM ${registrations} AS ${quote('eventInterestRegistration')} WHERE ${quote('eventInterestRegistration')}.${quote('userId')} = ${candidate} AND ${quote('eventInterestRegistration')}.${quote('status')} = 'registered')`));
    }

    const profileWhere = buildProfileWhere(filters);
    const preferenceClauses = discoveryPreferenceClauses(viewer);
    const users = await User.findAll({
      where: userWhere,
      include: [{
        model: OnboardingProfile,
        required: true,
        where: {
          ...profileWhere,
          [Op.and]: [
            ...(profileWhere[Op.and] || []),
            ...preferenceClauses,
            where(literal(scoreSql), { [Op.gte]: filters.minScore }),
          ],
        },
        attributes: { include: [[literal(scoreSql), 'compatibilityScore']] },
      }, { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] }],
      order: [[literal(scoreSql), 'DESC'], ['id', 'ASC']],
      offset: (page - 1) * limit,
      limit: limit + 1,
      subQuery: false,
    });

    const hasMore = users.length > limit;
    const selected = (hasMore ? users.slice(0, limit) : users)
      .map((user) => ({ user, score: Number(user.OnboardingProfile.getDataValue('compatibilityScore')) }));
    if (req.aiMatches === true) {
      const ranked = rankCandidates(viewer, selected.map(({ user, score }) => ({
        userId: user.id, user, profile: user.OnboardingProfile, compatibility: { score, coverage: 100, factors: [] },
      })));
      return success(res, ranked.length ? 'AI recommendations retrieved.' : 'No AI recommendations found.', {
        recommendations: ranked.map((item) => ({
          id: String(item.user.id),
          profile: profileData(req, item.user, item.profile, viewer, item.aiMatchScore),
          compatibility: { score: item.aiMatchScore, confidence: item.aiConfidence, level: item.aiMatchLevel, highlights: item.aiHighlights, reasons: item.aiReasons },
        })),
        pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
      });
    }
    return success(res, selected.length ? 'Discover feed retrieved.' : 'No discover profiles found.', {
      profiles: selected.map(({ user, score }) => profileData(req, user, user.OnboardingProfile, viewer, score)),
      pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
    });
  } catch (error) {
    return next(error);
  }
};

exports.swipe = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    const { User, OnboardingProfile, DiscoverAction, Match } = getModels();
    const targetUserId = Number(req.body.targetUserId);
    const failureType = req.body.action === 'superLike' ? 'super_like' : req.body.action === 'like' ? 'like' : null;
    if (targetUserId === Number(req.user.sub)) {
      if (failureType) await require('../services/matchingActionFailureService').recordFailure({ actionType: failureType, actorUserId: req.user.sub, targetUserId, code: 'SELF_ACTION_NOT_ALLOWED', stage: 'eligibility' });
      return fail(res, 400, 'You cannot swipe on your own profile.', 'INVALID_TARGET', [
        { field: 'targetUserId', message: 'Target user must be another user.' },
      ]);
    }
    const target = await User.findOne({
      where: { id: targetUserId, accountStatus: 'active' },
      include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
    });
    if (!target) {
      if (failureType) await require('../services/matchingActionFailureService').recordFailure({ actionType: failureType, actorUserId: req.user.sub, targetUserId, code: 'PROFILE_NOT_DISCOVERABLE', stage: 'eligibility' });
      return fail(res, 404, 'Profile is not available for Discover.', 'PROFILE_NOT_DISCOVERABLE');
    }
    if (await areUsersBlocked(req.user.sub, targetUserId)) {
      if (failureType) await require('../services/matchingActionFailureService').recordFailure({ actionType: failureType, actorUserId: req.user.sub, targetUserId, code: 'RELATIONSHIP_BLOCKED', stage: 'relationship' });
      return fail(res, 404, 'Profile is not available for Discover.', 'PROFILE_NOT_DISCOVERABLE');
    }
    let match = null;
    let matchedRow = null;
    let conversationRow = null;
    let createdAction = false;
    await User.sequelize.transaction(async (transaction) => {
      const participantIds = [Number(req.user.sub), targetUserId].sort((a, b) => a - b);
      await User.findAll({
        where: { id: participantIds },
        order: [['id', 'ASC']],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      const existingAction = await DiscoverAction.findOne({ where: { actorUserId: req.user.sub, targetUserId }, transaction, lock: transaction.LOCK.UPDATE });
      if (existingAction && ['like', 'superLike'].includes(existingAction.action) && req.body.action === 'like') return;
      createdAction = !existingAction;
      await DiscoverAction.upsert({ actorUserId: req.user.sub, targetUserId, action: req.body.action, createdAt: existingAction?.createdAt || new Date(), updatedAt: new Date() }, { transaction });
      if (['like', 'superLike'].includes(req.body.action)) {
        const reciprocal = await DiscoverAction.findOne({
          where: {
            actorUserId: targetUserId,
            targetUserId: req.user.sub,
            action: { [Op.in]: ['like', 'superLike'] },
          },
          transaction,
        });
        if (!reciprocal) {
          await createNotification({
            userId: targetUserId,
            actorUserId: Number(req.user.sub),
            type: req.body.action === 'superLike' ? 'new_super_like' : 'new_like',
            category: req.body.action === 'superLike' ? 'Super Likes' : 'Likes',
            title: req.body.action === 'superLike' ? 'You received a Super Like' : 'You received a like',
            message: 'Someone is interested in your profile.',
            data: { targetUserId: String(req.user.sub) },
            dedupeKey: `reaction:${req.user.sub}:${targetUserId}`,
            transaction,
          });
          return;
        }
        const userOneId = Math.min(Number(req.user.sub), targetUserId);
        const userTwoId = Math.max(Number(req.user.sub), targetUserId);
        const [row] = await Match.findOrCreate({
          where: { userOneId, userTwoId },
          defaults: { userOneId, userTwoId, matchedAt: new Date() },
          transaction,
        });
        matchedRow = row;
        conversationRow = (await ensureDirectConversation(userOneId, userTwoId, { transaction })).conversation;
      }
    });
    if (matchedRow) {
      match = {
        matched: true,
        matchId: String(matchedRow.id),
        conversationId: String(conversationRow.id),
        matchedProfile: profileData(req, target, target.OnboardingProfile, viewer),
      };
        await emitConversationEvent(conversationRow.id, 'conversation.updated', {
          conversationId: String(conversationRow.id),
          matchId: String(matchedRow.id),
        }).catch(() => {});
        await Promise.all([
          createNotification({ userId: Number(req.user.sub), actorUserId: targetUserId, type: 'new_match', category: 'match', title: 'It\'s a match', message: `You and ${target.name} matched.`, data: { matchId: String(matchedRow.id), userId: String(targetUserId) }, dedupeKey: `match:${matchedRow.id}:${req.user.sub}` }),
          createNotification({ userId: targetUserId, actorUserId: Number(req.user.sub), type: 'new_match', category: 'match', title: 'It\'s a match', message: 'You have a new match.', data: { matchId: String(matchedRow.id), userId: String(req.user.sub) }, dedupeKey: `match:${matchedRow.id}:${targetUserId}` }),
        ]);
    }
    return success(res, 'Swipe saved.', {
      action: req.body.action,
      targetUserId: String(targetUserId),
      likeStatus: req.body.action === 'like' ? (createdAction ? 'liked' : 'already_liked') : undefined,
      ...(match || { matched: false }),
    });
  } catch (error) {
    return next(error);
  }
};

exports.rewind = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    const { DiscoverAction } = getModels();
    const action = await DiscoverAction.findOne({
      where: { actorUserId: req.user.sub },
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
    });
    if (!action) return fail(res, 404, 'There is no swipe action to rewind.', 'NOTHING_TO_REWIND');
    await action.destroy();
    return success(res, 'Last swipe rewound.', {
      targetUserId: String(action.targetUserId),
      action: action.action,
    });
  } catch (error) {
    return next(error);
  }
};

exports.getFilters = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    return success(res, 'Discover filters retrieved.', { filters: await filtersFor(req.user.sub) });
  } catch (error) {
    return next(error);
  }
};

exports.updateFilters = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    const filters = await filtersFor(req.user.sub, req.body);
    if (filters.minAge > filters.maxAge) {
      return fail(res, 400, 'Minimum age cannot exceed maximum age.', 'VALIDATION_ERROR', [
        { field: 'minAge', message: 'Minimum age cannot exceed maximum age.' },
      ]);
    }
    return success(res, 'Discover filters updated.', { filters: await persistFilters(req.user.sub, req.body) });
  } catch (error) {
    return next(error);
  }
};

exports._test = { buildProfileWhere, discoveryPreferenceClauses, compatibilityScoreSql };
