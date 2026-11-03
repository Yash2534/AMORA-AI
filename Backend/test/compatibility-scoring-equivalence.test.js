const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');

require('../src/config/bootstrapEnv');

const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (
  !testDatabase
  || testDatabase.toLowerCase() === String(applicationDatabase || '').toLowerCase()
  || !/test/i.test(testDatabase)
) {
  throw new Error('Compatibility scoring equivalence tests require a separate TEST_DB_NAME containing "test".');
}

process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { initializeDatabase, closeDatabase, getSequelize } = require('../src/config/db');
const {
  MATCH_FACTORS,
  SCORE_WEIGHTS,
  TOTAL_WEIGHT,
  normalizeProfile,
  scoreCompatibility,
  sqlCompatibilityExpressions,
} = require('../src/services/compatibilityScoringService');

let sequelize;

before(async () => {
  await initializeDatabase();
  sequelize = getSequelize();
});

after(async () => {
  await closeDatabase();
});

async function evaluateSqlScore(viewer, candidate) {
  const expressions = sqlCompatibilityExpressions(sequelize, viewer);
  const columns = Object.entries(candidate)
    .map(([key, value]) => {
      const quoted = sequelize.getQueryInterface().queryGenerator.quoteIdentifier(key);
      if (value === null || value === undefined) return `NULL AS ${quoted}`;
      if (Array.isArray(value) || typeof value === 'object') {
        return `${sequelize.escape(JSON.stringify(value))} AS ${quoted}`;
      }
      return `${sequelize.escape(String(value))} AS ${quoted}`;
    })
    .join(', ');

  const sql = `SELECT ${expressions.score} AS score, ${expressions.coverage} AS coverage, ${expressions.availableWeight} AS availableWeight, ${expressions.weightedAgreement} AS weightedAgreement FROM (SELECT ${columns}) AS OnboardingProfile`;
  const [rows] = await sequelize.query(sql);
  return {
    score: Number(rows[0].score),
    coverage: Number(rows[0].coverage),
    availableWeight: Number(rows[0].availableWeight),
    weightedAgreement: Number(rows[0].weightedAgreement),
  };
}

// ---------------------------------------------------------------------------
// A. FACTOR-BY-FACTOR TESTS (ALL 8 FACTORS INDEPENDENTLY)
// ---------------------------------------------------------------------------

test('A1. Interests factor (weight 35, list): matching, partial, disjoint, empty, null', async () => {
  const viewer = { interests: ['hiking', 'music', 'books'] };

  const cases = [
    { interests: ['hiking', 'music', 'books'] }, // 100% overlap -> 3/3
    { interests: ['hiking', 'music'] },          // 2/3 overlap
    { interests: ['hiking', 'music', 'travel', 'cooking'] }, // 2/4 overlap
    { interests: ['art', 'gaming'] },            // 0 overlap
    { interests: [] },                           // Empty list -> unavailable
    { interests: null },                         // Null -> unavailable
    { interests: ['  HIKING  ', 'Music', 'hiking'] }, // Case, whitespace, duplicate
    { interests: ['prefer not to say', 'hiking'] },  // Decline filtering
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Interests score mismatch for ${JSON.stringify(cand.interests)}`);
    assert.equal(actual.coverage, expected.coverage, `Interests coverage mismatch for ${JSON.stringify(cand.interests)}`);
  }
});

test('A2. Relationship goals factor (weight 25, list): matching, partial, disjoint, empty, null', async () => {
  const viewer = { relationshipGoals: ['long_term', 'marriage'] };

  const cases = [
    { relationshipGoals: ['long_term', 'marriage'] },
    { relationshipGoals: ['long_term'] },
    { relationshipGoals: ['casual', 'friendship'] },
    { relationshipGoals: [] },
    { relationshipGoals: null },
    { relationshipGoals: [' LONG_TERM ', 'marriage'] },
    { relationshipGoals: ['prefer not to say'] },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Goals score mismatch for ${JSON.stringify(cand.relationshipGoals)}`);
    assert.equal(actual.coverage, expected.coverage, `Goals coverage mismatch for ${JSON.stringify(cand.relationshipGoals)}`);
  }
});

