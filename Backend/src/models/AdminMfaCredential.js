const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminMfaCredential', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, unique: true },
  encryptedSecret: { type: DataTypes.TEXT, allowNull: false },
  secretIv: { type: DataTypes.STRING(24), allowNull: false },
  secretTag: { type: DataTypes.STRING(32), allowNull: false },
  enabledAt: { type: DataTypes.DATE, allowNull: true },
  disabledAt: { type: DataTypes.DATE, allowNull: true },
  lastUsedCounter: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  recoveryCodeGeneration: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
}, { tableName: 'AdminMfaCredentials' });
