# AMORAA Local Test Environment Discovery

Discovery date: 2026-10-09 (Asia/Calcutta)

## Repository and tooling

| Item | Discovered value |
|---|---|
| Repository | `D:\Projects\amora_ai` |
| Branch | `security/amoraa-pending-remediation` |
| HEAD | `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` (dirty remediation worktree) |
| Node.js | 20.19.5 |
| npm | 10.8.2 |
| Flutter | 3.44.6 stable, revision `ee80f08bbf` |
| Dart | 3.12.2 |
| Backend test framework | Node built-in `node:test` runner |
| Flutter test framework | `flutter_test` from the Flutter SDK |
| Root Node dependencies | Present in `node_modules/` |
| Backend Node dependencies | Present in `Backend/node_modules/` |
| Flutter package configuration | Present in `.dart_tool/package_config.json` |
| Docker/Compose test environment | No repository Docker/Compose definition discovered |

## Supported commands

### Repository root

- `npm test` is **not a real test command**; it intentionally exits with “no test specified”. Do not use it as validation.
- Flutter supports `flutter analyze` and `flutter test` directly.

### Backend

- `npm test` → `node --test --test-concurrency=1`
- `npm run test:integration` → selected DB-backed integration files
- `npm run test:admin` → admin catalog/auth/users/management/verification/financial integration files
- Additional targeted test scripts exist for relationships, profile, notifications, phases 3–5, chat and Rose flows.
- No backend lint script is defined.
- The authoritative runner is Node’s built-in test runner. Jest commands previously shown as examples in `RUNTIME_VALIDATION_PLAN.md` are unsupported and must not be used.

## Database and service dependencies

- Backend persistence uses MySQL through Sequelize.
- The configured development database host is loopback, not an external host.
- The configured port is 3306.
- The port was not reachable during discovery; DB-backed integration tests are therefore blocked until a local disposable MySQL test service is available.
- `TEST_DB_NAME` is not explicitly present in the local environment. Integration tests derive a distinct name by appending `_test`, and relevant suites reject a name that equals the application database or lacks `test`.
- Some KYC/financial fixture scripts create and drop databases, but independently require names containing `kyc`, `e2e`, and `test`, or `financial`, `e2e`, and `test`. They are not authorized for execution until a local disposable MySQL service is explicitly prepared.
- Fixed OTP test mode is enabled, delivery is skipped, and restricted live OTP testing is disabled. No SMS/email delivery command is authorized.

## Environment-variable contract

Required backend configuration names include `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, and `ADMIN_JWT_SECRET`. Production-only validation additionally requires database TLS material, a database password, and a valid administrator MFA encryption key. Test-related names include `TEST_DB_NAME`, `TEST_FIXED_OTP_ENABLED`, `TEST_FIXED_OTP`, and `TEST_OTP_SKIP_DELIVERY`.

Only variable names and non-secret classifications were inspected. No credential or secret value was printed or copied into evidence.

## Safe local validation boundary

Authorized locally:

- pure Node unit/configuration tests that do not initialize a database or contact external providers;
- Flutter analyzer and widget/unit tests using installed packages;
- static source/Git scans that do not reveal secret values;
- offline dependency checks when the installed tool supports them;
- reports written below `security-remediation/evidence/tests/`.

Blocked until a local disposable service exists:

- all MySQL-backed integration suites;
- database creation/drop fixtures;
- end-to-end flows needing a running backend/database;
- multi-instance Redis/shared-store rate-limit verification.

Never authorized by this plan: production endpoints, production databases, real accounts/customer data, cloud/provider consoles, production credentials, store consoles, or automatic credential rotation.

## Phase 2 environment update — 2026-10-09

- Docker CLI 29.1.3 is installed, but the Docker Desktop Linux daemon was not running; no cached-image inventory or container could be used.
- No MySQL/MariaDB executable or TCP listener was available. Windows service enumeration was permission-blocked. No service was started and no database was created.
- Flutter/Dart commands hung only inside the restrictive workspace sandbox. Under the approved `flutter` command scope, Flutter 3.44.6 and Dart 3.12.2 ran successfully.
- `flutter doctor -v` completed with Android license and Windows desktop C++ component findings.
- The complete Flutter suite ran successfully: 658 passed, 14 skipped, 0 failed.
- `flutter analyze --no-pub` executed and exited 1 with 44 warnings/info findings.
- Exact disposable MySQL setup guidance is in `LOCAL_MYSQL_TEST_SETUP.md`; it was not executed during this phase.

## Source-report provenance

At initial discovery, `D:\Projects\amora_ai\AMORAA_SECURITY_COMPLIANCE_PENDING_REPORT.md` was absent. Phase 2 restored it from the previously used Downloads copy and verified an exact 69,844-byte SHA-256 match. See `AUTHORITATIVE_REPORT_PROVENANCE.md`.
