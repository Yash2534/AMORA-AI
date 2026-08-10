const { DataTypes } = require('sequelize');
const { REPORT_REASONS, REPORT_STATUSES, REPORT_TARGET_TYPES } = require('../constants/reportOptions');

module.exports = (sequelize) => sequelize.define('Report', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  reporterUserId: { type: DataTypes.INTEGER, allowNull: false },
  reportedUserId: { type: DataTypes.INTEGER, allowNull: true },
  targetType: { type: DataTypes.ENUM(...REPORT_TARGET_TYPES), allowNull: false, defaultValue: 'profile' },
  targetId: { type: DataTypes.STRING, allowNull: false },
  reason: { type: DataTypes.ENUM(...REPORT_REASONS), allowNull: false },
  notes: { type: DataTypes.TEXT, allowNull: true },
  status: { type: DataTypes.ENUM(...REPORT_STATUSES), allowNull: false, defaultValue: 'open' },
}, { tableName: 'Reports' });
