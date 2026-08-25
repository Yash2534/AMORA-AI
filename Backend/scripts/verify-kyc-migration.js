const mysql = require('mysql2/promise');

require('../src/config/bootstrapEnv');
require('../src/config/env');
const { createSequelize, migrate, migrationFiles, status, undo } = require('../src/migrations/run');

const databaseName = process.env.KYC_MIGRATION_TEST_DB || 'amora_ai_kyc_migration_test';
if (!/^[A-Za-z0-9_]+$/.test(databaseName) || !/kyc/i.test(databaseName) || !/test/i.test(databaseName)) {
  throw new Error('KYC_MIGRATION_TEST_DB must be an isolated database name containing both "kyc" and "test".');
}

async function dropDatabase() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASS || '',
  });
  try {
    await connection.query(`DROP DATABASE IF EXISTS \`${databaseName}\``);
  } finally {
    await connection.end();
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function main() {
  let sequelize;
  await dropDatabase();
  try {
    const applied = await migrate({ databaseName, quiet: true });
    assert(applied.length === migrationFiles().length, 'Fresh migration did not apply every migration.');
    sequelize = await createSequelize(databaseName);
    const queryInterface = sequelize.getQueryInterface();
    const tables = new Set((await queryInterface.showAllTables()).map((value) => String(value).toLowerCase()));
    assert(tables.has('identityverificationreasons'), 'Reason table is missing.');
    assert(tables.has('identityverificationdecisionevents'), 'Decision-event table is missing.');
    const columns = await queryInterface.describeTable('IdentityVerifications');
    for (const name of [
      'reviewerAdministratorId', 'reviewVersion', 'submissionVersion',
      'reviewReasonCode', 'resubmissionItems',
    ]) assert(columns[name], `IdentityVerifications.${name} is missing.`);
    const references = await queryInterface.getForeignKeyReferencesForTable('IdentityVerificationDecisionEvents');
    assert(references.some((item) => item.columnName === 'verificationId'
      && String(item.referencedTableName).toLowerCase() === 'identityverifications'),
      'Decision verification foreign key is missing.');
    assert(references.some((item) => item.columnName === 'administratorId'
      && String(item.referencedTableName).toLowerCase() === 'administrators'),
      'Decision reviewer foreign key is missing.');
    const indexes = await queryInterface.showIndex('IdentityVerificationDecisionEvents');
    assert(indexes.some((item) => item.unique && item.fields.some((field) => field.attribute === 'idempotencyKey')),
      'Unique decision idempotency index is missing.');

    const revertedFinancialIndexes = await undo({ sequelize, quiet: true });
    assert(revertedFinancialIndexes === '202608280001-add-admin-financial-read-indexes.js',
      'Rollback did not first target the Admin financial read-index migration.');
    const paymentIndexesAfterRollback = await queryInterface.showIndex('Payments');
    assert(!paymentIndexesAfterRollback.some((item) => item.name === 'payments_admin_status_history'),
      'Admin financial indexes survived rollback.');

    const reverted = await undo({ sequelize, quiet: true });
    assert(reverted === '202608270001-complete-kyc-decisions.js', 'Rollback did not target the KYC migration.');
    const rolledBackTables = new Set((await queryInterface.showAllTables()).map((value) => String(value).toLowerCase()));
    assert(!rolledBackTables.has('identityverificationreasons'), 'Reason table survived rollback.');
    assert(!rolledBackTables.has('identityverificationdecisionevents'), 'Decision-event table survived rollback.');
    const rolledBackColumns = await queryInterface.describeTable('IdentityVerifications');
    assert(!rolledBackColumns.reviewerAdministratorId && !rolledBackColumns.reviewVersion,
      'KYC decision columns survived rollback.');

    const reapplied = await migrate({ sequelize, quiet: true });
    assert(reapplied.length === 2
      && reapplied[0] === '202608270001-complete-kyc-decisions.js'
      && reapplied[1] === '202608280001-add-admin-financial-read-indexes.js',
    'Forward migrations did not reapply in the expected order.');
    const finalStatus = await status({ sequelize });
    assert(finalStatus.every((item) => item.status === 'up'), 'Not every migration is up after reapply.');
    console.log(`[KYC Migration] ${finalStatus.length}/${finalStatus.length} up; rollback and forward reapply passed in ${databaseName}.`);
  } finally {
    if (sequelize) await sequelize.close().catch(() => {});
    await dropDatabase();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
