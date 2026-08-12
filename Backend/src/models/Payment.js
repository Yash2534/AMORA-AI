const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('Payment', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, userId: { type: DataTypes.INTEGER, allowNull: false }, planId: DataTypes.STRING(64),
  productType: { type: DataTypes.ENUM('subscription'), allowNull: false }, productReferenceId: { type: DataTypes.STRING(64), allowNull: false }, provider: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'razorpay' },
  providerOrderId: DataTypes.STRING(120), providerPaymentId: DataTypes.STRING(120), amountMinor: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, currency: { type: DataTypes.STRING(3), allowNull: false },
  status: { type: DataTypes.ENUM('created', 'authorized', 'paid', 'failed', 'cancelled', 'refunded', 'chargeback'), allowNull: false, defaultValue: 'created' }, idempotencyKey: { type: DataTypes.STRING(100), allowNull: false },
  failureCode: DataTypes.STRING(100), failureMessage: DataTypes.STRING(500), verifiedAt: DataTypes.DATE, metadata: DataTypes.JSON,
}, { tableName: 'Payments' });
