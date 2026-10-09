# AMORAA Security and Compliance Program

Complete Security Status Completed Work Pending Controls and Final Validation Roadmap

**Date:** 9 October 2026  

**Branch:** `security/amoraa-pending-remediation`  

**Baseline commit:** `eeeee8165714976a4cdad7d5a1dd460907c9bbf9`  

**Status:** NOT PRODUCTION READY  

**Recommendation:** READY FOR NEXT SECURITY VALIDATION STAGE

<!-- PAGE BREAK -->

# Document Control

| Field | Value |
|---|---|
| Purpose | Give senior management one evidence-based view of completed controls, remaining launch gates, ownership and roadmap. |
| Audience | Leadership, Engineering, Mobile, Backend, DevOps, Security, Legal/Privacy, Support/Operations and Admin teams. |
| Scope | The 51 controls P-01 through P-51 and evidence produced through Phase 7. |
| Authority | AMORAA_ACTUAL_VERIFICATION_STATUS.md is the current control ledger. Phase reports are historical evidence. |
| Evidence rule | A control is complete only when implementation, required verification, absence of conflicting paths and regression evidence are all satisfied. |
| Confidentiality | Internal security governance. Do not add secrets, tokens, OTPs, customer data or private contacts. |

**Decision required.** Engineering has closed the identified repository-code gaps, but leadership must fund and authorize the real-world validation sequence. Production release remains prohibited until the final gate is signed.

## Contents

- Executive Summary and Senior Security Dashboard

- Verified Complete Controls

- User, Admin, Backend, Mobile, Database, Storage and Privacy Security

- Testing and Phase History

- Manual, Staging, Infrastructure, Legal and Management Pending Work

- VAPT and Remaining P0 Launch Blockers

- Management Actions, Roadmap, Release Gate and Evidence Index

- One Page Senior Summary

# Executive Summary

AMORAA began with 51 pending security and compliance controls. Seven controls are now genuinely COMPLETE — VERIFIED and 44 remain open. Engineering has removed the known repository implementation gaps: the remaining work is dominated by device and staging validation, cloud and infrastructure proof, legal decisions, management ownership, operational signoff and independent VAPT.

The strongest verified outcomes are removal of the development admin credential fallback, HTTPS-only production origin policy, recursive sensitive-log redaction, security-event coverage, password-change session revocation, SQL/ORM injection hardening and provider-neutral account deactivation. The latest backend regression passed 356 tests with no failures or blocks. The latest Flutter suite passed 659 tests with 14 intentional skips and no failures; analysis still reports 44 pre-existing warning/info items and is not reported as a pass.

AMORAA is not production ready. No production system, customer data, cloud console or production credential was accessed during validation. There is no approved staging host, release device/AVD, company-signed APK/AAB/IPA, production infrastructure evidence, legal approval, named operational roster or independent VAPT report. The valid recommendation is READY FOR NEXT SECURITY VALIDATION STAGE.

# Senior Security Dashboard

| Measure | Current result | Management interpretation |
|---|---|---|
| Original pending controls | 51 | Full control universe P-01 to P-51 |
| Verified complete | 7 | Evidence satisfies repository exit criteria |
| Remaining | 44 | Requires external evidence, approval or independent validation |
| P0 | 6 complete / 29 remaining | Launch-critical gates remain open |
| P1 | 1 complete / 14 remaining | Important readiness and governance work remains |
| P2 | 0 complete / 1 remaining | Tabletop exercise not completed |
| Repository gaps | 0 | No current primary status is a source-code remediation gap |
| Manual evidence | 5 | P-09, P-16, P-22, P-25, P-37 |
| Staging evidence | 3 | P-11, P-31, P-36 |
| Infrastructure evidence | 13 | Exact controls listed later |
| Legal pending | 10 | No legal conclusion is inferred |
| Management / operations | 11 | 10 management-primary controls plus P-26 signoff |
| Independent VAPT | 2 | P-46 and P-47 |
| Backend tests | 356 pass / 0 fail / 0 block | Latest Phase 5 full regression |
| Flutter tests | 659 pass / 0 fail / 14 skip | Latest Phase 5 full suite |
| Flutter analysis | 44 warning/info findings | Exit 1; no Phase 5 security finding |
| Production accessed | NO | No production evidence is claimed |
| Recommendation | NOT PRODUCTION READY | Proceed only to next controlled validation stage |

# Verified Complete Controls

<!-- WIDE -->

| ID | Area | Requirement and implementation | Verification | Phase | Status |
|---|---|---|---|---|---|
| P-01 | Development admin credential | No fallback/default password; production seeding disabled; sensitive values excluded from logs. | Seed guards and log regressions passed. | Phase 2 | COMPLETE — VERIFIED |
| P-02 | Production origin policy | HTTPS-only configured production origins; HTTP, wildcard and unlisted origins rejected. | CORS and OPTIONS regression passed. | Phase 2 | COMPLETE — VERIFIED |
| P-13 | Security event coverage | Critical event families use the sanitized shared audit architecture with correlation and outcome metadata. | Focused event tests and 350-test backend regression passed. | Phase 4 | COMPLETE — VERIFIED |
| P-14 | Log redaction | Recursive redaction covers credentials, OTPs, tokens, cookies, secrets and identity numbers. | Nested fixtures and direct-console review passed. | Phase 2 | COMPLETE — VERIFIED |
| P-20 | Account deactivation | Local and Google step-up, state enforcement, session/device revocation and safe reactivation implemented. | Dedicated Phase 5 lifecycle tests passed; stale sessions remain rejected. | Phase 5 | COMPLETE — VERIFIED |
| P-34 | Password session revocation | Password change increments token version and deletes refresh sessions. | Old access and refresh credentials rejected in DB-backed integration tests. | Phase 3 | COMPLETE — VERIFIED |
| P-35 | SQL and ORM injection review | Raw-query inventory, value binding/escaping and dynamic identifier allowlists completed. | Non-destructive injection regressions passed. | Phase 3 | COMPLETE — VERIFIED |

