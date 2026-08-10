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
    if (!(await columnExists(queryInterface, 'Users', 'role'))) {
      await queryInterface.addColumn('Users', 'role', {
        type: Sequelize.ENUM('user', 'host', 'admin'),
        allowNull: false,
        defaultValue: 'user',
      });
    }

    if (!(await tableExists(queryInterface, 'Events'))) {
      await queryInterface.createTable('Events', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        title: { type: Sequelize.STRING(160), allowNull: false },
        description: { type: Sequelize.TEXT, allowNull: false },
        category: { type: Sequelize.STRING(80), allowNull: false },
        city: { type: Sequelize.STRING(100), allowNull: false },
        venueName: { type: Sequelize.STRING(160), allowNull: false },
        address: { type: Sequelize.STRING(255), allowNull: true },
        latitude: { type: Sequelize.DECIMAL(10, 7), allowNull: true },
        longitude: { type: Sequelize.DECIMAL(10, 7), allowNull: true },
        startDateTime: { type: Sequelize.DATE, allowNull: false },
        endDateTime: { type: Sequelize.DATE, allowNull: false },
        capacity: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        waitlistCapacity: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        status: { type: Sequelize.ENUM('draft', 'published', 'cancelled', 'completed'), allowNull: false, defaultValue: 'draft' },
        visibility: { type: Sequelize.ENUM('public', 'private'), allowNull: false, defaultValue: 'public' },
        registrationOpen: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        waitlistEnabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        heroImageUrl: { type: Sequelize.STRING(500), allowNull: true },
        hostId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        price: { type: Sequelize.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
        dressCode: { type: Sequelize.STRING(120), allowNull: true },
        minAge: { type: Sequelize.INTEGER.UNSIGNED, allowNull: true },
        maxAge: { type: Sequelize.INTEGER.UNSIGNED, allowNull: true },
        language: { type: Sequelize.STRING(160), allowNull: true },
        agenda: { type: Sequelize.JSON, allowNull: true },
        facilities: { type: Sequelize.JSON, allowNull: true },
        interests: { type: Sequelize.JSON, allowNull: true },
        checkInOpensAt: { type: Sequelize.DATE, allowNull: true },
        checkInClosesAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'Events', ['status', 'visibility', 'startDateTime', 'id'], { name: 'events_browse_order' });
    await addIndex(queryInterface, 'Events', ['category', 'city', 'startDateTime'], { name: 'events_filter_lookup' });
    await addIndex(queryInterface, 'Events', ['hostId', 'startDateTime'], { name: 'events_host_order' });

    if (!(await tableExists(queryInterface, 'EventRegistrations'))) {
      await queryInterface.createTable('EventRegistrations', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        eventId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Events', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
        status: { type: Sequelize.ENUM('registered', 'promoted', 'cancelled'), allowNull: false, defaultValue: 'registered' },
        registeredAt: { type: Sequelize.DATE, allowNull: false },
        cancelledAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'EventRegistrations', ['eventId', 'userId'], { unique: true, name: 'event_registrations_event_user_unique' });
    await addIndex(queryInterface, 'EventRegistrations', ['eventId', 'status'], { name: 'event_registrations_capacity_lookup' });
    await addIndex(queryInterface, 'EventRegistrations', ['userId', 'status', 'eventId'], { name: 'event_registrations_user_lookup' });

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

    if (!(await tableExists(queryInterface, 'EventFeedback'))) {
      await queryInterface.createTable('EventFeedback', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        eventId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Events', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        rating: { type: Sequelize.TINYINT.UNSIGNED, allowNull: false },
        venueRating: { type: Sequelize.TINYINT.UNSIGNED, allowNull: true },
        hostRating: { type: Sequelize.TINYINT.UNSIGNED, allowNull: true },
        safetyRating: { type: Sequelize.TINYINT.UNSIGNED, allowNull: true },
        experienceRating: { type: Sequelize.TINYINT.UNSIGNED, allowNull: true },
        feedbackText: { type: Sequelize.TEXT, allowNull: true },
        recommend: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'EventFeedback', ['eventId', 'userId'], { unique: true, name: 'event_feedback_event_user_unique' });

    if (!(await tableExists(queryInterface, 'EventCheckIns'))) {
      await queryInterface.createTable('EventCheckIns', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        eventId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Events', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        checkedInAt: { type: Sequelize.DATE, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'EventCheckIns', ['eventId', 'userId'], { unique: true, name: 'event_checkins_event_user_unique' });

    if (!(await tableExists(queryInterface, 'EventGroupMessages'))) {
      await queryInterface.createTable('EventGroupMessages', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        eventId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Events', key: 'id' }, onDelete: 'CASCADE', onUpdate: 'CASCADE' },
        senderId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'RESTRICT', onUpdate: 'CASCADE' },
        type: { type: Sequelize.ENUM('text'), allowNull: false, defaultValue: 'text' },
        text: { type: Sequelize.TEXT, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'EventGroupMessages', ['eventId', 'id'], { name: 'event_group_messages_history' });
    await addIndex(queryInterface, 'EventGroupMessages', ['senderId', 'createdAt'], { name: 'event_group_messages_sender' });
  },

  async down() {
    // Event, participation, safety feedback, and chat records are retained on
    // rollback so production data is never destructively removed.
  },
};
