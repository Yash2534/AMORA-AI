const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('NotificationDelivery', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  notificationId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  userDeviceId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  channel: { type: DataTypes.ENUM('push'), allowNull: false, defaultValue: 'push' },
  status: { type: DataTypes.ENUM('pending', 'sent', 'failed', 'credentials_required'), allowNull: false, defaultValue: 'pending' },
  providerMessageId: { type: DataTypes.STRING(255), allowNull: true },
  attemptCount: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  lastAttemptAt: { type: DataTypes.DATE, allowNull: true },
  errorCode: { type: DataTypes.STRING(100), allowNull: true },
}, { tableName: 'NotificationDeliveries' });
