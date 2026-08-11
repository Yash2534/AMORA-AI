async function columnExists(queryInterface, table, column) {
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'ConversationParticipants', 'mutedAt'))) {
      await queryInterface.addColumn('ConversationParticipants', 'mutedAt', { type: Sequelize.DATE, allowNull: true });
    }
    if (!(await columnExists(queryInterface, 'ConversationParticipants', 'mutedUntil'))) {
      await queryInterface.addColumn('ConversationParticipants', 'mutedUntil', { type: Sequelize.DATE, allowNull: true });
    }
    await queryInterface.addIndex('ConversationParticipants', ['userId', 'mutedAt', 'mutedUntil'], { name: 'conversation_participants_mute_lookup' });
  },

  async down(queryInterface) {
    if (await columnExists(queryInterface, 'ConversationParticipants', 'mutedUntil')) await queryInterface.removeColumn('ConversationParticipants', 'mutedUntil');
    if (await columnExists(queryInterface, 'ConversationParticipants', 'mutedAt')) await queryInterface.removeColumn('ConversationParticipants', 'mutedAt');
  },
};
