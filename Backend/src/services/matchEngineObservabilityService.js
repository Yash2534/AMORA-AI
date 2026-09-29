const crypto = require('crypto');
const logger = require('../utils/logger');
const { MATCH_ENGINE_VERSION, MATCH_RANKING_VERSION } = require('./matchEngineContract');

const SCORE_BUCKETS = Object.freeze([
  Object.freeze({ key: '0_20', min: 0, max: 20 }),
  Object.freeze({ key: '21_40', min: 21, max: 40 }),
  Object.freeze({ key: '41_60', min: 41, max: 60 }),
  Object.freeze({ key: '61_80', min: 61, max: 80 }),
  Object.freeze({ key: '81_100', min: 81, max: 100 }),
]);
const COVERAGE_BUCKETS = Object.freeze([
  Object.freeze({ key: '0_33', min: 0, max: 33 }),
  Object.freeze({ key: '34_66', min: 34, max: 66 }),
  Object.freeze({ key: '67_100', min: 67, max: 100 }),
]);
const SAFE_SURFACES = new Set(['default', 'high_compatibility', 'near_you']);
const SAFE_PROVIDERS = new Set(['STANDARD', 'LOCAL']);
const SAFE_ERRORS = new Set([
  'AUTHENTICATION_REQUIRED', 'ONBOARDING_INCOMPLETE', 'LOCATION_REQUIRED',
  'DISCOVER_SURFACE_UNSUPPORTED', 'VALIDATION_ERROR', 'PAGINATION_CURSOR_INVALID',
  'PAGINATION_CURSOR_EXPIRED', 'PAGINATION_CONTEXT_CHANGED',
  'PAGINATION_CURSOR_REQUIRED', 'INTERNAL_ERROR',
]);

const enabled = () => process.env.MATCH_ENGINE_OBSERVABILITY_ENABLED === 'true';
const finiteNonNegativeInteger = (value) => {
  const number = Number(value);
  return Number.isFinite(number) && number >= 0 ? Math.round(number) : null;
};
const bucketCounts = (values, buckets) => Object.fromEntries(buckets.map((bucket) => [
  bucket.key,
  values.filter((value) => value >= bucket.min && value <= bucket.max).length,
]));
const boundedValues = (profiles, key) => profiles
  .map((profile) => Number(profile?.[key] ?? profile?.compatibility?.[key]))
  .filter((value) => Number.isFinite(value) && value >= 0 && value <= 100);

function recommendationDiagnostic({
  surface,
  provider,
  continuation,
  limit,
  profiles = [],
  candidateCounts = {},
  startedAt,
  aiRankingDurationMs,
  errorCode,
}) {
  const scores = boundedValues(profiles, 'compatibilityScore');
  const coverage = boundedValues(profiles, 'compatibilityCoverage');
  const durationMs = Math.max(0, Date.now() - Number(startedAt || Date.now()));
  return {
    event: 'match_engine.recommendation',
    requestId: crypto.randomUUID(),
    contractVersion: MATCH_ENGINE_VERSION,
    rankingVersion: MATCH_RANKING_VERSION,
    surface: SAFE_SURFACES.has(surface) ? surface : 'unknown',
    provider: SAFE_PROVIDERS.has(provider) ? provider : 'STANDARD',
    continuation: Boolean(continuation),
    limit: finiteNonNegativeInteger(limit),
    durationMs,
    durationBucket: durationMs < 100 ? 'lt_100ms' : durationMs < 500 ? '100_499ms' : durationMs < 2000 ? '500_1999ms' : 'gte_2000ms',
    aiRankingDurationMs: provider === 'LOCAL' ? finiteNonNegativeInteger(aiRankingDurationMs) : null,
    candidateCounts: {
      beforeEligibility: finiteNonNegativeInteger(candidateCounts.beforeEligibility),
      afterEligibility: finiteNonNegativeInteger(candidateCounts.afterEligibility),
      afterDistance: finiteNonNegativeInteger(candidateCounts.afterDistance),
      returned: profiles.length,
    },
    scoreBuckets: bucketCounts(scores, SCORE_BUCKETS),
    coverageBuckets: bucketCounts(coverage, COVERAGE_BUCKETS),
    errorClass: errorCode ? (SAFE_ERRORS.has(errorCode) ? errorCode : 'INTERNAL_ERROR') : null,
  };
}

function emitRecommendationDiagnostic(input) {
  const event = recommendationDiagnostic(input);
  logger.info(event);
  return event;
}

// Backward-compatible name retained for existing callers/tests.
const emitDiscoverDiagnostic = emitRecommendationDiagnostic;

module.exports = {
  SCORE_BUCKETS,
  COVERAGE_BUCKETS,
  enabled,
  recommendationDiagnostic,
  emitRecommendationDiagnostic,
  emitDiscoverDiagnostic,
};
