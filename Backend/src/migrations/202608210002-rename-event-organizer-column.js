module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('Events');
    if (columns.hostId && !columns.organizerId) {
      await queryInterface.renameColumn('Events', 'hostId', 'organizerId');
    }
    const updated = await queryInterface.describeTable('Events');
    if (updated.organizerId) {
      await queryInterface.changeColumn('Events', 'organizerId', {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: { model: 'Users', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT',
      });
    }
  },

  async down(queryInterface) {
    const columns = await queryInterface.describeTable('Events');
    if (columns.organizerId && !columns.hostId) {
      await queryInterface.renameColumn('Events', 'organizerId', 'hostId');
    }
  },
};
