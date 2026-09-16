const crypto = require('crypto');
const { resolveOtpTestConfig } = require('../config/otpTestConfig');

module.exports = () => {
  const config = resolveOtpTestConfig();
  if (config.enabled && config.fixedOtp) {
    return config.fixedOtp;
  }
  return crypto.randomInt(100000, 1000000).toString();
};
