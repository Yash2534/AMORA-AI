const nodemailer = require('nodemailer');
let transport;
function getTransport() {
  // Resolved lazily so importing modules that merely reference email delivery
  // does not trigger full startup validation; server.js validates at boot.
  const { smtpConfigured } = require('./env');
  if (!smtpConfigured) return null;
  if (!transport) transport = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: Number(process.env.EMAIL_PORT || 587),
    secure: Number(process.env.EMAIL_PORT) === 465,
    auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
  });
  return transport;
}
module.exports = { getTransport };
