const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const SUPPORTED_TYPES = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
]);

function sha256(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

function detectedMimeType(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return 'image/png';
  if (buffer.length >= 12 && buffer.subarray(0, 4).toString() === 'RIFF' && buffer.subarray(8, 12).toString() === 'WEBP') return 'image/webp';
  return null;
}

function listFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const fullPath = path.join(directory, entry.name);
      return entry.isDirectory() ? listFiles(fullPath) : [fullPath];
    })
    .sort((left, right) => left.localeCompare(right));
}

function sourceGender(file) {
  const normalized = file.replace(/\\/g, '/').toLowerCase();
  if (normalized.includes('/female/') || normalized.includes('/female_')) return 'Female';
  if (normalized.includes('/male/') || normalized.includes('/male_')) return 'Male';
  return null;
}

function collectSourceImages(config) {
  const files = [
    ...listFiles(config.repositoryPortraitsDirectory),
    ...listFiles(config.portraitAssetsDirectory),
  ];
  const seenHashes = new Map();
  const sources = [];
  for (const file of files) {
    const gender = sourceGender(file);
    if (!gender) continue;
    const bytes = fs.readFileSync(file);
    const mimeType = detectedMimeType(bytes);
    if (!mimeType) continue;
    const hash = sha256(bytes);
    // Source duplicates are not useful and must never get two demo filenames.
    if (seenHashes.has(hash)) continue;
    seenHashes.set(hash, file);
    sources.push({ file, gender, bytes, mimeType, hash });
  }
  return sources;
}

function sourcePoolFor(gender, pools) {
  if (gender === 'Female') return pools.female;
  if (gender === 'Male') return pools.male;
  return pools.other;
}

function assignSourceImages(config, entries) {
  const sources = collectSourceImages(config);
  const pools = {
    female: sources.filter((source) => source.gender === 'Female'),
    male: sources.filter((source) => source.gender === 'Male'),
    other: sources,
  };
  const needed = entries.reduce((total, entry) => total + entry.photoCount, 0);
  if (sources.length < needed) {
    throw new Error(`Demo profile image pack is incomplete: need ${needed} unique images, found ${sources.length}. Run npm run setup:demo-portrait-assets.`);
  }
  const usedHashes = new Set();
  const cursors = new Map();
  const take = (gender) => {
    const pool = sourcePoolFor(gender, pools);
    let cursor = cursors.get(pool) || 0;
    while (cursor < pool.length && usedHashes.has(pool[cursor].hash)) cursor += 1;
    if (cursor >= pool.length) throw new Error(`Demo profile image pack has insufficient unique ${gender} portraits.`);
    const source = pool[cursor];
    cursors.set(pool, cursor + 1);
    usedHashes.add(source.hash);
    return source;
  };
  return entries.map((entry) => Array.from({ length: entry.photoCount }, (_, photoIndex) => {
    // Non-binary seed profiles alternate broad presentation while still using
    // a globally unique source image.
    const gender = entry.gender === 'Other' ? (photoIndex % 2 ? 'Male' : 'Female') : entry.gender;
    return take(gender);
  }));
}

function removeSeedMedia(config) {
  if (!fs.existsSync(config.uploadsDirectory)) return 0;
  const files = fs.readdirSync(config.uploadsDirectory)
    .filter((name) => name.startsWith(config.mediaPrefix) || name.startsWith('amoraa-seed-avatar-'));
  for (const name of files) fs.unlinkSync(path.join(config.uploadsDirectory, name));
  return files.length;
}

function createSeedMedia(config, blueprint) {
  if (config.environment === 'production') throw new Error('Demo profile image seeding is disabled in production.');
  fs.mkdirSync(config.uploadsDirectory, { recursive: true });
  const assignments = assignSourceImages(config, blueprint.users);
  const plannedHashes = assignments.flat().map((source) => source.hash);
  if (new Set(plannedHashes).size !== plannedHashes.length) throw new Error('Refusing to seed duplicate demo profile image content.');
  removeSeedMedia(config);
  return assignments.map((photos, profileIndex) => photos.map((source, photoIndex) => {
    const extension = SUPPORTED_TYPES.get(source.mimeType);
    const filename = `${config.mediaPrefix}${String(profileIndex + 1).padStart(3, '0')}-${String(photoIndex + 1).padStart(2, '0')}${extension}`;
    fs.writeFileSync(path.join(config.uploadsDirectory, filename), source.bytes, { flag: 'wx' });
    return `/uploads/onboarding-photos/${filename}`;
  }));
}

module.exports = {
  assignSourceImages,
  collectSourceImages,
  createSeedMedia,
  detectedMimeType,
  removeSeedMedia,
  sha256,
};
