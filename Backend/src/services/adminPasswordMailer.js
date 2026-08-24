const { getTransport } = require('../config/mailer');

const escapeHtml = (value) => String(value)
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#39;');

async function sendAdminPasswordReset({ email, token, expiresAt }) {
  if (process.env.NODE_ENV === 'test') return;
  const baseUrl = String(process.env.ADMIN_WEB_RESET_URL || '').trim();
  if (!baseUrl) throw new Error('ADMIN_WEB_RESET_URL is required to deliver administrator password resets.');
  const url = new URL(baseUrl);
  if (process.env.NODE_ENV === 'production' && url.protocol !== 'https:') {
    throw new Error('ADMIN_WEB_RESET_URL must use HTTPS in production.');
  }
  url.searchParams.set('token', token);
  const transport = getTransport();
  if (!transport) {
    if (process.env.NODE_ENV === 'development') {
      console.log(`[DEV MODE] Administrator password reset for ${email}: ${url.toString()} (expires ${expiresAt.toISOString()})`);
      return;
    }
    throw new Error('Email is not configured for administrator password recovery.');
  }
  const safeUrl = escapeHtml(url.toString());
  await transport.sendMail({
    from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
    to: email,
    subject: 'Reset your AMORAA Admin password',
    text: `Reset your AMORAA Admin password: ${url.toString()}\nThis link expires at ${expiresAt.toISOString()}.`,
    html: `<p>Use the link below to reset your AMORAA Admin password.</p><p><a href="${safeUrl}">Reset password</a></p><p>This link expires at ${escapeHtml(expiresAt.toISOString())}.</p>`,
  });
}

module.exports = { sendAdminPasswordReset };
