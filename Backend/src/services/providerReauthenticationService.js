const bcrypt = require('bcrypt');
const { OAuth2Client } = require('google-auth-library');

function googleClientIds() {
  return String(process.env.GOOGLE_CLIENT_IDS || '')
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value && value !== 'skip-for-now');
}

async function verifyProviderReauthentication(user, credentials = {}) {
  if (user.authProvider === 'local') {
    if (!user.passwordHash || typeof credentials.password !== 'string') {
      return { ok: false, code: 'REAUTHENTICATION_REQUIRED' };
    }
    return await bcrypt.compare(credentials.password, user.passwordHash)
      ? { ok: true, method: 'password' }
      : { ok: false, code: 'CURRENT_PASSWORD_INCORRECT' };
  }

  if (user.authProvider === 'google') {
    const clientIds = googleClientIds();
    if (!clientIds.length) return { ok: false, code: 'PROVIDER_REAUTH_UNAVAILABLE' };
    if (typeof credentials.providerIdToken !== 'string' || !credentials.providerIdToken.trim()) {
      return { ok: false, code: 'REAUTHENTICATION_REQUIRED' };
    }
    try {
      const ticket = await new OAuth2Client().verifyIdToken({
        idToken: credentials.providerIdToken,
        audience: clientIds,
      });
      const payload = ticket.getPayload();
      const subjectMatches = payload?.sub && user.googleId && payload.sub === user.googleId;
      const emailMatches = payload?.email
        && String(payload.email).trim().toLowerCase() === String(user.email).trim().toLowerCase();
      return subjectMatches && emailMatches
        ? { ok: true, method: 'google' }
        : { ok: false, code: 'PROVIDER_IDENTITY_MISMATCH' };
    } catch (_) {
      return { ok: false, code: 'PROVIDER_TOKEN_INVALID' };
    }
  }

  return { ok: false, code: 'PROVIDER_REAUTH_UNAVAILABLE' };
}

module.exports = { verifyProviderReauthentication, _test: { googleClientIds } };
