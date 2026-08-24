const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminPermission', {
  id: { type: DataTypes.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
  key: { type: DataTypes.STRING(160), allowNull: false, unique: true },
  name: { type: DataTypes.STRING(200), allowNull: false },
  description: { type: DataTypes.STRING(500), allowNull: false },
  module: { type: DataTypes.STRING(80), allowNull: false },
}, { tableName: 'AdminPermissions', timestamps: false });
