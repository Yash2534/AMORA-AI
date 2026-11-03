const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  ACCOUNT_STATUS,
  ageFor,
  EXCLUDING_DISCOVER_ACTIONS,
  EXCLUDING_RELATIONSHIPS,
  HARD_FILTERS,
  NON_EXCLUDING_RELATIONSHIPS,
  isReportExcluding,
  candidateAcceptsViewer,
  isDiscoverComplete,
  isRecentlyActive,
  normalizedStringList,
  normalizeStoredFilterRanges,
  profileCompletionErrors,
  surfaceContract,
  validateSwipeEligibility,
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
  assert.deepEqual(NON_EXCLUDING_RELATIONSHIPS, ['rose', 'save']);
  assert.deepEqual(EXCLUDING_RELATIONSHIPS, ['block', 'report']);
  assert.equal(isReportExcluding, true);
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

test('validateSwipeEligibility enforces reciprocal gender, age, distance, and safety', () => {
  const now = new Date('2026-09-29T12:00:00.000Z');
  const viewerProfile = completeProfile({
    birthDate: '1996-01-01', // age 30
    gender: 'female',
    interestedIn: ['male'],
    matchLatitude: 23.0225,
    matchLongitude: 72.5714,
  });
  const targetUser = { id: 2, accountStatus: 'active' };
  const targetProfile = completeProfile({
    birthDate: '1994-01-01', // age 32
    gender: 'male',
    interestedIn: ['female'],
    matchLatitude: 23.0300,
    matchLongitude: 72.5800,
  });
  const viewerFilters = { minAge: 25, maxAge: 35, maxDistanceKm: 50 };
  const targetFilters = { minAge: 25, maxAge: 35, maxDistanceKm: 50 };

  // Eligible pair
  const ok = validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile, targetFilters, now,
  });
  assert.equal(ok.eligible, true);

  // Inactive target
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser: { id: 2, accountStatus: 'deactivated' }, targetProfile, targetFilters, now,
  }).eligible, false);

  // Blocked
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile, targetFilters, areBlocked: true, now,
  }).eligible, false);

  // Reported
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile, targetFilters, isReported: true, now,
  }).eligible, false);

  // Incompatible target gender
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile: { ...targetProfile, gender: 'female' }, targetFilters, now,
  }).eligible, false);

  // Incompatible reciprocal interest (target does not want females)
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile: { ...targetProfile, interestedIn: ['male'] }, targetFilters, now,
  }).eligible, false);

  // Target age outside viewer range
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters: { ...viewerFilters, maxAge: 31 }, targetUser, targetProfile, targetFilters, now,
  }).eligible, false);

  // Viewer age outside target range
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile, targetFilters: { ...targetFilters, minAge: 31 }, now,
  }).eligible, false);

  // Distance exceeded
  assert.equal(validateSwipeEligibility({
    viewerProfile, viewerFilters: { ...viewerFilters, maxDistanceKm: 0.1 }, targetUser, targetProfile, targetFilters, now,
  }).eligible, false);

  // VULN-P0-01: Filter definitions
  const noDistFilters = { minAge: 25, maxAge: 35, maxDistanceKm: null };

  // VULN-P0-01: Viewer coordinates missing with target distance restriction
  const viewerNoCoords = { ...viewerProfile, matchLatitude: null, matchLongitude: null };
  const resViewerMissing = validateSwipeEligibility({
    viewerProfile: viewerNoCoords, viewerFilters, targetUser, targetProfile, targetFilters, now,
  });
  assert.equal(resViewerMissing.eligible, false);
  assert.equal(resViewerMissing.reason, 'viewer_location_missing');

  // VULN-P0-01: Viewer coordinates missing with viewer distance restriction but target has NO restriction
  const resViewerMissingViewerRestriction = validateSwipeEligibility({
    viewerProfile: viewerNoCoords, viewerFilters, targetUser, targetProfile, targetFilters: noDistFilters, now,
  });
  assert.equal(resViewerMissingViewerRestriction.eligible, false);
  assert.equal(resViewerMissingViewerRestriction.reason, 'viewer_location_missing');

  // VULN-P0-01: Target coordinates missing with viewer distance restriction
  const targetNoCoords = { ...targetProfile, matchLatitude: null, matchLongitude: null };
  const resTargetMissing = validateSwipeEligibility({
    viewerProfile, viewerFilters, targetUser, targetProfile: targetNoCoords, targetFilters, now,
  });
  assert.equal(resTargetMissing.eligible, false);
  assert.equal(resTargetMissing.reason, 'target_location_missing');

  // VULN-P0-01: Target coordinates missing with target distance restriction but viewer has NO restriction
  const resTargetMissingTargetRestriction = validateSwipeEligibility({
    viewerProfile, viewerFilters: noDistFilters, targetUser, targetProfile: targetNoCoords, targetFilters, now,
  });
  assert.equal(resTargetMissingTargetRestriction.eligible, false);
  assert.equal(resTargetMissingTargetRestriction.reason, 'target_location_missing');

  // VULN-P0-01: Both missing coordinates with distance restriction configured
  const resBothMissing = validateSwipeEligibility({
    viewerProfile: viewerNoCoords, viewerFilters, targetUser, targetProfile: targetNoCoords, targetFilters, now,
  });
  assert.equal(resBothMissing.eligible, false);
  assert.equal(resBothMissing.reason, 'location_required');

  const resBothMissingTargetOnly = validateSwipeEligibility({
    viewerProfile: viewerNoCoords, viewerFilters: noDistFilters, targetUser, targetProfile: targetNoCoords, targetFilters, now,
  });
  assert.equal(resBothMissingTargetOnly.eligible, false);
  assert.equal(resBothMissingTargetOnly.reason, 'location_required');

  // VULN-P0-01: No distance restriction configured (maxDistanceKm = null)
  const resNoDistBothMissing = validateSwipeEligibility({
    viewerProfile: viewerNoCoords, viewerFilters: noDistFilters, targetUser, targetProfile: targetNoCoords, targetFilters: noDistFilters, now,
  });
  assert.equal(resNoDistBothMissing.eligible, true);

  // VULN-P0-01: Target missing coords but viewer has NO distance restriction
  const resTargetMissingNoRestriction = validateSwipeEligibility({
    viewerProfile, viewerFilters: noDistFilters, targetUser, targetProfile: targetNoCoords, targetFilters: noDistFilters, now,
  });
  assert.equal(resTargetMissingNoRestriction.eligible, true);

  // VULN-P0-01: Viewer missing coords but target has NO distance restriction
  const resViewerMissingNoRestriction = validateSwipeEligibility({
    viewerProfile: viewerNoCoords, viewerFilters: noDistFilters, targetUser, targetProfile, targetFilters: noDistFilters, now,
  });
  assert.equal(resViewerMissingNoRestriction.eligible, true);

  // VULN-P0-01: Boundary distance vs just outside boundary
  // Distance between (23.0225, 72.5714) and (23.0300, 72.5800) is approx 1.22 km
  const boundaryFilters = { minAge: 25, maxAge: 35, maxDistanceKm: 1.25 };
  const resBoundary = validateSwipeEligibility({
    viewerProfile, viewerFilters: boundaryFilters, targetUser, targetProfile, targetFilters: boundaryFilters, now,
  });
  assert.equal(resBoundary.eligible, true);

  const outsideFilters = { minAge: 25, maxAge: 35, maxDistanceKm: 1.20 };
  const resOutside = validateSwipeEligibility({
    viewerProfile, viewerFilters: outsideFilters, targetUser, targetProfile, targetFilters: outsideFilters, now,
  });
  assert.equal(resOutside.eligible, false);
  assert.equal(resOutside.reason, 'distance_exceeded');
});
