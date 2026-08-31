const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminRefreshToken', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  sessionFamilyId: { type: DataTypes.STRING(36), allowNull: false },
  selector: { type: DataTypes.STRING(32), allowNull: false, unique: true },
  tokenHash: { type: DataTypes.STRING(64), allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  revokedAt: { type: DataTypes.DATE, allowNull: true },
  revokedReason: { type: DataTypes.STRING(40), allowNull: true },
  replacedByTokenId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  createdByIp: { type: DataTypes.STRING(64), allowNull: true },
  userAgent: { type: DataTypes.STRING(500), allowNull: true },
  lastUsedAt: { type: DataTypes.DATE, allowNull: true },
  persistent: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  mfaVerifiedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'AdminRefreshTokens', updatedAt: false });
