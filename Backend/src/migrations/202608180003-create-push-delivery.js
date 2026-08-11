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
    if (!(await columnExists(queryInterface, 'Notifications', 'dedupeKey'))) {
      await queryInterface.addColumn('Notifications', 'dedupeKey', { type: Sequelize.STRING(180), allowNull: true });
      await queryInterface.addIndex('Notifications', ['userId', 'dedupeKey'], { unique: true, name: 'notifications_user_dedupe_unique' });
    }
    if (!(await tableExists(queryInterface, 'UserDevices'))) {
      await queryInterface.createTable('UserDevices', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        pushToken: { type: Sequelize.STRING(512), allowNull: false, unique: true },
        platform: { type: Sequelize.ENUM('android', 'ios', 'web'), allowNull: false },
        installationId: { type: Sequelize.STRING(160), allowNull: true },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        lastSeenAt: { type: Sequelize.DATE, allowNull: false },
        invalidatedAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('UserDevices', ['userId', 'active', 'lastSeenAt'], { name: 'user_devices_active_lookup' });
      await queryInterface.addIndex('UserDevices', ['userId', 'installationId'], { name: 'user_devices_installation_lookup' });
    }
    if (!(await tableExists(queryInterface, 'NotificationDeliveries'))) {
      await queryInterface.createTable('NotificationDeliveries', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        notificationId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'Notifications', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        userDeviceId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: false, references: { model: 'UserDevices', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        channel: { type: Sequelize.ENUM('push'), allowNull: false, defaultValue: 'push' },
        status: { type: Sequelize.ENUM('pending', 'sent', 'failed', 'credentials_required'), allowNull: false, defaultValue: 'pending' },
        providerMessageId: { type: Sequelize.STRING(255), allowNull: true },
        attemptCount: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        lastAttemptAt: { type: Sequelize.DATE, allowNull: true },
        errorCode: { type: Sequelize.STRING(100), allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('NotificationDeliveries', ['notificationId', 'userDeviceId', 'channel'], { unique: true, name: 'notification_deliveries_target_unique' });
      await queryInterface.addIndex('NotificationDeliveries', ['status', 'lastAttemptAt', 'id'], { name: 'notification_deliveries_retry_queue' });
    }
  },

  async down(queryInterface) {
    if (await tableExists(queryInterface, 'NotificationDeliveries')) await queryInterface.dropTable('NotificationDeliveries');
    if (await tableExists(queryInterface, 'UserDevices')) await queryInterface.dropTable('UserDevices');
    if (await columnExists(queryInterface, 'Notifications', 'dedupeKey')) await queryInterface.removeColumn('Notifications', 'dedupeKey');
  },
};
