async function indexNames(queryInterface, tableName) {
  const indexes = await queryInterface.showIndex(tableName);
  return new Set(indexes.map((index) => index.name));
}

async function addIndex(queryInterface, tableName, fields, name) {
  if ((await indexNames(queryInterface, tableName)).has(name)) return;
  await queryInterface.addIndex(tableName, fields, { name });
}

async function removeIndex(queryInterface, tableName, name) {
  if (!(await indexNames(queryInterface, tableName)).has(name)) return;
  await queryInterface.removeIndex(tableName, name);
}

module.exports = {
  async up(queryInterface, Sequelize) {
    await addIndex(
      queryInterface,
      'OnboardingProfiles',
      ['onboardingCompleted', 'birthDate', 'communicationStyle', 'userId'],
      'onboarding_profiles_discover_eligibility',
    );
    await addIndex(
      queryInterface,
      'Boosts',
      ['userId', 'active', 'expiresAt'],
      'boosts_active_user_expiry',
    );
    await addIndex(
      queryInterface,
      'OtpTokens',
      ['phoneNumber', 'purpose', 'consumed', 'createdAt'],
      'otp_tokens_resend_policy',
    );
    await queryInterface.changeColumn('DiscoverFilterPreferences', 'minScore', {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 0,
    });
  },

  async down(queryInterface, Sequelize) {
    await removeIndex(queryInterface, 'OtpTokens', 'otp_tokens_resend_policy');
    // MariaDB may discard the original single-column FK index as redundant
    // after the composite index is added. Restore FK coverage before removal.
    await addIndex(queryInterface, 'Boosts', ['userId'], 'boosts_user_id_fk');
    await removeIndex(queryInterface, 'Boosts', 'boosts_active_user_expiry');
    await removeIndex(queryInterface, 'OnboardingProfiles', 'onboarding_profiles_discover_eligibility');
    await queryInterface.changeColumn('DiscoverFilterPreferences', 'minScore', {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 80,
    });
  },
};
