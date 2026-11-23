const crypto = require('crypto');
const {
  MATCH_RANKING_VERSION,
  RECOMMENDATION_CURSOR_VERSION: CURSOR_VERSION,
} = require('./matchEngineContract');

const MAX_CURSOR_LENGTH = 2048;
const CURSOR_FORMAT_VERSION = 'c2';
const DEFAULT_KID = 'k1';
const KEY_LENGTH_BYTES = 32;
const IV_LENGTH_BYTES = 12;
const AUTH_TAG_LENGTH_BYTES = 16;
const DEFAULT_CURSOR_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const MAX_CURSOR_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const CLOCK_SKEW_TOLERANCE_MS = 60 * 1000; // 60 seconds
const BASE64URL_REGEX = /^[A-Za-z0-9_-]+$/;

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

function contextFingerprint(context) {
  return crypto.createHash('sha256').update(stableJson(context)).digest('base64url');
}

function parseEncryptionKey(rawSecret, name = 'CURSOR_ENCRYPTION_SECRET') {
  if (!rawSecret || typeof rawSecret !== 'string') {
    throw new Error(`${name} is required and must be configured.`);
  }
  const trimmed = rawSecret.trim();
  const placeholders = new Set(['', 'changeme', 'change-me', 'your-secret', 'replace-me']);
  const env = String(process.env.NODE_ENV || 'development').toLowerCase();
  if (['production', 'staging'].includes(env) && placeholders.has(trimmed.toLowerCase())) {
    throw new Error(`${name} cannot be a placeholder in ${env}.`);
  }

  // 1. Hex encoding (64 characters -> 32 bytes)
  if (/^[0-9a-fA-F]{64}$/.test(trimmed)) {
    return Buffer.from(trimmed, 'hex');
  }

  // 2. Base64 / Base64url encoding (43 or 44 characters -> 32 bytes)
  if (/^[A-Za-z0-9+/_-]{43,44}={0,2}$/.test(trimmed)) {
    const buf = Buffer.from(trimmed, trimmed.includes('-') || trimmed.includes('_') ? 'base64url' : 'base64');
    if (buf.length === KEY_LENGTH_BYTES) return buf;
  }

  // 3. Raw 32-byte UTF-8 string
  const rawBuf = Buffer.from(trimmed, 'utf8');
  if (rawBuf.length === KEY_LENGTH_BYTES) {
    return rawBuf;
  }

  throw new Error(`${name} must be exactly 32 bytes (256 bits). Expected a 64-character hex string or 32-byte encoding.`);
}

function getKeyRing(options = {}) {
  const env = options.env || process.env;
  const currentKid = options.kid || env.CURSOR_ENCRYPTION_KID || DEFAULT_KID;
  const keys = new Map();

  // If explicit keyRing passed (e.g. in test)
  if (options.keyRing && options.keyRing instanceof Map) {
    for (const [k, v] of options.keyRing) {
      keys.set(k, Buffer.isBuffer(v) ? v : parseEncryptionKey(v, `Key ${k}`));
    }
  }

  // Current key
  if (options.secret) {
    keys.set(currentKid, Buffer.isBuffer(options.secret) ? options.secret : parseEncryptionKey(options.secret, 'options.secret'));
  } else if (env.CURSOR_ENCRYPTION_SECRET) {
    keys.set(currentKid, parseEncryptionKey(env.CURSOR_ENCRYPTION_SECRET, 'CURSOR_ENCRYPTION_SECRET'));
  }

  // Previous keys for rotation
  const previousConfig = options.previousSecrets || env.CURSOR_PREVIOUS_SECRETS;
  if (previousConfig && typeof previousConfig === 'string') {
    const pairs = previousConfig.split(',').map((p) => p.trim()).filter(Boolean);
    for (const pair of pairs) {
      const idx = pair.indexOf(':');
      if (idx > 0) {
        const prevKid = pair.slice(0, idx).trim();
        const prevSecret = pair.slice(idx + 1).trim();
        if (prevKid && prevSecret && !keys.has(prevKid)) {
          keys.set(prevKid, parseEncryptionKey(prevSecret, `CURSOR_PREVIOUS_SECRETS (${prevKid})`));
        }
      }
    }
  }

  const currentKey = keys.get(currentKid);
  if (!currentKey) {
    throw new Error('CURSOR_ENCRYPTION_SECRET is required and must be configured.');
  }

  return { currentKid, currentKey, keys };
}

