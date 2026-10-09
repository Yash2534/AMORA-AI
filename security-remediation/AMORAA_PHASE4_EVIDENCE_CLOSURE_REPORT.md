# AMORAA Phase 4 P0 Evidence Closure Report

Date: 2026-10-09  
Branch: `security/amoraa-pending-remediation`  
Baseline commit: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` plus uncommitted remediation worktree  
Production/staging/cloud/customer data accessed: **NO**

## Executive result

P-13 is newly **COMPLETE — VERIFIED**. The repository now has an authoritative security-event family matrix and shared event coverage implemented through the existing hash-chained, recursively sanitized audit architecture. Focused tests and a database persistence assertion pass, followed by the complete backend suite: **350 passed, 0 failed, 0 skipped, 0 blocked**.

P-06, P-07, P-16, P-22, P-25, P-31, P-36 and P-37 were not falsely closed. Their local proof is separated from exact manual, staging, infrastructure, product, legal and management evidence requirements. Total COMPLETE increases from 5 to 6. P0 becomes **6 complete / 29 open**.

Recommendation: **READY FOR NEXT SECURITY VALIDATION STAGE — NOT PRODUCTION READY**.

## 1. P-13 result

Final status: **COMPLETE — VERIFIED** for repository security-event coverage.

- Added `Backend/src/middleware/securityEventMiddleware.js` and mounted it before bounded JSON parsing so rejected malformed/oversized sensitive requests can also retain correlation and audit coverage.
- Reused `AdminAuditLogs`/`recordAudit`; no duplicate logging framework or raw request-body capture was introduced.
- Covered user login/logout, OTP request/verification, password reset/change/session activity, account lifecycle, privacy lifecycle, grievances, reports, block/unblock, identity submission, admin mutations/sensitive reads, rate limits, privilege/authorization denials.
- Existing admin auth/MFA/role/permission/domain audit calls and immutable domain event models remain authoritative supporting evidence.
- Correlation ID, actor/target, request IP, bounded user agent, outcome/status and optional one-way device reference are captured.
- Passwords, OTPs, tokens, cookies, MFA material, identity content and export content are omitted or recursively redacted.
- Production centralized ingestion, append-only DB role, retention, time synchronization and alert delivery remain P-39 **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED**.

Evidence: `SECURITY_EVENT_COVERAGE_MATRIX.md`, `evidence/tests/phase4/phase4-security-events-and-backend.md`, `security-remediation.unit.test.js`, `change-password.integration.test.js`.

## 2–9. Named control evidence state

| Control | Proven now | Not proven / owner / next proof | Final status |
|---|---|---|---|
| P-06 | Protected profile/chat/identity authorization, block/inactive rules, traversal/type/size controls; local runtime pass | Infrastructure/Backend must prove deployed private storage, IAM/encryption, direct anonymous denial, signed-delivery expiry if used, lifecycle | **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED** |
| P-07 | Canonical owner-scoped step-up export, allowlisted fields, private local artifact, expiry/consume/delete; local runtime pass | Infrastructure proves deployed encrypted private storage/KMS; Product/Privacy/Legal approve fields/retention | **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED** |
| P-16 | Contextual permission service, Android system-picker path, manifest/iOS purpose source and Flutter tests | Mobile/Product/Privacy run signed release devices; decide fine location and `READ_MEDIA_IMAGES` necessity; approve purpose map | **IMPLEMENTED — MANUAL EVIDENCE REQUIRED** |
| P-22 | Auth/ownership/cross-user/status/step-up/export/correction/withdrawal local lifecycle | Privacy Operations runs staging E2E; Legal approves deadline/SLA and erasure/retention workflow | **IMPLEMENTED — MANUAL EVIDENCE REQUIRED** |
| P-25 | Shared server policy and exact-age/underage/future/invalid/mutation/discovery runtime proof | Mobile/Product runs Android/iOS journey; Product/Legal approves underage outcome policy | **IMPLEMENTED — MANUAL EVIDENCE REQUIRED** |
| P-31 | No public coordinates, coarse distance, blocked/deactivated/deleted exclusion locally | Product/Privacy/Security inspect staging UI/API/export/logs and test triangulation; decide incognito requirement | **IMPLEMENTED — STAGING EVIDENCE REQUIRED** |
| P-36 | 305 concrete route patterns reconciled; 279 protected/credential-bound, 26 intentionally public, 0 known active high-risk auth gaps; full regression pass | Backend/Security/DevOps capture staging headers, proxy identity, payload/error/CORS behavior and sign release matrix | **IMPLEMENTED — STAGING EVIDENCE REQUIRED** |
| P-37 | Admin session, origin, RBAC, MFA/fresh step-up, audit and destructive paths pass; generic missing-event coverage added | Security/Admin owner/Management run staging role tests, supply named roster/company ownership and approve destructive governance | **IMPLEMENTED — MANUAL EVIDENCE REQUIRED** |

## 10. New code changes

- `Backend/src/middleware/securityEventMiddleware.js`: bounded event catalog/classifier, denied/rate-limit coverage, correlation and sanitized persistence.
- `Backend/src/server.js`: global event middleware registration.
- `Backend/test/security-remediation.unit.test.js`: critical family, denial/rate-limit/admin and hashed-device tests.
- `Backend/test/change-password.integration.test.js`: correlated DB persistence and password non-disclosure assertion.

## 11. New tests

- `security-event classifier covers critical lifecycle events without copying request bodies`
- `security-event classifier records rate limits and denied sensitive/admin access`
- `security-event device references are bounded one-way hashes`
- Password-change integration now asserts `user.auth.password_changed` persistence, success outcome/actor and absence of both passwords.

## 12. Tests executed

| Command | Exit | Result |
|---|---:|---|
| focused security/hardening test pair | 0 | 25 passed |
| initial affected DB suite | 1 | One new test assertion assumed object JSON; event was present; corrected without weakening requirement |
| focused DB/security rerun | 0 | 20 passed |
| `npm test` | 0 | 350 passed, 0 failed/skipped/blocked; 215643.9692 ms |
| `npm test` (final post-middleware-order regression) | 0 | 350 passed, 0 failed/skipped/blocked; 180319.7669 ms |
| `git diff --check` | 0 | No whitespace errors; line-ending warnings only |
| initial syntax batch | aggregate 0 after later commands | One subcommand used nonexistent `server.js`; explicitly not counted as pass |
| corrected fail-fast syntax batch using `src/server.js` | 0 | Four changed JavaScript files parse successfully |

## 13. Documents created

- `SECURITY_EVENT_COVERAGE_MATRIX.md`
- `PERMISSION_PURPOSE_MATRIX.md`
- `API_SECURITY_COVERAGE_FINAL.md`
- `PHASE4_MANUAL_EVIDENCE_PACK.md`
- `evidence/manual/P06_MEDIA_VERIFICATION_CHECKLIST.md`
- `evidence/manual/P07_PRIVACY_EXPORT_VERIFICATION_CHECKLIST.md`
- `evidence/manual/P22_RIGHTS_REQUEST_E2E.md`
- `evidence/manual/P25_AGE_GATE_MANUAL_TEST.md`
- `evidence/manual/P31_LOCATION_PRIVACY_VERIFICATION.md`
- `evidence/manual/P37_ADMIN_MANUAL_VERIFICATION.md`
- Eight deterministic control evidence manifests under `evidence/manual/P-06/` through `P-37/`
- `evidence/tests/phase4/phase4-security-events-and-backend.md`

## 14–15. Remaining manual and infrastructure evidence

Manual/staging evidence is pending for P-09, P-11, P-16, P-22, P-25, P-31, P-36 and P-37. Phase 4 generated capture instructions but did not populate reviewer, date or artifacts.

Primary infrastructure-evidence controls: P-03, P-04, P-05, P-06, P-07, P-08, P-10, P-33, P-39, P-40, P-43, P-44 and P-45. No console or deployed endpoint was accessed.

## 16. Controls newly COMPLETE

- P-13 only.

Total COMPLETE — VERIFIED: P-01, P-02, P-13, P-14, P-34 and P-35 (**6**).

## 17. Remaining P0 blockers

- Repository gaps: P-20 provider-neutral deactivation reauthentication and P-26 phone change/reassignment/recycled-number lifecycle (both P1, still material release work).
- P0 infrastructure/manual/staging blockers include TLS, DB/storage encryption, backup restore, KMS, private deployed media/export storage, secret operations, mobile release/device proof, distributed rate limiting, DB network controls, signing and monitoring.
- P0 legal blockers remain P-12, P-15, P-17, P-18, P-19, P-21, P-27 and P-50; related P1 legal controls remain P-23 and P-32.
- Management blockers include moderation/staffing, account ownership, signing/store readiness, incident approvals/owners and a completed tabletop.
- P-46 independent VAPT and P-47 independent retest remain **BLOCKED — EXTERNAL VAPT**.

## 18. Exact next human actions

1. Backend/Security: review and sign the 305-pattern API and P-13 event matrices at an immutable release commit.
2. Mobile/Product/Privacy: execute P-16/P-25/P-31 device checklists with synthetic data and attach deterministic sanitized artifacts.
3. Backend/Privacy Operations: execute P-06/P-07/P-22 staging checklists with dummy users/files; attach only redacted metadata.
4. Infrastructure/DevOps: supply P-06/P-07 storage IAM/encryption/lifecycle and P-39 append-only sink/retention/alert proof.
5. Admin owner/Management: run P-37 wrong-role/allowed-role/MFA/session/audit checks and provide a sanitized named-account roster/governance decision.
6. Legal: approve purposes, underage behavior, rights deadlines, retention/deletion, grievance/identity/vendor and current regulatory interpretations; no legal conclusion is inferred here.
7. Independent assessor: perform P-46 VAPT on the exact candidate and P-47 retest after remediation.

## Final counts

- Complete: 6
- Manual evidence required: 5
- Staging evidence required: 3
- Infrastructure evidence required: 13
- Repository gaps: 2
- Legal blocked: 10
- Management blocked: 10
- External VAPT blocked: 2
- P0: 6 complete / 29 open
- P1: 0 complete / 15 open
- P2: 0 complete / 1 open

Production recommendation: **READY FOR NEXT SECURITY VALIDATION STAGE — NOT PRODUCTION READY**.