<!-- NARROW -->

# AMORAA User Security

| User area | Implemented | Verified or pending | Controls |
|---|---|---|---|
| Signup login OTP reset | Implemented; authentication, OTP challenge, reset and abuse controls covered locally | Runtime verified in backend suites; distributed/provider proof remains | P-01, P-10, P-33 |
| Password change sessions logout | Token-version invalidation, refresh deletion and client credential clearing | P-34 complete; release-device behavior remains P-11 | P-11, P-34 |
| Token storage | Platform secure storage and release HTTPS guard | Staging traffic and Android/iOS storage lifecycle pending | P-11 |
| Deactivation reactivation | Provider-neutral step-up, state enforcement, revocation and fresh-session reactivation | Complete locally; real provider/device release evidence remains secondary | P-20 |
| Deletion | Technical data map and lifecycle tests exist | Retention, vendor and backup decisions require Legal | P-19, P-21 |
| 18+ enforcement | Server policy covers create/update/correction and discovery | Backend verified; device journey and policy approval pending | P-25 |
| Privacy requests export | Owner scope, step-up, status, expiry and deletion implemented | Manual operations, staging storage and legal SLA pending | P-07, P-22 |
| Consent withdrawal | Immutable event model and withdrawal mechanisms exist | Purpose/legal-basis decisions pending | P-18 |
| Location discovery privacy | Exact public coordinates removed; coarse distance and visibility rules implemented | Staging UI/log/export and Product/Privacy signoff pending | P-31 |
| Block report unmatch safety | Repository flows and boundary tests exist | Operational moderation, anti-scam staffing and appeal evidence pending | P-28, P-29, P-30 |
| Profile chat identity media | Authenticated delivery, path/type/size/visibility controls implemented | Private deployed storage, encryption and identity governance pending | P-06, P-27 |
| Phone lifecycle | Canonicalization, uniqueness, OTP change, concurrency and revocation implemented | Recycled-number/support policy and provider staging signoff pending | P-26 |
| Permissions camera gallery notifications | Source/manifest minimization and automated checks exist | Device denial/retry/selected-photo captures and approval pending | P-16 |
| API authorization IDOR BOLA | Route matrix, auth, ownership and cross-user regressions exist | Staging edge and release-commit signoff pending | P-36 |

# AMORAA Admin Security

Repository controls now cover admin authentication, password handling, MFA enrollment and fresh step-up, hardened sessions, explicit route permissions, role enforcement, privilege-change auditing, destructive-action controls and sanitized audit/security events. The default admin credential fallback is removed and production seeding is prohibited.

| Admin area | Code verified | Still required | Dependency |
|---|---|---|---|
| Authentication and passwords | P-01 seed guard; password/session tests | Real company-owned dummy admin login | P-37/P-38 |
| MFA and step-up | Enrollment, challenge and fresh-MFA paths pass locally | Staging MFA device and expiry captures | P-37 |
| RBAC and privilege escalation | Explicit permission catalog and wrong-role tests | Current approved role roster and manual role testing | P-37/P-38 |
| Admin sessions | Refresh/session revocation and expiry controls exist | Staging timeout behavior and company identity ownership | P-37/P-38 |
| Sensitive and destructive actions | High-risk routes require permission/fresh MFA and audit | Approved workflow and sanitized before/after evidence | P-37 |
| Verification/moderation/support/privacy access | Route restrictions and audit events exist | Staffing, least-privilege roster and operational approval | P-27/P-29/P-37 |
| Role assignment and offboarding | Admin-management controls exist | Named owner, recertification and offboarding evidence | P-38/P-49 |
| Audit integrity | Sanitized hash-chain source and event coverage exist | Append-only role, centralized sink, retention and alerts | P-39 |

No dedicated admin frontend, safe dummy role credentials, MFA test device or approved admin roster was available in Phase 7. P-37 therefore remains manual-evidence pending; P-38 and P-49 remain management-owned.

# Backend and API Security

The backend uses centralized authentication middleware, token versioning, owner and role checks, input validation, parameterized/escaped ORM boundaries, HTTPS-origin policy, Helmet-compatible headers, sanitized errors, route-specific rate limits and security-event logging. Privacy, media, admin, location, account-lifecycle and age controls are covered by the current route/test architecture.

| Control surface | Current evidence | Residual dependency |
|---|---|---|
| Authentication authorization RBAC | Local unit/integration suites cover unauthenticated, cross-user, role and MFA boundaries | Staging/admin roster evidence |
| SQL/ORM safety | P-35 complete after raw-query inventory and injection regressions | Independent VAPT remains separate |
| CORS headers errors payloads | P-02 complete for origins; P-36 local matrix and tests exist | Staging proxy/header/error capture |
| Rate/OTP/brute-force | Explicit policies and proxy guard tests exist | Multi-instance shared-store proof P-33 |
| Sessions and refresh tokens | Rotation/replay/logout/password/deactivation revocation covered | Device release behavior P-11 |
| Logging and security events | P-13/P-14 complete at repository level | Central immutable sink P-39 |
| Privacy/media/location/admin endpoints | Local owner/visibility/RBAC regressions pass | Storage, staging and operational evidence |
| Latest full result | 356 passed; 0 failed; 0 skipped/blocked | Phase 5 local MariaDB environment; production not accessed |

# Mobile and Flutter Security

