const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const MAX_PROFILE_PHOTOS = 6;
const uploadDirectory = path.join(__dirname, '../../uploads/onboarding-photos');
const extensions = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
]);
fs.mkdirSync(uploadDirectory, { recursive: true });

const upload = multer({
  storage: multer.memoryStorage(),
  // Keep this in lockstep with DeviceAmoraMediaPicker.maximumImageBytes.
  limits: { fileSize: 12 * 1024 * 1024, files: MAX_PROFILE_PHOTOS },
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

const storageReference = (filename) => `profile-media/${path.basename(filename)}`;

function filenameFromReference(value) {
  const normalized = String(value || '').replaceAll('\\', '/');
  const protectedRoute = normalized.match(/(?:^|\/)api\/media\/profile\/\d+\/([a-zA-Z0-9._-]+)$/);
  if (protectedRoute) return protectedRoute[1];
  const match = normalized.match(/(?:^|\/)(?:profile-media|onboarding-photos|uploads)\/([a-zA-Z0-9._-]+)$/);
  return match ? match[1] : null;
}

const protectedPath = (userId, reference) => {
  const numericUserId = Number(userId);
  if (!Number.isSafeInteger(numericUserId) || numericUserId <= 0) return null;
  const filename = filenameFromReference(reference);
  return filename ? `/api/media/profile/${numericUserId}/${encodeURIComponent(filename)}` : null;
};

const remove = (reference) => {
  const filename = filenameFromReference(reference);
  if (!filename) return;
  const target = path.resolve(uploadDirectory, filename);
  if (path.dirname(target) === path.resolve(uploadDirectory)) fs.unlink(target, () => {});
};

module.exports = {
  MAX_PROFILE_PHOTOS,
  upload,
  store,
  storageReference,
  protectedPath,
  filenameFromReference,
  remove,
  uploadDirectory,
};
