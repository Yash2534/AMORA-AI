'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('Events', 'registrationDeadline', {
      type: Sequelize.DATE,
      allowNull: true,
      after: 'endDateTime',
    });
    await queryInterface.addIndex('Events', ['registrationDeadline'], {
      name: 'events_registration_deadline',
    });
  },
  async down(queryInterface) {
    await queryInterface.removeIndex('Events', 'events_registration_deadline');
    await queryInterface.removeColumn('Events', 'registrationDeadline');
  },
};
