const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const jwt = require('jsonwebtoken');

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