| Area | Implemented or observed | Current status |
|---|---|---|
| Secure token storage | Platform-backed secure storage is canonical; lifecycle clearing paths exist | Staging/device evidence pending P-11 |
| Endpoint configuration | Release requires explicit absolute HTTPS API URL; debug uses local endpoints | Staging capture pending P-11 |
| Cleartext/ATS | Android release guard and platform policies reviewed; no iOS artifact/device proof | Manual/release evidence pending |
| Permissions | Broad permissions reduced; contextual abstractions/tests exist | Device captures and Product/Privacy approval pending P-16 |
| Backup/debug/release config | Release debuggable false and signing variables required; secure backup controls reviewed | Company-signed artifacts absent P-42 |
| Firebase/public IDs versus secrets | Bounded debug APK scan found zero high-confidence patterns | Final APK/AAB/IPA scan and identifier classification pending P-09 |
| Signing/artifacts | Available APK is Android Debug-signed; no AAB/IPA or company key | Launch blocker P-09/P-42 |
| Flutter tests | 659 passed; 0 failed; 14 intentional skips | Latest Phase 5 result |
| Analyzer | 44 pre-existing warning/info findings; exit 1 | Not reported as pass; no Phase 5 security finding |
| Logout/deletion/password cleanup | Client and server cleanup paths covered by automated tests | Release-device confirmation pending P-11 |

# Database Security

Phase 3 used an isolated loopback MariaDB test environment, dedicated test schema/user and migration status checks. The final Phase 3 backend run passed 347 tests; later phases increased the full suite to 356. Production and staging databases were never accessed.

| Area | Repository or local evidence | External requirement |
|---|---|---|
| Connectivity and isolation | Tests require test intent/name; dedicated local schema/user used | Maintain separate non-production identities |
| SQL/ORM and transactions | P-35 complete; injection, rollback and concurrency tests pass | Independent VAPT |
| TLS and encryption at rest | Fail-closed configuration contract exists | Provider TLS/CA, at-rest and snapshot evidence P-04 |
| Network and least privilege | Source cannot prove topology | Private endpoint/firewall/grants P-40 |
| Backups and restore | Runbooks/checklists exist | Encrypted schedule, backup identity and restore drill P-05 |
| Retention and deletion | Technical maps/jobs exist | Legal schedule and real lifecycle execution P-19/P-21 |
| Audit data | Sanitized events/hash chain exist | Append-only roles/retention/alerts P-39 |

# Media and Storage Security

P-06 removed unrestricted protected-media delivery and adds authenticated ownership/visibility/block/inactive/path/type/size controls. P-07 provides owner-scoped, step-up protected export artifacts with expiry, one-time consumption and deletion. Identity media adds randomized names, size/type/signature checks, path safety and restricted admin access.

| Control | Repository verified | Not yet proven | Status |
|---|---|---|---|
| P-06 profile/chat media | Anonymous/cross-user/blocked/inactive/traversal boundaries pass locally | Private bucket/mount, encryption/IAM, lifecycle and malware/metadata policy | Infrastructure evidence required |
| P-07 privacy exports | Owner scope, approved fields, expiry, consume/delete and cleanup pass | Private encrypted deployed storage/KMS and approved retention/fields | Infrastructure and legal evidence required |
| P-27 identity media | Private validation, random filename, cleanup and admin restrictions | Necessity, retention, metadata/malware strategy, vendor/liveness governance | Legal/vendor evidence required |

# Privacy DPDP and Data Governance

Technical privacy mechanisms do not equal legal compliance. AMORAA has technical controls for consent events, withdrawal, rights requests, export expiry/deletion, account deletion mapping, data inventory, AI-flow documentation, grievance confidentiality, minimization and location privacy. The legal register contains ten unresolved decisions; therefore this report does not claim DPDP compliance.

| Domain | Technical implementation | Legal or real-world dependency | Controls |
|---|---|---|---|
| Notice and Terms | Versioned notice/legal document mechanisms | Final entity/contact/purposes/publication approval | P-17 |
| Consent/withdrawal | Immutable purpose/version events and withdrawal routes | Legal-basis/purpose/exception decision | P-18 |
| Rights and export | Owner scope, status, step-up, expiry/deletion | Legal SLA, operations journey, private storage | P-07/P-22 |
| Deletion/retention | Schema/file map and lifecycle implementation | Category retention, backups/vendors, signed schedule | P-19/P-21 |
| Processors/vendors | Source-derived vendor inventory | Executed DPA/contracts and verified settings | P-23 |
| AI data flow | Local provider path and payload register documented | Product/Privacy approval and provider facts | P-24 |
| Grievance | Authenticated owner status and throttle | Verified contact, SLA and escalation wording | P-32 |
| Location and verification data | Public coordinate minimization and private ID storage | Staging approval; identity necessity/retention/liveness | P-31/P-27 |
| Incident notification | Plans/templates exist | Current counsel-approved applicability, triggers and clocks | P-12/P-15/P-50 |

# Identity Age and Dating Safety

| Area | Technical state | Operational or external state |
|---|---|---|
| 18+ enforcement | Strict shared UTC age policy and mutation/discovery tests pass | Device journey and approved underage process pending P-25 |
| Phone verification and uniqueness | Canonical number, OTP purpose/expiry/replay, DB uniqueness and concurrency pass | P-26 support/recycled-number signoff and SMS-provider staging pending |
| Identity/selfie/ID handling | Private validated storage, randomized files, cleanup and restricted admin access | Necessity, retention, liveness/vendor approval pending P-27 |
| Fake account/bot/device controls | Auth/rate/report controls exist | Platform attestation decision and server proof pending P-28 |
| Report/block/unmatch | Repository behavior and boundaries exist | Moderation staffing, SLA, appeal and sampled cases pending P-29 |
| Anti-scam/impersonation/financial solicitation | Technical reporting/rate surfaces exist | Taxonomy, staffing, repeat-offender workflow and metrics pending P-30 |
| Location privacy | Exact public coordinates removed; coarse distance | Staging and Product/Privacy approval pending P-31 |

# Logging Monitoring and Incident Security

Repository-complete elements include recursive redaction and event-family coverage for login, admin actions, privilege changes, failures, rate limits, privacy/export, moderation and account lifecycle events. Incident response, severity, evidence-preservation and scenario templates also exist.

