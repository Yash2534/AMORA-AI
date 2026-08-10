require('../src/config/bootstrapEnv');
require('../src/config/env');
const { createSequelize } = require('../src/migrations/run');

const expectedTables = [
  'Conversations',
  'ConversationParticipants',
  'Messages',
  'MessageMedia',
];
const expectedIndexes = [
  'conversations_pair_key_unique',
  'conversations_activity',
  'conversation_participants_conversation_user_unique',
  'conversation_participants_user_conversation',
  'messages_conversation_id',
  'messages_conversation_sender_id',
  'message_media_message_id',
];

async function main() {
  const sequelize = await createSequelize();
  try {
    const [tables] = await sequelize.query(
      `SELECT TABLE_NAME AS tableName
       FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN (:tables)`,
      { replacements: { tables: expectedTables } },
    );
    const [indexes] = await sequelize.query(
      `SELECT DISTINCT INDEX_NAME AS indexName
       FROM information_schema.STATISTICS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN (:tables)`,
      { replacements: { tables: expectedTables } },
    );
    const [foreignKeys] = await sequelize.query(
      `SELECT CONSTRAINT_NAME AS constraintName
       FROM information_schema.REFERENTIAL_CONSTRAINTS
       WHERE CONSTRAINT_SCHEMA = DATABASE()
         AND TABLE_NAME IN (:tables)`,
      { replacements: { tables: expectedTables } },
    );
    const tableNames = new Set(tables.map((row) => row.tableName.toLowerCase()));
    const indexNames = new Set(indexes.map((row) => row.indexName));
    const missingTables = expectedTables.filter(
      (name) => !tableNames.has(name.toLowerCase()),
    );
    const missingIndexes = expectedIndexes.filter((name) => !indexNames.has(name));
    if (missingTables.length || missingIndexes.length || foreignKeys.length !== 7) {
      throw new Error(JSON.stringify({ missingTables, missingIndexes, foreignKeyCount: foreignKeys.length }));
    }
    console.log(`[Schema] Chat tables=${tables.length}, required indexes=${expectedIndexes.length}, foreign keys=${foreignKeys.length}`);
  } finally {
    await sequelize.close();
  }
}

main().catch((error) => {
  console.error(`[Schema] Chat verification failed: ${error.message}`);
  process.exit(1);
});
