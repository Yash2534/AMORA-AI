async function addColumnIfMissing(queryInterface, tableName, columnName, definition) {
  const columns = await queryInterface.describeTable(tableName);
  if (!columns[columnName]) {
    await queryInterface.addColumn(tableName, columnName, definition);
  }
}

module.exports = {
  async up(queryInterface, Sequelize) {
    await addColumnIfMissing(queryInterface, 'DeletedUsers', 'deletionReasonCode', {
      type: Sequelize.STRING(40),
      allowNull: true,
    });
    await addColumnIfMissing(queryInterface, 'DeletedUsers', 'deletionReasonText', {
      type: Sequelize.STRING(500),
      allowNull: true,
    });
  },

  async down(queryInterface) {
    const columns = await queryInterface.describeTable('DeletedUsers');
    if (columns.deletionReasonText) {
      await queryInterface.removeColumn('DeletedUsers', 'deletionReasonText');
    }
    if (columns.deletionReasonCode) {
      await queryInterface.removeColumn('DeletedUsers', 'deletionReasonCode');
    }
  },
};
