const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('NotificationPreference', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
  newMatches: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  messages: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  eventReminders: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  paymentsAndMembership: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  offers: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  safetyUpdates: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  pushEnabled: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  emailEnabled: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  smsEnabled: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  quietHoursEnabled: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  quietStart: { type: DataTypes.STRING(5), allowNull: false, defaultValue: '22:00' },
  quietEnd: { type: DataTypes.STRING(5), allowNull: false, defaultValue: '07:00' },
}, { tableName: 'NotificationPreferences' });
