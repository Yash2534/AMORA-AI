const fs = require('fs');
const path = require('path');
const { detectedMimeType } = require('./dummy-seed/media');

function ensureManualQaMedia(config, definition) {
  fs.mkdirSync(config.uploadsDirectory, { recursive: true });
  return [1, 2].map((photoNumber) => {
    const sourceName = `amoraa-v2-profile-${String(
      definition.sourceProfileNumber,
    ).padStart(3, '0')}-${String(photoNumber).padStart(2, '0')}.webp`;
    const source = path.join(config.portraitAssetsDirectory, sourceName);
    if (!fs.existsSync(source)) {
      throw new Error(`Missing generated QA portrait source: ${sourceName}.`);
    }
    const bytes = fs.readFileSync(source);
    if (detectedMimeType(bytes) !== 'image/webp') {
      throw new Error(`QA portrait source is not a valid WebP image: ${sourceName}.`);
    }
    const targetName = `amoraa-manual-qa-${definition.key}-${String(
      photoNumber,
    ).padStart(2, '0')}.webp`;
    fs.copyFileSync(source, path.join(config.uploadsDirectory, targetName));
    return `/uploads/onboarding-photos/${targetName}`;
  });
}

module.exports = { ensureManualQaMedia };
