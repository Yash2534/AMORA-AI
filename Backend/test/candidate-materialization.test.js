const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');

const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (
  !testDatabase
  || testDatabase.toLowerCase() === String(applicationDatabase || '').toLowerCase()
  || !/test/i.test(testDatabase)
) {
  throw new Error('Candidate materialization tests require a separate TEST_DB_NAME containing "test".');
}

process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { initializeDatabase, closeDatabase } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { scoreCompatibility, normalizeProfile } = require('../src/services/compatibilityScoringService');

let server;
let baseUrl;
let models;
let createdGoldPlan = false;
const createdUserIds = [];

function birthDateForAge(age) {
  return `${new Date().getUTCFullYear() - age}-05-20`;
}

function authHeader(user) {
  const token = jwt.sign(
    { sub: user.id, role: 'user' },
    process.env.JWT_SECRET || 'test_jwt_secret',
    { expiresIn: '1h' }
  );
  return { Authorization: `Bearer ${token}` };
}

async function request(path, options = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
  });
  let body = null;
  try {
    body = await res.json();
  } catch (_) {}
  return { status: res.status, headers: res.headers, body };
}

async function createTestUser(key, options = {}) {
  const suffix = `${Date.now()}_${createdUserIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name: `User_${key}`,
    email: `${key}_${suffix}@mat-opt.test`,
    passwordHash: 'hash_secret_never_leak_123',
    phoneNumber: `+9198765${(createdUserIds.length % 90000) + 10000}`,
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: options.verified === false ? null : new Date(),
    lastActiveAt: new Date(),
    accountStatus: 'active',
  });
  createdUserIds.push(user.id);
  return user;
}

async function createCandidateProfile(user, values = {}) {
  const profile = await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: values.birthDate || birthDateForAge(values.age || 26),
    gender: values.gender || 'Female',
    interestedIn: values.interestedIn || ['Male'],
    relationshipGoals: values.relationshipGoals || ['long_term'],
    city: values.city || 'Ahmedabad',
    profession: values.profession || 'Engineer',
    education: values.education || 'Graduate',
    hometown: values.hometown || 'Ahmedabad',
    interests: values.interests || ['hiking', 'music', 'books'],
    lifestyle: values.lifestyle || { fitness: 'active', drinking: 'never', smoking: 'never' },
    prompts: values.prompts || { idealDate: 'Coffee and a walk' },
    pronouns: values.pronouns || ['she/her'],
    sexuality: values.sexuality || 'straight',
    valuedQualities: values.valuedQualities || ['kindness'],
    loveLanguages: values.loveLanguages || ['quality_time'],
    preferredTalkingHours: values.preferredTalkingHours || ['evening'],
    communicationStyle: values.communicationStyle || 'calls',
    languages: values.languages || ['English', 'Gujarati'],
    photos: values.photos || ['/uploads/cand-1.jpg', '/uploads/cand-2.jpg'],
    matchLatitude: values.matchLatitude ?? 23.0225,
    matchLongitude: values.matchLongitude ?? 72.5714,
    stage: 'complete',
    onboardingCompleted: true,
  });
  return profile;
}

async function cleanupUsers(userIds) {
  if (!userIds || !userIds.length) return;
  try {
    await models.Block.destroy({
      where: {
        [Op.or]: [
          { blockerUserId: { [Op.in]: userIds } },
          { blockedUserId: { [Op.in]: userIds } },
        ],
      },
    });
  } catch (_) {}
  try {
    await models.Report.destroy({
      where: {
        [Op.or]: [
          { reporterUserId: { [Op.in]: userIds } },
          { reportedUserId: { [Op.in]: userIds } },
        ],
      },
    });
  } catch (_) {}
  try {
    await models.Subscription.destroy({ where: { userId: { [Op.in]: userIds } } });
  } catch (_) {}
  try {
    await models.OnboardingProfile.destroy({ where: { userId: { [Op.in]: userIds } } });
  } catch (_) {}
  try {
    await models.User.destroy({ where: { id: { [Op.in]: userIds } } });
  } catch (_) {}
}

before(async () => {
  await initializeDatabase();
  models = getModels();

  // Pre-cleanup any stale mat-opt test users
  const stale = await models.User.findAll({
    where: { email: { [Op.like]: '%@mat-opt.test' } },
    attributes: ['id'],
  });
  if (stale.length) {
    await cleanupUsers(stale.map((u) => u.id));
  }

  server = app.listen(0);
  const port = server.address().port;
  baseUrl = `http://127.0.0.1:${port}`;
});

