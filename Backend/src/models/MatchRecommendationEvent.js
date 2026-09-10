const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('MatchRecommendationEvent', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  viewerUserId: { type: DataTypes.INTEGER, allowNull: false }, candidateUserId: { type: DataTypes.INTEGER, allowNull: true },
  eventType: { type: DataTypes.ENUM('impression', 'no_result'), allowNull: false }, rankingVersion: { type: DataTypes.STRING(32), allowNull: false },
  requestId: { type: DataTypes.STRING(36), allowNull: false }, page: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false }, position: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
  score: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true }, coverage: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true },
  experimentId: { type: DataTypes.STRING(80), allowNull: true }, variant: { type: DataTypes.STRING(40), allowNull: true }, noResultReason: { type: DataTypes.STRING(40), allowNull: true },
}, { tableName: 'MatchRecommendationEvents', indexes: [{ unique: true, fields: ['requestId', 'candidateUserId'] }, { fields: ['rankingVersion', 'eventType', 'createdAt'] }] });
