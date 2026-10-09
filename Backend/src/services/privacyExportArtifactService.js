const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const { Op } = require('sequelize');
const { getModels } = require('../models');

const root = process.env.AMORA_PRIVATE_EXPORT_ROOT
  ? path.resolve(process.env.AMORA_PRIVATE_EXPORT_ROOT)
  : path.resolve(__dirname, '../../private-exports');
const DEFAULT_TTL_MINUTES = 24 * 60;

function ttlMinutes(env = process.env) {
  const requested = Number(env.PRIVACY_EXPORT_TTL_MINUTES || DEFAULT_TTL_MINUTES);
  return Number.isInteger(requested) && requested >= 15 && requested <= DEFAULT_TTL_MINUTES
    ? requested
    : DEFAULT_TTL_MINUTES;
}

const storageKey = () => `${crypto.randomUUID()}.json`;

async function ensureRoot() {
  await fs.promises.mkdir(root, { recursive: true, mode: 0o700 });
}

const serviceError = (message, status, code) => Object.assign(new Error(message), { status, code });

class PrivacyExportArtifactService {
  resolve(key) {
    if (!/^[a-f0-9-]{36}\.json$/i.test(String(key))) throw serviceError('Invalid export storage key.', 400, 'INVALID_STORAGE_KEY');
    const target = path.resolve(root, key);
    if (path.dirname(target) !== root) throw serviceError('Invalid export storage key.', 400, 'INVALID_STORAGE_KEY');
    return target;
  }

  async create({ userId, privacyRequestId }) {
    const { PrivacyRequest, PrivacyExportArtifact } = getModels();
    return PrivacyRequest.sequelize.transaction(async (transaction) => {
      const request = await PrivacyRequest.findOne({ where: { id: privacyRequestId, userId, requestType: 'EXPORT' }, transaction, lock: transaction.LOCK.UPDATE });
      if (!request) throw serviceError('Privacy request not found.', 404, 'NOT_FOUND');
      const [artifact] = await PrivacyExportArtifact.findOrCreate({
        where: { privacyRequestId },
        defaults: { userId, storageKey: storageKey(), filename: `amoraa-data-export-${crypto.randomUUID()}.json` },
        transaction,
      });
      if (Number(artifact.userId) !== Number(userId)) throw serviceError('Privacy request not found.', 404, 'NOT_FOUND');
      return artifact;
    });
  }

  async deleteArtifact(artifact, status = 'DELETED', now = new Date()) {
    await fs.promises.unlink(this.resolve(artifact.storageKey)).catch((error) => {
      if (error.code !== 'ENOENT') throw error;
    });
    await artifact.update({ status, deletedAt: now, failureCode: status === 'EXPIRED' ? 'EXPORT_EXPIRED' : null });
  }

  async cleanupExpired(now = new Date()) {
    const { PrivacyExportArtifact } = getModels();
    const expired = await PrivacyExportArtifact.findAll({
      where: { status: 'GENERATED', expiresAt: { [Op.lte]: now } },
      order: [['id', 'ASC']],
      limit: 100,
    });
    for (const artifact of expired) await this.deleteArtifact(artifact, 'EXPIRED', now);
    return expired.length;
  }

  async download({ userId, privacyRequestId, now = new Date() }) {
    const models = getModels();
    const request = await models.PrivacyRequest.findOne({ where: { id: privacyRequestId, userId, requestType: 'EXPORT' } });
    if (!request) throw serviceError('Privacy request not found.', 404, 'NOT_FOUND');
    if (request.status !== 'COMPLETED') throw serviceError('Export artifact is not ready.', 409, 'EXPORT_ARTIFACT_NOT_READY');
    const artifact = await models.PrivacyExportArtifact.findOne({ where: { privacyRequestId: request.id, userId } });
    if (!artifact || artifact.status !== 'GENERATED') throw serviceError('Export artifact is not ready.', 409, 'EXPORT_ARTIFACT_NOT_READY');
    if (!artifact.expiresAt || new Date(artifact.expiresAt) <= now) {
      await this.deleteArtifact(artifact, 'EXPIRED', now);
      throw serviceError('Export artifact has expired.', 410, 'EXPORT_ARTIFACT_EXPIRED');
    }
    if (!/^amoraa-data-export-[a-f0-9-]{36}\.json$/i.test(String(artifact.filename))) throw serviceError('Export artifact is unavailable.', 409, 'EXPORT_ARTIFACT_UNAVAILABLE');
    const filePath = this.resolve(artifact.storageKey);
    const stat = await fs.promises.stat(filePath).catch(() => null);
    if (!stat?.isFile()) throw serviceError('Export artifact is unavailable.', 409, 'EXPORT_ARTIFACT_UNAVAILABLE');
    return { artifact, filePath };
  }

