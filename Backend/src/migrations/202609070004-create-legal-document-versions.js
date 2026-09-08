module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('LegalDocumentVersions', {
      id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
      documentKey: { type: Sequelize.ENUM('TERMS_OF_SERVICE', 'PRIVACY_POLICY'), allowNull: false },
      version: { type: Sequelize.STRING(64), allowNull: false },
      contentHash: { type: Sequelize.CHAR(64), allowNull: false },
      publishedAt: { type: Sequelize.DATE, allowNull: false },
      effectiveAt: { type: Sequelize.DATE, allowNull: false },
      retiredAt: { type: Sequelize.DATE, allowNull: true },
      status: { type: Sequelize.ENUM('DRAFT', 'PUBLISHED', 'ACTIVE', 'RETIRED'), allowNull: false, defaultValue: 'DRAFT' },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
    await queryInterface.addIndex('LegalDocumentVersions', ['documentKey', 'version'], { unique: true, name: 'legal_document_versions_key_version' });
    await queryInterface.addIndex('LegalDocumentVersions', ['documentKey', 'status', 'effectiveAt'], { name: 'legal_document_versions_active_lookup' });
  },
  async down(queryInterface) {
    await queryInterface.dropTable('LegalDocumentVersions');
  },
};
