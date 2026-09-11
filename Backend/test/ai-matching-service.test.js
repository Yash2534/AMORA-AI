const assert = require('node:assert/strict');
const { test } = require('node:test');
const { localAiMatch, rankCandidates, PROVIDER } = require('../src/services/aiMatchProvider');

const viewer = { interests: ['travel', 'fitness'], relationshipGoals: ['long term'], communicationStyle: 'direct', languages: ['English'], city: 'Pune', smoking: 'never', drinking: 'occasionally', weed: 'never' };

test('LOCAL AI provider is deterministic, bounded, and uses only structured compatibility data', () => {
  const candidate = { interests: ['travel', 'fitness'], relationshipGoals: ['long term'], communicationStyle: 'direct', languages: ['English'], city: 'Pune', smoking: 'never', drinking: 'occasionally', weed: 'never', email: 'must-not-be-used@example.invalid', bio: 'private text' };
  const first = localAiMatch(viewer, candidate); const second = localAiMatch(viewer, candidate);
  assert.deepEqual(first, second); assert.equal(first.provider, PROVIDER); assert.ok(first.aiMatchScore >= 0 && first.aiMatchScore <= 100); assert.ok(first.aiConfidence >= 0 && first.aiConfidence <= 100); assert.ok(first.aiHighlights.length <= 3); assert.equal(JSON.stringify(first).includes('private text'), false);
});

test('LOCAL AI provider keeps sparse comparisons neutral and uses a stable candidate-id tie breaker', () => {
  const sparse = localAiMatch({}, {}); assert.ok(sparse.aiMatchScore >= 45 && sparse.aiMatchScore <= 55); assert.equal(sparse.aiConfidence, 0);
  const ranked = rankCandidates({}, [{ userId: 9, profile: {} }, { userId: 2, profile: {} }]); assert.deepEqual(ranked.map((item) => item.userId), [2, 9]);
});
