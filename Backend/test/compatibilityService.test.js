const assert = require('node:assert/strict');
const { test } = require('node:test');
const { compatibilityFor } = require('../src/services/compatibilityService');

test('compatibility explanation is deterministic, factual, and explicitly non-AI', () => {
  const viewer = {
    relationshipGoals: ['long_term'], interests: ['music', 'hiking'], languages: ['Gujarati'],
    valuedQualities: ['kindness'], communicationStyle: 'calls', lifestyle: { Exercise: 'Often' },
  };
  const candidate = {
    relationshipGoals: ['long_term'], interests: ['music', 'travel'], languages: ['Gujarati'],
    valuedQualities: ['kindness'], communicationStyle: 'calls', lifestyle: { Exercise: 'Often' },
  };
  const first = compatibilityFor(viewer, candidate);
  const second = compatibilityFor(viewer, candidate);
  assert.deepEqual(first, second);
  assert.equal(first.method, 'deterministic_explainable_v1');
  assert.ok(first.reasons.some((reason) => reason.factor === 'relationship_goal'));
  assert.ok(first.reasons.some((reason) => reason.label === 'You share 1 interest'));
  assert.match(first.disclaimer, /deterministic/i);
  assert.doesNotMatch(JSON.stringify(first), /AI-powered|emotional compatibility|conversation chemistry/i);
});
