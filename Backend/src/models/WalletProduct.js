const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('WalletProduct', {
  id: { type: DataTypes.STRING(64), primaryKey: true }, type: { type: DataTypes.ENUM('top_up', 'redemption'), allowNull: false }, name: { type: DataTypes.STRING(120), allowNull: false }, description: DataTypes.STRING(255),
  credits: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 }, priceMinor: DataTypes.INTEGER.UNSIGNED, currency: DataTypes.STRING(3), redemptionKind: DataTypes.ENUM('boost'),
  grantQuantity: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 }, durationMinutes: DataTypes.INTEGER.UNSIGNED, active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true }, sortOrder: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
}, { tableName: 'WalletProducts' });
