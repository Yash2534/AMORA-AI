const jwt = require('jsonwebtoken');

exports.token = async (req, res) => {
  const token = jwt.sign({
    sub: Number(req.user.sub),
    ver: Number(req.authUser.tokenVersion || 0),
    purpose: 'realtime',
  }, process.env.JWT_SECRET, { expiresIn: '5m' });
  return res.json({ success: true, message: 'Realtime token issued.', data: { token, expiresInSeconds: 300 } });
};
