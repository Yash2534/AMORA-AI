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

module.exports = (sequelize) => sequelize.define('IdentityVerificationReason', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  code: { type: DataTypes.STRING(80), allowNull: false, unique: true },
  action: { type: DataTypes.ENUM('reject', 'request_resubmission'), allowNull: false },
  label: { type: DataTypes.STRING(160), allowNull: false },
  allowsDetail: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  requiresDetail: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  allowedItems: jsonValue('allowedItems'),
  isActive: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  sortOrder: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
}, { tableName: 'IdentityVerificationReasons' });
