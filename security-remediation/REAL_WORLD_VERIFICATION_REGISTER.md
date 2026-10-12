# Real-World Infrastructure Verification Register

No console, deployed endpoint, shared service, production identity, or customer data was accessed. Every status is **BLOCKED — EXTERNAL SYSTEM EVIDENCE REQUIRED**.

| Control | System | Required real-world check | Exact console/environment | Required evidence | Owner | Status |
|---|---|---|---|---|---|---|
| P-03 | API/admin/socket edge | TLS 1.2+, HTTPS/WSS, HTTP redirect, HSTS, trusted proxy, certificate renewal | Staging and production CDN/load balancer/reverse proxy; release device | Sanitized config, protocol scan, redirect/header capture, WSS result, renewal alert | DevOps + Mobile | BLOCKED |
| P-04 | MySQL/storage/KMS | At-rest encryption, CA/hostname TLS, encrypted snapshots | DB provider console and isolated staging connection | Encryption/key export, TLS-required positive and plaintext-negative results, snapshot proof | Infrastructure + DB | BLOCKED |
| P-05 | Backup/DR | Encrypted schedule, separate identity, retention, restore, RPO/RTO | Backup console and isolated recovery environment | Policy export, grants, restore log, integrity checks, measured recovery | DevOps + DB | BLOCKED |
| P-06 | Media storage/CDN | Private access, encryption, app identity, lifecycle deletion, anonymous denial | Production/staging bucket, mount or object gateway | Bucket/ACL/IAM export, anonymous negative result, delete/lifecycle proof | Infrastructure + Backend | BLOCKED |
| P-07 | Privacy export storage | Private encrypted owner-authorized artifacts, expiry/deletion and access logging | Staging export bucket/mount/object gateway, KMS and cleanup scheduler | ACL/IAM/KMS export, cross-user/public negative result, expiry/delete and log proof | Infrastructure + Privacy + Backend | BLOCKED |
| P-08 | KMS/secrets manager | Ownership, separation, IAM, access audit, rotation and recovery | KMS/secrets/IAM consoles | Inventory, policies, access logs and rotation/recovery drill | Infrastructure + Security | BLOCKED |
| P-09/P-42 | Mobile release/signing | Company signing and secret-free hardened binaries | Protected signing service, CI, signed APK/IPA | Signature/build metadata, manifest/entitlements, redacted binary scans | Mobile + Release + Security | BLOCKED |
| P-10 | Secret operations | Environment separation, managed injection, history scan and rotation | Secret manager, Git host and CI | Sanitized inventory/policy, scans, exposure disposition and rotation references | DevOps + Security | BLOCKED |
| P-11 | Mobile transport/storage | HTTPS traffic and platform-backed credential clear/backup behavior | Staging release devices and network/storage inspection | Traffic and lifecycle test evidence | Mobile + Security | BLOCKED |
| P-12/P-14 | Logging platform | Region, retention, time sync, restricted/immutable roles | Log platform/IAM/time service | Configuration exports, access test and retained sample metadata | Security + Legal + DevOps | BLOCKED |
| P-21 | Lifecycle jobs/backups/vendors | Approved retention actions actually execute | Staging DB/files/jobs and vendor consoles | Before/after dummy data evidence, scheduler logs, backup/vendor handling | Privacy + Backend + DevOps | BLOCKED |
| P-23/P-24/P-27 | Vendors/providers | Actual region, subprocessors, retention/training/deletion/liveness settings | Provider contracts and consoles | Executed terms plus sanitized settings evidence | Legal + Procurement + Product | BLOCKED |
| P-29/P-30 | Safety operations | Staffed queues, escalation, repeat-abuse handling and appeals | Moderation/support system | Roster/SLA, sampled dummy cases, metrics and appeal records | Safety + Operations | BLOCKED |
| P-33 | Distributed abuse control | Shared state across instances and correct identity extraction | Multi-instance staging, Redis/shared store, proxy | Deterministic 429 test across nodes, store/proxy config and recovery | Backend + DevOps | BLOCKED |
| P-38 | External accounts | Company ownership, MFA/recovery, least privilege/offboarding | Git/cloud/DNS/DB/stores/analytics/vendor consoles | Signed register and sanitized access exports | Management + IT/Security | BLOCKED |
| P-39 | Audit/monitoring | Append-only restrictions, retention, integrity and alerts | DB roles plus centralized sink/monitoring | Grants, prohibited mutation result, chain result, alert delivery | Security + Backend + DevOps | BLOCKED |
| P-40 | DB network/identity | Private endpoint/firewall, public negative connection, least-privilege identities | Cloud network and DB consoles; approved test vantage | Rules/topology, negative result, grants and review | Database + Infrastructure | BLOCKED |
| P-41 | Play/Apple | Org ownership, current declarations, reviewer flow and URLs | Google Play Console/App Store Connect | Sanitized exports/screenshots and reviewer test | Product + Legal + Release | BLOCKED |
| P-43 | Repository hosting | Branch rules, reviews, required checks, secret/SAST/dependency results | Git hosting and CI | Rules export, run links, SBOM and exception register | Repository admins + Security | BLOCKED |
| P-44 | Deployment pipeline | Protected environment, approval, deploy identity, immutable artifact and rollback | CI/CD/hosting console and staging | Policy exports, release record and rollback drill | Release + DevOps | BLOCKED |
| P-45 | Monitoring/on-call | Required signals, dashboard, delivery and escalation | Monitoring/paging platform and staging | Rules/dashboard export, alert tests, on-call schedule | SRE + Security | BLOCKED |
| P-46/P-47 | Independent test provider | Authorized VAPT and retest against exact candidate | Independent provider environment/evidence store | Signed report, finding register and retest closure | Security + Management | BLOCKED |
| P-51 | Incident exercise | Real participant response and action closure | Approved exercise environment | Dated exercise and verified closure records | Security + Legal + Operations | BLOCKED |

