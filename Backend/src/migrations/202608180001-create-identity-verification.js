async function tableExists(queryInterface, name) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === name.toLowerCase());
}

async function columnExists(queryInterface, table, column) {
  if (!(await tableExists(queryInterface, table))) return false;
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'Users', 'identityVerifiedAt'))) {
      await queryInterface.addColumn('Users', 'identityVerifiedAt', { type: Sequelize.DATE, allowNull: true });
      await queryInterface.addIndex('Users', ['identityVerifiedAt', 'id'], { name: 'users_identity_verified' });
    }
    if (!(await tableExists(queryInterface, 'IdentityVerifications'))) {
      await queryInterface.createTable('IdentityVerifications', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, unique: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        status: { type: Sequelize.ENUM('pending', 'under_review', 'verified', 'rejected'), allowNull: false, defaultValue: 'pending' },
        aadhaarStoragePath: { type: Sequelize.STRING(500), allowNull: false },
        aadhaarMimeType: { type: Sequelize.STRING(50), allowNull: false },
        aadhaarSizeBytes: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        selfieStoragePath: { type: Sequelize.STRING(500), allowNull: false },
        selfieMimeType: { type: Sequelize.STRING(50), allowNull: false },
        selfieSizeBytes: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        submittedAt: { type: Sequelize.DATE, allowNull: false },
        reviewedAt: { type: Sequelize.DATE, allowNull: true },
        reviewerUserId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        reviewNote: { type: Sequelize.STRING(500), allowNull: true },
        rejectionReason: { type: Sequelize.STRING(500), allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('IdentityVerifications', ['status', 'submittedAt', 'id'], { name: 'identity_verifications_review_queue' });
    }
  },

  async down(queryInterface) {
    if (await tableExists(queryInterface, 'IdentityVerifications')) await queryInterface.dropTable('IdentityVerifications');
    if (await columnExists(queryInterface, 'Users', 'identityVerifiedAt')) await queryInterface.removeColumn('Users', 'identityVerifiedAt');
  },
};
