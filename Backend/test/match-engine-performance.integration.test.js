const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const { performance } = require('node:perf_hooks');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Match Engine performance certification requires a separate test database.');
}
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
let candidates;
const certificationTag = `Phase7Scale${Date.now()}`;
const birthDate = `${new Date().getUTCFullYear() - 28}-06-15`;

const tokenFor = (user) => jwt.sign({ sub: user.id, ver: user.tokenVersion || 0 }, process.env.JWT_SECRET, { expiresIn: '15m' });
async function request(path) {
  const response = await fetch(`${baseUrl}${path}`, { headers: { authorization: `Bearer ${tokenFor(viewer)}` } });
  return { status: response.status, body: await response.json() };
}

async function measured(path) {
  const sequelize = getSequelize();
  const original = sequelize.query;
  let queries = 0;
  sequelize.query = function countedQuery(...args) { queries += 1; return original.apply(this, args); };
  const heapBefore = process.memoryUsage().heapUsed;
  const startedAt = performance.now();
  let response;
  try { response = await request(path); } finally { sequelize.query = original; }
  return {
    response,
    queries,
    durationMs: Number((performance.now() - startedAt).toFixed(3)),
    heapDeltaBytes: process.memoryUsage().heapUsed - heapBefore,
  };
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  viewer = await models.User.create({
    name: 'Phase 7 Performance Viewer', email: `${certificationTag}.viewer@example.test`, phoneNumber: '',
    authProvider: 'local', isVerified: true, identityVerifiedAt: new Date(), termsAcceptedAt: new Date(), accountStatus: 'active',
  });
  await models.OnboardingProfile.create({
    userId: viewer.id, birthDate, gender: 'Female', interestedIn: ['Male'], relationshipGoals: ['long_term'],
    city: 'Ahmedabad', interests: ['music', 'travel'], languages: ['English'], communicationStyle: 'calls',
    smoking: 'never', drinking: 'never', weed: 'never', photos: ['/uploads/phase7-viewer-1.jpg', '/uploads/phase7-viewer-2.jpg'],
    matchLatitude: 23.0225, matchLongitude: 72.5714, locationUpdatedAt: new Date(), stage: 'complete', onboardingCompleted: true,
  });
  candidates = await models.User.bulkCreate(Array.from({ length: 1000 }, (_, index) => ({
    name: `Phase 7 Candidate ${index}`,
    email: `${certificationTag}.${index}@example.test`, phoneNumber: '', authProvider: 'local', isVerified: true,
    identityVerifiedAt: new Date(), termsAcceptedAt: new Date(), accountStatus: 'active',
  })));
  await models.OnboardingProfile.bulkCreate(candidates.map((candidate, index) => ({
    userId: candidate.id, birthDate, gender: 'Male', interestedIn: ['Female'], relationshipGoals: ['long_term'],
    city: index % 2 ? 'Ahmedabad' : 'Gandhinagar', profession: 'phase7_inactive',
    interests: index % 3 ? ['music'] : ['music', 'travel'], languages: ['English'], communicationStyle: index % 2 ? 'calls' : 'voice_notes',
    smoking: 'never', drinking: 'never', weed: 'never', photos: ['/uploads/phase7-1.jpg', '/uploads/phase7-2.jpg'],
    matchLatitude: 23.0225 + ((index % 100) * 0.00001), matchLongitude: 72.5714 + ((index % 50) * 0.00001),
    locationUpdatedAt: new Date(), stage: 'complete', onboardingCompleted: true,
  })));
  await models.DiscoverFilterPreference.create({ userId: viewer.id, minAge: 18, maxAge: 45, maxDistanceKm: 300, minScore: 0 });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const ids = [viewer.id, ...candidates.map((candidate) => candidate.id)];
  await models.DiscoverFilterPreference.destroy({ where: { userId: ids } });
  await models.OnboardingProfile.destroy({ where: { userId: ids } });
  await models.User.destroy({ where: { id: ids } });
  await getSequelize().close();
});

test('100/500/1000 candidate recommendation performance is deterministic and query-bounded', async () => {
  const results = [];
  let activated = 0;
  for (const count of [100, 500, 1000]) {
    const next = candidates.slice(activated, count).map((candidate) => candidate.id);
    await models.OnboardingProfile.update({ profession: certificationTag }, { where: { userId: { [Op.in]: next } } });
    activated = count;
    const suffix = `profession=${encodeURIComponent(certificationTag)}&limit=30`;
    await request(`/api/discover/feed?${suffix}`);
    const discover = await measured(`/api/discover/feed?${suffix}`);
    const nearYou = await measured(`/api/discover/feed?surface=near_you&${suffix}`);
    const ai = await measured(`/api/discover/ai-matches?${suffix}`);
    for (const measurement of [discover, nearYou, ai]) {
      assert.equal(measurement.response.status, 200, JSON.stringify(measurement.response.body));
    }
    assert.equal(discover.response.body.data.profiles.length, 30);
    assert.equal(nearYou.response.body.data.profiles.length, 30);
    assert.equal(ai.response.body.data.recommendations.length, 30);
    results.push({
      candidates: count,
      discover: { ms: discover.durationMs, queries: discover.queries, heapDeltaBytes: discover.heapDeltaBytes },
      nearYou: { ms: nearYou.durationMs, queries: nearYou.queries, heapDeltaBytes: nearYou.heapDeltaBytes },
      ai: { ms: ai.durationMs, queries: ai.queries, heapDeltaBytes: ai.heapDeltaBytes },
    });
  }
  for (const surface of ['discover', 'nearYou', 'ai']) {
    const counts = results.map((result) => result[surface].queries);
    // Auth may perform its bounded lastActiveAt refresh once every 30 seconds
    // (one read plus one update) during this intentionally long test.
    assert.ok(Math.max(...counts) - Math.min(...counts) <= 2, `${surface} query count grew with candidate count: ${counts}`);
  }
  console.log(`[Phase 7 performance] ${JSON.stringify(results)}`);
});

test('Near You walks at least 100 candidates exactly once to exhaustion', async () => {
  await models.OnboardingProfile.update({ profession: 'phase7_inactive' }, { where: { userId: candidates.map((candidate) => candidate.id) } });
  await models.OnboardingProfile.update({ profession: certificationTag }, { where: { userId: candidates.slice(0, 100).map((candidate) => candidate.id) } });
  const ids = [];
  let cursor = null;
  do {
    const response = await request(`/api/discover/feed?surface=near_you&profession=${encodeURIComponent(certificationTag)}&limit=30${cursor ? `&cursor=${encodeURIComponent(cursor)}` : ''}`);
    assert.equal(response.status, 200, JSON.stringify(response.body));
    ids.push(...response.body.data.profiles.map((profile) => profile.id));
    cursor = response.body.data.pagination.nextCursor;
    if (!cursor) {
      assert.equal(response.body.data.pagination.hasMore, false);
      assert.equal(response.body.data.pagination.nextCursor, null);
    }
  } while (cursor);
  assert.equal(ids.length, 100);
  assert.equal(new Set(ids).size, 100);
});
