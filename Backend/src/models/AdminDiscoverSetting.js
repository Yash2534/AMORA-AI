const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('AdminDiscoverSetting', {
  key: { type: DataTypes.STRING(80), primaryKey: true },
  value: { type: DataTypes.JSON, allowNull: false },
  version: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
  updatedByAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  updatedAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'AdminDiscoverSettings', createdAt: false });
