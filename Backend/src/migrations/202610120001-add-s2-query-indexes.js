async function indexNames(queryInterface, tableName) {
  return new Set((await queryInterface.showIndex(tableName)).map((index) => index.name));
}

async function addIndex(queryInterface, tableName, fields, name, options = {}) {
  if ((await indexNames(queryInterface, tableName)).has(name)) return;
  await queryInterface.addIndex(tableName, fields, { ...options, name });
}

async function removeIndex(queryInterface, tableName, name) {
  if (!(await indexNames(queryInterface, tableName)).has(name)) return;
  await queryInterface.removeIndex(tableName, name);
}

module.exports = {
  async up(queryInterface) {
    await addIndex(queryInterface, 'OnboardingProfiles', ['matchLatitude', 'matchLongitude', 'userId'], 'onboarding_profiles_match_location');
    await addIndex(queryInterface, 'Users', ['createdAt', 'id'], 'users_created_at_id');
    await addIndex(queryInterface, 'Matches', ['matchedAt', 'id'], 'matches_matched_at_id');
    await addIndex(queryInterface, 'Subscriptions', ['createdAt', 'id'], 'subscriptions_created_at_id');
    await addIndex(queryInterface, 'Reports', ['status', 'createdAt', 'id'], 'reports_status_created_id');
    await addIndex(queryInterface, 'PrivacyRequests', ['userId', 'requestedAt', 'id'], 'privacy_requests_user_requested_id');

    // This exact reverse-pair index was created twice by earlier migrations.
    await removeIndex(queryInterface, 'Blocks', 'blocks_blocked_blocker');
    await removeIndex(queryInterface, 'PrivacyRequests', 'privacy_requests_user_requested');
  },

  async down(queryInterface) {
    await addIndex(queryInterface, 'PrivacyRequests', ['userId', 'requestedAt'], 'privacy_requests_user_requested');
    await addIndex(queryInterface, 'Blocks', ['blockedUserId', 'blockerUserId'], 'blocks_blocked_blocker');
    await removeIndex(queryInterface, 'PrivacyRequests', 'privacy_requests_user_requested_id');
    await removeIndex(queryInterface, 'Reports', 'reports_status_created_id');
    await removeIndex(queryInterface, 'Subscriptions', 'subscriptions_created_at_id');
    await removeIndex(queryInterface, 'Matches', 'matches_matched_at_id');
    await removeIndex(queryInterface, 'Users', 'users_created_at_id');
    await removeIndex(queryInterface, 'OnboardingProfiles', 'onboarding_profiles_match_location');
  },
};
