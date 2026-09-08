const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('AccountDeletionFileTask', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  accountDeletionRequestId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  category: { type: DataTypes.ENUM('PROFILE_PHOTO'), allowNull: false },
  storageType: { type: DataTypes.ENUM('local_public'), allowNull: false },
  storageKey: { type: DataTypes.STRING(255), allowNull: false },
  status: { type: DataTypes.ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'), allowNull: false, defaultValue: 'PENDING' },
  attemptCount: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  lastAttemptAt: { type: DataTypes.DATE, allowNull: true }, completedAt: { type: DataTypes.DATE, allowNull: true }, failedAt: { type: DataTypes.DATE, allowNull: true },
  failureCode: { type: DataTypes.STRING(80), allowNull: true }, correlationId: { type: DataTypes.STRING(36), allowNull: false },
}, { tableName: 'AccountDeletionFileTasks', indexes: [{ unique: true, fields: ['accountDeletionRequestId', 'category', 'storageKey'] }, { fields: ['status', 'createdAt'] }] });
