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

    // -------------------------------------------------------------------------
    // TEMPORARY HTTP EXCEPTION
    //
    // AMORAA Admin is currently hosted using the server IP over HTTP.
    //
    // Remove this exception when the Admin site is moved to an HTTPS domain.
    // -------------------------------------------------------------------------

    const temporaryAllowedHttpOrigins = new Set([
      'http://195.35.23.132',
    ]);

    for (const origin of origins) {
      const isHttps =
        /^https:\/\//i.test(origin);

      const isTemporaryAllowedHttp =
        temporaryAllowedHttpOrigins.has(origin);

      if (!isHttps && !isTemporaryAllowedHttp) {
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