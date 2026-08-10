const jwt = require('jsonwebtoken'); const crypto = require('crypto'); const bcrypt = require('bcrypt');
const { getModels } = require('../models');
function accessToken(user) { return jwt.sign({ sub: user.id, email: user.email, ver: Number(user.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' }); }
async function issueTokens(user, ip) {
  const rawRefreshToken = crypto.randomBytes(64).toString('hex');
  const tokenHash = await bcrypt.hash(rawRefreshToken, 12);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  await getModels().RefreshToken.create({ userId: user.id, tokenHash, expiresAt, createdByIp: ip || null });
  return { accessToken: accessToken(user), refreshToken: rawRefreshToken };
}
module.exports = { accessToken, issueTokens };
