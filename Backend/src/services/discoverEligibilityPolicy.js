const { Op, col, fn, where, literal } = require('sequelize');
const { DISCOVER_FILTER_RANGES } = require('../constants/discoverFilterRanges');

const ACCOUNT_STATUS = Object.freeze({ eligible: 'active', ineligible: ['deactivated', 'deleted'] });
const EXCLUDING_DISCOVER_ACTIONS = Object.freeze(['pass', 'like', 'superLike']);
const NON_EXCLUDING_RELATIONSHIPS = Object.freeze(['rose', 'save', 'report']);
const UNIVERSAL_INTEREST_TOKENS = Object.freeze(['everyone', 'all', 'any', 'both']);
const VALID_GENDERS = Object.freeze(['male', 'female', 'other']);
const EVENT_REGISTRATION_STATUSES = Object.freeze(['registered']);
const DEFAULT_RECENT_ACTIVITY_WINDOW_MINUTES = 5;

const SURFACES = Object.freeze({
  recommended: Object.freeze({ supported: true, behavior: 'standard_discover' }),
  high_compatibility: Object.freeze({ supported: true, behavior: 'compatibility_ranked' }),
  near_you: Object.freeze({ supported: true, behavior: 'distance_ranked' }),
  similar_interests: Object.freeze({ supported: false, reservedFor: 'future_surface_ranking' }),
  new_here: Object.freeze({ supported: false, reservedFor: 'future_surface_ranking' }),
  recently_active: Object.freeze({ supported: false, reservedFor: 'future_surface_ranking' }),
});

const HARD_FILTERS = Object.freeze([
  'minAge', 'maxAge', 'minHeight', 'city', 'datingIntentions', 'sexuality',
  'education', 'profession', 'community', 'religion', 'smoking', 'drinking',
  'weed', 'languages', 'pronouns', 'qualities', 'preferredTalkingHours',
  'loveLanguages', 'lifestyleTags', 'communicationStyles', 'hasPrompts',
  'verifiedOnly', 'onlineNow', 'hasEventInterest', 'minScore', 'maxDistanceKm',
]);

function normalizedString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function comparisonString(value) {
  return normalizedString(value).toLowerCase();
}

function normalizedStringList(value) {
  const source = Array.isArray(value)
    ? value
    : typeof value === 'string'
      ? value.split(',')
      : [];
  const result = [];
  const seen = new Set();
  for (const item of source) {
    const canonical = normalizedString(item);
    const key = canonical.toLowerCase();
    if (!canonical || seen.has(key)) continue;
    seen.add(key);
    result.push(canonical);
  }
  return result;
}

function usableStringList(value) {
  return normalizedStringList(value).filter((item) => comparisonString(item) !== 'prefer not to say');
}

function ageFor(birthDate, now = new Date()) {
  if (!birthDate) return null;
  const birth = new Date(`${birthDate}T00:00:00.000Z`);
  if (Number.isNaN(birth.getTime()) || birth > now) return null;
  let age = now.getUTCFullYear() - birth.getUTCFullYear();
  if (now.getUTCMonth() < birth.getUTCMonth()
    || (now.getUTCMonth() === birth.getUTCMonth() && now.getUTCDate() < birth.getUTCDate())) age -= 1;
  return age;
}

function boundedInteger(value, range, fallback) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return fallback;
  return Math.min(range.max, Math.max(range.min, Math.round(numeric)));
}

function normalizeStoredFilterRanges(values = {}, fallbacks = {}) {
  const normalized = { ...values };
  normalized.minAge = boundedInteger(values.minAge, DISCOVER_FILTER_RANGES.age, fallbacks.minAge);
  normalized.maxAge = boundedInteger(values.maxAge, DISCOVER_FILTER_RANGES.age, fallbacks.maxAge);
  if (normalized.minAge > normalized.maxAge) {
    normalized.minAge = fallbacks.minAge;
    normalized.maxAge = fallbacks.maxAge;
  }
  normalized.maxDistanceKm = boundedInteger(
    values.maxDistanceKm,
    DISCOVER_FILTER_RANGES.distanceKm,
    fallbacks.maxDistanceKm,
  );
  normalized.minScore = boundedInteger(values.minScore, DISCOVER_FILTER_RANGES.score, fallbacks.minScore);
  if (values.minHeight == null || values.minHeight === '') {
    normalized.minHeight = null;
  } else {
    normalized.minHeight = boundedInteger(
      values.minHeight,
      DISCOVER_FILTER_RANGES.heightCm,
      fallbacks.minHeight,
    );
  }
  return normalized;
}

