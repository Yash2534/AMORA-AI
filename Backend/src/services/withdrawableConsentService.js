const { getModels } = require('../models');

const WITHDRAWABLE_PURPOSES = Object.freeze({
  OFFERS_NOTIFICATIONS: Object.freeze({ preferenceField: 'offers' }),
});

function invalid(code, message, status = 400) {
  return Object.assign(new Error(message), { code, status });
}

function normalizePurposes(purposes) {
  if (!Array.isArray(purposes) || purposes.length === 0 || purposes.some((purpose) => typeof purpose !== 'string')) throw invalid('INVALID_WITHDRAWAL_SCOPE', 'Withdrawal scope is invalid.');
  const normalized = purposes.map((purpose) => purpose.trim());
  if (new Set(normalized).size !== normalized.length) throw invalid('INVALID_WITHDRAWAL_SCOPE', 'Withdrawal scope contains duplicate purposes.');
  if (normalized.some((purpose) => !Object.hasOwn(WITHDRAWABLE_PURPOSES, purpose))) throw invalid('WITHDRAWAL_PURPOSE_NOT_SUPPORTED', 'Withdrawal purpose is not supported.');
  return normalized;
}

async function currentStates(userId, { transaction = null } = {}) {
  const { ConsentEvent, NotificationPreference } = getModels();
  const purposes = Object.keys(WITHDRAWABLE_PURPOSES);
  const [preference] = await NotificationPreference.findOrCreate({ where: { userId }, defaults: { userId }, transaction });
  const events = await ConsentEvent.findAll({ where: { userId, purpose: purposes }, order: [['occurredAt', 'DESC'], ['id', 'DESC']], transaction });
  return purposes.map((purpose) => {
    const event = events.find((item) => item.purpose === purpose);
    const granted = event ? ['ACCEPTED', 'RECONSENTED'].includes(event.action) : Boolean(preference[WITHDRAWABLE_PURPOSES[purpose].preferenceField]);
    return { purpose, status: granted ? 'granted' : 'withdrawn', withdrawable: true };
  });
}

async function processWithdrawal({ userId, requestId }) {
  const models = getModels();
  try {
    return await models.PrivacyRequest.sequelize.transaction(async (transaction) => {
      const request = await models.PrivacyRequest.findOne({ where: { id: requestId, userId, requestType: 'WITHDRAWAL' }, transaction, lock: transaction.LOCK.UPDATE });
      if (!request) throw invalid('NOT_FOUND', 'Privacy request not found.', 404);
      const metadata = typeof request.metadata === 'string' ? JSON.parse(request.metadata) : request.metadata;
      const purposes = normalizePurposes(metadata?.withdrawalPurposes);
      if (request.status === 'COMPLETED') return { request, states: await currentStates(userId, { transaction }), idempotent: true };
      if (request.status !== 'VERIFIED') throw invalid('PRIVACY_REQUEST_NOT_READY', 'Privacy request is not ready.', 409);
      request.status = 'PROCESSING'; request.processingStartedAt = new Date(); await request.save({ transaction });
      const [preference] = await models.NotificationPreference.findOrCreate({ where: { userId }, defaults: { userId }, transaction, lock: transaction.LOCK.UPDATE });
      const states = await currentStates(userId, { transaction });
      for (const purpose of purposes) {
        if (states.find((state) => state.purpose === purpose)?.status !== 'granted') continue;
        await preference.update({ [WITHDRAWABLE_PURPOSES[purpose].preferenceField]: false }, { transaction });
        await models.ConsentEvent.create({ userId, documentVersionId: null, purpose, action: 'WITHDRAWN', source: 'SETTINGS', platform: 'WEB', occurredAt: new Date(), metadata: { privacyRequestId: String(request.id) } }, { transaction });
      }
      request.status = 'COMPLETED'; request.completedAt = new Date(); await request.save({ transaction });
      return { request, states: await currentStates(userId, { transaction }), idempotent: false };
    });
  } catch (error) {
    if (error.code || error.status) throw error;
    await models.PrivacyRequest.update({ status: 'FAILED', failedAt: new Date(), failureCode: 'WITHDRAWAL_PROCESSING_FAILED' }, { where: { id: requestId, userId, requestType: 'WITHDRAWAL', status: ['VERIFIED', 'PROCESSING'] } });
    throw invalid('WITHDRAWAL_PROCESSING_FAILED', 'Withdrawal could not be completed.', 500);
  }
}

module.exports = { WITHDRAWABLE_PURPOSES, normalizePurposes, currentStates, processWithdrawal };
