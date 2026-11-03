const assert = require('node:assert/strict');
const { test } = require('node:test');
const crypto = require('crypto');

require('../src/config/bootstrapEnv');

const {
  CURSOR_VERSION,
  CURSOR_FORMAT_VERSION,
  DEFAULT_KID,
  MATCH_RANKING_VERSION,
  MAX_CURSOR_LENGTH,
  MAX_CURSOR_TTL_MS,
  RecommendationCursorError,
  contextFingerprint,
  createCursor,
  readCursor,
  parseEncryptionKey,
} = require('../src/services/recommendationCursorService');

const context = { filters: { minAge: 18, maxAge: 35, city: 'Ahmedabad' }, viewer: { gender: 'female' } };
const validKeys = { score: 91, id: 42, distance: 3.5 };

test('1. Successful encrypt/decrypt round trip preserves keys exactly', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  assert.equal(typeof cursor, 'string');
  const result = readCursor(cursor, { viewerId: 7, surface: 'default', context });
  assert.deepEqual(result, validKeys);
});

test('2. Ciphertext contains no plaintext IDs, scores, viewer identifiers, or surface names', () => {
  const customKeys = { score: 99.12345, id: 887766, aiScore: 88.54321, confidence: 77.12345 };
  const cursor = createCursor({ viewerId: 123456, surface: 'high_compatibility', context, keys: customKeys });
  assert.equal(cursor.includes('887766'), false, 'Candidate ID must not appear in plaintext');
  assert.equal(cursor.includes('123456'), false, 'Viewer ID must not appear in plaintext');
  assert.equal(cursor.includes('high_compatibility'), false, 'Surface name must not appear in plaintext');
  assert.equal(cursor.includes('99.12345'), false, 'Score must not appear in plaintext');
  // Also verify ciphertext decoded as utf8 does not contain JSON keys
  const decodedCiphertext = Buffer.from(cursor.split('.')[3], 'base64url').toString('utf8');
  assert.equal(decodedCiphertext.includes('"score"'), false, 'Decoded ciphertext must not contain JSON properties');
  assert.equal(decodedCiphertext.includes('"id"'), false, 'Decoded ciphertext must not contain candidate ID property');
});

test('3. Identical payloads produce different ciphertexts due to unique random IVs', () => {
  const cursor1 = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const cursor2 = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  assert.notEqual(cursor1, cursor2, 'Consecutive cursors must differ in IV and ciphertext');
  const parts1 = cursor1.split('.');
  const parts2 = cursor2.split('.');
  assert.notEqual(parts1[2], parts2[2], 'IVs must be unique');
  assert.notEqual(parts1[3], parts2[3], 'Ciphertexts must be unique');
  assert.deepEqual(readCursor(cursor1, { viewerId: 7, surface: 'default', context }), validKeys);
  assert.deepEqual(readCursor(cursor2, { viewerId: 7, surface: 'default', context }), validKeys);
});

