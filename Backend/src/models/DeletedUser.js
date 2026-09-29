const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('DeletedUser', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  originalUserId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
  deletionMechanism: {
    type: DataTypes.ENUM('USER_INITIATED_OTP'),
    allowNull: false,
  },
  deletionReasonCode: { type: DataTypes.STRING(40), allowNull: true },
  deletionReasonText: { type: DataTypes.STRING(500), allowNull: true },
  accountCreatedAt: { type: DataTypes.DATE, allowNull: false },
  deletedAt: { type: DataTypes.DATE, allowNull: false },
}, {
  tableName: 'DeletedUsers',
  updatedAt: false,
  indexes: [{ fields: ['deletedAt'] }],
});
