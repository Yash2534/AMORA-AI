const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminPasswordResetToken', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  selector: { type: DataTypes.STRING(32), allowNull: false, unique: true },
  tokenHash: { type: DataTypes.STRING(64), allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  consumedAt: { type: DataTypes.DATE, allowNull: true },
  requestedByIp: { type: DataTypes.STRING(64), allowNull: true },
}, { tableName: 'AdminPasswordResetTokens', updatedAt: false });
