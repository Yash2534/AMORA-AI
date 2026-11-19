module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();
    const tableExists = tables.some((table) => String(table).toLowerCase() === 'discoverfilterpreferences');
    if (!tableExists) return;

    const columns = await queryInterface.describeTable('DiscoverFilterPreferences');
    if (columns.verifiedOnly) {
      await queryInterface.changeColumn('DiscoverFilterPreferences', 'verifiedOnly', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      });
      await queryInterface.sequelize.query(
        'UPDATE DiscoverFilterPreferences SET verifiedOnly = false WHERE verifiedOnly = true'
      );
    }
  },

  async down(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();
    const tableExists = tables.some((table) => String(table).toLowerCase() === 'discoverfilterpreferences');
    if (!tableExists) return;

    const columns = await queryInterface.describeTable('DiscoverFilterPreferences');
    if (columns.verifiedOnly) {
      await queryInterface.changeColumn('DiscoverFilterPreferences', 'verifiedOnly', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      });
    }
  },
};

