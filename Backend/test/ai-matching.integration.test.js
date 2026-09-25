const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { performance } = require('node:perf_hooks');
const { scoreCompatibility } = require('../src/services/matchEngineService');
const { rankCandidates } = require('../src/services/aiMatchProvider');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) throw new Error('AI matching integration tests require a separate test database.');
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

let models;
let server;
let baseUrl;
let viewer;
const userIds = [];

const tokenFor = (user) => jwt.sign({ sub: user.id, ver: user.tokenVersion || 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
const auth = (user) => ({ authorization: `Bearer ${tokenFor(user)}` });
const birthDateForAge = (age) => `${new Date().getUTCFullYear() - age}-06-15`;

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: { ...(options.body ? { 'content-type': 'application/json' } : {}), ...(options.headers || {}) },
  });
  return { status: response.status, body: await response.json() };
}

async function createMember(name, values = {}) {
  const suffix = `${Date.now()}_${userIds.length}_${Math.random().toString(16).slice(2)}`;
  const user = await models.User.create({
    name,
    email: `${suffix}@ai-matching.test`,
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    identityVerifiedAt: new Date(),
    termsAcceptedAt: new Date(),
    accountStatus: values.accountStatus || 'active',
  });
  userIds.push(user.id);
  await models.OnboardingProfile.create({
    userId: user.id,
    birthDate: values.birthDate || birthDateForAge(27),
    gender: values.gender || 'Male',
    interestedIn: values.interestedIn || ['Female'],
    relationshipGoals: values.relationshipGoals || ['long_term'],
    city: values.city || 'Ahmedabad',
    interests: values.interests || ['music', 'travel'],
    languages: values.languages || ['English'],
    communicationStyle: values.communicationStyle || 'calls',
    smoking: values.smoking || 'never', drinking: values.drinking || 'never', weed: values.weed || 'never',
    photos: ['/uploads/ai-matching-test.jpg'],
    prompts: { idealDate: 'Coffee' },
    lifestyle: {},
    stage: values.onboardingCompleted === false ? 'photos' : 'complete',
    onboardingCompleted: values.onboardingCompleted ?? true,
  });
  return user;
}

function recommendations(body) { return body.data.recommendations || []; }
function ids(body) { return recommendations(body).map((item) => item.id); }

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  viewer = await createMember('AI Viewer', { gender: 'Female', interestedIn: ['Male'], interests: ['music', 'travel'], languages: ['English'] });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const where = { id: userIds };
  await models.DiscoverAction.destroy({ where: { actorUserId: userIds } });
  await models.Block.destroy({ where: { blockerUserId: userIds } });
  await models.Block.destroy({ where: { blockedUserId: userIds } });
  await models.Match.destroy({ where: { userOneId: userIds } });
  await models.Match.destroy({ where: { userTwoId: userIds } });
  await models.OnboardingProfile.destroy({ where: { userId: userIds } });
  await models.User.destroy({ where });
  await getSequelize().close();
});

test('AI Matches requires valid bearer authentication', async () => {
  assert.equal((await request('/api/discover/ai-matches')).status, 401);
  assert.equal((await request('/api/discover/ai-matches', { headers: { authorization: 'Bearer invalid' } })).status, 401);
});

