const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('WalletTransaction', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, walletId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false }, userId: { type: DataTypes.INTEGER, allowNull: false },
  type: { type: DataTypes.ENUM('top_up', 'gift_spend', 'boost_spend', 'redemption', 'refund', 'adjustment'), allowNull: false }, direction: { type: DataTypes.ENUM('credit', 'debit'), allowNull: false }, amount: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  referenceType: { type: DataTypes.STRING(50), allowNull: false }, referenceId: { type: DataTypes.STRING(100), allowNull: false }, idempotencyKey: { type: DataTypes.STRING(100), allowNull: false },
  balanceBefore: { type: DataTypes.BIGINT, allowNull: false }, balanceAfter: { type: DataTypes.BIGINT, allowNull: false }, status: { type: DataTypes.ENUM('posted', 'reversed'), allowNull: false, defaultValue: 'posted' }, description: DataTypes.STRING(255),
}, { tableName: 'WalletTransactions' });
