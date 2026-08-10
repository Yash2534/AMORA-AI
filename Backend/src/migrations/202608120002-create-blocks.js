async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (await tableExists(queryInterface, 'Blocks')) return;
    await queryInterface.createTable('Blocks', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      blockerUserId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
      blockedUserId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
      createdAt: { type: Sequelize.DATE, allowNull: false },
      updatedAt: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('Blocks', ['blockerUserId', 'blockedUserId'], { unique: true, name: 'blocks_blocker_blocked_unique' });
    await queryInterface.addIndex('Blocks', ['blockedUserId', 'blockerUserId'], { name: 'blocks_blocked_blocker_lookup' });
  },

  async down() {
    // Safety relationships are retained on rollback to avoid destructive data loss.
  },
};
