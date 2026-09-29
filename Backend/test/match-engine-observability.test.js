const assert = require('node:assert/strict');
const { test } = require('node:test');
const { recommendationDiagnostic, emitRecommendationDiagnostic } = require('../src/services/matchEngineObservabilityService');

const sensitiveProfile = {
  compatibilityScore: 80, compatibilityCoverage: 70, email: 'email-sentinel', phone: 'phone-sentinel',
  bio: 'bio-sentinel', compatibilityReasons: ['reason-sentinel'], birthDate: 'dob-sentinel',
  matchLatitude: 23.123456, matchLongitude: 72.123456, password: 'password-sentinel',
  token: 'access-sentinel', refreshToken: 'refresh-sentinel', otp: 'otp-sentinel',
  prompts: 'prompt-sentinel', sexuality: 'sexuality-sentinel', kyc: 'kyc-sentinel', message: 'message-sentinel',
};

test('recommendation diagnostic uses bounded dimensions and never logs profile data', () => {
  let output = '';
  const original = console.log;
  console.log = (...values) => { output = values.join(' '); };
  try {
    const event = emitRecommendationDiagnostic({
      surface: 'near_you', provider: 'LOCAL', continuation: true, limit: 10, startedAt: Date.now(),
      aiRankingDurationMs: 7,
      candidateCounts: { beforeEligibility: 100, afterEligibility: 70, afterDistance: 40 },
      profiles: [sensitiveProfile],
    });
    assert.equal(event.event, 'match_engine.recommendation');
    assert.equal(event.surface, 'near_you');
    assert.equal(event.provider, 'LOCAL');
    assert.deepEqual(event.candidateCounts, { beforeEligibility: 100, afterEligibility: 70, afterDistance: 40, returned: 1 });
    assert.equal(event.scoreBuckets['61_80'], 1);
    assert.equal(event.coverageBuckets['67_100'], 1);
    assert.ok(event.durationMs >= 0);
    for (const value of ['email-sentinel', 'phone-sentinel', 'bio-sentinel', 'reason-sentinel', 'dob-sentinel', '23.123456', '72.123456', 'password-sentinel', 'access-sentinel', 'refresh-sentinel', 'otp-sentinel', 'prompt-sentinel', 'sexuality-sentinel', 'kyc-sentinel', 'message-sentinel']) {
      assert.doesNotMatch(output, new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    }
    for (const forbidden of ['compatibilityReasons', 'matchLatitude', 'matchLongitude', 'userId', 'candidateId', 'cursor']) assert.doesNotMatch(output, new RegExp(forbidden));
  } finally {
    console.log = original;
  }
});

test('recommendation diagnostic bounds unknown labels and error classes', () => {
  const event = recommendationDiagnostic({ surface: 'user-controlled-city', provider: 'external-user-value', errorCode: 'SEQUELIZE_RAW_PRIVATE_DETAIL', profiles: [] });
  assert.equal(event.surface, 'unknown');
  assert.equal(event.provider, 'STANDARD');
  assert.equal(event.errorClass, 'INTERNAL_ERROR');
  assert.equal(Object.hasOwn(event, 'city'), false);
});
