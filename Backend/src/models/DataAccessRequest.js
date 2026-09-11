const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('DataAccessRequest', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  requestNumber: { type: DataTypes.STRING, allowNull: false, unique: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  status: {
    type: DataTypes.ENUM('pending', 'completed', 'failed'),
    allowNull: false,
    defaultValue: 'pending'
  },
  exportData: { type: DataTypes.TEXT('long'), allowNull: true },
  requestedAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
  completedAt: { type: DataTypes.DATE, allowNull: true }
}, {
  tableName: 'DataAccessRequests',
  timestamps: true,
  indexes: [
    { fields: ['requestNumber'] },
    { fields: ['userId'] }
  ]
});
