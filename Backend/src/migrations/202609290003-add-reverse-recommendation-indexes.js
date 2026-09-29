module.exports = {
  async up(queryInterface) {
    await queryInterface.addIndex('Matches', ['userTwoId', 'userOneId'], {
      name: 'matches_user_two_user_one',
    });
    await queryInterface.addIndex('Blocks', ['blockedUserId', 'blockerUserId'], {
      name: 'blocks_blocked_blocker',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('Blocks', 'blocks_blocked_blocker');
    await queryInterface.removeIndex('Matches', 'matches_user_two_user_one');
  },
};
