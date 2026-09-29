const crypto = require('crypto');
const path = require('path');

const SAFE_ENVIRONMENTS = new Set(['development', 'test', 'qa']);
const EXPECTED_PASSWORD_HASHES = Object.freeze({
  krupa: '4e675a0fc3d3f29d712a7fd1818be2a78ef3964a545ff74c08dcacaea44365b2',
  yashu: '952e3ee2fe4b7c18f58b0cfa0fcd98f2b7f055b7090891be8fa4604bbf413386',
});

function sha256(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function resolveManualQaConfig(
  env = process.env,
  argv = process.argv.slice(2),
  { expectedPasswordHashes = EXPECTED_PASSWORD_HASHES } = {},
) {
  const environment = String(env.NODE_ENV || '').trim().toLowerCase();
  if (environment === 'production') {
    throw new Error('Manual QA user seeding is blocked in production.');
  }
  if (!SAFE_ENVIRONMENTS.has(environment)) {
    throw new Error(
      `NODE_ENV must be one of: ${[...SAFE_ENVIRONMENTS].join(', ')}.`,
    );
  }
  if (String(env.ALLOW_DUMMY_SEED || '').trim().toLowerCase() !== 'true') {
    throw new Error('Manual QA user seeding requires ALLOW_DUMMY_SEED=true.');
  }
  if (!argv.includes('--confirm-development-db')) {
    throw new Error('Manual QA user seeding requires --confirm-development-db.');
  }

  const databaseName = String(env.DB_NAME || '').trim();
  const allowedDatabases = String(env.DUMMY_SEED_DATABASES || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  if (!databaseName || !allowedDatabases.includes(databaseName)) {
    throw new Error('DB_NAME must be explicitly listed in DUMMY_SEED_DATABASES.');
  }

  const mode = argv.includes('--reset-relations') ? 'reset-relations' : 'seed';
  const passwords = Object.freeze({
    krupa: String(env.MANUAL_QA_KRUPA_PASSWORD || ''),
    yashu: String(env.MANUAL_QA_YASHU_PASSWORD || ''),
  });
  if (mode === 'seed') {
    for (const key of ['krupa', 'yashu']) {
      if (!passwords[key] || sha256(passwords[key]) !== expectedPasswordHashes[key]) {
        throw new Error(
          `MANUAL_QA_${key.toUpperCase()}_PASSWORD must contain the approved local QA password.`,
        );
      }
    }
  }

  return Object.freeze({
    environment,
    databaseName,
    mode,
    passwords,
    uploadsDirectory: path.resolve(__dirname, '../uploads/onboarding-photos'),
    portraitAssetsDirectory: path.resolve(
      __dirname,
      '../demo-assets/amoraa-v2-generated/profiles',
    ),
  });
}

module.exports = {
  EXPECTED_PASSWORD_HASHES,
  SAFE_ENVIRONMENTS,
  resolveManualQaConfig,
  sha256,
};
