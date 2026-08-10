async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'Reports'))) {
      await queryInterface.createTable('Reports', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        reporterUserId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT' },
        reportedUserId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT' },
        targetType: { type: Sequelize.ENUM('profile', 'event', 'message'), allowNull: false, defaultValue: 'profile' },
        targetId: { type: Sequelize.STRING, allowNull: false },
        reason: { type: Sequelize.ENUM('fake_profile', 'harassment', 'inappropriate_photo', 'scam', 'spam', 'other'), allowNull: false },
        notes: { type: Sequelize.TEXT, allowNull: true },
        status: { type: Sequelize.ENUM('open', 'reviewing', 'resolved', 'dismissed'), allowNull: false, defaultValue: 'open' },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('Reports', ['reporterUserId', 'targetType', 'targetId', 'reason', 'createdAt'], { name: 'reports_duplicate_guard_lookup' });
      await queryInterface.addIndex('Reports', ['reportedUserId', 'status'], { name: 'reports_reported_user_status' });
    }

    if (!(await tableExists(queryInterface, 'ReportEvidence'))) {
      await queryInterface.createTable('ReportEvidence', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        reportId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Reports', key: 'id' }, onDelete: 'CASCADE' },
        originalName: { type: Sequelize.STRING, allowNull: false },
        storagePath: { type: Sequelize.STRING, allowNull: false },
        mimeType: { type: Sequelize.STRING, allowNull: false },
        sizeBytes: { type: Sequelize.INTEGER, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('ReportEvidence', ['reportId', 'createdAt'], { name: 'report_evidence_report_created' });
    }
  },

  async down() {
    // Moderation reports and evidence metadata are retained for safety/audit purposes.
  },
};
