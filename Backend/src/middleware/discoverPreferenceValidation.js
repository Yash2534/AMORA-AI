const { body } = require('express-validator');
const { hasOnlyCommunicationStyles, parseCommunicationStyles } = require('../constants/communicationStyles');
const { defaults } = require('../services/discoverPreferenceService');
const { DISCOVER_FILTER_RANGES } = require('../constants/discoverFilterRanges');

const optionalInt = (name, min, max) => body(name).optional({ nullable: true }).isInt({ min, max }).withMessage(`${name} must be between ${min} and ${max}.`).toInt();
const optionalArray = (name, max = 30) => body(name).optional().isArray({ max }).withMessage(`${name} must be an array with at most ${max} values.`)
  .custom((value) => value.every((item) => typeof item === 'string' && item.length <= 100)).withMessage(`${name} contains an invalid value.`);
const optionalString = (name, max = 255) => body(name).optional().isString().trim().isLength({ max }).withMessage(`${name} is invalid.`);
const optionalBoolean = (name) => body(name).optional().isBoolean().withMessage(`${name} must be a boolean.`).toBoolean();

const discoverPreferenceValidation = [
  body().custom((value) => {
    if (Object.keys(value || {}).some((key) => !Object.hasOwn(defaults, key))) {
      throw new Error('Request contains an unsupported account preference.');
    }
    return true;
  }),
  optionalInt('minAge', DISCOVER_FILTER_RANGES.age.min, DISCOVER_FILTER_RANGES.age.max),
  optionalInt('maxAge', DISCOVER_FILTER_RANGES.age.min, DISCOVER_FILTER_RANGES.age.max),
  optionalInt('maxDistanceKm', DISCOVER_FILTER_RANGES.distanceKm.min, DISCOVER_FILTER_RANGES.distanceKm.max),
  optionalInt('minScore', DISCOVER_FILTER_RANGES.score.min, DISCOVER_FILTER_RANGES.score.max),
  optionalString('city'),
  optionalInt('minHeight', DISCOVER_FILTER_RANGES.heightCm.min, DISCOVER_FILTER_RANGES.heightCm.max),
  optionalArray('hometown'),
  optionalArray('datingIntentions'),
  optionalArray('lifestyleTags'),
  optionalString('education'),
  optionalString('profession'),
  optionalString('community'),
  optionalString('religion'),
  optionalArray('languages'),
  optionalArray('pronouns'),
  optionalString('sexuality'),
  optionalArray('qualities'),
  optionalArray('preferredTalkingHours'),
  optionalArray('loveLanguages'),
  body('communicationStyles').optional().custom((value) => {
    if (!Array.isArray(value) || !hasOnlyCommunicationStyles(value)) throw new Error('communicationStyles must be an array of approved values.');
    return true;
  }).customSanitizer((value) => parseCommunicationStyles(value)),
  optionalString('smoking', 100),
  optionalString('drinking', 100),
  optionalString('weed', 100),
  optionalBoolean('verifiedOnly'),
  optionalBoolean('onlineNow'),
  optionalBoolean('hasPrompts'),
  optionalBoolean('hasEventInterest'),
];

module.exports = { discoverPreferenceValidation };
