# Local MySQL Test Setup — Not Executed

## Discovered blocker

At `2026-10-09T12:10:03+05:30`, no `mysql`, `mysqld`, or `mariadb` executable was available, no listener accepted connections at `127.0.0.1:3306`, Windows service enumeration was permission-blocked, and Docker Desktop's Linux daemon was not running. No database software was installed or started and no database was created.

Backend tests use MySQL through Sequelize. `Backend/src/migrations/run.js` validates database identifiers, creates missing databases, creates `SequelizeMeta`, and applies ordered migrations. Integration tests require a distinct `TEST_DB_NAME` containing `test`; several suites append their own suffix. The test identity therefore needs database-create privileges only inside a disposable local test server.

## Approved disposable Docker option

Run only after a human starts/approves Docker Desktop and approves the image. Use a new non-production password supplied locally; do not commit it.

```powershell
docker run --rm --name amoraa-mysql-test -p 127.0.0.1:3307:3306 -e MYSQL_ROOT_PASSWORD='<LOCAL_TEST_ONLY_PASSWORD>' -e MYSQL_DATABASE='amoraa_phase2_test' mysql:8.4
```

In a separate PowerShell session, set process-local values and run the suite:

```powershell
$env:NODE_ENV='test'
$env:DB_HOST='127.0.0.1'
$env:DB_PORT='3307'
$env:DB_USER='root'
$env:DB_PASS='<LOCAL_TEST_ONLY_PASSWORD>'
$env:DB_NAME='amoraa_phase2_test'
$env:TEST_DB_NAME='amoraa_phase2_test'
$env:TEST_FIXED_OTP_ENABLED='true'
$env:TEST_OTP_SKIP_DELIVERY='true'
$env:LIVE_TEST_OTP_ENABLED='false'
npm test
```

Working directory for `npm test`: `D:\Projects\amora_ai\Backend`.

## Safety conditions

- Bind only to loopback.
- Use a disposable container and a unique test-only password.
- Confirm both `DB_NAME` and `TEST_DB_NAME` contain `test` before execution.
- Do not point these variables at production, staging, shared development, or any existing developer account database.
- Do not use real user fixtures or provider credentials.
- Preserve the test output before stopping the container; `--rm` removes the container when stopped.
- If a non-container local MySQL server is used, create a dedicated test-only instance/identity with access limited to databases prefixed `amoraa_phase2_test`; do not reuse an application or production identity.