test('A3. Communication style factor (weight 10, scalar): exact match, mismatch, whitespace, empty, null', async () => {
  const viewer = { communicationStyle: 'calls' };

  const cases = [
    { communicationStyle: 'calls' },
    { communicationStyle: ' Calls ' },
    { communicationStyle: 'CALLS' },
    { communicationStyle: 'voice_notes' },
    { communicationStyle: '' },
    { communicationStyle: null },
    { communicationStyle: 'prefer not to say' },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Comm style score mismatch for ${cand.communicationStyle}`);
    assert.equal(actual.coverage, expected.coverage, `Comm style coverage mismatch for ${cand.communicationStyle}`);
  }
});

test('A4. Languages factor (weight 10, list): exact match, subset, disjoint, case, empty, null', async () => {
  const viewer = { languages: ['English', 'Gujarati', 'Hindi'] };

  const cases = [
    { languages: ['English', 'Gujarati', 'Hindi'] },
    { languages: ['English'] },
    { languages: ['French', 'German'] },
    { languages: [] },
    { languages: null },
    { languages: [' english ', 'HINDI'] },
    { languages: ['prefer not to say'] },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Languages score mismatch for ${JSON.stringify(cand.languages)}`);
    assert.equal(actual.coverage, expected.coverage, `Languages coverage mismatch for ${JSON.stringify(cand.languages)}`);
  }
});

test('A5. City factor (weight 5, scalar): match, mismatch, case-insensitive, empty, null', async () => {
  const viewer = { city: 'Ahmedabad' };

  const cases = [
    { city: 'Ahmedabad' },
    { city: ' ahmedabad ' },
    { city: 'AHMEDABAD' },
    { city: 'Mumbai' },
    { city: '' },
    { city: null },
    { city: 'prefer not to say' },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `City score mismatch for ${cand.city}`);
    assert.equal(actual.coverage, expected.coverage, `City coverage mismatch for ${cand.city}`);
  }
});

test('A6. Smoking factor (weight 5, scalar): match, mismatch, empty, null', async () => {
  const viewer = { smoking: 'never' };

  const cases = [
    { smoking: 'never' },
    { smoking: ' Never ' },
    { smoking: 'socially' },
    { smoking: '' },
    { smoking: null },
    { smoking: 'prefer not to say' },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Smoking score mismatch for ${cand.smoking}`);
    assert.equal(actual.coverage, expected.coverage, `Smoking coverage mismatch for ${cand.smoking}`);
  }
});

test('A7. Drinking factor (weight 5, scalar): match, mismatch, empty, null', async () => {
  const viewer = { drinking: 'never' };

  const cases = [
    { drinking: 'never' },
    { drinking: ' Never ' },
    { drinking: 'socially' },
    { drinking: '' },
    { drinking: null },
    { drinking: 'prefer not to say' },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Drinking score mismatch for ${cand.drinking}`);
    assert.equal(actual.coverage, expected.coverage, `Drinking coverage mismatch for ${cand.drinking}`);
  }
});

test('A8. Weed factor (weight 5, scalar): match, mismatch, empty, null', async () => {
  const viewer = { weed: 'never' };

  const cases = [
    { weed: 'never' },
    { weed: ' Never ' },
    { weed: 'regularly' },
    { weed: '' },
    { weed: null },
    { weed: 'prefer not to say' },
  ];

  for (const cand of cases) {
    const actual = await evaluateSqlScore(viewer, cand);
    const expected = scoreCompatibility(viewer, cand);
    assert.equal(actual.score, expected.score, `Weed score mismatch for ${cand.weed}`);
    assert.equal(actual.coverage, expected.coverage, `Weed coverage mismatch for ${cand.weed}`);
  }
});

