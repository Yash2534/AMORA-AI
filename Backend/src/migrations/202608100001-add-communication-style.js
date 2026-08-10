const { COMMUNICATION_STYLE_VALUES } = require('../constants/communicationStyles');

async function tableColumns(queryInterface, tableName) {
  try {
    return await queryInterface.describeTable(tableName);
  } catch (error) {
    if (['ER_NO_SUCH_TABLE', 'SQLITE_ERROR'].includes(error.original?.code)) {
      return null;
    }
    throw error;
  }
}

module.exports = {
  async up(queryInterface, Sequelize) {
    const profileColumns = await tableColumns(queryInterface, 'OnboardingProfiles');
    if (profileColumns && !profileColumns.communicationStyle) {
      await queryInterface.addColumn('OnboardingProfiles', 'communicationStyle', {
        type: Sequelize.ENUM(...COMMUNICATION_STYLE_VALUES),
        allowNull: true,
      });
    }

    const filterColumns = await tableColumns(
      queryInterface,
      'DiscoverFilterPreferences',
    );
    if (filterColumns && !filterColumns.communicationStyles) {
      await queryInterface.addColumn(
        'DiscoverFilterPreferences',
        'communicationStyles',
        {
          type: Sequelize.JSON,
          allowNull: false,
          defaultValue: [],
        },
      );
    }
  },

  async down(queryInterface) {
    const filterColumns = await tableColumns(
      queryInterface,
      'DiscoverFilterPreferences',
    );
    if (filterColumns?.communicationStyles) {
      await queryInterface.removeColumn(
        'DiscoverFilterPreferences',
        'communicationStyles',
      );
    }

    const profileColumns = await tableColumns(queryInterface, 'OnboardingProfiles');
    if (profileColumns?.communicationStyle) {
      await queryInterface.removeColumn('OnboardingProfiles', 'communicationStyle');
    }
  },
};
