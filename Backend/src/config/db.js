const fs = require('fs');
const path = require('path');
const { Sequelize } = require('sequelize');
const { databasePoolConfig, databaseQueryTimeoutMs, migrationStartupMode } = require('./scalability');

async function rawQuery(connection, sql) {
  if (typeof connection.promise === 'function') return connection.promise().query(sql);
  return new Promise((resolve, reject) => connection.query(sql, (error, rows) => (error ? reject(error) : resolve([rows]))));
}

async function configureStatementTimeout(connection, timeoutMs) {
  if (!timeoutMs) return;
  const [rows] = await rawQuery(connection, 'SELECT VERSION() AS version');
  const version = String(rows?.[0]?.version || '');
  if (/mariadb/i.test(version)) {
    await rawQuery(connection, `SET SESSION max_statement_time = ${timeoutMs / 1000}`);
  } else {
    await rawQuery(connection, `SET SESSION MAX_EXECUTION_TIME = ${timeoutMs}`);
  }
}

function databaseDialectOptions(env = process.env) {
  if (env.NODE_ENV !== 'production') return {};
  const caFile = String(env.DB_SSL_CA_FILE || '').trim();
  if (!caFile) throw new Error('Production requires DB_SSL_CA_FILE for verified database TLS.');
  const resolved = path.resolve(caFile);
  return {
    ssl: {
      ca: fs.readFileSync(resolved, 'utf8'),
      rejectUnauthorized: true,
    },
  };
}

let sequelize;
async function assertMigrationsApplied(connection, env = process.env) {
  let rows;
  try {
    [rows] = await connection.query('SELECT `name` FROM `SequelizeMeta`');
  } catch (error) {
    if (error.original?.code === 'ER_NO_SUCH_TABLE') {
      throw new Error('Database migrations have not been applied. Run npm run db:migrate.');
    }
    throw error;
  }
  const applied = new Set(rows.map((row) => row.name));
  const runner = require('../migrations/run');
  const pending = runner.migrationFiles().filter((file) => !applied.has(file));
  if (pending.length) {
    if (migrationStartupMode(env) === 'apply') {
      console.log(`[Database] Applying ${pending.length} pending migrations in explicitly configured startup mode.`);
      await runner.migrate({ sequelize: connection });
    } else {
      throw new Error(`Pending database migrations: ${pending.join(', ')}. Run npm run db:migrate as the release step.`);
    }
  }
}

async function initializeDatabase() {
  try {
    const dbName = process.env.DB_NAME;
    const pool = databasePoolConfig(process.env);
    const queryTimeout = databaseQueryTimeoutMs(process.env);
    const metricsEnabled = String(process.env.ENABLE_PERFORMANCE_METRICS || '').toLowerCase() === 'true';
    sequelize = new Sequelize(dbName, process.env.DB_USER, process.env.DB_PASS || '', {
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      dialect: 'mysql',
      dialectOptions: databaseDialectOptions(),
      benchmark: metricsEnabled,
      logging: metricsEnabled
        ? (_sql, milliseconds) => require('../services/performanceMetrics').observe('db_query_duration_ms', milliseconds)
        : false,
      pool,
      hooks: queryTimeout ? {
        afterConnect: (connection) => configureStatementTimeout(connection, queryTimeout),
      } : undefined,
    });
    await sequelize.authenticate();
    await assertMigrationsApplied(sequelize);
    require('../models').initModels(sequelize);
    console.log(`[Database] Connected to MySQL schema '${dbName}'`);
    console.log(`[Database] Pool configured max=${pool.max} min=${pool.min} acquireMs=${pool.acquire} idleMs=${pool.idle}`);
    console.log(`[Database] Statement timeout ${queryTimeout ? `${queryTimeout}ms` : 'disabled'}`);
    const { ensureDefaultAdminAccount } = require('./seedDefaultAdmin');
    await ensureDefaultAdminAccount();
    return sequelize;
  } catch (error) {
    if (sequelize) await sequelize.close().catch(() => {});
    sequelize = undefined;
    const safeCode = String(error.original?.code || error.code || '')
      .replace(/[^A-Z0-9_]/gi, '')
      .slice(0, 80);
    const pendingMessage = String(error.message || '').startsWith('Pending database migrations:')
      ? ` ${error.message}`
      : '';
    console.error(
      `[Database] Startup validation failed.${pendingMessage}`
      + `${safeCode ? ` Database error code: ${safeCode}.` : ''}`
      + ' Run migration status and verify DB_HOST/DB_PORT/DB_NAME/DB_USER.',
    );
    throw error;
  }
}
function getSequelize() { if (!sequelize) throw new Error('Database has not been initialized.'); return sequelize; }
async function closeDatabase() {
  const current = sequelize;
  sequelize = undefined;
  if (current) await current.close();
}
async function databaseReady() {
  if (!sequelize) return false;
  try {
    await sequelize.query('SELECT 1', { raw: true });
    return true;
  } catch (_) {
    return false;
  }
}
module.exports = { initializeDatabase, getSequelize, closeDatabase, databaseReady, databaseDialectOptions, assertMigrationsApplied, configureStatementTimeout };
