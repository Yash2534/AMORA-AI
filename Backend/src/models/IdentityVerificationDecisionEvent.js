const { DataTypes } = require('sequelize');

const jsonValue = (field, fallback = null) => ({
  type: DataTypes.JSON,
  allowNull: true,
  get() {
    const value = this.getDataValue(field);
    if (typeof value !== 'string') return value ?? fallback;
    try { return JSON.parse(value); } catch (_) { return fallback; }
  },
});

module.exports = (sequelize) => sequelize.define('IdentityVerificationDecisionEvent', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  verificationId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  action: { type: DataTypes.ENUM('approve', 'reject', 'request_resubmission'), allowNull: false },
  fromStatus: {
    type: DataTypes.ENUM('pending', 'under_review', 'verified', 'rejected', 'resubmission_requested'),
    allowNull: false,
  },
  toStatus: {
    type: DataTypes.ENUM('pending', 'under_review', 'verified', 'rejected', 'resubmission_requested'),
    allowNull: false,
  },
  reasonId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  reasonCodeSnapshot: { type: DataTypes.STRING(80), allowNull: true },
  reasonLabelSnapshot: { type: DataTypes.STRING(160), allowNull: true },
  reasonDetail: { type: DataTypes.STRING(500), allowNull: true },
  requiredItems: jsonValue('requiredItems'),
  internalNote: { type: DataTypes.STRING(500), allowNull: true },
  submissionVersion: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  idempotencyKey: { type: DataTypes.STRING(160), allowNull: false, unique: true },
  requestHash: { type: DataTypes.CHAR(64), allowNull: false },
  responseSnapshot: jsonValue('responseSnapshot'),
}, {
  tableName: 'IdentityVerificationDecisionEvents',
  updatedAt: false,
  hooks: {
    beforeUpdate() { throw new Error('Identity verification decision events are immutable.'); },
    beforeDestroy() { throw new Error('Identity verification decision events are immutable.'); },
    beforeBulkUpdate() { throw new Error('Identity verification decision events are immutable.'); },
    beforeBulkDestroy() { throw new Error('Identity verification decision events are immutable.'); },
  },
});
