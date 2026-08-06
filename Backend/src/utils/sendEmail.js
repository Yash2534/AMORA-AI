const nodemailer = require('nodemailer'); const { getTransport } = require('../config/mailer');
async function sendEmail(to, subject, html, meta = {}) {
  const transport = getTransport();
  if (!transport) {
    if (process.env.NODE_ENV === 'development') {
      console.log(`============================================\n[DEV MODE] Email not configured — OTP for ${to}:\nCODE: ${meta.code}\nPurpose: ${meta.purpose}\nExpires: ${meta.expiresAt.toISOString()}\n============================================`);
      return;
    }
    throw new Error('Email is not configured. Set EMAIL_HOST, EMAIL_USER, and EMAIL_PASS.');
  }
  const info = await transport.sendMail({ from: process.env.EMAIL_FROM || process.env.EMAIL_USER, to, subject, html });
  if (/ethereal/i.test(process.env.EMAIL_HOST || '')) console.log(`[Email] Preview: ${nodemailer.getTestMessageUrl(info)}`);
}
module.exports = sendEmail;
