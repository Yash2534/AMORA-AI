async function sendSms(to, message, meta = {}) {
  const configured = Boolean(process.env.SMS_PROVIDER && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_FROM_NUMBER);
  if (!configured) {
    if (process.env.NODE_ENV === 'development') {
      console.log(`============================================\n[DEV MODE] SMS not configured — OTP for ${to}:\nCODE: ${meta.code}\nPurpose: ${meta.purpose}\nExpires: ${meta.expiresAt.toISOString()}\n============================================`);
      return;
    }
    throw new Error('SMS is not configured. Set SMS_PROVIDER, TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_FROM_NUMBER.');
  }
  if (process.env.SMS_PROVIDER.toLowerCase() !== 'twilio') throw new Error(`Unsupported SMS provider: ${process.env.SMS_PROVIDER}`);
  const client = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  await client.messages.create({ to, from: process.env.TWILIO_FROM_NUMBER, body: message });
}
module.exports = sendSms;
