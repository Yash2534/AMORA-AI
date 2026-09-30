require('../src/config/bootstrapEnv');

const { run } = require('./seed-dummy-data');

if (require.main === module) run().catch((error) => {
  console.error(`[DemoWalkthrough] ${error.stack || error.message}`);
  process.exitCode = 1;
});

module.exports = { run };