| Area | Repository state | Real-world requirement |
|---|---|---|
| Credential/token/OTP redaction | P-14 complete with nested fixtures | Central platform access/retention remains P-39 |
| Security/admin events | P-13 complete; sanitized actor/action/target/outcome metadata | Central sink, alerts and operating ownership P-39/P-45 |
| Tamper resistance and clock | Hash-chain source exists | Append-only role, time sync and prohibited-mutation evidence P-39 |
| Monitoring and alerting | Runbook guidance exists | Dashboards, delivery tests, on-call and false-positive review P-45 |
| Incident response | Plans, severity and evidence templates exist | Approval, named commander/team and contact test P-48/P-49 |
| Regulatory reporting | Draft workflows/templates exist | Counsel-approved scope/clock/contact P-12/P-15/P-50 |
| Tabletop drills | Scenarios/template exist | Real exercise and action closure P-51 |

# Release SDLC and CI CD Security

| Area | Repository state | Launch blocker |
|---|---|---|
| Branch protection/review | CI examples and secure process documented | Hosted rules/required checks export P-43 |
| SAST/dependency/secret/SBOM | Workflow and configurations exist; local bounded scans/audits recorded | Hosted runs, final exceptions and SBOM P-10/P-43 |
| CI secrets and production approval | Environment separation and protected-process guidance exist | Secret manager, protected deploy identity/approver P-10/P-44 |
| No direct push/rollback/changelog | Secure release procedure exists | Real pipeline policy and rollback drill P-44 |
| Release signing/binaries | Release config requires protected signing variables | Company key custody and signed APK/AAB/IPA P-09/P-42 |
| Store readiness | Checklist exists | Org accounts, Data Safety/App Privacy, URLs, reviewer access P-41 |
| Patch SLA | Repository policy exists | Management ownership and operating evidence |

# Security Testing Summary

<!-- WIDE -->

| Phase | Execution | Passed | Failed | Blocked or skipped | Important result | Production |
|---|---|---|---|---|---|---|
| 1 Repository remediation | Static syntax/diff checks; runtime withheld | Static checks passed | 0 runtime failures recorded | Runtime not executed | Implementation and evidence framework created; 0 complete at that snapshot | NO |
| 2 Local runtime | Flutter, backend attempt, scans | Flutter 658; backend 114 pure/unit | 243 backend setup failures | 14 Flutter skips; DB unavailable | P-01/P-02/P-14 complete; stale permission expectation corrected | NO |
| 3 Database validation | Migrations, focused and full backend | 347 final | 0 final | 0 | Initial 333/13 run exposed test/app defects; corrected without weakening controls; P-34/P-35 complete | NO |
| 4 P0 evidence closure | Event-focused and full backend | 350 final | 0 final | 0 | P-13 event coverage complete; external evidence split | NO |
| 5 Repository gap closure | Dedicated/focused/full backend and Flutter | Backend 356; Flutter 659 | 0 final | 14 Flutter skips | Early fixture/OTP/deadlock findings corrected; P-20 complete; P-26 awaits signoff | NO |
| 6 Manual evidence attempt | APK/static prerequisite inspection | 795 APK entries scanned | Artifact gate failed | 4 journeys not executed | Zero high-confidence patterns, but APK debug-signed and no device/approvers | NO |
| 7 Staging/device readiness | Environment discovery | N/A | N/A | 3 staging and 5 manual flows | No AVD/device/staging/accounts/company artifacts; execution packs prepared | NO |

Historical failures are retained above. A corrected final pass does not erase the initial result; the detailed phase evidence records both the defect and the successful rerun.

<!-- NARROW -->

# Phase by Phase Security History

## Phase 1 Repository remediation and evidence framework

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Implement source-controlled fixes and build the 51-control evidence structure. | Code/tests/docs across credentials, CORS, media, exports, secrets, logging, age, location, sessions, API/admin, mobile, CI and incident response. | P-01 through P-51 reviewed | Static source checks; runtime not claimed | 0 at that snapshot | Runtime and external proof | Phase 2 needed real local execution. |

## Phase 2 Local runtime validation

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Run supported local suites and remove tooling blockers. | Flutter runner fixed; analyzer, backend attempt and redacted scans executed. | P-01, P-02, P-14 and implemented controls | Flutter 658 pass/14 skip; backend 114 pass/243 DB setup failures | 3 | Database-backed controls blocked | Phase 3 needed isolated MariaDB. |

## Phase 3 Database security validation

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Execute all DB-backed tests safely. | Isolated MariaDB, migrations, full regression, injection and lifecycle evidence. | P-06/P-07/P-13/P-16/P-22/P-25/P-31/P-34/P-35/P-36/P-37 | 347/347 final; initial 333/13 triaged and fixed | P-34, P-35 | P-13 code gap and external/manual evidence | Phase 4 closed event coverage. |

## Phase 4 P0 evidence closure

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Complete security-event families and separate evidence dependencies. | Event matrix/middleware/persistence tests; manual packs for eight controls. | P-13 plus P-06/P-07/P-16/P-22/P-25/P-31/P-36/P-37 | 350/350 final | P-13 | P-20/P-26 repository gaps and real evidence | Phase 5 closed remaining code gaps. |

## Phase 5 Repository gap closure

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Close P-20 and P-26 repository requirements. | Provider-neutral deactivation, session revocation, phone change/uniqueness/concurrency and Flutter step-up UX. | P-20, P-26 | 6/6 dedicated; 34/34 focused; backend 356/356; Flutter 659 pass/14 skip | P-20 | P-26 operations policy and all real-world gates | Phase 6 attempted manual evidence. |

## Phase 6 Manual evidence closure attempt

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Execute device/admin/user checks where prerequisites exist. | Identified five controls; inspected APK; created evidence records/signoff. | P-09/P-16/P-22/P-25/P-37 and P-26 | 795 APK entries; no device flows | 0 | No devices/staging/admin credentials/approvers; APK debug-signed | Phase 7 prepared environment. |

