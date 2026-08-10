const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('Gift', {
  id: { type: DataTypes.STRING(64), primaryKey: true }, name: { type: DataTypes.STRING(120), allowNull: false }, type: { type: DataTypes.ENUM('rose', 'gift'), allowNull: false }, description: DataTypes.STRING(255),
  priceCredits: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, creditUnit: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'AMORAA_CREDITS' }, assetUrl: DataTypes.STRING(500), active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true }, sortOrder: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
}, { tableName: 'Gifts' });