function reciprocalEligibilitySqlClauses(sequelize, {
  viewerAge,
  viewerMaxDistanceKm,
  distanceSql = null,
  preferenceDefaults,
  preferenceTableName,
} = {}) {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const table = quote(preferenceTableName);
  const candidateId = `${quote('User')}.${quote('id')}`;
  const raw = (field) => `(SELECT ${quote(`reciprocalPreference_${field}`)}.${quote(field)} FROM ${table} AS ${quote(`reciprocalPreference_${field}`)} WHERE ${quote(`reciprocalPreference_${field}`)}.${quote('userId')} = ${candidateId} LIMIT 1)`;
  const bounded = (field, range, fallback) => {
    const value = raw(field);
    return `LEAST(${range.max}, GREATEST(${range.min}, ROUND(COALESCE(${value}, ${sequelize.escape(fallback)}))))`;
  };
  const candidateMinAge = bounded('minAge', DISCOVER_FILTER_RANGES.age, preferenceDefaults.minAge);
  const candidateMaxAge = bounded('maxAge', DISCOVER_FILTER_RANGES.age, preferenceDefaults.maxAge);
  const effectiveMinAge = `(CASE WHEN ${candidateMinAge} <= ${candidateMaxAge} THEN ${candidateMinAge} ELSE ${sequelize.escape(preferenceDefaults.minAge)} END)`;
  const effectiveMaxAge = `(CASE WHEN ${candidateMinAge} <= ${candidateMaxAge} THEN ${candidateMaxAge} ELSE ${sequelize.escape(preferenceDefaults.maxAge)} END)`;
  const clauses = [literal(`${sequelize.escape(viewerAge)} BETWEEN ${effectiveMinAge} AND ${effectiveMaxAge}`)];

  if (distanceSql) {
    const candidateMaxDistance = bounded(
      'maxDistanceKm',
      DISCOVER_FILTER_RANGES.distanceKm,
      preferenceDefaults.maxDistanceKm,
    );
    clauses.push(literal(`${distanceSql} <= LEAST(${sequelize.escape(viewerMaxDistanceKm)}, ${candidateMaxDistance})`));
  }
  return clauses;
}

function profileCompletionErrors(profile, { requireStoredFlags = true, now = new Date() } = {}) {
  const missing = [];
  const age = ageFor(profile?.birthDate, now);
  if (age == null || age < DISCOVER_FILTER_RANGES.age.min) missing.push('birthDate');
  if (!VALID_GENDERS.includes(comparisonString(profile?.gender))) missing.push('gender');
  if (!usableStringList(profile?.interestedIn).length) missing.push('interestedIn');
  if (!usableStringList(profile?.relationshipGoals).length) missing.push('relationshipGoals');
  if (!normalizedString(profile?.city)) missing.push('city');
  if (usableStringList(profile?.photos).length < 2) missing.push('photos');
  if (requireStoredFlags && profile?.onboardingCompleted !== true) missing.push('onboardingCompleted');
  if (requireStoredFlags && profile?.stage !== 'complete') missing.push('stage');
  return [...new Set(missing)];
}

function isDiscoverComplete(profile, options) {
  return profileCompletionErrors(profile, options).length === 0;
}

function genderVariants(value) {
  const gender = comparisonString(value);
  if (['woman', 'women', 'female'].includes(gender)) return ['female', 'woman', 'women'];
  if (['man', 'men', 'male'].includes(gender)) return ['male', 'man', 'men'];
  if (['other', 'non-binary', 'nonbinary', 'transgender', 'custom'].includes(gender)) {
    return ['other', 'non-binary', 'nonbinary', 'transgender', 'custom'];
  }
  return gender ? [gender] : [];
}

function interestedInVariants(value) {
  const result = new Set();
  for (const item of normalizedStringList(value).map(comparisonString)) {
    result.add(item);
    genderVariants(item).forEach((variant) => result.add(variant));
  }
  return [...result];
}

function viewerAcceptsCandidate(viewerInterestedIn, candidateGender) {
  const preferences = normalizedStringList(viewerInterestedIn).map(comparisonString);
  if (!preferences.length || preferences.some((item) => UNIVERSAL_INTEREST_TOKENS.includes(item))) return true;
  const accepted = new Set(interestedInVariants(preferences));
  return genderVariants(candidateGender).some((variant) => accepted.has(variant));
}

function candidateAcceptsViewer(candidateInterestedIn, viewerGender) {
  const preferences = normalizedStringList(candidateInterestedIn).map(comparisonString);
  if (!preferences.length || preferences.some((item) => UNIVERSAL_INTEREST_TOKENS.includes(item))) return true;
  const accepted = new Set(interestedInVariants(preferences));
  return genderVariants(viewerGender).some((variant) => accepted.has(variant));
}

function jsonContainsAny(columnName, values) {
  return normalizedStringList(values).map((value) => where(
    fn('JSON_CONTAINS', fn('LOWER', col(`OnboardingProfile.${columnName}`)), JSON.stringify(value.toLowerCase())),
    1,
  ));
}

