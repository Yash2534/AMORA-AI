module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.changeColumn('Administrators', 'passwordHash', {
        type: Sequelize.STRING(255),
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'version', {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: false,
        defaultValue: 1,
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'locale', {
        type: Sequelize.STRING(20),
        allowNull: false,
        defaultValue: 'en-IN',
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'timezone', {
        type: Sequelize.STRING(80),
        allowNull: false,
        defaultValue: 'Asia/Kolkata',
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'invitationStatus', {
        type: Sequelize.ENUM('not_required', 'pending', 'accepted', 'expired', 'revoked'),
        allowNull: false,
        defaultValue: 'not_required',
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'activatedAt', {
        type: Sequelize.DATE,
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'suspendedAt', {
        type: Sequelize.DATE,
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'suspendedByAdministratorId', {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: true,
        references: { model: 'Administrators', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'suspensionReasonCode', {
        type: Sequelize.STRING(40),
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'suspensionReasonDetail', {
        type: Sequelize.STRING(500),
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('Administrators', 'suspensionEndsAt', {
        type: Sequelize.DATE,
        allowNull: true,
      }, { transaction });
      await queryInterface.sequelize.query(
        'UPDATE `Administrators` SET `activatedAt` = COALESCE(`lastLoginAt`, `createdAt`) WHERE `status` = "active" AND `activatedAt` IS NULL',
        { transaction },
      );
      await queryInterface.addConstraint('Administrators', {
        fields: ['createdByAdministratorId'],
        type: 'foreign key',
        name: 'administrators_created_by_fk',
        references: { table: 'Administrators', field: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
        transaction,
      });
      await queryInterface.addIndex('Administrators', ['status', 'createdAt'], {
        name: 'administrators_status_created_at', transaction,
      });
      await queryInterface.addIndex('Administrators', ['invitationStatus', 'createdAt'], {
        name: 'administrators_invitation_created_at', transaction,
      });

      await queryInterface.addColumn('AdminRoles', 'version', {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: false,
        defaultValue: 1,
      }, { transaction });
      await queryInterface.addIndex('AdminRoles', ['isActive', 'name'], {
        name: 'admin_roles_state_name', transaction,
      });

      await queryInterface.createTable('AdminInvitations', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: false,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        invitedByAdministratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: true,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        selector: { type: Sequelize.STRING(32), allowNull: false, unique: true },
        tokenHash: { type: Sequelize.STRING(64), allowNull: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        consumedAt: { type: Sequelize.DATE, allowNull: true },
        revokedAt: { type: Sequelize.DATE, allowNull: true },
        deliveryStatus: {
          type: Sequelize.ENUM('not_requested', 'pending', 'provider_accepted', 'failed'),
          allowNull: false,
          defaultValue: 'not_requested',
        },
        deliveryAttempts: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        providerMessageId: { type: Sequelize.STRING(191), allowNull: true },
        deliveryErrorCode: { type: Sequelize.STRING(80), allowNull: true },
        deliveryAttemptedAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('AdminInvitations', ['administratorId', 'expiresAt'], {
        name: 'admin_invitations_owner_expiry', transaction,
      });
      await queryInterface.addIndex('AdminInvitations', ['deliveryStatus', 'createdAt'], {
        name: 'admin_invitations_delivery_state', transaction,
      });

      await queryInterface.createTable('AdminIdempotencyKeys', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: false,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        scope: { type: Sequelize.STRING(120), allowNull: false },
        idempotencyKey: { type: Sequelize.STRING(160), allowNull: false },
        requestHash: { type: Sequelize.STRING(64), allowNull: false },
        responseStatus: { type: Sequelize.SMALLINT.UNSIGNED, allowNull: false },
        responseBody: { type: Sequelize.JSON, allowNull: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addConstraint('AdminIdempotencyKeys', {
        fields: ['administratorId', 'scope', 'idempotencyKey'],
        type: 'unique',
        name: 'admin_idempotency_actor_scope_key',
        transaction,
      });
      await queryInterface.addIndex('AdminIdempotencyKeys', ['expiresAt'], {
        name: 'admin_idempotency_expiry', transaction,
      });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.dropTable('AdminIdempotencyKeys', { transaction });
      await queryInterface.dropTable('AdminInvitations', { transaction });
      await queryInterface.removeIndex('AdminRoles', 'admin_roles_state_name', { transaction });
      await queryInterface.removeColumn('AdminRoles', 'version', { transaction });
      await queryInterface.removeIndex('Administrators', 'administrators_invitation_created_at', { transaction });
      await queryInterface.removeIndex('Administrators', 'administrators_status_created_at', { transaction });
      await queryInterface.removeConstraint('Administrators', 'administrators_created_by_fk', { transaction });
      for (const column of [
        'suspensionEndsAt', 'suspensionReasonDetail', 'suspensionReasonCode',
        'suspendedByAdministratorId', 'suspendedAt', 'activatedAt',
        'invitationStatus', 'timezone', 'locale', 'version',
      ]) await queryInterface.removeColumn('Administrators', column, { transaction });
      await queryInterface.changeColumn('Administrators', 'passwordHash', {
        type: Sequelize.STRING(255), allowNull: false,
      }, { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
