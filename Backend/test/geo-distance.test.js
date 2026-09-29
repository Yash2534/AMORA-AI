const assert = require('node:assert/strict');
const test = require('node:test');
const { distanceKm, validCoordinates } = require('../src/utils/geoDistance');

test('Haversine returns zero for identical coordinates and is deterministic', () => {
  assert.equal(distanceKm(23.0225, 72.5714, 23.0225, 72.5714), 0);
  assert.equal(
    distanceKm(23.0225, 72.5714, 23.0325, 72.5814),
    distanceKm(23.0225, 72.5714, 23.0325, 72.5814),
  );
});

test('Haversine produces the expected approximate Ahmedabad to Surat distance', () => {
  const result = distanceKm(23.0225, 72.5714, 21.1702, 72.8311);
  assert.ok(result > 205 && result < 215, `unexpected distance ${result}`);
});

test('Haversine is symmetric across negative longitude and southern latitude', () => {
  const first = distanceKm(-33.8688, 151.2093, 37.7749, -122.4194);
  const second = distanceKm(37.7749, -122.4194, -33.8688, 151.2093);
  assert.ok(Math.abs(first - second) < 1e-9);
});

test('coordinate boundaries are accepted', () => {
  assert.equal(validCoordinates(-90, -180), true);
  assert.equal(validCoordinates(90, 180), true);
  assert.ok(Number.isFinite(distanceKm(-90, -180, 90, 180)));
});

test('invalid or missing coordinates are rejected safely', () => {
  for (const values of [
    [null, 0], [0, undefined], [91, 0], [-91, 0], [0, 181], [0, -181],
    [Number.NaN, 0], [Number.POSITIVE_INFINITY, 0], ['not-a-number', 0],
  ]) {
    assert.equal(validCoordinates(values[0], values[1]), false);
    assert.throws(() => distanceKm(values[0], values[1], 0, 0), TypeError);
  }
});
