const DISCOVER_FILTER_RANGES = Object.freeze({
  age: Object.freeze({ min: 18, max: 99 }),
  distanceKm: Object.freeze({ min: 1, max: 300 }),
  score: Object.freeze({ min: 0, max: 100 }),
  heightCm: Object.freeze({ min: 137, max: 213 }),
});

module.exports = { DISCOVER_FILTER_RANGES };
