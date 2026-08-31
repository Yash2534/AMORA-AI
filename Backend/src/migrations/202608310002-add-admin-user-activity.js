module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('UserLoginEvents', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        result: { type: Sequelize.ENUM('successful', 'failed'), allowNull: false },
        authenticationMethod: { type: Sequelize.ENUM('password', 'google'), allowNull: false },
        failureCategory: { type: Sequelize.STRING(80), allowNull: true },
        ipAddress: { type: Sequelize.STRING(64), allowNull: true },
        userAgent: { type: Sequelize.STRING(500), allowNull: true },
        occurredAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('UserLoginEvents', ['userId', 'occurredAt'], { name: 'user_login_events_user_time', transaction });

      await queryInterface.createTable('AdminUserNotes', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        authorAdministratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'RESTRICT' },
        text: { type: Sequelize.TEXT, allowNull: false },
        category: { type: Sequelize.STRING(40), allowNull: false, defaultValue: 'general' },
        version: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
        deletedAt: { type: Sequelize.DATE, allowNull: true },
        deletedByAdministratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('AdminUserNotes', ['userId', 'deletedAt', 'createdAt'], { name: 'admin_user_notes_user_state_time', transaction });
      await queryInterface.addIndex('AdminUserNotes', ['authorAdministratorId', 'deletedAt'], { name: 'admin_user_notes_author_state', transaction });

      await queryInterface.createTable('AdminUserNoteVersions', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        noteId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'AdminUserNotes', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        version: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        action: { type: Sequelize.ENUM('created', 'updated', 'deleted'), allowNull: false },
        text: { type: Sequelize.TEXT, allowNull: true },
        administratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addConstraint('AdminUserNoteVersions', { fields: ['noteId', 'version'], type: 'unique', name: 'admin_user_note_versions_note_version', transaction });

      await queryInterface.createTable('UserTimelineEvents', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        eventType: { type: Sequelize.STRING(80), allowNull: false },
        title: { type: Sequelize.STRING(160), allowNull: false },
        description: { type: Sequelize.STRING(500), allowNull: true },
        status: { type: Sequelize.STRING(80), allowNull: true },
        relatedReference: { type: Sequelize.STRING(191), allowNull: true },
        administratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        occurredAt: { type: Sequelize.DATE, allowNull: false },
      }, { transaction });
      await queryInterface.addIndex('UserTimelineEvents', ['userId', 'occurredAt'], { name: 'user_timeline_events_user_time', transaction });

      await queryInterface.sequelize.query(
        'INSERT INTO `UserTimelineEvents` (`userId`, `eventType`, `title`, `occurredAt`) SELECT `id`, \'account_created\', \'Account created\', `createdAt` FROM `Users`',
        { transaction },
      );
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.dropTable('UserTimelineEvents', { transaction });
      await queryInterface.dropTable('AdminUserNoteVersions', { transaction });
      await queryInterface.dropTable('AdminUserNotes', { transaction });
      await queryInterface.dropTable('UserLoginEvents', { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
