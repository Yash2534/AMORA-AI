const { DataTypes } = require('sequelize');

const REQUEST_TYPES = Object.freeze({
  ACCESS: 'ACCESS',
  EXPORT: 'EXPORT',
  CORRECTION: 'CORRECTION',
  WITHDRAWAL: 'WITHDRAWAL',
});

const STATUSES = Object.freeze({
  IDENTITY_VERIFICATION_REQUIRED: 'IDENTITY_VERIFICATION_REQUIRED',
  VERIFIED: 'VERIFIED',
  PROCESSING: 'PROCESSING',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
});

const definePrivacyRequest = (sequelize) => sequelize.define('PrivacyRequest', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  // Nullable only if a future physical User deletion is explicitly approved; this preserves audit evidence.
  userId: { type: DataTypes.INTEGER, allowNull: true },
  requestType: { type: DataTypes.ENUM(...Object.values(REQUEST_TYPES)), allowNull: false, validate: { isIn: { args: [Object.values(REQUEST_TYPES)], msg: 'requestType is invalid.' } } },
  status: { type: DataTypes.ENUM(...Object.values(STATUSES)), allowNull: false, defaultValue: STATUSES.IDENTITY_VERIFICATION_REQUIRED, validate: { isIn: { args: [Object.values(STATUSES)], msg: 'status is invalid.' } } },
  requestedAt: { type: DataTypes.DATE, allowNull: false },
  identityVerifiedAt: { type: DataTypes.DATE, allowNull: true },
  processingStartedAt: { type: DataTypes.DATE, allowNull: true },
  completedAt: { type: DataTypes.DATE, allowNull: true },
  failedAt: { type: DataTypes.DATE, allowNull: true },
  failureCode: { type: DataTypes.STRING(80), allowNull: true },
  assignedAdminId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  correlationId: { type: DataTypes.STRING(36), allowNull: false, unique: true },
  // This phase never accepts client metadata. Kept for narrowly controlled future server-side operational metadata.
  metadata: { type: DataTypes.JSON, allowNull: true },
}, {
  tableName: 'PrivacyRequests',
  indexes: [
    { fields: ['userId', 'requestedAt'] },
    { fields: ['requestType', 'status'] },
  ],
});

definePrivacyRequest.REQUEST_TYPES = REQUEST_TYPES;
definePrivacyRequest.STATUSES = STATUSES;
module.exports = definePrivacyRequest;
