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

module.exports = (sequelize) => sequelize.define('IdentityVerification', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
  status: {
    type: DataTypes.ENUM('pending', 'under_review', 'verified', 'rejected', 'resubmission_requested'),
    allowNull: false,
    defaultValue: 'pending',
  },
  aadhaarStoragePath: { type: DataTypes.STRING(500), allowNull: false },
  aadhaarMimeType: { type: DataTypes.STRING(50), allowNull: false },
  aadhaarSizeBytes: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  selfieStoragePath: { type: DataTypes.STRING(500), allowNull: false },
  selfieMimeType: { type: DataTypes.STRING(50), allowNull: false },
  selfieSizeBytes: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  submittedAt: { type: DataTypes.DATE, allowNull: false },
  reviewedAt: { type: DataTypes.DATE, allowNull: true },
  reviewerAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  reviewVersion: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
  submissionVersion: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
  reviewReasonCode: { type: DataTypes.STRING(80), allowNull: true },
  resubmissionItems: jsonValue('resubmissionItems'),
  rejectionReason: { type: DataTypes.STRING(500), allowNull: true },
}, {
  tableName: 'IdentityVerifications',
  indexes: [
    { unique: true, fields: ['userId'] },
    { fields: ['status', 'submittedAt', 'id'] },
    { fields: ['reviewerAdministratorId', 'reviewedAt', 'id'] },
    { fields: ['status', 'updatedAt', 'id'] },
  ],
});
