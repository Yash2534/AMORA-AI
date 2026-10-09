# AMORAA Local Runtime Validation Report

Validation date: 2026-10-09 (Asia/Calcutta)

Sections 1–9 preserve the earlier validation history. Section 10 records Phase 3 and is the current state; `AMORAA_PHASE3_DATABASE_VALIDATION_REPORT.md` is the detailed current report.

## 1. Environment discovered

The supported environment is documented in `LOCAL_TEST_ENVIRONMENT_DISCOVERY.md`. Node 20.19.5, npm 10.8.2, Flutter 3.44.6 and Dart 3.12.2 are installed with local dependencies. Backend tests use Node’s built-in test runner. The configured DB host is loopback, but MySQL port 3306 was unreachable. The test suites derive distinct names containing `test`; no production database, API, customer data, cloud resource, provider console or production credential was accessed.

The root `AMORAA_SECURITY_COMPLIANCE_PENDING_REPORT.md` remained absent. The previously supplied Downloads copy was used for original control criteria.

## 2. Commands actually executed

Twenty validation invocations were made, excluding read-only discovery commands: nine completed successfully, five returned nonzero results, and six were interrupted/blocked after hangs or excessive duration. Exact summarized output is stored under `evidence/tests/`.

| Command group | Executions | Final/observed result |
|---|---:|---|
| Backend targeted security/hardening Node tests | 5 | Initial logger defect found and fixed; socket fixture blocked; fixture expectation corrected; final run 21/21 passed |
| Backend `npm test` | 1 | Exit 1: 113 passed; 243 DB setup failures (`EACCES 127.0.0.1:3306`) |
| Flutter/Dart analyzer | 4 | Hung without diagnostics; interrupted and blocked |
| Targeted Flutter tests | 2 | First: 9 passed, 2 files failed to compile due duplicate method; duplicate fixed; post-fix rerun hung |
| Offline npm audits | 2 | Both exit 0; zero advisories in available local cache |
| Current-tree secret scan | 1 | Completed path-only; no high-confidence credential patterns |
| Git-history secret scan | 1 | Partial; 157 commits enumerated, first category produced vendor false positives, remainder stopped for runtime |
| JavaScript syntax scan | 1 | 52 files, zero failures |
| Raw SQL/literal inventory | 1 | 42 files identified; supporting evidence only |
| Origin/seed source scan | 1 | No hardcoded HTTP origin or seed fallback/logging path found |
| Direct console inventory | 1 | No request-body/auth-object console output found; migration CLI raw error remains reviewable |

## 3. Tests passed, failed, skipped and blocked

- Unique passing test cases observed: **123** (114 backend including the newly added preflight case, plus 9 Flutter secure-storage cases).
- Confirmed current security assertion failures remaining: **0**.
- Environment/tooling-blocked test cases/files: **245** (243 backend DB setup failures and 2 Flutter files not successfully rerun after the compile fix).
- Skipped by runners: **0**.
- Analyzer status: **BLOCKED** by repeatable local Flutter/Dart hangs.

Historical failures are not concealed:

1. Logger regression failed, was fixed narrowly, and passed on rerun.
2. Two Flutter files failed to compile because of a duplicate lifecycle method; source was fixed, but the post-fix run hung and is not a pass.
3. The first CORS preflight fixture could not use loopback TCP in the execution environment; the equivalent real middleware assertion was changed to an in-process fixture.
4. One fixture expectation incorrectly required rejected preflights to short-circuit with 204; corrected to assert the actual security property—absence of an allow-origin header.

## 4. Control upgrades

Controls upgraded to **COMPLETE — VERIFIED**:

- **P-01:** explicit development-only admin seed, production disablement, no credential logging, source scan and passing regression.
- **P-02:** production HTTPS allowlist, HTTP/wildcard/unlisted rejection, preflight behavior and no conflicting HTTP exception.
- **P-14:** recursive application/audit redaction and credential-output regression. Production log sink remains P-39, not part of this closure.

Previously implemented/runtime-pending: **16**. Now complete: **3**. Still requiring runtime or additional evidence: **13**.

## 5. Runtime/evidence work still required

- P-06/P-07/P-13/P-16/P-22/P-25/P-31/P-34/P-35/P-36/P-37 require the local disposable MySQL test service and their API/integration suites.
- P-10 requires an approved dedicated secret scanner and complete history/build-artifact coverage.
- P-11 requires successful post-fix Flutter analysis and full tests; it is currently `PARTIAL — RUNTIME FAILURE`.
- P-20 and P-26 still require repository remediation, not merely test execution.

## 6. External, legal, management and VAPT blockers

