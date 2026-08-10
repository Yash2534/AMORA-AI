const fs = require('fs'); const path = require('path'); const multer = require('multer');
const uploadDirectory = path.join(__dirname, '../../uploads/onboarding-photos');
fs.mkdirSync(uploadDirectory, { recursive: true });
const extensionFor = (file) => ({ 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' }[file.mimetype]);
const storage = multer.diskStorage({ destination: (_req, _file, cb) => cb(null, uploadDirectory), filename: (req, file, cb) => cb(null, `${req.user.sub}-${Date.now()}-${Math.random().toString(36).slice(2, 10)}${extensionFor(file) || ''}`) });
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024, files: 6 }, fileFilter: (_req, file, cb) => extensionFor(file) ? cb(null, true) : cb(Object.assign(new Error('Only JPEG, PNG, and WebP images are allowed.'), { code: 'INVALID_PHOTO_TYPE' })) });
const publicPath = (file) => `/uploads/onboarding-photos/${file.filename}`;
const remove = (url) => { if (!url || !url.startsWith('/uploads/onboarding-photos/')) return; const target = path.resolve(uploadDirectory, path.basename(url)); if (target.startsWith(uploadDirectory)) fs.unlink(target, () => {}); };
module.exports = { upload, publicPath, remove, uploadDirectory };
