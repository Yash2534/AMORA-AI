const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('PrivacyRequestConfirmation', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  privacyRequestId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false }, userId: { type: DataTypes.INTEGER, allowNull: false },
  tokenSelector: { type: DataTypes.STRING(32), allowNull: false, unique: true }, tokenHash: { type: DataTypes.STRING(64), allowNull: false },
  purpose: { type: DataTypes.STRING(64), allowNull: false }, expiresAt: { type: DataTypes.DATE, allowNull: false }, consumedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'PrivacyRequestConfirmations', indexes: [{ fields: ['privacyRequestId', 'userId', 'expiresAt'] }] });
