# AMORAA Runtime Validation Plan

## Current execution status

**PARTIALLY EXECUTED LOCALLY on 2026-10-09.** The user explicitly authorized safe local development/test execution without production access. Pure backend tests, the backend baseline, targeted Flutter tests, offline npm audits, source scans and syntax checks were attempted. MySQL-backed tests were blocked by loopback port 3306, and Flutter/Dart analysis and post-fix execution hung. Exact evidence is in `AMORAA_LOCAL_RUNTIME_VALIDATION_REPORT.md` and `evidence/tests/`.

## Required safe harness

Before executing any command below, the operator must provide all of the following:

- a disposable copy or read-only mount of this commit;
- outbound network denied, with loopback limited to the isolated test services;
- an empty environment followed by an explicit test-only allowlist;
- dummy credentials and a database whose name unmistakably contains `test`;
- no production endpoints, buckets, queues, keys, customer data, or cloud credentials;
- writes restricted to disposable scratch, test database, and generated coverage directories;
- CPU, memory, process, file-size, and wall-clock limits;
- local dependency caches only, or separately approved dependency installation;
- captured command, commit, environment description, start/end time, exit code, stdout/stderr digest, and artifact path.

## Planned command suites

| Suite | Safe command | Expected evidence | Current result |
|---|---|---|---|
| Backend full regression | `cd Backend; npm test -- --runInBand` | Test log, exit code, coverage if configured | NOT EXECUTED — ENVIRONMENT BLOCKER |
| Backend lint | `cd Backend; npm run lint` only if script exists | Lint log and exit code | NOT EXECUTED — ENVIRONMENT BLOCKER |
| Backend dependency audit | `cd Backend; npm audit --offline --json` if lockfile/cache supports offline operation | Redacted JSON and triage | NOT EXECUTED — ENVIRONMENT BLOCKER |
| Flutter static analysis | `flutter analyze` | Analyzer log and exit code | NOT EXECUTED — ENVIRONMENT BLOCKER |
| Flutter tests | `flutter test` | Test log and exit code | NOT EXECUTED — ENVIRONMENT BLOCKER |
| Flutter dependency review | `flutter pub outdated --offline` where supported | Redacted dependency report | NOT EXECUTED — ENVIRONMENT BLOCKER |
| Secret scan | Approved scanner against tracked files and history, offline rules | Redacted findings; never secret values | NOT EXECUTED — ENVIRONMENT BLOCKER |
| SAST | Approved offline ruleset for JavaScript/Dart | SARIF or redacted report | NOT EXECUTED — ENVIRONMENT BLOCKER |
| SBOM | Repository workflow in `.github/workflows/security.yml` | CycloneDX/SPDX artifact | NOT EXECUTED — ENVIRONMENT BLOCKER |

## Control-level validation matrix

Commands below use the repository’s discovered Node built-in test runner and Flutter tools. For every row, **pass** means the command exits `0` and every stated assertion succeeds; **fail** means a nonzero exit, failed assertion, timeout, crash, unexpected skip, unsafe external connection attempt, or missing required evidence. This common fail rule applies in addition to each row's expected-result assertions.

