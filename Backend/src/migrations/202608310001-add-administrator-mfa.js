module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('AdminMfaCredentials', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED, allowNull: false, unique: true,
          references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE',
        },
        encryptedSecret: { type: Sequelize.TEXT, allowNull: false },
        secretIv: { type: Sequelize.STRING(24), allowNull: false },
        secretTag: { type: Sequelize.STRING(32), allowNull: false },
        enabledAt: { type: Sequelize.DATE, allowNull: true },
        disabledAt: { type: Sequelize.DATE, allowNull: true },
        lastUsedCounter: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true },
        recoveryCodeGeneration: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('AdminMfaCredentials', ['enabledAt', 'administratorId'], {
        name: 'admin_mfa_credentials_state_admin', transaction,
      });

      await queryInterface.createTable('AdminMfaRecoveryCodes', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED, allowNull: false,
          references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE',
        },
        generation: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        codeHash: { type: Sequelize.STRING(64), allowNull: false, unique: true },
        consumedAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('AdminMfaRecoveryCodes', ['administratorId', 'generation', 'consumedAt'], {
        name: 'admin_mfa_recovery_owner_generation_state', transaction,
      });

      await queryInterface.createTable('AdminMfaChallenges', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED, allowNull: false,
          references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE',
        },
        selector: { type: Sequelize.STRING(32), allowNull: false, unique: true },
        tokenHash: { type: Sequelize.STRING(64), allowNull: false },
        rememberMe: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        consumedAt: { type: Sequelize.DATE, allowNull: true },
        attempts: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        requestedByIp: { type: Sequelize.STRING(64), allowNull: true },
        userAgent: { type: Sequelize.STRING(500), allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('AdminMfaChallenges', ['administratorId', 'expiresAt', 'consumedAt'], {
        name: 'admin_mfa_challenges_owner_expiry_state', transaction,
      });

      await queryInterface.addColumn('AdminRefreshTokens', 'mfaVerifiedAt', {
        type: Sequelize.DATE, allowNull: true,
      }, { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.removeColumn('AdminRefreshTokens', 'mfaVerifiedAt', { transaction });
      await queryInterface.dropTable('AdminMfaChallenges', { transaction });
      await queryInterface.dropTable('AdminMfaRecoveryCodes', { transaction });
      await queryInterface.dropTable('AdminMfaCredentials', { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
