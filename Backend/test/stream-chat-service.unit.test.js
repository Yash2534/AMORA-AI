const assert = require('node:assert/strict');
const { test } = require('node:test');
const { streamUserId, channelIdForMatch, channelDataForMatch, messageDataForAmoraMessage } = require('../src/services/streamChatService');

test('uses deterministic Stream identities and match channel IDs', () => {
  assert.equal(streamUserId(123), 'amora_user_123');
  assert.equal(channelIdForMatch(456), 'match_456');
});

test('includes the authenticated Amora user as the server-side Stream channel creator', () => {
  assert.deepEqual(channelDataForMatch({ id: 13 }, ['amora_user_49', 'amora_user_78'], 78), {
    members: ['amora_user_49', 'amora_user_78'],
    created_by_id: 'amora_user_78',
    amora_match_id: '13',
  });
});

test('publishes a single deterministic Stream message for an Amora message', () => {
  assert.deepEqual(messageDataForAmoraMessage(901, 78, 'Hello'), {
    id: 'amora_message_901',
    text: 'Hello',
    user_id: 'amora_user_78',
    amora_message_id: '901',
  });
});
