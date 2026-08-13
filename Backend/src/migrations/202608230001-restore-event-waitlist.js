async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

async function columnExists(queryInterface, tableName, columnName) {
  if (!(await tableExists(queryInterface, tableName))) return false;
  const columns = await queryInterface.describeTable(tableName);
  return Object.keys(columns).some((column) => column.toLowerCase() === columnName.toLowerCase());
}

async function indexNames(queryInterface, tableName) {
  if (!(await tableExists(queryInterface, tableName))) return new Set();
  return new Set((await queryInterface.showIndex(tableName)).map((index) => index.name));
}

async function addIndex(queryInterface, tableName, fields, options) {
  if ((await indexNames(queryInterface, tableName)).has(options.name)) return;
  await queryInterface.addIndex(tableName, fields, options);
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'Events', 'waitlistCapacity'))) {
      await queryInterface.addColumn('Events', 'waitlistCapacity', {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: false,
        defaultValue: 0,
      });
    }
    if (!(await columnExists(queryInterface, 'Events', 'waitlistEnabled'))) {
      await queryInterface.addColumn('Events', 'waitlistEnabled', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      });
    }

    if (await tableExists(queryInterface, 'EventRegistrations')) {
      await queryInterface.changeColumn('EventRegistrations', 'status', {
        type: Sequelize.ENUM('registered', 'promoted', 'cancelled'),
        allowNull: false,
        defaultValue: 'registered',
      });
    }

    if (!(await tableExists(queryInterface, 'EventWaitlist'))) {
      await queryInterface.createTable('EventWaitlist', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        eventId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Events', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
        status: { type: Sequelize.ENUM('waiting', 'promoted', 'left'), allowNull: false, defaultValue: 'waiting' },
        joinedAt: { type: Sequelize.DATE, allowNull: false },
        endedAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'EventWaitlist', ['eventId', 'userId'], { unique: true, name: 'event_waitlist_event_user_unique' });
    await addIndex(queryInterface, 'EventWaitlist', ['eventId', 'status', 'joinedAt', 'id'], { name: 'event_waitlist_promotion_order' });
    await addIndex(queryInterface, 'EventWaitlist', ['userId', 'status', 'eventId'], { name: 'event_waitlist_user_lookup' });
  },

  async down(queryInterface, Sequelize) {
    if (await tableExists(queryInterface, 'EventWaitlist')) await queryInterface.dropTable('EventWaitlist');
    if (await tableExists(queryInterface, 'EventRegistrations')) {
      await queryInterface.sequelize.query("UPDATE `EventRegistrations` SET `status` = 'registered' WHERE `status` = 'promoted'");
      await queryInterface.changeColumn('EventRegistrations', 'status', {
        type: Sequelize.ENUM('registered', 'cancelled'),
        allowNull: false,
        defaultValue: 'registered',
      });
    }
    if (await columnExists(queryInterface, 'Events', 'waitlistEnabled')) await queryInterface.removeColumn('Events', 'waitlistEnabled');
    if (await columnExists(queryInterface, 'Events', 'waitlistCapacity')) await queryInterface.removeColumn('Events', 'waitlistCapacity');
  },
};