test('4. Ciphertext tampering is rejected safely', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const parts = cursor.split('.');
  const tamperedCiphertext = parts[3].slice(0, -1) + (parts[3].endsWith('a') ? 'b' : 'a');
  const tampered = [parts[0], parts[1], parts[2], tamperedCiphertext, parts[4]].join('.');
  assert.throws(
    () => readCursor(tampered, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('5. Authentication-tag tampering is rejected safely', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const parts = cursor.split('.');
  const tamperedTag = (parts[4].endsWith('a') ? 'b' : 'a') + parts[4].slice(1);
  const tampered = [parts[0], parts[1], parts[2], parts[3], tamperedTag].join('.');
  assert.throws(
    () => readCursor(tampered, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('6. IV tampering is rejected safely', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const parts = cursor.split('.');
  const tamperedIv = parts[2].slice(0, -1) + (parts[2].endsWith('a') ? 'b' : 'a');
  const tampered = [parts[0], parts[1], tamperedIv, parts[3], parts[4]].join('.');
  assert.throws(
    () => readCursor(tampered, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('7. Cross-viewer token reuse is rejected', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  assert.throws(
    () => readCursor(cursor, { viewerId: 8, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('8. Cross-surface token reuse is rejected', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  assert.throws(
    () => readCursor(cursor, { viewerId: 7, surface: 'near_you', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('9. Context fingerprint mismatch is rejected with PAGINATION_CONTEXT_CHANGED', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  assert.throws(
    () => readCursor(cursor, { viewerId: 7, surface: 'default', context: { ...context, filters: { ...context.filters, minAge: 25 } } }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CONTEXT_CHANGED',
  );
});

test('10. Expired token is rejected with PAGINATION_CURSOR_EXPIRED', () => {
  const pastTime = Date.now() - 10000;
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys }, {
    iat: pastTime - 10000,
    exp: pastTime,
  });
  assert.throws(
    () => readCursor(cursor, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_EXPIRED',
  );
});

test('11. Future-issued token is rejected', () => {
  const futureTime = Date.now() + 5 * 60 * 1000;
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys }, {
    iat: futureTime,
    exp: futureTime + 3600000,
  });
  assert.throws(
    () => readCursor(cursor, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('12. TTL exceeding maximum permitted limit is rejected', () => {
  const now = Date.now();
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys }, {
    iat: now,
    exp: now + MAX_CURSOR_TTL_MS + 10 * 60 * 1000,
  });
  assert.throws(
    () => readCursor(cursor, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('13. Unknown encryption key identifier is rejected safely', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const parts = cursor.split('.');
  const unknownKidCursor = [parts[0], 'k99', parts[2], parts[3], parts[4]].join('.');
  assert.throws(
    () => readCursor(unknownKidCursor, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_EXPIRED',
  );
});

test('14. Key rotation supports explicitly configured previous keys', () => {
  const testKey0 = crypto.randomBytes(32).toString('hex');
  const testKey1 = crypto.randomBytes(32).toString('hex');

  const keyRing = new Map([
    ['k0', Buffer.from(testKey0, 'hex')],
    ['k1', Buffer.from(testKey1, 'hex')],
  ]);

  const oldCursor = createCursor(
    { viewerId: 7, surface: 'default', context, keys: validKeys },
    { kid: 'k0', secret: testKey0 },
  );
  assert.ok(oldCursor.startsWith('c2.k0.'));

  const decrypted = readCursor(
    oldCursor,
    { viewerId: 7, surface: 'default', context },
    { keyRing },
  );
  assert.deepEqual(decrypted, validKeys);
});

test('15. Legacy cursor rejection is safe and returns PAGINATION_CURSOR_EXPIRED', () => {
  const legacyPayload = Buffer.from(JSON.stringify({ v: 1, u: '7', s: 'default' })).toString('base64url');
  const legacyHmac = crypto.createHmac('sha256', 'some-legacy-secret').update(legacyPayload).digest('base64url');
  const legacyCursor = `${legacyPayload}.${legacyHmac}`;

  assert.throws(
    () => readCursor(legacyCursor, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_EXPIRED',
  );
});

test('16. Malformed base64url is rejected safely', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const parts = cursor.split('.');
  const malformed = [parts[0], parts[1], '??!#%', parts[3], parts[4]].join('.');
  assert.throws(
    () => readCursor(malformed, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('17. Truncated token is rejected safely', () => {
  assert.throws(
    () => readCursor('c2.k1.short', { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('18. Extra token components are rejected safely', () => {
  const cursor = createCursor({ viewerId: 7, surface: 'default', context, keys: validKeys });
  const extraParts = `${cursor}.extra_unexpected_component`;
  assert.throws(
    () => readCursor(extraParts, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('19. Invalid JSON payload is rejected safely', () => {
  const { currentKey } = require('../src/services/recommendationCursorService')._test.getKeyRing();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', currentKey, iv);
  cipher.setAAD(Buffer.from('c2:k1:7:default', 'utf8'));
  const ciphertext = Buffer.concat([cipher.update(Buffer.from('not-valid-json{{{')), cipher.final()]);
  const tag = cipher.getAuthTag();
  const badJsonCursor = `c2.k1.${iv.toString('base64url')}.${ciphertext.toString('base64url')}.${tag.toString('base64url')}`;

  assert.throws(
    () => readCursor(badJsonCursor, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('20. Invalid ranking-key schema is rejected safely', () => {
  const badKeysCursor1 = createCursor({ viewerId: 7, surface: 'default', context, keys: { id: 'invalid_id' } });
  assert.throws(
    () => readCursor(badKeysCursor1, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );

  const badKeysCursor2 = createCursor({ viewerId: 7, surface: 'default', context, keys: { id: 10, score: 105 } });
  assert.throws(
    () => readCursor(badKeysCursor2, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );

  const badKeysCursor3 = createCursor({ viewerId: 7, surface: 'default', context, keys: { id: 10, distance: -5 } });
  assert.throws(
    () => readCursor(badKeysCursor3, { viewerId: 7, surface: 'default', context }),
    (err) => err instanceof RecommendationCursorError && err.code === 'PAGINATION_CURSOR_INVALID',
  );
});

test('21. Missing encryption configuration fails safely', () => {
  assert.throws(
    () => parseEncryptionKey(''),
    (err) => err.message.includes('required'),
  );
  assert.throws(
    () => parseEncryptionKey('short_key'),
    (err) => err.message.includes('32 bytes'),
  );
});

test('22. No unhandled exceptions or sensitive error output', () => {
  const attempts = [
    null,
    undefined,
    12345,
    '',
    '.',
    '..',
    '....',
    'x'.repeat(3000),
  ];
  for (const input of attempts) {
    assert.throws(
      () => readCursor(input, { viewerId: 7, surface: 'default', context }),
      (err) => err instanceof RecommendationCursorError && !err.message.includes('secret') && !err.message.includes('key:'),
    );
  }
});
