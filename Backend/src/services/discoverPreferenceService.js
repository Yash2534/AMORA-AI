const { getModels } = require('../models');
const { parseCommunicationStyles } = require('../constants/communicationStyles');

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
  'hometown', 'datingIntentions', 'lifestyleTags', 'languages', 'pronouns',
  'qualities', 'preferredTalkingHours', 'loveLanguages', 'communicationStyles',
]);

async function filtersFor(userId, overrides = {}) {
  const { DiscoverFilterPreference } = getModels();
  const runtime = await require('./adminDiscoverConfigurationService').runtimeConfiguration();
  const { onlineWindowMinutes: _onlineWindowMinutes, ...runtimePreferenceDefaults } = runtime.defaults;
  const effectiveDefaults = { ...defaults, ...runtimePreferenceDefaults };
  const [stored] = await DiscoverFilterPreference.findOrCreate({
    where: { userId },
    defaults: { userId, ...effectiveDefaults },
  });
  const values = { ...effectiveDefaults, ...stored.toJSON() };
  for (const key of Object.keys(effectiveDefaults)) {
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
  for (const key of Object.keys(effectiveDefaults)) if (!runtime.enabledFilters.has(key)) values[key] = effectiveDefaults[key];
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

module.exports = { defaults, filtersFor, updateFilters };
