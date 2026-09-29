const { getModels } = require('../models');
const { parseCommunicationStyles } = require('../constants/communicationStyles');
const { DISCOVER_FILTER_RANGES } = require('../constants/discoverFilterRanges');
const {
  HARD_FILTERS: POLICY_HARD_FILTERS,
  normalizeStoredFilterRanges,
  normalizedString,
  normalizedStringList,
} = require('./discoverEligibilityPolicy');

const HARD_FILTERS = new Set(POLICY_HARD_FILTERS);

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

function normalizeStoredRanges(values, fallbacks) {
  return normalizeStoredFilterRanges(values, fallbacks);
}

function effectiveDefaultsFor(runtimeDefaults = {}) {
  const { onlineWindowMinutes: _onlineWindowMinutes, ...preferenceDefaults } = runtimeDefaults;
  return normalizeStoredRanges({ ...defaults, ...preferenceDefaults }, defaults);
}

function normalizeFilterValues(values) {
  const normalized = { ...values };
  for (const key of arrayFilters) {
    normalized[key] = key === 'communicationStyles'
      ? parseCommunicationStyles(normalizedStringList(values[key]))
      : normalizedStringList(values[key]);
  }
  for (const key of ['city', 'education', 'profession', 'community', 'religion', 'sexuality', 'smoking', 'drinking', 'weed']) {
    normalized[key] = normalizedString(values[key]);
  }
  for (const key of ['verifiedOnly', 'onlineNow', 'hasPrompts', 'hasEventInterest']) {
    if (typeof values[key] === 'string') normalized[key] = values[key].trim().toLowerCase() === 'true';
    else normalized[key] = values[key] === true;
  }
  return normalized;
}

async function filtersFor(userId, overrides = {}) {
  const { DiscoverFilterPreference } = getModels();
  const runtime = await require('./adminDiscoverConfigurationService').runtimeConfiguration();
  const effectiveDefaults = effectiveDefaultsFor(runtime.defaults);
  const [stored] = await DiscoverFilterPreference.findOrCreate({
    where: { userId },
    defaults: { userId, ...effectiveDefaults },
  });
  const values = normalizeFilterValues({
    ...effectiveDefaults,
    ...normalizeStoredRanges(stored.toJSON(), effectiveDefaults),
  });
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
        : normalizedStringList(overrides[key]);
    } else {
      values[key] = normalizedString(overrides[key]);
    }
  }
  for (const key of Object.keys(effectiveDefaults)) if (!runtime.enabledFilters.has(key)) values[key] = effectiveDefaults[key];
  
  // Enforce strict separation: Behavioral rankers must never override hard filters.
  // We expose HARD_FILTERS separately so discoverEngine can apply them strictly.
  const normalizedValues = normalizeFilterValues(values);
  return Object.fromEntries(Object.keys(effectiveDefaults).map((key) => [key, normalizedValues[key]]));
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
  effectiveDefaultsFor,
  filtersFor,
  updateFilters,
  _test: { normalizeFilterValues, normalizeStoredRanges },
};
