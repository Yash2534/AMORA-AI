const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('RefreshToken', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  tokenHash: { type: DataTypes.STRING, allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  createdByIp: { type: DataTypes.STRING, allowNull: true }
}, { tableName: 'RefreshTokens' });
