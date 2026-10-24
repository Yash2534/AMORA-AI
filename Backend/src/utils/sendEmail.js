const { getTransport } = require('../config/mailer');
const logger = require('./logger');
async function sendEmail(to, subject, html, meta = {}) {
  const startedAt = Date.now();
  const transport = getTransport();
  if (!transport) {
    logger.warn('[OTP] Email delivery unavailable because SMTP is not configured.', { purpose: meta.purpose });
    throw new Error('Email is not configured. Set EMAIL_HOST, EMAIL_USER, and EMAIL_PASS.');
  }
  try {
    await transport.sendMail({ from: process.env.EMAIL_FROM || process.env.EMAIL_USER, to, subject, html });
    require('../services/performanceMetrics').increment('provider_calls', { provider: 'email', outcome: 'success' });
  } catch (error) {
    require('../services/performanceMetrics').increment('provider_calls', { provider: 'email', outcome: 'failure' });
    throw error;
  } finally {
    require('../services/performanceMetrics').observe('provider_email_duration_ms', Date.now() - startedAt);
  }
}
module.exports = sendEmail;