## Phase 7 Staging and device validation attempt

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Discover prerequisites and prepare real execution. | SDK/device/artifact/account/staging inventory; AVD, staging and human packs. | P-11/P-31/P-36 plus manual controls | Discovery only; no external probes | 0 | No system image/AVD/device/staging/company artifacts/accounts | Phase 8 must close infrastructure and release prerequisites. |

## Phase 8 NEXT

| Goal | Work completed | Controls | Tests | New complete | Pending after phase | Why next phase |
|---|---|---|---|---|---|---|
| Infrastructure and release prerequisite closure. | Not yet executed. | Infrastructure, signing, staging and account prerequisites | Pending | 0 | All real owners/access required | Enables Phase 9 manual/staging revalidation. |

# Manual Verification Pending

<!-- WIDE -->

| ID | Requirement | Implemented | Why not complete | Manual test | Prerequisite | Evidence | Owner | Next step |
|---|---|---|---|---|---|---|---|---|
| P-09 | Final mobile binary secret scan | Release URL guards and a redacted APK scanner exist; a debug-signed APK produced zero high-confidence pattern matches. | No company-signed APK/AAB or IPA; final variants and public-ID review absent. | Scan signed APK/AAB/IPA and verify signatures/debug flags. | Company signing service and final artifacts | P09_release_binary_scan.txt | Mobile + Security + Release |
| P-16 | Permission minimization and behavior | Manifest/source permissions reduced; contextual permission abstractions and automated tests exist. | No Android/iOS device captures or Product/Privacy approval. | Exercise timing, deny, retry, selected-photo and no-crash behavior. | Test device/AVD and approved release build | P16 permission screenshots and approval | Mobile + Product + Privacy |
| P-22 | Privacy-rights user and operations flow | Owner scoping, step-up, status, export expiry/deletion and cross-user protections pass locally. | No end-user staging journey, operations queue proof or legal SLA. | Execute request types, status, ownership, expiry, deletion and completion. | Approved staging, two dummy users, Privacy Operations | P22_cross_user_request_denied.json | Privacy + Backend + Legal |
| P-25 | 18+ user journey | Shared UTC age policy protects signup, onboarding, updates and correction paths. | No Android/iOS journey or approved underage response policy. | Capture exact-18, under-18, future, malformed, edit and discovery outcomes. | Device/AVD, dummy users, Product/Legal decision | P25_exact18_allowed.png and P25_under18_rejected.png | Mobile + Backend + Product |
| P-37 | Admin RBAC and MFA manual validation | Route permissions, MFA/fresh step-up, sessions and audit behavior pass locally. | No staging admin UI, dummy role accounts, MFA device, roster or owner approval. | Exercise normal user, lower role, authorized role, expiry and audited action. | Approved staging, dummy admins, MFA and roster | P37_wrong_admin_role_denied.png and audit JSON | Security + Admin owner + Management |

<!-- NARROW -->

# Staging Verification Pending

<!-- WIDE -->

| ID | Requirement | Implemented | Staging must prove | Accounts | Evidence | Pass blocker | Owner |
|---|---|---|---|---|---|---|---|
| P-11 | Release transport and token storage | Release URL must be HTTPS; platform secure storage is canonical; lifecycle clearing is implemented. | HTTPS/WSS traffic, Android/iOS secure-storage and backup/clear behavior. | Release devices and dummy account | Traffic capture and storage/lifecycle evidence | No device/AVD, signed build or approved staging | Mobile + DevOps + Security |
| P-31 | Location privacy | Public serializers omit coordinates, quantize distance and exclude blocked/inactive/deleted users. | Deployed responses, UI, logs and exports contain no exact coordinates; Product/Privacy accepts precision. | Active, blocked, deactivated and deleted dummy users | P31_location_api_redacted.json plus UI/log review | No approved staging or Product/Privacy signoff | Backend + Product + Privacy |
| P-36 | Route-wide API hardening | Route matrix and local auth, ownership, validation, error, CORS and payload controls exist. | Edge HTTPS, headers, OPTIONS, auth/IDOR, invalid IDs, sanitized errors and bounded rate-limit behavior. | Users A/B and approved proxy topology | P36_cors_https_headers.txt and sanitized API captures | No approved staging/proxy/topology | Backend + DevOps + Security |

<!-- NARROW -->

# Infrastructure Evidence Pending

| ID | System or area | Required evidence | Owner |
|---|---|---|---|
| P-03 | TLS edge | TLS 1.2+, HTTPS/WSS, redirect, HSTS, proxy and certificate renewal proof | DevOps + Mobile |
| P-04 | DB encryption and TLS | Provider at-rest encryption, CA/hostname TLS and encrypted snapshots | Infrastructure + DB |
| P-05 | Backup and restore | Encrypted schedule, separate identity, RPO/RTO and isolated restore drill | DevOps + DB |
| P-06 | Private media storage | Private ACL/IAM, encryption, anonymous denial and lifecycle deletion | Infrastructure + Backend |
| P-07 | Private export storage | Encrypted private artifact store, key controls and lifecycle evidence | Infrastructure + Privacy |
| P-08 | KMS and secret manager | Ownership, IAM, access logs, rotation and recovery drill | Infrastructure + Security |
| P-10 | Secret operations | Managed injection, full scans, exposure disposition and rotation references | DevOps + Security |
| P-33 | Distributed abuse control | Shared store, trusted proxy topology, multi-node 429 and recovery test | Backend + DevOps |
| P-39 | Central audit logging | Append-only role, retention, time sync, integrity and alert delivery | Security + DevOps |
| P-40 | DB network and identities | Private endpoint/firewall, public negative test and least-privilege grants | Database + Infrastructure |
| P-43 | Repository protection | Branch/ruleset exports, required checks, hosted scan/SBOM evidence | Repository admin + Security |
| P-44 | Deployment approval | Protected environment, deploy identity, immutable artifact and rollback drill | Release + DevOps |
| P-45 | Monitoring and on-call | Dashboards, alert delivery tests, ownership, rota and runbooks | SRE + Security |

