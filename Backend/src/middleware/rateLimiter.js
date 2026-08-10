const rateLimit = require('express-rate-limit');
const options = (windowMs, max, keyGenerator) => ({ windowMs, max, keyGenerator, standardHeaders: true, legacyHeaders: false, handler: (_req, res) => res.status(429).json({ success: false, message: 'Too many requests. Please try again later.', code: 'RATE_LIMITED', errors: [] }) });
const normalizedEmail = (req) => `${req.ip}:${String(req.body.phoneNumber || req.body.email || '').trim().toLowerCase()}`;
module.exports = {
  loginLimiter: rateLimit(options(15 * 60 * 1000, 5, normalizedEmail)),
  signupLimiter: rateLimit(options(15 * 60 * 1000, 10, (req) => req.ip)),
  otpLimiter: rateLimit(options(45 * 1000, 1, normalizedEmail)),
  photoUploadLimiter: rateLimit(options(15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  discoverSwipeLimiter: rateLimit(options(5 * 60 * 1000, 120, (req) => String(req.user?.sub || req.ip))),
  reportCreateLimiter: rateLimit(options(60 * 60 * 1000, 5, (req) => String(req.user?.sub || req.ip))),
  reportEvidenceLimiter: rateLimit(options(60 * 60 * 1000, 10, (req) => String(req.user?.sub || req.ip))),
  chatMessageLimiter: rateLimit(options(60 * 1000, 60, (req) => String(req.user?.sub || req.ip))),
  chatMediaLimiter: rateLimit(options(15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  realtimeTokenLimiter: rateLimit(options(60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  eventActionLimiter: rateLimit(options(60 * 1000, 30, (req) => String(req.user?.sub || req.ip))),
  eventMessageLimiter: rateLimit(options(60 * 1000, 60, (req) => String(req.user?.sub || req.ip))),
  eventFeedbackLimiter: rateLimit(options(60 * 60 * 1000, 10, (req) => String(req.user?.sub || req.ip))),
  paymentOrderLimiter: rateLimit(options(15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip))),
  paymentVerifyLimiter: rateLimit(options(15 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip))),
  paymentWebhookLimiter: rateLimit(options(60 * 1000, 300, (req) => String(req.ip))),
  walletValueLimiter: rateLimit(options(5 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip))),
  giftSendLimiter: rateLimit(options(5 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip)))
};
