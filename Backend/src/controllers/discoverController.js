const { Op, fn, col, where, cast, literal } = require('sequelize');
const { getModels } = require('../models');
const { scoreCompatibility, sqlCompatibilityExpressions } = require('../services/matchEngineService');
const { areUsersBlocked, notBlockedUserSql } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');
const { defaults, effectiveDefaultsFor, filtersFor, updateFilters: persistFilters } = require('../services/discoverPreferenceService');
const { createNotification } = require('../services/notificationService');
const { ensureDirectConversation } = require('../services/conversationAccessService');
const { emitConversationEvent } = require('../realtime/realtimeHub');
const { rankCandidates } = require('../services/aiMatchProvider');
const matchEngineObservability = require('../services/matchEngineObservabilityService');
const { sqlDistanceExpression, validCoordinates } = require('../utils/geoDistance');
const {
  MATCH_RANKING_VERSION,
  RecommendationCursorError,
  createCursor,
  readCursor,
} = require('../services/recommendationCursorService');
const {
  ACCOUNT_STATUS,
  EVENT_REGISTRATION_STATUSES,
  EXCLUDING_DISCOVER_ACTIONS,
  comparisonString,
  ageFor,
  isDiscoverComplete,
  jsonContainsAny,
  normalizedStringList,
  profileCompletionSqlClauses,
  recentActivityWindowMinutes,
  reciprocalPreferenceClauses,
  reciprocalEligibilitySqlClauses,
  surfaceContract,
} = require('../services/discoverEligibilityPolicy');

const success = (res, message, data) => res.json({ success: true, message, data });
const fail = (res, status, message, code, errors = []) => res.status(status).json({ success: false, message, code, errors });
const list = (value) => (Array.isArray(value) ? value : []);
const lower = comparisonString;
const normalizedList = (value) => normalizedStringList(value).map(lower);


function yearsAgoDate(years) {
  const now = new Date();
  const date = new Date(Date.UTC(now.getUTCFullYear() - years, now.getUTCMonth(), now.getUTCDate()));
  return date.toISOString().slice(0, 10);
}

async function profileFor(userId) {
  const { OnboardingProfile } = getModels();
  return OnboardingProfile.findOne({ where: { userId } });
}

async function requireCompleted(res, userId, onIncomplete) {
  const profile = await profileFor(userId);
  if (!isDiscoverComplete(profile)) {
    if (onIncomplete) onIncomplete();
    fail(res, 403, 'Complete your profile before using Discover.', 'ONBOARDING_INCOMPLETE');
    return null;
  }
  return profile;
}

function profileData(req, user, profile, viewer, compatibility, recentActivityMinutes, distanceKm) {
  return serializePublicProfile(req, user, profile, {
    viewer,
    recentActivityWindowMinutes: recentActivityMinutes,
    distanceKm,
    ...(compatibility ? { compatibility, score: compatibility.score } : {}),
  });
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
    stage: 'complete',
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

  whereValues[Op.and] = clauses;
  return whereValues;
}

function discoveryPreferenceClauses(viewer) {
  return reciprocalPreferenceClauses(viewer);
}

function compatibilityScoreSql(sequelize, viewer) {
  return sqlCompatibilityExpressions(sequelize, viewer).score;
}

function paginationContext({ filters, surface, viewer, activityWindowMinutes, candidatePreferenceDefaults }) {
  return {
    filters,
    surface,
    activityWindowMinutes,
    candidatePreferenceDefaults,
    viewer: {
      birthDate: viewer.birthDate,
      gender: viewer.gender,
      interestedIn: viewer.interestedIn,
      interests: viewer.interests,
      relationshipGoals: viewer.relationshipGoals,
      communicationStyle: viewer.communicationStyle,
      languages: viewer.languages,
      city: viewer.city,
      smoking: viewer.smoking,
      drinking: viewer.drinking,
      weed: viewer.weed,
      matchLatitude: viewer.matchLatitude,
      matchLongitude: viewer.matchLongitude,
    },
  };
}

function finiteCursorNumber(value, field) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) throw new RecommendationCursorError(`The pagination cursor ${field} is invalid.`);
  return parsed;
}

function positiveCursorId(value) {
  const parsed = finiteCursorNumber(value, 'id');
  if (!Number.isInteger(parsed) || parsed < 1) throw new RecommendationCursorError('The pagination cursor id is invalid.');
  return parsed;
}

