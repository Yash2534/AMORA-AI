const { Op, fn, col, where, cast, literal } = require('sequelize');
const { getModels } = require('../models');
const computeCompatibilityScore = require('../utils/computeCompatibilityScore');
const { parseCommunicationStyles } = require('../constants/communicationStyles');
const { areUsersBlocked, notBlockedUserSql } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');

const success = (res, message, data) => res.json({ success: true, message, data });
const fail = (res, status, message, code, errors = []) => res.status(status).json({ success: false, message, code, errors });
const list = (value) => (Array.isArray(value) ? value : []);
const lower = (value) => String(value || '').trim().toLowerCase();
const normalizedList = (value) => [...new Set(list(value).map(lower).filter(Boolean))];

const defaults = {
  minAge: 18,
  maxAge: 45,
  maxDistanceKm: 80,
  minScore: 0,
  city: '',
  minHeight: '',
  hometown: [],
  datingIntentions: [],
  lifestyleTags: [],
  education: '',
  profession: '',
  community: '',
  religion: '',
  languages: [],
  pronouns: [],
  sexuality: '',
  qualities: [],
  preferredTalkingHours: [],
  loveLanguages: [],
  communicationStyles: [],
  smoking: '',
  drinking: '',
  weed: '',
  verifiedOnly: true,
  onlineNow: false,
  hasPrompts: false,
  hasEventInterest: false,
};
const arrayFilters = new Set([
  'hometown',
  'datingIntentions',
  'lifestyleTags',
  'languages',
  'pronouns',
  'qualities',
  'preferredTalkingHours',
  'loveLanguages',
  'communicationStyles',
]);

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

function profileData(req, user, profile, viewer) {
  return serializePublicProfile(req, user, profile, { viewer });
}

async function filtersFor(userId, overrides = {}) {
  const { DiscoverFilterPreference } = getModels();
  const [stored] = await DiscoverFilterPreference.findOrCreate({
    where: { userId },
    defaults: { userId, ...defaults },
  });
  const values = { ...defaults, ...stored.toJSON() };
  for (const key of Object.keys(defaults)) {
    if (overrides[key] === undefined) continue;
    if (['minAge', 'maxAge', 'maxDistanceKm', 'minScore'].includes(key)) {
      values[key] = Number(overrides[key]);
    } else if (['verifiedOnly', 'onlineNow', 'hasPrompts', 'hasEventInterest'].includes(key)) {
      values[key] = String(overrides[key]) === 'true';
    } else if (arrayFilters.has(key)) {
      values[key] = key === 'communicationStyles'
        ? parseCommunicationStyles(overrides[key])
        : typeof overrides[key] === 'string'
          ? overrides[key].split(',').map((value) => value.trim()).filter(Boolean)
          : overrides[key];
    } else {
      values[key] = overrides[key];
    }
  }
  return values;
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

  // There is no persisted presence or event-participation source in the Phase 1 schema.
  // An active filter therefore has no eligible rows instead of using placeholder state.
  if (filters.onlineNow || filters.hasEventInterest) clauses.push(literal('1 = 0'));

  if (clauses.length) whereValues[Op.and] = clauses;
  return whereValues;
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
  const interests = sharedCount('interests', viewer.interests);
  const goals = sharedCount('relationshipGoals', viewer.relationshipGoals);
  const languages = sharedCount('languages', viewer.languages);
  const qualities = sharedCount('valuedQualities', viewer.valuedQualities);
  return `LEAST(100, GREATEST(0, ROUND(55 + LEAST((${interests}) * 6, 24) + LEAST((${goals}) * 10, 10) + LEAST((${languages}) * 4, 6) + LEAST((${qualities}) * 3, 5))))`;
}

function activeBoostSql(sequelize) {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const boosts = quote(getModels().Boost.getTableName());
  return `EXISTS (SELECT 1 FROM ${boosts} AS ${quote('activeBoost')} WHERE ${quote('activeBoost')}.${quote('userId')} = ${quote('User')}.${quote('id')} AND ${quote('activeBoost')}.${quote('active')} = 1 AND ${quote('activeBoost')}.${quote('expiresAt')} > CURRENT_TIMESTAMP)`;
}

