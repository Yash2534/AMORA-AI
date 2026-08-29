require('../src/config/bootstrapEnv');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { resolveDummySeedConfig } = require('./dummy-seed/config');
const { detectedMimeType } = require('./dummy-seed/media');

const FAKER_CDN = 'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait';
const VARIANTS = ['female', 'male'];
const INDICES = Array.from({ length: 100 }, (_, index) => index);

function digest(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

async function download(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
  const buffer = Buffer.from(await response.arrayBuffer());
  if (!buffer.length || detectedMimeType(buffer) !== 'image/jpeg') throw new Error(`${url} did not return a JPEG image`);
  return buffer;
}

async function run() {
  const config = resolveDummySeedConfig();
  if (config.environment === 'production') throw new Error('Demo portrait asset setup is disabled in production.');
  const targets = VARIANTS.flatMap((gender) => INDICES.map((index) => ({
    gender,
    index,
    target: path.join(config.portraitAssetsDirectory, gender, `faker-${String(index).padStart(3, '0')}.jpg`),
    url: `${FAKER_CDN}/${gender}/512/${index}.jpg`,
  })));
  const hashes = new Map();
  let downloaded = 0;
  for (const item of targets) {
    fs.mkdirSync(path.dirname(item.target), { recursive: true });
    const bytes = fs.existsSync(item.target) ? fs.readFileSync(item.target) : await download(item.url);
    if (detectedMimeType(bytes) !== 'image/jpeg') throw new Error(`Invalid cached portrait ${item.target}`);
    const hash = digest(bytes);
    if (hashes.has(hash)) throw new Error(`Duplicate portrait source: ${item.target} and ${hashes.get(hash)}`);
    hashes.set(hash, item.target);
    if (!fs.existsSync(item.target)) {
      fs.writeFileSync(item.target, bytes, { flag: 'wx' });
      downloaded += 1;
    }
  }
  if (hashes.size !== targets.length) throw new Error('Demo portrait asset setup detected duplicate image content.');
  console.log(`[DemoPortraitAssets] Ready: ${targets.length} CC0 AI-generated source portraits (${downloaded} downloaded, ${targets.length - downloaded} reused).`);
  console.log('[DemoPortraitAssets] Source: faker-js/assets-person-portrait (CC0-1.0).');
}

if (require.main === module) run().catch((error) => { console.error(`[DemoPortraitAssets] ${error.message}`); process.exitCode = 1; });
module.exports = { run };
