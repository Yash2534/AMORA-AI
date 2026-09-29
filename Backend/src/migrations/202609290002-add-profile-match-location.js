module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('OnboardingProfiles', 'matchLatitude', {
      type: Sequelize.DECIMAL(9, 6),
      allowNull: true,
    });
    await queryInterface.addColumn('OnboardingProfiles', 'matchLongitude', {
      type: Sequelize.DECIMAL(9, 6),
      allowNull: true,
    });
    await queryInterface.addColumn('OnboardingProfiles', 'locationUpdatedAt', {
      type: Sequelize.DATE,
      allowNull: true,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('OnboardingProfiles', 'locationUpdatedAt');
    await queryInterface.removeColumn('OnboardingProfiles', 'matchLongitude');
    await queryInterface.removeColumn('OnboardingProfiles', 'matchLatitude');
  },
};