// ---------------------------------------------------------------------------
// B. FORMULA TESTS (AGGREGATION, COVERAGE, CLAMPING)
// ---------------------------------------------------------------------------

test('B1. All eight factors available with 100% agreement produces score 100 and coverage 100', async () => {
  const profile = {
    interests: ['hiking', 'music'],
    relationshipGoals: ['long_term'],
    communicationStyle: 'calls',
    languages: ['English', 'Gujarati'],
    city: 'Ahmedabad',
    smoking: 'never',
    drinking: 'never',
    weed: 'never',
  };

  const actual = await evaluateSqlScore(profile, profile);
  const expected = scoreCompatibility(profile, profile);

  assert.equal(actual.score, 100);
  assert.equal(actual.coverage, 100);
  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

test('B2. All eight factors available with 0% agreement produces score 0 and coverage 100', async () => {
  const viewer = {
    interests: ['hiking', 'music'],
    relationshipGoals: ['long_term'],
    communicationStyle: 'calls',
    languages: ['English'],
    city: 'Ahmedabad',
    smoking: 'never',
    drinking: 'never',
    weed: 'never',
  };

  const candidate = {
    interests: ['coding', 'art'],
    relationshipGoals: ['casual'],
    communicationStyle: 'texts',
    languages: ['French'],
    city: 'Mumbai',
    smoking: 'often',
    drinking: 'often',
    weed: 'often',
  };

  const actual = await evaluateSqlScore(viewer, candidate);
  const expected = scoreCompatibility(viewer, candidate);

  assert.equal(actual.score, 0);
  assert.equal(actual.coverage, 100);
  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

test('B3. Zero factors available produces baseline score 50 and coverage 0', async () => {
  const empty = {
    interests: [],
    relationshipGoals: [],
    communicationStyle: null,
    languages: [],
    city: null,
    smoking: null,
    drinking: null,
    weed: null,
  };

  const actual = await evaluateSqlScore(empty, empty);
  const expected = scoreCompatibility(empty, empty);

  assert.equal(actual.score, 50);
  assert.equal(actual.coverage, 0);
  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

test('B4. Only interests available (weight 35) produces calibrated partial score', async () => {
  const viewer = {
    interests: ['music', 'hiking'],
    relationshipGoals: [],
    communicationStyle: null,
    languages: [],
    city: null,
    smoking: null,
    drinking: null,
    weed: null,
  };

  const candidate = {
    interests: ['music', 'hiking'],
    relationshipGoals: [],
    communicationStyle: null,
    languages: [],
    city: null,
    smoking: null,
    drinking: null,
    weed: null,
  };

  const actual = await evaluateSqlScore(viewer, candidate);
  const expected = scoreCompatibility(viewer, candidate);

  // 100% agreement on 35 weight: 50 + 35 - 35/2 = 50 + 17.5 = 68 (rounded)
  assert.equal(actual.score, 68);
  assert.equal(actual.coverage, 35);
  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

test('B5. Only scalar factors available evaluates exact fractional score aggregation', async () => {
  const viewer = {
    interests: [],
    relationshipGoals: [],
    communicationStyle: 'calls', // 10
    languages: [],
    city: 'Ahmedabad',           // 5
    smoking: 'never',            // 5
    drinking: 'never',           // 5
    weed: 'never',               // 5
  };

  const candidate = {
    interests: [],
    relationshipGoals: [],
    communicationStyle: 'calls', // match: +5
    city: 'Ahmedabad',           // match: +2.5
    smoking: 'often',            // mismatch: -2.5
    drinking: 'often',           // mismatch: -2.5
    weed: 'never',               // match: +2.5
  };

  const actual = await evaluateSqlScore(viewer, candidate);
  const expected = scoreCompatibility(viewer, candidate);

  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
  assert.equal(actual.availableWeight, expected.availableWeight);
});

// ---------------------------------------------------------------------------
// C. EDGE-CASE & ROBUSTNESS TESTS
// ---------------------------------------------------------------------------

test('C1. Missing candidate columns or completely null profile rows handle safely', async () => {
  const viewer = {
    interests: ['music'],
    relationshipGoals: ['long_term'],
    communicationStyle: 'calls',
    languages: ['English'],
    city: 'Ahmedabad',
    smoking: 'never',
    drinking: 'never',
    weed: 'never',
  };

  const nullCand = {
    interests: null,
    relationshipGoals: null,
    communicationStyle: null,
    languages: null,
    city: null,
    smoking: null,
    drinking: null,
    weed: null,
  };

  const actual = await evaluateSqlScore(viewer, nullCand);
  const expected = scoreCompatibility(viewer, nullCand);

  assert.equal(actual.score, 50);
  assert.equal(actual.coverage, 0);
  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

test('C2. Duplicate array values in candidate do not inflate count or score artificially', async () => {
  const viewer = { interests: ['hiking', 'music'] };
  const dupeCand = { interests: ['hiking', 'hiking', 'hiking', 'music', 'music'] };

  const actual = await evaluateSqlScore(viewer, dupeCand);
  const expected = scoreCompatibility(viewer, dupeCand);

  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

test('C3. Extreme dirty array elements (numbers, booleans, invalid strings) are filtered safely', async () => {
  const viewer = { interests: ['music', 'travel'] };
  const dirtyCand = { interests: ['music', 42, false, null, '', '   ', 'prefer not to say', 'travel'] };

  const actual = await evaluateSqlScore(viewer, dirtyCand);
  const expected = scoreCompatibility(viewer, dirtyCand);

  assert.equal(actual.score, expected.score);
  assert.equal(actual.coverage, expected.coverage);
});

// ---------------------------------------------------------------------------
// D. COMPREHENSIVE COMBINATORIAL MATRIX (64 COMBINATIONS)
// ---------------------------------------------------------------------------

test('D1. Exhaustive 64-profile matrix guarantees 100% numerical score agreement', async () => {
  const viewer = {
    interests: ['Music', 'Art', 'Hiking'],
    relationshipGoals: ['long_term'],
    communicationStyle: 'calls',
    languages: ['English', 'Gujarati'],
    city: 'Ahmedabad',
    smoking: 'never',
    drinking: 'occasionally',
    weed: 'never',
  };

  const options = {
    interests: [['music', 'art'], ['coding'], [], null],
    relationshipGoals: [['long_term'], ['casual'], null],
    communicationStyle: ['calls', 'texts', null],
    languages: [['English'], ['Hindi'], null],
    city: ['Ahmedabad', 'Surat', null],
    smoking: ['never', 'often', null],
    drinking: ['occasionally', 'often', null],
    weed: ['never', 'often', null],
  };

  let tested = 0;
  for (let i = 0; i < 64; i++) {
    const candidate = {
      interests: options.interests[i % options.interests.length],
      relationshipGoals: options.relationshipGoals[(i + 1) % options.relationshipGoals.length],
      communicationStyle: options.communicationStyle[(i + 2) % options.communicationStyle.length],
      languages: options.languages[(i + 3) % options.languages.length],
      city: options.city[(i + 4) % options.city.length],
      smoking: options.smoking[(i + 5) % options.smoking.length],
      drinking: options.drinking[(i + 6) % options.drinking.length],
      weed: options.weed[(i + 7) % options.weed.length],
    };

    const actual = await evaluateSqlScore(viewer, candidate);
    const expected = scoreCompatibility(viewer, candidate);

    assert.equal(actual.score, expected.score, `Score mismatch on iteration ${i}`);
    assert.equal(actual.coverage, expected.coverage, `Coverage mismatch on iteration ${i}`);
    tested++;
  }

  assert.equal(tested, 64);
});
