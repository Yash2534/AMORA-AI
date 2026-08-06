const jwt = require('jsonwebtoken');
module.exports = (req, res, next) => {
  const value = req.headers.authorization || ''; const token = value.startsWith('Bearer ') ? value.slice(7) : null;
  if (!token) return res.status(401).json({ success: false, message: 'Access token is required.', code: 'TOKEN_INVALID', errors: [] });
  try { req.user = jwt.verify(token, process.env.JWT_SECRET); return next(); }
  catch (error) { return res.status(401).json({ success: false, message: error.name === 'TokenExpiredError' ? 'Access token has expired.' : 'Invalid access token.', code: error.name === 'TokenExpiredError' ? 'TOKEN_EXPIRED' : 'TOKEN_INVALID', errors: [] }); }
};
