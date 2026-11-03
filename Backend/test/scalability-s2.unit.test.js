const assert = require('node:assert/strict');
const test = require('node:test');

const { boundedDateRange } = require('../src/utils/boundedDateRange');
const { distanceBoundingBox, distanceKm } = require('../src/utils/geoDistance');
const { databaseQueryTimeoutMs } = require('../src/config/scalability');

test('distance bounding box is a safe superset of the exact distance circle', () => {
  const viewer = { latitude: 19.076, longitude: 72.8777 };
  const box = distanceBoundingBox(viewer.latitude, viewer.longitude, 80);
  const candidates = [
    [19.2, 72.9],
    [18.8, 72.7],
    [19.6, 73.2],
  ];
  for (const [latitude, longitude] of candidates) {
    if (distanceKm(viewer.latitude, viewer.longitude, latitude, longitude) > 80) continue;
    assert.ok(latitude >= box.minimumLatitude && latitude <= box.maximumLatitude);
    assert.ok(box.longitudeRanges.some(([minimum, maximum]) => longitude >= minimum && longitude <= maximum));
  }
});

test('distance bounding box safely wraps across the antimeridian', () => {
  const box = distanceBoundingBox(0, 179.8, 80);
  assert.equal(box.longitudeRanges.length, 2);
  assert.ok(box.longitudeRanges.some(([minimum]) => minimum === -180));
  assert.ok(box.longitudeRanges.some(([, maximum]) => maximum === 180));
});

test('admin date ranges default to 30 days and reject spans above 366 days', () => {
  const now = new Date('2026-10-12T00:00:00.000Z');
  const range = boundedDateRange({ now });
  assert.equal(range.to.toISOString(), now.toISOString());
  assert.equal((range.to - range.from) / (24 * 60 * 60 * 1000), 30);
  assert.throws(
    () => boundedDateRange({ from: '2024-01-01', to: '2026-01-02' }),
    (error) => error.status === 400 && error.code === 'DATE_RANGE_TOO_LARGE',
  );
});

test('database statement timeout is opt-in and bounded', () => {
  assert.equal(databaseQueryTimeoutMs({}), 0);
  assert.equal(databaseQueryTimeoutMs({ DB_QUERY_TIMEOUT_MS: '60000' }), 60000);
  assert.throws(() => databaseQueryTimeoutMs({ DB_QUERY_TIMEOUT_MS: '300001' }), /DB_QUERY_TIMEOUT_MS/);
});

test('S2 migration is reversible and names every index deterministically', async () => {
  const migration = require('../src/migrations/202610120001-add-s2-query-indexes');
  const indexes = new Map([
    ['OnboardingProfiles', new Set()],
    ['Users', new Set()],
    ['Matches', new Set()],
    ['Subscriptions', new Set()],
    ['Reports', new Set()],
    ['PrivacyRequests', new Set(['privacy_requests_user_requested'])],
    ['Blocks', new Set(['blocks_blocked_blocker'])],
  ]);
  const queryInterface = {
    showIndex: async (table) => [...indexes.get(table)].map((name) => ({ name })),
    addIndex: async (table, _fields, { name }) => indexes.get(table).add(name),
    removeIndex: async (table, name) => indexes.get(table).delete(name),
  };
  await migration.up(queryInterface);
  assert.ok(indexes.get('OnboardingProfiles').has('onboarding_profiles_match_location'));
  assert.ok(indexes.get('PrivacyRequests').has('privacy_requests_user_requested_id'));
  assert.equal(indexes.get('Blocks').has('blocks_blocked_blocker'), false);
  await migration.down(queryInterface);
  assert.equal(indexes.get('OnboardingProfiles').has('onboarding_profiles_match_location'), false);
  assert.ok(indexes.get('PrivacyRequests').has('privacy_requests_user_requested'));
  assert.ok(indexes.get('Blocks').has('blocks_blocked_blocker'));
});