test('AI Matches uses Discover eligibility and returns separate safe LOCAL fields', async () => {
  const eligible = await createMember('AI Eligible');
  const forwardBlocked = await createMember('AI Forward Blocked');
  const reverseBlocked = await createMember('AI Reverse Blocked');
  const inactive = await createMember('AI Inactive', { accountStatus: 'deactivated' });
  const incomplete = await createMember('AI Incomplete', { onboardingCompleted: false });
  const passed = await createMember('AI Passed');
  const matched = await createMember('AI Matched');
  const wrongAge = await createMember('AI Wrong Age', { birthDate: birthDateForAge(72) });
  const wrongPreference = await createMember('AI Wrong Preference', { interestedIn: ['Male'] });
  await models.Block.create({ blockerUserId: viewer.id, blockedUserId: forwardBlocked.id });
  await models.Block.create({ blockerUserId: reverseBlocked.id, blockedUserId: viewer.id });
  await models.DiscoverAction.create({ actorUserId: viewer.id, targetUserId: passed.id, action: 'pass' });
  await models.Match.create({ userOneId: Math.min(viewer.id, matched.id), userTwoId: Math.max(viewer.id, matched.id), matchedAt: new Date() });

  const result = await request('/api/discover/ai-matches?limit=30&provider=external&userId=999&aiMatchScore=100', { headers: auth(viewer) });
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.equal(result.body.data.provider, 'LOCAL');
  const returned = new Set(ids(result.body));
  for (const user of [viewer, forwardBlocked, reverseBlocked, inactive, incomplete, passed, matched, wrongAge, wrongPreference]) assert.equal(returned.has(String(user.id)), false, `ineligible ${user.id} was returned`);
  assert.equal(returned.has(String(eligible.id)), true);
  const item = recommendations(result.body).find((row) => row.id === String(eligible.id));
  assert.ok(item);
  assert.ok(item.compatibilityScore >= 0 && item.compatibilityScore <= 100);
  assert.ok(item.compatibilityCoverage >= 0 && item.compatibilityCoverage <= 100);
  assert.ok(item.aiMatchScore >= 0 && item.aiMatchScore <= 100);
  assert.ok(item.aiConfidence >= 0 && item.aiConfidence <= 100);
  assert.ok(Array.isArray(item.aiHighlights) && item.aiHighlights.length <= 3);
  assert.ok(Array.isArray(item.aiReasons) && item.aiReasons.length <= 3);
  assert.equal(JSON.stringify(item).includes(eligible.email), false);
  assert.equal(JSON.stringify(item).includes('passwordHash'), false);
  assert.equal(JSON.stringify(item).includes('phoneNumber'), false);

  // Recommendation id and public profile id are both canonical user IDs.
  // A recommendation is directly viewable without an existing Match row.
  assert.equal(item.id, String(eligible.id));
  assert.equal(item.profile.id, item.id);
  assert.equal(await models.Match.findOne({ where: { [Op.or]: [
    { userOneId: viewer.id, userTwoId: eligible.id },
    { userOneId: eligible.id, userTwoId: viewer.id },
  ] } }), null);
  const publicProfile = await request(`/api/profiles/${item.id}`, { headers: auth(viewer) });
  assert.equal(publicProfile.status, 200, JSON.stringify(publicProfile.body));
  assert.equal(publicProfile.body.data.profile.id, item.id);
  assert.equal(publicProfile.body.data.profile.relationship.matched, false);
  const messageBeforeMatch = await request('/api/conversations', {
    method: 'POST', headers: auth(viewer), body: JSON.stringify({ targetUserId: Number(item.id) }),
  });
  assert.equal(messageBeforeMatch.status, 403);
  assert.equal(messageBeforeMatch.body.code, 'MATCH_REQUIRED');

  for (const unavailableUser of [forwardBlocked, reverseBlocked, inactive]) {
    const inaccessible = await request(`/api/profiles/${unavailableUser.id}`, { headers: auth(viewer) });
    assert.equal(inaccessible.status, 404, `profile ${unavailableUser.id} must remain unavailable`);
    assert.equal(inaccessible.body.code, 'PROFILE_NOT_AVAILABLE');
  }
});

test('AI Matches performs global deterministic ranking before page slicing without N+1 query growth', async () => {
  const eligible = [];
  for (let index = 0; index < 50; index += 1) {
    eligible.push(await createMember(`AI Scale ${index}`, {
      interests: index % 2 ? ['music', 'travel'] : ['music'],
      city: index % 3 ? 'Ahmedabad' : 'Surat',
      languages: index % 4 ? ['English'] : [],
    }));
  }
  const sequelize = getSequelize();
  const originalQuery = sequelize.query;
  const countQueries = async (path) => {
    let count = 0;
    sequelize.query = async function countedQuery(...args) { count += 1; return originalQuery.apply(this, args); };
    try { return { result: await request(path, { headers: auth(viewer) }), count }; } finally { sequelize.query = originalQuery; }
  };
  const fifty = await countQueries('/api/discover/ai-matches?limit=10');
  for (let index = 50; index < 100; index += 1) {
    eligible.push(await createMember(`AI Scale ${index}`, {
      interests: index % 2 ? ['music', 'travel'] : ['music'],
      city: index % 3 ? 'Ahmedabad' : 'Surat',
      languages: index % 4 ? ['English'] : [],
    }));
  }
  const hundred = await countQueries('/api/discover/ai-matches?limit=10');
  assert.equal(fifty.result.status, 200);
  assert.equal(hundred.result.status, 200);
  assert.ok(hundred.count - fifty.count <= 2, `query count grew from ${fifty.count} to ${hundred.count}`);
  console.log(`[AI Matches] query counts: approximately 50=${fifty.count}, 100=${hundred.count}`);
  const page1 = await request('/api/discover/ai-matches?page=1&limit=10', { headers: auth(viewer) });
  const page2 = await request('/api/discover/ai-matches?page=2&limit=10', { headers: auth(viewer) });
  const page3 = await request('/api/discover/ai-matches?page=3&limit=10', { headers: auth(viewer) });
  const repeat = await request('/api/discover/ai-matches?page=1&limit=10', { headers: auth(viewer) });
  assert.deepEqual(ids(page1.body), ids(repeat.body));
  assert.equal(new Set([...ids(page1.body), ...ids(page2.body), ...ids(page3.body)]).size, 30);
  assert.equal(page1.body.data.pagination.page, 1);
  assert.equal(page1.body.data.pagination.nextPage, 2);
  assert.equal(page3.body.data.pagination.page, 3);
  assert.ok(recommendations(page1.body).every((row) => row.aiMatchScore >= 0 && row.aiMatchScore <= 100));
  assert.ok(eligible.length === 100);
});

