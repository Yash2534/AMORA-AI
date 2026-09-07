const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AccountDeletionConfirmation', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  tokenSelector: { type: DataTypes.STRING(32), allowNull: false, unique: true },
  tokenHash: { type: DataTypes.STRING(64), allowNull: false },
  purpose: { type: DataTypes.STRING(64), allowNull: false, defaultValue: 'account_deletion' },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  consumedAt: { type: DataTypes.DATE, allowNull: true },
}, {
  tableName: 'AccountDeletionConfirmations',
  indexes: [{ fields: ['userId', 'expiresAt'] }],
});
