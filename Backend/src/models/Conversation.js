const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Conversation', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  pairKey: { type: DataTypes.STRING(64), allowNull: false, unique: true },
  type: { type: DataTypes.ENUM('direct'), allowNull: false, defaultValue: 'direct' },
  lastMessageId: { type: DataTypes.INTEGER, allowNull: true },
  lastMessageAt: { type: DataTypes.DATE, allowNull: true },
}, {
  tableName: 'Conversations',
  indexes: [
    { unique: true, fields: ['pairKey'] },
    { fields: ['lastMessageAt', 'id'] },
  ],
});
