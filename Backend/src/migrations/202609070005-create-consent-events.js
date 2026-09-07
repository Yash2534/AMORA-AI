module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('ConsentEvents', {
      id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      // SET NULL preserves evidence if a future approved workflow removes Users.
      userId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      documentVersionId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'LegalDocumentVersions', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'RESTRICT' },
      purpose: { type: Sequelize.ENUM('TERMS_OF_SERVICE_ACCEPTANCE', 'PRIVACY_POLICY_ACKNOWLEDGEMENT'), allowNull: false },
      action: { type: Sequelize.ENUM('ACCEPTED', 'ACKNOWLEDGED', 'WITHDRAWN', 'RECONSENTED'), allowNull: false },
      source: { type: Sequelize.ENUM('SIGNUP_EMAIL', 'SIGNUP_GOOGLE', 'SETTINGS', 'RECONSENT_FLOW', 'ONBOARDING'), allowNull: false },
      platform: { type: Sequelize.ENUM('ANDROID', 'IOS', 'WEB'), allowNull: false },
      occurredAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      metadata: { type: Sequelize.JSON, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('ConsentEvents', ['userId', 'occurredAt'], { name: 'consent_events_user_history' });
    await queryInterface.addIndex('ConsentEvents', ['documentVersionId', 'occurredAt'], { name: 'consent_events_document_history' });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('ConsentEvents');
  },
};
