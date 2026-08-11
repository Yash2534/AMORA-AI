const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('SavedProfile', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  savedUserId: { type: DataTypes.INTEGER, allowNull: false },
}, {
  tableName: 'SavedProfiles',
  indexes: [{ unique: true, fields: ['userId', 'savedUserId'] }],
});
