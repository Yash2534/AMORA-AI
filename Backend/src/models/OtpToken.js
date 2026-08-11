const { DataTypes } = require('sequelize');
module.exports = (sequelize) => {
return sequelize.define('OtpToken', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  phoneNumber: { type: DataTypes.STRING, allowNull: true },
  email: { type: DataTypes.STRING, allowNull: true },
  codeHash: { type: DataTypes.STRING, allowNull: false },
  purpose: { type: DataTypes.ENUM('account_verification', 'password_reset'), allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  attempts: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
  consumed: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  recoveryUsedAt: { type: DataTypes.DATE, allowNull: true },
}, {
  tableName: 'OtpTokens',
  indexes: [{ fields: ['phoneNumber'] }, { fields: ['email'] }],
});
};