| Control | Tests/commands to run in safe harness | Fixtures/data | Expected result | Evidence path | Current state |
|---|---|---|---|---|---|
| P-01 | `cd Backend; node --test --test-concurrency=1 test/security-remediation.unit.test.js test/production-hardening.test.js` | Dummy development secret and production env without seed secret | Production seed prohibited; missing dev secret fails; logs contain no credential value | `evidence/tests/backend/security-unit-and-hardening.md` | COMPLETE — VERIFIED |
| P-02 | `cd Backend; node --test --test-concurrency=1 test/security-remediation.unit.test.js test/production-hardening.test.js` | HTTPS allowlist, HTTP origin, unlisted origin | HTTPS succeeds; production HTTP/unlisted origins fail; OPTIONS is correct | `evidence/tests/backend/security-unit-and-hardening.md` | COMPLETE — VERIFIED |
| P-06 | `cd Backend; node --test --test-concurrency=1 test/security-remediation.unit.test.js test/phase2.integration.test.js` | Dummy owners, stranger, blocked and deactivated users; traversal payload | Anonymous/unauthorized/blocked/deactivated/traversal denied; owner succeeds | backend evidence | PARTIAL — PATH TEST PASSED; DB/API TEST BLOCKED |
| P-07 | `cd Backend; node --test --test-concurrency=1 test/privacy-requests.integration.test.js test/security-remediation.unit.test.js` | Two dummy users; expired and downloaded artifacts | Cross-user and expired access denied; expiry/download deletion succeeds | backend evidence | PARTIAL — TTL PASSED; DB/API TEST BLOCKED |
| P-10 | `cd Backend; node --test --test-concurrency=1 test/production-hardening.test.js`; then approved dedicated offline scanner | Empty production secret set; synthetic canary secrets | Startup rejects absent secrets; scanner detects synthetic canaries and output is redacted | secret/dependency evidence | PARTIAL — CURRENT SCAN/OFFLINE AUDIT RUN; HISTORY/DEDICATED SCAN PENDING |
| P-11 | `flutter analyze --no-pub; flutter test --no-pub` | Release HTTPS/HTTP configs; dummy token | HTTP release config fails; token persists only in secure storage and clears on lifecycle events | Flutter evidence | PARTIAL — RUNTIME FAILURE/TOOLCHAIN HANG |
| P-13 | `cd Backend; node --test --test-concurrency=1 test/auth-onboarding.integration.test.js test/admin-auth.integration.test.js test/privacy-requests.integration.test.js` | Anonymous, ordinary user, admin roles | Protected routes reject missing/invalid authentication and unauthorized roles | backend evidence | BLOCKED — LOCAL MYSQL UNAVAILABLE |
| P-14 | `cd Backend; node --test --test-concurrency=1 test/security-remediation.unit.test.js`; then direct-console source inventory | Nested objects/arrays containing synthetic sensitive keys | Every sensitive value is redacted while safe metadata remains; no unsafe direct logging remains | security/static evidence | COMPLETE — VERIFIED |
| P-16 | `cd Backend; node --test --test-concurrency=1 test/admin-permission-catalog.test.js test/admin-auth.integration.test.js test/admin-management.integration.test.js` | Admin roles/permissions | Each route enforces mapped permission; bypass attempts fail | backend evidence | BLOCKED — LOCAL MYSQL UNAVAILABLE |
| P-18 | `cd Backend; node --test --test-concurrency=1 test/consent.integration.test.js test/privacy-withdrawal.integration.test.js` | Two users; grant, withdrawal, re-consent events | Immutable versioned history; cross-user mutation denied; governed feature withdrawal enforced | backend evidence | BLOCKED — LOCAL MYSQL AND LEGAL APPROVAL |
| P-19 | `cd Backend; node --test --test-concurrency=1 test/account-deletion-otp.integration.test.js` | Seeded dummy user with linked model/file records | Approved records deleted/anonymized; retained evidence follows approved policy; no orphaned private files | backend evidence | BLOCKED — LOCAL MYSQL AND LEGAL RETENTION DECISION |
| P-20 | `cd Backend; node --test --test-concurrency=1 test/account-deactivation-reactivation.integration.test.js test/discover-eligibility-policy.test.js test/discover.integration.test.js` | Local and federated dummy users | Discovery/matching/notifications/sessions disabled; secure reactivation path works | backend evidence | BLOCKED — IMPLEMENTATION GAPS AND LOCAL MYSQL |
| P-22 | `cd Backend; node --test --test-concurrency=1 test/privacy-requests.integration.test.js test/privacy-withdrawal.integration.test.js` | Owner, stranger, invalid IDs, state transitions | Ownership enforced; enumeration prevented; valid transitions only; artifacts protected | backend evidence | BLOCKED — LOCAL MYSQL |
| P-24 | `cd Backend; node --test --test-concurrency=1 test/ai-matching-service.test.js test/ai-matching.integration.test.js` | Synthetic profile with surplus sensitive fields | Only registered/minimized fields leave provider boundary | backend evidence | DOCUMENT SIGNOFF/PROVIDER EVIDENCE REQUIRED |
| P-25 | `cd Backend; node --test --test-concurrency=1 test/auth-onboarding.integration.test.js test/security-remediation.unit.test.js` | Exactly 18, one day under, future, invalid, malformed | Exactly 18 accepted; all prohibited values rejected on every mutation path | backend evidence | PARTIAL — UNIT PASSED; DB MUTATION PATHS BLOCKED |
| P-26 | After adding the missing test: `cd Backend; node --test --test-concurrency=1 test/phone-lifecycle.integration.test.js test/auth-onboarding.integration.test.js` | Reused number, changed number, deleted account, OTP states | Verified ownership required; stale number/session links revoked; reuse policy enforced | backend evidence | BLOCKED — IMPLEMENTATION GAPS AND LOCAL MYSQL |
| P-27 | `cd Backend; node --test --test-concurrency=1 test/identity-verification.integration.test.js test/admin-verification-decisions.integration.test.js` | Valid images, spoofed MIME, oversized, traversal, unauthorized/admin role cases | Strict validation, randomized private storage, authorization, cleanup and role checks pass | backend evidence | BLOCKED — LOCAL MYSQL, LEGAL, AND VENDOR EVIDENCE |
| P-31 | `cd Backend; node --test --test-concurrency=1 test/location-distance.integration.test.js test/discover.integration.test.js test/security-remediation.unit.test.js` | Exact coordinates, blocked/deactivated/deleted users | Public responses/logs omit exact coordinates; visibility restrictions pass | backend evidence | PARTIAL — HELPER PASSED; DB/API TESTS BLOCKED |
| P-32 | `cd Backend; node --test --test-concurrency=1 test/privacy-requests.integration.test.js test/security-remediation.unit.test.js` | Owner, stranger, guessed ID/token, throttled client | No enumeration or PII leak; only owner/strong token succeeds; throttling works | backend evidence | BLOCKED — LOCAL MYSQL AND LEGAL REVIEW |
| P-33 | `cd Backend; node --test --test-concurrency=1 test/security-remediation.unit.test.js test/production-hardening.test.js test/otp-delivery-safety.test.js` | Fake clock and isolated store | Per-policy limits and trusted-proxy behavior are deterministic; production shared-store absence fails/warns as designed | backend evidence | PARTIAL — PROXY PASSED; ROUTE/DISTRIBUTED EVIDENCE REQUIRED |
| P-34 | `cd Backend; node --test --test-concurrency=1 test/change-password.integration.test.js` | Two sessions and old refresh token | Token/session version increments; existing refresh sessions revoked; old refresh rejected | backend evidence | BLOCKED — LOCAL MYSQL |
| P-35 | `cd Backend; node --test --test-concurrency=1 test/security-remediation.unit.test.js test/discover.integration.test.js test/ai-matching.integration.test.js` | Injection strings in values/order/dynamic identifiers | Values remain bound; identifiers/directions allowlisted; behavior preserved | backend evidence | BLOCKED — LOCAL MYSQL |
| P-36 | `cd Backend; npm test` | Matrix-derived anonymous, cross-user, invalid-ID, invalid-schema and error cases | Every mapped route enforces schema/auth/ownership/rate/error policy | backend evidence | PARTIAL — 113 PASSED; 243 DB-BLOCKED |
| P-37 | `cd Backend; node --test --test-concurrency=1 test/admin-auth.integration.test.js test/admin-management.integration.test.js test/admin-permission-catalog.test.js test/admin-safety.integration.test.js` | Admin roles, stale/fresh MFA, high-risk actions | No route bypass; high-risk actions require mapped MFA; redacted audit events recorded | backend evidence | BLOCKED — LOCAL MYSQL |
| P-39 | `cd Backend; node --test --test-concurrency=1 test/admin-auth.integration.test.js test/admin-management.integration.test.js test/security-remediation.unit.test.js` | Synthetic security/admin actions | Required events are complete/redacted; production sink immutability/retention must be proven separately | backend evidence | PARTIAL — REDACTION PASSED; DB/PRODUCTION EVIDENCE REQUIRED |
| P-42 | `flutter analyze --no-pub; flutter test --no-pub test/android_permissions_test.dart test/production_release_acceptance_test.dart` followed by a non-secret release artifact inspection | Release variant with external signing placeholders | No debug signing/flags/cleartext; backup/export rules intentional; external company key still required | Flutter evidence | BLOCKED — FLUTTER TOOLCHAIN AND COMPANY SIGNING KEY REQUIRED |
| P-43 | Execute each pinned command from `.github/workflows/security.yml` in a local isolated runner | Test commit with synthetic finding | Backend, Flutter, secret, dependency, SAST and SBOM jobs produce expected gates | local evidence and repository-host export | PARTIAL — LOCAL AUDITS RUN; HOST SETTINGS/WORKFLOW EVIDENCE REQUIRED |
| P-48 | No target code command; complete the review fields in `docs/security/INCIDENT_RESPONSE_PLAN.md` and `docs/security/INCIDENT_EVIDENCE_CHECKLIST.md` | Management-approved scenario and assigned roles | Plan fields are approved and usable; actual drill remains P-51 | `evidence/manual/P-48-review.md` | BLOCKED — MANAGEMENT APPROVAL REQUIRED |

## Recording rule

A validator must replace no status in this plan without attaching the complete evidence bundle. A failed, skipped, timed-out, unavailable, or partially executed command is not a pass. Logs must be redacted before storage and must never contain live secrets or customer data.