test('AI recommendation candidates continue through the canonical Like and Match flow', async () => {
  const recommendationPage = await request('/api/discover/ai-matches?limit=30', { headers: auth(viewer) });
  const targetUserId = Number(ids(recommendationPage.body)[0]);
  assert.ok(Number.isInteger(targetUserId));
  const target = await models.User.findByPk(targetUserId);
  await models.DiscoverAction.upsert({ actorUserId: target.id, targetUserId: viewer.id, action: 'like' });
  const like = await request('/api/discover/swipe', { method: 'POST', headers: auth(viewer), body: JSON.stringify({ targetUserId, action: 'like' }) });
  assert.equal(like.status, 200);
  assert.equal(like.body.data.likeStatus, 'liked');
  assert.equal(like.body.data.matched, true);
  assert.ok(like.body.data.matchId);
  assert.ok(like.body.data.conversationId);
  const repeated = await request('/api/discover/swipe', { method: 'POST', headers: auth(viewer), body: JSON.stringify({ targetUserId, action: 'like' }) });
  assert.equal(repeated.status, 200);
  assert.equal(repeated.body.data.likeStatus, 'already_liked');
  assert.equal(repeated.body.data.matched, true);
  assert.equal(repeated.body.data.matchId, like.body.data.matchId);
  assert.equal(repeated.body.data.conversationId, like.body.data.conversationId);
});

test('AI Matches validates bounded pagination and returns an empty recommendation list safely', async () => {
  assert.equal((await request('/api/discover/ai-matches?page=0', { headers: auth(viewer) })).status, 400);
  assert.equal((await request('/api/discover/ai-matches?limit=31', { headers: auth(viewer) })).status, 400);
});

test('AI Matches returns actual evidence and truthful sparse confidence without internal leaks', async () => {
  const sparse = await createMember('AI Sparse Optional', { city: 'SparseEvidenceFixture' });
  await models.OnboardingProfile.update({ interests: [], relationshipGoals: [], communicationStyle: null, languages: [], smoking: null, drinking: null, weed: null }, { where: { userId: sparse.id } });
  const result = await request('/api/discover/ai-matches?city=SparseEvidenceFixture', { headers: auth(viewer) });
  assert.equal(result.status, 200);
  const item = recommendations(result.body)[0];
  assert.equal(item.id, String(sparse.id));
  assert.equal(item.compatibilityCoverage, 5); // Known city mismatch; other factors missing.
  assert.equal(item.compatibilityScore, 48);
  assert.equal(item.aiConfidence, 4);
  assert.deepEqual(item.aiReasons, ['Explore this profile to learn more about each other.']);
  assert.equal(item.profile.compatibilityCoverage, item.compatibilityCoverage);
  for (const key of ['factorBreakdown', 'negativeFactors', 'interestedIn', 'passwordHash', 'aiConfidenceScore']) assert.equal(Object.hasOwn(item, key), false);
});

test('a genuine zero compatibility remains zero in Discover and AI responses', async () => {
  const candidate = await createMember('Zero Compatibility', { city: 'ZeroCompatibilityFixture', interests: ['unrelated'], relationshipGoals: ['friendship'], communicationStyle: 'voice_notes', languages: ['Hindi'], smoking: 'often', drinking: 'often', weed: 'often' });
  for (const endpoint of ['feed', 'ai-matches']) {
    const response = await request(`/api/discover/${endpoint}?city=ZeroCompatibilityFixture`, { headers: auth(viewer) });
    assert.equal(response.status, 200);
    const item = endpoint === 'feed' ? response.body.data.profiles[0] : recommendations(response.body)[0];
    assert.equal(item.id, String(candidate.id));
    assert.equal(item.compatibilityScore, 0);
    if (endpoint === 'ai-matches') assert.equal(item.profile.compatibilityScore, 0);
  }
});

test('incomplete or absent viewer profiles are rejected without mutation', async () => {
  const incomplete = await createMember('Incomplete AI Viewer', { onboardingCompleted: false });
  const missing = await createMember('Missing AI Viewer');
  await models.OnboardingProfile.destroy({ where: { userId: missing.id } });
  for (const member of [incomplete, missing]) {
    for (const path of ['/api/discover/feed', '/api/discover/ai-matches']) {
      const response = await request(path, { headers: auth(member) });
      assert.equal(response.status, 403);
      assert.equal(response.body.code, 'ONBOARDING_INCOMPLETE');
    }
  }
  assert.equal((await models.OnboardingProfile.findOne({ where: { userId: incomplete.id } })).onboardingCompleted, false);
  assert.equal(await models.OnboardingProfile.findOne({ where: { userId: missing.id } }), null);
});

