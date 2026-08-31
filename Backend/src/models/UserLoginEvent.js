const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('UserLoginEvent', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  result: { type: DataTypes.ENUM('successful', 'failed'), allowNull: false },
  authenticationMethod: { type: DataTypes.ENUM('password', 'google'), allowNull: false },
  failureCategory: { type: DataTypes.STRING(80), allowNull: true },
  ipAddress: { type: DataTypes.STRING(64), allowNull: true },
  userAgent: { type: DataTypes.STRING(500), allowNull: true },
  occurredAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'UserLoginEvents', createdAt: false, updatedAt: false });
