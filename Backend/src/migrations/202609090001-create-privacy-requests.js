module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('PrivacyRequests', {
      id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      // SET NULL preserves request history if a future approved process physically removes Users.
      userId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      requestType: { type: Sequelize.ENUM('ACCESS', 'EXPORT', 'CORRECTION', 'WITHDRAWAL'), allowNull: false },
      status: { type: Sequelize.ENUM('IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'PROCESSING', 'COMPLETED', 'FAILED'), allowNull: false, defaultValue: 'IDENTITY_VERIFICATION_REQUIRED' },
      requestedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      identityVerifiedAt: { type: Sequelize.DATE, allowNull: true },
      processingStartedAt: { type: Sequelize.DATE, allowNull: true },
      completedAt: { type: Sequelize.DATE, allowNull: true },
      failedAt: { type: Sequelize.DATE, allowNull: true },
      failureCode: { type: Sequelize.STRING(80), allowNull: true },
      assignedAdminId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      correlationId: { type: Sequelize.STRING(36), allowNull: false, unique: true },
      metadata: { type: Sequelize.JSON, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('PrivacyRequests', ['userId', 'requestedAt'], { name: 'privacy_requests_user_requested' });
    await queryInterface.addIndex('PrivacyRequests', ['requestType', 'status'], { name: 'privacy_requests_type_status' });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('PrivacyRequests');
  },
};
