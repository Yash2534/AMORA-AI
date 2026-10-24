require('dotenv').config();
const mysql = require('mysql2/promise');

const ROWS = 10000;
const BATCH = 1000;

function config() {
  const name = String(process.env.DB_NAME || '');
  if (!name || /prod/i.test(name)) throw new Error('Refusing S2 evidence run without an explicitly non-production DB_NAME.');
  return {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASS || '',
    database: name,
  };
}

async function insertRows(connection, table, columns, factory) {
  for (let start = 1; start <= ROWS; start += BATCH) {
    const values = [];
    for (let id = start; id < start + BATCH && id <= ROWS; id += 1) values.push(factory(id));
    await connection.query(`INSERT INTO ${table} (${columns.join(',')}) VALUES ?`, [values]);
  }
}

function walk(value, result = { accessTypes: [], keys: [], estimatedRows: [], actualRows: [], filesort: false, temporary: false }) {
  if (!value || typeof value !== 'object') return result;
  if (value.access_type) result.accessTypes.push(value.access_type);
  if (value.key) result.keys.push(value.key);
  if (value.rows != null) result.estimatedRows.push(Number(value.rows));
  if (value.r_rows != null) result.actualRows.push(Number(value.r_rows));
  if (value.filesort) result.filesort = true;
  if (value.temporary_table) result.temporary = true;
  for (const child of Object.values(value)) walk(child, result);
  return result;
}

async function explain(connection, sql) {
  const [rows] = await connection.query(`EXPLAIN FORMAT=JSON ${sql}`);
  const parsed = JSON.parse(rows[0].EXPLAIN);
  const summary = walk(parsed);
  let analyze = null;
  try {
    const [actualRows] = await connection.query(`ANALYZE FORMAT=JSON ${sql}`);
    const actual = JSON.parse(actualRows[0].ANALYZE || actualRows[0].EXPLAIN);
    const actualSummary = walk(actual);
    analyze = {
      accessTypes: [...new Set(actualSummary.accessTypes)],
      keys: [...new Set(actualSummary.keys)],
      estimatedRows: actualSummary.estimatedRows,
      actualRows: actualSummary.actualRows,
      filesort: actualSummary.filesort,
      temporary: actualSummary.temporary,
    };
  } catch (error) {
    analyze = { unsupported: true, reason: error.code || error.name };
  }
  return {
    accessTypes: [...new Set(summary.accessTypes)],
    keys: [...new Set(summary.keys)],
    estimatedRows: summary.estimatedRows,
    actualRows: summary.actualRows,
    filesort: summary.filesort,
    temporary: summary.temporary,
    analyze,
  };
}

