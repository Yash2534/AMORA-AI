const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('UserDevice', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  pushToken: { type: DataTypes.STRING(512), allowNull: false, unique: true },
  platform: { type: DataTypes.ENUM('android', 'ios', 'web'), allowNull: false },
  installationId: { type: DataTypes.STRING(160), allowNull: true },
  active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  lastSeenAt: { type: DataTypes.DATE, allowNull: false },
  invalidatedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'UserDevices' });
