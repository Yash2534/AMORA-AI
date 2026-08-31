const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('UserTimelineEvent', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  eventType: { type: DataTypes.STRING(80), allowNull: false },
  title: { type: DataTypes.STRING(160), allowNull: false },
  description: { type: DataTypes.STRING(500), allowNull: true },
  status: { type: DataTypes.STRING(80), allowNull: true },
  relatedReference: { type: DataTypes.STRING(191), allowNull: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  occurredAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'UserTimelineEvents', createdAt: false, updatedAt: false });
