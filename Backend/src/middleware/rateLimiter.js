const rateLimit = require('express-rate-limit');
const options = (windowMs, max, keyGenerator) => ({ windowMs, max, keyGenerator, standardHeaders: true, legacyHeaders: false, handler: (_req, res) => res.status(429).json({ success: false, message: 'Too many requests. Please try again later.', code: 'RATE_LIMITED', errors: [] }) });
const normalizedIdentity = (req) => {
  const rawPhone = String(req.body.phoneNumber || '').trim();
  if (rawPhone) {
    const digits = rawPhone.replace(/\D/g, '');
    const national = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits;
    return `${req.ip}:phone:${national}`;
  }
  return `${req.ip}:email:${String(req.body.email || '').trim().toLowerCase()}`;
};
module.exports = {
  loginLimiter: rateLimit(options(15 * 60 * 1000, 5, normalizedIdentity)),
  signupLimiter: rateLimit(options(15 * 60 * 1000, 10, (req) => req.ip)),
  otpLimiter: rateLimit(options(45 * 1000, 1, normalizedIdentity)),
  photoUploadLimiter: rateLimit(options(15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  discoverSwipeLimiter: rateLimit(options(5 * 60 * 1000, 120, (req) => String(req.user?.sub || req.ip))),
  reportCreateLimiter: rateLimit(options(60 * 60 * 1000, 5, (req) => String(req.user?.sub || req.ip))),
  chatMessageLimiter: rateLimit(options(60 * 1000, 60, (req) => String(req.user?.sub || req.ip))),
  chatMediaLimiter: rateLimit(options(15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  eventActionLimiter: rateLimit(options(60 * 1000, 30, (req) => String(req.user?.sub || req.ip))),
  paymentOrderLimiter: rateLimit(options(15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  paymentVerifyLimiter: rateLimit(options(15 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip))),
  paymentWebhookLimiter: rateLimit(options(60 * 1000, 300, (req) => String(req.ip))),
  roseSendLimiter: rateLimit(options(5 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip))),
  identityVerificationLimiter: rateLimit(options(60 * 60 * 1000, 5, (req) => String(req.user?.sub || req.ip))),
};
