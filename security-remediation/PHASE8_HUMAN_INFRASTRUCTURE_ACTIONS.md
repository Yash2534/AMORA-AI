# Phase 8 Human Infrastructure Action Register

All actions require genuine sanitized evidence. Owners remain role-based until Management assigns named people in the restricted roster.

## DEVOPS

| Control ID | System | Owner | Required access | Exact action | Evidence required | Pass criteria | Current blocker | Next phase dependency |
|---|---|---|---|---|---|---|---|---|
| P-03 | DNS/edge/API/admin/socket | DevOps | DNS, CDN/LB/proxy and certificate console | Approve staging host; enforce HTTPS/WSS/TLS 1.2+/redirect/HSTS/proxy; test renewal | TLS template and sanitized exports | Every applicable target passes | No approved hostname/access | P-11/P-36 Phase 9 |
| P-05 | Backup/DR | DevOps + DB | Backup console and isolated restore target | Configure encrypted schedule/separate identity and run restore drill | Policy, grants, logs, integrity, RPO/RTO | Restore meets approved objectives | No target/objectives/owner | Release gate |
| P-33 | API fleet/shared store | DevOps + Backend | Staging orchestrator, proxy, Redis/equivalent | Configure shared store; bounded cross-node threshold/recovery test | Topology, config, 429/recovery/alert | Consistent safe enforcement | Shared store/topology absent | P-36 Phase 9 |
| P-44 | CI/CD/hosting | DevOps + Release | Pipeline/protected environment | Enforce approver/deploy identity/immutable digest; drill rollback | Rules, grants, release and rollback records | No direct unapproved deploy; rollback works | Pipeline evidence absent | Phase 9 candidate deployment |
| P-45 | Monitoring/paging | SRE + Security | Metrics/log/paging systems | Configure matrix, assign owner/runbook and test delivery | Rules/dashboard/delivery/escalation | Every mandatory signal passes | Platform/on-call absent | Phase 9 and release gate |
| P-43 | Git hosting/CI | Repo admin + Security | Rulesets/actions/security settings | Require reviews/checks; run security workflow; retain SBOM | Rules export, run URLs/results, SBOM | Bypass governed; required checks pass | Host settings not supplied | Release candidate acceptance |

## DATABASE

| Control ID | System | Owner | Required access | Exact action | Evidence required | Pass criteria | Current blocker | Next phase dependency |
|---|---|---|---|---|---|---|---|---|
| P-04 | Managed MySQL/KMS/snapshots | Cloud/DB owner | DB provider and KMS console, staging connection | Prove at-rest/snapshot encryption and CA/hostname TLS; reject plaintext | DB template/config and safe results | Encrypted and verified TLS only | Provider evidence absent | P-05/P-40 |
| P-40 | DB network/IAM | DB + Infrastructure | Network/firewall and DB grants | Make endpoint private; run approved public negative test; review app/backup grants | Topology/rules/result/grants | No public reachability; least privilege | Console/test vantage absent | Approved staging DB |

## SECURITY

| Control ID | System | Owner | Required access | Exact action | Evidence required | Pass criteria | Current blocker | Next phase dependency |
|---|---|---|---|---|---|---|---|---|
| P-06 | Media storage/CDN | Infrastructure + Backend + Security | Storage/IAM/logging | Prove private/encrypted media, authorization, expiry if used, deletion/logging | P-06 plan evidence | Anonymous/cross-user denied; lifecycle works | Real storage absent | P-16/P-31/P-37 supporting evidence |
| P-07 | Export storage | Infrastructure + Privacy + Security | Storage/KMS/IAM/jobs/logging | Prove private encrypted export, owner-only access, expiry/delete/cleanup/logging | P-07 plan evidence | No public/cross-user access; lifecycle works | Deployed store absent | P-22 Phase 9 |
| P-08 | KMS/secrets | Security + DevOps | KMS/secrets/IAM/audit | Inventory and prove IAM, isolation, rotation and recovery | Sanitized inventory/policies/logs/drills | All categories managed and recoverable | Managed-store evidence absent | Signing/deployment readiness |
| P-10 | Secrets/Git/CI | Security + DevOps | Secret manager, Git host, CI | Run scans, disposition findings, prove injection/isolation/rotation | Scan results, inventory and rotation refs | No unmanaged/exposed secret | Hosted/store evidence absent | P-09 and release gate |
| P-39 | Audit/log sink | Security + DevOps | DB roles, sink, IAM, monitoring | Prove ingestion/redaction, append-only restriction, time/retention/integrity and alert | Central logging plan evidence | Required events protected and alerted | Central sink/legal retention absent | P-37 and release gate |

## MOBILE / RELEASE

| Control ID | System | Owner | Required access | Exact action | Evidence required | Pass criteria | Current blocker | Next phase dependency |
|---|---|---|---|---|---|---|---|---|
| P-09/P-42 | Android signing/build | Mobile + Release + Security | Protected signing service and CI | Approve app ID; build company-signed APK/AAB; verify/scan/review | Hash/signature/manifest/config/scans/custody | Company signature, debug off, scans accepted | Signing material/custodian absent | P-09 Phase 9/device tests |
| P-16/P-25 | Android device/AVD | Mobile + Product | Approved device or SDK install | Install API image/AVD or provide device; run permission/age journeys | Inventory and screenshots/results | All manual criteria pass | No image/AVD/device | Phase 9 |
| P-11 | Release client | Mobile + Security + DevOps | Signed non-production build, staging and inspection device | Verify HTTPS/WSS and secure-token lifecycle | Traffic/storage/lifecycle evidence | No cleartext/retained credentials | No staging/device/candidate | Phase 9 |

## MANAGEMENT

| Control ID | System | Owner | Required access | Exact action | Evidence required | Pass criteria | Current blocker | Next phase dependency |
|---|---|---|---|---|---|---|---|---|
| Cross-cutting | Staging | Executive sponsor + DevOps | Governance/budget/DNS authority | Approve exact host, scope, test window, owner, cost and exclusions | Written authorization reference | Isolated staging can be built/tested | No approval | All Phase 9 staging/manual work |
| P-37 | Admin identities | Admin owner + Security | Staging RBAC/MFA | Approve and provision ADMIN-LOW/FULL/MFA-ADMIN | Roster/role/MFA/audit evidence | Unique least-privilege non-prod identities | Owner/accounts/MFA absent | Phase 9 |
| P-22/P-31/P-36 | Dummy users | Product/Privacy/Security | Staging account tooling | Approve and provision required synthetic states | Controlled roster and cleanup | All states available; no real PII | Staging unavailable | Phase 9 |
| P-26 | Phone operations | Product + Security + Support/Ops | Policy and staging SMS workflow | Decide/sign every scenario and rehearse | Signed form and provider evidence | Three approvals; all topics resolved | All approvers TBD | Phase 9/10 |
| P-42 | Company signing custody | Management + Release | Company store/signing governance | Assign custodian/backup/recovery and authorize build | Custody and approval references | No personal/shared custody | Unassigned | P-09 and release gate |
| P-45 | Monitoring ownership | Management + SRE | Roster/paging governance | Assign primary/backup owners and escalation authority | Restricted roster reference and contact test | Reachable, authorized coverage | Unassigned | Phase 9/release gate |
