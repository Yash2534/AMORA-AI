const assert = require('node:assert/strict');
const { test } = require('node:test');
const { localAiMatch, rankCandidates, PROVIDER } = require('../src/services/aiMatchProvider');

const viewer = { interests: ['travel', 'fitness'], relationshipGoals: ['long term'], communicationStyle: 'direct', languages: ['English'], city: 'Pune', smoking: 'never', drinking: 'occasionally', weed: 'never' };

test('confidence measures coverage and support separately from compatibility', () => {
  const full = localAiMatch(viewer, viewer);
  const sparse = localAiMatch(viewer, { interests: viewer.interests });
  const missing = localAiMatch({}, {});
  const mismatch = localAiMatch(viewer, { interests: ['other'], relationshipGoals: ['friendship'], communicationStyle: 'calls', languages: ['Hindi'], city: 'Delhi', smoking: 'often', drinking: 'never', weed: 'often' });
  assert.equal(full.aiConfidence, 100);
  assert.equal(sparse.aiConfidence, 35);
  assert.equal(missing.aiConfidence, 0);
  assert.equal(mismatch.aiConfidence, 80); // Complete contradictory data is still evidence.
  assert.equal(mismatch.aiMatchScore, 4);
  assert.notEqual(sparse.aiConfidence, sparse.aiMatchScore);
  assert.deepEqual(sparse, localAiMatch(viewer, { interests: viewer.interests }));
});

test('reasons use actual shared values, prioritize goals/style and never fabricate overlap', () => {
  const profile = { ...viewer, communicationStyle: 'calls' };
  const full = localAiMatch(profile, profile);
  assert.deepEqual(full.aiReasons, [
    'You share a relationship goal: long term.', 'You both prefer calls.',
    'You share 2 interests, including fitness, travel.',
  ]);
  const partial = localAiMatch(profile, { interests: ['travel', 'cooking'], languages: ['English'] });
  assert.deepEqual(partial.aiReasons, ['You share 1 interest, including travel.', 'You both speak english.']);
  assert.deepEqual(localAiMatch(profile, {}).aiReasons, ['Explore this profile to learn more about each other.']);
  assert.deepEqual(full.aiReasons, localAiMatch(profile, { ...profile, interests: ['fitness', 'travel', 'TRAVEL'] }).aiReasons);
});

test('private account data and unsupported factors never enter public explanations', () => {
  const { scoreCompatibility } = require('../src/services/matchEngineService');
  const base = scoreCompatibility(viewer, viewer);
  base.factors.push({ key: 'privatePreferences', available: true, weight: 999, value: 1, shared: ['SECRET'] });
  const result = localAiMatch({ ...viewer, privatePreferences: 'SECRET' }, { ...viewer, passwordHash: 'SECRET', moderationEvidence: 'SECRET', bio: 'SECRET' }, base);
  assert.doesNotMatch(JSON.stringify(result), /SECRET|password|moderation|privatePreferences|factorBreakdown/);
  assert.ok(result.aiHighlights.every((h) => typeof h.label === 'string'));
  assert.ok(result.aiReasons.length <= 3);
});

test('missing or malformed factor evidence cannot produce false certainty or invalid numbers', () => {
  for (const score of [NaN, Infinity, undefined, -99, 900]) {
    const result = localAiMatch({}, {}, { score, coverage: 100, factors: [] });
    assert.equal(result.aiConfidence, 0);
    assert.ok(Number.isFinite(result.aiMatchScore) && result.aiMatchScore >= 0 && result.aiMatchScore <= 100);
  }
  assert.equal(localAiMatch({}, {}, { score: 50, factors: [{ key: 'interests', available: true, value: NaN }] }).aiConfidence, 0);
});

test('ranking uses complete-set relevance, evidence ties and numeric IDs without randomness', () => {
  const candidates = [{ userId: 10, profile: viewer }, { userId: 2, profile: viewer }, { userId: 1, profile: {} }];
  const first = rankCandidates(viewer, candidates);
  assert.deepEqual(first.map((row) => row.userId), [2, 10, 1]);
  assert.deepEqual(first, rankCandidates(viewer, [...candidates].reverse()));
});

test('LOCAL AI provider is deterministic, bounded, and uses only structured compatibility data', () => {
  const candidate = { interests: ['travel', 'fitness'], relationshipGoals: ['long term'], communicationStyle: 'direct', languages: ['English'], city: 'Pune', smoking: 'never', drinking: 'occasionally', weed: 'never', email: 'must-not-be-used@example.invalid', bio: 'private text' };
  const first = localAiMatch(viewer, candidate); const second = localAiMatch(viewer, candidate);
  assert.deepEqual(first, second); assert.equal(first.provider, PROVIDER); assert.ok(first.aiMatchScore >= 0 && first.aiMatchScore <= 100); assert.ok(first.aiConfidence >= 0 && first.aiConfidence <= 100); assert.ok(first.aiHighlights.length <= 3); assert.equal(JSON.stringify(first).includes('private text'), false);
});

test('LOCAL AI provider keeps sparse comparisons neutral and uses a stable candidate-id tie breaker', () => {
  const sparse = localAiMatch({}, {}); assert.ok(sparse.aiMatchScore >= 45 && sparse.aiMatchScore <= 55); assert.equal(sparse.aiConfidence, 0);
  const ranked = rankCandidates({}, [{ userId: 9, profile: {} }, { userId: 2, profile: {} }]); assert.deepEqual(ranked.map((item) => item.userId), [2, 9]);
});
