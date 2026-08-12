const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('IdentityVerification', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
  status: {
    type: DataTypes.ENUM('pending', 'under_review', 'verified', 'rejected'),
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
  rejectionReason: { type: DataTypes.STRING(500), allowNull: true },
}, {
  tableName: 'IdentityVerifications',
  indexes: [
    { unique: true, fields: ['userId'] },
    { fields: ['status', 'submittedAt', 'id'] },
  ],
});
