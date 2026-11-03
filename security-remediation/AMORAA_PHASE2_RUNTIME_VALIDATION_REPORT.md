# AMORAA Phase 2 Runtime Validation Report

Validation date: 2026-10-09 (Asia/Calcutta)  
Branch: `security/amoraa-pending-remediation`  
Commit inspected: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9`  
Production accessed: **NO**

## 1. Outcome

Phase 2 removed the local Flutter execution blocker and produced a successful complete Flutter test run. It did not remove the backend database blocker because this computer has no running local MySQL/MariaDB service and Docker Desktop's daemon is stopped. No runtime was installed or started and no database was created.

No new control satisfies all source-report exit criteria. P-11 improved from `PARTIAL — RUNTIME FAILURE` to `IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED`. Actual complete remains **3 of 51**.

## 2. Authoritative report

`AMORAA_SECURITY_COMPLIANCE_PENDING_REPORT.md` was restored from the previously used Downloads copy. Both files are 69,844 bytes and have SHA-256 `A06F1410368B19A0D22C05AFA1F1765EF180EC3992AB24258A5816B4B5FFDC98`. See `AUTHORITATIVE_REPORT_PROVENANCE.md`.

## 3. Local database discovery

- `mysql`, `mysqld`, and `mariadb`: unavailable on PATH.
- `127.0.0.1:3306`: no TCP listener.
- Windows MySQL/MariaDB service enumeration: permission-blocked; no service was started.
- Docker CLI: 29.1.3 installed.
- Docker Desktop Linux daemon: unavailable (`dockerDesktopLinuxEngine` named pipe absent).
- Database creation/migrations/fixtures: **NOT EXECUTED**.

The backend uses MySQL/Sequelize. `Backend/src/migrations/run.js` safely validates identifiers, creates the named database, maintains `SequelizeMeta`, and applies ordered migrations. Tests enforce a distinct database name containing `test` and some append suite-specific suffixes. Exact disposable setup is documented in `LOCAL_MYSQL_TEST_SETUP.md`.

## 4. Commands actually executed

The command ledger includes diagnostic attempts because unexecuted or interrupted commands are not reported as passes.

| Command | Result |
|---|---|
| Git branch/commit/status and source/target SHA-256 | completed |
| MySQL/MariaDB command, service and port discovery | no runtime/listener; service query permission-blocked |
| `docker version` / `docker image ls` | CLI present; daemon unavailable |
| restricted-sandbox Flutter/Dart diagnostic attempts | no output; interrupted |
| three restricted-sandbox targeted Flutter attempts | no output; interrupted |
| `flutter --version` | exit 0 |
| `flutter doctor -v` | exit 0; two toolchain categories need attention |
| secure-storage targeted Flutter test | exit 0; 9 pass |
| two guessed, nonexistent Flutter test paths | exit 1 command errors; no tests ran |
| production-release acceptance test | exit 0; 5 pass |
| Android permission test, initial | exit 1; 11 pass/1 stale expectation fail |
| Android permission test, final | exit 0; 12 pass |
| `flutter analyze --no-pub` | exit 1; 44 issues |
| `flutter test --no-pub --timeout 30s` | exit 0; 658 pass/14 skip/0 fail |
| Backend `npm test` | exit 1; 114 pass/243 DB-hook failures |
| redacted current-tree and Git-history secret scan | exit 0; zero high-confidence path matches |

## 5. Flutter result

Flutter 3.44.6 and Dart 3.12.2 are functional. The earlier hang was caused by the restrictive workspace sandbox. The complete suite passed 658 tests, skipped 14 opt-in QA evidence captures, and failed none.

The Android permission regression initially expected `READ_MEDIA_VIDEO`, although the application uses the system picker and the hardened manifest intentionally removed that unused permission. The test expectation was narrowed; it now proves the smaller approved permission set and passes 12/12. This is a least-privilege correction, not a weakened test.

Analyzer exit 1 remains recorded: 44 warnings/info issues, primarily unused imports/elements/variables and style/lifecycle diagnostics. No duplicate `didUpdateWidget` compilation error remains.

## 6. Backend result

The supported command `npm test` ran from `Backend` using Node's built-in test runner with concurrency 1:

- total 357;
- passed 114;
- failed 243;
- skipped 0;
- duration 51.722 seconds;
- exit code 1.

Database-backed suites consistently failed in setup at `ensureDatabase` with `connect EACCES 127.0.0.1:3306`. Secondary teardown errors do not establish product defects because setup never completed. The 114 passing pure/unit cases include the previously verified P-01, P-02 and P-14 assertions. No failed database-backed control was upgraded.

## 7. Secret scan

A path-only scan covered the current tree (including remediation documents) and reachable Git history. High-confidence private-key, AWS, GitHub, OpenAI-style, Google API, and Slack token categories returned zero matching paths. Values were never printed.

Dedicated scanners are not installed. Build artifacts, external secret stores, credential rotation/revocation and low-entropy/context-specific secrets remain outside this evidence. P-10 remains implemented/additional-evidence.

## 8. Re-evaluation of the 13 implemented controls

| Control | Phase 2 result | Final status | Remaining proof |
|---|---|---|---|
| P-06 | Backend authorization suite DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | API owner/stranger/blocked/deactivated tests; storage infrastructure |
| P-07 | Backend export lifecycle suite DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | cross-user/expiry/deletion runtime; storage/KMS/retention |
| P-10 | Current/history high-confidence scan completed | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | dedicated/build scan; secret manager and rotation |
| P-11 | Full Flutter suite passed | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | staging traffic capture and Android/iOS release-device checks |
| P-13 | Event/auth integration DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | event-family integration evidence |
| P-16 | Admin authorization integration DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | RBAC/permission runtime evidence |
| P-22 | Rights-request suite DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | ownership/state/artifact runtime and approved SLA |
| P-25 | Boundary unit evidence retained; mutation APIs DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | signup/onboarding/profile/import runtime paths |
| P-31 | Serializer unit retained; visibility APIs DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | exact-coordinate negative and blocked/deactivated API tests |
| P-34 | Password/session integration DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | old access/refresh rejection runtime proof |
| P-35 | Static review retained; injection runtime DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | isolated query/injection fixtures |
| P-36 | Full suite attempted; database routes blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | matrix-derived auth/IDOR/validation runtime tests |
| P-37 | Admin integration DB-blocked | IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED | role/MFA/audit runtime plus operational roster review |

Controls newly complete: **0**. Controls still needing local database runtime: **11**. P-10 and P-11 need non-database supporting/manual evidence.

## 9. Status counts after Phase 2

- COMPLETE — VERIFIED: 3
- IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED: 13
- PARTIAL — RUNTIME FAILURE: 0
- PARTIAL — REMEDIATION STILL REQUIRED: 2
- DOCUMENT COMPLETE — SIGNOFF REQUIRED: 2
- BLOCKED — INFRASTRUCTURE EVIDENCE: 10
- BLOCKED — MANUAL VERIFICATION: 1
- BLOCKED — LEGAL VERIFICATION: 10
- BLOCKED — MANAGEMENT/OPERATIONS: 8
- BLOCKED — INDEPENDENT VAPT: 2

Priority counts are unchanged: P0 complete 3/35 (32 open), P1 complete 0/15 (15 open), P2 complete 0/1 (1 open).

### P0 reconciliation

- P0 COMPLETE: 3 — P-01, P-02, P-14.
- P0 runtime-verified but external/manual evidence pending: 1 — P-11.
- P0 runtime failure: 0.
- P0 repository/additional local validation pending: 10 — P-06, P-07, P-10, P-13, P-16, P-25, P-31, P-34, P-35, P-37.
- P0 manual/signoff pending: 2 — P-09, P-48.
- P0 legal pending: 8 — P-12, P-15, P-17, P-18, P-19, P-21, P-27, P-50.
- P0 infrastructure pending: 6 — P-03, P-04, P-05, P-08, P-33, P-40.
- P0 management/operations pending: 3 — P-29, P-38, P-42.
- P0 independent VAPT pending: 2 — P-46, P-47.

These buckets are mutually exclusive and sum to all 35 P0 controls. P-11's local Flutter runtime is verified, but its source-report exit criteria still require staging traffic and release-device evidence.

## 10. External and manual state

No manual register row was verified. All 31 manual checks remain unverified. No TLS, encryption-at-rest, KMS, backup restore, centralized logging, firewall, production monitoring, signing/store-console, branch protection, deployment pipeline, legal approval, staffing, named incident ownership, tabletop, independent VAPT or VAPT retest evidence was supplied or inferred.

## 11. Evidence paths

- `AUTHORITATIVE_REPORT_PROVENANCE.md`
- `LOCAL_MYSQL_TEST_SETUP.md`
- `evidence/tests/backend-full/phase2-backend-full.md`
- `evidence/tests/flutter-final/phase2-flutter-final.md`
- `evidence/tests/secrets/phase2-path-only-scan.md`
- `AMORAA_ACTUAL_VERIFICATION_STATUS.md`
- `AMORAA_SECURITY_REAL_VERIFICATION_REPORT.md`
- `PRODUCTION_SECURITY_RELEASE_GATE.md`

## 12. Production readiness

**NOT PRODUCTION READY.**

Recommendation: **READY FOR NEXT SECURITY VALIDATION STAGE**. The immediate next local step is an explicitly approved disposable MySQL runtime followed by the full backend suite. External, legal, management, manual, signing/device and independent VAPT gates remain mandatory.
