const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('PrivacyCorrectionDetail', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true }, privacyRequestId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, unique: true }, category: { type: DataTypes.ENUM('DATE_OF_BIRTH'), allowNull: false }, requestedBirthDate: { type: DataTypes.DATEONLY, allowNull: false }, submittedAt: { type: DataTypes.DATE, allowNull: false },
}, { tableName: 'PrivacyCorrectionDetails' });
