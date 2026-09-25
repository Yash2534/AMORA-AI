const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('DeletedUser', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  originalUserId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
  deletionMechanism: {
    type: DataTypes.ENUM('USER_INITIATED_OTP'),
    allowNull: false,
  },
  accountCreatedAt: { type: DataTypes.DATE, allowNull: false },
  deletedAt: { type: DataTypes.DATE, allowNull: false },
}, {
  tableName: 'DeletedUsers',
  updatedAt: false,
  indexes: [{ fields: ['deletedAt'] }],
});
