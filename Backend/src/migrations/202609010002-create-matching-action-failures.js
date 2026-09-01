module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('MatchingActionFailures', {
      id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      actionType: { type: Sequelize.ENUM('like', 'super_like', 'rose'), allowNull: false },
      actorUserId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      targetUserId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      requestedTargetReference: { type: Sequelize.STRING(80), allowNull: true },
      safeCode: { type: Sequelize.STRING(80), allowNull: false },
      safeCategory: { type: Sequelize.ENUM('business_rejection', 'system_failure'), allowNull: false, defaultValue: 'business_rejection' },
      safeStage: { type: Sequelize.STRING(80), allowNull: false },
      retryable: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
      resolutionStatus: { type: Sequelize.ENUM('not_applicable', 'unresolved', 'resolved'), allowNull: false, defaultValue: 'not_applicable' },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('MatchingActionFailures', ['actionType', 'createdAt'], { name: 'matching_action_failures_type_time' });
    await queryInterface.addIndex('MatchingActionFailures', ['safeCode', 'createdAt'], { name: 'matching_action_failures_code_time' });
    await queryInterface.addIndex('MatchingActionFailures', ['actorUserId', 'createdAt'], { name: 'matching_action_failures_actor_time' });
  },
  async down(queryInterface) { await queryInterface.dropTable('MatchingActionFailures'); },
};
