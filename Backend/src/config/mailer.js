const nodemailer = require('nodemailer');
const { smtpConfigured } = require('./env');
let transport;
function getTransport() {
  if (!smtpConfigured) return null;
  if (!transport) transport = nodemailer.createTransport({ host: process.env.EMAIL_HOST, port: Number(process.env.EMAIL_PORT || 587), secure: Number(process.env.EMAIL_PORT) === 465, auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS } });
  return transport;
}
module.exports = { getTransport };
