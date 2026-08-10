const crypto = require('crypto');
const fs = require('fs/promises');
const path = require('path');
const multer = require('multer');

const root = path.join(__dirname, '../../private-uploads/event-feedback');
const types = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
]);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, callback) => {
    if (!types.has(file.mimetype)) {
      const error = new Error('Feedback photos must be JPEG, PNG, or WebP images.');
      error.code = 'INVALID_MEDIA_TYPE';
      return callback(error);
    }
    return callback(null, true);
  },
});

async function saveFeedbackMedia(file) {
  if (!file) return null;
  const bytes = file.buffer;
  const valid = file.mimetype === 'image/jpeg'
    ? bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff
    : file.mimetype === 'image/png'
      ? bytes.length >= 8 && bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
      : file.mimetype === 'image/webp'
        ? bytes.length >= 12 && bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP'
        : false;
  if (!valid) {
    const error = new Error('Feedback photo content does not match its file type.');
    error.code = 'INVALID_MEDIA_TYPE';
    throw error;
  }
  await fs.mkdir(root, { recursive: true });
  const filename = `${Date.now()}-${crypto.randomUUID()}${types.get(file.mimetype)}`;
  await fs.writeFile(path.join(root, filename), file.buffer, { flag: 'wx' });
  return {
    mediaOriginalName: path.basename(file.originalname).slice(0, 255),
    mediaStoragePath: filename,
    mediaMimeType: file.mimetype,
    mediaSizeBytes: file.size,
  };
}

async function removeFeedbackMedia(storagePath) {
  if (!storagePath || path.basename(storagePath) !== storagePath) return;
  await fs.unlink(path.join(root, storagePath)).catch(() => {});
}

module.exports = { upload, saveFeedbackMedia, removeFeedbackMedia };
