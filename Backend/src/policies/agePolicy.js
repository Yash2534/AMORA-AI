const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

function parseBirthDate(value) {
  const match = ISO_DATE.exec(String(value || ''));
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const date = new Date(Date.UTC(year, month - 1, day));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null;
  return date;
}

function adultBirthDate(value, now = new Date()) {
  const birthDate = parseBirthDate(value);
  if (!birthDate) return { allowed: false, reason: 'INVALID_DATE' };
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  if (birthDate > today) return { allowed: false, reason: 'FUTURE_DATE' };
  const cutoff = new Date(Date.UTC(today.getUTCFullYear() - 18, today.getUTCMonth(), today.getUTCDate()));
  return birthDate <= cutoff
    ? { allowed: true, birthDate }
    : { allowed: false, reason: 'UNDER_18' };
}

function assertAdultBirthDate(value, now = new Date()) {
  const result = adultBirthDate(value, now);
  if (!result.allowed) {
    const error = new Error(result.reason === 'UNDER_18' ? 'You must be at least 18 years old.' : 'Date of birth must be a valid non-future ISO date.');
    error.code = result.reason === 'UNDER_18' ? 'AGE_RESTRICTION' : 'INVALID_BIRTH_DATE';
    throw error;
  }
  return true;
}

module.exports = { parseBirthDate, adultBirthDate, assertAdultBirthDate };
