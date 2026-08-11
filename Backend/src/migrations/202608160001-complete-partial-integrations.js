async function tableExists(queryInterface, name) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === name.toLowerCase());
}

async function columnExists(queryInterface, table, column) {
  if (!(await tableExists(queryInterface, table))) return false;
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

async function indexExists(queryInterface, table, name) {
  if (!(await tableExists(queryInterface, table))) return false;
  const indexes = await queryInterface.showIndex(table);
  return indexes.some((index) => index.name === name);
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'Users', 'lastActiveAt'))) {
      await queryInterface.addColumn('Users', 'lastActiveAt', { type: Sequelize.DATE, allowNull: true });
    }
    if (!(await indexExists(queryInterface, 'Users', 'users_last_active'))) {
      await queryInterface.addIndex('Users', ['lastActiveAt', 'id'], { name: 'users_last_active' });
    }
    if (!(await columnExists(queryInterface, 'OnboardingProfiles', 'iceBreaker'))) {
      await queryInterface.addColumn('OnboardingProfiles', 'iceBreaker', { type: Sequelize.STRING(280), allowNull: false, defaultValue: '' });
    }
    if (!(await tableExists(queryInterface, 'SavedProfiles'))) {
      await queryInterface.createTable('SavedProfiles', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        savedUserId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    if (!(await indexExists(queryInterface, 'SavedProfiles', 'saved_profiles_user_target_unique'))) {
      await queryInterface.addIndex('SavedProfiles', ['userId', 'savedUserId'], { unique: true, name: 'saved_profiles_user_target_unique' });
    }
    if (!(await indexExists(queryInterface, 'SavedProfiles', 'saved_profiles_user_created'))) {
      await queryInterface.addIndex('SavedProfiles', ['userId', 'createdAt', 'id'], { name: 'saved_profiles_user_created' });
    }
    if (!(await tableExists(queryInterface, 'NotificationPreferences'))) {
      await queryInterface.createTable('NotificationPreferences', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, unique: true, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        newMatches: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        messages: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        eventReminders: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        paymentsAndMembership: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        offers: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        safetyUpdates: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        pushEnabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        emailEnabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        smsEnabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        quietHoursEnabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        quietStart: { type: Sequelize.STRING(5), allowNull: false, defaultValue: '22:00' },
        quietEnd: { type: Sequelize.STRING(5), allowNull: false, defaultValue: '07:00' },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
  },

  async down(queryInterface) {
    if (await tableExists(queryInterface, 'NotificationPreferences')) await queryInterface.dropTable('NotificationPreferences');
    if (await tableExists(queryInterface, 'SavedProfiles')) await queryInterface.dropTable('SavedProfiles');
    if (await columnExists(queryInterface, 'OnboardingProfiles', 'iceBreaker')) await queryInterface.removeColumn('OnboardingProfiles', 'iceBreaker');
    if (await columnExists(queryInterface, 'Users', 'lastActiveAt')) await queryInterface.removeColumn('Users', 'lastActiveAt');
  },
};
