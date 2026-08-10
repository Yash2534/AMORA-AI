const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('BoostProduct', {
  id: { type: DataTypes.STRING(64), primaryKey: true }, name: { type: DataTypes.STRING(120), allowNull: false }, description: DataTypes.STRING(255), quantity: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
  durationMinutes: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, priceMinor: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, walletCost: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, currency: { type: DataTypes.STRING(3), allowNull: false, defaultValue: 'INR' },
  active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true }, sortOrder: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
}, { tableName: 'BoostProducts' });