function reciprocalPreferenceClauses(viewer) {
  const clauses = [];
  const interestedIn = normalizedStringList(viewer?.interestedIn).map(comparisonString);
  const viewerGender = comparisonString(viewer?.gender);

  if (interestedIn.length && !interestedIn.some((item) => UNIVERSAL_INTEREST_TOKENS.includes(item))) {
    const targetGenders = interestedInVariants(interestedIn);
    if (targetGenders.length) clauses.push(where(fn('LOWER', col('OnboardingProfile.gender')), { [Op.in]: targetGenders }));
  }

  if (viewerGender) {
    const reciprocalMatches = genderVariants(viewerGender).flatMap((gender) => jsonContainsAny('interestedIn', [gender]));
    const universalMatches = jsonContainsAny('interestedIn', UNIVERSAL_INTEREST_TOKENS);
    clauses.push({ [Op.or]: [
      where(col('OnboardingProfile.interestedIn'), null),
      where(fn('JSON_LENGTH', col('OnboardingProfile.interestedIn')), null),
      where(fn('JSON_LENGTH', col('OnboardingProfile.interestedIn')), 0),
      ...reciprocalMatches,
      ...universalMatches,
    ] });
  }
  return clauses;
}

function profileCompletionSqlClauses(sequelize) {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const column = (name) => `${quote('OnboardingProfile')}.${quote(name)}`;
  // MariaDB in this repository does not support MySQL JSON_TABLE syntax.
  // Bounded indexed extraction remains a single SQL query and covers the
  // API's maximum list sizes without loading candidates for JS filtering.
  const usableArrayCount = (name, maximumItems) => {
    const source = column(name);
    const terms = Array.from({ length: maximumItems }, (_, index) => {
      const value = `LOWER(TRIM(JSON_UNQUOTE(JSON_EXTRACT(${source}, '$[${index}]'))))`;
      return `CASE WHEN ${value} IS NOT NULL AND ${value} NOT IN ('', 'prefer not to say', 'null') THEN 1 ELSE 0 END`;
    });
    return literal(`(${terms.join(' + ')})`);
  };
  return [
    where(fn('LOWER', fn('TRIM', col('OnboardingProfile.gender'))), { [Op.in]: VALID_GENDERS }),
    where(fn('TRIM', col('OnboardingProfile.city')), { [Op.ne]: '' }),
    where(usableArrayCount('interestedIn', 30), { [Op.gte]: 1 }),
    where(usableArrayCount('relationshipGoals', 30), { [Op.gte]: 1 }),
    where(usableArrayCount('photos', 6), { [Op.gte]: 2 }),
  ];
}

function recentActivityWindowMinutes(value) {
  const parsed = Number(value ?? process.env.ONLINE_NOW_WINDOW_MINUTES ?? DEFAULT_RECENT_ACTIVITY_WINDOW_MINUTES);
  return Number.isFinite(parsed) ? Math.max(1, Math.round(parsed)) : DEFAULT_RECENT_ACTIVITY_WINDOW_MINUTES;
}

function isRecentlyActive(lastActiveAt, { windowMinutes = DEFAULT_RECENT_ACTIVITY_WINDOW_MINUTES, now = new Date() } = {}) {
  if (!lastActiveAt) return false;
  const activity = new Date(lastActiveAt);
  if (Number.isNaN(activity.getTime())) return false;
  return activity >= new Date(now.getTime() - recentActivityWindowMinutes(windowMinutes) * 60 * 1000);
}

function surfaceContract(surface, { aiMatches = false } = {}) {
  const name = aiMatches ? 'high_compatibility' : (normalizedString(surface) || 'recommended');
  return { name, ...(SURFACES[name] || { supported: false, reservedFor: 'unknown' }) };
}

module.exports = {
  ACCOUNT_STATUS,
  DEFAULT_RECENT_ACTIVITY_WINDOW_MINUTES,
  EVENT_REGISTRATION_STATUSES,
  EXCLUDING_DISCOVER_ACTIONS,
  HARD_FILTERS,
  NON_EXCLUDING_RELATIONSHIPS,
  SURFACES,
  UNIVERSAL_INTEREST_TOKENS,
  VALID_GENDERS,
  ageFor,
  boundedInteger,
  candidateAcceptsViewer,
  comparisonString,
  genderVariants,
  interestedInVariants,
  isDiscoverComplete,
  isRecentlyActive,
  jsonContainsAny,
  normalizedString,
  normalizedStringList,
  normalizeStoredFilterRanges,
  profileCompletionErrors,
  profileCompletionSqlClauses,
  recentActivityWindowMinutes,
  reciprocalPreferenceClauses,
  reciprocalEligibilitySqlClauses,
  surfaceContract,
  usableStringList,
  viewerAcceptsCandidate,
};
