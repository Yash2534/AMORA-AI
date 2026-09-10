const assert = require('node:assert/strict');
const { test } = require('node:test');
const { MATCH_ENGINE_VERSION, SCORE_WEIGHTS, scoreCompatibility, compatibilityReasons } = require('../src/services/matchEngineService');

const viewer = { interests: ['music', 'hiking'], relationshipGoals: ['long_term'], communicationStyle: 'calls' };

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
