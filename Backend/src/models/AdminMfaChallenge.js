const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminMfaChallenge', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  selector: { type: DataTypes.STRING(32), allowNull: false, unique: true },
  tokenHash: { type: DataTypes.STRING(64), allowNull: false },
  rememberMe: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  consumedAt: { type: DataTypes.DATE, allowNull: true },
  attempts: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  requestedByIp: { type: DataTypes.STRING(64), allowNull: true },
  userAgent: { type: DataTypes.STRING(500), allowNull: true },
}, { tableName: 'AdminMfaChallenges' });