function aadFor(version, kid, viewerId, surface) {
  return Buffer.from(`${version}:${kid}:${viewerId}:${surface}`, 'utf8');
}

function createCursor({ viewerId, surface, context, keys }, options = {}) {
  const { currentKid, currentKey } = getKeyRing(options);
  const iv = options.iv || crypto.randomBytes(IV_LENGTH_BYTES);
  if (!Buffer.isBuffer(iv) || iv.length !== IV_LENGTH_BYTES) {
    throw new Error('Invalid initialization vector.');
  }

  const now = typeof options.iat === 'number' ? options.iat : Date.now();
  const ttlMs = typeof options.ttlMs === 'number' ? options.ttlMs : DEFAULT_CURSOR_TTL_MS;
  const exp = typeof options.exp === 'number' ? options.exp : now + ttlMs;

  const payload = {
    v: CURSOR_VERSION,
    r: MATCH_RANKING_VERSION,
    u: String(viewerId),
    s: surface,
    c: contextFingerprint(context),
    k: keys,
    iat: now,
    exp,
  };

  const plaintext = Buffer.from(JSON.stringify(payload), 'utf8');
  const cipher = crypto.createCipheriv('aes-256-gcm', currentKey, iv);
  cipher.setAAD(aadFor(CURSOR_FORMAT_VERSION, currentKid, viewerId, surface));

  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();

  return [
    CURSOR_FORMAT_VERSION,
    currentKid,
    iv.toString('base64url'),
    ciphertext.toString('base64url'),
    tag.toString('base64url'),
  ].join('.');
}

function validateRankingKeys(keys) {
  if (!keys || typeof keys !== 'object' || Array.isArray(keys)) {
    throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.', 'PAGINATION_CURSOR_INVALID');
  }
  const entries = Object.entries(keys);
  if (entries.length === 0) {
    throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.', 'PAGINATION_CURSOR_INVALID');
  }
  for (const [key, value] of entries) {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.', 'PAGINATION_CURSOR_INVALID');
    }
    if (key === 'id') {
      if (!Number.isInteger(value) || value <= 0) {
        throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.', 'PAGINATION_CURSOR_INVALID');
      }
    }
    if (['score', 'aiScore', 'confidence'].includes(key)) {
      if (value < 0 || value > 100) {
        throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.', 'PAGINATION_CURSOR_INVALID');
      }
    }
    if (key === 'distance' && value < 0) {
      throw new RecommendationCursorError('The pagination cursor ranking keys are invalid.', 'PAGINATION_CURSOR_INVALID');
    }
  }
}