  async consumeAfterDownload({ userId, privacyRequestId, now = new Date() }) {
    const { PrivacyExportArtifact } = getModels();
    const consumed = await PrivacyExportArtifact.sequelize.transaction(async (transaction) => {
      const artifact = await PrivacyExportArtifact.findOne({
        where: { privacyRequestId, userId, status: 'GENERATED' },
        transaction,
        lock: transaction.LOCK.UPDATE,
      });
      if (!artifact) return null;
      await artifact.update({ status: 'DELETED', downloadedAt: now, deletedAt: now, failureCode: null }, { transaction });
      return artifact.storageKey;
    });
    if (!consumed) return false;
    await fs.promises.unlink(this.resolve(consumed)).catch((error) => {
      if (error.code !== 'ENOENT') throw error;
    });
    return true;
  }

  async generate({ userId, privacyRequestId, now = new Date() }) {
    const models = getModels();
    await this.cleanupExpired(now);
    const request = await models.PrivacyRequest.findOne({ where: { id: privacyRequestId, userId, requestType: 'EXPORT' } });
    if (!request) throw serviceError('Privacy request not found.', 404, 'NOT_FOUND');
    let artifact = await models.PrivacyExportArtifact.findOne({ where: { privacyRequestId, userId } });
    if (request.status === 'COMPLETED' && artifact?.status === 'GENERATED') {
      if (artifact.expiresAt && new Date(artifact.expiresAt) > now) {
        const stat = await fs.promises.stat(this.resolve(artifact.storageKey)).catch(() => null);
        if (stat?.isFile()) return artifact;
      }
      await this.deleteArtifact(artifact, 'EXPIRED', now);
      throw serviceError('Export artifact has expired.', 410, 'EXPORT_ARTIFACT_EXPIRED');
    }
    if (request.status !== 'VERIFIED') throw serviceError('Privacy request is not ready.', 409, 'PRIVACY_REQUEST_NOT_READY');
    artifact = await this.create({ userId, privacyRequestId });
    request.status = 'PROCESSING';
    request.processingStartedAt = now;
    await request.save();
    try {
      const [account, profile, discovery, notifications, consents, requests] = await Promise.all([
        models.User.findByPk(userId, { attributes: ['id', 'name', 'email', 'phoneNumber', 'authProvider', 'isVerified', 'accountStatus', 'createdAt'] }),
        models.OnboardingProfile.findOne({ where: { userId }, attributes: ['birthDate', 'gender', 'city', 'profession', 'education', 'interests', 'languages'] }),
        models.DiscoverFilterPreference.findOne({ where: { userId }, attributes: ['minAge', 'maxAge', 'maxDistanceKm', 'minScore', 'city', 'verifiedOnly'] }),
        models.NotificationPreference.findOne({ where: { userId }, attributes: ['newMatches', 'messages', 'eventReminders', 'offers', 'pushEnabled', 'emailEnabled', 'smsEnabled'] }),
        models.ConsentEvent.findAll({ where: { userId }, attributes: ['documentVersionId', 'purpose', 'action', 'source', 'platform', 'occurredAt'] }),
        models.PrivacyRequest.findAll({ where: { userId }, attributes: ['id', 'requestType', 'status', 'requestedAt', 'identityVerifiedAt', 'completedAt', 'failedAt', 'failureCode', 'correlationId'] }),
      ]);
      const payload = {
        exportMetadata: { schemaVersion: 'amoraa-personal-data-export/v1', generatedAt: now.toISOString(), correlationId: request.correlationId },
        account: account?.toJSON() || null,
        profile: profile?.toJSON() || null,
        preferences: { discovery: discovery?.toJSON() || null, notifications: notifications?.toJSON() || null },
        consents: consents.map((item) => item.toJSON()),
        privacyRequests: requests.map((item) => item.toJSON()),
      };
      const body = JSON.stringify(payload, null, 2);
      await ensureRoot();
      await fs.promises.writeFile(this.resolve(artifact.storageKey), body, { mode: 0o600, flag: 'wx' });
      const expiresAt = new Date(now.getTime() + ttlMinutes() * 60 * 1000);
      await artifact.update({ status: 'GENERATED', byteSize: Buffer.byteLength(body), checksum: crypto.createHash('sha256').update(body).digest('hex'), generatedAt: now, expiresAt, downloadedAt: null, deletedAt: null, failureCode: null });
      request.status = 'COMPLETED';
      request.completedAt = now;
      await request.save();
      return artifact;
    } catch (_) {
      await fs.promises.unlink(this.resolve(artifact.storageKey)).catch(() => {});
      await artifact.update({ status: 'FAILED', failureCode: 'EXPORT_GENERATION_FAILED' });
      request.status = 'FAILED';
      request.failedAt = new Date();
      request.failureCode = 'EXPORT_GENERATION_FAILED';
      await request.save();
      throw serviceError('Export generation failed.', 500, 'EXPORT_GENERATION_FAILED');
    }
  }
}

module.exports = { PrivacyExportArtifactService, ensureRoot, ttlMinutes };
