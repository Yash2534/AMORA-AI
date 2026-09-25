const assert = require('node:assert/strict');
const { test } = require('node:test');
const { MATCH_ENGINE_VERSION, SCORE_WEIGHTS, scoreCompatibility, compatibilityReasons } = require('../src/services/matchEngineService');

const viewer = { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls' };

test('all optional-factor subsets stay bounded, symmetric and deterministic', () => {
  const full = { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls', languages: ['English'], city: 'Pune', smoking: 'never', drinking: 'never', weed: 'never' };
  const keys = Object.keys(SCORE_WEIGHTS);
  for (let mask = 0; mask < 256; mask++) {
    const candidate = Object.fromEntries(keys.filter((_, index) => mask & (1 << index)).map((key) => [key, full[key]]));
    const result = scoreCompatibility(full, candidate);
    assert.deepEqual(result, scoreCompatibility(full, candidate));
    assert.equal(result.score, scoreCompatibility(candidate, full).score);
    const weight = keys.filter((_, index) => mask & (1 << index)).reduce((sum, key) => sum + SCORE_WEIGHTS[key], 0);
    assert.equal(result.coverage, weight);
    assert.equal(result.score, Math.round(50 + weight / 2));
    for (const value of [result.score, result.rawScore, result.coverage]) assert.ok(Number.isFinite(value) && value >= 0 && value <= 100);
  }
});

test('malformed and declined values never become fake shared evidence', () => {
  for (const value of [null, undefined, 7, NaN, Infinity, {}, [null, undefined, 7, {}, '', '  ', 'Prefer not to say']]) {
    const malformed = Object.fromEntries(Object.keys(SCORE_WEIGHTS).map((key) => [key, value]));
    const result = scoreCompatibility(malformed, malformed);
    assert.equal(result.coverage, 0);
    assert.equal(result.score, 50);
    assert.deepEqual(compatibilityReasons(malformed, malformed), []);
  }
  assert.equal(scoreCompatibility(null, null).score, 50);
});

test('factor contributions reconstruct the score and partition available/missing evidence', () => {
  const result = scoreCompatibility(viewer, { interests: ['MUSIC', 'music', ' hiking '], relationshipGoals: ['friendship'] });
  assert.equal(result.factorBreakdown.interests.value, 1);
  assert.equal(result.factorBreakdown.interests.contribution, 35);
  assert.equal(result.factorBreakdown.relationshipGoals.netContribution, -12.5);
  assert.equal(result.score, Math.round(50 + result.factors.reduce((sum, f) => sum + f.netContribution, 0)));
  assert.deepEqual(result.positiveFactors.map((f) => f.key), ['interests']);
  assert.deepEqual(result.negativeFactors.map((f) => f.key), ['relationshipGoals']);
  assert.equal(result.neutralFactors.length, 6);
});

test('deterministic seed known examples retain their certified compatibility scores', () => {
  const { buildSeedBlueprint } = require('../scripts/dummy-seed/factory');
  const { users } = buildSeedBlueprint({ randomSeed: 12345, userCount: 40, referenceDate: new Date('2026-08-29T12:00:00Z') });
  for (const [name, expected] of Object.entries({ 'Dhruv Shah': 92, 'Rhea Patel': 87, 'Kabir Menon': 62, 'Jay Shah': 53, 'Naina Rao': 48 })) {
    assert.equal(scoreCompatibility(users[0], users.find((user) => user.name === name)).score, expected, name);
  }
  const sparse = users.find((user) => !user.completed);
  assert.equal(scoreCompatibility(users[0], sparse).coverage, 85);
});

test('match engine score is deterministic, bounded, and centrally weighted', () => {
  const candidate = { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls' };
  const first = scoreCompatibility(viewer, candidate);
  assert.deepEqual(first, scoreCompatibility(viewer, candidate));
  assert.equal(first.score, 85);
  assert.equal(MATCH_ENGINE_VERSION, 'v2');
  assert.deepEqual(SCORE_WEIGHTS, { interests: 35, relationshipGoals: 25, communicationStyle: 10, languages: 10, city: 5, smoking: 5, drinking: 5, weed: 5 });
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
  assert.equal(missing.score, 63);
  assert.equal(scoreCompatibility({ interests: [] }, { interests: [] }).score, 50);
});

test('coverage calibrates sparse matches below equally perfect rich matches', () => {
  const rich = scoreCompatibility(viewer, { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls', languages: ['English'], city: 'Ahmedabad', smoking: 'never', drinking: 'never', weed: 'never' });
  const richViewer = { ...viewer, languages: ['English'], city: 'Ahmedabad', smoking: 'never', drinking: 'never', weed: 'never' };
  const sparse = scoreCompatibility(richViewer, { relationshipGoals: ['long_term'] });
  const complete = scoreCompatibility(richViewer, { ...richViewer });
  assert.ok(sparse.score > 50 && sparse.score < complete.score);
  assert.ok(sparse.coverage < complete.coverage);
  assert.equal(scoreCompatibility({}, {}).score, 50);
  assert.ok(rich.score >= 0 && rich.score <= 100);
});

test('structured lifestyle, language and city factors are bounded and factual', () => {
  const aligned = scoreCompatibility({ languages: ['English'], city: 'Ahmedabad', smoking: 'never', drinking: 'never', weed: 'never' }, { languages: ['English'], city: 'Ahmedabad', smoking: 'never', drinking: 'never', weed: 'never' });
  const mismatch = scoreCompatibility({ languages: ['English'], city: 'Ahmedabad', smoking: 'never' }, { languages: ['Hindi'], city: 'Surat', smoking: 'often' });
  assert.ok(aligned.score > mismatch.score);
  assert.ok(compatibilityReasons({ city: 'Ahmedabad', smoking: 'never' }, { city: 'Ahmedabad', smoking: 'never' }).includes('Same city'));
});

test('compatibility reasons are factual and contain no AI claims', () => {
  const reasons = compatibilityReasons(viewer, { interests: ['music'], relationshipGoals: ['long_term'], communicationStyle: 'calls' });
  assert.deepEqual(reasons, ['1 shared interest', 'Both prefer the same relationship goal', 'Compatible communication styles']);
  assert.doesNotMatch(reasons.join(' '), /AI|soulmate|destiny|guarantee/i);
});
