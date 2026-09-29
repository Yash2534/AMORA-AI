const assert = require('node:assert/strict');
const { test } = require('node:test');

require('../src/config/bootstrapEnv');

const {
  MATCH_RANKING_VERSION,
  RecommendationCursorError,
  contextFingerprint,
  createCursor,
  readCursor,
} = require('../src/services/recommendationCursorService');

test('recommendation cursor is opaque, signed, deterministic, and context-bound', () => {
  const context = { filters: { minAge: 18, city: '' }, viewer: { gender: 'female' } };
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: { score: 91, id: 42 } });
  assert.equal(cursor.includes('91'), false);
  assert.deepEqual(readCursor(cursor, { viewerId: 7, surface: 'default', context }), { id: 42, score: 91 });
  assert.equal(contextFingerprint({ b: 2, a: 1 }), contextFingerprint({ a: 1, b: 2 }));
  assert.equal(typeof MATCH_RANKING_VERSION, 'string');

  for (const attempt of [
    () => readCursor(`${cursor.slice(0, -1)}x`, { viewerId: 7, surface: 'default', context }),
    () => readCursor(cursor, { viewerId: 8, surface: 'default', context }),
    () => readCursor(cursor, { viewerId: 7, surface: 'near_you', context }),
  ]) assert.throws(attempt, RecommendationCursorError);

  assert.throws(
    () => readCursor(cursor, { viewerId: 7, surface: 'default', context: { ...context, filters: { minAge: 19 } } }),
    (error) => error instanceof RecommendationCursorError && error.code === 'PAGINATION_CONTEXT_CHANGED',
  );
});