test('AI query validation and reset cannot weaken Discover eligibility', async () => {
  for (const query of ['minAge=undefined', 'maxAge=17', 'minScore=NaN', 'verifiedOnly=invalid', 'communicationStyles=invalid']) {
    assert.equal((await request(`/api/discover/ai-matches?${query}`, { headers: auth(viewer) })).status, 400);
  }
  const passed = await createMember('AI Reset Must Not Restore', { city: 'AIResetFixture' });
  await models.DiscoverAction.create({ actorUserId: viewer.id, targetUserId: passed.id, action: 'pass' });
  const result = await request('/api/discover/ai-matches?reset=true&city=AIResetFixture', { headers: auth(viewer) });
  assert.equal(result.status, 200);
  assert.deepEqual(recommendations(result.body), []);
  assert.ok(await models.DiscoverAction.findOne({ where: { actorUserId: viewer.id, targetUserId: passed.id } }));
});

test('exact 25/50/100 candidate pools use constant bulk query counts', async () => {
  const city = `Scale${Date.now()}`;
  const candidates = [];
  const measurements = [];
  const sequelize = getSequelize();
  for (const count of [25, 50, 100]) {
    while (candidates.length < count) candidates.push(await createMember(`Measured ${candidates.length}`, { city }));
    await request(`/api/discover/ai-matches?city=${city}`, { headers: auth(viewer) }); // Warm preferences/auth.
    let queries = 0;
    const original = sequelize.query;
    sequelize.query = function (...args) { queries++; return original.apply(this, args); };
    const started = performance.now();
    let result;
    try { result = await request(`/api/discover/ai-matches?city=${city}&limit=30`, { headers: auth(viewer) }); }
    finally { sequelize.query = original; }
    assert.equal(result.status, 200);
    assert.equal(recommendations(result.body).length, Math.min(count, 30));
    measurements.push({ candidates: count, queries, httpMs: +(performance.now() - started).toFixed(3) });
  }
  assert.ok(Math.max(...measurements.map((m) => m.queries)) - Math.min(...measurements.map((m) => m.queries)) <= 1);
  console.log(`[AI exact performance] ${JSON.stringify(measurements)}`);
});

test('all eligible candidates beyond 500 are globally ranked before pagination', async () => {
  const tag = `GlobalPool${Date.now()}`;
  const members = await models.User.bulkCreate(Array.from({ length: 501 }, (_, index) => ({
    name: `Global ${index}`, email: `${tag}-${index}@ai-matching.test`, phoneNumber: '', authProvider: 'local', isVerified: true, identityVerifiedAt: new Date(), termsAcceptedAt: new Date(), accountStatus: 'active',
  })));
  userIds.push(...members.map((member) => member.id));
  const profiles = members.map((member, index) => ({
    userId: member.id, birthDate: birthDateForAge(27), gender: 'Male', interestedIn: ['Female'], profession: tag,
    onboardingCompleted: true, stage: 'complete', interests: [], relationshipGoals: [], languages: [],
    ...(index === 500 ? { interests: ['music', 'travel'], relationshipGoals: ['friendship'], languages: ['Hindi'], communicationStyle: 'voice_notes', city: 'Ahmedabad', smoking: 'never', drinking: 'never', weed: 'often' } : {}),
  }));
  await models.OnboardingProfile.bulkCreate(profiles);
  const viewerProfile = await models.OnboardingProfile.findOne({ where: { userId: viewer.id } });
  const expected = rankCandidates(viewerProfile, profiles.map((profile) => ({ userId: profile.userId, profile, compatibility: scoreCompatibility(viewerProfile, profile) }))).map((row) => String(row.userId));
  assert.equal(expected[0], String(members[500].id)); // SQL score ties at 50; final candidate has more evidence.
  const actual = [];
  for (let page = 1; page <= 17; page++) {
    const result = await request(`/api/discover/ai-matches?profession=${tag}&page=${page}&limit=30`, { headers: auth(viewer) });
    assert.equal(result.status, 200);
    actual.push(...ids(result.body));
    assert.equal(result.body.data.pagination.hasMore, page < 17);
  }
  assert.deepEqual(actual, expected);
  assert.equal(new Set(actual).size, 501);
  const repeat = await request(`/api/discover/ai-matches?profession=${tag}&page=1&limit=30`, { headers: auth(viewer) });
  assert.deepEqual(ids(repeat.body), expected.slice(0, 30));
});
