const rateLimit = require('express-rate-limit');
const handler = (_req, res) => {
  require('../services/performanceMetrics').increment('rate_limit_events');
  return res.status(429).json({ success: false, message: 'Too many requests. Please try again later.', code: 'RATE_LIMITED', errors: [] });
};
const options = (name, windowMs, max, keyGenerator, storeFactory) => ({
  windowMs,
  max,
  keyGenerator,
  standardHeaders: true,
  legacyHeaders: false,
  handler,
  ...(storeFactory ? { store: storeFactory(name, { windowMs, max }) } : {}),
});
const normalizedIdentity = (req) => {
  const rawPhone = String(req.body.phoneNumber || '').trim();
  if (rawPhone) {
    const digits = rawPhone.replace(/\D/g, '');
    const national = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits;
    return `${req.ip}:phone:${national}`;
  }
  return `${req.ip}:email:${String(req.body.email || '').trim().toLowerCase()}`;
};
function buildRateLimiters({ storeFactory } = {}) {
  return {
  loginLimiter: rateLimit(options('login', 15 * 60 * 1000, 5, normalizedIdentity, storeFactory)),
  reactivationLimiter: rateLimit(options('reactivation', 15 * 60 * 1000, 10, (req) => String(req.ip), storeFactory)),
  accountDeletionReauthLimiter: rateLimit(options('account-deletion-reauth', 15 * 60 * 1000, 5, (req) => String(req.user?.sub || req.ip), storeFactory)),
  accountDeletionOtpLimiter: rateLimit(options('account-deletion-otp', 45 * 1000, 1, (req) => String(req.user?.sub || req.ip), storeFactory)),
  signupLimiter: rateLimit(options('signup', 15 * 60 * 1000, 10, (req) => req.ip, storeFactory)),
  otpRequestLimiter: rateLimit(options('otp-request', 45 * 1000, 1, normalizedIdentity, storeFactory)),
  otpVerificationLimiter: rateLimit(options('otp-verification', 15 * 60 * 1000, 5, normalizedIdentity, storeFactory)),
  passwordResetLimiter: rateLimit(options('password-reset', 15 * 60 * 1000, 5, normalizedIdentity, storeFactory)),
    photoUploadLimiter: rateLimit(options('photo-upload', 15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip), storeFactory)),
    discoverSwipeLimiter: rateLimit(options('discover-swipe', 5 * 60 * 1000, 120, (req) => String(req.user?.sub || req.ip), storeFactory)),
    reportCreateLimiter: rateLimit(options('report-create', 60 * 60 * 1000, 5, (req) => String(req.user?.sub || req.ip), storeFactory)),
    chatMessageLimiter: rateLimit(options('chat-message', 60 * 1000, 60, (req) => String(req.user?.sub || req.ip), storeFactory)),
    chatMediaLimiter: rateLimit(options('chat-media', 15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip), storeFactory)),
    eventActionLimiter: rateLimit(options('event-action', 60 * 1000, 30, (req) => String(req.user?.sub || req.ip), storeFactory)),
    paymentOrderLimiter: rateLimit(options('payment-order', 15 * 60 * 1000, 20, (req) => String(req.user?.sub || req.ip), storeFactory)),
    paymentVerifyLimiter: rateLimit(options('payment-verify', 15 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip), storeFactory)),
    paymentWebhookLimiter: rateLimit(options('payment-webhook', 60 * 1000, 300, (req) => String(req.ip), storeFactory)),
    roseSendLimiter: rateLimit(options('rose-send', 5 * 60 * 1000, 30, (req) => String(req.user?.sub || req.ip), storeFactory)),
    identityVerificationLimiter: rateLimit(options('identity-verification', 60 * 60 * 1000, 5, (req) => String(req.user?.sub || req.ip), storeFactory)),
    mediaDownloadLimiter: rateLimit(options('media-download', 60 * 1000, 120, (req) => String(req.user?.sub || req.ip), storeFactory)),
    grievanceLimiter: rateLimit(options('grievance', 60 * 60 * 1000, 10, (req) => String(req.user?.sub || req.ip), storeFactory)),
    privacyRequestLimiter: rateLimit(options('privacy-request', 15 * 60 * 1000, 60, (req) => String(req.user?.sub || req.ip), storeFactory)),
  };
}

module.exports = { ...buildRateLimiters(), buildRateLimiters, normalizedIdentity };
