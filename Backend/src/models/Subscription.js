const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('Subscription', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, userId: { type: DataTypes.INTEGER, allowNull: false }, planId: { type: DataTypes.STRING(64), allowNull: false },
  status: { type: DataTypes.ENUM('active', 'expired', 'cancelled', 'past_due', 'trialing'), allowNull: false }, provider: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'razorpay' },
  providerCustomerId: DataTypes.STRING(120), providerSubscriptionId: DataTypes.STRING(120), startedAt: { type: DataTypes.DATE, allowNull: false }, currentPeriodStart: { type: DataTypes.DATE, allowNull: false }, currentPeriodEnd: { type: DataTypes.DATE, allowNull: false },
  autoRenew: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false }, cancelAtPeriodEnd: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false }, cancelledAt: DataTypes.DATE, endedAt: DataTypes.DATE,
}, { tableName: 'Subscriptions' });