async function main() {
  const connection = await mysql.createConnection(config());
  try {
    const [[server]] = await connection.query('SELECT VERSION() AS version, DATABASE() AS databaseName');
    await connection.query('CREATE TEMPORARY TABLE s2_profiles (id INT PRIMARY KEY, userId INT NOT NULL, onboardingCompleted TINYINT NOT NULL, birthDate DATE, matchLatitude DECIMAL(9,6), matchLongitude DECIMAL(9,6)) ENGINE=InnoDB');
    await connection.query('CREATE TEMPORARY TABLE s2_users (id INT PRIMARY KEY, accountStatus VARCHAR(20), createdAt DATETIME NOT NULL) ENGINE=InnoDB');
    await connection.query('CREATE TEMPORARY TABLE s2_matches (id INT PRIMARY KEY, userOneId INT, userTwoId INT, matchedAt DATETIME NOT NULL) ENGINE=InnoDB');
    await connection.query('CREATE TEMPORARY TABLE s2_subscriptions (id INT PRIMARY KEY, status VARCHAR(20), createdAt DATETIME NOT NULL) ENGINE=InnoDB');
    await connection.query('CREATE TEMPORARY TABLE s2_reports (id INT PRIMARY KEY, status VARCHAR(20), createdAt DATETIME NOT NULL) ENGINE=InnoDB');
    await connection.query('CREATE TEMPORARY TABLE s2_privacy (id BIGINT PRIMARY KEY, userId INT, requestedAt DATETIME NOT NULL) ENGINE=InnoDB');

    await insertRows(connection, 's2_profiles', ['id', 'userId', 'onboardingCompleted', 'birthDate', 'matchLatitude', 'matchLongitude'], (id) => [id, id, 1, `19${80 + (id % 20)}-01-01`, 8 + (id % 2800) / 100, 68 + ((id * 17) % 2800) / 100]);
    await insertRows(connection, 's2_users', ['id', 'accountStatus', 'createdAt'], (id) => [id, id % 10 ? 'active' : 'deactivated', new Date(Date.UTC(2024 + (id % 3), id % 12, (id % 27) + 1))]);
    await insertRows(connection, 's2_matches', ['id', 'userOneId', 'userTwoId', 'matchedAt'], (id) => [id, id, id + 1, new Date(Date.UTC(2025, id % 12, (id % 27) + 1))]);
    await insertRows(connection, 's2_subscriptions', ['id', 'status', 'createdAt'], (id) => [id, id % 4 ? 'active' : 'expired', new Date(Date.UTC(2025, id % 12, (id % 27) + 1))]);
    await insertRows(connection, 's2_reports', ['id', 'status', 'createdAt'], (id) => [id, ['open', 'reviewing', 'resolved', 'dismissed'][id % 4], new Date(Date.UTC(2025, id % 12, (id % 27) + 1))]);
    await insertRows(connection, 's2_privacy', ['id', 'userId', 'requestedAt'], (id) => [id, (id % 100) + 1, new Date(Date.UTC(2025, id % 12, (id % 27) + 1))]);

    const cases = [
      { name: 'discovery_bounding_box', table: 's2_profiles', index: 'CREATE INDEX s2_profile_location ON s2_profiles(matchLatitude,matchLongitude,userId)', sql: "SELECT id FROM s2_profiles WHERE matchLatitude BETWEEN 18 AND 20 AND matchLongitude BETWEEN 72 AND 74 AND onboardingCompleted=1 AND birthDate BETWEEN '1980-01-01' AND '2008-01-01' LIMIT 500" },
      { name: 'user_registration_range', table: 's2_users', index: 'CREATE INDEX s2_users_created ON s2_users(createdAt,id)', sql: "SELECT DATE(createdAt),COUNT(*) FROM s2_users WHERE createdAt BETWEEN '2026-01-01' AND '2026-12-31' GROUP BY DATE(createdAt) ORDER BY DATE(createdAt)" },
      { name: 'admin_match_chronology', table: 's2_matches', index: 'CREATE INDEX s2_matches_time ON s2_matches(matchedAt,id)', sql: 'SELECT id,userOneId,userTwoId FROM s2_matches ORDER BY matchedAt DESC,id DESC LIMIT 20' },
      { name: 'subscription_chronology', table: 's2_subscriptions', index: 'CREATE INDEX s2_subscriptions_time ON s2_subscriptions(createdAt,id)', sql: 'SELECT id,status FROM s2_subscriptions ORDER BY createdAt DESC,id DESC LIMIT 20' },
      { name: 'moderation_status_queue', table: 's2_reports', index: 'CREATE INDEX s2_reports_status_time ON s2_reports(status,createdAt,id)', sql: "SELECT id FROM s2_reports WHERE status='open' ORDER BY createdAt DESC,id DESC LIMIT 20" },
      { name: 'privacy_user_history', table: 's2_privacy', index: 'CREATE INDEX s2_privacy_user_time ON s2_privacy(userId,requestedAt,id)', sql: 'SELECT id FROM s2_privacy WHERE userId=42 ORDER BY requestedAt DESC,id DESC LIMIT 20' },
    ];

    const results = [];
    for (const item of cases) {
      const before = await explain(connection, item.sql);
      await connection.query(item.index);
      const after = await explain(connection, item.sql);
      results.push({ name: item.name, syntheticRows: ROWS, before, after });
    }
    console.log(JSON.stringify({ generatedAt: new Date().toISOString(), server: { version: server.version }, dataset: { synthetic: true, persisted: false, rowsPerTable: ROWS }, results }, null, 2));
  } finally {
    await connection.end();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
