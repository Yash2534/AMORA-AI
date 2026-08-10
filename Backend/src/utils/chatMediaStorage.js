const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const mediaDirectory = path.join(__dirname, '../../private-uploads/chat-media');
const maximumMediaBytes = 10 * 1024 * 1024;
const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
fs.mkdirSync(mediaDirectory, { recursive: true });

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: maximumMediaBytes, files: 1 },
  fileFilter: (_req, file, callback) => allowedMimeTypes.has(file.mimetype)
    ? callback(null, true)
    : callback(Object.assign(new Error('Only JPEG, PNG, and WebP chat images are allowed.'), { code: 'INVALID_MEDIA_TYPE' })),
});

function detectedMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.length >= 8 && buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) return 'image/png';
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString() === 'RIFF' && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';
  return null;
}

async function storeMedia(messageId, file) {
  const mimeType = detectedMimeType(file.buffer);
  if (!mimeType || mimeType !== file.mimetype) {
    throw Object.assign(new Error('Chat media content does not match an allowed image type.'), { code: 'INVALID_MEDIA_TYPE' });
  }
  const extension = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' }[mimeType];
  const filename = `${Number(messageId)}-${Date.now()}-${crypto.randomBytes(16).toString('hex')}${extension}`;
  const absolutePath = path.join(mediaDirectory, filename);
  await fs.promises.writeFile(absolutePath, file.buffer, { flag: 'wx' });
  return {
    absolutePath,
    storagePath: `chat-media/${filename}`,
    originalName: path.basename(file.originalname || 'image').slice(0, 255),
    mimeType,
    sizeBytes: file.size,
  };
}

const absolutePathFor = (storagePath) => {
  const target = path.resolve(path.join(__dirname, '../../private-uploads', storagePath || ''));
  return target.startsWith(path.resolve(mediaDirectory)) ? target : null;
};
const removeStoredMedia = async (absolutePath) => {
  if (!absolutePath || !path.resolve(absolutePath).startsWith(path.resolve(mediaDirectory))) return;
  await fs.promises.unlink(absolutePath).catch(() => {});
};

module.exports = { upload, storeMedia, removeStoredMedia, absolutePathFor, maximumMediaBytes, mediaDirectory };