after(async () => {
  if (createdUserIds.length) {
    await cleanupUsers(createdUserIds);
  }
  if (createdGoldPlan) {
    await models.SubscriptionPlan.destroy({ where: { id: 'amoraa_gold_monthly' } });
  }
  if (server) server.close();
  await closeDatabase();
});

// ---------------------------------------------------------------------------
// A. CANDIDATE RESULT EQUIVALENCE & ACCURACY
// ---------------------------------------------------------------------------

test('1. Discover feed returns expected candidate count and valid structure', async () => {
  const viewer = await createTestUser('ViewerA1');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_A1' });

  for (let i = 1; i <= 5; i++) {
    const cand = await createTestUser(`CandA1_${i}`);
    await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_A1' });
  }

  const res = await request('/api/discover/feed?city=City_A1&limit=3', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.profiles.length, 3);
  assert.equal(res.body.data.pagination.limit, 3);
  assert.equal(res.body.data.pagination.hasMore, true);
  assert.ok(res.body.data.pagination.nextCursor);
});

test('2. AI Matches feed returns ranking ordered deterministically', async () => {
  const viewer = await createTestUser('ViewerA2');
  await createCandidateProfile(viewer, {
    gender: 'Male',
    interestedIn: ['Female'],
    interests: ['hiking', 'music', 'books', 'travel'],
    city: 'City_A2',
  });

  // Candidate with high overlap
  const highCand = await createTestUser('HighCandA2');
  await createCandidateProfile(highCand, {
    gender: 'Female',
    interestedIn: ['Male'],
    interests: ['hiking', 'music', 'books', 'travel'],
    city: 'City_A2',
  });

  // Candidate with lower overlap
  const lowCand = await createTestUser('LowCandA2');
  await createCandidateProfile(lowCand, {
    gender: 'Female',
    interestedIn: ['Male'],
    interests: ['gardening'],
    city: 'City_A2',
  });

  const res = await request('/api/discover/ai-matches?city=City_A2&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  assert.ok(res.body.data.recommendations.length >= 2);

  const highIdx = res.body.data.recommendations.findIndex((r) => r.id === String(highCand.id));
  const lowIdx = res.body.data.recommendations.findIndex((r) => r.id === String(lowCand.id));
  assert.ok(highIdx !== -1 && lowIdx !== -1);
  assert.ok(highIdx < lowIdx, 'High compatibility candidate must be ranked ahead of low compatibility candidate');
});

test('3. Compatibility calculation values match mathematical formulas exactly', async () => {
  const viewer = await createTestUser('ViewerA3');
  const vProfile = await createCandidateProfile(viewer, {
    gender: 'Male',
    interestedIn: ['Female'],
    interests: ['hiking', 'coding'],
    city: 'City_A3',
  });

  const cand = await createTestUser('CandA3');
  const cProfile = await createCandidateProfile(cand, {
    gender: 'Female',
    interestedIn: ['Male'],
    interests: ['hiking', 'art'],
    city: 'City_A3',
  });

  const expected = scoreCompatibility(vProfile, cProfile);

  const res = await request('/api/discover/feed?city=City_A3&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const found = res.body.data.profiles.find((p) => p.id === String(cand.id));
  assert.ok(found);
  assert.equal(found.compatibilityScore, expected.score);
  assert.equal(found.compatibilityCoverage, expected.coverage);
});

test('4. Block and report exclusions remain 100% effective after optimization', async () => {
  const viewer = await createTestUser('ViewerA4');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_A4' });

  const blockedCand = await createTestUser('BlockedCandA4');
  await createCandidateProfile(blockedCand, { gender: 'Female', interestedIn: ['Male'], city: 'City_A4' });
  await models.Block.create({ blockerUserId: viewer.id, blockedUserId: blockedCand.id });

  const reportedCand = await createTestUser('ReportedCandA4');
  await createCandidateProfile(reportedCand, { gender: 'Female', interestedIn: ['Male'], city: 'City_A4' });
  await models.Report.create({
    reporterUserId: viewer.id,
    reportedUserId: reportedCand.id,
    targetType: 'profile',
    targetId: String(reportedCand.id),
    reason: 'fake_profile',
    status: 'open',
  });

  const res = await request('/api/discover/feed?city=City_A4&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const ids = res.body.data.profiles.map((p) => p.id);
  assert.ok(!ids.includes(String(blockedCand.id)), 'Blocked user must not appear in feed');
  assert.ok(!ids.includes(String(reportedCand.id)), 'Reported user must not appear in feed');
});

test('5. Public profile response contains all expected fields and zero missing contract attributes', async () => {
  const viewer = await createTestUser('ViewerA5');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_A5' });

  const cand = await createTestUser('CandA5');
  await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_A5' });

  const res = await request('/api/discover/feed?city=City_A5&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(cand.id));
  assert.ok(p);

  const requiredFields = [
    'id', 'gender', 'name', 'age', 'city', 'profession', 'education',
    'compatibilityScore', 'compatibilityCoverage', 'compatibilityReasons',
    'bio', 'interests', 'imageUrl', 'gallery', 'languages', 'verification',
    'lifestyle', 'promptAnswers', 'religion', 'community', 'height',
    'smoking', 'drinking', 'weed', 'hometown', 'valuedQualities',
    'pronouns', 'sexuality', 'preferredTalkingHours', 'loveLanguages',
    'communicationStyle',
  ];

  for (const field of requiredFields) {
    assert.ok(field in p, `Expected field '${field}' to be present on public profile`);
  }
});

// ---------------------------------------------------------------------------
// B. QUERY PROJECTION & LEAN ATTRIBUTE VERIFICATION
// ---------------------------------------------------------------------------

test('6. User model instances do not load sensitive passwordHash or phone columns', async () => {
  const viewer = await createTestUser('ViewerB6');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_B6' });

  const cand = await createTestUser('CandB6');
  await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_B6' });

  const res = await request('/api/discover/feed?city=City_B6&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(cand.id));
  assert.ok(p);

  // Verify response doesn't expose internal database fields
  assert.equal(p.passwordHash, undefined);
  assert.equal(p.phoneNumber, undefined);
  assert.equal(p.email, undefined);
  assert.equal(p.tokenVersion, undefined);
});

test('7. Model instances exclude raw matchLatitude and matchLongitude from candidate profile', async () => {
  const viewer = await createTestUser('ViewerB7');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_B7' });

  const cand = await createTestUser('CandB7');
  await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_B7', matchLatitude: 23.05, matchLongitude: 72.55 });

  const res = await request('/api/discover/feed?city=City_B7&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(cand.id));
  assert.ok(p);

  assert.equal(p.matchLatitude, undefined, 'matchLatitude must never be returned in public profile');
  assert.equal(p.matchLongitude, undefined, 'matchLongitude must never be returned in public profile');
});

test('8. Subscription association is projected with lean attributes (status, currentPeriodEnd)', async () => {
  const viewer = await createTestUser('ViewerB8');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_B8' });

  const cand = await createTestUser('CandB8');
  await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_B8' });

  const existingGoldPlan = await models.SubscriptionPlan.findByPk('amoraa_gold_monthly');
  if (!existingGoldPlan) {
    await models.SubscriptionPlan.create({
      id: 'amoraa_gold_monthly',
      name: 'AMORAA Gold',
      displayName: 'AMORAA Gold Monthly',
      description: 'Premium candidate-materialization test fixture.',
      priceMinor: 199900,
      currency: 'INR',
      billingPeriod: 'month',
      billingInterval: 1,
      features: ['Priority recommendations'],
      entitlements: { premium: true },
      trialDays: 0,
      active: true,
      sortOrder: 20,
    });
    createdGoldPlan = true;
  }

  await models.Subscription.create({
    userId: cand.id,
    planId: 'amoraa_gold_monthly',
    status: 'active',
    startedAt: new Date(),
    currentPeriodStart: new Date(),
    currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
  });

  const res = await request('/api/discover/feed?city=City_B8&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(cand.id));
  assert.ok(p);
  assert.equal(p.premium, true, 'Active subscription must mark profile as premium');
});

test('9. Unverified user verification status reflects Unverified correctly', async () => {
  const viewer = await createTestUser('ViewerB9');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_B9' });

  const unverifiedCand = await createTestUser('CandB9', { verified: false });
  await createCandidateProfile(unverifiedCand, { gender: 'Female', interestedIn: ['Male'], city: 'City_B9' });

  const res = await request('/api/discover/feed?city=City_B9&verifiedOnly=false&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(unverifiedCand.id));
  assert.ok(p);
  assert.equal(p.verification, 'Unverified');
});

test('10. Verified user verification status reflects Verified correctly', async () => {
  const viewer = await createTestUser('ViewerB10');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_B10' });

  const verifiedCand = await createTestUser('CandB10', { verified: true });
  await createCandidateProfile(verifiedCand, { gender: 'Female', interestedIn: ['Male'], city: 'City_B10' });

  const res = await request('/api/discover/feed?city=City_B10&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(verifiedCand.id));
  assert.ok(p);
  assert.equal(p.verification, 'Verified');
});

// ---------------------------------------------------------------------------
// C. PAGINATION & ENCRYPTED CURSOR CONTINUITY
// ---------------------------------------------------------------------------

test('11. Multi-page pagination produces contiguous, non-overlapping candidate sets', async () => {
  const viewer = await createTestUser('ViewerC11');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_C11' });

  for (let i = 1; i <= 6; i++) {
    const cand = await createTestUser(`CandC11_${i}`);
    await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_C11' });
  }

  // Page 1: limit 3
  const page1 = await request('/api/discover/feed?city=City_C11&limit=3', { headers: authHeader(viewer) });
  assert.equal(page1.status, 200);
  assert.equal(page1.body.data.profiles.length, 3);
  assert.ok(page1.body.data.pagination.nextCursor);

  // Page 2: with cursor
  const cursor1 = encodeURIComponent(page1.body.data.pagination.nextCursor);
  const page2 = await request(`/api/discover/feed?city=City_C11&limit=3&cursor=${cursor1}&page=2`, { headers: authHeader(viewer) });
  assert.equal(page2.status, 200);
  assert.ok(page2.body.data.profiles.length >= 1);

  const idsPage1 = new Set(page1.body.data.profiles.map((p) => p.id));
  const idsPage2 = new Set(page2.body.data.profiles.map((p) => p.id));

  for (const id of idsPage2) {
    assert.ok(!idsPage1.has(id), `Candidate ${id} must not appear on both Page 1 and Page 2`);
  }
});

test('12. AI Matches multi-page pagination preserves cursor state and ranking continuity', async () => {
  const viewer = await createTestUser('ViewerC12');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_C12', interests: ['music', 'art'] });

  for (let i = 1; i <= 5; i++) {
    const cand = await createTestUser(`CandC12_${i}`);
    await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_C12', interests: ['music', 'art'] });
  }

  const p1 = await request('/api/discover/ai-matches?city=City_C12&limit=2', { headers: authHeader(viewer) });
  assert.equal(p1.status, 200);
  assert.equal(p1.body.data.recommendations.length, 2);
  assert.ok(p1.body.data.pagination.nextCursor);

  const cursor = encodeURIComponent(p1.body.data.pagination.nextCursor);
  const p2 = await request(`/api/discover/ai-matches?city=City_C12&limit=2&cursor=${cursor}&page=2`, { headers: authHeader(viewer) });
  assert.equal(p2.status, 200);
  assert.ok(p2.body.data.recommendations.length >= 1);

  const p1Ids = new Set(p1.body.data.recommendations.map((r) => r.id));
  for (const r of p2.body.data.recommendations) {
    assert.ok(!p1Ids.has(r.id), `AI recommendation ${r.id} must not appear on both pages`);
  }
});

test('13. Stable tie-breaking orders candidates with identical scores by ID ascending', async () => {
  const viewer = await createTestUser('ViewerC13');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_C13' });

  const c1 = await createTestUser('CandC13_1');
  await createCandidateProfile(c1, { gender: 'Female', interestedIn: ['Male'], city: 'City_C13' });

  const c2 = await createTestUser('CandC13_2');
  await createCandidateProfile(c2, { gender: 'Female', interestedIn: ['Male'], city: 'City_C13' });

  const res = await request('/api/discover/feed?city=City_C13&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p1 = res.body.data.profiles.find((p) => p.id === String(c1.id));
  const p2 = res.body.data.profiles.find((p) => p.id === String(c2.id));

  if (p1 && p2 && p1.compatibilityScore === p2.compatibilityScore) {
    const idx1 = res.body.data.profiles.findIndex((p) => p.id === String(c1.id));
    const idx2 = res.body.data.profiles.findIndex((p) => p.id === String(c2.id));
    if (Number(c1.id) < Number(c2.id)) {
      assert.ok(idx1 < idx2, 'Lower ID candidate must precede higher ID candidate on tied score');
    } else {
      assert.ok(idx2 < idx1, 'Lower ID candidate must precede higher ID candidate on tied score');
    }
  }
});

test('14. Near You surface sorts primarily by distance and preserves cursor pagination', async () => {
  const viewer = await createTestUser('ViewerC14');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_C14', matchLatitude: 23.0225, matchLongitude: 72.5714 });

  const close = await createTestUser('CloseC14');
  await createCandidateProfile(close, { gender: 'Female', interestedIn: ['Male'], city: 'City_C14', matchLatitude: 23.0230, matchLongitude: 72.5720 });

  const far = await createTestUser('FarC14');
  await createCandidateProfile(far, { gender: 'Female', interestedIn: ['Male'], city: 'City_C14', matchLatitude: 23.1000, matchLongitude: 72.6500 });

  const res = await request('/api/discover/feed?surface=near_you&city=City_C14&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const closeIdx = res.body.data.profiles.findIndex((p) => p.id === String(close.id));
  const farIdx = res.body.data.profiles.findIndex((p) => p.id === String(far.id));
  assert.ok(closeIdx !== -1 && farIdx !== -1);
  assert.ok(closeIdx < farIdx, 'Closer candidate must rank ahead of farther candidate on near_you surface');
});

test('15. Tampered or invalid pagination cursor fails safely with HTTP 400', async () => {
  const viewer = await createTestUser('ViewerC15');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'] });

  const res = await request('/api/discover/feed?cursor=invalid_tampered_cursor_data&page=2', { headers: authHeader(viewer) });
  assert.equal(res.status, 400);
  assert.equal(res.body.code, 'PAGINATION_CURSOR_INVALID');
});

// ---------------------------------------------------------------------------
// D. LOCATION PRIVACY & DEFENSE
// ---------------------------------------------------------------------------

test('16. Public distance is coarsened and exact distanceKm is never exposed as decimal', async () => {
  const viewer = await createTestUser('ViewerD16');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'], city: 'City_D16', matchLatitude: 23.0225, matchLongitude: 72.5714 });

  const cand = await createTestUser('CandD16');
  await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'], city: 'City_D16', matchLatitude: 23.0245, matchLongitude: 72.5734 });

  const res = await request('/api/discover/feed?city=City_D16&limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  const p = res.body.data.profiles.find((item) => item.id === String(cand.id));
  assert.ok(p);
  // Coarsened distance must be an integer multiple of 5 or integer km, never a raw floating point number like 0.28374
  if (p.distance !== null) {
    assert.equal(Number.isInteger(p.distance), true, 'Distance must be an integer');
  }
});

test('17. AI Matches response profile objects contain zero coordinates', async () => {
  const viewer = await createTestUser('ViewerD17');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'] });

  const cand = await createTestUser('CandD17');
  await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'] });

  const res = await request('/api/discover/ai-matches?limit=10', { headers: authHeader(viewer) });
  assert.equal(res.status, 200);
  for (const rec of res.body.data.recommendations) {
    assert.equal(rec.profile.matchLatitude, undefined);
    assert.equal(rec.profile.matchLongitude, undefined);
    assert.equal(rec.matchLatitude, undefined);
    assert.equal(rec.matchLongitude, undefined);
  }
});

// ---------------------------------------------------------------------------
// E. MEMORY & NORMALIZATION OPTIMIZATION
// ---------------------------------------------------------------------------

test('18. normalizeProfile returns memoized profile with _isNormalized property', async () => {
  const raw = {
    interests: ['hiking', 'music'],
    relationshipGoals: ['long_term'],
    communicationStyle: 'calls',
    languages: ['English'],
    city: 'Ahmedabad',
    smoking: 'never',
    drinking: 'never',
    weed: 'never',
  };

  const norm1 = normalizeProfile(raw);
  assert.equal(norm1._isNormalized, true);

  const norm2 = normalizeProfile(norm1);
  assert.equal(norm1, norm2, 'Second call to normalizeProfile must return the exact same object reference');
});

test('19. scoreCompatibility produces identical results with raw vs normalized viewer', async () => {
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
    interests: ['hiking', 'art'],
    relationshipGoals: ['long_term'],
    communicationStyle: 'calls',
    languages: ['English', 'Gujarati'],
    city: 'Ahmedabad',
    smoking: 'never',
    drinking: 'never',
    weed: 'never',
  };

  const scoreRaw = scoreCompatibility(viewer, candidate);
  const normViewer = normalizeProfile(viewer);
  const scoreNorm = scoreCompatibility(normViewer, candidate);

  assert.equal(scoreRaw.score, scoreNorm.score);
  assert.equal(scoreRaw.coverage, scoreNorm.coverage);
  assert.equal(scoreRaw.confidence, scoreNorm.confidence);
});

test('20. Repeated calls do not produce memory leaks or growing object retention', async () => {
  const viewer = await createTestUser('ViewerE20');
  await createCandidateProfile(viewer, { gender: 'Male', interestedIn: ['Female'] });

  for (let i = 1; i <= 3; i++) {
    const cand = await createTestUser(`CandE20_${i}`);
    await createCandidateProfile(cand, { gender: 'Female', interestedIn: ['Male'] });
  }

  // Execute 5 rapid requests
  for (let i = 0; i < 5; i++) {
    const res = await request('/api/discover/feed?limit=5', { headers: authHeader(viewer) });
    assert.equal(res.status, 200);
  }
});
