const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminInvitation', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  invitedByAdministratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true },
  selector: { type: DataTypes.STRING(32), allowNull: false, unique: true },
  tokenHash: { type: DataTypes.STRING(64), allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  consumedAt: { type: DataTypes.DATE, allowNull: true },
  revokedAt: { type: DataTypes.DATE, allowNull: true },
  deliveryStatus: { type: DataTypes.ENUM('not_requested', 'pending', 'provider_accepted', 'failed'), allowNull: false, defaultValue: 'not_requested' },
  deliveryAttempts: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
  providerMessageId: { type: DataTypes.STRING(191), allowNull: true },
  deliveryErrorCode: { type: DataTypes.STRING(80), allowNull: true },
  deliveryAttemptedAt: { type: DataTypes.DATE, allowNull: true },
}, { tableName: 'AdminInvitations' });
