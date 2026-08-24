const permissionCatalog = require('../admin/permissions');

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const description = await queryInterface.describeTable('AdminPermissions');
      if (!description.description) {
        await queryInterface.addColumn('AdminPermissions', 'description', {
          type: Sequelize.STRING(500),
          allowNull: true,
        }, { transaction });
      }

      for (const permission of permissionCatalog) {
        await queryInterface.bulkInsert('AdminPermissions', [{
          key: permission.key,
          name: permission.name,
          description: permission.description,
          module: permission.module,
        }], {
          updateOnDuplicate: ['name', 'description', 'module'],
          transaction,
        });
      }

      await queryInterface.sequelize.query(
        'UPDATE `AdminPermissions` SET `description` = CONCAT("Allows the administrator to perform the ", `name`, " operation.") WHERE `description` IS NULL OR `description` = ""',
        { transaction },
      );
      await queryInterface.changeColumn('AdminPermissions', 'description', {
        type: Sequelize.STRING(500),
        allowNull: false,
      }, { transaction });

      await queryInterface.sequelize.query(
        'INSERT IGNORE INTO `AdminRolePermissions` (`roleId`, `permissionId`, `createdAt`, `updatedAt`) SELECT r.`id`, p.`id`, NOW(), NOW() FROM `AdminRoles` r CROSS JOIN `AdminPermissions` p WHERE r.`key` = "super_admin"',
        { transaction },
      );

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('AdminPermissions', 'description');
  },
};
