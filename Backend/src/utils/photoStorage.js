const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const uploadDirectory = path.join(__dirname, '../../uploads/onboarding-photos');
const extensions = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
]);
fs.mkdirSync(uploadDirectory, { recursive: true });

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 6 },
  fileFilter: (_req, file, callback) => extensions.has(file.mimetype)
    ? callback(null, true)
    : callback(Object.assign(
      new Error('Only JPEG, PNG, and WebP images are allowed.'),
      { code: 'INVALID_PHOTO_TYPE' },
    )),
});

function detectedMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString() === 'RIFF' && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';
  return null;
}

async function store(userId, file) {
  const mimeType = detectedMimeType(file.buffer);
  if (!mimeType || mimeType !== file.mimetype) {
    throw Object.assign(
      new Error('Photo content does not match an allowed image type.'),
      { status: 400, code: 'INVALID_PHOTO_TYPE' },
    );
  }
  const filename = `${Number(userId)}-${Date.now()}-${crypto.randomBytes(8).toString('hex')}${extensions.get(mimeType)}`;
  await fs.promises.writeFile(path.join(uploadDirectory, filename), file.buffer, { flag: 'wx' });
  return filename;
}

const publicPath = (filename) => `/uploads/onboarding-photos/${path.basename(filename)}`;

const remove = (url) => {
  if (!url || !url.startsWith('/uploads/onboarding-photos/')) return;
  const target = path.resolve(uploadDirectory, path.basename(url));
  if (target.startsWith(path.resolve(uploadDirectory))) fs.unlink(target, () => {});
};

module.exports = { upload, store, publicPath, remove, uploadDirectory };
