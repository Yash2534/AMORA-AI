const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('AdminIdempotencyKey', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  administratorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  scope: { type: DataTypes.STRING(120), allowNull: false },
  idempotencyKey: { type: DataTypes.STRING(160), allowNull: false },
  requestHash: { type: DataTypes.STRING(64), allowNull: false },
  responseStatus: { type: DataTypes.SMALLINT.UNSIGNED, allowNull: false },
  responseBody: { type: DataTypes.JSON, allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'AdminIdempotencyKeys', updatedAt: false });
