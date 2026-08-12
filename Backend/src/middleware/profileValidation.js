const { body } = require('express-validator');
const { COMMUNICATION_STYLE_VALUES } = require('../constants/communicationStyles');

const allowed = new Set([
  'name', 'birthdate', 'gender', 'customGender', 'bio', 'profession', 'company', 'education',
  'location', 'datingIntention', 'interests', 'prompts', 'lifestyle',
  'hometown', 'valuedQualities', 'pronouns', 'sexuality',
  'preferredTalkingHours', 'loveLanguages', 'iceBreaker',
  'communicationStyle', 'photos', 'primaryPhotoIndex',
]);

const string = (field, max) => body(field)
  .optional()
  .isString()
  .trim()
  .isLength({ max })
  .withMessage(`${field} must be ${max} characters or less.`);

const array = (field, max) => body(field)
  .optional()
  .isArray({ max })
  .withMessage(`${field} must be an array with at most ${max} values.`)
  .custom((value) => value.every((item) => typeof item === 'string'
    && item.trim().length > 0 && item.length <= 100))
  .withMessage(`${field} contains an invalid value.`);

const profileUpdateValidation = [
  body().custom((value) => {
    if (Object.keys(value || {}).some((key) => !allowed.has(key))) {
      throw new Error('Request contains an unsupported profile field.');
    }
    return true;
  }),
  string('name', 100).notEmpty().withMessage('name cannot be empty.'),
  body('birthdate').optional().isISO8601({ strict: true }).withMessage('birthdate must be a valid ISO date.').bail().custom((value) => {
    const birthDate = new Date(`${value}T00:00:00.000Z`);
    const cutoff = new Date();
    cutoff.setUTCHours(0, 0, 0, 0);
    cutoff.setUTCFullYear(cutoff.getUTCFullYear() - 18);
    if (birthDate > cutoff) throw new Error('You must be at least 18 years old.');
    return true;
  }),
  body('gender').optional().isIn(['Male', 'Female', 'Other']).withMessage('gender must be Male, Female, or Other.'),
  string('customGender', 100),
  string('bio', 2000),
  string('profession', 255),
  string('company', 255),
  string('education', 255),
  string('location', 255),
  string('datingIntention', 100),
  array('interests', 20),
  body('prompts').optional().isObject().custom((value) => Object.entries(value).length <= 3
    && Object.entries(value).every(([question, answer]) => question.trim() && question.length <= 200
      && typeof answer === 'string' && answer.trim() && answer.length <= 180))
    .withMessage('prompts must contain at most 3 valid answers.'),
  body('lifestyle').optional().isObject().custom((value) => Object.keys(value).length <= 20
    && Object.entries(value).every(([key, item]) => key.length <= 100
      && typeof item === 'string' && item.length <= 100))
    .withMessage('lifestyle contains an invalid value.'),
  string('hometown', 255),
  array('valuedQualities', 10),
  array('pronouns', 5),
  string('sexuality', 100),
  array('preferredTalkingHours', 10),
  array('loveLanguages', 10),
  string('iceBreaker', 280),
  body('communicationStyle').optional({ nullable: true }).isIn(COMMUNICATION_STYLE_VALUES).withMessage('communicationStyle is invalid.'),
  body('photos').optional().isArray({ max: 6 }).withMessage('photos must contain at most 6 uploaded references.'),
  body('photos.*').optional().isString().isLength({ min: 1, max: 2048 }).withMessage('Each photo reference is invalid.'),
  body('primaryPhotoIndex').optional().isInt({ min: 0, max: 5 }).withMessage('primaryPhotoIndex is invalid.').toInt(),
];

module.exports = { profileUpdateValidation };
