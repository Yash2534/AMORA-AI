const assert = require('node:assert/strict');
const { test } = require('node:test');
const { SCORE_WEIGHTS, scoreCompatibility, compatibilityReasons } = require('../src/services/matchEngineService');

const viewer = { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls' };

test('match engine score is deterministic, bounded, and centrally weighted', () => {
  const candidate = { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls' };
  const first = scoreCompatibility(viewer, candidate);
  assert.deepEqual(first, scoreCompatibility(viewer, candidate));
  assert.equal(first.score, 100);
  assert.deepEqual(SCORE_WEIGHTS, { interests: 55, relationshipGoals: 30, communicationStyle: 15 });
  assert.ok(first.score >= 0 && first.score <= 100);
});

test('shared interests and communication style affect the deterministic score', () => {
  const aligned = scoreCompatibility(viewer, { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls' }).score;
  const partial = scoreCompatibility(viewer, { interests: ['music', 'travel'], relationshipGoals: ['long_term'], communicationStyle: 'texts' }).score;
  assert.ok(aligned > partial);
});

test('missing optional data is normalised over comparable factors', () => {
  const missing = scoreCompatibility(viewer, { interests: [], relationshipGoals: ['long_term'], communicationStyle: null });
  assert.equal(missing.availableWeight, SCORE_WEIGHTS.relationshipGoals);
  assert.equal(missing.score, 100);
  assert.equal(scoreCompatibility({ interests: [] }, { interests: [] }).score, 0);
});

test('compatibility reasons are factual and contain no AI claims', () => {
  const reasons = compatibilityReasons(viewer, { interests: ['music'], relationshipGoals: ['long_term'], communicationStyle: 'calls' });
  assert.deepEqual(reasons, ['1 shared interest', 'Both prefer the same relationship goal', 'Compatible communication styles']);
  assert.doesNotMatch(reasons.join(' '), /AI|soulmate|destiny|guarantee/i);
});
