const crypto = require('crypto');
const {
  MATCH_RANKING_VERSION,
  RECOMMENDATION_CURSOR_VERSION: CURSOR_VERSION,
} = require('./matchEngineContract');
const MAX_CURSOR_LENGTH = 2048;

class RecommendationCursorError extends Error {
  constructor(message, code = 'PAGINATION_CURSOR_INVALID') {
    super(message);
    this.name = 'RecommendationCursorError';
    this.code = code;
  }
}

function stableValue(value) {
  if (Array.isArray(value)) return value.map(stableValue);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stableValue(value[key])]));
  }
  return value;
}

function stableJson(value) {
  return JSON.stringify(stableValue(value));
}

function secret() {
  const value = process.env.JWT_SECRET;
  if (!value) throw new Error('JWT_SECRET is required for recommendation cursors.');
  return value;
}

function signature(encodedPayload) {
  return crypto.createHmac('sha256', secret()).update(encodedPayload).digest('base64url');
}

function contextFingerprint(context) {
  return crypto.createHash('sha256').update(stableJson(context)).digest('base64url');
}

function createCursor({ viewerId, surface, context, keys }) {
  const payload = Buffer.from(stableJson({
    v: CURSOR_VERSION,
    r: MATCH_RANKING_VERSION,
    u: String(viewerId),
    s: surface,
    c: contextFingerprint(context),
    k: keys,
  })).toString('base64url');
  return `${payload}.${signature(payload)}`;
}

function readCursor(cursor, { viewerId, surface, context }) {
  if (typeof cursor !== 'string' || cursor.length < 3 || cursor.length > MAX_CURSOR_LENGTH) {
    throw new RecommendationCursorError('The pagination cursor is invalid.');
  }
  const parts = cursor.split('.');
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    throw new RecommendationCursorError('The pagination cursor is invalid.');
  }
  const expected = Buffer.from(signature(parts[0]));
  const supplied = Buffer.from(parts[1]);
  if (expected.length !== supplied.length || !crypto.timingSafeEqual(expected, supplied)) {
    throw new RecommendationCursorError('The pagination cursor signature is invalid.');
  }
  let payload;
  try {
    payload = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
  } catch (_) {
    throw new RecommendationCursorError('The pagination cursor payload is invalid.');
  }
  if (payload.v !== CURSOR_VERSION || payload.r !== MATCH_RANKING_VERSION) {
    throw new RecommendationCursorError('The pagination cursor version is no longer supported.', 'PAGINATION_CURSOR_EXPIRED');
  }
  if (payload.u !== String(viewerId) || payload.s !== surface) {
    throw new RecommendationCursorError('The pagination cursor does not belong to this recommendation feed.');
  }
  if (payload.c !== contextFingerprint(context)) {
    throw new RecommendationCursorError('Recommendation filters or viewer context changed. Start again from the first page.', 'PAGINATION_CONTEXT_CHANGED');
  }
  if (!payload.k || typeof payload.k !== 'object' || Array.isArray(payload.k)) {
    throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.');
  }
  return payload.k;
}

module.exports = {
  CURSOR_VERSION,
  MATCH_RANKING_VERSION,
  MAX_CURSOR_LENGTH,
  RecommendationCursorError,
  contextFingerprint,
  createCursor,
  readCursor,
  _test: { stableJson },
};
