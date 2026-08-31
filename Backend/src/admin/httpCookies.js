const REFRESH_COOKIE = 'amoraa_admin_refresh';

function cookiesFrom(request) {
  const result = {};
  for (const part of String(request.headers.cookie || '').split(';')) {
    const separator = part.indexOf('=');
    if (separator <= 0) continue;
    const key = part.slice(0, separator).trim();
    const value = part.slice(separator + 1).trim();
    if (key) result[key] = decodeURIComponent(value);
  }
  return result;
}

function refreshTokenFrom(request) {
  const bodyToken = request.body?.refreshToken;
  if (typeof bodyToken === 'string' && bodyToken.trim()) return bodyToken.trim();
  return cookiesFrom(request)[REFRESH_COOKIE] || null;
}

function cookieValue(token, options = {}) {
  const parts = [
    `${REFRESH_COOKIE}=${encodeURIComponent(token)}`,
    'HttpOnly',
    'Path=/api/admin/v1/auth',
    'SameSite=Strict',
  ];
  if (process.env.NODE_ENV !== 'development') parts.push('Secure');
  if (options.persistent && options.expiresAt) {
    const seconds = Math.max(0, Math.floor((options.expiresAt.getTime() - Date.now()) / 1000));
    parts.push(`Max-Age=${seconds}`);
    parts.push(`Expires=${options.expiresAt.toUTCString()}`);
  }
  return parts.join('; ');
}

function clearCookieValue() {
  const parts = [
    `${REFRESH_COOKIE}=`,
    'HttpOnly',
    'Path=/api/admin/v1/auth',
    'SameSite=Strict',
    'Max-Age=0',
    'Expires=Thu, 01 Jan 1970 00:00:00 GMT',
  ];
  if (process.env.NODE_ENV !== 'development') parts.push('Secure');
  return parts.join('; ');
}

module.exports = {
  REFRESH_COOKIE,
  refreshTokenFrom,
  cookieValue,
  clearCookieValue,
};
