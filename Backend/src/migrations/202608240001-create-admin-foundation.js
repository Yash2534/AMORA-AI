const permissionCatalog = require('../admin/permissions');

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('Administrators', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        name: { type: Sequelize.STRING(120), allowNull: false },
        email: { type: Sequelize.STRING(191), allowNull: false, unique: true },
        passwordHash: { type: Sequelize.STRING(255), allowNull: false },
        status: { type: Sequelize.ENUM('active', 'suspended', 'disabled'), allowNull: false, defaultValue: 'active' },
        tokenVersion: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        failedLoginAttempts: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        lockedUntil: { type: Sequelize.DATE, allowNull: true },
        lastLoginAt: { type: Sequelize.DATE, allowNull: true },
        lastActiveAt: { type: Sequelize.DATE, allowNull: true },
        createdByAdministratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });

      await queryInterface.createTable('AdminRoles', {
        id: { type: Sequelize.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
        key: { type: Sequelize.STRING(80), allowNull: false, unique: true },
        name: { type: Sequelize.STRING(120), allowNull: false },
        description: { type: Sequelize.STRING(500), allowNull: true },
        isSystem: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        isActive: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });

      await queryInterface.createTable('AdminPermissions', {
        id: { type: Sequelize.INTEGER.UNSIGNED, autoIncrement: true, primaryKey: true },
        key: { type: Sequelize.STRING(160), allowNull: false, unique: true },
        name: { type: Sequelize.STRING(200), allowNull: false },
        description: { type: Sequelize.STRING(500), allowNull: false },
        module: { type: Sequelize.STRING(80), allowNull: false },
      }, { transaction });

      await queryInterface.createTable('AdministratorRoles', {
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: false,
          primaryKey: true,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        roleId: {
          type: Sequelize.INTEGER.UNSIGNED,
          allowNull: false,
          primaryKey: true,
          references: { model: 'AdminRoles', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });

      await queryInterface.createTable('AdminRolePermissions', {
        roleId: {
          type: Sequelize.INTEGER.UNSIGNED,
          allowNull: false,
          primaryKey: true,
          references: { model: 'AdminRoles', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        permissionId: {
          type: Sequelize.INTEGER.UNSIGNED,
          allowNull: false,
          primaryKey: true,
          references: { model: 'AdminPermissions', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });

      await queryInterface.createTable('AdminRefreshTokens', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: false,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        selector: { type: Sequelize.STRING(32), allowNull: false, unique: true },
        tokenHash: { type: Sequelize.STRING(64), allowNull: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        revokedAt: { type: Sequelize.DATE, allowNull: true },
        createdByIp: { type: Sequelize.STRING(64), allowNull: true },
        userAgent: { type: Sequelize.STRING(500), allowNull: true },
        lastUsedAt: { type: Sequelize.DATE, allowNull: true },
        persistent: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });

      await queryInterface.createTable('AdminAuditLogs', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: true,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        action: { type: Sequelize.STRING(160), allowNull: false },
        targetType: { type: Sequelize.STRING(80), allowNull: true },
        targetId: { type: Sequelize.STRING(191), allowNull: true },
        oldValue: { type: Sequelize.JSON, allowNull: true },
        newValue: { type: Sequelize.JSON, allowNull: true },
        reason: { type: Sequelize.STRING(500), allowNull: true },
        metadata: { type: Sequelize.JSON, allowNull: true },
        ipAddress: { type: Sequelize.STRING(64), allowNull: true },
        userAgent: { type: Sequelize.STRING(500), allowNull: true },
        correlationId: { type: Sequelize.STRING(80), allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });

      await queryInterface.addIndex('Administrators', ['status', 'id'], { name: 'administrators_status', transaction });
      await queryInterface.addIndex('AdminRefreshTokens', ['administratorId', 'expiresAt'], { name: 'admin_refresh_tokens_owner_expiry', transaction });
      await queryInterface.addIndex('AdminAuditLogs', ['administratorId', 'createdAt'], { name: 'admin_audit_actor_time', transaction });
      await queryInterface.addIndex('AdminAuditLogs', ['targetType', 'targetId', 'createdAt'], { name: 'admin_audit_target_time', transaction });
      await queryInterface.addIndex('AdminAuditLogs', ['action', 'createdAt'], { name: 'admin_audit_action_time', transaction });

      const now = new Date();
      await queryInterface.bulkInsert('AdminPermissions', permissionCatalog.map((permission) => ({
        key: permission.key,
        name: permission.name,
        description: permission.description,
        module: permission.module,
      })), { transaction });
      await queryInterface.bulkInsert('AdminRoles', [{
        key: 'super_admin',
        name: 'Super Admin',
        description: 'System role with the complete administrator permission catalog.',
        isSystem: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      }], { transaction });

      const [roles] = await queryInterface.sequelize.query(
        'SELECT `id` FROM `AdminRoles` WHERE `key` = ?',
        { replacements: ['super_admin'], transaction },
      );
      const [permissionRows] = await queryInterface.sequelize.query(
        'SELECT `id` FROM `AdminPermissions`',
        { transaction },
      );
      await queryInterface.bulkInsert('AdminRolePermissions', permissionRows.map((permission) => ({
        roleId: roles[0].id,
        permissionId: permission.id,
        createdAt: now,
        updatedAt: now,
      })), { transaction });

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('AdminAuditLogs');
    await queryInterface.dropTable('AdminRefreshTokens');
    await queryInterface.dropTable('AdminRolePermissions');
    await queryInterface.dropTable('AdministratorRoles');
    await queryInterface.dropTable('AdminPermissions');
    await queryInterface.dropTable('AdminRoles');
    await queryInterface.dropTable('Administrators');
  },
};
