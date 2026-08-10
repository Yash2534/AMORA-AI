const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const { Sequelize, DataTypes } = require('sequelize');

const migrationsDirectory = __dirname;
const migrationPattern = /^\d{12,}-[a-z0-9-]+\.js$/i;

function migrationFiles() {
  return fs.readdirSync(migrationsDirectory)
    .filter((name) => migrationPattern.test(name))
    .sort();
}

function databaseName(value = process.env.DB_NAME) {
  if (!/^[A-Za-z0-9_]+$/.test(value || '')) {
    throw new Error('DB_NAME may contain only letters, numbers, and underscores.');
  }
  return value;
}

async function ensureDatabase(name) {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASS || '',
  });
  try {
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${name}\``);
  } finally {
    await connection.end();
  }
}

async function createSequelize(name = databaseName()) {
  await ensureDatabase(name);
  const sequelize = new Sequelize(name, process.env.DB_USER, process.env.DB_PASS || '', {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    dialect: 'mysql',
    logging: false,
  });
  await sequelize.authenticate();
  return sequelize;
}

async function ensureMetaTable(queryInterface) {
  const tables = await queryInterface.showAllTables();
  if (tables.some((table) => String(table).toLowerCase() === 'sequelizemeta')) return;
  await queryInterface.createTable('SequelizeMeta', {
    name: { type: DataTypes.STRING, allowNull: false, primaryKey: true },
  });
}

async function appliedMigrations(sequelize) {
  const [rows] = await sequelize.query('SELECT `name` FROM `SequelizeMeta` ORDER BY `name`');
  return rows.map((row) => row.name);
}

async function migrate(options = {}) {
  const name = databaseName(options.databaseName);
  const sequelize = options.sequelize || await createSequelize(name);
  const ownsConnection = !options.sequelize;
  try {
    const queryInterface = sequelize.getQueryInterface();
    await ensureMetaTable(queryInterface);
    const applied = new Set(await appliedMigrations(sequelize));
    const pending = migrationFiles().filter((file) => !applied.has(file));
    for (const file of pending) {
      const migration = require(path.join(migrationsDirectory, file));
      await migration.up(queryInterface, Sequelize);
      await queryInterface.bulkInsert('SequelizeMeta', [{ name: file }]);
      if (!options.quiet) console.log(`[Migration] Applied ${file}`);
    }
    return pending;
  } finally {
    if (ownsConnection) await sequelize.close();
  }
}

async function undo(options = {}) {
  const name = databaseName(options.databaseName);
  const sequelize = options.sequelize || await createSequelize(name);
  const ownsConnection = !options.sequelize;
  try {
    const queryInterface = sequelize.getQueryInterface();
    await ensureMetaTable(queryInterface);
    const applied = await appliedMigrations(sequelize);
    const file = applied.at(-1);
    if (!file) return null;
    const migration = require(path.join(migrationsDirectory, file));
    await migration.down(queryInterface, Sequelize);
    await queryInterface.bulkDelete('SequelizeMeta', { name: file });
    if (!options.quiet) console.log(`[Migration] Reverted ${file}`);
    return file;
  } finally {
    if (ownsConnection) await sequelize.close();
  }
}

async function status(options = {}) {
  const name = databaseName(options.databaseName);
  const sequelize = options.sequelize || await createSequelize(name);
  const ownsConnection = !options.sequelize;
  try {
    const queryInterface = sequelize.getQueryInterface();
    await ensureMetaTable(queryInterface);
    const applied = new Set(await appliedMigrations(sequelize));
    return migrationFiles().map((file) => ({ file, status: applied.has(file) ? 'up' : 'down' }));
  } finally {
    if (ownsConnection) await sequelize.close();
  }
}

async function main() {
  require('../config/bootstrapEnv');
  require('../config/env');
  const command = process.argv[2] || 'up';
  if (command === 'up') await migrate();
  else if (command === 'down') await undo();
  else if (command === 'status') {
    for (const item of await status()) console.log(`${item.status.padEnd(4)} ${item.file}`);
  } else {
    throw new Error(`Unknown migration command: ${command}`);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = { createSequelize, migrate, undo, status, migrationFiles };
