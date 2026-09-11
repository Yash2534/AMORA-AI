const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('PrivacyGrievance', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  ticketNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
  userId: { type: DataTypes.INTEGER, allowNull: true },
  name: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, allowNull: false, validate: { isEmail: true } },
  phoneNumber: { type: DataTypes.STRING, allowNull: true },
  category: {
    type: DataTypes.ENUM(
      'DATA_ACCESS',
      'DATA_CORRECTION',
      'CONSENT_WITHDRAWAL',
      'DATA_ERASURE',
      'UNAUTHORIZED_PROCESSING',
      'GENERAL_PRIVACY'
    ),
    allowNull: false
  },
  subject: { type: DataTypes.STRING, allowNull: false },
  description: { type: DataTypes.TEXT, allowNull: false },
  status: {
    type: DataTypes.ENUM('open', 'under_review', 'resolved', 'rejected'),
    allowNull: false,
    defaultValue: 'open'
  },
  assignedAdministratorId: { type: DataTypes.INTEGER, allowNull: true },
  resolutionNotes: { type: DataTypes.TEXT, allowNull: true },
  resolvedAt: { type: DataTypes.DATE, allowNull: true }
}, {
  tableName: 'PrivacyGrievances',
  timestamps: true,
  indexes: [
    { fields: ['ticketNumber'] },
    { fields: ['userId'] },
    { fields: ['status'] }
  ]
});
