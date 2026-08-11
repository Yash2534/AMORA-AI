const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Notification', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  type: { type: DataTypes.STRING(50), allowNull: false },
  category: { type: DataTypes.STRING(50), allowNull: false },
  title: { type: DataTypes.STRING(160), allowNull: false },
  message: { type: DataTypes.STRING(500), allowNull: false },
  isRead: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  readAt: { type: DataTypes.DATE, allowNull: true },
  data: { type: DataTypes.JSON, allowNull: false, defaultValue: {} },
  deletedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'Notifications' });