function readCursor(cursor, { viewerId, surface, context }, options = {}) {
  if (typeof cursor !== 'string' || cursor.length < 10 || cursor.length > MAX_CURSOR_LENGTH) {
    throw new RecommendationCursorError('The pagination cursor is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  const parts = cursor.split('.');
  if (parts.length !== 5) {
    // Check for legacy v1 format (payload.signature)
    if (parts.length === 2) {
      throw new RecommendationCursorError('The pagination cursor version is no longer supported.', 'PAGINATION_CURSOR_EXPIRED');
    }
    throw new RecommendationCursorError('The pagination cursor format is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  const [version, kid, ivB64, ciphertextB64, tagB64] = parts;

  if (version !== CURSOR_FORMAT_VERSION) {
    throw new RecommendationCursorError('The pagination cursor version is no longer supported.', 'PAGINATION_CURSOR_EXPIRED');
  }


  if (
    !BASE64URL_REGEX.test(ivB64)
    || !BASE64URL_REGEX.test(ciphertextB64)
    || !BASE64URL_REGEX.test(tagB64)
  ) {
    throw new RecommendationCursorError(
      'The pagination cursor components are malformed.',
      'PAGINATION_CURSOR_INVALID',
    );
  }

  // Reject non-canonical Base64URL encodings.
  // This prevents alternate final characters from decoding
  // to the same bytes and bypassing tampering detection.
  const encodedComponents = [ivB64, ciphertextB64, tagB64];

  for (const component of encodedComponents) {
    if (Buffer.from(component, 'base64url').toString('base64url') !== component) {
      throw new RecommendationCursorError(
        'The pagination cursor components are malformed.',
        'PAGINATION_CURSOR_INVALID',
      );
    }
  }


  const { keys } = getKeyRing(options);
  const key = keys.get(kid);
  if (!key) {
    throw new RecommendationCursorError('The pagination cursor key identifier is unknown or expired.', 'PAGINATION_CURSOR_EXPIRED');
  }

  const iv = Buffer.from(ivB64, 'base64url');
  if (iv.length !== IV_LENGTH_BYTES) {
    throw new RecommendationCursorError('The pagination cursor initialization vector is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  const tag = Buffer.from(tagB64, 'base64url');
  if (tag.length !== AUTH_TAG_LENGTH_BYTES) {
    throw new RecommendationCursorError('The pagination cursor authentication tag is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  const ciphertext = Buffer.from(ciphertextB64, 'base64url');
  if (ciphertext.length === 0) {
    throw new RecommendationCursorError('The pagination cursor ciphertext is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  let plaintext;
  try {
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAAD(aadFor(version, kid, viewerId, surface));
    decipher.setAuthTag(tag);
    plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  } catch (_) {
    throw new RecommendationCursorError('The pagination cursor signature or authentication failed.', 'PAGINATION_CURSOR_INVALID');
  }

  let payload;
  try {
    payload = JSON.parse(plaintext.toString('utf8'));
  } catch (_) {
    throw new RecommendationCursorError('The pagination cursor payload is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    throw new RecommendationCursorError('The pagination cursor payload is invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  if (payload.v !== CURSOR_VERSION || payload.r !== MATCH_RANKING_VERSION) {
    throw new RecommendationCursorError('The pagination cursor version is no longer supported.', 'PAGINATION_CURSOR_EXPIRED');
  }

  if (payload.u !== String(viewerId) || payload.s !== surface) {
    throw new RecommendationCursorError('The pagination cursor does not belong to this recommendation feed.', 'PAGINATION_CURSOR_INVALID');
  }

  const now = typeof options.now === 'number' ? options.now : Date.now();
  if (typeof payload.iat !== 'number' || typeof payload.exp !== 'number' || !Number.isFinite(payload.iat) || !Number.isFinite(payload.exp)) {
    throw new RecommendationCursorError('The pagination cursor timestamps are missing or invalid.', 'PAGINATION_CURSOR_INVALID');
  }

  if (payload.iat > now + CLOCK_SKEW_TOLERANCE_MS) {
    throw new RecommendationCursorError('The pagination cursor was issued with an invalid timestamp in the future.', 'PAGINATION_CURSOR_INVALID');
  }

  if (payload.exp < payload.iat || (payload.exp - payload.iat) > (MAX_CURSOR_TTL_MS + CLOCK_SKEW_TOLERANCE_MS)) {
    throw new RecommendationCursorError('The pagination cursor lifetime exceeds the maximum permitted TTL.', 'PAGINATION_CURSOR_INVALID');
  }

  if (now > payload.exp) {
    throw new RecommendationCursorError('The pagination cursor has expired.', 'PAGINATION_CURSOR_EXPIRED');
  }

  if (payload.c !== contextFingerprint(context)) {
    throw new RecommendationCursorError('Recommendation filters or viewer context changed. Start again from the first page.', 'PAGINATION_CONTEXT_CHANGED');
  }

  validateRankingKeys(payload.k);

  return payload.k;
}

module.exports = {
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
  _test: { stableJson, getKeyRing },
};
