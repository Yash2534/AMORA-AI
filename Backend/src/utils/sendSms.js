const logger = require('./logger');

async function sendSms(to, message, meta = {}) {
  const startedAt = Date.now();
  const configured = Boolean(process.env.SMS_PROVIDER && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_FROM_NUMBER);
  if (!configured) {
    logger.warn('[OTP] SMS delivery unavailable because the provider is not configured.', { purpose: meta.purpose });
    const error = new Error('SMS is not configured. Set SMS_PROVIDER, TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_FROM_NUMBER.');
    error.code = 'OTP_CONFIG_ERROR';
    throw error;
  }
  if (process.env.SMS_PROVIDER.toLowerCase() !== 'twilio') throw new Error(`Unsupported SMS provider: ${process.env.SMS_PROVIDER}`);
  const client = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN, {
    timeout: 10000,
    autoRetry: false,
  });
  try {
    await client.messages.create({ to, from: process.env.TWILIO_FROM_NUMBER, body: message });
    require('../services/performanceMetrics').increment('provider_calls', { provider: 'sms', outcome: 'success' });
  } catch (error) {
    require('../services/performanceMetrics').increment('provider_calls', { provider: 'sms', outcome: 'failure' });
    throw error;
  } finally {
    require('../services/performanceMetrics').observe('provider_sms_duration_ms', Date.now() - startedAt);
  }
}
module.exports = sendSms;
