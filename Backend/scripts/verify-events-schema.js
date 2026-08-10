require('../src/config/bootstrapEnv');
const mysql = require('mysql2/promise');

const requiredTables = ['events', 'eventregistrations', 'eventwaitlist', 'eventfeedback', 'eventcheckins', 'eventgroupmessages'];
const requiredIndexes = [
  'events_browse_order', 'events_filter_lookup', 'events_host_order',
  'event_registrations_event_user_unique', 'event_registrations_capacity_lookup',
  'event_waitlist_event_user_unique', 'event_waitlist_promotion_order',
  'event_feedback_event_user_unique', 'event_checkins_event_user_unique',
  'event_group_messages_history',
];

async function main() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME,
  });
  try {
    const [tables] = await connection.query('SELECT LOWER(TABLE_NAME) name FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()');
    const tableSet = new Set(tables.map((row) => row.name));
    const missingTables = requiredTables.filter((name) => !tableSet.has(name));
    const [indexes] = await connection.query("SELECT INDEX_NAME name FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND LOWER(TABLE_NAME) LIKE 'event%'");
    const indexSet = new Set(indexes.map((row) => row.name));
    const missingIndexes = requiredIndexes.filter((name) => !indexSet.has(name));
    const [role] = await connection.query("SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME)='users' AND COLUMN_NAME='role'");
    const [feedbackColumns] = await connection.query("SELECT COLUMN_NAME name FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME)='eventfeedback'");
    const feedbackColumnSet = new Set(feedbackColumns.map((row) => row.name));
    const requiredFeedbackColumns = ['mediaOriginalName', 'mediaStoragePath', 'mediaMimeType', 'mediaSizeBytes'];
    const missingFeedbackColumns = requiredFeedbackColumns.filter((name) => !feedbackColumnSet.has(name));
    const [foreignKeys] = await connection.query("SELECT COUNT(*) count_ FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME) LIKE 'event%' AND REFERENCED_TABLE_NAME IS NOT NULL");
    if (missingTables.length || missingIndexes.length || missingFeedbackColumns.length || !role.length || Number(foreignKeys[0].count_) < 11) {
      throw new Error(`Event schema verification failed. Missing tables: ${missingTables.join(', ') || 'none'}; missing indexes: ${missingIndexes.join(', ') || 'none'}; missing feedback columns: ${missingFeedbackColumns.join(', ') || 'none'}; role: ${role.length ? 'ok' : 'missing'}; foreign keys: ${foreignKeys[0].count_}.`);
    }
    console.log(`[Schema] Events verified: ${requiredTables.length} tables, ${requiredIndexes.length} required indexes, ${foreignKeys[0].count_} foreign keys, Users.role present.`);
  } finally {
    await connection.end();
  }
}

main().catch((error) => { console.error(error.message); process.exit(1); });
