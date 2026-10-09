/**
 * DPDP Compliant PII Redactor Logger
 * Ensures no plain-text PII (Emails, Phone numbers, Passwords, Tokens, Aadhaar) is written to logs.
 */

const SENSITIVE_KEY = /(?:password|passphrase|pwd|otp|one.?time|token|authorization|cookie|secret|api.?key|refresh.?token|access.?token|mfa|totp|aadhaar|identity.?document|document.?number|private.?key|client.?secret)/i;
const REDACTED = '[REDACTED_SENSITIVE_FIELD]';

function sanitizeValue(value, seen = new WeakSet()) {
  if (value === null || value === undefined) return value;
  if (typeof value === 'string') {
    // Mask Email Addresses
    let sanitized = value.replace(/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g, (match, p1, p2) => {
      const maskedUser = p1.length > 2 ? p1[0] + '***' + p1[p1.length - 1] : '***';
      return `${maskedUser}@${p2}`;
    });

    // Mask Indian Phone Numbers (+91 10-digits or raw 10 digits)
    sanitized = sanitized.replace(/(\+?91[\s-]?)?([6-9]\d{9})/g, (_match, prefix = '', digits) => `${prefix}******${digits.slice(-4)}`);
    sanitized = sanitized.replace(/\b\d{12}\b/g, '[REDACTED_IDENTITY_NUMBER]');

    // Mask JWT Tokens / Passwords
    sanitized = sanitized.replace(/bearer\s+[a-zA-Z0-9._~+/=-]+/gi, 'Bearer [REDACTED_TOKEN]');
    sanitized = sanitized.replace(/\b(?:password|pwd|otp|token|authorization|cookie|secret|api[_-]?key|refresh[_-]?token|access[_-]?token|mfa[_-]?secret)\b\s*[:=]\s*[^\s,;]+/gi, (match) => `${match.split(/[:=]/, 1)[0]}=${REDACTED}`);

    return sanitized;
  }

  if (typeof value === 'object') {
    if (seen.has(value)) return '[REDACTED_CIRCULAR_REFERENCE]';
    seen.add(value);
    if (value instanceof Error) {
      return {
        name: value.name,
        code: value.code,
        status: value.status,
      };
    }
    if (Array.isArray(value)) {
      return value.slice(0, 100).map((item) => sanitizeValue(item, seen));
    }
    const sanitizedObj = {};
    for (const [key, val] of Object.entries(value)) {
      if (SENSITIVE_KEY.test(key.replace(/[^a-z0-9]/gi, ''))) {
        sanitizedObj[key] = REDACTED;
      } else {
        sanitizedObj[key] = sanitizeValue(val, seen);
      }
    }
    return sanitizedObj;
  }

  return value;
}

const logger = {
  info: (...args) => {
    console.log('[INFO]', ...args.map((value) => sanitizeValue(value)));
  },
  warn: (...args) => {
    console.warn('[WARN]', ...args.map((value) => sanitizeValue(value)));
  },
  error: (...args) => {
    console.error('[ERROR]', ...args.map((value) => sanitizeValue(value)));
  },
  debug: (...args) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug('[DEBUG]', ...args.map((value) => sanitizeValue(value)));
    }
  }
};

module.exports = logger;
module.exports.sanitizeValue = sanitizeValue;
module.exports.REDACTED = REDACTED;
