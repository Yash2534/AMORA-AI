const { DataTypes } = require('sequelize');
module.exports = (sequelize) => sequelize.define('User', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  name: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, allowNull: false, unique: true, validate: { isEmail: true } },
  phoneNumber: { type: DataTypes.STRING, allowNull: false, defaultValue: '' },
  passwordHash: { type: DataTypes.STRING, allowNull: true },
  authProvider: { type: DataTypes.ENUM('local', 'google'), allowNull: false, defaultValue: 'local' },
  googleId: { type: DataTypes.STRING, allowNull: true, unique: true },
  isVerified: { type: DataTypes.BOOLEAN, defaultValue: false },
  termsAcceptedAt: { type: DataTypes.DATE, allowNull: true },
  accountStatus: { type: DataTypes.ENUM('active', 'deactivated', 'deleted'), allowNull: false, defaultValue: 'active' },
  deactivatedAt: { type: DataTypes.DATE, allowNull: true },
  deletedAt: { type: DataTypes.DATE, allowNull: true },
  tokenVersion: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
  deletionReason: { type: DataTypes.STRING, allowNull: true },
  deletionDetails: { type: DataTypes.TEXT, allowNull: true },
  role: { type: DataTypes.ENUM('user', 'host', 'admin'), allowNull: false, defaultValue: 'user' }
}, { tableName: 'Users' });
