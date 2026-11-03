const bcrypt = require('bcrypt');
const { getModels } = require('../models');
const logger = require('../utils/logger');

function developmentSeedConfig(env = process.env) {
  if (env.NODE_ENV !== 'development') return null;
  const email = String(env.DEV_ADMIN_SEED_EMAIL || '').trim().toLowerCase();
  const password = String(env.DEV_ADMIN_SEED_PASSWORD || '');
  if (!email || !password) return null;
  if (password.length < 14) {
    throw new Error('DEV_ADMIN_SEED_PASSWORD must contain at least 14 characters.');
  }
  return { email, password };
}

async function ensureDefaultAdminAccount() {
  const seed = developmentSeedConfig();
  if (!seed) {
    if (process.env.NODE_ENV === 'development') {
      logger.info('[Database] Development administrator seed skipped: explicit seed configuration is absent.');
    }
    return;
  }

  try {
    const { Administrator, AdminRole } = getModels();
    const { email, password } = seed;

    const superAdminRole = await AdminRole.findOne({ where: { key: 'super_admin' } });
    if (!superAdminRole) {
      logger.warn('[Database] Super Admin role not found. Skipping development administrator seed.');
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
      logger.info('[Database] Seeded explicit development administrator.', { email });
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
      logger.info('[Database] Verified explicit development administrator.', { email });
    }
  } catch (error) {
    logger.error('[Database] Failed to ensure development administrator account.', {
      errorName: error?.name,
      errorCode: error?.code,
    });
  }
}

module.exports = { ensureDefaultAdminAccount, developmentSeedConfig };
