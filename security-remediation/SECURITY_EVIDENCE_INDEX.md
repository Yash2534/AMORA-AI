# Security Evidence Index

This index records repository evidence only. `PASSED` means the named local command executed successfully; `PARTIAL/BLOCKED` means only some assertions ran or a required local dependency was unavailable; `EXTERNAL` means the repository cannot establish the fact.

| Control | Implementation evidence | Test/evidence name | State |
|---|---|---|---|
| P-01 | `Backend/src/config/seedDefaultAdmin.js`; removed `Backend/scripts/test-db-connect.js`; `.gitignore` | seed/log regression and redacted current-tree scan | PASSED — COMPLETE |
| P-02 | `Backend/src/config/originPolicy.js` | HTTPS/HTTP/unlisted policy and in-process OPTIONS tests | PASSED — COMPLETE |
| P-03 | No deployment configuration proves TLS termination | TLS/certificate/redirect/WSS evidence request | EXTERNAL |
| P-04 | `Backend/src/config/db.js` requires a trusted CA and certificate verification in production | source contract unit PASSED; provider encryption/connection proof EXTERNAL |
| P-05 | backup/restore runbook/checklist | Restore report and timing | EXTERNAL |
| P-06 | media route/controller/storage and removal of `/uploads` static route | authorization/visibility/traversal integration PASSED | IMPLEMENTED; bucket/KMS EXTERNAL |
| P-07/P-22 | canonical privacy requests and export lifecycle | ownership/step-up/expiry/deletion integration PASSED | IMPLEMENTED; KMS/retention/deadline evidence EXTERNAL |
| P-09/P-11/P-42 | release HTTPS guard, secure storage, backup exclusion, signing contract | full Flutter suite 658 pass/14 skip/0 fail; secure-storage 9/9; analyzer exit 1 with 44 issues | P-11 IMPLEMENTED/additional device evidence; P-09/P-42 external artifact |
| P-10 | ignore rules, CI/config and environment separation | current-tree and reachable-history high-confidence path-only scans completed with zero matches; dedicated/build scan pending | PARTIAL |
| P-13 | `securityEventMiddleware`, existing audit/domain sinks, event-family matrix | focused 25/25; DB persistence 20/20; full backend 350/350 | PASSED — COMPLETE; production sink remains P-39 |
| P-14/P-39 | recursive logger/audit redaction | final targeted suite 21/21 PASSED; append-only sink EXTERNAL under P-39 | P-14 COMPLETE; P-39 EXTERNAL |
| P-18 | legacy mutable consent routes retired; consent-event service remains canonical | grant/withdraw/re-consent/ownership tests | DB-BLOCKED; legal approval required |
| P-19/P-21 | account deletion/data maps | seeded lifecycle/residual query | DB-BLOCKED; legal schedule EXTERNAL |
| P-24 | `aiMatchProvider.js` source-proves `LOCAL` and rejects external enablement | `AI_DATA_FLOW_REGISTER.md`; minimization unit tests | source evidence / execution PLANNED |
| P-25 | shared age policy used by mutation paths | exact-18, under-18, future, invalid, malformed and DB mutation cases | IMPLEMENTED; policy approval pending |
| P-27 | private randomized/signature-checked identity storage | identity-verification integration tests | existing; execution PLANNED; liveness/vendor EXTERNAL |
| P-31 | public serializer quantization and coordinate omission | coarse-distance and API/visibility integration PASSED | IMPLEMENTED; Product/Privacy sign-off pending |
| P-32 | authenticated grievance submission/status owner predicate and explicit limiter | anonymous/cross-user/ticket-enumeration/throttle tests | PLANNED; contact/SLA LEGAL/EXTERNAL |
| P-33 | explicit route limiters and bounded trusted proxy | proxy unit PASSED; deterministic route/distributed tests pending | PARTIAL; shared-store EXTERNAL |
| P-34 | token-version increment, refresh deletion and client clear | old access/refresh rejection; Phase 3 full suite | COMPLETE — VERIFIED |
| P-35 | raw SQL review, escaping and allowlists | isolated safe injection regression | COMPLETE — VERIFIED |
| P-36 | API route security matrix and 296-declaration final reconciliation | Phase 4 full backend command: 350 pass, 0 fail/block | IMPLEMENTED; staging header/sign-off evidence pending |
| P-37 | admin permissions/recent MFA and route matrix | admin RBAC/MFA/audit integration PASSED | IMPLEMENTED; operational roster/approval pending |
| P-43 | security CI, vulnerability/release/patch documents | hosted run links, branch-rules export, SBOM | repository artifacts / EXTERNAL settings |
| P-46/P-47 | no provider artifact supplied | independent report and retest | EXTERNAL VAPT |
| P-48/P-49/P-50/P-51 | incident templates/runbooks | approvals, named roster, counsel register, real tabletop | repository artifacts / EXTERNAL |

## Phase 3 database evidence

- `PHASE3_DB_TEST_ENVIRONMENT.md`
- `AMORAA_PHASE3_DATABASE_VALIDATION_REPORT.md`
- `FLUTTER_ANALYZER_TRIAGE.md`
- `evidence/tests/database/phase3-environment-and-migrations.md`
- `evidence/tests/database/phase3-backend-full.md`
- `evidence/tests/database/phase3-control-validation.md`
- `evidence/tests/database/phase3-sql-injection.md`

## Phase 4 evidence

- `SECURITY_EVENT_COVERAGE_MATRIX.md`
- `API_SECURITY_COVERAGE_FINAL.md`
- `PHASE4_MANUAL_EVIDENCE_PACK.md`
- `evidence/tests/phase4/phase4-security-events-and-backend.md`

## Evidence safety

- Secret scans record file/category/count only and never secret values.
- No production endpoint, live customer data, cloud console, store console, or production credential is used.
- A command is listed as passing only when its actual exit code is recorded in the final report.
