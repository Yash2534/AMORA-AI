const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('RoseTransaction', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  senderId: { type: DataTypes.INTEGER, allowNull: false },
  recipientId: { type: DataTypes.INTEGER, allowNull: false },
  conversationId: { type: DataTypes.INTEGER, allowNull: true },
  idempotencyKey: { type: DataTypes.STRING(100), allowNull: false },
  status: { type: DataTypes.ENUM('sent', 'reversed'), allowNull: false, defaultValue: 'sent' },
  note: { type: DataTypes.STRING(280), allowNull: true },
}, { tableName: 'RoseTransactions' });
