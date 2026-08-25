const bcrypt = require('bcrypt');
const crypto = require('crypto');
const mysql = require('mysql2/promise');

require('../src/config/bootstrapEnv');
require('../src/config/env');
const { createSequelize, migrate } = require('../src/migrations/run');
const { initModels } = require('../src/models');

const databaseName = process.env.FINANCIAL_E2E_TEST_DB || 'amora_ai_financial_e2e_test';
if (!/^[A-Za-z0-9_]+$/.test(databaseName)
  || !/financial/i.test(databaseName)
  || !/e2e/i.test(databaseName)
  || !/test/i.test(databaseName)) {
  throw new Error('FINANCIAL_E2E_TEST_DB must contain "financial", "e2e", and "test".');
}

async function serverConnection() {
  return mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASS || '',
  });
}

async function dropDatabase() {
  const connection = await serverConnection();
  try { await connection.query(`DROP DATABASE IF EXISTS \`${databaseName}\``); } finally { await connection.end(); }
}

async function teardown() {
  await dropDatabase();
  console.log(`[Financial E2E] Removed isolated schema ${databaseName}.`);
}

async function setup() {
  await teardown();
  await migrate({ databaseName, quiet: true });
  const sequelize = await createSequelize(databaseName);
  try {
    const models = initModels(sequelize);
    const permissionKeys = [
      'dashboard.view',
      'membership.view',
      'membership.plans.view',
      'payments.transactions.view',
      'payments.transactions.details.view',
      'payments.transactions.sensitiveFields.view',
      'payments.audit.view',
    ];
    const role = await models.AdminRole.create({
      key: 'financial_e2e_admin',
      name: 'Financial E2E Admin',
      isActive: true,
    });
    const permissions = await models.AdminPermission.findAll({ where: { key: permissionKeys } });
    if (permissions.length !== permissionKeys.length) throw new Error('Financial E2E permission catalog is incomplete.');
    await role.addPermissions(permissions);
    const password = 'FinancialE2e!Admin2026';
    const administrator = await models.Administrator.create({
      name: 'Financial E2E Admin',
      email: 'financial-admin@e2e.test',
      passwordHash: await bcrypt.hash(password, 12),
    });
    await administrator.addRole(role);
    const user = await models.User.create({
      name: 'Financial Browser Fixture',
      email: 'financial-consumer@e2e.test',
      phoneNumber: '+919999000002',
      passwordHash: await bcrypt.hash('Client!FinancialE2e2026', 4),
      isVerified: true,
      accountStatus: 'active',
    });
    const plan = await models.SubscriptionPlan.create({
      id: 'financial_e2e_premium',
      name: 'premium',
      displayName: 'Financial E2E Premium',
      description: 'Isolated browser verification plan.',
      priceMinor: 149900,
      currency: 'INR',
      billingPeriod: 'month',
      billingInterval: 1,
      features: ['Browser-verified plan'],
      entitlements: { dailyLikes: 50 },
      active: true,
      sortOrder: 1,
    });
    const now = new Date();
    await models.Subscription.create({
      userId: user.id,
      planId: plan.id,
      status: 'active',
      provider: 'razorpay',
      providerCustomerId: 'cust_financial_e2e',
      providerSubscriptionId: 'sub_financial_e2e',
      startedAt: now,
      currentPeriodStart: now,
      currentPeriodEnd: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000),
      autoRenew: true,
    });
    const payment = await models.Payment.create({
      userId: user.id,
      planId: plan.id,
      productType: 'subscription',
      productReferenceId: plan.id,
      provider: 'razorpay',
      providerOrderId: 'order_financial_e2e',
      providerPaymentId: 'pay_financial_e2e',
      amountMinor: 149900,
      currency: 'INR',
      status: 'paid',
      idempotencyKey: 'financial_e2e_payment',
      verifiedAt: now,
      metadata: { providerStatus: 'captured', privateValue: 'never-return-this' },
    });
    await models.PaymentEvent.create({
      paymentId: payment.id,
      provider: 'razorpay',
      providerEventId: 'event_financial_e2e',
      eventType: 'payment.captured',
      payloadHash: crypto.createHash('sha256').update('financial-e2e').digest('hex'),
      payload: { privateProviderPayload: 'never-return-this' },
      status: 'processed',
      processedAt: now,
    });
    console.log(JSON.stringify({
      databaseName,
      administrator: { email: administrator.email, password },
      transactionId: String(payment.id),
      planId: plan.id,
    }));
  } finally {
    await sequelize.close();
  }
}

async function verify() {
  const sequelize = await createSequelize(databaseName);
  try {
    const models = initModels(sequelize);
    const administrator = await models.Administrator.findOne({
      where: { email: 'financial-admin@e2e.test' },
    });
    const payment = await models.Payment.findOne({
      where: { providerPaymentId: 'pay_financial_e2e' },
    });
    if (!administrator || !payment) {
      throw new Error('The isolated financial E2E fixture is incomplete.');
    }
    const auditedReads = await models.AdminAuditLog.count({
      where: {
        administratorId: administrator.id,
        action: 'admin.payments.transaction.read',
        targetType: 'payment',
        targetId: String(payment.id),
      },
    });
    if (auditedReads < 1) {
      throw new Error('No audited financial transaction detail read was persisted.');
    }
    console.log(JSON.stringify({ databaseName, transactionId: String(payment.id), auditedReads }));
  } finally {
    await sequelize.close();
  }
}

const command = process.argv[2];
(command === 'setup'
  ? setup()
  : command === 'verify'
    ? verify()
    : command === 'teardown'
      ? teardown()
      : Promise.reject(new Error('Use setup, verify, or teardown.')))
  .catch((error) => { console.error(error); process.exit(1); });
