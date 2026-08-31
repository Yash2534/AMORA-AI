const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('ProfileTaxonomyCategory', {
  key: { type: DataTypes.STRING(40), primaryKey: true },
  label: { type: DataTypes.STRING(120), allowNull: false },
  maximumSelections: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
}, { tableName: 'ProfileTaxonomyCategories', createdAt: false, updatedAt: false });
