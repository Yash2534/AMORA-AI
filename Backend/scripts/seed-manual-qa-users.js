require('../src/config/bootstrapEnv');
const { resolveManualQaConfig } = require('./manual-qa-users-config');

async function run() {
  const config = resolveManualQaConfig();
  require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db');
  const { getModels } = require('../src/models');
  const { ensureManualQaMedia } = require('./manual-qa-users-media');
  const { QA_USERS } = require('./manual-qa-users-fixture');
  const { findQaUsers, resetQaRelations, seedQaUsers } = require('./manual-qa-users-store');
  const { validateManualQaUsers } = require('./manual-qa-users-validate');
  await initializeDatabase();
  const sequelize = getSequelize();
  const models = getModels();
  try {
    if (config.mode === 'reset-relations') {
      await sequelize.transaction(async (transaction) => {
        const users = await findQaUsers(models, transaction);
        await resetQaRelations(models, users, transaction);
      });
    } else {
      const mediaByUser = Object.fromEntries(
        Object.entries(QA_USERS).map(([key, definition]) => [
          key,
          ensureManualQaMedia(config, definition),
        ]),
      );
      await sequelize.transaction((transaction) => seedQaUsers(
        models, config, mediaByUser, transaction,
      ));
    }
    const result = await validateManualQaUsers(models, config);
    console.log(`[ManualQA] ${config.mode} complete and validated.`);
    console.log(`[ManualQA] ${JSON.stringify(result)}`);
    return result;
  } finally {
    await sequelize.close();
  }
}

if (require.main === module) run().catch((error) => {
  console.error(`[ManualQA] ${error.stack || error.message}`);
  process.exitCode = 1;
});

module.exports = { run };
