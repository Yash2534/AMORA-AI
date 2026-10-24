function integerSetting(env, name, fallback, { min, max }) {
  const raw = String(env[name] ?? '').trim();
  if (!raw) return fallback;
  if (!/^\d+$/.test(raw)) throw new Error(`${name} must be an integer between ${min} and ${max}.`);
  const value = Number(raw);
  if (!Number.isSafeInteger(value) || value < min || value > max) {
    throw new Error(`${name} must be an integer between ${min} and ${max}.`);
  }
  return value;
}

function databasePoolConfig(env = process.env) {
  const max = integerSetting(env, 'DB_POOL_MAX', 10, { min: 1, max: 200 });
  const min = integerSetting(env, 'DB_POOL_MIN', 0, { min: 0, max: 50 });
  if (min > max) throw new Error('DB_POOL_MIN cannot exceed DB_POOL_MAX.');
  return {
    max,
    min,
    acquire: integerSetting(env, 'DB_POOL_ACQUIRE_MS', 30000, { min: 1000, max: 120000 }),
    idle: integerSetting(env, 'DB_POOL_IDLE_MS', 10000, { min: 1000, max: 120000 }),
  };
}

function migrationStartupMode(env = process.env) {
  const configured = String(env.DB_MIGRATION_STARTUP_MODE || '').trim().toLowerCase();
  const fallback = env.NODE_ENV === 'production' ? 'verify' : 'apply';
  const mode = configured || fallback;
  if (!['verify', 'apply'].includes(mode)) {
    throw new Error('DB_MIGRATION_STARTUP_MODE must be either verify or apply.');
  }
  return mode;
}

function aiCandidateWindow(env = process.env) {
  return integerSetting(env, 'AI_DISCOVERY_CANDIDATE_WINDOW', 500, { min: 30, max: 2000 });
}

function shutdownTimeoutMs(env = process.env) {
  return integerSetting(env, 'SHUTDOWN_TIMEOUT_MS', 15000, { min: 1000, max: 60000 });
}

function databaseQueryTimeoutMs(env = process.env) {
  return integerSetting(env, 'DB_QUERY_TIMEOUT_MS', 0, { min: 0, max: 300000 });
}

function requireDistributedRateLimit(env = process.env) {
  const raw = String(env.REQUIRE_DISTRIBUTED_RATE_LIMIT || '').trim().toLowerCase();
  if (!raw) return false;
  if (!['true', 'false'].includes(raw)) throw new Error('REQUIRE_DISTRIBUTED_RATE_LIMIT must be true or false.');
  return raw === 'true';
}

module.exports = {
  integerSetting,
  databasePoolConfig,
  migrationStartupMode,
  aiCandidateWindow,
  shutdownTimeoutMs,
  databaseQueryTimeoutMs,
  requireDistributedRateLimit,
};
