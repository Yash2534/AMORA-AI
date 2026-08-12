require('../src/config/bootstrapEnv');
const mysql = require('mysql2/promise');

const requiredTables = ['events', 'eventregistrations'];
const retiredTables = ['eventwaitlist', 'eventfeedback', 'eventcheckins', 'eventgroupmessages'];

async function main() {
  const connection = await mysql.createConnection({ host: process.env.DB_HOST, port: Number(process.env.DB_PORT), user: process.env.DB_USER, password: process.env.DB_PASS || '', database: process.env.DB_NAME });
  try {
    const [tables] = await connection.query('SELECT LOWER(TABLE_NAME) name FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()');
    const names = new Set(tables.map((row) => row.name));
    const missing = requiredTables.filter((name) => !names.has(name));
    const remaining = retiredTables.filter((name) => names.has(name));
    const [columns] = await connection.query("SELECT COLUMN_NAME name FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND LOWER(TABLE_NAME)='events'");
    const columnNames = new Set(columns.map((row) => row.name));
    if (missing.length || remaining.length || !columnNames.has('organizerId') || columnNames.has('hostId')) {
      throw new Error(`Event schema failed. Missing: ${missing.join(', ') || 'none'}; retired remaining: ${remaining.join(', ') || 'none'}; organizerId: ${columnNames.has('organizerId')}.`);
    }
    console.log('[Schema] Retained event browsing and registration schema verified.');
  } finally { await connection.end(); }
}

main().catch((error) => { console.error(error.message); process.exit(1); });