exports.getFeed = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    const { User, OnboardingProfile, DiscoverAction } = getModels();
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
    const boostSql = activeBoostSql(sequelize);
    const excludedTargets = literal(`(SELECT ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier('targetUserId')} FROM ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier(DiscoverAction.getTableName())} WHERE ${sequelize.getQueryInterface().queryGenerator.quoteIdentifier('actorUserId')} = ${sequelize.escape(Number(req.user.sub))})`);
    const userWhere = {
      id: { [Op.ne]: Number(req.user.sub), [Op.notIn]: excludedTargets },
      accountStatus: 'active',
      [Op.and]: [notBlockedUserSql(sequelize, req.user.sub)],
    };
    if (filters.verifiedOnly) userWhere.isVerified = true;

    const profileWhere = buildProfileWhere(filters);
    const users = await User.findAll({
      where: userWhere,
      include: [{
        model: OnboardingProfile,
        required: true,
        where: {
          ...profileWhere,
          [Op.and]: [
            ...(profileWhere[Op.and] || []),
            where(literal(scoreSql), { [Op.gte]: filters.minScore }),
          ],
        },
        attributes: { include: [[literal(scoreSql), 'compatibilityScore']] },
      }],
      order: [
        [literal(boostSql), 'DESC'],
        [literal(scoreSql), 'DESC'],
        ['id', 'ASC'],
      ],
      offset: (page - 1) * limit,
      limit: limit + 1,
      subQuery: false,
    });

    const hasMore = users.length > limit;
    const selected = hasMore ? users.slice(0, limit) : users;
    return success(res, selected.length ? 'Discover feed retrieved.' : 'No discover profiles found.', {
      profiles: selected.map((user) => profileData(req, user, user.OnboardingProfile, viewer)),
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
    if (targetUserId === Number(req.user.sub)) {
      return fail(res, 400, 'You cannot swipe on your own profile.', 'INVALID_TARGET', [
        { field: 'targetUserId', message: 'Target user must be another user.' },
      ]);
    }
    const target = await User.findOne({
      where: { id: targetUserId, accountStatus: 'active' },
      include: [{ model: OnboardingProfile, required: true, where: { onboardingCompleted: true } }],
    });
    if (!target || await areUsersBlocked(req.user.sub, targetUserId)) return fail(res, 404, 'Profile is not available for Discover.', 'PROFILE_NOT_DISCOVERABLE');
    await DiscoverAction.upsert({
      actorUserId: req.user.sub,
      targetUserId,
      action: req.body.action,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    let match = null;
    if (['like', 'superLike'].includes(req.body.action)) {
      const reciprocal = await DiscoverAction.findOne({
        where: {
          actorUserId: targetUserId,
          targetUserId: req.user.sub,
          action: { [Op.in]: ['like', 'superLike'] },
        },
      });
      if (reciprocal) {
        const userOneId = Math.min(Number(req.user.sub), targetUserId);
        const userTwoId = Math.max(Number(req.user.sub), targetUserId);
        const [row] = await Match.findOrCreate({
          where: { userOneId, userTwoId },
          defaults: { userOneId, userTwoId, matchedAt: new Date() },
        });
        match = {
          matched: true,
          matchId: String(row.id),
          matchedProfile: profileData(req, target, target.OnboardingProfile, viewer),
        };
      }
    }
    return success(res, 'Swipe saved.', {
      action: req.body.action,
      targetUserId: String(targetUserId),
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

exports.boost = async (req, res, next) => {
  try {
    const viewer = await requireCompleted(res, req.user.sub);
    if (!viewer) return;
    const { Boost } = getModels();
    const now = new Date();
    const active = await Boost.findOne({
      where: { userId: req.user.sub, active: true, expiresAt: { [Op.gt]: now } },
      order: [['expiresAt', 'DESC']],
    });
    if (active) {
      return success(res, 'Boost is already active.', {
        active: true,
        startedAt: active.startedAt,
        expiresAt: active.expiresAt,
        remainingSeconds: Math.max(0, Math.ceil((new Date(active.expiresAt).getTime() - now.getTime()) / 1000)),
      });
    }
    await Boost.update({ active: false }, { where: { userId: req.user.sub, active: true } });
    const expiresAt = new Date(now.getTime() + 30 * 60 * 1000);
    const boost = await Boost.create({ userId: req.user.sub, startedAt: now, expiresAt, active: true });
    // TODO(monetization): require a verified entitlement before activation in the monetization phase.
    return success(res, 'Boost activated.', {
      active: true,
      startedAt: boost.startedAt,
      expiresAt: boost.expiresAt,
      remainingSeconds: 1800,
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
    const { DiscoverFilterPreference } = getModels();
    const values = {};
    for (const key of Object.keys(defaults)) {
      if (Object.prototype.hasOwnProperty.call(req.body, key)) values[key] = filters[key];
    }
    await DiscoverFilterPreference.upsert({ userId: req.user.sub, ...values });
    return success(res, 'Discover filters updated.', { filters: await filtersFor(req.user.sub) });
  } catch (error) {
    return next(error);
  }
};

exports._test = { buildProfileWhere, compatibilityScoreSql };
