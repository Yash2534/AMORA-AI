const assert = require('node:assert/strict');
const { test } = require('node:test');
const { calculateProfileCompletion } = require('../src/services/profileCompletionService');
const {
  ageFor,
  isDiscoverComplete,
  profileCompletionErrors,
  viewerAcceptsCandidate,
} = require('../src/services/discoverEligibilityPolicy');
const { scoreCompatibility } = require('../src/services/compatibilityScoringService');
const { distanceKm } = require('../src/utils/geoDistance');
const {
  EXPECTED_PASSWORD_HASHES,
  resolveManualQaConfig,
} = require('../scripts/manual-qa-users-config');
const {
  QA_USERS,
  preferenceValues,
  profileValues,
} = require('../scripts/manual-qa-users-fixture');

const approvedHashes = { krupa: 'hash-a', yashu: 'hash-b' };
const safeEnvironment = {
  NODE_ENV: 'development',
  ALLOW_DUMMY_SEED: 'true',
  DB_NAME: 'amora_ai',
  DUMMY_SEED_DATABASES: 'amora_ai',
  MANUAL_QA_KRUPA_PASSWORD: 'runtime-a',
  MANUAL_QA_YASHU_PASSWORD: 'runtime-b',
};
const configOptions = {
  expectedPasswordHashes: {
    krupa: require('../scripts/manual-qa-users-config').sha256('runtime-a'),
    yashu: require('../scripts/manual-qa-users-config').sha256('runtime-b'),
  },
};

const now = new Date('2026-09-30T12:00:00.000Z');
const photos = ['/uploads/onboarding-photos/one.webp', '/uploads/onboarding-photos/two.webp'];
const profiles = {
  krupa: profileValues(QA_USERS.krupa, photos, now),
  yashu: profileValues(QA_USERS.yashu, photos, now),
};
const users = {
  krupa: { name: QA_USERS.krupa.name },
  yashu: { name: QA_USERS.yashu.name },
};

test('production execution is blocked before credentials are evaluated', () => {
  assert.throws(
    () => resolveManualQaConfig({ ...safeEnvironment, NODE_ENV: 'production' }, ['--confirm-development-db'], configOptions),
    /blocked in production/,
  );
});

test('development database confirmation and allowlist are mandatory', () => {
  assert.throws(() => resolveManualQaConfig(safeEnvironment, [], configOptions), /confirm-development-db/);
  assert.throws(
    () => resolveManualQaConfig({ ...safeEnvironment, DUMMY_SEED_DATABASES: 'another_db' }, ['--confirm-development-db'], configOptions),
    /explicitly listed/,
  );
});

test('approved QA passwords are verified without storing plaintext in source', () => {
  assert.equal(Object.keys(EXPECTED_PASSWORD_HASHES).length, 2);
  assert.throws(
    () => resolveManualQaConfig({ ...safeEnvironment, MANUAL_QA_KRUPA_PASSWORD: 'wrong' }, ['--confirm-development-db'], configOptions),
    /approved local QA password/,
  );
});

test('reset-relations mode does not require passwords', () => {
  const config = resolveManualQaConfig(
    { ...safeEnvironment, MANUAL_QA_KRUPA_PASSWORD: '', MANUAL_QA_YASHU_PASSWORD: '' },
    ['--confirm-development-db', '--reset-relations'],
    { expectedPasswordHashes: approvedHashes },
  );
  assert.equal(config.mode, 'reset-relations');
});

for (const key of ['krupa', 'yashu']) {
  test(`${key} fixture has deterministic identity and active-match profile state`, () => {
    const definition = QA_USERS[key];
    const profile = profiles[key];
    assert.match(definition.email, new RegExp(`^${key}@gmail\\.com$`));
    assert.equal(ageFor(profile.birthDate, now), definition.age);
    assert.equal(profile.onboardingCompleted, true);
    assert.equal(profile.stage, 'complete');
    assert.equal(profile.photos.length, 2);
    assert.deepEqual(profileCompletionErrors(profile, { now }), []);
    assert.equal(isDiscoverComplete(profile, { now }), true);
    assert.deepEqual(calculateProfileCompletion(users[key], profile), { percentage: 100, complete: true });
  });
}

test('fixtures pass reciprocal gender and age preferences', () => {
  const krupaPreferences = preferenceValues(1);
  const yashuPreferences = preferenceValues(2);
  assert.equal(viewerAcceptsCandidate(profiles.krupa.interestedIn, profiles.yashu.gender), true);
  assert.equal(viewerAcceptsCandidate(profiles.yashu.interestedIn, profiles.krupa.gender), true);
  assert.ok(QA_USERS.yashu.age >= krupaPreferences.minAge && QA_USERS.yashu.age <= krupaPreferences.maxAge);
  assert.ok(QA_USERS.krupa.age >= yashuPreferences.minAge && QA_USERS.krupa.age <= yashuPreferences.maxAge);
});

test('fixtures pass reciprocal 50 km distance limits', () => {
  const distance = distanceKm(
    QA_USERS.krupa.latitude,
    QA_USERS.krupa.longitude,
    QA_USERS.yashu.latitude,
    QA_USERS.yashu.longitude,
  );
  assert.ok(distance > 0);
  assert.ok(distance < preferenceValues(1).maxDistanceKm);
  assert.ok(distance < preferenceValues(2).maxDistanceKm);
});

test('canonical compatibility includes every production factor', () => {
  const result = scoreCompatibility(profiles.krupa, profiles.yashu);
  assert.deepEqual(Object.keys(result.factorBreakdown), [
    'interests',
    'relationshipGoals',
    'communicationStyle',
    'languages',
    'city',
    'smoking',
    'drinking',
    'weed',
  ]);
  assert.equal(result.coverage, 100);
  assert.equal(result.score, 93);
});
