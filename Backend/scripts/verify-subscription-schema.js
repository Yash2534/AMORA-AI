require('../src/config/bootstrapEnv');
const { initializeDatabase, getSequelize } = require('../src/config/db');

async function main() {
  await initializeDatabase();
  const sequelize = getSequelize();
  const [tables] = await sequelize.query(`
    SELECT table_name AS tableName
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND LOWER(table_name) IN ('wallets','wallettransactions','walletproducts','boosts','boostentitlements','boostproducts','gifts','gifttransactions','products','entitlements')
  `);
  if (tables.length) throw new Error(`Retired commerce tables remain: ${tables.map((row) => row.tableName).join(', ')}`);
  const [paymentTypes] = await sequelize.query('SELECT DISTINCT productType FROM Payments');
  if (paymentTypes.some((row) => row.productType !== 'subscription')) throw new Error('Payments contains a non-subscription product type.');
  const [[catalog]] = await sequelize.query('SELECT COUNT(*) AS plans FROM SubscriptionPlans WHERE active = 1');
  console.log(`[Schema] Subscription-only commerce verified; ${Number(catalog.plans)} active plans.`);
  await sequelize.close();
}

main().catch((error) => { console.error(error); process.exit(1); });
