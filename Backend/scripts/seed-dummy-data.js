require('../src/config/bootstrapEnv');
const { resolveDummySeedConfig } = require('./dummy-seed/config');

async function run() {
  const config = resolveDummySeedConfig();
  require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db');
  const { getModels } = require('../src/models');
  const { createSeedMedia, removeSeedMedia } = require('./dummy-seed/media');
  const { buildSeedBlueprint } = require('./dummy-seed/factory');
  const { resetSeedData, seedDummyData } = require('./dummy-seed/store');
  const { validateDummyData } = require('./dummy-seed/validate');
  await initializeDatabase();
  const sequelize = getSequelize();
  const models = getModels();
  try {
    if (config.mode === 'validate') {
      const counts = await validateDummyData(sequelize, models, config);
      console.log(`[DummySeed] Validation passed: ${JSON.stringify(counts)}`);
      return counts;
    }
    let resetCounts;
    let result;
    const blueprint = buildSeedBlueprint(config);
    const mediaUrls = config.mode === 'reset' ? [] : createSeedMedia(config, blueprint);
    await sequelize.transaction(async (transaction) => {
      resetCounts = await resetSeedData(models, config, transaction);
      if (config.mode === 'seed') result = await seedDummyData(models, config, mediaUrls, transaction, blueprint);
    });
    if (config.mode === 'reset') {
      removeSeedMedia(config);
      console.log(`[DummySeed] Removed ${resetCounts.users} seed users and ${resetCounts.conversations} related conversations.`);
      return resetCounts;
    }
    const validated = await validateDummyData(sequelize, models, config);
    console.log(`[DummySeed] Seeded and validated ${config.databaseName}.`);
    console.log(`[DummySeed] Deterministic fingerprint: ${result.fingerprint}`);
    console.log(`[DummySeed] Counts: ${JSON.stringify(validated)}`);
    console.log('[DummySeed] Demo logins: demo.aisha@seed.amoraa.example.test, demo.rohan@seed.amoraa.example.test, demo.kavya@seed.amoraa.example.test');
    console.log('[DummySeed] Password is the configured SEED_TEST_PASSWORD; no email or SMS was sent.');
    return validated;
  } finally {
    await sequelize.close();
  }
}

if (require.main === module) run().catch((error) => {
  console.error(`[DummySeed] ${error.stack || error.message}`);
  process.exitCode = 1;
});
module.exports = { run };