async function observableCandidateCounts({
  enabled,
  User,
  OnboardingProfile,
  viewerId,
  userWhereWithoutDistance,
  userWhereWithDistance,
  profileWhereWithoutDistance,
  profileWhereWithDistance,
  distanceFilterActive,
}) {
  if (!enabled) return {};
  const countWithProfile = (userWhere, profileWhere) => User.count({
    where: userWhere,
    include: [{ model: OnboardingProfile, required: true, attributes: [], where: profileWhere }],
    distinct: true,
    col: 'id',
  });
  const beforeEligibility = await User.count({ where: { id: { [Op.ne]: Number(viewerId) } } });
  const afterEligibility = await countWithProfile(userWhereWithoutDistance, profileWhereWithoutDistance);
  const afterDistance = distanceFilterActive
    ? await countWithProfile(userWhereWithDistance, profileWhereWithDistance)
    : afterEligibility;
  return { beforeEligibility, afterEligibility, afterDistance };
}

exports.getFeed = async (req, res, next) => {
  const startedAt = Date.now();
  const observabilityEnabled = matchEngineObservability.enabled();
  let observedSurface = req.aiMatches === true ? 'high_compatibility' : 'default';
  let observedProvider = req.aiMatches === true ? 'LOCAL' : 'STANDARD';
  let candidateCounts = {};
  const observe = (values = {}) => {
    if (!observabilityEnabled) return null;
    return matchEngineObservability.emitRecommendationDiagnostic({
      surface: observedSurface,
      provider: observedProvider,
      continuation: Boolean(req.query.cursor),
      limit: req.query.limit || 10,
      profiles: [],
      candidateCounts,
      startedAt,
      ...values,
    });
  };
  const observedFail = (status, message, code, errors = []) => {
    observe({ errorCode: code });
    return fail(res, status, message, code, errors);
  };
  try {
    const surface = surfaceContract(req.query.surface, { aiMatches: req.aiMatches === true });
    observedSurface = surface.name === 'recommended' ? 'default' : surface.name;
    if (!surface.supported) {
      return observedFail(400, `Discover surface '${surface.name}' is not supported yet.`, 'DISCOVER_SURFACE_UNSUPPORTED', [
        { field: 'surface', message: `${surface.name} is reserved for a later Match Engine phase.` },
      ]);
    }
    const viewer = await requireCompleted(res, req.user.sub, () => observe({ errorCode: 'ONBOARDING_INCOMPLETE' }));
    if (!viewer) return;
    const viewerLocationAvailable = validCoordinates(viewer.matchLatitude, viewer.matchLongitude);
    if (surface.name === 'near_you' && !viewerLocationAvailable) {
      return observedFail(409, 'Enable current location to use Near You.', 'LOCATION_REQUIRED', [
        { field: 'location', message: 'A saved current location is required for Near You.' },
      ]);
    }
    const { User, OnboardingProfile, DiscoverAction, DiscoverFilterPreference, Match, Subscription } = getModels();
    const page = Number(req.query.page || 1);
    if (page > 1 && !req.query.cursor) {
      return observedFail(400, 'A continuation cursor is required after the first recommendation page.', 'PAGINATION_CURSOR_REQUIRED', [
        { field: 'cursor', message: 'Use pagination.nextCursor from the preceding response.' },
      ]);
    }
    const limit = Number(req.query.limit || 10);
    const filters = await filtersFor(req.user.sub, req.query);
    if (filters.minAge > filters.maxAge) {
      return observedFail(400, 'Minimum age cannot exceed maximum age.', 'VALIDATION_ERROR', [
        { field: 'minAge', message: 'Minimum age cannot exceed maximum age.' },
      ]);
    }

    if (!req.aiMatches && String(req.query.reset) === 'true') {
      await DiscoverAction.destroy({
        where: {
          actorUserId: req.user.sub,
          action: 'pass',
        },
      }).catch(() => {});
    }

    const runtime = await require('../services/adminDiscoverConfigurationService').runtimeConfiguration();
    const activityWindowMinutes = recentActivityWindowMinutes(runtime.defaults.onlineWindowMinutes);
    const candidatePreferenceDefaults = effectiveDefaultsFor(runtime.defaults);
    const sequelize = User.sequelize;
    const scoreExpressions = sqlCompatibilityExpressions(sequelize, viewer);
    const scoreSql = scoreExpressions.score;
    const distanceFilterActive = viewerLocationAvailable;
    const distanceSql = distanceFilterActive ? sqlDistanceExpression(sequelize, {
      viewerLatitude: viewer.matchLatitude,
      viewerLongitude: viewer.matchLongitude,
    }) : null;
    const distanceRankSql = distanceSql ? `ROUND(${distanceSql}, 6)` : null;
    const cursorContext = paginationContext({
      filters,
      surface: surface.name,
      viewer,
      activityWindowMinutes,
      candidatePreferenceDefaults,
    });
    const cursorKeys = req.query.cursor ? readCursor(req.query.cursor, {
      viewerId: req.user.sub,
      surface: surface.name,
      context: cursorContext,
    }) : null;
    const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
    const viewerId = sequelize.escape(Number(req.user.sub));
    const excludedActions = EXCLUDING_DISCOVER_ACTIONS.map((action) => sequelize.escape(action)).join(', ');
    const excludedTargets = literal(`(SELECT ${quote('targetUserId')} FROM ${quote(DiscoverAction.getTableName())} WHERE ${quote('actorUserId')} = ${viewerId} AND ${quote('action')} IN (${excludedActions}))`);
    const matchedTargets = literal(`(SELECT CASE WHEN ${quote('userOneId')} = ${viewerId} THEN ${quote('userTwoId')} ELSE ${quote('userOneId')} END FROM ${quote(Match.getTableName())} WHERE ${quote('userOneId')} = ${viewerId} OR ${quote('userTwoId')} = ${viewerId})`);
    const userWhere = {
      id: { [Op.ne]: Number(req.user.sub), [Op.notIn]: excludedTargets },
      accountStatus: ACCOUNT_STATUS.eligible,
      [Op.and]: [
        notBlockedUserSql(sequelize, req.user.sub),
        where(col('User.id'), { [Op.notIn]: matchedTargets }),
      ],
    };
    if (filters.verifiedOnly) userWhere.identityVerifiedAt = { [Op.ne]: null };
    if (filters.onlineNow) {
      userWhere.lastActiveAt = { [Op.gte]: new Date(Date.now() - activityWindowMinutes * 60 * 1000) };
    }
    if (filters.hasEventInterest) {
      const registrations = quote(getModels().EventRegistration.getTableName());
      const candidate = `${quote('User')}.${quote('id')}`;
      const statuses = EVENT_REGISTRATION_STATUSES.map((status) => sequelize.escape(status)).join(', ');
      userWhere[Op.and].push(literal(`EXISTS (SELECT 1 FROM ${registrations} AS ${quote('eventInterestRegistration')} WHERE ${quote('eventInterestRegistration')}.${quote('userId')} = ${candidate} AND ${quote('eventInterestRegistration')}.${quote('status')} IN (${statuses}))`));
    }

    const reciprocalWithoutDistance = reciprocalEligibilitySqlClauses(sequelize, {
      viewerAge: ageFor(viewer.birthDate),
      viewerMaxDistanceKm: filters.maxDistanceKm,
      distanceSql: null,
      preferenceDefaults: candidatePreferenceDefaults,
      preferenceTableName: DiscoverFilterPreference.getTableName(),
    });
    const userWhereWithoutDistance = {
      ...userWhere,
      [Op.and]: [...userWhere[Op.and], ...reciprocalWithoutDistance],
    };
    userWhere[Op.and].push(...reciprocalEligibilitySqlClauses(sequelize, {
      viewerAge: ageFor(viewer.birthDate),
      viewerMaxDistanceKm: filters.maxDistanceKm,
      distanceSql,
      preferenceDefaults: candidatePreferenceDefaults,
      preferenceTableName: DiscoverFilterPreference.getTableName(),
    }));

    const profileWhere = buildProfileWhere(filters);
    const preferenceClauses = discoveryPreferenceClauses(viewer);
    const distanceClauses = distanceFilterActive ? [
      where(col('OnboardingProfile.matchLatitude'), { [Op.between]: [-90, 90] }),
      where(col('OnboardingProfile.matchLongitude'), { [Op.between]: [-180, 180] }),
    ] : [];
    const profileWhereWithoutDistance = {
      ...profileWhere,
      [Op.and]: [
        ...(profileWhere[Op.and] || []),
        ...profileCompletionSqlClauses(sequelize),
        ...preferenceClauses,
      ],
    };
    const profileWhereWithDistance = {
      ...profileWhere,
      [Op.and]: [...profileWhereWithoutDistance[Op.and], ...distanceClauses],
    };
    const isAiMatches = req.aiMatches === true;
    const cursorProfileClauses = [];
    if (cursorKeys && !isAiMatches) {
      const lastId = positiveCursorId(cursorKeys.id);
      const lastScore = finiteCursorNumber(cursorKeys.score, 'score');
      if (surface.name === 'near_you') {
        const lastDistance = finiteCursorNumber(cursorKeys.distance, 'distance');
        cursorProfileClauses.push(literal(`(${distanceRankSql} > ${sequelize.escape(lastDistance)} OR (${distanceRankSql} = ${sequelize.escape(lastDistance)} AND (${scoreSql} < ${sequelize.escape(lastScore)} OR (${scoreSql} = ${sequelize.escape(lastScore)} AND ${quote('User')}.${quote('id')} > ${sequelize.escape(lastId)}))))`));
      } else {
        cursorProfileClauses.push(literal(`(${scoreSql} < ${sequelize.escape(lastScore)} OR (${scoreSql} = ${sequelize.escape(lastScore)} AND ${quote('User')}.${quote('id')} > ${sequelize.escape(lastId)}))`));
      }
    }
    const users = await User.findAll({
      where: userWhere,
      include: [{
        model: OnboardingProfile,
        required: true,
        where: {
          ...profileWhere,
          [Op.and]: [
            ...(profileWhere[Op.and] || []),
            ...profileCompletionSqlClauses(sequelize),
            ...preferenceClauses,
            ...distanceClauses,
            ...cursorProfileClauses,
            where(literal(scoreSql), { [Op.gte]: filters.minScore }),
          ],
        },
        attributes: { include: [
          [literal(scoreSql), 'compatibilityScore'],
          [literal(scoreExpressions.coverage), 'compatibilityCoverage'],
          ...(distanceSql ? [[literal(distanceSql), 'distanceKmPrecise']] : []),
          ...(surface.name === 'near_you' ? [[literal(distanceRankSql), 'distanceRank']] : []),
        ] },
      }, { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] }],
      order: surface.name === 'near_you'
        ? [[literal(distanceRankSql), 'ASC'], [literal(scoreSql), 'DESC'], ['id', 'ASC']]
        : [[literal(scoreSql), 'DESC'], ['id', 'ASC']],
      // AI ranking must happen over the eligible set before page slicing.
      // Never silently truncate eligibility at 500. Larger pools need a future
      // versioned snapshot/cache, not independent per-page ranking.
      ...(isAiMatches ? {} : { limit: limit + 1 }),
      subQuery: false,
    });
    candidateCounts = await observableCandidateCounts({
      enabled: observabilityEnabled,
      User,
      OnboardingProfile,
      viewerId: req.user.sub,
      userWhereWithoutDistance,
      userWhereWithDistance: userWhere,
      profileWhereWithoutDistance,
      profileWhereWithDistance,
      distanceFilterActive,
    });

    const hasMore = !isAiMatches && users.length > limit;
    const selected = (hasMore ? users.slice(0, limit) : users)
      .map((user) => {
        const queried = user.OnboardingProfile?.getDataValue('compatibilityScore');
        const canonicalCompatibility = scoreCompatibility(viewer, user.OnboardingProfile);
        const score = queried != null && Number.isFinite(Number(queried))
          ? Number(queried) : canonicalCompatibility.score;
        const queriedCoverage = user.OnboardingProfile?.getDataValue('compatibilityCoverage');
        const coverage = queriedCoverage != null && Number.isFinite(Number(queriedCoverage))
          ? Number(queriedCoverage) : canonicalCompatibility.coverage;
        const compatibility = {
          ...canonicalCompatibility,
          score,
          coverage,
          compatibilityScore: score,
          compatibilityCoverage: coverage,
        };
        const queriedDistance = user.OnboardingProfile?.getDataValue('distanceKmPrecise');
        const distanceKm = queriedDistance != null && Number.isFinite(Number(queriedDistance))
          ? Number(queriedDistance) : null;
        return { user, compatibility, distanceKm };
      });
    if (isAiMatches) {
      const distanceByUserId = new Map(selected.map(({ user, distanceKm }) => [Number(user.id), distanceKm]));
      const selectedByUserId = new Map(selected.map((item) => [Number(item.user.id), item]));
      // Compatibility is already calculated. Keep user/profile objects and
      // especially exact coordinates outside the AI provider boundary.
      const aiRankingStartedAt = Date.now();
      const ranked = rankCandidates({}, selected.map(({ user, compatibility }) => ({
        userId: user.id,
        compatibility,
      }))).map((item) => ({
        ...item,
        user: selectedByUserId.get(Number(item.userId)).user,
      }));
      let continuation = ranked;
      if (cursorKeys) {
        const lastId = positiveCursorId(cursorKeys.id);
        const lastAiScore = finiteCursorNumber(cursorKeys.aiScore, 'AI score');
        const lastConfidence = finiteCursorNumber(cursorKeys.confidence, 'AI confidence');
        continuation = ranked.filter((item) => (
          item.aiMatchScore < lastAiScore
          || (item.aiMatchScore === lastAiScore && (
            item.aiConfidence < lastConfidence
            || (item.aiConfidence === lastConfidence && Number(item.userId) > lastId)
          ))
        ));
      }
      const aiHasMore = continuation.length > limit;
      const pageItems = continuation.slice(0, limit);
      const lastItem = pageItems.at(-1);
      const nextCursor = aiHasMore && lastItem ? createCursor({
        viewerId: req.user.sub,
        surface: surface.name,
        context: cursorContext,
        keys: { aiScore: lastItem.aiMatchScore, confidence: lastItem.aiConfidence, id: Number(lastItem.userId) },
      }) : null;
      const recommendations = pageItems.map((item) => ({
        id: String(item.user.id),
        profile: profileData(req, item.user, item.user.OnboardingProfile || {}, viewer, item.compatibility, activityWindowMinutes, distanceByUserId.get(Number(item.user.id))),
        compatibilityScore: item.compatibility.score,
        compatibilityCoverage: item.compatibility.coverage,
        aiMatchScore: item.aiMatchScore,
        aiConfidence: item.aiConfidence,
        aiMatchLevel: item.aiMatchLevel,
        aiHighlights: item.aiHighlights,
        aiReasons: item.aiReasons,
      }));
      observe({ profiles: recommendations, aiRankingDurationMs: Date.now() - aiRankingStartedAt });
      return success(res, ranked.length ? 'AI recommendations retrieved.' : 'No AI recommendations found.', {
        provider: 'LOCAL',
        recommendations,
        locationMatching: { viewerLocationAvailable, distanceFilterActive },
        pagination: { limit, hasMore: aiHasMore, nextCursor, rankingVersion: MATCH_RANKING_VERSION },
      });
    }
    const lastSelected = selected.at(-1);
    const nextCursor = hasMore && lastSelected ? createCursor({
      viewerId: req.user.sub,
      surface: surface.name,
      context: cursorContext,
      keys: {
        score: lastSelected.compatibility.score,
        id: Number(lastSelected.user.id),
        ...(surface.name === 'near_you' ? {
          distance: Number(lastSelected.user.OnboardingProfile.getDataValue('distanceRank')),
        } : {}),
      },
    }) : null;
    const profiles = selected.map(({ user, compatibility, distanceKm }) => profileData(req, user, user.OnboardingProfile || {}, viewer, compatibility, activityWindowMinutes, distanceKm));
    observe({ profiles });
    return success(res, selected.length ? 'Discover feed retrieved.' : 'No discover profiles found.', {
      profiles,
      locationMatching: { viewerLocationAvailable, distanceFilterActive },
      pagination: { limit, hasMore, nextCursor, rankingVersion: MATCH_RANKING_VERSION },
    });
  } catch (error) {
    if (error instanceof RecommendationCursorError) {
      return observedFail(400, error.message, error.code, [{ field: 'cursor', message: error.message }]);
    }
    observe({ errorCode: error.code || 'INTERNAL_ERROR' });
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
    let alreadyLiked = false;
    await User.sequelize.transaction(async (transaction) => {
      const participantIds = [Number(req.user.sub), targetUserId].sort((a, b) => a - b);
      await User.findAll({
        where: { id: participantIds },
        order: [['id', 'ASC']],
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      const existingAction = await DiscoverAction.findOne({ where: { actorUserId: req.user.sub, targetUserId }, transaction, lock: transaction.LOCK.UPDATE });
      alreadyLiked = existingAction
        && ['like', 'superLike'].includes(existingAction.action)
        && req.body.action === 'like';
      if (!alreadyLiked) {
        await DiscoverAction.upsert({ actorUserId: req.user.sub, targetUserId, action: req.body.action, createdAt: existingAction?.createdAt || new Date(), updatedAt: new Date() }, { transaction });
      }
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
      liked: req.body.action === 'like' ? true : undefined,
      likeStatus: req.body.action === 'like' ? (alreadyLiked ? 'already_liked' : 'liked') : undefined,
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
