const catalog = require('../admin/permissions');

const KEYS = ['privacy.grievances.view', 'privacy.grievances.manage'];

module.exports = {
  async up(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const rows = catalog.filter((permission) => KEYS.includes(permission.key));
      await queryInterface.bulkInsert('AdminPermissions', rows, {
        updateOnDuplicate: ['name', 'description', 'module'],
        transaction,
      });
      await queryInterface.sequelize.query(
        'INSERT IGNORE INTO `AdminRolePermissions` (`roleId`, `permissionId`, `createdAt`, `updatedAt`) '
          + 'SELECT roleRow.`id`, permissionRow.`id`, NOW(), NOW() '
          + 'FROM `AdminRoles` roleRow JOIN `AdminPermissions` permissionRow '
          + 'WHERE roleRow.`key` = :roleKey AND permissionRow.`key` IN (:permissionKeys)',
        { replacements: { roleKey: 'super_admin', permissionKeys: KEYS }, transaction },
      );
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.sequelize.query(
        'DELETE rolePermission FROM `AdminRolePermissions` rolePermission '
          + 'JOIN `AdminPermissions` permissionRow ON permissionRow.`id` = rolePermission.`permissionId` '
          + 'WHERE permissionRow.`key` IN (:permissionKeys)',
        { replacements: { permissionKeys: KEYS }, transaction },
      );
      await queryInterface.bulkDelete('AdminPermissions', { key: KEYS }, { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