These 13 controls are the mutually exclusive infrastructure-primary category in the current ledger. Other controls may also need infrastructure support without being counted again.

# Legal Verification Pending

<!-- WIDE -->

| ID | Legal question | Document requiring approval | Owner | Status |
|---|---|---|---|---|
| P-12 | Applicable security-log categories, retention and location | Logging/retention policy and incident plan | Legal + Security | PENDING — LEGAL VERIFICATION REQUIRED |
| P-15 | Reportable incidents, trigger, clock, recipient and reporter | Incident reporting procedure | Legal + Security | PENDING — LEGAL VERIFICATION REQUIRED |
| P-17 | Accuracy of entity, contact, purposes, sharing, rights and Terms | Privacy Policy, Terms and notice content | Legal + Product | PENDING — LEGAL VERIFICATION REQUIRED |
| P-18 | Consent purposes/legal basis and withdrawal effects | Consent purpose review and public notice | Legal + Privacy + Product | PENDING — LEGAL VERIFICATION REQUIRED |
| P-19 | Deletion, anonymization and lawful retention by data category | Account deletion data map and policy | Legal + Privacy | PENDING — LEGAL VERIFICATION REQUIRED |
| P-21 | Retention trigger, duration, action, exceptions and backups/vendors | Data inventory and retention schedule | Legal + Privacy | PENDING — LEGAL VERIFICATION REQUIRED |
| P-23 | Vendor processing, transfer, security, deletion and incident terms | Processor register and executed DPAs/contracts | Legal + Procurement | PENDING — LEGAL VERIFICATION REQUIRED |
| P-27 | Necessity, retention, notices, vendor and liveness claims for identity data | Identity verification policy/DPIA | Legal + Privacy + Product | PENDING — LEGAL VERIFICATION REQUIRED |
| P-32 | Verified grievance contact, SLA, identity and escalation process | Privacy notice and grievance procedure | Legal + Support | PENDING — LEGAL VERIFICATION REQUIRED |
| P-50 | Current DPDP/DPB/CERT-In obligations, triggers and exact clocks | Counsel-approved rule register and templates | Legal + Security + Support | PENDING — LEGAL VERIFICATION REQUIRED |

Unverified claims include any asserted DPDP enforcement date, a 72-hour DPB notice, a ₹250 crore per-instance penalty and CERT-In applicability/location/retention interpretations. Qualified counsel must provide dated evidence.

<!-- NARROW -->

# Management and Operations Pending

| ID | Decision or operating requirement | Owner | Current evidence |
|---|---|---|---|
| P-24 | Approve AI/matching data-flow register, purpose and provider facts | Product + Privacy + Security | TBD — MANAGEMENT TO ASSIGN |
| P-26 | Approve duplicate/lost/recycled/disputed phone and recovery operations | Product + Security + Support/Ops | TBD — MANAGEMENT TO ASSIGN |
| P-28 | Decide platform attestation/device-risk approach and appeal | Product + Mobile + Security | TBD — MANAGEMENT TO ASSIGN |
| P-29 | Staff moderation queue, training, coverage, SLA and appeal | Management + Safety | TBD — MANAGEMENT TO ASSIGN |
| P-30 | Approve and staff anti-scam taxonomy, escalation and measurement | Safety + Product | TBD — MANAGEMENT TO ASSIGN |
| P-38 | Assign company account, MFA/recovery and offboarding ownership | Management + IT/Security | TBD — MANAGEMENT TO ASSIGN |
| P-41 | Own store accounts, declarations, URLs and reviewer flow | Mobile + Release + Product | TBD — MANAGEMENT TO ASSIGN |
| P-42 | Provide company signing custody and signed release artifacts | Mobile + Release + Management | TBD — MANAGEMENT TO ASSIGN |
| P-48 | Approve incident plan, authority and operating model | Management + Legal + Security | TBD — MANAGEMENT TO ASSIGN |
| P-49 | Assign named primary/backup incident owners and test contacts | Management | TBD — MANAGEMENT TO ASSIGN |
| P-51 | Conduct real tabletop and close actions | Incident lead + Management | TBD — MANAGEMENT TO ASSIGN |

The management/operations summary count is 11: ten controls whose primary ledger category is management plus P-26, whose primary status is operations/policy signoff required. The named-role register also contains cross-cutting roles such as incident commander, security lead, backup owner, monitoring owner, release approver and offboarding owner; all remain TBD.

# Vulnerability Assessment and Penetration Testing

VAPT means Vulnerability Assessment and Penetration Testing. P-46 requires an authorized independent assessment of the exact release candidate. P-47 requires remediation tracking, risk decisions and an independent retest confirming closure. Internal Codex source review and local regression testing improve readiness but are not independent adversarial assurance and cannot replace VAPT.

Expected scope: Android/iOS application, API, admin surface, authentication, OTP, sessions, RBAC, IDOR/BOLA, SQL injection, uploads/media, cloud and DB/storage, rate limits, location/privacy, business logic, account lifecycle, verification and moderation. No VAPT report, certificate or retest evidence exists.

# Remaining P0 Launch Blockers

<!-- WIDE -->

