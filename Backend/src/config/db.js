const { Sequelize } = require('sequelize');

let sequelize;
async function assertMigrationsApplied(connection) {
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
  const pending = require('../migrations/run').migrationFiles().filter((file) => !applied.has(file));
  if (pending.length) {
    throw new Error(`Pending database migrations: ${pending.join(', ')}`);
  }
}

async function initializeDatabase() {
  try {
    const dbName = process.env.DB_NAME;
    sequelize = new Sequelize(dbName, process.env.DB_USER, process.env.DB_PASS || '', {
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      dialect: 'mysql',
      logging: false,
    });
    await sequelize.authenticate();
    await assertMigrationsApplied(sequelize);
    require('../models').initModels(sequelize);
    console.log(`[Database] Connected to MySQL schema '${dbName}'`);
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
module.exports = { initializeDatabase, getSequelize };
