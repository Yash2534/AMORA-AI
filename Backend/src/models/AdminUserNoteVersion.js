const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminUserNoteVersion', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  noteId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  version: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  action: { type: DataTypes.ENUM('created', 'updated', 'deleted'), allowNull: false },
  text: { type: DataTypes.TEXT, allowNull: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
}, { tableName: 'AdminUserNoteVersions', updatedAt: false });
