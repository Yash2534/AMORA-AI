const crypto = require('crypto');
const { v2: cloudinary } = require('cloudinary');

const allowedFormats = ['jpg', 'jpeg', 'png', 'webp'];
const maxImageBytes = 12 * 1024 * 1024;

function settings() {
  return { cloudName: process.env.CLOUDINARY_CLOUD_NAME, apiKey: process.env.CLOUDINARY_API_KEY, apiSecret: process.env.CLOUDINARY_API_SECRET, uploadPreset: process.env.CLOUDINARY_UPLOAD_PRESET || 'kinetictecharc_dev_media' };
}

function unavailable() { return Object.assign(new Error('Cloudinary image uploads are not configured on this server.'), { status: 503, code: 'CLOUDINARY_NOT_CONFIGURED' }); }

function client() {
  const config = settings();
  if (!config.cloudName || !config.apiKey || !config.apiSecret || !config.uploadPreset) throw unavailable();
  cloudinary.config({ cloud_name: config.cloudName, api_key: config.apiKey, api_secret: config.apiSecret, secure: true });
  return { cloudinary, config };
}

function validMimeType(mimeType) { return ['image/jpeg', 'image/png', 'image/webp'].includes(mimeType); }

function createProfilePhotoSignature(userId) {
  const { cloudinary: configured, config } = client();
  const timestamp = Math.floor(Date.now() / 1000);
  const folder = `amora/dev/users/${Number(userId)}/profile`;
  const publicId = `profile-${crypto.randomUUID()}`;
  const params = { timestamp, folder, public_id: publicId, upload_preset: config.uploadPreset, allowed_formats: allowedFormats.join(',') };
  return { cloudName: config.cloudName, apiKey: config.apiKey, timestamp, signature: configured.utils.api_sign_request(params, config.apiSecret), uploadPreset: config.uploadPreset, folder, publicId, allowedFormats };
}

async function verifyProfilePhoto(userId, publicId) {
  const { cloudinary: configured } = client();
  const prefix = `amora/dev/users/${Number(userId)}/profile/`;
  if (typeof publicId !== 'string' || !publicId.startsWith(prefix)) throw Object.assign(new Error('The uploaded image does not belong to this user.'), { status: 400, code: 'INVALID_CLOUDINARY_ASSET' });
  let asset;
  try { asset = await configured.api.resource(publicId, { resource_type: 'image' }); } catch (_) { throw Object.assign(new Error('The uploaded image could not be verified.'), { status: 400, code: 'INVALID_CLOUDINARY_ASSET' }); }
  if (asset.resource_type !== 'image' || !allowedFormats.includes(String(asset.format || '').toLowerCase()) || !asset.secure_url || Number(asset.bytes || 0) > maxImageBytes) throw Object.assign(new Error('The uploaded file is not an allowed image.'), { status: 400, code: 'INVALID_PHOTO_TYPE' });
  return { publicId: asset.public_id, secureUrl: asset.secure_url, resourceType: asset.resource_type, format: asset.format, width: asset.width, height: asset.height, bytes: asset.bytes };
}

async function destroyProfilePhoto(publicId) {
  if (!publicId) return;
  const { cloudinary: configured } = client();
  const result = await configured.uploader.destroy(publicId, { resource_type: 'image', invalidate: true });
  if (!['ok', 'not found'].includes(result.result)) throw Object.assign(new Error('The Cloudinary image could not be deleted.'), { status: 502, code: 'CLOUDINARY_DELETE_FAILED' });
}

module.exports = { allowedFormats, validMimeType, createProfilePhotoSignature, verifyProfilePhoto, destroyProfilePhoto };
