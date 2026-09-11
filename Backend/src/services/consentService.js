const { Op } = require('sequelize');
const { getModels } = require('../models');

const REQUIRED_SIGNUP_DOCUMENTS = Object.freeze([
  { documentKey: 'TERMS_OF_SERVICE', purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'ACCEPTED' },
  // Privacy is recorded as notice acknowledgement, not optional processing consent.
  { documentKey: 'PRIVACY_POLICY', purpose: 'PRIVACY_POLICY_ACKNOWLEDGEMENT', action: 'ACKNOWLEDGED' },
]);
const metadataKeys = new Set(['appVersion', 'locale', 'flowVersion']);

const serviceError = (code, message, status = 422) => Object.assign(new Error(message), { code, status });

function safeMetadata(value) {
  if (value == null) return null;
  if (!value || Array.isArray(value) || typeof value !== 'object') throw serviceError('CONSENT_METADATA_INVALID', 'Consent metadata is invalid.');
  const result = {};
  for (const [key, item] of Object.entries(value)) {
    if (!metadataKeys.has(key) || typeof item !== 'string' || item.length > 80) throw serviceError('CONSENT_METADATA_INVALID', 'Consent metadata is invalid.');
    result[key] = item;
  }
  return result;
}

class ConsentService {
  constructor({ models = getModels, now = () => new Date() } = {}) { this.models = models; this.now = now; }

  async getActiveLegalDocument(documentKey, { transaction } = {}) {
    const { LegalDocumentVersion } = this.models();
    const now = this.now();
    const documents = await LegalDocumentVersion.findAll({
      where: { documentKey, status: 'ACTIVE', effectiveAt: { [Op.lte]: now }, [Op.or]: [{ retiredAt: null }, { retiredAt: { [Op.gt]: now } }] },
      order: [['effectiveAt', 'DESC'], ['id', 'DESC']], transaction,
    });
    if (documents.length !== 1) throw serviceError('LEGAL_DOCUMENTS_NOT_CONFIGURED', 'Required legal documents are not available.', 503);
    return documents[0];
  }

  async requiredSignupDocuments({ transaction } = {}) {
    return Promise.all(REQUIRED_SIGNUP_DOCUMENTS.map(async (requirement) => {
      const document = await this.getActiveLegalDocument(requirement.documentKey, { transaction });
      return {
        documentKey: document.documentKey,
        documentVersionId: String(document.id),
        version: document.version,
        effectiveAt: document.effectiveAt,
        title: document.documentKey === 'TERMS_OF_SERVICE' ? 'Terms & Conditions' : 'Privacy Policy',
        content: document.content,
      };
    }));
  }

  async recordRequiredSignupConsent({ userId, acceptedLegalDocuments, source, platform, metadata, transaction }) {
    const accepted = new Map((acceptedLegalDocuments || []).map((item) => [item?.documentKey, String(item?.documentVersionId || '')]));
    if (!accepted.has('TERMS_OF_SERVICE')) throw serviceError('TERMS_ACCEPTANCE_REQUIRED', 'Please accept the Terms and Conditions.');
    if (!accepted.has('PRIVACY_POLICY')) throw serviceError('PRIVACY_ACKNOWLEDGEMENT_REQUIRED', 'Please acknowledge the Privacy Policy.');
    if (accepted.size !== REQUIRED_SIGNUP_DOCUMENTS.length) throw serviceError('LEGAL_ACCEPTANCE_REQUIRED', 'Please accept the required legal documents.');
    const events = [];
    for (const requirement of REQUIRED_SIGNUP_DOCUMENTS) {
      const document = await this.getActiveLegalDocument(requirement.documentKey, { transaction });
      if (accepted.get(requirement.documentKey) !== String(document.id)) {
        throw serviceError('LEGAL_DOCUMENT_VERSION_OUTDATED', 'The legal documents have been updated. Please review the latest version.');
      }
      events.push(await this.recordEvent({ userId, documentVersionId: document.id, purpose: requirement.purpose, action: requirement.action, source, platform, metadata, transaction }));
    }
    return events;
  }

  async recordEvent({ userId, documentVersionId, purpose, action, source, platform, metadata, transaction }) {
    const { LegalDocumentVersion, ConsentEvent } = this.models();
    const document = await LegalDocumentVersion.findByPk(documentVersionId, { transaction });
    if (!document) throw serviceError('LEGAL_DOCUMENT_VERSION_INVALID', 'The legal document version is invalid.');
    const expectedKey = purpose === 'TERMS_OF_SERVICE_ACCEPTANCE' ? 'TERMS_OF_SERVICE' : 'PRIVACY_POLICY';
    if (document.documentKey !== expectedKey) throw serviceError('LEGAL_DOCUMENT_VERSION_INVALID', 'The legal document version is invalid.');
    if (!Object.values(ConsentEvent.ACTIONS).includes(action) || !Object.values(ConsentEvent.SOURCES).includes(source) || !Object.values(ConsentEvent.PLATFORMS).includes(platform)) throw serviceError('CONSENT_EVENT_INVALID', 'Consent event is invalid.');
    return ConsentEvent.create({ userId, documentVersionId: document.id, purpose, action, source, platform, occurredAt: this.now(), metadata: safeMetadata(metadata) }, { transaction });
  }

  async requiresReconsent(userId) {
    const { ConsentEvent } = this.models();
    const missing = [];
    for (const requirement of REQUIRED_SIGNUP_DOCUMENTS) {
      const active = await this.getActiveLegalDocument(requirement.documentKey);
      const latest = await ConsentEvent.findOne({ where: { userId, documentVersionId: active.id }, order: [['occurredAt', 'DESC'], ['id', 'DESC']] });
      if (!latest || latest.action === 'WITHDRAWN' || !['ACCEPTED', 'ACKNOWLEDGED', 'RECONSENTED'].includes(latest.action)) missing.push({ documentKey: active.documentKey, documentVersionId: String(active.id), version: active.version });
    }
    return { requiresLegalAction: missing.length > 0, documents: missing };
  }
}

module.exports = new ConsentService();
module.exports.ConsentService = ConsentService;
module.exports.REQUIRED_SIGNUP_DOCUMENTS = REQUIRED_SIGNUP_DOCUMENTS;
