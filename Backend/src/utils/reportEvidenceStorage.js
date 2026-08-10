const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const evidenceDirectory = path.join(__dirname, '../../private-uploads/report-evidence');
const maximumEvidenceBytes = 12 * 1024 * 1024;
const maximumEvidenceCount = 5;
const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
fs.mkdirSync(evidenceDirectory, { recursive: true });

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: maximumEvidenceBytes, files: 1 },
  fileFilter: (_req, file, callback) => allowedMimeTypes.has(file.mimetype)
    ? callback(null, true)
    : callback(Object.assign(new Error('Only JPEG, PNG, and WebP evidence images are allowed.'), { code: 'INVALID_EVIDENCE_TYPE' })),
});

function detectedMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.length >= 8 && buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) return 'image/png';
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString() === 'RIFF' && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';
  return null;
}

async function storeEvidence(reportId, file) {
  const mimeType = detectedMimeType(file.buffer);
  if (!mimeType || mimeType !== file.mimetype) {
    const error = new Error('Evidence content does not match an allowed image type.');
    error.code = 'INVALID_EVIDENCE_TYPE';
    throw error;
  }
  const extension = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' }[mimeType];
  const filename = `${Number(reportId)}-${Date.now()}-${crypto.randomBytes(16).toString('hex')}${extension}`;
  const absolutePath = path.join(evidenceDirectory, filename);
  await fs.promises.writeFile(absolutePath, file.buffer, { flag: 'wx' });
  return {
    absolutePath,
    storagePath: `report-evidence/${filename}`,
    originalName: path.basename(file.originalname || 'evidence').slice(0, 255),
    mimeType,
    sizeBytes: file.size,
  };
}

async function removeStoredEvidence(absolutePath) {
  if (!absolutePath || !path.resolve(absolutePath).startsWith(path.resolve(evidenceDirectory))) return;
  await fs.promises.unlink(absolutePath).catch(() => {});
}

module.exports = {
  upload,
  storeEvidence,
  removeStoredEvidence,
  maximumEvidenceBytes,
  maximumEvidenceCount,
  evidenceDirectory,
};
