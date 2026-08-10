const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('EventCheckIn', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  eventId: { type: DataTypes.INTEGER, allowNull: false },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  checkedInAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'EventCheckIns', updatedAt: false });
