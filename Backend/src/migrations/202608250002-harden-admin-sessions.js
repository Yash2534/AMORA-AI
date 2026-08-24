module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.addColumn('AdminRefreshTokens', 'sessionFamilyId', {
        type: Sequelize.STRING(36),
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('AdminRefreshTokens', 'revokedReason', {
        type: Sequelize.STRING(40),
        allowNull: true,
      }, { transaction });
      await queryInterface.addColumn('AdminRefreshTokens', 'replacedByTokenId', {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: true,
        references: { model: 'AdminRefreshTokens', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      }, { transaction });
      await queryInterface.sequelize.query(
        'UPDATE `AdminRefreshTokens` SET `sessionFamilyId` = UUID() WHERE `sessionFamilyId` IS NULL',
        { transaction },
      );
      await queryInterface.changeColumn('AdminRefreshTokens', 'sessionFamilyId', {
        type: Sequelize.STRING(36),
        allowNull: false,
      }, { transaction });
      await queryInterface.addIndex('AdminRefreshTokens', ['sessionFamilyId', 'revokedAt'], {
        name: 'admin_refresh_tokens_family_state',
        transaction,
      });

      await queryInterface.createTable('AdminPasswordResetTokens', {
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
        consumedAt: { type: Sequelize.DATE, allowNull: true },
        requestedByIp: { type: Sequelize.STRING(64), allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('AdminPasswordResetTokens', ['administratorId', 'expiresAt'], {
        name: 'admin_password_reset_owner_expiry',
        transaction,
      });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('AdminPasswordResetTokens');
    await queryInterface.removeIndex('AdminRefreshTokens', 'admin_refresh_tokens_family_state');
    await queryInterface.removeColumn('AdminRefreshTokens', 'replacedByTokenId');
    await queryInterface.removeColumn('AdminRefreshTokens', 'revokedReason');
    await queryInterface.removeColumn('AdminRefreshTokens', 'sessionFamilyId');
  },
};
