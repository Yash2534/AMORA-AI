module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn('Messages', 'type', { type: Sequelize.ENUM('text', 'image', 'rose'), allowNull: false, defaultValue: 'text' });
    const columns = await queryInterface.describeTable('Messages');
    if (!columns.roseTransactionId) {
      await queryInterface.addColumn('Messages', 'roseTransactionId', { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'RoseTransactions', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'RESTRICT' });
      await queryInterface.addIndex('Messages', ['roseTransactionId'], { unique: true, name: 'messages_rose_transaction_unique' });
    }
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex('Messages', 'messages_rose_transaction_unique');
    await queryInterface.removeColumn('Messages', 'roseTransactionId');
    await queryInterface.changeColumn('Messages', 'type', { type: Sequelize.ENUM('text', 'image'), allowNull: false, defaultValue: 'text' });
  },
};
