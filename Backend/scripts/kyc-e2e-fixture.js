const bcrypt = require('bcrypt');
const fs = require('node:fs');
const mysql = require('mysql2/promise');

require('../src/config/bootstrapEnv');
require('../src/config/env');
const { createSequelize, migrate } = require('../src/migrations/run');
const { initModels } = require('../src/models');
const { absolutePathFor } = require('../src/utils/identityVerificationStorage');

const databaseName = process.env.KYC_E2E_TEST_DB || 'amora_ai_kyc_e2e_test';
const evidencePath = 'identity-verification/kyc-e2e-fixture.png';
if (!/^[A-Za-z0-9_]+$/.test(databaseName) || !/kyc/i.test(databaseName) || !/e2e/i.test(databaseName) || !/test/i.test(databaseName)) {
  throw new Error('KYC_E2E_TEST_DB must contain "kyc", "e2e", and "test".');
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
  await fs.promises.unlink(absolutePathFor(evidencePath)).catch(() => {});
  console.log(`[KYC E2E] Removed isolated schema ${databaseName} and its evidence fixture.`);
}

async function setup() {
  await teardown();
  await migrate({ databaseName, quiet: true });
  const sequelize = await createSequelize(databaseName);
  try {
    const models = initModels(sequelize);
    const reviewerKeys = [
      'dashboard.view',
      'verifications.view', 'verifications.pending.view', 'verifications.approved.view',
      'verifications.rejected.view', 'verifications.details.view', 'verifications.aadhaar.view',
      'verifications.selfie.view', 'verifications.history.view', 'verifications.approve',
      'verifications.reject', 'verifications.resubmit',
    ];
    const viewerKeys = reviewerKeys.filter((key) => !['verifications.approve', 'verifications.reject', 'verifications.resubmit'].includes(key));
    const [reviewerRole, viewerRole] = await Promise.all([
      models.AdminRole.create({ key: 'kyc_e2e_reviewer', name: 'KYC E2E Reviewer', isActive: true }),
      models.AdminRole.create({ key: 'kyc_e2e_viewer', name: 'KYC E2E Read Only', isActive: true }),
    ]);
    const permissions = await models.AdminPermission.findAll({ where: { key: reviewerKeys } });
    if (permissions.length !== reviewerKeys.length) throw new Error('KYC E2E permission catalog is incomplete.');
    await reviewerRole.addPermissions(permissions);
    await viewerRole.addPermissions(permissions.filter((permission) => viewerKeys.includes(permission.key)));
    const password = 'KycE2e!Admin2026';
    const [reviewer, viewer] = await Promise.all([
      models.Administrator.create({
        name: 'KYC E2E Reviewer', email: 'kyc-reviewer@e2e.test', passwordHash: await bcrypt.hash(password, 12),
      }),
      models.Administrator.create({
        name: 'KYC E2E Viewer', email: 'kyc-viewer@e2e.test', passwordHash: await bcrypt.hash(password, 12),
      }),
    ]);
    await reviewer.addRole(reviewerRole);
    await viewer.addRole(viewerRole);
    const consumer = await models.User.create({
      name: 'KYC Browser Fixture', email: 'kyc-consumer@e2e.test', phoneNumber: '+919999000001',
      passwordHash: await bcrypt.hash('Client!E2e2026', 4), isVerified: true, accountStatus: 'active',
    });
    await models.OnboardingProfile.create({
      userId: consumer.id, birthDate: '1995-04-20', gender: 'Woman', city: 'Pune',
      bio: 'Isolated KYC browser fixture.', photos: [], onboardingCompleted: true, stage: 'complete',
    });
    const imageBytes = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      'base64',
    );
    await fs.promises.writeFile(absolutePathFor(evidencePath), imageBytes, { flag: 'w', mode: 0o600 });
    const verification = await models.IdentityVerification.create({
      userId: consumer.id, status: 'pending', aadhaarStoragePath: evidencePath,
      aadhaarMimeType: 'image/png', aadhaarSizeBytes: imageBytes.length,
      selfieStoragePath: evidencePath, selfieMimeType: 'image/png', selfieSizeBytes: imageBytes.length,
      submittedAt: new Date(),
    });
    await models.IdentityVerificationReason.bulkCreate([
      {
        code: 'e2e_document_unreadable', action: 'reject', label: 'E2E document unreadable',
        allowsDetail: false, requiresDetail: false, allowedItems: null, sortOrder: 1,
      },
      {
        code: 'e2e_selfie_unclear', action: 'request_resubmission', label: 'E2E selfie unclear',
        allowsDetail: true, requiresDetail: false, allowedItems: ['selfie'], sortOrder: 1,
      },
    ]);
    console.log(JSON.stringify({
      databaseName,
      reviewer: { email: reviewer.email, password },
      viewer: { email: viewer.email, password },
      verificationId: String(verification.id),
    }));
  } finally {
    await sequelize.close();
  }
}

const command = process.argv[2];
(command === 'setup' ? setup() : command === 'teardown' ? teardown() : Promise.reject(new Error('Use setup or teardown.')))
  .catch((error) => { console.error(error); process.exit(1); });
