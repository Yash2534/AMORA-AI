const crypto = require('crypto');
const path = require('path');

const SAFE_ENVIRONMENTS = new Set(['development', 'test', 'qa', 'staging']);
const DEFAULT_USER_COUNT = 25;
const MIN_USER_COUNT = 25;
const MAX_USER_COUNT = 25;
const SEED_EMAIL_SUFFIX = '@seed.amoraa.example.test';
const SEED_MEDIA_PREFIX = 'amoraa-v2-profile-';
const DEMO_EMAIL = 'demo.walkthrough@amoraa.test';
const EXPECTED_DEMO_PASSWORD_HASH = '0267164411c64fee737a0e29122f6c540617fe04c02a77d7ebcfd862f6ec9120';

function parseInteger(name, raw, fallback, minimum, maximum) {
  const value = raw === undefined || raw === '' ? fallback : Number(raw);
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) {
    throw new Error(`${name} must be an integer from ${minimum} to ${maximum}.`);
  }
  return value;
}

function resolveDummySeedConfig(
  env = process.env,
  argv = process.argv.slice(2),
  { expectedDemoPasswordHash = EXPECTED_DEMO_PASSWORD_HASH } = {},
) {
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
  if (/(^|[_-])(prod|production|live|primary)([_-]|$)/i.test(databaseName)) {
    throw new Error('Dummy data seeding is blocked for production-like database names.');
  }
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

  const password = String(env.AMORAA_DEMO_PASSWORD || '');
  const passwordHash = crypto.createHash('sha256').update(password).digest('hex');
  if (!password || passwordHash !== expectedDemoPasswordHash) {
    throw new Error('AMORAA_DEMO_PASSWORD must contain the approved local walkthrough password.');
  }

  return Object.freeze({
    environment,
    databaseName,
    userCount: parseInteger('AMORAA_DEMO_USER_COUNT', env.AMORAA_DEMO_USER_COUNT, DEFAULT_USER_COUNT, MIN_USER_COUNT, MAX_USER_COUNT),
    randomSeed: parseInteger('SEED_RANDOM_SEED', env.SEED_RANDOM_SEED, 12345, 1, 2147483647),
    referenceDate: new Date(`${referenceDateText}T12:00:00.000Z`),
    referenceDateText,
    password,
    demoEmail: DEMO_EMAIL,
    ownedEmails: [DEMO_EMAIL],
    emailSuffix: SEED_EMAIL_SUFFIX,
    mediaPrefix: SEED_MEDIA_PREFIX,
    uploadsDirectory: path.resolve(__dirname, '../../uploads/onboarding-photos'),
    portraitAssetsDirectory: path.resolve(__dirname, '../../demo-assets/amoraa-v2-generated/profiles'),
    mode: argv.includes('--reset') || argv.includes('--reset-only') ? 'reset' : argv.includes('--validate-only') ? 'validate' : 'seed',
  });
}

module.exports = {
  DEFAULT_USER_COUNT,
  MAX_USER_COUNT,
  MIN_USER_COUNT,
  SAFE_ENVIRONMENTS,
  SEED_EMAIL_SUFFIX,
  SEED_MEDIA_PREFIX,
  DEMO_EMAIL,
  EXPECTED_DEMO_PASSWORD_HASH,
  resolveDummySeedConfig,
};
