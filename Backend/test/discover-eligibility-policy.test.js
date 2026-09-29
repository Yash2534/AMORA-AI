const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  ACCOUNT_STATUS,
  ageFor,
  EXCLUDING_DISCOVER_ACTIONS,
  HARD_FILTERS,
  NON_EXCLUDING_RELATIONSHIPS,
  candidateAcceptsViewer,
  isDiscoverComplete,
  isRecentlyActive,
  normalizedStringList,
  normalizeStoredFilterRanges,
  profileCompletionErrors,
  surfaceContract,
  viewerAcceptsCandidate,
} = require('../src/services/discoverEligibilityPolicy');

const completeProfile = (overrides = {}) => ({
  birthDate: '1995-01-15',
  gender: 'Female',
  interestedIn: ['Male'],
  relationshipGoals: ['long_term'],
  city: 'Ahmedabad',
  photos: ['/one.jpg', '/two.jpg'],
  onboardingCompleted: true,
  stage: 'complete',
  ...overrides,
});

test('canonical account and relationship policy is explicit', () => {
  assert.equal(ACCOUNT_STATUS.eligible, 'active');
  assert.deepEqual(ACCOUNT_STATUS.ineligible, ['deactivated', 'deleted']);
  assert.deepEqual(EXCLUDING_DISCOVER_ACTIONS, ['pass', 'like', 'superLike']);
  assert.deepEqual(NON_EXCLUDING_RELATIONSHIPS, ['rose', 'save', 'report']);
});

test('canonical completion rejects every stale required-field state', () => {
  assert.equal(isDiscoverComplete(completeProfile()), true);
  for (const [field, value] of [
    ['birthDate', null], ['birthDate', '2015-01-15'], ['gender', ''],
    ['gender', 'not-a-gender'], ['interestedIn', ['  ']],
    ['relationshipGoals', []], ['city', '  '], ['photos', ['/one.jpg']],
    ['onboardingCompleted', false], ['stage', 'photos'],
  ]) {
    assert.equal(isDiscoverComplete(completeProfile({ [field]: value })), false, field);
  }
});

test('onboarding completion uses the same fields without requiring historical flags', () => {
  assert.deepEqual(profileCompletionErrors(completeProfile({
    onboardingCompleted: false,
    stage: 'photos',
  }), { requireStoredFlags: false }), []);
});

test('string-list normalization trims, removes blanks, and deduplicates case-insensitively', () => {
  assert.deepEqual(normalizedStringList([' Male ', '', 'male', 'Female', 7, null]), ['Male', 'Female']);
  assert.deepEqual(normalizedStringList(' calls, Calls, voice_notes '), ['calls', 'voice_notes']);
});

test('viewer and reciprocal interest aliases and universal tokens are deterministic', () => {
  assert.equal(viewerAcceptsCandidate(['Women'], 'Female'), true);
  assert.equal(viewerAcceptsCandidate(['Male'], 'Female'), false);
  assert.equal(viewerAcceptsCandidate(['Everyone'], 'Other'), true);
  assert.equal(candidateAcceptsViewer(['Women'], 'Female'), true);
  assert.equal(candidateAcceptsViewer(['Male'], 'Female'), false);
  assert.equal(candidateAcceptsViewer(['any'], 'Female'), true);
  assert.equal(candidateAcceptsViewer([], 'Female'), true);
  assert.equal(candidateAcceptsViewer(null, 'Female'), true);
});

test('reciprocal age uses exact birthdays and inclusive boundaries', () => {
  const now = new Date('2026-09-29T12:00:00.000Z');
  assert.equal(ageFor('1998-09-29', now), 28);
  assert.equal(ageFor('1998-09-30', now), 27);
  assert.equal(ageFor('1998-09-28', now), 28);
  assert.equal(ageFor('not-a-date', now), null);
});

test('reciprocal stored ranges share canonical defaults and safely normalize legacy values', () => {
  const fallbacks = { minAge: 18, maxAge: 45, maxDistanceKm: 80, minScore: 0, minHeight: null };
  assert.deepEqual(
    normalizeStoredFilterRanges({ minAge: 22, maxAge: 50, maxDistanceKm: 120, minScore: 10 }, fallbacks),
    { minAge: 22, maxAge: 50, maxDistanceKm: 120, minScore: 10, minHeight: null },
  );
  const malformed = normalizeStoredFilterRanges({
    minAge: 'bad', maxAge: 500, maxDistanceKm: -1, minScore: null,
  }, fallbacks);
  assert.deepEqual(
    { minAge: malformed.minAge, maxAge: malformed.maxAge, maxDistanceKm: malformed.maxDistanceKm },
    { minAge: 18, maxAge: 99, maxDistanceKm: 1 },
  );
  const reversed = normalizeStoredFilterRanges({ minAge: 50, maxAge: 20, maxDistanceKm: 80 }, fallbacks);
  assert.equal(reversed.minAge, 18);
  assert.equal(reversed.maxAge, 45);
});

test('surface contract supports real distance and rejects remaining no-op surfaces explicitly', () => {
  assert.deepEqual(surfaceContract().name, 'recommended');
  assert.equal(surfaceContract().supported, true);
  assert.equal(surfaceContract('high_compatibility').supported, true);
  assert.equal(surfaceContract('near_you').supported, true);
  for (const value of ['similar_interests', 'new_here', 'recently_active', 'unknown']) {
    assert.equal(surfaceContract(value).supported, false, value);
  }
  assert.deepEqual(surfaceContract('near_you', { aiMatches: true }).name, 'high_compatibility');
});

test('hard-filter policy includes real geographic distance in Phase 3', () => {
  assert.equal(HARD_FILTERS.includes('minScore'), true);
  assert.equal(HARD_FILTERS.includes('onlineNow'), true);
  assert.equal(HARD_FILTERS.includes('maxDistanceKm'), true);
});

test('recent activity is a timestamp window, not presence', () => {
  const now = new Date('2026-09-29T12:00:00.000Z');
  assert.equal(isRecentlyActive('2026-09-29T11:56:00.000Z', { now, windowMinutes: 5 }), true);
  assert.equal(isRecentlyActive('2026-09-29T11:54:59.000Z', { now, windowMinutes: 5 }), false);
  assert.equal(isRecentlyActive(null, { now, windowMinutes: 5 }), false);
});
