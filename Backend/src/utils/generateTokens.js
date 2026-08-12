const jwt = require('jsonwebtoken'); const crypto = require('crypto'); const bcrypt = require('bcrypt');
const { getModels } = require('../models');
function accessToken(user) { return jwt.sign({ sub: user.id, email: user.email, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' }); }
async function issueTokens(user, ip, options = {}) {
  const tokenSelector = crypto.randomBytes(16).toString('hex');
  const rawRefreshToken = `${tokenSelector}.${crypto.randomBytes(64).toString('hex')}`;
  const tokenHash = await bcrypt.hash(rawRefreshToken, 12);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  await getModels().RefreshToken.create(
    { userId: user.id, tokenSelector, tokenHash, expiresAt, createdByIp: ip || null },
    options.transaction ? { transaction: options.transaction } : {},
  );
  return { accessToken: accessToken(user), refreshToken: rawRefreshToken };
}
module.exports = { accessToken, issueTokens };
