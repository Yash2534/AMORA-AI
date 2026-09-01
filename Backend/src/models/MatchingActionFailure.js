const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('MatchingActionFailure', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  actionType: { type: DataTypes.ENUM('like', 'super_like', 'rose'), allowNull: false },
  actorUserId: { type: DataTypes.INTEGER, allowNull: true },
  targetUserId: { type: DataTypes.INTEGER, allowNull: true },
  requestedTargetReference: { type: DataTypes.STRING(80), allowNull: true },
  safeCode: { type: DataTypes.STRING(80), allowNull: false },
  safeCategory: { type: DataTypes.ENUM('business_rejection', 'system_failure'), allowNull: false },
  safeStage: { type: DataTypes.STRING(80), allowNull: false },
  retryable: { type: DataTypes.BOOLEAN, allowNull: false },
  resolutionStatus: { type: DataTypes.ENUM('not_applicable', 'unresolved', 'resolved'), allowNull: false },
  createdAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'MatchingActionFailures', updatedAt: false });