| ID | Area | Status | Why blocker | Owner | Required evidence | Next phase |
|---|---|---|---|---|---|---|
| P-03 | TLS deployment | Infrastructure evidence | Deployed transport is unproven | DevOps | TLS/header/WSS/certificate evidence | Phase 8 |
| P-04 | DB encryption | Infrastructure evidence | Provider encryption/TLS unproven | Infrastructure + DB | Console and connection proof | Phase 8 |
| P-05 | Backup/restore | Infrastructure evidence | No real restore drill | DevOps + DB | Encrypted backup and restore report | Phase 8 |
| P-06 | Private media | Infrastructure evidence | Production storage privacy unproven | Backend + Infrastructure | ACL/IAM/encryption/lifecycle evidence | Phase 8 |
| P-07 | Privacy export | Infrastructure evidence | Private encrypted deployed storage unproven | Backend + Privacy | Storage/KMS/lifecycle proof | Phase 8 |
| P-08 | KMS | Infrastructure evidence | No key ownership/rotation proof | Infrastructure + Security | KMS/IAM/recovery evidence | Phase 8 |
| P-09 | Mobile package scan | Manual evidence | No company-signed final binaries | Mobile + Security | Signed APK/AAB/IPA scans | Phase 8/9 |
| P-10 | Secret management | Infrastructure evidence | Managed injection/rotation not proven | DevOps + Security | Secret manager and scan evidence | Phase 8 |
| P-11 | Mobile transport/storage | Staging evidence | No release-device proof | Mobile + DevOps | HTTPS and secure-storage lifecycle | Phase 9 |
| P-12 | Log legal requirements | Legal pending | Applicable rules unapproved | Legal + Security | Dated counsel decision | Phase 10 |
| P-15 | Incident reporting | Legal pending | Reporting workflow unapproved | Legal + Security | Approved triggers/clocks/rehearsal | Phase 10 |
| P-16 | Permissions | Manual evidence | No device behavior/approval | Mobile + Product/Privacy | Device captures and purpose approval | Phase 9/10 |
| P-17 | Policies and Terms | Legal pending | Final content/publication absent | Legal + Product | Signed policy versions and URLs | Phase 10 |
| P-18 | Consent | Legal pending | Purpose/legal-basis decision absent | Legal + Product | Approved purpose map | Phase 10 |
| P-19 | Deletion | Legal pending | Retention exceptions unresolved | Legal + Privacy | Approved deletion/retention matrix | Phase 10 |
| P-21 | Retention | Legal pending | Schedule unapproved | Legal + Privacy | Signed schedule and execution proof | Phase 10 |
| P-25 | Age journey | Manual evidence | No device journey/policy approval | Backend + Product | UI captures and underage policy | Phase 9/10 |
| P-27 | Identity governance | Legal pending | Necessity/retention/vendor/liveness unresolved | Legal + Product | DPIA/policy/vendor proof | Phase 10 |
| P-29 | Moderation | Management pending | No staffed queue/SLA | Management + Safety | Roster, training and sampled cases | Phase 10 |
| P-31 | Location privacy | Staging evidence | Deployed UI/log/export behavior unproven | Backend + Product | Sanitized staging evidence/signoff | Phase 9 |
| P-33 | Rate limiting | Infrastructure evidence | Multi-instance enforcement unproven | DevOps + Backend | Shared-store/proxy/429 evidence | Phase 8 |
| P-37 | Admin hardening | Manual evidence | No real role/MFA/roster evidence | Security + Admin owner | Dummy admin captures and approval | Phase 9/10 |
| P-38 | Account ownership | Management pending | Company ownership/MFA register absent | Management + IT | Signed ownership/access register | Phase 10 |
| P-40 | DB network | Infrastructure evidence | Firewall/private path unproven | Infrastructure + DB | Topology/rules/grants evidence | Phase 8 |
| P-42 | Mobile release | Management pending | Company signing/build absent | Mobile + Release | Custody and signed artifact review | Phase 8 |
| P-46 | Independent VAPT | Independent VAPT | No independent assessment | Security + Management | Signed scoped VAPT report | Phase 11 |
| P-47 | Independent retest | Independent VAPT | No independent closure/retest | Security + Engineering | Finding register and signed retest | Phase 12 |
| P-48 | Incident readiness | Management pending | Plan not approved/exercised | Management + Security | Approval and exercise proof | Phase 10 |
| P-50 | Regulatory verification | Legal pending | Current legal interpretation absent | Legal | Dated counsel-approved register | Phase 10 |

<!-- NARROW -->

# Senior Management Actions Required

<!-- WIDE -->

| Action | Why needed | Owner needed | Due | Evidence |
|---|---|---|---|---|
| Approve exact staging hostname and test window | Enables P-11/P-31/P-36 and manual workflows | Executive sponsor + DevOps | Before Phase 9 | Written scope, owner, build and exclusions |
| Provide Android AVD/system image or dedicated devices | Enables permission, age and secure-storage evidence | Mobile leadership | Before Phase 9 | Device inventory and sanitized captures |
| Provision dummy user/admin roles and MFA | Enables privacy/admin/ownership testing | Security + Admin owner | Before Phase 9 | Controlled account roster; no production identities |
| Provide company signing material through protected service | Enables P-09/P-42 | Management + Release | Phase 8 | Custody, recovery and signed artifacts |
| Authorize infrastructure evidence access | Enables TLS/DB/storage/KMS/backup/logging proof | CTO/DevOps/Infrastructure | Phase 8 | Sanitized console/runtime exports |
| Engage qualified counsel | Closes ten legal decisions | Leadership + Legal | Phase 10 | Dated signed decisions and approved documents |
| Assign management and operational owners | Creates accountability for accounts, safety, incident and release | Executive leadership | Phase 10 | Restricted roster and authority statements |
| Approve P-26 operations policy | Controls lost/recycled/disputed phone handling | Product + Security + Support/Ops | Phase 10 | Three signed approvals and rehearsal |
| Establish monitoring and on-call | Required for production response | SRE + Security | Phase 8/10 | Dashboards, alerts, rota and delivery tests |
| Select independent VAPT vendor and budget | Mandatory independent assurance | Management + Security | Before Phase 11 | Authorization, scope, vendor and budget |
| Reserve remediation and retest window | P-47 requires independent closure | Engineering + Release | Before Phase 12 | Finding SLA, owners and retest booking |
| Appoint final release risk approver | Prevents informal launch | Executive leadership | Final phase | Signed immutable release decision |

<!-- NARROW -->

# Pending Security Phases

