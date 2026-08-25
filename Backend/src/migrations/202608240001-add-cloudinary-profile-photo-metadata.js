async function columnExists(queryInterface, tableName, columnName) {
  const columns = await queryInterface.describeTable(tableName);
  return Object.keys(columns).some((column) => column.toLowerCase() === columnName.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'OnboardingProfiles', 'photoMetadata'))) await queryInterface.addColumn('OnboardingProfiles', 'photoMetadata', { type: Sequelize.JSON, allowNull: false, defaultValue: [] });
  },
  async down(queryInterface) {
    if (await columnExists(queryInterface, 'OnboardingProfiles', 'photoMetadata')) await queryInterface.removeColumn('OnboardingProfiles', 'photoMetadata');
  },
};
