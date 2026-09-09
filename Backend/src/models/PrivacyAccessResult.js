const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('PrivacyAccessResult', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, privacyRequestId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, unique: true }, userId: { type: DataTypes.INTEGER, allowNull: true }, data: { type: DataTypes.JSON, allowNull: false }, generatedAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'PrivacyAccessResults', indexes: [{ fields: ['userId', 'generatedAt'] }] });
