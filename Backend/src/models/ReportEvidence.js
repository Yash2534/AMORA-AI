const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('ReportEvidence', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  reportId: { type: DataTypes.INTEGER, allowNull: false },
  originalName: { type: DataTypes.STRING, allowNull: false },
  storagePath: { type: DataTypes.STRING, allowNull: false },
  mimeType: { type: DataTypes.STRING, allowNull: false },
  sizeBytes: { type: DataTypes.INTEGER, allowNull: false },
}, { tableName: 'ReportEvidence', updatedAt: false });
