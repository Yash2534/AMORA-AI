function configuredOrigins(env = process.env) {
  const value = String(
    env.CORS_ORIGIN || '',
  ).trim();

  if (!value) {
    return [];
  }

  const origins = value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  if (env.NODE_ENV === 'production') {
    // Never allow wildcard CORS in production.
    if (origins.includes('*')) {
      throw new Error(
        'Production CORS_ORIGIN must not contain wildcard origins.',
      );
    }

    for (const origin of origins) {
      let parsed;
      try {
        parsed = new URL(origin);
      } catch (_) {
        throw new Error(`Production CORS_ORIGIN must contain valid origins: ${origin}`);
      }
      if (parsed.protocol !== 'https:' || parsed.username || parsed.password || parsed.pathname !== '/' || parsed.search || parsed.hash) {
        throw new Error(
          `Production CORS_ORIGIN must use HTTPS. HTTP origin is not approved: ${origin}`,
        );
      }
    }
  }

  return origins;
}

function isAllowedOrigin(
  origin,
  env = process.env,
) {
  if (!origin) {
    return false;
  }

  const origins = configuredOrigins(env);

  return (
    origins.includes(origin) ||
    (
      env.NODE_ENV !== 'production' &&
      origins.includes('*')
    )
  );
}

function corsOrigin(
  origin,
  callback,
  env = process.env,
) {
  // Requests without an Origin header are normally native/server clients,
  // rather than browser CORS requests.
  if (!origin) {
    return callback(null, false);
  }

  const allowed = isAllowedOrigin(
    origin,
    env,
  );

  return callback(
    null,
    allowed ? origin : false,
  );
}

module.exports = {
  configuredOrigins,
  isAllowedOrigin,
  corsOrigin,
};
