async function columnExists(queryInterface, table, column) {
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'ConversationParticipants', 'hiddenAt'))) {
      await queryInterface.addColumn('ConversationParticipants', 'hiddenAt', { type: Sequelize.DATE, allowNull: true });
    }
    await queryInterface.addIndex('ConversationParticipants', ['userId', 'hiddenAt'], { name: 'conversation_participants_hidden_lookup' });
  },
  async down(queryInterface) {
    await queryInterface.removeIndex('ConversationParticipants', 'conversation_participants_hidden_lookup').catch(() => {});
    if (await columnExists(queryInterface, 'ConversationParticipants', 'hiddenAt')) await queryInterface.removeColumn('ConversationParticipants', 'hiddenAt');
  },
};
