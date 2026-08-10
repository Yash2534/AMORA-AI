const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('Wallet', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, userId: { type: DataTypes.INTEGER, allowNull: false }, status: { type: DataTypes.ENUM('active', 'frozen', 'closed'), allowNull: false, defaultValue: 'active' },
  creditUnit: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'AMORAA_CREDITS' }, balance: { type: DataTypes.BIGINT, allowNull: false, defaultValue: 0 },
}, { tableName: 'Wallets' });
