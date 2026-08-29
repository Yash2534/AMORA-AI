const path = require('path');

const SAFE_ENVIRONMENTS = new Set(['development', 'test', 'qa', 'staging']);
const DEFAULT_USER_COUNT = 150;
const MIN_USER_COUNT = 20;
const MAX_USER_COUNT = 2000;
const SEED_EMAIL_SUFFIX = '@seed.amoraa.example.test';
const SEED_MEDIA_PREFIX = 'amoraa-seed-avatar-';

function parseInteger(name, raw, fallback, minimum, maximum) {
  const value = raw === undefined || raw === '' ? fallback : Number(raw);
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) {
    throw new Error(`${name} must be an integer from ${minimum} to ${maximum}.`);
  }
  return value;
}

function resolveDummySeedConfig(env = process.env, argv = process.argv.slice(2)) {
  const environment = String(env.NODE_ENV || '').trim().toLowerCase();
  if (environment === 'production') {
    throw new Error('Dummy data seeding is blocked in production.');
  }
  if (!SAFE_ENVIRONMENTS.has(environment)) {
    throw new Error(`NODE_ENV must be one of: ${[...SAFE_ENVIRONMENTS].join(', ')}.`);
  }
  if (String(env.ALLOW_DUMMY_SEED || '').trim().toLowerCase() !== 'true') {
    throw new Error('Dummy data seeding requires ALLOW_DUMMY_SEED=true.');
  }
  if (!argv.includes('--confirm-development-db')) {
    throw new Error('Dummy data seeding requires --confirm-development-db.');
  }

  const databaseName = String(env.DB_NAME || '').trim();
  const allowedDatabases = String(env.DUMMY_SEED_DATABASES || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  if (!databaseName || !allowedDatabases.includes(databaseName)) {
    throw new Error('DB_NAME must be explicitly listed in DUMMY_SEED_DATABASES.');
  }

  const referenceDateText = String(env.SEED_REFERENCE_DATE || '2026-08-29').trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(referenceDateText)
      || Number.isNaN(Date.parse(`${referenceDateText}T12:00:00.000Z`))) {
    throw new Error('SEED_REFERENCE_DATE must use YYYY-MM-DD.');
  }

  const password = String(env.SEED_TEST_PASSWORD || 'Amoraa-Dev-Only-2026!');
  if (password.length < 12 || password.length > 72) {
    throw new Error('SEED_TEST_PASSWORD must contain 12 to 72 characters.');
  }

  return Object.freeze({
    environment,
    databaseName,
    userCount: parseInteger('SEED_USER_COUNT', env.SEED_USER_COUNT, DEFAULT_USER_COUNT, MIN_USER_COUNT, MAX_USER_COUNT),
    randomSeed: parseInteger('SEED_RANDOM_SEED', env.SEED_RANDOM_SEED, 12345, 1, 2147483647),
    mediaVariants: parseInteger('SEED_MEDIA_VARIANTS', env.SEED_MEDIA_VARIANTS, 48, 12, 120),
    referenceDate: new Date(`${referenceDateText}T12:00:00.000Z`),
    referenceDateText,
    password,
    emailSuffix: SEED_EMAIL_SUFFIX,
    mediaPrefix: SEED_MEDIA_PREFIX,
    uploadsDirectory: path.resolve(__dirname, '../../uploads/onboarding-photos'),
    mode: argv.includes('--reset-only') ? 'reset' : argv.includes('--validate-only') ? 'validate' : 'seed',
  });
}

module.exports = {
  DEFAULT_USER_COUNT,
  MAX_USER_COUNT,
  MIN_USER_COUNT,
  SAFE_ENVIRONMENTS,
  SEED_EMAIL_SUFFIX,
  SEED_MEDIA_PREFIX,
  resolveDummySeedConfig,
};
