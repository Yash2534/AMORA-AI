const assert = require('node:assert/strict');
const { afterEach, test } = require('node:test');
const cloudinary = require('../src/config/cloudinary');

const keys = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET', 'CLOUDINARY_UPLOAD_PRESET'];
const original = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
const restore = () => keys.forEach((key) => { if (original[key] === undefined) delete process.env[key]; else process.env[key] = original[key]; });
afterEach(restore);

test('rejects a Cloudinary signature when configuration is absent', () => {
  keys.forEach((key) => delete process.env[key]);
  assert.throws(() => cloudinary.createProfilePhotoSignature(42), { code: 'CLOUDINARY_NOT_CONFIGURED', status: 503 });
});

test('creates an image-only, user-scoped signature without exposing the API secret', () => {
  process.env.CLOUDINARY_CLOUD_NAME = 'test-cloud'; process.env.CLOUDINARY_API_KEY = 'test-key'; process.env.CLOUDINARY_API_SECRET = 'test-secret'; process.env.CLOUDINARY_UPLOAD_PRESET = 'test-preset';
  const signature = cloudinary.createProfilePhotoSignature(42);
  assert.equal(signature.cloudName, 'test-cloud'); assert.equal(signature.apiKey, 'test-key'); assert.match(signature.folder, /^amora\/dev\/users\/42\/profile$/); assert.match(signature.publicId, /^profile-/); assert.equal(typeof signature.signature, 'string'); assert.equal(Object.hasOwn(signature, 'apiSecret'), false); assert.deepEqual(signature.allowedFormats, ['jpg', 'jpeg', 'png', 'webp']);
});

test('accepts only supported image MIME types for signatures', () => {
  assert.equal(cloudinary.validMimeType('image/jpeg'), true); assert.equal(cloudinary.validMimeType('image/png'), true); assert.equal(cloudinary.validMimeType('image/webp'), true); assert.equal(cloudinary.validMimeType('image/gif'), false);
});
