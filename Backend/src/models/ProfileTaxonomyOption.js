const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('ProfileTaxonomyOption', {
  id: { type: DataTypes.STRING(80), primaryKey: true },
  categoryKey: { type: DataTypes.STRING(40), allowNull: false },
  label: { type: DataTypes.STRING(255), allowNull: false },
  normalizedLabel: { type: DataTypes.STRING(255), allowNull: false },
  allowsCustomValue: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  isActive: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  sortOrder: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
}, { tableName: 'ProfileTaxonomyOptions', createdAt: false, updatedAt: false });
