const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminMfaRecoveryCode', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  generation: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  codeHash: { type: DataTypes.STRING(64), allowNull: false, unique: true },
  consumedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'AdminMfaRecoveryCodes', updatedAt: false });
