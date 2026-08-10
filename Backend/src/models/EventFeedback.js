const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('EventFeedback', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  eventId: { type: DataTypes.INTEGER, allowNull: false },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  rating: { type: DataTypes.TINYINT.UNSIGNED, allowNull: false },
  venueRating: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true },
  hostRating: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true },
  safetyRating: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true },
  experienceRating: { type: DataTypes.TINYINT.UNSIGNED, allowNull: true },
  feedbackText: { type: DataTypes.TEXT, allowNull: true },
  recommend: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  mediaOriginalName: { type: DataTypes.STRING, allowNull: true },
  mediaStoragePath: { type: DataTypes.STRING, allowNull: true },
  mediaMimeType: { type: DataTypes.STRING, allowNull: true },
  mediaSizeBytes: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
}, { tableName: 'EventFeedback' });
