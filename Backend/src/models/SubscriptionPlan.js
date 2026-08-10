const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('SubscriptionPlan', {
  id: { type: DataTypes.STRING(64), primaryKey: true },
  name: { type: DataTypes.STRING(120), allowNull: false }, displayName: { type: DataTypes.STRING(160), allowNull: false }, description: DataTypes.STRING(500),
  priceMinor: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, currency: { type: DataTypes.STRING(3), allowNull: false, defaultValue: 'INR' },
  billingPeriod: { type: DataTypes.ENUM('day', 'week', 'month', 'year'), allowNull: false, defaultValue: 'month' }, billingInterval: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
  features: { type: DataTypes.JSON, allowNull: false }, entitlements: { type: DataTypes.JSON, allowNull: false }, trialDays: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  offerText: DataTypes.STRING(255), active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true }, sortOrder: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
}, { tableName: 'SubscriptionPlans' });
