const assert = require('node:assert/strict');
const test = require('node:test');
const { Op } = require('sequelize');

const {
  COMMUNICATION_STYLE_VALUES,
  hasOnlyCommunicationStyles,
  parseCommunicationStyles,
} = require('../src/constants/communicationStyles');
const { _test } = require('../src/controllers/discoverController');

test('communication style parser supports CSV/arrays and removes duplicates', () => {
  assert.deepEqual(parseCommunicationStyles('calls,voice_notes,calls'), [
    'calls',
    'voice_notes',
  ]);
  assert.deepEqual(parseCommunicationStyles(['calls', 'deep_conversations']), [
    'calls',
    'deep_conversations',
  ]);
  assert.equal(COMMUNICATION_STYLE_VALUES.length, 6);
});

test('invalid communication styles are rejected', () => {
  assert.equal(hasOnlyCommunicationStyles('calls,random_value'), false);
  assert.equal(hasOnlyCommunicationStyles({ calls: true }), false);
  assert.equal(hasOnlyCommunicationStyles('calls,voice_notes'), true);
});

test('empty styles leave the profile query unchanged', () => {
  assert.deepEqual(_test.buildProfileWhere({ communicationStyles: [] }), {
    onboardingCompleted: true,
  });
});

test('one or many styles use a database IN condition before pagination', () => {
  const one = _test.buildProfileWhere({ communicationStyles: ['calls'] });
  assert.deepEqual(one.communicationStyle[Op.in], ['calls']);

  const many = _test.buildProfileWhere({
    communicationStyles: ['calls', 'voice_notes'],
  });
  assert.deepEqual(many.communicationStyle[Op.in], ['calls', 'voice_notes']);
  assert.equal(many.onboardingCompleted, true);
});

test('null profile styles do not match an active filter', () => {
  const baseFilters = {
    minAge: 18,
    maxAge: 45,
    maxDistanceKm: 500,
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
    communicationStyles: ['calls', 'voice_notes'],
    smoking: '',
    drinking: '',
    weed: '',
    verifiedOnly: false,
    onlineNow: false,
    hasPrompts: false,
    hasEventInterest: false,
  };
  const viewer = { city: 'Ahmedabad' };
  const profile = {
    birthDate: '1995-01-01',
    city: 'Ahmedabad',
    communicationStyle: null,
    lifestyle: {},
  };

  assert.equal(_test.matchesFilters({}, profile, viewer, baseFilters), false);
  assert.equal(
    _test.matchesFilters(
      {},
      { ...profile, communicationStyle: 'voice_notes' },
      viewer,
      baseFilters,
    ),
    true,
  );
});
