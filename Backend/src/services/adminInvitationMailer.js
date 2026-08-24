const { getTransport } = require('../config/mailer');

const escapeHtml = (value) => String(value)
  .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;').replaceAll("'", '&#39;');

async function sendAdminInvitation({ email, name, token, expiresAt, invitationMessage }) {
  if (process.env.NODE_ENV === 'test') return { accepted: false, testSkipped: true };
  const baseUrl = String(process.env.ADMIN_WEB_INVITATION_URL || '').trim();
  if (!baseUrl) throw Object.assign(new Error('ADMIN_WEB_INVITATION_URL is required.'), { code: 'INVITATION_PROVIDER_NOT_CONFIGURED' });
  const url = new URL(baseUrl);
  if (process.env.NODE_ENV === 'production' && url.protocol !== 'https:') {
    throw Object.assign(new Error('ADMIN_WEB_INVITATION_URL must use HTTPS in production.'), { code: 'INVITATION_PROVIDER_NOT_CONFIGURED' });
  }
  url.searchParams.set('token', token);
  const transport = getTransport();
  if (!transport) throw Object.assign(new Error('Email is not configured.'), { code: 'INVITATION_PROVIDER_NOT_CONFIGURED' });
  const optionalText = invitationMessage ? `\n\n${invitationMessage}` : '';
  const optionalHtml = invitationMessage ? `<p>${escapeHtml(invitationMessage)}</p>` : '';
  const info = await transport.sendMail({
    from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
    to: email,
    subject: 'You have been invited to AMORAA Admin',
    text: `Hello ${name},\n\nAccept your AMORAA Admin invitation: ${url.toString()}\nThis link expires at ${expiresAt.toISOString()}.${optionalText}`,
    html: `<p>Hello ${escapeHtml(name)},</p><p><a href="${escapeHtml(url.toString())}">Accept your AMORAA Admin invitation</a></p><p>This link expires at ${escapeHtml(expiresAt.toISOString())}.</p>${optionalHtml}`,
  });
  return { accepted: true, messageId: info?.messageId ? String(info.messageId).slice(0, 191) : null };
}

module.exports = { sendAdminInvitation };
