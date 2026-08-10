const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('EventGroupMessage', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  eventId: { type: DataTypes.INTEGER, allowNull: false },
  senderId: { type: DataTypes.INTEGER, allowNull: false },
  type: { type: DataTypes.ENUM('text'), allowNull: false, defaultValue: 'text' },
  text: { type: DataTypes.TEXT, allowNull: false },
}, { tableName: 'EventGroupMessages' });
