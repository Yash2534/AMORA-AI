const COMMUNICATION_STYLE_VALUES = Object.freeze([
  'frequent_texting',
  'occasional_texting',
  'calls',
  'voice_notes',
  'deep_conversations',
  'light_fun_conversations',
]);

const communicationStyleSet = new Set(COMMUNICATION_STYLE_VALUES);

function parseCommunicationStyles(value) {
  if (value === undefined || value === null || value === '') return [];
  const source = Array.isArray(value)
    ? value
    : typeof value === 'string'
      ? value.split(',')
      : null;
  if (!source || source.some((item) => typeof item !== 'string')) return null;
  return [...new Set(source.map((item) => item.trim()).filter(Boolean))];
}

function hasOnlyCommunicationStyles(value) {
  const parsed = parseCommunicationStyles(value);
  return parsed !== null && parsed.every((style) => communicationStyleSet.has(style));
}

module.exports = {
  COMMUNICATION_STYLE_VALUES,
  hasOnlyCommunicationStyles,
  parseCommunicationStyles,
};
