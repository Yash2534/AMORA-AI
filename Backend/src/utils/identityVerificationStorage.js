const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const verificationDirectory = path.join(__dirname, '../../private-uploads/identity-verification');
const maximumDocumentBytes = 12 * 1024 * 1024;
const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
fs.mkdirSync(verificationDirectory, { recursive: true });

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: maximumDocumentBytes, files: 2, fields: 4 },
  fileFilter: (_req, file, callback) => allowedMimeTypes.has(file.mimetype)
    ? callback(null, true)
    : callback(Object.assign(new Error('Only JPEG, PNG, and WebP verification images are allowed.'), { code: 'INVALID_VERIFICATION_MEDIA' })),
});

function detectedMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.length >= 8 && buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) return 'image/png';
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString() === 'RIFF' && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';
  return null;
}

async function storeOne(userId, kind, file) {
  const mimeType = detectedMimeType(file.buffer);
  if (!mimeType || mimeType !== file.mimetype) {
    const error = new Error(`${kind} content does not match an allowed image type.`);
    error.code = 'INVALID_VERIFICATION_MEDIA';
    throw error;
  }
  const extension = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' }[mimeType];
  const filename = `${Number(userId)}-${kind}-${Date.now()}-${crypto.randomBytes(18).toString('hex')}${extension}`;
  const absolutePath = path.join(verificationDirectory, filename);
  await fs.promises.writeFile(absolutePath, file.buffer, { flag: 'wx', mode: 0o600 });
  return {
    absolutePath,
    storagePath: `identity-verification/${filename}`,
    mimeType,
    sizeBytes: file.size,
  };
}

async function storeSubmission(userId, aadhaar, selfie) {
  const stored = [];
  try {
    const aadhaarFile = await storeOne(userId, 'aadhaar', aadhaar);
    stored.push(aadhaarFile.absolutePath);
    const selfieFile = await storeOne(userId, 'selfie', selfie);
    stored.push(selfieFile.absolutePath);
    return { aadhaar: aadhaarFile, selfie: selfieFile };
  } catch (error) {
    await Promise.all(stored.map((file) => fs.promises.unlink(file).catch(() => {})));
    throw error;
  }
}

function absolutePathFor(storagePath) {
  const relative = String(storagePath || '').replace(/^identity-verification[\\/]/, '');
  const resolved = path.resolve(verificationDirectory, relative);
  const root = `${path.resolve(verificationDirectory)}${path.sep}`;
  return resolved.startsWith(root) ? resolved : null;
}

async function removeStored(storagePath) {
  const absolute = absolutePathFor(storagePath);
  if (absolute) await fs.promises.unlink(absolute).catch(() => {});
}

module.exports = { upload, storeSubmission, removeStored, absolutePathFor, maximumDocumentBytes };
