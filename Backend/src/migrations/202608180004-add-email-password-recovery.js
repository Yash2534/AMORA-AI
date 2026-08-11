module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('OtpTokens');
    if (!columns.email) {
      await queryInterface.addColumn('OtpTokens', 'email', {
        type: Sequelize.STRING,
        allowNull: true,
      });
    }
    if (!columns.recoveryUsedAt) {
      await queryInterface.addColumn('OtpTokens', 'recoveryUsedAt', {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }
    await queryInterface.changeColumn('OtpTokens', 'phoneNumber', {
      type: Sequelize.STRING,
      allowNull: true,
    });
    const indexes = await queryInterface.showIndex('OtpTokens');
    if (!indexes.some((index) => index.name === 'otp_tokens_email_policy')) {
      await queryInterface.addIndex(
        'OtpTokens',
        ['email', 'purpose', 'consumed', 'createdAt'],
        { name: 'otp_tokens_email_policy' },
      );
    }
  },

  async down(queryInterface, Sequelize) {
    const indexes = await queryInterface.showIndex('OtpTokens');
    if (indexes.some((index) => index.name === 'otp_tokens_email_policy')) {
      await queryInterface.removeIndex('OtpTokens', 'otp_tokens_email_policy');
    }
    const columns = await queryInterface.describeTable('OtpTokens');
    if (columns.recoveryUsedAt) {
      await queryInterface.removeColumn('OtpTokens', 'recoveryUsedAt');
    }
    if (columns.email) await queryInterface.removeColumn('OtpTokens', 'email');
    await queryInterface.changeColumn('OtpTokens', 'phoneNumber', {
      type: Sequelize.STRING,
      allowNull: false,
    });
  },
};
