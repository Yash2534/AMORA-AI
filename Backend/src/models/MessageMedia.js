const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('MessageMedia', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  messageId: { type: DataTypes.INTEGER, allowNull: false },
  mediaType: { type: DataTypes.ENUM('image'), allowNull: false, defaultValue: 'image' },
  originalName: { type: DataTypes.STRING, allowNull: false },
  storagePath: { type: DataTypes.STRING, allowNull: false },
  mimeType: { type: DataTypes.STRING(100), allowNull: false },
  sizeBytes: { type: DataTypes.INTEGER, allowNull: false },
}, {
  tableName: 'MessageMedia',
  updatedAt: false,
  indexes: [{ fields: ['messageId', 'id'] }],
});
