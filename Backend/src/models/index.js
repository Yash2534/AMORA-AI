const defineUser = require('./User'); const defineOtpToken = require('./OtpToken'); const defineRefreshToken = require('./RefreshToken'); const defineOnboardingProfile = require('./OnboardingProfile'); const defineDiscoverAction = require('./DiscoverAction'); const defineMatch = require('./Match'); const defineBoost = require('./Boost'); const defineDiscoverFilterPreference = require('./DiscoverFilterPreference');
let models = {};
function initModels(sequelize) {
  if (models.User) return models;
  const User = defineUser(sequelize); const OtpToken = defineOtpToken(sequelize); const RefreshToken = defineRefreshToken(sequelize); const OnboardingProfile = defineOnboardingProfile(sequelize); const DiscoverAction = defineDiscoverAction(sequelize); const Match = defineMatch(sequelize); const Boost = defineBoost(sequelize); const DiscoverFilterPreference = defineDiscoverFilterPreference(sequelize);
  User.hasMany(RefreshToken, { foreignKey: 'userId', onDelete: 'CASCADE' }); RefreshToken.belongsTo(User, { foreignKey: 'userId' }); User.hasOne(OnboardingProfile, { foreignKey: 'userId', onDelete: 'CASCADE' }); OnboardingProfile.belongsTo(User, { foreignKey: 'userId' });
  User.hasMany(DiscoverAction, { foreignKey: 'actorUserId', onDelete: 'CASCADE', as: 'discoverActions' }); DiscoverAction.belongsTo(User, { foreignKey: 'actorUserId', as: 'actor' }); DiscoverAction.belongsTo(User, { foreignKey: 'targetUserId', as: 'target' });
  User.hasMany(Match, { foreignKey: 'userOneId', onDelete: 'CASCADE', as: 'firstMatches' }); User.hasMany(Match, { foreignKey: 'userTwoId', onDelete: 'CASCADE', as: 'secondMatches' }); Match.belongsTo(User, { foreignKey: 'userOneId', as: 'userOne' }); Match.belongsTo(User, { foreignKey: 'userTwoId', as: 'userTwo' });
  User.hasMany(Boost, { foreignKey: 'userId', onDelete: 'CASCADE', as: 'boosts' }); Boost.belongsTo(User, { foreignKey: 'userId' });
  User.hasOne(DiscoverFilterPreference, { foreignKey: 'userId', onDelete: 'CASCADE' }); DiscoverFilterPreference.belongsTo(User, { foreignKey: 'userId' });
  models = { User, OtpToken, RefreshToken, OnboardingProfile, DiscoverAction, Match, Boost, DiscoverFilterPreference }; return models;
}
function getModels() { if (!models.User) throw new Error('Models are not initialized.'); return models; }
module.exports = { initModels, getModels };
