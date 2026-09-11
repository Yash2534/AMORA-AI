const { DataTypes } = require('sequelize');

const DOCUMENT_KEYS = Object.freeze({ TERMS_OF_SERVICE: 'TERMS_OF_SERVICE', PRIVACY_POLICY: 'PRIVACY_POLICY' });
const STATUSES = Object.freeze({ DRAFT: 'DRAFT', PUBLISHED: 'PUBLISHED', ACTIVE: 'ACTIVE', RETIRED: 'RETIRED' });
const values = (object) => Object.values(object);

const defineLegalDocumentVersion = (sequelize) => sequelize.define('LegalDocumentVersion', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  documentKey: { type: DataTypes.ENUM(...values(DOCUMENT_KEYS)), allowNull: false, validate: { isIn: [values(DOCUMENT_KEYS)] } },
  version: { type: DataTypes.STRING(64), allowNull: false, validate: { notEmpty: true } },
  contentHash: { type: DataTypes.CHAR(64), allowNull: false, validate: { is: /^[a-f0-9]{64}$/i } },
  // Canonical, versioned content.  Consent must always be tied to the exact
  // document a member was shown, rather than to a mutable app screen.
  content: { type: DataTypes.TEXT('long'), allowNull: false },
  publishedAt: { type: DataTypes.DATE, allowNull: false },
  effectiveAt: { type: DataTypes.DATE, allowNull: false },
  retiredAt: { type: DataTypes.DATE, allowNull: true },
  status: { type: DataTypes.ENUM(...values(STATUSES)), allowNull: false, defaultValue: STATUSES.DRAFT, validate: { isIn: [values(STATUSES)] } },
}, {
  tableName: 'LegalDocumentVersions',
  indexes: [{ unique: true, fields: ['documentKey', 'version'] }, { fields: ['documentKey', 'status', 'effectiveAt'] }],
  hooks: {
    async beforeUpdate(document) {
      if (!['documentKey', 'version', 'contentHash'].some((field) => document.changed(field))) return;
      const ConsentEvent = document.sequelize.models.ConsentEvent;
      if (ConsentEvent && await ConsentEvent.count({ where: { documentVersionId: document.id } })) {
        throw new Error('Referenced legal document versions are immutable.');
      }
    },
  },
});

defineLegalDocumentVersion.DOCUMENT_KEYS = DOCUMENT_KEYS;
defineLegalDocumentVersion.STATUSES = STATUSES;
module.exports = defineLegalDocumentVersion;
