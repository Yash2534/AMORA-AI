const bcrypt = require('bcrypt');

const { resolveOtpTestConfig, matchesFixedOtp } = require('../config/otpTestConfig');
const { getModels } = require('../models');
const generateOtp = require('../utils/generateOtp');
const sendEmail = require('../utils/sendEmail');
const sendSms = require('../utils/sendSms');

const OTP_EXPIRY_MS = 10 * 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;

async function deliverPhoneOtp(phoneNumber, purpose, code, expiresAt) {
  if (resolveOtpTestConfig().skipDelivery) return { skipped: true };
  await sendSms(
    phoneNumber,
    `Your Amora AI verification code is ${code}. It expires in 10 minutes.`,
    { code, purpose, expiresAt },
  );
  return { skipped: false };
}

async function deliverEmailOtp(email, purpose, code, expiresAt) {
  if (resolveOtpTestConfig().skipDelivery) return { skipped: true };
  await sendEmail(
    email,
    'Your Amora AI password reset code',
    `<p>Your Amora AI password reset code is <strong>${code}</strong>.</p><p>It expires in 10 minutes. If you did not request this, you can ignore this email.</p>`,
    { code, purpose, expiresAt },
  );
  return { skipped: false };
}

async function createOtp(identifierField, identifier, purpose, options = {}) {
  const { OtpToken } = getModels();
  const code = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MS);
  const queryOptions = options.transaction ? { transaction: options.transaction } : {};
  await OtpToken.update(
    { consumed: true },
    { where: { [identifierField]: identifier, purpose, consumed: false }, ...queryOptions },
  );
  const otp = await OtpToken.create({
    [identifierField]: identifier,
    purpose,
    codeHash: await bcrypt.hash(code, 12),
    expiresAt,
  }, queryOptions);

  if (options.deliver !== false) {
    if (identifierField === 'phoneNumber') {
      await deliverPhoneOtp(identifier, purpose, code, expiresAt);
    } else {
      await deliverEmailOtp(identifier, purpose, code, expiresAt);
    }
  }
  return { code, expiresAt, otp };
}

async function createPhoneOtp(phoneNumber, purpose, options) {
  return createOtp('phoneNumber', phoneNumber, purpose, options);
}

async function createEmailOtp(email, purpose, options) {
  return createOtp('email', email, purpose, options);
}

async function verifyOtp(identifierField, identifier, code, purpose) {
  const { OtpToken } = getModels();
  const otp = await OtpToken.findOne({
    where: { [identifierField]: identifier, purpose, consumed: false },
    order: [['createdAt', 'DESC']],
  });
  if (!otp || otp.expiresAt <= new Date()) {
    if (otp) {
      otp.consumed = true;
      await otp.save();
    }
    return { error: ['OTP_EXPIRED', 'This verification code has expired.'] };
  }
  if (otp.attempts >= OTP_MAX_ATTEMPTS) {
    return {
      error: [
        'OTP_MAX_ATTEMPTS',
        'Maximum verification attempts reached. Request a new code.',
      ],
    };
  }

  const accepted = matchesFixedOtp(code) || await bcrypt.compare(code, otp.codeHash);
  if (!accepted) {
    otp.attempts += 1;
    if (otp.attempts >= OTP_MAX_ATTEMPTS) otp.consumed = true;
    await otp.save();
    return {
      error: [
        otp.attempts >= OTP_MAX_ATTEMPTS ? 'OTP_MAX_ATTEMPTS' : 'OTP_INVALID',
        otp.attempts >= OTP_MAX_ATTEMPTS
          ? 'Maximum verification attempts reached. Request a new code.'
          : 'Invalid verification code.',
        OTP_MAX_ATTEMPTS - otp.attempts,
      ],
    };
  }

  otp.consumed = true;
  await otp.save();
  return { otp };
}

async function verifyPhoneOtp(phoneNumber, code, purpose) {
  return verifyOtp('phoneNumber', phoneNumber, code, purpose);
}

async function verifyEmailOtp(email, code, purpose) {
  return verifyOtp('email', email, code, purpose);
}

module.exports = {
  OTP_EXPIRY_MS,
  OTP_MAX_ATTEMPTS,
  createEmailOtp,
  createPhoneOtp,
  deliverEmailOtp,
  deliverPhoneOtp,
  verifyEmailOtp,
  verifyPhoneOtp,
};
