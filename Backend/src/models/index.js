const defineUser = require('./User'); const defineOtpToken = require('./OtpToken'); const defineRefreshToken = require('./RefreshToken');
let models = {};
function initModels(sequelize) {
  if (models.User) return models;
  const User = defineUser(sequelize); const OtpToken = defineOtpToken(sequelize); const RefreshToken = defineRefreshToken(sequelize);
  User.hasMany(RefreshToken, { foreignKey: 'userId', onDelete: 'CASCADE' }); RefreshToken.belongsTo(User, { foreignKey: 'userId' });
  models = { User, OtpToken, RefreshToken }; return models;
}
function getModels() { if (!models.User) throw new Error('Models are not initialized.'); return models; }
module.exports = { initModels, getModels };
