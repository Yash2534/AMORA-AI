const { getTransport } = require('../config/mailer');
const logger = require('./logger');
async function sendEmail(to, subject, html, meta = {}) {
  const transport = getTransport();
  if (!transport) {
    logger.warn('[OTP] Email delivery unavailable because SMTP is not configured.', { purpose: meta.purpose });
    throw new Error('Email is not configured. Set EMAIL_HOST, EMAIL_USER, and EMAIL_PASS.');
  }
  await transport.sendMail({ from: process.env.EMAIL_FROM || process.env.EMAIL_USER, to, subject, html });
}
module.exports = sendEmail;
