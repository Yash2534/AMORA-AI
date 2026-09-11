'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableDescription = await queryInterface.describeTable('AdminAuditLogs');

    if (!tableDescription.sequence) {
      await queryInterface.addColumn('AdminAuditLogs', 'sequence', {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: true,
      });
    }

    if (!tableDescription.previousHash) {
      await queryInterface.addColumn('AdminAuditLogs', 'previousHash', {
        type: Sequelize.STRING(64),
        allowNull: true,
      });
    }

    if (!tableDescription.currentHash) {
      await queryInterface.addColumn('AdminAuditLogs', 'currentHash', {
        type: Sequelize.STRING(64),
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    const tableDescription = await queryInterface.describeTable('AdminAuditLogs');

    if (tableDescription.currentHash) {
      await queryInterface.removeColumn('AdminAuditLogs', 'currentHash');
    }
    if (tableDescription.previousHash) {
      await queryInterface.removeColumn('AdminAuditLogs', 'previousHash');
    }
    if (tableDescription.sequence) {
      await queryInterface.removeColumn('AdminAuditLogs', 'sequence');
    }
  },
};
