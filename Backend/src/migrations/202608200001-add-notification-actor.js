async function tableExists(queryInterface, name) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === name.toLowerCase());
}

async function columnExists(queryInterface, table, column) {
  if (!(await tableExists(queryInterface, table))) return false;
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

async function indexExists(queryInterface, table, indexName) {
  if (!(await tableExists(queryInterface, table))) return false;
  const indexes = await queryInterface.showIndex(table);
  return indexes.some((index) => index.name === indexName);
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'Notifications', 'actorUserId'))) {
      await queryInterface.addColumn('Notifications', 'actorUserId', {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: { model: 'Users', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
        after: 'userId',
      });
    }
    if (!(await indexExists(queryInterface, 'Notifications', 'notifications_actor_user_id'))) {
      await queryInterface.addIndex('Notifications', ['actorUserId'], { name: 'notifications_actor_user_id' });
    }
  },

  async down(queryInterface) {
    if (await indexExists(queryInterface, 'Notifications', 'notifications_actor_user_id')) {
      await queryInterface.removeIndex('Notifications', 'notifications_actor_user_id');
    }
    if (await columnExists(queryInterface, 'Notifications', 'actorUserId')) {
      await queryInterface.removeColumn('Notifications', 'actorUserId');
    }
  },
};
