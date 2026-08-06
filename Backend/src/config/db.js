const mysql = require('mysql2/promise');
const { Sequelize } = require('sequelize');

let sequelize;
async function initializeDatabase() {
  const config = { host: process.env.DB_HOST, port: Number(process.env.DB_PORT), user: process.env.DB_USER, password: process.env.DB_PASS || '' };
  let connection;
  try {
    connection = await mysql.createConnection(config);
    const dbName = process.env.DB_NAME;
    const escapedName = `\`${dbName.replace(/`/g, '``')}\``;
    await connection.query(`CREATE DATABASE IF NOT EXISTS ${escapedName}`);
    await connection.end();
    sequelize = new Sequelize(dbName, config.user, config.password, { host: config.host, port: config.port, dialect: 'mysql', logging: false });
    await sequelize.authenticate();
    require('../models').initModels(sequelize);
    await sequelize.sync();
    console.log(`[Database] Connected to MySQL, schema '${dbName}' ready`);
    return sequelize;
  } catch (error) {
    if (connection) await connection.end().catch(() => {});
    console.error('[Database] Could not connect to MySQL. Check that MySQL is running and verify DB_HOST/DB_USER/DB_PASS/DB_NAME in .env.');
    throw error;
  }
}
function getSequelize() { if (!sequelize) throw new Error('Database has not been initialized.'); return sequelize; }
module.exports = { initializeDatabase, getSequelize };