| Phase | Goal | Primary outputs |
|---|---|---|
| Phase 8 Infrastructure and Release Prerequisite Closure | Authorize staging/signing/accounts and prove TLS, DB, storage, backup, KMS, logging and monitoring | Sanitized external evidence and company-signed candidate |
| Phase 9 Manual and Staging Revalidation | Close P-09/P-16/P-22/P-25/P-37 and P-11/P-31/P-36 where all exit criteria pass | Device/UI/API/admin evidence packs |
| Phase 10 Legal Management and Operations Closure | Close legal approvals, P-26 signoff, ownership, incident and moderation/support governance | Signed decisions, rosters and rehearsals |
| Phase 11 Independent VAPT P-46 | Assess the exact release candidate independently | Signed VAPT report and finding register |
| Phase 12 Remediation and Independent Retest P-47 | Fix findings, record risk decisions and obtain independent closure | Retest report and residual-risk approval |
| Final Production Security Release Gate | Reconcile one immutable build/evidence set and authorize or reject release | Signed final gate and rollback/monitoring readiness |

# Final Production Release Gate

- [ ] All mandatory P0 controls closed

- [ ] Required P1 controls closed

- [ ] Manual verification complete

- [ ] Staging validation complete

- [ ] Infrastructure evidence complete

- [ ] Signed release artifact validated

- [ ] Legal approval complete

- [ ] Management and operations signoff complete

- [ ] Incident readiness complete

- [ ] Monitoring enabled

- [ ] Backup restore proven

- [ ] VAPT complete

- [ ] Critical findings closed

- [ ] High findings closed or formally accepted

- [ ] Independent retest complete

- [ ] Store declarations match actual behavior

- [ ] Rollback tested

- [ ] Final risk signoff complete

Current result: no release-gate approval. NOT PRODUCTION READY.

# Evidence and Report Index

| Evidence group | Authoritative or latest artifact | Purpose |
|---|---|---|
| Current status | AMORAA_ACTUAL_VERIFICATION_STATUS.md | 51-control mutually exclusive ledger |
| Real verification | AMORAA_SECURITY_REAL_VERIFICATION_REPORT.md | Evidence reconciliation and phase appendices |
| Phase 3 | AMORAA_PHASE3_DATABASE_VALIDATION_REPORT.md | Isolated DB, migrations and 347-test baseline |
| Phase 4 | AMORAA_PHASE4_EVIDENCE_CLOSURE_REPORT.md | P-13 closure and evidence packs |
| Phase 5 | AMORAA_PHASE5_REPOSITORY_GAP_REPORT.md | P-20/P-26 implementation and latest regressions |
| Phase 6 | AMORAA_PHASE6_MANUAL_EVIDENCE_REPORT.md | Manual attempt and APK result |
| Phase 7 | AMORAA_PHASE7_STAGING_DEVICE_VALIDATION_REPORT.md | Current prerequisite state |
| Manual register | MANUAL_VERIFICATION_REGISTER.md | 31 broader human checks; all unverified |
| Infrastructure | REAL_WORLD_VERIFICATION_REGISTER.md | External systems and proof |
| Legal | LEGAL_VERIFICATION_REGISTER.md | Ten pending counsel decisions |
| Management | MANAGEMENT_OPERATIONS_SIGNOFF.md | Unassigned operational roles |
| Release gate | PRODUCTION_SECURITY_RELEASE_GATE.md | Current release decision |
| Human pack | PHASE7_HUMAN_EXECUTION_CHECKLIST.md | Exact future evidence capture tasks |

## Report reconciliation and discrepancies

- The initial repository final report recorded 0 complete because runtime execution had not yet occurred. It is historical and is superseded by the current 7-control ledger.

- Phase 2 recorded 3 complete, Phase 3 recorded 5, Phase 4 recorded 6 and Phase 5 raised the current total to 7. Phase 6 and Phase 7 added no completions.

- Backend totals progressed from a DB-blocked Phase 2 attempt to 347, 350 and finally 356 passing tests. The latest result is 356/356.

- Flutter progressed from 658 passing tests in Phase 2 to 659 in Phase 5; 14 skips remain. Analysis still exits 1 with 44 warning/info findings.

- Older SECURITY_REMEDIATION_MATRIX and initial final-report rows retain pre-runtime PARTIAL labels. Current status must come from AMORAA_ACTUAL_VERIFICATION_STATUS.md.

- The manual register has 31 verification rows, while only 5 controls have manual evidence as their primary ledger status. This is scope, not a count error.

- The management/operations headline count of 11 combines 10 management-primary controls with P-26 operations/policy signoff; controls are not double-counted in the 51-control ledger.

<!-- PAGE BREAK -->

# One Page Senior Summary

| Measure | Result |
|---|---|
| Original pending controls | 51 |
| Verified complete | 7 |
| Remaining | 44 |
| P0 | 6 complete / 29 remaining |
| P1 | 1 complete / 14 remaining |
| P2 | 0 complete / 1 remaining |
| Repository gaps | 0 |
| Manual pending | 5 |
| Staging pending | 3 |
| Infrastructure pending | 13 |
| Legal pending | 10 |
| Management / operations pending | 11 |
| VAPT pending | 2 |
| Latest backend tests | 356 passed; 0 failed; 0 blocked |
| Latest Flutter tests | 659 passed; 0 failed; 14 skipped |
| Production accessed | NO |
| Next phase | Phase 8 Infrastructure and Release Prerequisite Closure |
| Recommendation | READY FOR NEXT SECURITY VALIDATION STAGE — NOT PRODUCTION READY |

## Top Five Management Actions

- Authorize the exact staging environment, scope, owners and test window.

- Provide dedicated Android/iOS test capability and safe dummy user/admin/MFA identities.

- Establish company-controlled signing and produce final APK/AAB/IPA candidates.

- Authorize infrastructure evidence collection and engage qualified legal review.

- Select and fund an independent VAPT provider plus remediation/retest window.
