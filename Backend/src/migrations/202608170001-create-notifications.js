async function tableExists(queryInterface, name) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === name.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (await tableExists(queryInterface, 'Notifications')) return;
    await queryInterface.createTable('Notifications', {
      id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      userId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'Users', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      type: { type: Sequelize.STRING(50), allowNull: false },
      category: { type: Sequelize.STRING(50), allowNull: false },
      title: { type: Sequelize.STRING(160), allowNull: false },
      message: { type: Sequelize.STRING(500), allowNull: false },
      isRead: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      readAt: { type: Sequelize.DATE, allowNull: true },
      data: { type: Sequelize.JSON, allowNull: false },
      deletedAt: { type: Sequelize.DATE, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false },
      updatedAt: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('Notifications', ['userId', 'createdAt', 'id'], {
      name: 'notifications_inbox_order',
    });
    await queryInterface.addIndex('Notifications', ['userId', 'isRead', 'deletedAt'], {
      name: 'notifications_unread_lookup',
    });
  },

  async down(queryInterface) {
    if (await tableExists(queryInterface, 'Notifications')) {
      await queryInterface.dropTable('Notifications');
    }
  },
};
