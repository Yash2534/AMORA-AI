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

test('profile query always enforces completion and a database age range', () => {
  const query = _test.buildProfileWhere({ communicationStyles: [] });
  assert.equal(query.onboardingCompleted, true);
  assert.match(query.birthDate[Op.gt], /^\d{4}-\d{2}-\d{2}$/);
  assert.match(query.birthDate[Op.lte], /^\d{4}-\d{2}-\d{2}$/);
});

test('one or many communication styles use a database IN condition', () => {
  const one = _test.buildProfileWhere({ communicationStyles: ['calls'] });
  assert.deepEqual(one.communicationStyle[Op.in], ['calls']);

  const many = _test.buildProfileWhere({
    communicationStyles: ['calls', 'voice_notes'],
  });
  assert.deepEqual(many.communicationStyle[Op.in], ['calls', 'voice_notes']);
  assert.equal(many.onboardingCompleted, true);
});
