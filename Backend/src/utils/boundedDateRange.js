const DAY_MS = 24 * 60 * 60 * 1000;

function invalid(message, code = 'INVALID_DATE_RANGE') {
  const error = new Error(message);
  error.status = 400;
  error.code = code;
  return error;
}

function parsedDate(value, fallback, name) {
  if (value === undefined || value === null || value === '') return fallback;
  const result = value instanceof Date ? new Date(value) : new Date(value);
  if (Number.isNaN(result.getTime())) throw invalid(`${name} must be a valid date.`);
  return result;
}

function boundedDateRange({ from, to, defaultDays = 30, maximumDays = 366, now = new Date() } = {}) {
  const end = parsedDate(to, new Date(now), 'to');
  const start = parsedDate(from, new Date(end.getTime() - defaultDays * DAY_MS), 'from');
  if (start > end) throw invalid('from must be before or equal to to.');
  if (end.getTime() - start.getTime() > maximumDays * DAY_MS) {
    throw invalid(`Date range cannot exceed ${maximumDays} days.`, 'DATE_RANGE_TOO_LARGE');
  }
  return { from: start, to: end };
}

module.exports = { DAY_MS, boundedDateRange };
