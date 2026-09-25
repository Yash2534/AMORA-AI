async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'DeletedUsers'))) {
      await queryInterface.createTable('DeletedUsers', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        originalUserId: { type: Sequelize.INTEGER, allowNull: false, unique: true },
        deletionMechanism: { type: Sequelize.ENUM('USER_INITIATED_OTP'), allowNull: false },
        accountCreatedAt: { type: Sequelize.DATE, allowNull: false },
        deletedAt: { type: Sequelize.DATE, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('DeletedUsers', ['deletedAt'], {
        name: 'deleted_users_deleted_at',
      });
    }

    const otpColumns = await queryInterface.describeTable('OtpTokens');
    if (!otpColumns.userId) {
      await queryInterface.addColumn('OtpTokens', 'userId', {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: { model: 'Users', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      });
      await queryInterface.addIndex('OtpTokens', ['userId', 'purpose', 'consumed'], {
        name: 'otp_tokens_user_purpose_consumed',
      });
    }
    await queryInterface.changeColumn('OtpTokens', 'purpose', {
      type: Sequelize.ENUM('account_verification', 'password_reset', 'account_deletion'),
      allowNull: false,
    });
  },

  async down() {
    // Deliberately non-destructive: historical deletion evidence must remain.
  },
};
