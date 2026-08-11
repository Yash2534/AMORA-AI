"use strict";

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..", "..");
const backend = path.join(root, "Backend");
process.chdir(backend);
require(path.join(backend, "src", "config", "bootstrapEnv"));
require(path.join(backend, "src", "config", "env"));
const { Sequelize } = require(path.join(backend, "node_modules", "sequelize"));

async function main() {
  const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASS || "",
    {
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      dialect: "mysql",
      logging: false,
    },
  );

  try {
    await sequelize.authenticate();
    const replacements = { schema: process.env.DB_NAME };
    const [tables] = await sequelize.query(
      `SELECT TABLE_NAME AS tableName, TABLE_ROWS AS estimatedRows
       FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = :schema
       ORDER BY TABLE_NAME`,
      { replacements },
    );
    const [columns] = await sequelize.query(
      `SELECT TABLE_NAME AS tableName, COLUMN_NAME AS columnName,
              COLUMN_TYPE AS columnType, IS_NULLABLE AS isNullable,
              COLUMN_DEFAULT AS columnDefault, COLUMN_KEY AS columnKey,
              EXTRA AS extra
       FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = :schema
       ORDER BY TABLE_NAME, ORDINAL_POSITION`,
      { replacements },
    );
    const [indexes] = await sequelize.query(
      `SELECT TABLE_NAME AS tableName, INDEX_NAME AS indexName,
              NON_UNIQUE AS nonUnique, SEQ_IN_INDEX AS sequence,
              COLUMN_NAME AS columnName
       FROM information_schema.STATISTICS
       WHERE TABLE_SCHEMA = :schema
       ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX`,
      { replacements },
    );
    const [foreignKeys] = await sequelize.query(
      `SELECT TABLE_NAME AS tableName, CONSTRAINT_NAME AS constraintName,
              COLUMN_NAME AS columnName, REFERENCED_TABLE_NAME AS referencedTable,
              REFERENCED_COLUMN_NAME AS referencedColumn
       FROM information_schema.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = :schema AND REFERENCED_TABLE_NAME IS NOT NULL
       ORDER BY TABLE_NAME, CONSTRAINT_NAME, ORDINAL_POSITION`,
      { replacements },
    );
    const [migrations] = await sequelize.query(
      "SELECT name FROM SequelizeMeta ORDER BY name",
    );

    const tableDetails = [];
    const queryGenerator = sequelize.getQueryInterface().queryGenerator;
    for (const table of tables) {
      const quotedTable = queryGenerator.quoteTable(table.tableName);
      const [countRows] = await sequelize.query(
        `SELECT COUNT(*) AS exactRows FROM ${quotedTable}`,
      );
      tableDetails.push({
        ...table,
        exactRows: Number(countRows[0].exactRows),
        columns: columns.filter((column) => column.tableName === table.tableName),
        indexes: indexes.filter((index) => index.tableName === table.tableName),
        foreignKeys: foreignKeys.filter((key) => key.tableName === table.tableName),
      });
    }
    const output = {
      database: process.env.DB_NAME,
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      tableCount: tableDetails.length,
      tables: tableDetails,
      appliedMigrations: migrations.map((row) => row.name),
      environmentCapabilities: {
        nodeEnv: process.env.NODE_ENV || "development",
        googleAuthConfigured: Boolean(
          (process.env.GOOGLE_CLIENT_IDS || "")
            .split(",")
            .map((value) => value.trim())
            .filter((value) => value && value !== "skip-for-now").length,
        ),
        smsConfigured: Boolean(
          process.env.SMS_PROVIDER &&
            process.env.TWILIO_ACCOUNT_SID &&
            process.env.TWILIO_AUTH_TOKEN &&
            process.env.TWILIO_FROM_NUMBER,
        ),
        smtpConfigured: ["EMAIL_HOST", "EMAIL_USER", "EMAIL_PASS"].every(
          (key) => Boolean(process.env[key]),
        ),
        razorpayConfigured: Boolean(
          process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET,
        ),
      },
    };
    const outputPath = path.join(root, "tmp", "project_audit", "mysql_schema.json");
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, JSON.stringify(output, null, 2), "utf8");
    console.log(
      JSON.stringify(
        {
          database: output.database,
          tableCount: output.tableCount,
          appliedMigrationCount: output.appliedMigrations.length,
          environmentCapabilities: output.environmentCapabilities,
          tableNames: output.tables.map((table) => table.tableName),
        },
        null,
        2,
      ),
    );
  } finally {
    await sequelize.close();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