## Phase 4 reconciliation

- P-06 and P-07 now have exact staging/storage capture checklists, but no deployed storage, IAM, encryption, signed-delivery or lifecycle evidence was supplied. Their real-world rows remain blocked.
- P-16/P-22/P-25/P-31/P-36/P-37 now have deterministic manual evidence manifests. No screenshots, release-device captures, staging responses, roster export or approvals were collected.
- P-13 repository event coverage passed. P-39 remains blocked because no production append-only role, centralized sink, retention, clock synchronization or alert-delivery evidence was accessed.
- Production and staging systems were not accessed in Phase 4.

## Phase 7 environment reconciliation

- Device evidence remains blocked: SDK/emulator tooling exists, but no system image, AVD or Android/iOS device exists.
- Release evidence remains blocked: only a debug-signed APK exists; no company-signed APK/AAB/IPA or signing-custody proof exists.
- Staging evidence remains blocked: no exact hostname or test authorization was supplied, so no external URL was probed.
- Identity evidence remains blocked: local synthetic seed tooling exists, but no approved active dummy-user environment, dummy admin roles or MFA device was established.
- Human evidence remains blocked: P-26 and all relevant Product/Privacy/Security/Admin/Operations decisions remain unsigned.
- The exact three staging-primary controls are P-11, P-31 and P-36; none was executed in Phase 7.

Owners should use `STAGING_ACCESS_REQUIRED.md` and `PHASE7_HUMAN_EXECUTION_CHECKLIST.md` to supply genuine sanitized evidence. Discovery/setup documents do not close any row in this register.

## Phase 8 infrastructure readiness reconciliation — 2026-10-12

- The exact infrastructure-primary controls are P-03, P-04, P-05, P-06, P-07, P-08, P-10, P-33, P-39, P-40, P-43, P-44 and P-45.
- Local source/config was rechecked at commit `432950ddf974ee412760e147cf1219cc0b294f0f`; supporting readiness improved, but no deployed/provider evidence was supplied.
- P-07 now has its own explicit register row; this corrects register coverage without changing the 13-control ledger count or status.
- No approved staging hostname, cloud/DB/storage/KMS/logging/monitoring console access, company-signed artifact, dummy account roster or real owner assignment exists.
- Infrastructure controls newly verified complete: **0**. All 13 remain `IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED`.
- Production accessed: **NO**. No external endpoint was probed and no secret, key or customer data was used.

Use `PHASE8_INFRASTRUCTURE_CONTROL_MATRIX.md`, `PHASE8_HUMAN_INFRASTRUCTURE_ACTIONS.md` and `evidence/infrastructure/` for the next authorized evidence collection.

