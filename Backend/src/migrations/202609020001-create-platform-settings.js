const permissionCatalog = require('../admin/permissions');

const defaults = [
  ['maintenance_mode_enabled', false],
  ['registration_enabled', true],
  ['support_email', ''],
];

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('PlatformSettings', {
        key: { type: Sequelize.STRING(80), primaryKey: true },
        value: { type: Sequelize.JSON, allowNull: false },
        version: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
        updatedByAdministratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
        updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      }, { transaction });
      await queryInterface.bulkInsert('PlatformSettings', defaults.map(([key, value]) => ({ key, value: JSON.stringify(value), version: 1, createdAt: new Date(), updatedAt: new Date() })), { transaction });
      const permissions = permissionCatalog.filter((permission) => permission.key.startsWith('systemSettings.'));
      for (const permission of permissions) {
        await queryInterface.bulkInsert('AdminPermissions', [{ key: permission.key, name: permission.name, description: permission.description, module: permission.module }], { updateOnDuplicate: ['name', 'description', 'module'], transaction });
      }
      await queryInterface.sequelize.query(
        'INSERT IGNORE INTO `AdminRolePermissions` (`roleId`, `permissionId`, `createdAt`, `updatedAt`) SELECT r.`id`, p.`id`, NOW(), NOW() FROM `AdminRoles` r INNER JOIN `AdminPermissions` p ON p.`key` IN ("systemSettings.view", "systemSettings.update") WHERE r.`key` = "super_admin"',
        { transaction },
      );
      await transaction.commit();
    } catch (error) { await transaction.rollback(); throw error; }
  },
  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.sequelize.query('DELETE rp FROM `AdminRolePermissions` rp INNER JOIN `AdminPermissions` p ON p.`id` = rp.`permissionId` WHERE p.`key` IN ("systemSettings.view", "systemSettings.update")', { transaction });
      await queryInterface.bulkDelete('AdminPermissions', { key: ['systemSettings.view', 'systemSettings.update'] }, { transaction });
      await queryInterface.dropTable('PlatformSettings', { transaction });
      await transaction.commit();
    } catch (error) { await transaction.rollback(); throw error; }
  },
};
