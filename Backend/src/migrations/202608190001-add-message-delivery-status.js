async function columnNames(queryInterface, tableName) {
  return new Set(Object.keys(await queryInterface.describeTable(tableName)));
}

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await columnNames(queryInterface, 'Messages');
    if (!columns.has('status')) {
      await queryInterface.addColumn('Messages', 'status', {
        type: Sequelize.ENUM('sent', 'delivered', 'read'),
        allowNull: false,
        defaultValue: 'sent',
        after: 'context',
      });
    }
    if (!columns.has('deliveredAt')) {
      await queryInterface.addColumn('Messages', 'deliveredAt', {
        type: Sequelize.DATE,
        allowNull: true,
        after: 'status',
      });
    }
    if (!columns.has('readAt')) {
      await queryInterface.addColumn('Messages', 'readAt', {
        type: Sequelize.DATE,
        allowNull: true,
        after: 'deliveredAt',
      });
    }
    await queryInterface.sequelize.query(`
      UPDATE Messages m
      JOIN ConversationParticipants cp
        ON cp.conversationId = m.conversationId
       AND cp.userId <> m.senderId
       AND cp.lastReadMessageId IS NOT NULL
       AND m.id <= cp.lastReadMessageId
      SET m.status = 'read',
          m.deliveredAt = COALESCE(m.deliveredAt, cp.lastReadAt, m.createdAt),
          m.readAt = COALESCE(m.readAt, cp.lastReadAt, m.createdAt)
      WHERE m.status <> 'read'
    `);
  },

  async down(queryInterface) {
    const columns = await columnNames(queryInterface, 'Messages');
    if (columns.has('readAt')) await queryInterface.removeColumn('Messages', 'readAt');
    if (columns.has('deliveredAt')) await queryInterface.removeColumn('Messages', 'deliveredAt');
    if (columns.has('status')) await queryInterface.removeColumn('Messages', 'status');
  },
};
