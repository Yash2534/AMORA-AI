const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('PaymentEvent', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, paymentId: DataTypes.BIGINT.UNSIGNED, provider: { type: DataTypes.STRING(32), allowNull: false }, providerEventId: { type: DataTypes.STRING(160), allowNull: false },
  eventType: { type: DataTypes.STRING(120), allowNull: false }, payloadHash: { type: DataTypes.STRING(64), allowNull: false }, payload: { type: DataTypes.JSON, allowNull: false },
  status: { type: DataTypes.ENUM('received', 'processed', 'ignored', 'failed'), allowNull: false, defaultValue: 'received' }, processedAt: DataTypes.DATE, errorMessage: DataTypes.STRING(500),
}, { tableName: 'PaymentEvents' });
