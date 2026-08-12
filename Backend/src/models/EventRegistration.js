const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('EventRegistration', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  eventId: { type: DataTypes.INTEGER, allowNull: false },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  status: { type: DataTypes.ENUM('registered', 'cancelled'), allowNull: false, defaultValue: 'registered' },
  registeredAt: { type: DataTypes.DATE, allowNull: false },
  cancelledAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'EventRegistrations' });
