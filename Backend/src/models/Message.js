const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Message', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  conversationId: { type: DataTypes.INTEGER, allowNull: false },
  senderId: { type: DataTypes.INTEGER, allowNull: false },
  type: { type: DataTypes.ENUM('text', 'image'), allowNull: false, defaultValue: 'text' },
  text: { type: DataTypes.TEXT, allowNull: true },
  context: { type: DataTypes.JSON, allowNull: true },
  status: { type: DataTypes.ENUM('sent', 'delivered', 'read'), allowNull: false, defaultValue: 'sent' },
  deliveredAt: { type: DataTypes.DATE, allowNull: true },
  readAt: { type: DataTypes.DATE, allowNull: true },
  deletedAt: { type: DataTypes.DATE, allowNull: true },
}, {
  tableName: 'Messages',
  indexes: [
    { fields: ['conversationId', 'id'] },
    { fields: ['conversationId', 'senderId', 'id'] },
  ],
});
