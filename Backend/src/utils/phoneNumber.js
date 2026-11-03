function normalizeIndianMobile(value) {
  const digits = String(value == null ? '' : value).replace(/\D/g, '');
  const national = digits.length === 12 && digits.startsWith('91')
    ? digits.slice(2)
    : digits;
  return /^[6-9]\d{9}$/.test(national) ? `+91${national}` : '';
}

function phoneReference(value) {
  const crypto = require('crypto');
  const normalized = normalizeIndianMobile(value);
  return normalized
    ? crypto.createHash('sha256').update(normalized).digest('hex').slice(0, 24)
    : null;
}

module.exports = { normalizeIndianMobile, phoneReference };
