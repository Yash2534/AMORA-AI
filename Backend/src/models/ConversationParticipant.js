const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('ConversationParticipant', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  conversationId: { type: DataTypes.INTEGER, allowNull: false },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  lastReadMessageId: { type: DataTypes.INTEGER, allowNull: true },
  lastReadAt: { type: DataTypes.DATE, allowNull: true },
  draftText: { type: DataTypes.TEXT, allowNull: true },
  mutedAt: { type: DataTypes.DATE, allowNull: true },
  mutedUntil: { type: DataTypes.DATE, allowNull: true },
  joinedAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
}, {
  tableName: 'ConversationParticipants',
  indexes: [
    { unique: true, fields: ['conversationId', 'userId'] },
    { fields: ['userId', 'conversationId'] },
  ],
});
