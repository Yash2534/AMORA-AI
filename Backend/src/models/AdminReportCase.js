const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('AdminReportCase', {
  reportId: { type: DataTypes.INTEGER, primaryKey: true }, status: { type: DataTypes.ENUM('open', 'under_review', 'action_required', 'resolved', 'dismissed'), allowNull: false, defaultValue: 'open' }, severity: { type: DataTypes.ENUM('low', 'medium', 'high', 'critical'), allowNull: false, defaultValue: 'medium' }, assignedAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true }, resolution: { type: DataTypes.TEXT, allowNull: true }, resolvedAt: { type: DataTypes.DATE, allowNull: true }, resolvedByAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
}, { tableName: 'AdminReportCases' });
