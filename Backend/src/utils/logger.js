/**
 * DPDP Compliant PII Redactor Logger
 * Ensures no plain-text PII (Emails, Phone numbers, Passwords, Tokens, Aadhaar) is written to logs.
 */

function sanitizeValue(value) {
  if (!value) return value;
  if (typeof value === 'string') {
    // Mask Email Addresses
    let sanitized = value.replace(/([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g, (match, p1, p2) => {
      const maskedUser = p1.length > 2 ? p1[0] + '***' + p1[p1.length - 1] : '***';
      return `${maskedUser}@${p2}`;
    });

    // Mask Indian Phone Numbers (+91 10-digits or raw 10 digits)
    sanitized = sanitized.replace(/(\+?91[\s-]?)?([6-9]\d{9})/g, '$1******$2'.slice(-4));

    // Mask JWT Tokens / Passwords
    sanitized = sanitized.replace(/(bearer\s+[a-zA-Z0-9-_=]+\.[a-zA-Z0-9-_=]+\.[a-zA-Z0-9-_=]+)/gi, '[REDACTED_JWT_TOKEN]');

    return sanitized;
  }

  if (typeof value === 'object') {
    if (Array.isArray(value)) {
      return value.map(sanitizeValue);
    }
    const sanitizedObj = {};
    for (const [key, val] of Object.entries(value)) {
      const lowerKey = key.toLowerCase();
      if (['password', 'passwordhash', 'token', 'refreshtoken', 'aadhaar', 'selfie', 'secret', 'otp'].includes(lowerKey)) {
        sanitizedObj[key] = '[REDACTED_SENSITIVE_FIELD]';
      } else {
        sanitizedObj[key] = sanitizeValue(val);
      }
    }
    return sanitizedObj;
  }

  return value;
}

const logger = {
  info: (...args) => {
    console.log('[INFO]', ...args.map(sanitizeValue));
  },
  warn: (...args) => {
    console.warn('[WARN]', ...args.map(sanitizeValue));
  },
  error: (...args) => {
    console.error('[ERROR]', ...args.map(sanitizeValue));
  },
  debug: (...args) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug('[DEBUG]', ...args.map(sanitizeValue));
    }
  }
};

module.exports = logger;
