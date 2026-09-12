const bcrypt = require('bcrypt');
const { getModels } = require('../models');

async function ensureDefaultAdminAccount() {
  if (process.env.NODE_ENV !== 'development') return;

  try {
    const { Administrator, AdminRole } = getModels();
    const email = 'admin@amoraa.com';
    const password = process.env.SEED_TEST_PASSWORD || 'Amora@TDS2026';

    const superAdminRole = await AdminRole.findOne({ where: { key: 'super_admin' } });
    if (!superAdminRole) {
      console.warn('[Database] Super Admin role not found. Skipping default admin seed.');
      return;
    }

    let admin = await Administrator.findOne({ where: { email } });
    const passwordHash = await bcrypt.hash(password, 12);

    if (!admin) {
      admin = await Administrator.create({
        name: 'AMORAA Super Admin',
        email,
        passwordHash,
        status: 'active',
      });
      await admin.addRole(superAdminRole);
      console.log(`[Database] Seeded default development administrator: ${email} (Password: ${password})`);
    } else {
      await admin.update({
        passwordHash,
        status: 'active',
        failedLoginAttempts: 0,
        lockedUntil: null,
      });
      const roles = await admin.getRoles();
      if (!roles.some((r) => r.key === 'super_admin')) {
        await admin.addRole(superAdminRole);
      }
      console.log(`[Database] Default development administrator verified: ${email} (Password: ${password})`);
    }
  } catch (error) {
    console.error('[Database] Failed to ensure default admin account:', error.message);
  }
}

module.exports = { ensureDefaultAdminAccount };
