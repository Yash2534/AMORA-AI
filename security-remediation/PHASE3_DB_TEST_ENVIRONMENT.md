# Phase 3 Local Database Test Environment

Date: 2026-10-09 (Asia/Kolkata)  
Branch: `security/amoraa-pending-remediation`  
Commit at validation start: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9`

## Safety boundary

- Production accessed: **NO**.
- Staging accessed: **NO**.
- Customer data used: **NO**.
- Database endpoint: loopback `127.0.0.1:3306` only.
- Runtime: local XAMPP MariaDB 10.4.32; no existing application database was reused.
- Test database: `amoraa_security_test`; application-name placeholder: `amoraa_security_test_base`.
- Test account: `amoraa_test_runner`; its process-local random password was never printed or committed.
- Grants are limited to schemas matching `amoraa_security_test%`. Schema-create privileges are required because integration suites create isolated suffix schemas.

The local MariaDB listener is a developer-machine service, not production evidence. It was reached only through loopback for this validation.

## Repository-derived configuration

- Dialect: MySQL through Sequelize/mysql2.
- Test runner: Node built-in `node:test` with `--test-concurrency=1`.
- Node: v20.19.5; npm: 10.8.2.
- Required environment: `NODE_ENV=test`, `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`, `TEST_DB_NAME`, and dummy test-only signing/configuration values.
- Parallel execution is unsafe because several suites reuse the base schema and global in-process limiters; the package script is deliberately serial.
- Migrations are repository migrations from `Backend/src/migrations/run.js`; no hand-created tables or production dump was used.
- Tests manage synthetic fixtures and use suffix databases for migration-sensitive suites.

## Destructive-operation guard

`Backend/src/migrations/run.js` now rejects test database operations unless `NODE_ENV=test` and the database name contains `test`. The regression `test database operations require NODE_ENV=test and a test-only database name` passed.

## Initialization and health

- `npm run db:migrate`: exit 0; all repository migrations applied through `202610090002-add-privacy-grievance-admin-permissions.js`.
- `npm run db:migrate:status`: exit 0; every migration reported `up`.
- Smallest DB test: `node --test --test-concurrency=1 test/match-recommendation-migration.test.js`: 1 pass, 0 fail.
- Post-run database check selected `amoraa_security_test`, observed nine test-prefixed schemas, and found zero synthetic users matching the test email domains in the base schema.

The isolated database and test-prefixed schemas were retained for repeatable local validation. The two exact temporary `amoraa_test_runner` host accounts were removed after testing; a future run must create a fresh process-local credential. No evidence contains the password.
