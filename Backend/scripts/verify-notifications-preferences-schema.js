require('../src/config/bootstrapEnv');
const mysql = require('mysql2/promise');

const requiredTables = [
  'notifications',
  'notificationpreferences',
  'discoverfilterpreferences',
];
const requiredNotificationColumns = [
  'id',
  'userId',
  'actorUserId',
  'type',
  'category',
  'title',
  'message',
  'isRead',
  'readAt',
  'data',
  'deletedAt',
  'createdAt',
  'updatedAt',
];
const requiredNotificationIndexes = [
  'notifications_inbox_order',
  'notifications_unread_lookup',
  'notifications_actor_user_id',
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
    const [tables] = await connection.query(
      'SELECT LOWER(TABLE_NAME) name FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()',
    );
    const tableSet = new Set(tables.map((row) => row.name));
    const missingTables = requiredTables.filter((name) => !tableSet.has(name));

    const [columns] = await connection.query(
      "SELECT COLUMN_NAME name FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME)='notifications'",
    );
    const columnSet = new Set(columns.map((row) => row.name));
    const missingColumns = requiredNotificationColumns.filter((name) => !columnSet.has(name));

    const [indexes] = await connection.query(
      "SELECT DISTINCT INDEX_NAME name FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME)='notifications'",
    );
    const indexSet = new Set(indexes.map((row) => row.name));
    const missingIndexes = requiredNotificationIndexes.filter((name) => !indexSet.has(name));

    const [foreignKeys] = await connection.query(
      "SELECT COLUMN_NAME columnName, REFERENCED_TABLE_NAME referencedTable, REFERENCED_COLUMN_NAME referencedColumn FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME)='notifications' AND REFERENCED_TABLE_NAME IS NOT NULL",
    );
    const foreignKeySet = new Set(foreignKeys.map((row) => `${row.columnName}->${row.referencedTable}.${row.referencedColumn}`.toLowerCase()));
    const requiredForeignKeys = new Set(['userid->users.id', 'actoruserid->users.id']);
    const [rows] = await connection.query(
      'SELECT COUNT(*) notificationCount, SUM(CASE WHEN isRead = 0 AND deletedAt IS NULL THEN 1 ELSE 0 END) unreadCount FROM Notifications',
    );

    if (
      missingTables.length ||
      missingColumns.length ||
      missingIndexes.length ||
      foreignKeys.length !== 2 ||
      [...requiredForeignKeys].some((value) => !foreignKeySet.has(value))
    ) {
      throw new Error(
        `Notification/preferences schema verification failed. Missing tables: ${missingTables.join(', ') || 'none'}; missing columns: ${missingColumns.join(', ') || 'none'}; missing indexes: ${missingIndexes.join(', ') || 'none'}; notification foreign keys: ${[...foreignKeySet].join(', ') || 'none'}.`,
      );
    }

    console.log(
      `[Schema] Notifications/preferences verified: ${requiredTables.length} tables, ${requiredNotificationColumns.length} notification columns, ${requiredNotificationIndexes.length} indexes, 2 foreign keys. Persisted notifications: ${rows[0].notificationCount}; unread active: ${rows[0].unreadCount || 0}.`,
    );
  } finally {
    await connection.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
