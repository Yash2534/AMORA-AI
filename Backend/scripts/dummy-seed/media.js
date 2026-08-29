const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

let crcTable;
function crc32(buffer) {
  if (!crcTable) {
    crcTable = Array.from({ length: 256 }, (_, index) => {
      let value = index;
      for (let bit = 0; bit < 8; bit += 1) value = (value & 1) ? (0xEDB88320 ^ (value >>> 1)) : (value >>> 1);
      return value >>> 0;
    });
  }
  let crc = 0xFFFFFFFF;
  for (const byte of buffer) crc = crcTable[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function chunk(type, data) {
  const typeBuffer = Buffer.from(type, 'ascii');
  const length = Buffer.alloc(4); length.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4); checksum.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])));
  return Buffer.concat([length, typeBuffer, data, checksum]);
}

function generateAvatarPng(index, width = 360, height = 480) {
  const palettes = [
    [[233, 196, 183], [126, 76, 98]], [[176, 213, 211], [36, 91, 108]],
    [[244, 216, 151], [165, 77, 60]], [[200, 190, 226], [77, 62, 118]],
    [[189, 219, 179], [56, 102, 74]], [[239, 190, 204], [130, 56, 86]],
  ];
  const [background, accent] = palettes[index % palettes.length];
  const pixels = Buffer.alloc((width * 4 + 1) * height);
  const headX = width * (0.42 + ((index % 5) * 0.04));
  const headY = height * (0.31 + ((index % 3) * 0.015));
  const headRadius = width * (0.15 + ((index % 4) * 0.008));
  const shoulderY = height * 0.62;
  for (let y = 0; y < height; y += 1) {
    const rowOffset = y * (width * 4 + 1);
    pixels[rowOffset] = 0;
    const blend = y / height;
    for (let x = 0; x < width; x += 1) {
      const radial = Math.sqrt(((x - headX) ** 2) + ((y - headY) ** 2)) < headRadius;
      const shoulders = y > shoulderY && (((x - width / 2) / (width * 0.43)) ** 2 + ((y - height * 0.9) / (height * 0.34)) ** 2 < 1);
      const foreground = radial || shoulders;
      const base = foreground ? accent : background;
      const shade = foreground ? 1 - Math.max(0, y - headY) / height * 0.12 : 0.9 + blend * 0.1;
      const offset = rowOffset + 1 + x * 4;
      pixels[offset] = Math.round(base[0] * shade);
      pixels[offset + 1] = Math.round(base[1] * shade);
      pixels[offset + 2] = Math.round(base[2] * shade);
      pixels[offset + 3] = 255;
    }
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0); header.writeUInt32BE(height, 4);
  header[8] = 8; header[9] = 6; header[10] = 0; header[11] = 0; header[12] = 0;
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(pixels, { level: 9 })), chunk('IEND', Buffer.alloc(0)),
  ]);
}

function removeSeedMedia(config) {
  if (!fs.existsSync(config.uploadsDirectory)) return 0;
  const files = fs.readdirSync(config.uploadsDirectory).filter((name) => name.startsWith(config.mediaPrefix) && name.endsWith('.png'));
  for (const name of files) fs.unlinkSync(path.join(config.uploadsDirectory, name));
  return files.length;
}

function createSeedMedia(config) {
  fs.mkdirSync(config.uploadsDirectory, { recursive: true });
  removeSeedMedia(config);
  const urls = [];
  for (let index = 0; index < config.mediaVariants; index += 1) {
    const name = `${config.mediaPrefix}${String(index + 1).padStart(3, '0')}.png`;
    fs.writeFileSync(path.join(config.uploadsDirectory, name), generateAvatarPng(index));
    urls.push(`/uploads/onboarding-photos/${name}`);
  }
  return urls;
}

module.exports = { createSeedMedia, generateAvatarPng, removeSeedMedia };
