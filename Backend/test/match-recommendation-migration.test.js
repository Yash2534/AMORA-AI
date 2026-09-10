const assert = require('node:assert/strict');
const { before, after, test } = require('node:test');

require('../src/config/bootstrapEnv');
process.env.NODE_ENV = 'test';
const databaseName = process.env.TEST_DB_NAME || `${process.env.DB_NAME}_test`;
process.env.DB_NAME = databaseName;

const { Sequelize } = require('sequelize');
const { migrate, status } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');

let models;

before(async () => {
  await migrate({ databaseName, quiet: true });
  await initializeDatabase();
  models = getModels();
});

after(async () => {
  try { await getSequelize().close(); } catch (_) { /* test setup failure */ }
});

test('MatchRecommendationEvents migration supports disposable UP to DOWN to UP model validation', async () => {
  const sequelize = getSequelize();
  const queryInterface = sequelize.getQueryInterface();
  const migrationName = '202609100001-create-match-recommendation-events.js';
  const telemetryMigration = require('../src/migrations/202609100001-create-match-recommendation-events');

  assert.equal((await status({ databaseName, quiet: true })).find((item) => item.file === migrationName)?.status, 'up');
  const firstDescription = await queryInterface.describeTable('MatchRecommendationEvents');
  for (const column of ['viewerUserId', 'candidateUserId', 'eventType', 'rankingVersion', 'requestId', 'score', 'coverage', 'experimentId', 'variant']) assert.ok(firstDescription[column]);
  const firstIndexes = await queryInterface.showIndex('MatchRecommendationEvents');
  assert.ok(firstIndexes.some((index) => index.name === 'match_recommendation_event_request_candidate'));
  assert.ok(firstIndexes.some((index) => index.name === 'match_recommendation_event_metrics'));

  const first = await models.MatchRecommendationEvent.create({ viewerUserId: 999999001, eventType: 'no_result', rankingVersion: 'v2', requestId: '00000000-0000-4000-8000-000000000001', page: 1, noResultReason: 'eligible_candidates_empty' });
  assert.equal((await models.MatchRecommendationEvent.findByPk(first.id)).id, first.id);
  await models.MatchRecommendationEvent.destroy({ where: { id: first.id } });

  await telemetryMigration.down(queryInterface, Sequelize);
  const tablesAfterDown = (await queryInterface.showAllTables()).map((table) => String(table).toLowerCase());
  assert.equal(tablesAfterDown.includes('matchrecommendationevents'), false);
  assert.equal(tablesAfterDown.includes('users'), true);
  assert.equal(tablesAfterDown.includes('onboardingprofiles'), true);
  assert.equal(tablesAfterDown.includes('discoveractions'), true);
  assert.equal(tablesAfterDown.includes('matches'), true);

  await telemetryMigration.up(queryInterface, Sequelize);
  const secondIndexes = await queryInterface.showIndex('MatchRecommendationEvents');
  assert.ok(secondIndexes.some((index) => index.name === 'match_recommendation_event_request_candidate'));
  assert.ok(secondIndexes.some((index) => index.name === 'match_recommendation_event_metrics'));
  const second = await models.MatchRecommendationEvent.create({ viewerUserId: 999999002, eventType: 'no_result', rankingVersion: 'v2', requestId: '00000000-0000-4000-8000-000000000002', page: 1, noResultReason: 'eligible_candidates_empty' });
  assert.equal((await models.MatchRecommendationEvent.findByPk(second.id)).id, second.id);
  await models.MatchRecommendationEvent.destroy({ where: { id: second.id } });
});
