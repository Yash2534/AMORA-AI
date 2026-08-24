function assertTimeZone(value) {
  const timezone = String(value || 'Asia/Kolkata');
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: timezone }).format(new Date());
  } catch (_) {
    const error = new Error('timezone must be a valid IANA time zone.');
    error.status = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  return timezone;
}

function partsAt(date, timezone) {
  return Object.fromEntries(new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date).filter((part) => part.type !== 'literal').map((part) => [part.type, Number(part.value)]));
}

function zonedDate(dateOnly, timezone, endOfDay = false) {
  const match = String(dateOnly).match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!match) throw new Error('Invalid date boundary.');
  const desired = {
    year: Number(match[1]), month: Number(match[2]), day: Number(match[3]),
    hour: endOfDay ? 23 : 0,
    minute: endOfDay ? 59 : 0,
    second: endOfDay ? 59 : 0,
  };
  let timestamp = Date.UTC(desired.year, desired.month - 1, desired.day, desired.hour, desired.minute, desired.second, endOfDay ? 999 : 0);
  for (let index = 0; index < 3; index += 1) {
    const actual = partsAt(new Date(timestamp), timezone);
    const actualUtc = Date.UTC(actual.year, actual.month - 1, actual.day, actual.hour, actual.minute, actual.second, endOfDay ? 999 : 0);
    const desiredUtc = Date.UTC(desired.year, desired.month - 1, desired.day, desired.hour, desired.minute, desired.second, endOfDay ? 999 : 0);
    timestamp += desiredUtc - actualUtc;
  }
  return new Date(timestamp);
}

function isoDateInZone(date, timezone) {
  const parts = partsAt(date, timezone);
  return `${parts.year.toString().padStart(4, '0')}-${parts.month.toString().padStart(2, '0')}-${parts.day.toString().padStart(2, '0')}`;
}

function dashboardRange(query, now = new Date()) {
  const timezone = assertTimeZone(query.timezone);
  if (Boolean(query.from) !== Boolean(query.to)) {
    const error = new Error('from and to must be supplied together.');
    error.status = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  if (query.from && query.to) {
    const from = zonedDate(query.from, timezone, false);
    const to = zonedDate(query.to, timezone, true);
    if (to < from) {
      const error = new Error('to must not be before from.');
      error.status = 400;
      error.code = 'VALIDATION_ERROR';
      throw error;
    }
    return { from, to, timezone };
  }
  const days = { today: 1, '7d': 7, '30d': 30, '90d': 90 }[query.range || '30d'];
  if (!days) {
    const error = new Error('Unsupported dashboard range.');
    error.status = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  const toDate = isoDateInZone(now, timezone);
  const start = new Date(`${toDate}T00:00:00.000Z`);
  start.setUTCDate(start.getUTCDate() - (days - 1));
  const fromDate = start.toISOString().slice(0, 10);
  return { from: zonedDate(fromDate, timezone, false), to: zonedDate(toDate, timezone, true), timezone };
}

module.exports = { assertTimeZone, zonedDate, dashboardRange };
