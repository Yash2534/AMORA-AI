const defineUser = require('./User'); const defineOtpToken = require('./OtpToken'); const defineRefreshToken = require('./RefreshToken'); const defineOnboardingProfile = require('./OnboardingProfile');
let models = {};
function initModels(sequelize) {
  if (models.User) return models;
  const User = defineUser(sequelize); const OtpToken = defineOtpToken(sequelize); const RefreshToken = defineRefreshToken(sequelize); const OnboardingProfile = defineOnboardingProfile(sequelize);
  User.hasMany(RefreshToken, { foreignKey: 'userId', onDelete: 'CASCADE' }); RefreshToken.belongsTo(User, { foreignKey: 'userId' }); User.hasOne(OnboardingProfile, { foreignKey: 'userId', onDelete: 'CASCADE' }); OnboardingProfile.belongsTo(User, { foreignKey: 'userId' });
  models = { User, OtpToken, RefreshToken, OnboardingProfile }; return models;
}
function getModels() { if (!models.User) throw new Error('Models are not initialized.'); return models; }
module.exports = { initModels, getModels };
