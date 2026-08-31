const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminUserNote', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  authorAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  text: { type: DataTypes.TEXT, allowNull: false },
  category: { type: DataTypes.STRING(40), allowNull: false, defaultValue: 'general' },
  version: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
  deletedAt: { type: DataTypes.DATE, allowNull: true },
  deletedByAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
}, { tableName: 'AdminUserNotes', paranoid: false });
