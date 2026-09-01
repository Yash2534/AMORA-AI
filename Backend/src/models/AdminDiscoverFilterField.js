const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('AdminDiscoverFilterField', {
  id: { type: DataTypes.STRING(80), primaryKey: true },
  key: { type: DataTypes.STRING(80), allowNull: false, unique: true },
  label: { type: DataTypes.STRING(120), allowNull: false },
  type: { type: DataTypes.STRING(40), allowNull: false },
  enabled: { type: DataTypes.BOOLEAN, allowNull: false },
  visible: { type: DataTypes.BOOLEAN, allowNull: false },
  required: { type: DataTypes.BOOLEAN, allowNull: false },
  displayOrder: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  maximumSelections: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
  minimumValue: { type: DataTypes.DECIMAL(10, 2), allowNull: true },
  maximumValue: { type: DataTypes.DECIMAL(10, 2), allowNull: true },
  sensitive: { type: DataTypes.BOOLEAN, allowNull: false },
  editable: { type: DataTypes.BOOLEAN, allowNull: false },
  version: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  updatedByAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  updatedAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'AdminDiscoverFilterFields', createdAt: false });
