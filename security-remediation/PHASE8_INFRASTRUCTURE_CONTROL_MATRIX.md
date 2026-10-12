# Phase 8 Infrastructure Control Matrix

Authoritative ledger date: 2026-10-12 (Asia/Calcutta)  
Reviewed branch/commit: `security/amoraa-pending-remediation` / `432950ddf974ee412760e147cf1219cc0b294f0f`

The exact infrastructure-primary controls are **P-03, P-04, P-05, P-06, P-07, P-08, P-10, P-33, P-39, P-40, P-43, P-44 and P-45**. The list comes from the current mutually exclusive ledger in `AMORAA_ACTUAL_VERIFICATION_STATUS.md`; controls that merely depend on infrastructure are not added to this count.

| Control ID | Requirement | Current implementation | Already verified | External system required | Evidence required | Owner | Local verification possible | Human verification required | Current blocker | Final Phase 8 status |
|---|---|---|---|---|---|---|---|---|---|---|
| P-03 | TLS 1.2+, HTTPS/WSS, redirect, HSTS, certificate lifecycle and trusted proxy | Node serves HTTP behind an expected edge; production Helmet HSTS and explicit trust-proxy parsing exist; Flutter release URL requires HTTPS | Source/config only | DNS, CDN/LB/reverse proxy, certificate manager, staging clients | Protocol/cipher scan, redirect/header/WSS capture, certificate hostname/chain/renewal, proxy export | DevOps | Yes—source/config review | Yes | No approved deployed endpoint or edge export | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-04 | DB TLS and encryption at rest/snapshots | Production requires `DB_SSL_CA_FILE`; Sequelize enables CA validation and `rejectUnauthorized` | Production fail-closed TLS config reviewed | DB provider, KMS, snapshot service | Provider encryption/key export, encrypted snapshot proof, TLS positive and plaintext-negative checks | Cloud/DB owner | Yes—config review | Yes | Provider console and isolated staging DB unavailable | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-05 | Encrypted backups, isolated identity, retention, tested restore, RPO/RTO | Planning/checklist evidence only | No real backup or restore verified | Backup service and isolated recovery target | Schedule/policy, grants, retention, restore log, integrity result, measured RPO/RTO | DevOps/DB | Documentation only | Yes | No backup console, approved objectives or restore target | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-06 | Private encrypted profile, identity and chat media with authorized delivery/deletion | Authenticated profile-media route; randomized local private identity/chat paths; local lifecycle tests | Repository paths/tests only | Staging storage/bucket/CDN/KMS/IAM | Public-access blocks, ACL/IAM, encryption, anonymous denial, signed URL expiry if used, access logs, lifecycle/delete evidence | Backend/Infra | Yes—route/storage review | Yes | Real storage/IAM/CDN proof absent | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-07 | Private encrypted privacy-export artifacts with owner authorization, expiry and deletion | Owner-scoped request/artifact lookup, random key, mode `0600`, max 24-hour TTL, consume/delete and expiry cleanup | Repository paths/tests only | Staging export store, KMS/IAM/logging | Private-access policy, encryption/key, authorization, expiry/delete, access logs, no-public-object result | Backend/Privacy/Infra | Yes—service review | Yes | Deployed store/KMS/logging evidence absent; retention approval pending | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-08 | Managed KMS/secrets manager, least privilege, separation, rotation and recovery | Production configuration consumes injected secrets; MFA key format checked | Interface/config only | KMS, secrets manager and IAM | Inventory without values, policies, workload grants, audit logs, rotation and recovery drill | Security/DevOps | Yes—consumer inventory | Yes | No managed-store or IAM evidence | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-10 | Secret inventory, environment isolation, managed injection, scanning and rotation | Required environment variables; local scans; GitHub Actions gitleaks job defined | Source and prior path-only scans | Secrets manager, Git host and hosted CI | Environment-separated inventory, hosted scan results, exposure disposition, rotation references, workload injection proof | Security/DevOps | Yes—names/config/history checks | Yes | Hosted CI/store/rotation evidence absent | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-33 | Distributed abuse controls with trusted identity extraction and consistent 429 | Route-specific `express-rate-limit`; trust-proxy parser and local route tests | Single-process/config behavior only | Multi-instance staging, shared store, edge proxy and alerting | Shared-store config, proxy topology, cross-node threshold/429, recovery/failure-mode and abuse alert | DevOps/Backend | Yes—policy/source review | Yes | Current code uses default process-local store; no deployed shared store/topology | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-39 | Central audit logging, restricted/append-only sink, retention, time sync and alerts | Sanitized audit events and SHA-256 chain verification exist locally | Event/redaction/persistence tests | Central log sink, IAM, time source, monitoring | Sink config, mutation-negative result, grants, retention, clock sync, ingestion and alert-delivery proof | Security/DevOps | Yes—event/audit source review | Yes | No central/append-only sink or retention/alert evidence | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-40 | Private DB endpoint, firewall/ACL, least-privilege app and backup identities | Env-configured MySQL and verified production TLS | Client config only | Cloud network, DB/IAM consoles and approved test vantage | Topology/rules, public negative test, TLS result, app/backup grants and access review | Cloud/DB owner | Yes—client config review | Yes | Network and grants are external | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-43 | Protected branches, required reviews/checks, SAST/dependency/secret scans and SBOM | `.github/workflows/security.yml` defines gitleaks, npm audit, syntax, tests, Flutter, CodeQL and SBOM jobs | Workflow source only | Git hosting/rulesets and hosted CI | Branch/ruleset export, successful required runs, SBOM artifact, exception/bypass register | Repo admin/Security | Yes—workflow review | Yes | Hosted settings and runs not supplied | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-44 | Approval-gated deployment, restricted identity, immutable artifact and rollback | Process documentation exists; no deployment workflow in repository | Documentation only | CI/CD protected environment and hosting control plane | Environment rules, approver, deploy grants, artifact digest/release record, rollback drill | DevOps/Release | Documentation only | Yes | Real pipeline, approvers and rollback proof absent | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |
| P-45 | Monitoring, alert delivery, on-call ownership and runbooks | Required signals are documented; no platform config is present | Documentation only | Metrics/logging/paging platforms and staging | Dashboard/rule exports, staged alert tests, destinations, rota and linked runbooks | SRE/Security/Management | Documentation only | Yes | Monitoring platform, owners and on-call evidence absent | IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED |

## Classification

| Class | Controls |
|---|---|
| A. TLS / HTTPS / WSS | P-03, P-04 |
| B. Database security | P-04, P-40 |
| C. Backup / restore | P-05 |
| D. KMS / secrets manager | P-04, P-06, P-07, P-08, P-10 |
| E. Private media storage | P-06 |
| F. Privacy export storage | P-07 |
| G. Centralized logging | P-39 |
| H. Monitoring / alerting | P-33, P-39, P-45 |
| I. Distributed rate limiting | P-33 |
| J. Release signing | Cross-cutting P-09/P-42 prerequisite; not one of the 13 infrastructure-primary controls |
| K. Cloud / hosting access | P-03, P-04, P-05, P-06, P-07, P-08, P-40, P-44, P-45 |
| L. Network / firewall | P-03, P-40 |
| M. Store / release infrastructure | P-43, P-44; P-09/P-42 cross-cutting |
| N. Management authorization | P-05, P-08, P-43, P-44, P-45; P-42 cross-cutting |

Phase 8 infrastructure controls closed: **0 of 13**. Plans, templates and local configuration do not satisfy external evidence.
