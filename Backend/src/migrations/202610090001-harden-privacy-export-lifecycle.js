async function columns(queryInterface) {
  return queryInterface.describeTable('PrivacyExportArtifacts');
}

module.exports = {
  async up(queryInterface, Sequelize) {
    const current = await columns(queryInterface);
    await queryInterface.changeColumn('PrivacyExportArtifacts', 'status', {
      type: Sequelize.ENUM('PENDING', 'GENERATED', 'FAILED', 'EXPIRED', 'DELETED'),
      allowNull: false,
      defaultValue: 'PENDING',
    });
    for (const field of ['expiresAt', 'downloadedAt', 'deletedAt']) {
      if (!current[field]) await queryInterface.addColumn('PrivacyExportArtifacts', field, { type: Sequelize.DATE, allowNull: true });
    }
    const indexes = await queryInterface.showIndex('PrivacyExportArtifacts');
    if (!indexes.some((index) => index.name === 'privacy_export_artifacts_status_expiry')) {
      await queryInterface.addIndex('PrivacyExportArtifacts', ['status', 'expiresAt'], { name: 'privacy_export_artifacts_status_expiry' });
    }
  },
  async down(queryInterface, Sequelize) {
    const indexes = await queryInterface.showIndex('PrivacyExportArtifacts');
    if (indexes.some((index) => index.name === 'privacy_export_artifacts_status_expiry')) await queryInterface.removeIndex('PrivacyExportArtifacts', 'privacy_export_artifacts_status_expiry');
    const current = await columns(queryInterface);
    for (const field of ['deletedAt', 'downloadedAt', 'expiresAt']) if (current[field]) await queryInterface.removeColumn('PrivacyExportArtifacts', field);
    await queryInterface.changeColumn('PrivacyExportArtifacts', 'status', {
      type: Sequelize.ENUM('PENDING', 'GENERATED', 'FAILED'),
      allowNull: false,
      defaultValue: 'PENDING',
    });
  },
};
