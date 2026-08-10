const { DataTypes } = require('sequelize');
module.exports = (sequelize) => {
const model = sequelize.define('OtpToken', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  phoneNumber: { type: DataTypes.STRING, allowNull: false },
  codeHash: { type: DataTypes.STRING, allowNull: false },
  purpose: { type: DataTypes.ENUM('account_verification', 'password_reset'), allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  attempts: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
  consumed: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false }
}, { tableName: 'OtpTokens', indexes: [{ fields: ['phoneNumber'] }] });
model.addHook('beforeSync', async () => { const columns = await sequelize.getQueryInterface().describeTable('OtpTokens').catch(() => null); if (columns && columns.email && !columns.phoneNumber) await sequelize.getQueryInterface().renameColumn('OtpTokens', 'email', 'phoneNumber'); });
return model;
};
