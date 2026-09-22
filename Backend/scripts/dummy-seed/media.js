const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function sha256(buffer) { return crypto.createHash('sha256').update(buffer).digest('hex'); }
function detectedMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString() === 'RIFF' && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';
  return null;
}

function sourcePath(config, profileIndex, photoIndex) {
  return path.join(config.portraitAssetsDirectory, `${config.mediaPrefix}${String(profileIndex + 1).padStart(3, '0')}-${String(photoIndex + 1).padStart(2, '0')}.webp`);
}

function collectSourceImages(config) {
  if (!fs.existsSync(config.portraitAssetsDirectory)) return [];
  return fs.readdirSync(config.portraitAssetsDirectory).filter((name) => name.startsWith(config.mediaPrefix)).sort().map((name) => {
    const file = path.join(config.portraitAssetsDirectory, name); const bytes = fs.readFileSync(file);
    return { file, bytes, mimeType: detectedMimeType(bytes), hash: sha256(bytes) };
  }).filter((item) => item.mimeType);
}

function assignSourceImages(config, entries) {
  return entries.map((entry, profileIndex) => Array.from({ length: entry.photoCount }, (_, photoIndex) => {
    const file = sourcePath(config, profileIndex, photoIndex); if (!fs.existsSync(file)) throw new Error(`Missing generated portrait source ${file}. Run the portrait build script.`);
    const bytes = fs.readFileSync(file); const mimeType = detectedMimeType(bytes); if (!mimeType) throw new Error(`Unsupported generated portrait ${file}.`);
    return { file, bytes, mimeType, hash: sha256(bytes), gender: entry.gender };
  }));
}

function removeSeedMedia(config) {
  if (!fs.existsSync(config.uploadsDirectory)) return 0;
  const files = fs.readdirSync(config.uploadsDirectory).filter((name) => name.startsWith(config.mediaPrefix) || name.startsWith('amoraa-demo-profile-') || name.startsWith('amoraa-seed-avatar-'));
  for (const name of files) fs.unlinkSync(path.join(config.uploadsDirectory, name));
  let chatFiles = [];
  if (fs.existsSync(config.chatMediaDirectory)) {
    chatFiles = fs.readdirSync(config.chatMediaDirectory).filter((name) => name.startsWith('amoraa-v2-seed-chat-'));
    for (const name of chatFiles) fs.unlinkSync(path.join(config.chatMediaDirectory, name));
  }
  return files.length + chatFiles.length;
}

function createSeedMedia(config, blueprint) {
  if (config.environment === 'production') throw new Error('Development portrait seeding is disabled in production.');
  fs.mkdirSync(config.uploadsDirectory, { recursive: true });
  const assignments = assignSourceImages(config, blueprint.users); const hashes = assignments.flat().map((source) => source.hash);
  if (new Set(hashes).size !== hashes.length) throw new Error('Generated portrait pack contains duplicate image content.');
  removeSeedMedia(config);
  fs.mkdirSync(config.chatMediaDirectory, { recursive: true });
  fs.copyFileSync(sourcePath(config, 0, 1), path.join(config.chatMediaDirectory, 'amoraa-v2-seed-chat-image.webp'), fs.constants.COPYFILE_EXCL);
  return assignments.map((photos, profileIndex) => photos.map((source, photoIndex) => {
    const filename = `${config.mediaPrefix}${String(profileIndex + 1).padStart(3, '0')}-${String(photoIndex + 1).padStart(2, '0')}.webp`;
    fs.copyFileSync(source.file, path.join(config.uploadsDirectory, filename), fs.constants.COPYFILE_EXCL);
    return `/uploads/onboarding-photos/${filename}`;
  }));
}

module.exports = { assignSourceImages, collectSourceImages, createSeedMedia, detectedMimeType, removeSeedMedia, sha256 };