- Manual verification: P-09 primary, with 31 detailed register entries still pending across controls.
- Infrastructure evidence: 10 primary-status controls.
- Legal verification: 10 controls.
- Management/operations: 8 controls.
- Independent VAPT: P-46 and P-47 remain open.

Local testing did not close TLS deployment, provider encryption, backup restore, KMS, distributed rate limiting, centralized logging, firewall, branch protection, deployment approvals, monitoring, signing/store consoles, legal approvals, staffing, incident assignments, drills or VAPT.

## 7. Evidence paths

- `security-remediation/evidence/tests/backend/security-unit-and-hardening.md`
- `security-remediation/evidence/tests/backend/full-baseline.md`
- `security-remediation/evidence/tests/flutter/baseline.md`
- `security-remediation/evidence/tests/secrets/local-secret-scan.md`
- `security-remediation/evidence/tests/dependencies/offline-audit.md`
- `security-remediation/evidence/tests/static/source-checks.md`

## 8. Production readiness

**NOT PRODUCTION READY.** The repository is ready for the next validation step: provide the isolated local MySQL test service, repair/diagnose the Flutter toolchain, rerun all affected suites, then collect the external/legal/management/VAPT evidence required by the release gate.

## 9. Phase 2 runtime validation — 2026-10-09

Phase 2 resolved the Flutter execution blocker by rerunning the approved `flutter` commands outside the restrictive workspace sandbox. `flutter doctor -v` completed, targeted security tests passed after correcting one stale least-privilege permission expectation, and the complete Flutter suite passed **658 tests with 14 skips and 0 failures**. `flutter analyze --no-pub` executed and exited 1 with 44 existing warnings/info findings.

The complete backend suite was rerun and produced **114 passes and 243 failures**. All 243 failures are rooted in the unavailable local MySQL setup (`connect EACCES 127.0.0.1:3306`); no local MySQL/MariaDB runtime or listener exists and Docker Desktop's daemon was stopped. No database was created or migrated. Exact safe setup instructions are in `LOCAL_MYSQL_TEST_SETUP.md`.

The authoritative pending report was restored byte-for-byte and provenance is in `AUTHORITATIVE_REPORT_PROVENANCE.md`. A redacted high-confidence current-tree and reachable-Git-history scan returned zero path matches. This does not replace a dedicated scanner, artifact scan, secret-manager evidence, or rotation record.

P-11 moved from `PARTIAL — RUNTIME FAILURE` to `IMPLEMENTED — ADDITIONAL EVIDENCE REQUIRED`; staging traffic capture and Android/iOS release-device verification remain required. No new control was marked complete. Current totals remain 3 complete, 48 open. Production was not accessed.

Phase 2 evidence:

- `evidence/tests/backend-full/phase2-backend-full.md`
- `evidence/tests/flutter-final/phase2-flutter-final.md`
- `evidence/tests/secrets/phase2-path-only-scan.md`
- `AMORAA_PHASE2_RUNTIME_VALIDATION_REPORT.md`

## 10. Phase 3 database validation — 2026-10-09

Phase 3 found the running local XAMPP MariaDB service and created an isolated `amoraa_security_test` environment with a dedicated least-scope test principal. Credentials remained process-local and redacted. The repository migration runner now refuses test-intent operations unless `NODE_ENV=test` and the target database name contains `test`.

All migrations applied successfully. The smallest migration suite passed 1/1. The initial full backend run executed 346 cases: 333 passed and 13 failed. Those failures were classified as stale test fixtures plus two application defects (shared OTP limiter buckets and missing owner IDs in protected-media serialization). No failing security assertion was hidden or weakened. After corrections, a focused 52-test run passed and the final full suite passed **347/347**, with zero failures, skips or blocked tests.

P-34 and P-35 are newly COMPLETE — VERIFIED. P-13 remains repository-incomplete because explicit event-family success/failure/correlation coverage is not exhaustive. The other eight members of the eleven-control database plan still require external/manual/legal/staging/device/operational evidence. P-16 was corrected to its source-of-truth meaning—mobile permission minimization; admin RBAC tests do not close it.

`flutter analyze --no-pub` executed again and returned the same 44 warnings/info: 4 functional and 40 style/info, with zero classified as security-relevant. No unrelated Flutter refactor was performed.

Current state: **5 COMPLETE — VERIFIED**, P0 **5 complete / 30 open**, P1 **0 / 15**, P2 **0 / 1**. Production recommendation remains **READY FOR NEXT SECURITY VALIDATION STAGE — NOT PRODUCTION READY**.

Phase 3 evidence:

- `AMORAA_PHASE3_DATABASE_VALIDATION_REPORT.md`
- `PHASE3_DB_TEST_ENVIRONMENT.md`
- `FLUTTER_ANALYZER_TRIAGE.md`
- `evidence/tests/database/`
