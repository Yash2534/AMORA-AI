const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Administrator', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  name: { type: DataTypes.STRING(120), allowNull: false },
  email: { type: DataTypes.STRING(191), allowNull: false, unique: true, validate: { isEmail: true } },
  passwordHash: { type: DataTypes.STRING(255), allowNull: false },
  status: { type: DataTypes.ENUM('active', 'suspended', 'disabled'), allowNull: false, defaultValue: 'active' },
  tokenVersion: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  failedLoginAttempts: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  lockedUntil: { type: DataTypes.DATE, allowNull: true },
  lastLoginAt: { type: DataTypes.DATE, allowNull: true },
  lastActiveAt: { type: DataTypes.DATE, allowNull: true },
  createdByAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
}, { tableName: 'Administrators' });
