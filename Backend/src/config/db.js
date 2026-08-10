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
    console.error('[Database] Could not connect to MySQL. Run migrations and verify DB_HOST/DB_USER/DB_PASS/DB_NAME.');
    throw error;
  }
}
function getSequelize() { if (!sequelize) throw new Error('Database has not been initialized.'); return sequelize; }
module.exports = { initializeDatabase, getSequelize };
