function configuredOrigins(env = process.env) {
  const value = String(env.CORS_ORIGIN || '').trim();
  if (!value) return [];
  const origins = value.split(',').map((origin) => origin.trim()).filter(Boolean);
  if (env.NODE_ENV === 'production') {
    if (origins.includes('*')) throw new Error('Production CORS_ORIGIN must not contain wildcard origins.');
    if (origins.some((origin) => !/^https:\/\//i.test(origin))) {
      throw new Error('Production CORS_ORIGIN entries must use HTTPS.');
    }
  }
  return origins;
}

function isAllowedOrigin(origin, env = process.env) {
  if (!origin) return false;
  const origins = configuredOrigins(env);
  return origins.includes(origin) || (env.NODE_ENV !== 'production' && origins.includes('*'));
}

function corsOrigin(origin, callback, env = process.env) {
  // Requests without Origin are native/server clients, not browser CORS.
  if (!origin) return callback(null, false);
  return callback(null, isAllowedOrigin(origin, env) ? origin : false);
}

module.exports = { configuredOrigins, isAllowedOrigin, corsOrigin };
