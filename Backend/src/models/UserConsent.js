const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('UserConsent', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  purposeCode: {
    type: DataTypes.ENUM(
      'TERMS_AND_PRIVACY',
      'PROFILE_MATCHING',
      'LOCATION_DISCOVERY',
      'MARKETING_PROMOTIONS',
      'ANALYTICS_METRICS'
    ),
    allowNull: false
  },
  consentVersion: { type: DataTypes.STRING, allowNull: false, defaultValue: '1.0' },
  status: { type: DataTypes.ENUM('granted', 'withdrawn'), allowNull: false, defaultValue: 'granted' },
  grantedAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
  withdrawnAt: { type: DataTypes.DATE, allowNull: true },
  ipAddress: { type: DataTypes.STRING, allowNull: true },
  userAgent: { type: DataTypes.STRING, allowNull: true }
}, {
  tableName: 'UserConsents',
  timestamps: true,
  indexes: [
    { fields: ['userId', 'purposeCode'] }
  ]
});
