async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (await tableExists(queryInterface, 'AccountDeletionConfirmations')) return;
    await queryInterface.createTable('AccountDeletionConfirmations', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
      tokenSelector: { type: Sequelize.STRING(32), allowNull: false, unique: true },
      tokenHash: { type: Sequelize.STRING(64), allowNull: false },
      purpose: { type: Sequelize.STRING(64), allowNull: false, defaultValue: 'account_deletion' },
      expiresAt: { type: Sequelize.DATE, allowNull: false },
      consumedAt: { type: Sequelize.DATE, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false },
      updatedAt: { type: Sequelize.DATE, allowNull: false },
    });
    await queryInterface.addIndex('AccountDeletionConfirmations', ['userId', 'expiresAt'], { name: 'account_deletion_confirmations_user_expiry' });
  },
  async down() {
    // Deliberately non-destructive for production safety.
  },
};
