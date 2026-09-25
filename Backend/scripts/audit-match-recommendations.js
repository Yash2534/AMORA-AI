// Read-only development audit. No login, migrations, admin initialization or seed writes.
require('../src/config/bootstrapEnv');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { performance } = require('node:perf_hooks');
const { Sequelize, Op } = require('sequelize');
const { resolveDummySeedConfig } = require('./dummy-seed/config');
const { scoreCompatibility } = require('../src/services/matchEngineService');
const { localAiMatch, rankCandidates } = require('../src/services/aiMatchProvider');

const stats = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  const average = values.reduce((a, b) => a + b, 0) / values.length;
  return { minimum: sorted[0], maximum: sorted.at(-1), average: +average.toFixed(2), median: (sorted[Math.floor((sorted.length - 1) / 2)] + sorted[Math.floor(sorted.length / 2)]) / 2,
    variance: +(values.reduce((sum, value) => sum + (value - average) ** 2, 0) / values.length).toFixed(2) };
};

async function run() {
  const config = resolveDummySeedConfig(process.env, [...process.argv.slice(2), '--validate-only']);
  const db = new Sequelize(config.databaseName, process.env.DB_USER, process.env.DB_PASS || '', {
    host: process.env.DB_HOST, port: Number(process.env.DB_PORT), dialect: 'mysql', logging: false,
  });
  let queryCount = 0;
  const query = db.query.bind(db);
  db.query = (sql, ...args) => {
    const statement = typeof sql === 'string' ? sql : sql.query;
    if (!/^\s*(SELECT|SHOW|SET TRANSACTION|START TRANSACTION|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT)\b/i.test(statement)) throw new Error('Read-only audit refused a write.');
    queryCount += 1;
    return query(sql, ...args);
  };
  try {
    await db.authenticate();
    require('../src/models').initModels(db);
    const m = require('../src/models').getModels();
    const users = await m.User.findAll({ where: { email: { [Op.like]: `%${config.emailSuffix}` } }, include: [m.OnboardingProfile] });
    assert.equal(users.length, 40);
    const master = users.find((user) => user.email === 'master@seed.amoraa.example.test');
    assert.ok(master);
    assert.ok(await m.DiscoverFilterPreference.findOne({ where: { userId: master.id } }), 'Stored master filters required; audit never creates them');
    const controller = require('../src/controllers/discoverController');
    async function page(ai, number) {
      const req = { user: { sub: master.id }, aiMatches: ai, query: { page: number, limit: 10 }, protocol: 'http', get: () => 'localhost' };
      let response;
      await controller.getFeed(req, { json: (value) => { response = value; }, status: () => { throw new Error('Unexpected controller failure'); } }, (error) => { throw error; });
      assert.equal(response.success, true);
      return response.data;
    }
    const collect = async (ai) => {
      const rows = []; let number = 1; let data;
      do { data = await page(ai, number++); rows.push(...(ai ? data.recommendations : data.profiles)); assert.ok(number < 100); } while (data.pagination.hasMore);
      assert.equal(new Set(rows.map((row) => row.id)).size, rows.length);
      return rows;
    };
    const feed = await collect(false);
    const ai = await collect(true);
    assert.deepEqual(new Set(ai.map((row) => row.id)), new Set(feed.map((row) => row.id)));
    assert.deepEqual(ai, await collect(true));
    const seedIds = new Set(users.map((user) => String(user.id)));
    const seedAi = ai.filter((row) => seedIds.has(row.id));
    queryCount = 0;
    const started = performance.now(); await page(true, 1);
    const controllerMetrics = { queryCount, durationMs: +(performance.now() - started).toFixed(3) };
    const rows = seedAi.map((row, index) => ({ rank: index + 1, name: row.profile.name, compatibility: row.compatibilityScore, coverage: row.compatibilityCoverage, aiConfidence: row.aiConfidence, aiMatchScore: row.aiMatchScore, reasons: row.aiReasons }));
    const distribution = { '<50': 0, '50-59': 0, '60-69': 0, '70-79': 0, '80-89': 0, '90-100': 0 };
    for (const row of rows) distribution[row.compatibility < 50 ? '<50' : row.compatibility < 60 ? '50-59' : row.compatibility < 70 ? '60-69' : row.compatibility < 80 ? '70-79' : row.compatibility < 90 ? '80-89' : '90-100'] += 1;
    const sparse = users.find((user) => !user.OnboardingProfile.onboardingCompleted);
    const sparseBase = scoreCompatibility(master.OnboardingProfile, sparse.OnboardingProfile);
    const sparseAi = localAiMatch(master.OnboardingProfile, sparse.OnboardingProfile, sparseBase);
    const providerPerformance = [25, 50, 100].map((count) => {
      const candidates = Array.from({ length: count }, (_, index) => {
        const profile = users[(index % (users.length - 1)) + 1].OnboardingProfile;
        return { userId: index + 1, compatibility: scoreCompatibility(master.OnboardingProfile, profile) };
      });
      for (let i = 0; i < 20; i++) rankCandidates({}, candidates);
      const heapBefore = process.memoryUsage().heapUsed;
      const times = [];
      queryCount = 0;
      for (let i = 0; i < 100; i++) { const start = performance.now(); rankCandidates({}, candidates); times.push(performance.now() - start); }
      return { count, iterations: 100, medianMs: +stats(times).median.toFixed(3), p95Ms: +times.sort((a, b) => a - b)[94].toFixed(3), heapDeltaBytes: process.memoryUsage().heapUsed - heapBefore, queries: queryCount };
    });
    const counts = (values) => values.reduce((result, value) => ({ ...result, [value]: (result[value] || 0) + 1 }), {});
    const report = { generatedAt: new Date().toISOString(), totalApiEligible: ai.length, nonSeedEligible: ai.length - seedAi.length, dataset: { users: users.length, complete: users.filter((u) => u.OnboardingProfile.onboardingCompleted).length, images: users.reduce((sum, u) => sum + u.OnboardingProfile.photos.length, 0) }, eligible: rows.length, excluded: users.length - 1 - rows.length,
      compatibility: stats(rows.map((row) => row.compatibility)), coverage: stats(rows.map((row) => row.coverage)), confidence: stats(rows.map((row) => row.aiConfidence)), distribution,
      genericReasons: rows.filter((row) => row.reasons.includes('Potential match based on shared platform presence.')).length,
      distinctReasonSets: new Set(rows.map((row) => JSON.stringify(row.reasons))).size,
      paginationStable: true, rankingStable: true, controllerMetrics, providerPerformance,
      concentration: { cities: counts(seedAi.map((r) => r.profile.city)), top10Cities: counts(seedAi.slice(0, 10).map((r) => r.profile.city)), genders: counts(seedAi.map((r) => r.profile.gender)), top10Genders: counts(seedAi.slice(0, 10).map((r) => r.profile.gender)), top10Interests: counts(seedAi.slice(0, 10).flatMap((r) => r.profile.interests)), scoreTies: counts(rows.map((r) => r.compatibility)) },
      sparse: { name: sparse.name, excluded: !ai.some((r) => r.id === String(sparse.id)), score: sparseBase.score, coverage: sparseBase.coverage, confidence: sparseAi.aiConfidence, reasons: sparseAi.aiReasons, usableFactors: sparseBase.factors.filter((f) => f.available).length }, rows };
    const outputIndex = process.argv.indexOf('--output');
    if (outputIndex !== -1) fs.writeFileSync(process.argv[outputIndex + 1], `${JSON.stringify(report, null, 2)}\n`);
    console.log(JSON.stringify(report, null, 2));
    return report;
  } finally { await db.close(); }
}
if (require.main === module) run().catch((error) => { console.error(error.message); process.exitCode = 1; });
module.exports = { run };
