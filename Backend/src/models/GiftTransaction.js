const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('GiftTransaction', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, senderId: { type: DataTypes.INTEGER, allowNull: false }, recipientId: { type: DataTypes.INTEGER, allowNull: false }, giftId: { type: DataTypes.STRING(64), allowNull: false },
  walletTransactionId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false }, conversationId: DataTypes.INTEGER, priceAtPurchase: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, creditUnit: { type: DataTypes.STRING(32), allowNull: false },
  idempotencyKey: { type: DataTypes.STRING(100), allowNull: false }, status: { type: DataTypes.ENUM('sent', 'refunded', 'reversed'), allowNull: false, defaultValue: 'sent' }, note: DataTypes.STRING(280),
}, { tableName: 'GiftTransactions' });
