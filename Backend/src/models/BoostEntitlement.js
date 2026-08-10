const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('BoostEntitlement', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, userId: { type: DataTypes.INTEGER, allowNull: false }, productId: DataTypes.STRING(64), paymentId: DataTypes.BIGINT.UNSIGNED, walletTransactionId: DataTypes.BIGINT.UNSIGNED,
  source: { type: DataTypes.ENUM('subscription', 'payment', 'wallet', 'redemption', 'admin'), allowNull: false }, quantity: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, remainingQuantity: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  durationMinutes: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, status: { type: DataTypes.ENUM('active', 'consumed', 'expired', 'revoked'), allowNull: false, defaultValue: 'active' }, expiresAt: DataTypes.DATE, idempotencyKey: { type: DataTypes.STRING(100), allowNull: false },
}, { tableName: 'BoostEntitlements' });
