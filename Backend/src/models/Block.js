const { DataTypes } = require('sequelize');

module.exports = (sequelize) => sequelize.define('Block', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  blockerUserId: { type: DataTypes.INTEGER, allowNull: false },
  blockedUserId: { type: DataTypes.INTEGER, allowNull: false },
}, {
  tableName: 'Blocks',
  indexes: [{ unique: true, fields: ['blockerUserId', 'blockedUserId'] }],
});
