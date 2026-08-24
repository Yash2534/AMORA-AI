const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminAuditLog', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  action: { type: DataTypes.STRING(160), allowNull: false },
  targetType: { type: DataTypes.STRING(80), allowNull: true },
  targetId: { type: DataTypes.STRING(191), allowNull: true },
  oldValue: { type: DataTypes.JSON, allowNull: true },
  newValue: { type: DataTypes.JSON, allowNull: true },
  reason: { type: DataTypes.STRING(500), allowNull: true },
  metadata: { type: DataTypes.JSON, allowNull: true },
  ipAddress: { type: DataTypes.STRING(64), allowNull: true },
  userAgent: { type: DataTypes.STRING(500), allowNull: true },
  correlationId: { type: DataTypes.STRING(80), allowNull: true },
}, { tableName: 'AdminAuditLogs', updatedAt: false });
