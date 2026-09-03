const test = require('node:test');
const assert = require('node:assert/strict');
const { registrationDeadlineFor, registrationIsClosed } = require('../src/services/eventService');

test('uses an explicit registration deadline as the authoritative cutoff', () => {
  const event = {
    registrationDeadline: new Date('2026-09-15T12:00:00.000Z'),
    startDateTime: new Date('2026-09-20T12:00:00.000Z'),
  };
  assert.equal(registrationDeadlineFor(event).toISOString(), '2026-09-15T12:00:00.000Z');
  assert.equal(registrationIsClosed(event, new Date('2026-09-15T11:59:59.999Z')), false);
  assert.equal(registrationIsClosed(event, new Date('2026-09-15T12:00:00.000Z')), true);
});

test('legacy events use their start time as a safe registration cutoff', () => {
  const event = { startDateTime: new Date('2026-09-20T12:00:00.000Z') };
  assert.equal(registrationDeadlineFor(event).toISOString(), '2026-09-20T12:00:00.000Z');
  assert.equal(registrationIsClosed(event, new Date('2026-09-20T12:00:00.000Z')), true);
});
