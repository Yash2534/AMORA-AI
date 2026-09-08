module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('AccountDeletionRequests', {
      id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      // SET NULL preserves lifecycle evidence if a future workflow physically removes Users.
      userId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      status: { type: Sequelize.ENUM('PENDING', 'VERIFIED', 'PROCESSING', 'COMPLETED', 'FAILED', 'BLOCKED_BY_RETENTION_DECISION'), allowNull: false, defaultValue: 'PENDING' },
      requestedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      verifiedAt: { type: Sequelize.DATE, allowNull: true },
      processingStartedAt: { type: Sequelize.DATE, allowNull: true },
      completedAt: { type: Sequelize.DATE, allowNull: true },
      failedAt: { type: Sequelize.DATE, allowNull: true },
      failureCode: { type: Sequelize.STRING(80), allowNull: true },
      legalHold: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      legalHoldReason: { type: Sequelize.STRING(120), allowNull: true },
      correlationId: { type: Sequelize.STRING(36), allowNull: false, unique: true },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('AccountDeletionRequests', ['userId', 'requestedAt'], { name: 'account_deletion_requests_user_requested' });
    await queryInterface.addIndex('AccountDeletionRequests', ['status', 'requestedAt'], { name: 'account_deletion_requests_status_requested' });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('AccountDeletionRequests');
  },
};
