const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('EventWaitlist', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  eventId: { type: DataTypes.INTEGER, allowNull: false },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  status: { type: DataTypes.ENUM('waiting', 'promoted', 'left'), allowNull: false, defaultValue: 'waiting' },
  joinedAt: { type: DataTypes.DATE, allowNull: false },
  endedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'EventWaitlist' });
