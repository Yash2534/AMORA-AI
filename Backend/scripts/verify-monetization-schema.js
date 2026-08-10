require('../src/config/bootstrapEnv'); require('../src/config/env');
const { createSequelize } = require('../src/migrations/run');
const expected = ['SubscriptionPlans', 'Subscriptions', 'Payments', 'PaymentEvents', 'Wallets', 'WalletTransactions', 'WalletProducts', 'BoostProducts', 'BoostEntitlements', 'Gifts', 'GiftTransactions'];
(async () => {
  const sequelize = await createSequelize(); const qi = sequelize.getQueryInterface(); const tables = (await qi.showAllTables()).map((value) => String(value).toLowerCase());
  const missing = expected.filter((name) => !tables.includes(name.toLowerCase()));
  if (missing.length) throw new Error(`Missing monetization tables: ${missing.join(', ')}`);
  const boostColumns = await qi.describeTable('Boosts');
  if (!boostColumns.boostEntitlementId || !boostColumns.idempotencyKey) throw new Error('Boosts entitlement audit columns are missing.');
  const walletColumns = await qi.describeTable('Wallets');
  if (/UNSIGNED/i.test(walletColumns.balance.type)) throw new Error('Wallet balance must support provider reversal debt.');
  const requiredIndexes = {
    SubscriptionPlans: ['subscription_plans_catalog'], Subscriptions: ['subscriptions_user_unique', 'subscriptions_entitlement_lookup'],
    Payments: ['payments_user_idempotency_unique', 'payments_provider_order_unique', 'payments_provider_payment_unique'], PaymentEvents: ['payment_events_provider_event_unique'],
    Wallets: ['wallets_user_unique'], WalletTransactions: ['wallet_transactions_idempotency_unique', 'wallet_transactions_user_history'],
    BoostEntitlements: ['boost_entitlements_user_idempotency_unique', 'boost_entitlements_inventory'], Gifts: ['gifts_catalog'], GiftTransactions: ['gift_transactions_sender_idempotency_unique'],
  };
  let indexCount = 0;
  for (const [table, names] of Object.entries(requiredIndexes)) {
    const existing = new Set((await qi.showIndex(table)).map((index) => index.name));
    for (const name of names) { if (!existing.has(name)) throw new Error(`Missing index ${name} on ${table}.`); indexCount += 1; }
  }
  const [foreignKeys] = await sequelize.query(`SELECT COUNT(*) AS count FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_NAME IN (${expected.map(() => '?').join(',')})`, { replacements: expected });
  const [[catalog]] = await sequelize.query('SELECT (SELECT COUNT(*) FROM SubscriptionPlans WHERE active = 1) AS plans, (SELECT COUNT(*) FROM WalletProducts WHERE active = 1) AS walletProducts, (SELECT COUNT(*) FROM BoostProducts WHERE active = 1) AS boostProducts, (SELECT COUNT(*) FROM Gifts WHERE active = 1) AS gifts');
  console.log(`[Schema] Monetization verified: ${expected.length} tables, ${indexCount} required indexes, ${Number(foreignKeys[0].count)} foreign keys; catalogs ${catalog.plans}/${catalog.walletProducts}/${catalog.boostProducts}/${catalog.gifts}.`); await sequelize.close();
})().catch((error) => { console.error(error); process.exit(1); });
