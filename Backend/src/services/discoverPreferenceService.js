const { getModels } = require('../models');
const { parseCommunicationStyles } = require('../constants/communicationStyles');
const { DISCOVER_FILTER_RANGES } = require('../constants/discoverFilterRanges');

const HARD_FILTERS = new Set(['minAge', 'maxAge', 'maxDistanceKm', 'blockedUsers', 'reportedUsers', 'verifiedOnly']);

const defaults = {
  minAge: 18,
  maxAge: 45,
  maxDistanceKm: 80,
  minScore: 0,
  city: '',
  minHeight: null,
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
  'hometown', 'datingIntentions', 'lifestyleTags', 'languages', 'pronouns',
  'qualities', 'preferredTalkingHours', 'loveLanguages', 'communicationStyles',
]);

function boundedInteger(value, range, fallback) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return fallback;
  return Math.min(range.max, Math.max(range.min, Math.round(numeric)));
}

function normalizeStoredRanges(values, fallbacks) {
  const normalized = { ...values };
  normalized.minAge = boundedInteger(
    values.minAge,
    DISCOVER_FILTER_RANGES.age,
    fallbacks.minAge,
  );
  normalized.maxAge = boundedInteger(
    values.maxAge,
    DISCOVER_FILTER_RANGES.age,
    fallbacks.maxAge,
  );
  if (normalized.minAge > normalized.maxAge) {
    normalized.minAge = fallbacks.minAge;
    normalized.maxAge = fallbacks.maxAge;
  }
  normalized.maxDistanceKm = boundedInteger(
    values.maxDistanceKm,
    DISCOVER_FILTER_RANGES.distanceKm,
    fallbacks.maxDistanceKm,
  );
  normalized.minScore = boundedInteger(
    values.minScore,
    DISCOVER_FILTER_RANGES.score,
    fallbacks.minScore,
  );
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

async function filtersFor(userId, overrides = {}) {
  const { DiscoverFilterPreference } = getModels();
  const runtime = await require('./adminDiscoverConfigurationService').runtimeConfiguration();
  const { onlineWindowMinutes: _onlineWindowMinutes, ...runtimePreferenceDefaults } = runtime.defaults;
  const effectiveDefaults = normalizeStoredRanges(
    { ...defaults, ...runtimePreferenceDefaults },
    defaults,
  );
  const [stored] = await DiscoverFilterPreference.findOrCreate({
    where: { userId },
    defaults: { userId, ...effectiveDefaults },
  });
  const values = {
    ...effectiveDefaults,
    ...normalizeStoredRanges(stored.toJSON(), effectiveDefaults),
  };
  for (const key of Object.keys(effectiveDefaults)) {
    if (overrides[key] === undefined) continue;
    if (['minAge', 'maxAge', 'maxDistanceKm', 'minScore'].includes(key)) {
      values[key] = Number(overrides[key]);
    } else if (key === 'minHeight') {
      values[key] = overrides[key] === '' || overrides[key] == null
        ? null
        : Number(overrides[key]);
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
  for (const key of Object.keys(effectiveDefaults)) if (!runtime.enabledFilters.has(key)) values[key] = effectiveDefaults[key];
  
  // Enforce strict separation: Behavioral rankers must never override hard filters.
  // We expose HARD_FILTERS separately so discoverEngine can apply them strictly.
  return Object.fromEntries(Object.keys(effectiveDefaults).map((key) => [key, values[key]]));
}

async function updateFilters(userId, body) {
  const filters = await filtersFor(userId, body);
  const { DiscoverFilterPreference } = getModels();
  const values = {};
  for (const key of Object.keys(defaults)) {
    if (Object.prototype.hasOwnProperty.call(body, key)) values[key] = filters[key];
  }
  await DiscoverFilterPreference.upsert({ userId, ...values });
  return filtersFor(userId);
}

module.exports = {
  HARD_FILTERS,
  defaults,
  filtersFor,
  updateFilters,
  _test: { boundedInteger, normalizeStoredRanges },
};
