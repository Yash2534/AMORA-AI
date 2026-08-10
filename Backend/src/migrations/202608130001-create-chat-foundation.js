async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

async function indexNames(queryInterface, tableName) {
  return new Set((await queryInterface.showIndex(tableName)).map((index) => index.name));
}

async function addIndex(queryInterface, tableName, fields, options) {
  if ((await indexNames(queryInterface, tableName)).has(options.name)) return;
  await queryInterface.addIndex(tableName, fields, options);
}

async function constraintExists(queryInterface, tableName, name) {
  const [rows] = await queryInterface.sequelize.query(
    'SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND CONSTRAINT_NAME = ?',
    { replacements: [tableName, name] },
  );
  return rows.length > 0;
}

async function addForeignKey(queryInterface, tableName, fields, name, references, onDelete) {
  if (await constraintExists(queryInterface, tableName, name)) return;
  await queryInterface.addConstraint(tableName, {
    fields,
    type: 'foreign key',
    name,
    references,
    onDelete,
    onUpdate: 'CASCADE',
  });
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'Conversations'))) {
      await queryInterface.createTable('Conversations', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        pairKey: { type: Sequelize.STRING(64), allowNull: false },
        type: { type: Sequelize.ENUM('direct'), allowNull: false, defaultValue: 'direct' },
        lastMessageId: { type: Sequelize.INTEGER, allowNull: true },
        lastMessageAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'Conversations', ['pairKey'], { unique: true, name: 'conversations_pair_key_unique' });
    await addIndex(queryInterface, 'Conversations', ['lastMessageAt', 'id'], { name: 'conversations_activity' });

    if (!(await tableExists(queryInterface, 'ConversationParticipants'))) {
      await queryInterface.createTable('ConversationParticipants', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        conversationId: { type: Sequelize.INTEGER, allowNull: false },
        userId: { type: Sequelize.INTEGER, allowNull: false },
        lastReadMessageId: { type: Sequelize.INTEGER, allowNull: true },
        lastReadAt: { type: Sequelize.DATE, allowNull: true },
        draftText: { type: Sequelize.TEXT, allowNull: true },
        joinedAt: { type: Sequelize.DATE, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'ConversationParticipants', ['conversationId', 'userId'], { unique: true, name: 'conversation_participants_conversation_user_unique' });
    await addIndex(queryInterface, 'ConversationParticipants', ['userId', 'conversationId'], { name: 'conversation_participants_user_conversation' });

    if (!(await tableExists(queryInterface, 'Messages'))) {
      await queryInterface.createTable('Messages', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        conversationId: { type: Sequelize.INTEGER, allowNull: false },
        senderId: { type: Sequelize.INTEGER, allowNull: false },
        type: { type: Sequelize.ENUM('text', 'image'), allowNull: false, defaultValue: 'text' },
        text: { type: Sequelize.TEXT, allowNull: true },
        context: { type: Sequelize.JSON, allowNull: true },
        deletedAt: { type: Sequelize.DATE, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'Messages', ['conversationId', 'id'], { name: 'messages_conversation_id' });
    await addIndex(queryInterface, 'Messages', ['conversationId', 'senderId', 'id'], { name: 'messages_conversation_sender_id' });

    if (!(await tableExists(queryInterface, 'MessageMedia'))) {
      await queryInterface.createTable('MessageMedia', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        messageId: { type: Sequelize.INTEGER, allowNull: false },
        mediaType: { type: Sequelize.ENUM('image'), allowNull: false, defaultValue: 'image' },
        originalName: { type: Sequelize.STRING, allowNull: false },
        storagePath: { type: Sequelize.STRING, allowNull: false },
        mimeType: { type: Sequelize.STRING(100), allowNull: false },
        sizeBytes: { type: Sequelize.INTEGER, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      });
    }
    await addIndex(queryInterface, 'MessageMedia', ['messageId', 'id'], { name: 'message_media_message_id' });

    await addForeignKey(queryInterface, 'ConversationParticipants', ['conversationId'], 'conversation_participants_conversation_fk', { table: 'Conversations', field: 'id' }, 'CASCADE');
    await addForeignKey(queryInterface, 'ConversationParticipants', ['userId'], 'conversation_participants_user_fk', { table: 'Users', field: 'id' }, 'CASCADE');
    await addForeignKey(queryInterface, 'Messages', ['conversationId'], 'messages_conversation_fk', { table: 'Conversations', field: 'id' }, 'CASCADE');
    await addForeignKey(queryInterface, 'Messages', ['senderId'], 'messages_sender_fk', { table: 'Users', field: 'id' }, 'RESTRICT');
    await addForeignKey(queryInterface, 'MessageMedia', ['messageId'], 'message_media_message_fk', { table: 'Messages', field: 'id' }, 'CASCADE');
    await addForeignKey(queryInterface, 'ConversationParticipants', ['lastReadMessageId'], 'conversation_participants_last_read_message_fk', { table: 'Messages', field: 'id' }, 'SET NULL');
    await addForeignKey(queryInterface, 'Conversations', ['lastMessageId'], 'conversations_last_message_fk', { table: 'Messages', field: 'id' }, 'SET NULL');
  },

  async down() {
    // Conversation and message history is user data and is intentionally
    // retained during rollback. Reapplying this migration is idempotent.
  },
};
