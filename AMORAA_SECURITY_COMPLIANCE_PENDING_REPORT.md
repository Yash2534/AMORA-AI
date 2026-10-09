# AMORAA Security & Compliance — Pending Items & Completion Plan

## 1. Executive Summary

Fifty-one of 62 merged controls remain pending. Controls are merged only where the two supplied documents describe the same outcome. The status labels below reflect repository evidence, not checklist status. Partial implementation, missing runtime proof, or external ownership is never counted as complete.

| Priority | Pending controls | Meaning |
|---|---:|---|
| P0 | 35 | Launch blocker or critical security/privacy gap |
| P1 | 15 | Required before production readiness |
| P2 | 1 | Ongoing assurance and operational maturity |
| **Total pending** | **51** | |

Status breakdown: 34 `PENDING — PARTIAL`; 8 `PENDING — MANUAL VERIFICATION`; 5 `PENDING — MISSING`; 2 `PENDING — LEGAL VERIFICATION`; 2 `PENDING — EXTERNAL VAPT`. Counts are by primary status; a control may have additional external/legal dependencies. No valid VAPT report or retest was found. The security-drill control is P2 ongoing assurance; the remaining pending controls affect production readiness.

## 2. Pending Matrix

| ID | Category | Requirement | Current State | Missing | Priority | Owner | Evidence |
|---|---|---|---|---|---|---|---|
| P-01 | Secrets | Remove default development administrator password and credential logging; scan repository/history/build artifacts | PARTIAL — a dev-only seed is guarded by `NODE_ENV=development`, but contains a fallback credential and logs its value | Remove fallback and all credential-bearing logs; audit history, generated APKs and shared artifacts; rotate if ever reused/exposed | P0 | Backend + Security | `Backend/src/config/seedDefaultAdmin.js` |
| P-02 | API transport | Eliminate HTTP production admin origin | PARTIAL — production CORS explicitly permits one hardcoded HTTP origin | Move admin to HTTPS, remove exception, confirm proxy/TLS and browser behavior | P0 | DevOps | `Backend/src/config/originPolicy.js`; `Backend/src/server.js` |
| P-03 | TLS | Prove TLS 1.2+, HTTPS/WSS, redirects and certificate lifecycle for app/API/admin | PARTIAL — backend creates plain HTTP server and expects upstream TLS; Flutter endpoint/environment configuration and edge config do not prove deployment TLS | Deployment-owned TLS termination, protocol/cipher settings, redirect, HSTS, WSS, certificate renewal, real device verification | P0 | DevOps | `Backend/src/server.js`; `lib/core/config/` (endpoint configuration); no proxy/deployment configuration found |
| P-04 | Encryption | Database encryption at rest and MySQL transport encryption | PARTIAL — Sequelize MySQL connection has no TLS options; provider encryption is external | Evidence of encrypted volume/service, TLS connection, key ownership/access and restore behavior | P0 | Infrastructure | `Backend/src/config/db.js`; `Backend/src/config/env.js` |
| P-05 | Backup/recovery | Encrypted backups, separate credentials, tested restore, RPO/RTO and disaster recovery | MISSING in repository | Written procedures, encrypted backup configuration, isolated credentials, restore and DR evidence | P0 | DevOps + Database | No backup/restore policy or script located; `Backend/src/config/db.js` |
| P-06 | Media privacy | Private profile/verification media and authorized short-lived delivery | PARTIAL — profile images are served through public Express static `/uploads`; identity and chat files are private local paths with authenticated download paths | Private profile object storage, authorization or expiring signed URLs, storage encryption/access policy, deployment bucket/mount verification | P0 | Backend + Infrastructure | `Backend/src/server.js`; `Backend/src/utils/photoStorage.js`; `Backend/src/utils/identityVerificationStorage.js`; `Backend/src/utils/chatMediaStorage.js` |
| P-07 | Sensitive exports | Encrypt and protect generated/exported personal data | PARTIAL — `privacyRequest` models/services exist; a legacy export route builds an in-memory bundle and persists JSON in a DB record | Confirm current client path, minimize fields, encrypt export artifact/storage, authorization, expiry, deletion and access evidence | P0 | Backend + Privacy | `Backend/src/controllers/privacyController.js`; `Backend/src/services/privacyExportArtifactService.js`; `Backend/src/models/PrivacyExportArtifact.js` |
| P-08 | Key management | Separate encryption keys from data; restricted key access and rotation | PARTIAL — an admin MFA encryption key is required in production; no general data/storage key-management evidence | KMS/secrets manager ownership, separation, IAM, rotation and recovery proof | P0 | Infrastructure/Security | `Backend/src/config/env.js`; storage and DB configuration |
| P-09 | Mobile secrets | No API/provider secrets in Flutter source, APK/IPA or build config | MANUAL VERIFICATION — source has API/provider integration code and Android conditionally applies Firebase config; no APK/IPA scan was run | Review all build variants, assets, Firebase config, generated binaries and CI injection; document public client identifiers separately from secrets | P0 | Mobile + Security | `lib/`; `android/app/build.gradle.kts`; `android/app/google-services.json` presence not confirmed |
| P-10 | Secrets operations | Environment/secrets-manager use, repo/CI scanning, rotation and dev/stage/prod separation | PARTIAL — backend expects environment variables; no CI workflows, committed scanner config, rotation runbook, or per-environment evidence found | Add Git/CI secret scan; use managed secret store; inventory and rotate exposed credentials; prove isolated credentials | P0 | DevOps + Security | `Backend/src/config/env.js`; `Backend/src/config/bootstrapEnv.js`; no `.github/workflows` or deployment secret policy found |
| P-11 | Mobile network/session | HTTPS API use, certificate validation, no cleartext, secure local token storage | PARTIAL — `flutter_secure_storage` is a dependency, but its use and platform options need route-by-route verification; backend URL/TLS deployment is unproven | Verify all API/socket URLs, release behavior, token persistence/clear, Android network config and iOS ATS; test interception on staging | P0 | Mobile + DevOps | `pubspec.yaml`; `lib/core/`; `android/app/src/main/AndroidManifest.xml`; iOS project config |
| P-12 | CERT-In logging | Applicable security logs retained at least 180 days and in required location | MANUAL VERIFICATION — console logging and database event models do not prove central retention or location | Confirm applicability/interpretation with counsel; implement log sink, India location if required, retention lock and measured evidence | P0 | Security + Legal + DevOps | `Backend/src/utils/logger.js`; `Backend/src/models/UserLoginEvent.js`; no log platform configuration found |
| P-13 | Security event coverage | Login, API access, admin actions, privilege changes, security errors, moderation, critical account/data events | PARTIAL — login and admin audit models/services exist; full API/access and security-event coverage is not established | Define event catalog, cover success/failure and sensitive changes, verify owner/admin/moderation paths and ensure no gaps | P0 | Backend + Security | `Backend/src/models/UserLoginEvent.js`; `Backend/src/services/adminAuditService.js`; `Backend/src/middleware/adminAuditMiddleware.js`; report/safety controllers |
| P-14 | Log protection | Exclude passwords/OTP/full tokens/raw IDs; least-privilege access, tamper resistance, time sync, monitoring | PARTIAL — sanitizers exist but are key-name based and incomplete; audit integrity chain is in source; centralized access, retention, clock sync and alerts are external | Expand redaction, eliminate direct console credential output, deploy restricted append-only sink, sync clocks and alert on suspicious patterns | P0 | Security + DevOps | `Backend/src/utils/logger.js`; `Backend/src/services/adminAuditService.js`; `Backend/src/config/seedDefaultAdmin.js` |
| P-15 | Regulatory incident reporting | CERT-In process and 6-hour workflow for applicable incidents | PENDING — LEGAL VERIFICATION — checklist states six hours for specified incidents; no operational process or legal applicability record found | Counsel/security must document incident scope, current rule, trigger, clock owner, contact/account access and rehearsal | P0 | Legal + Security | No incident procedure found; supplied Word checklists only |
| P-16 | Data minimization/permissions | Necessary data only; no unnecessary contacts/full-gallery/precise location; contextual permission explanation | PARTIAL — app requests coarse/fine location, camera, media images/video and notifications; user journey purpose timing and minimization not fully verified | Remove unneeded OS permissions, use selected-photo access where feasible, contextual rationale, inventory collection and test denied/one-time grants | P0 | Product + Mobile + Privacy | `android/app/src/main/AndroidManifest.xml`; `lib/` permission/location/media flows |
| P-17 | Privacy notice/Terms | Accurate published policy, processing purposes, retention, sharing, rights, grievance details | PARTIAL — in-app legal/version registry and privacy notice code exist, but public policy accuracy and company/DPO identity conflict with project context and require approval | Reconcile legal entity/contact, policies and actual processing; publish stable URLs; verify notices in app/store | P0 | Legal + Product | `Backend/src/controllers/privacyController.js`; `Backend/src/services/consentService.js`; `lib/features/legal/`; `Backend/docs/DPDP_CONTROL_MATRIX.md` contains unsupported broad PASS claims |
| P-18 | Consent/withdrawal | Purpose-specific consent and withdrawal with durable evidence and actual processing stop | PARTIAL — versioned signup acknowledgements exist; separate purpose consent code is in legacy `/api/v1/privacy`; no verified end-to-end stop behavior for every purpose | Choose one canonical API/schema, distinguish notice from consent, validate purpose, append events, propagate withdrawal to processors/features and verify client UX | P0 | Product + Backend + Legal | `Backend/src/services/consentService.js`; `Backend/src/controllers/privacyController.js`; `Backend/src/models/ConsentEvent.js`; `Backend/src/models/UserConsent.js` |
| P-19 | Account deletion | Complete personal-data/media/chat/verification/vendor/backup lifecycle with approved retention exceptions | PARTIAL — OTP-confirmed deletion anonymizes account, removes many associated rows and attempts file cleanup; archive, reports/audit/consent/grievance and backup/vendor lifecycle are not fully defined | Map every personal-data table/file/vendor, approve exceptions, cascade/anonymize consistently, handle failed file tasks/backups and produce completion evidence | P0 | Backend + Privacy + Legal | `Backend/src/controllers/accountController.js`; `Backend/src/services/immediateAccountDeletionService.js`; deletion migrations under `Backend/src/migrations/202609*` |
| P-20 | Deactivation | Password confirmation, access restriction, restoration and retention behavior | PARTIAL — local password check, status change, token/device revocation and reactivation flow exist; Google accounts cannot use this password-only path and deletion/retention language is not evidenced | Define provider-neutral reauthentication, confirm visibility/search/chat/notifications exclusion and retention rules, test restore and abuse cases | P1 | Product + Backend + Privacy | `Backend/src/controllers/accountController.js`; `Backend/src/controllers/authController.js`; `Backend/src/services/discoverEligibilityPolicy.js` |
| P-21 | Data inventory/retention | Field-to-purpose/legal basis/storage/retention/recipient mapping and operational expiry | PARTIAL — `DATA_INVENTORY.md` exists but contains values/retention claims not verified against schema or jobs; no general cleanup scheduler found | Rebuild inventory from models/migrations and runtime vendors; legal approval; implement scheduled lifecycle and verify backups/soft deletes | P0 | Privacy + Backend + Legal | `Backend/docs/DATA_INVENTORY.md`; `Backend/src/models/`; `Backend/src/migrations/` |
| P-22 | Data-principal requests | Authenticated access/export/correction/erasure request intake, status, completion and evidence | PARTIAL — privacy request routes/models/services, confirmation and export artifact models exist, but user-facing flow, complete data scope, notification/SLA and runtime verification are unresolved; older export/grievance routes coexist | Select canonical route, test authorization/step-up and cross-user boundaries, implement queue/status/outcomes, expiry and approved deadline tracking | P1 | Privacy + Backend + Product | `Backend/src/routes/privacyRequestRoutes.js`; `Backend/src/controllers/privacyRequestController.js`; `Backend/src/services/privacyRequestService.js`; `lib/features/privacy/presentation/data_export_screen.dart` |
| P-23 | Vendors/processors | Processor inventory, region, contract/DPA/security review and deletion obligations | MISSING — no complete repository-backed register or executed agreements | Inventory SMS/email, Google/Firebase, payments, AI, analytics, hosting and store processors; obtain DPAs, transfer/security/deletion terms and review evidence | P1 | Legal + Procurement + Security | Integrations in `Backend/src/utils/`, `Backend/src/controllers/`, `pubspec.yaml`, `Backend/package.json`; no vendor register found |
| P-24 | AI transparency | Disclose data sent to AI/matching/moderation/recommendation services and vendor controls | PARTIAL — matching services and AI-related product screens exist; no verified data-flow/vendor register or approved disclosures | Trace outbound payloads, identify providers/regions/logging/retention, minimize inputs, update notice and test no secret/PII leakage | P1 | Product + Backend + Privacy | `Backend/src/services/matchEngineService.js`; `Backend/src/services/aiMatchProvider.js`; matching controllers; `AMORA_MATCH_AI_OPTIMIZATION_REPORT.md` |
| P-25 | 18+ enforcement | Server-side date-of-birth validation, age gate and under-age response | PARTIAL — Flutter DOB widget enforces 18; backend onboarding age route stores `birthDate` without demonstrated age check in its route/controller | Enforce age at server trust boundary on signup/onboarding and profile updates; define under-age block/deletion and appeal handling | P0 | Product + Backend | `lib/core/widgets/amora_dob_field.dart`; `Backend/src/controllers/onboardingController.js`; `Backend/src/routes/onboardingRoutes.js` |
| P-26 | Phone identity | Phone OTP at signup and one-account/duplicate or recycled-number control | PARTIAL — phone verification and uniqueness constraints exist; recycled-number policy, account recovery/number reassignment protections and full end-to-end proof remain absent | Define uniqueness and reassignment lifecycle, reverify changes, prevent takeover of old account, test duplicate/recycled cases | P1 | Product + Backend | `Backend/src/controllers/authController.js`; `Backend/src/services/otpService.js`; `Backend/src/models/User.js` |
| P-27 | Identity verification | Selfie/liveness/photo badge and optional ID vendor strategy with minimum raw-ID retention | PARTIAL — Aadhaar and selfie file intake/admin review exists; no liveness evidence, vendor contract, raw-ID expiry/deletion scheduler, encryption or malware/EXIF control | Approve necessity/purpose and provider; implement liveness if claimed, retention and deletion, staff access, scanning/metadata safeguards, badge criteria | P0 | Product + Privacy + Backend | `Backend/src/controllers/identityVerificationController.js`; `Backend/src/utils/identityVerificationStorage.js`; `Backend/src/models/IdentityVerification.js` |
| P-28 | Fake-account prevention | Bot/risk signals, device controls, Play Integrity and abuse detection | PARTIAL — user device registration and endpoint rate limits exist; no Play Integrity or demonstrated bot/risk scoring/monitoring | Decide risk signals with privacy review, server-verify platform attestation, alert and tune abuse controls, document false-positive appeal | P1 | Mobile + Backend + Security | `Backend/src/routes/deviceRoutes.js`; `Backend/src/controllers/deviceController.js`; `Backend/src/middleware/rateLimiter.js`; no Play Integrity implementation found |
| P-29 | Dating safety | Report/block/unmatch, moderation queues, human escalation and response SLA | PARTIAL — report/block and admin safety/chat moderation routes exist; human staffing, response SLA, content moderation coverage and tested enforcement are not evidenced | Define queue ownership/SLA/escalation, moderation coverage for profiles/photos/chat, evidence controls and user feedback; test abuse cases | P0 | Safety/Product + Operations | `Backend/src/routes/reportRoutes.js`; `Backend/src/routes/blockRoutes.js`; `Backend/src/routes/adminSafetyRoutes.js`; `Backend/src/controllers/adminChatController.js`; `lib/features/safety/` |
| P-30 | Anti-scam | Spam, impersonation, financial solicitation and repeat-abuse controls | PARTIAL — rate limits and reports provide basic mechanisms; no policy/rules/model, repeat-offender workflow or detection evidence found | Define abuse taxonomy and escalation, implement detection and account action workflow, publish user guidance, measure false positives and closure | P1 | Safety + Product + Backend | `Backend/src/middleware/rateLimiter.js`; report/admin safety routes; `lib/features/support/` |
| P-31 | Location privacy | Hide exact location; expose only coarse distance; incognito/visibility controls | PARTIAL — discovery uses match coordinates and distance; exact output serialization and real-device/API exposure not security-tested; no verified incognito control | Review public serializers and every endpoint/log/export, quantize/suppress distance/location, test triangulation and hidden/deactivated/blocked users | P0 | Backend + Product + Security | `Backend/src/controllers/discoverController.js`; `Backend/src/services/publicProfileService.js`; `Backend/src/controllers/locationController.js`; `Backend/src/utils/geoDistance.js` |
| P-32 | Grievance/support | Clear published grievance/contact channel and authenticated case handling | PARTIAL — grievance API and privacy-request support models exist; public code embeds an unverified entity/contact identity and exposes ticket status without authentication/ownership proof | Verify entity/contact with counsel, secure status lookup using confirmation token, add abuse throttling and SLA/evidence workflow | P1 | Legal + Support + Backend | `Backend/src/controllers/privacyController.js`; `Backend/src/routes/privacyRoutes.js`; `Backend/src/models/PrivacyGrievance.js` |
| P-33 | API abuse controls | Brute-force, OTP, messaging and sensitive endpoint throttling in production topology | PARTIAL — in-process express-rate-limit policies exist for multiple routes; shared/distributed store, proxy correctness and alerting are unproven | Configure shared store at production scale, validate trusted proxy/IP extraction, add lockout/abuse alerts and load-safe thresholds | P0 | Backend + DevOps | `Backend/src/middleware/rateLimiter.js`; `Backend/src/server.js`; route definitions |
| P-34 | Session revocation | Password change invalidates existing sessions; refresh/logout/session management is complete | PARTIAL — password reset revokes refresh rows; password change does not; user access JWT is 15 minutes and token-version invalidation exists for some lifecycle operations | Increment token version and revoke refresh sessions after password change; add session listing/revocation if required; verify client token cleanup | P0 | Backend + Mobile | `Backend/src/controllers/authController.js`; `Backend/src/middleware/authMiddleware.js`; `Backend/src/models/RefreshToken.js` |
| P-35 | SQL/ORM safety | Parameterized queries, safe ORM usage and injection verification across APIs | PARTIAL — Sequelize is used broadly; raw SQL/literals also exist and no injection test result is present | Inventory raw SQL/literals, bind/escape untrusted values, review dynamic identifiers and run isolated injection regression tests | P0 | Backend + Security | `Backend/src/`; especially discovery/matching query services and migration SQL |
| P-36 | API validation/headers/CORS | Complete route validation, production-safe errors, secure headers, restrictive CORS | PARTIAL — Helmet, JSON body limit, validation middleware and CORS config exist; some routes use legacy validation and a production HTTP allowlist exception remains | Route audit, explicit allowed origins, remove HTTP exception, sanitize status-bearing errors, verify headers/OPTIONS and production responses | P1 | Backend + DevOps | `Backend/src/server.js`; `Backend/src/config/originPolicy.js`; `Backend/src/middleware/errorHandler.js`; `Backend/src/routes/` |
| P-37 | Admin hardening | Universal admin MFA, granular RBAC, session timeout, no shared admins, destructive-action approval | PARTIAL — MFA and RBAC components exist, but no proof all routes enforce recent MFA, session timeout, two-person approval, or current roster hygiene; dev fallback credential also exists | Map every route to permission/step-up, harden seed, set session/idle controls, approvals for destructive actions and test privilege boundaries | P0 | Admin + Backend + Security | `Backend/src/routes/adminRoutes.js`; `Backend/src/admin/permissions.js`; `Backend/src/middleware/adminMfaMiddleware.js`; `Backend/src/config/seedDefaultAdmin.js` |
| P-38 | Ownership/access | Company ownership of Git/org, cloud/root, DNS, DB, Play/Apple, analytics/ad accounts; least privilege, MFA, register, offboarding/review | MANUAL VERIFICATION — repository cannot establish account ownership or external MFA | Inventory owner, admins, roles, recovery factors, MFA and offboarding; transfer to company-controlled accounts; scheduled recertification | P0 | Management + IT/Security | No authoritative ownership/access register found |
| P-39 | Audit logging | Admin/privilege/moderation/data-change audit coverage, retention/access restrictions and monitoring | PARTIAL — audit model, middleware and integrity-chain verification exist; append-only enforcement, broad PII redaction, log retention and alert delivery are unverified | Complete event coverage and redaction review; restrict database access; configure retention/monitoring and test integrity checks | P1 | Security + Backend + DevOps | `Backend/src/services/adminAuditService.js`; `Backend/src/middleware/adminAuditMiddleware.js`; `Backend/src/models/AdminAuditLog.js`; `Backend/src/controllers/adminCatalogController.js` |
| P-40 | Database exposure | Database not public; network/identity restrictions and separate application/backup identities | MANUAL VERIFICATION — schema/config show MySQL connection inputs only | Verify network ACL/firewall, private endpoint, TLS, least-privilege grants, service accounts and external exposure using cloud/DB console evidence | P0 | Database + Infrastructure | `Backend/src/config/db.js`; no infrastructure-as-code or DB firewall config found |
| P-41 | Store readiness | Org accounts, UGC policy, deletion URL, privacy URL, Data Safety/App Privacy, age rating, permissions, reviewer OTP/demo access | MANUAL VERIFICATION — no store submission/account artifacts present | Complete current Play/Apple forms from observed data flows; publish URLs; provision reviewer access and deletion mechanism; verify policy declarations | P1 | Product + Legal + Release | Android/iOS app configs; `Backend/src/routes/accountRoutes.js`; no console submission evidence found |
| P-42 | Release build | Hardened/signed release, debug disabled, Android exported/deep links, backup/local storage review | PARTIAL — Android release build currently signs with debug signing config; main manifest has exported launcher; backup enabled; no custom deep link filter shown | Configure production signing/secret custody, inspect merged manifest/dependencies, disable unnecessary backup and validate secure storage/exported components | P0 | Mobile + Release | `android/app/build.gradle.kts`; `android/app/src/main/AndroidManifest.xml`; `android/app/src/main/res/xml/backup_rules.xml`; iOS project config |
| P-43 | Secure SDLC | Protected branches, required reviews, SAST/dependency/secret scans, SBOM, patching, unused dependency cleanup, and security review after major auth/payment/API/cloud/KYC/database/media/chat changes | MANUAL VERIFICATION — no CI workflow or branch-protection evidence found; lockfiles alone are not scan evidence | Enable branch rules and automated scans, generate SBOM, define patch SLA and major-change review trigger, document exceptions, run scan against release commit | P1 | Engineering + DevOps | `package-lock.json`; `Backend/package-lock.json`; `pubspec.lock`; no `.github/workflows` found |
| P-44 | CI/CD | Restricted CI secrets, deployment approval, no direct production push, release changelog/approver/rollback | MANUAL VERIFICATION — no CI/deployment pipeline or production change records found | Implement protected deploy workflow, reviewers/environments, least-privilege secrets, release notes, approval and tested rollback | P1 | Release + DevOps | No repository CI/CD/deployment config found; package scripts only |
| P-45 | Production monitoring | Login abuse, admin/privilege changes, exports, API failures, storage exposure and service outage alerts | MISSING in repository evidence | Configure metrics/alerts, on-call routing and dashboard; test alert delivery with safe staging events | P1 | SRE + Security | `Backend/src/utils/logger.js`; no alert/monitoring configuration found |
| P-46 | Independent VAPT | Pre-launch, periodic 6–12 months and major-change external VAPT across mobile/API/admin/cloud/DB/storage/auth/business logic | PENDING — EXTERNAL VAPT — no valid independent report/certificate found | Engage qualified independent tester (CERT-In empanelled auditor recommended by supplied checklist); define authorization and full scope | P0 | Security + Management | No VAPT artifact found; source code review is not a substitute |
| P-47 | VAPT closure | Track Critical/High findings, risk acceptance, remediation, independent retest and closure evidence | PENDING — EXTERNAL VAPT — no findings register, risk acceptance, retest or closure evidence found | Assign owners/dates, fix Critical before launch, fix High or formally accept with compensating controls, obtain retest | P0 | Security + Engineering + Management | No VAPT finding/closure pack found |
| P-48 | Incident response | Written incident playbook for detection, triage, severity, containment, token/secret revocation, isolation, evidence, investigation and recovery | MISSING — no incident runbook found in repository docs/config | Approve runbook, evidence custody, affected-data assessment, technical response steps, recovery and post-incident review | P0 | Security + Backend + SRE | No incident-response document found |
| P-49 | Incident ownership | Named commander/security, backend/infra, product/ops, legal/DPDP, communications/support and management approver | MANUAL VERIFICATION — no named ownership roster/critical escalation path found | Name primary/backup owners and contacts; publish 24/7 escalation path and authority to contain/notify | P1 | Management | Supplied checklist role table is not an AMORAA assignment record |
| P-50 | Breach notification readiness | Current DPDP/DPB process, legal review, deadline tracking, CERT-In/user notices, contacts and 24/7 path | PENDING — LEGAL VERIFICATION — checklist itself requires verification | Counsel verifies rules/triggers/timing, records sources/effective dates, prepares templates/support scripts and tests deadline clock | P0 | Legal + Support + Security | No legal opinion, current rule register, templates or contact tree found |
| P-51 | Security drills | Tabletop exercises for credential leak, public media, admin compromise, DB exfiltration, OTP abuse, server compromise and third-party breach; actions tracked to closure | PENDING — MISSING — no exercise record/action closure evidence found | Schedule scenarios, assign participants, exercise containment/evidence/notification, track owners and close actions | P2 | Security + Legal + Operations | No drill evidence found in repository |

### Sensitive Search Results (Redacted)

- `Backend/src/config/seedDefaultAdmin.js` (around lines 8–12, 38–43): hardcoded development administrator fallback credential; logging includes the credential. **Category:** password/default credential. **Severity/priority:** P0 before repository distribution or production use; whether it was ever used outside development is unknown. The value is intentionally omitted. Remove it and any related logs; rotate if reused or exposed.
- `Backend/src/config/originPolicy.js` (around lines 18–31): explicit production HTTP origin exception for the admin web client. **Category:** insecure transport allowlist. **Priority:** P0. Remove after serving the admin site only over HTTPS.
- No credential values are reproduced. Static keyword matches in tests/Postman data included dummy credentials, tokens, OTP fixtures and localhost URLs and were not treated as production secrets. This search was not a Git-history scan and does not establish that no secret exists in history, binaries, ignored files, or external systems.

## 3. Step-by-Step Completion Plan

Each plan below maps one-to-one to a pending matrix ID. Priority, owner and source evidence are in the matrix.

### P-01 — Remove development seed credential

Current implementation: development-only admin seeding has a credential fallback and logs it. What is missing: no fallback, no credential output, no reuse/history check. Why it matters: a predictable credential can escape development and logs can persist it. Risk: administrator takeover if the credential is reachable/reused. Files: `Backend/src/config/seedDefaultAdmin.js`. Recommended owner: Backend + Security.

Steps to complete:
1. Remove the fallback and require a one-time, externally supplied development secret or interactive setup.
2. Remove password-bearing logs; log only non-sensitive seed outcome.
3. Search source, Git history, artifacts and release packages with a secret scanner; suppress values in evidence.
4. Rotate/disable any matching credential if it was ever used or shared.
5. Add a regression check that rejects credential output and production seed behavior.

Validation: source scan and captured test logs contain no credential; production config cannot seed a default admin. Exit criteria: reviewed commit, clean secret scan/history disposition and rotation record where applicable.

### P-02 — Remove production HTTP admin origin

Current implementation: production origin parser accepts one hardcoded HTTP origin. What is missing: HTTPS-only admin origin. Why it matters: browser traffic can be intercepted or altered. Risk: admin session/API actions exposed in transit. Files: `Backend/src/config/originPolicy.js`; `Backend/src/server.js`. Owner: DevOps.

Steps: 1. Provision HTTPS admin domain and valid certificate. 2. Change production `CORS_ORIGIN` to HTTPS origin only. 3. Remove the source exception. 4. Verify redirect/HSTS and admin API origin checks on staging. 5. Add config test rejecting all HTTP production origins.

Validation: production config unit test and safe staging browser/network inspection. Exit criteria: no HTTP production exception, HTTPS-only origin, evidence of TLS and HSTS.

### P-03 — Prove end-to-end TLS

Current implementation: Express creates an HTTP server; edge TLS is external. Missing: verifiable TLS configuration for mobile/API/admin/socket and certificate lifecycle. Why/risk: credentials and sensitive content may traverse plaintext. Files: server, Flutter API config, deployment edge (not present). Owner: DevOps + Mobile.

Steps: 1. Inventory API/socket endpoints per build flavor. 2. Configure TLS 1.2+ and disable obsolete protocols. 3. Redirect HTTP and configure HSTS/WSS. 4. verify certificate renewal and trusted proxy headers. 5. Test release app traffic and negative HTTP behavior on staging.

Validation/exit: protocol scan and real-device request capture against staging; deployment config/certificate ownership evidence.

### P-04 — Database encryption in transit/at rest

Current: MySQL via Sequelize without TLS options in source. Missing: DB TLS and provider encryption evidence. Why/risk: database snapshots/network path expose personal data. Owner: Database + Infrastructure.

Steps: 1. Choose managed DB/volume encryption and KMS. 2. Enable required TLS and verify CA/hostname. 3. restrict key and DB identities. 4. Verify encrypted snapshots and fail-closed TLS. 5. document key rotation/recovery.

Validation/exit: DB connection config and provider console evidence; test TLS-required connection and storage encryption without exporting real data.

### P-05 — Encrypted backups and restore readiness

Current: no backup/restore policy evidence. Missing: encryption, separate credentials, RPO/RTO, restore/DR tests. Why/risk: breach and outage can expose or lose sensitive records. Owner: DevOps + Database.

Steps: 1. Define data scope and RPO/RTO. 2. Configure scheduled encrypted backups and isolated credentials. 3. restrict backup access and retention. 4. restore into isolated environment. 5. record recovery timing and corrective actions.

Validation/exit: restore report, encryption/access evidence and approved DR runbook.

### P-06 — Private media delivery

Current: profile media is public static; ID/chat media have private local storage code. Missing: private profile media and production bucket/access proof. Why/risk: profile or identity media can be enumerated or exposed. Owner: Backend + Infrastructure.

Steps: 1. Decide media classification and access rules. 2. Move profile media behind authenticated authorization or short-lived signed URLs. 3. apply encryption and least-privilege bucket policy. 4. add metadata stripping/scanning and lifecycle deletion. 5. test unauthorized, expired URL, deletion and deactivated-account paths.

Validation/exit: anonymous requests cannot fetch protected files; signed URLs expire; deployed bucket policy/encryption and deletion evidence retained.

### P-07 — Protect sensitive exports

Current: newer privacy request/artifact pieces coexist with a legacy inline export. Missing: one canonical, minimized, encrypted, expiring export flow. Why/risk: broad personal records can leak through API, DB or logs. Owner: Backend + Privacy.

Steps: 1. Select canonical endpoint and remove/disable duplicate. 2. enumerate export fields and redact third-party data. 3. encrypt private artifact and restrict reads. 4. enforce step-up, expiry and deletion. 5. verify logs omit content and other users' data.

Validation/exit: authorization tests, encrypted artifact evidence, expiry/deletion test and approved field manifest.

### P-08 — Central key management

Current: production config requires an admin MFA encryption key; no general KMS evidence. Missing: separated data keys, IAM, rotation and recovery. Owner: Infrastructure/Security.

Steps: 1. Inventory keys and protected data. 2. move keys to managed KMS/secrets manager. 3. scope access by workload/role. 4. rotate with rollback/recovery procedure. 5. audit and alert key access.

Validation/exit: KMS policy, access audit and rotation drill; no keys in source or logs.

### P-09 — Scan mobile packages for secrets

Current: Flutter source and Android build config are present; release binary scan not performed. Missing: APK/IPA evidence and build-secret handling. Why/risk: embedded credentials are extractable. Owner: Mobile + Security.

Steps: 1. inventory public IDs vs secret credentials. 2. scan source, assets, config and all release variants. 3. remove server secrets and replace with backend calls. 4. rotate exposed values. 5. add package scan in CI.

Validation/exit: redacted scan evidence for signed APK/IPA and source; only documented public client identifiers remain.

### P-10 — Secret management and rotation

Current: backend reads env vars, but no scanner/CI/deployment config is visible. Missing: managed secrets, separated environments, scanning, rotation. Owner: DevOps + Security.

Steps: 1. inventory secret categories and owners. 2. configure secrets manager and separate credentials. 3. enable pre-commit/repository/CI scans. 4. rotate any exposed values and revoke old credentials. 5. test recovery and alert workflow.

Validation/exit: clean scans including history disposition, secret manager policy and recorded rotation without secret values.

### P-11 — Secure Flutter transport and local token storage

Current: secure-storage dependency exists; usage/options and full URL inventory are unverified. Missing: proof of HTTPS, certificate behavior, token clear/backup controls. Owner: Mobile + DevOps.

Steps: 1. trace auth tokens through all code paths. 2. ensure platform-backed secure storage and clear-on-logout/delete. 3. inventory API/socket URLs. 4. enforce HTTPS and secure platform network settings. 5. verify on Android/iOS release devices.

Validation/exit: code review plus staging traffic capture and storage/logout test; no cleartext endpoint or token in ordinary preferences/logs.

### P-12 — CERT-In log retention and location

Current: application logs/events exist but retention and region are operational. Missing: counsel interpretation and deployed retention proof. Owner: Security + Legal + DevOps.

Steps: 1. counsel maps applicable log categories/retention/location. 2. select India-located sink if required. 3. configure 180-day retention and access controls. 4. verify ingestion/time sync and deletion lock. 5. retain evidence of a full retention configuration review.

Validation/exit: legal sign-off and sanitized log-platform configuration/export showing correct region and retention.

### P-13 — Security event coverage

Current: login and admin audit data exist; universal event coverage is not shown. Missing: event catalog and route coverage. Owner: Backend + Security.

Steps: 1. define required event types and fields. 2. map each event to route/service. 3. add missing auth, privilege, API, moderation and data-change events. 4. redact sensitive values. 5. test success/failure and correlation.

Validation/exit: event-to-control map and integration evidence for each event family.

### P-14 — Safe, tamper-resistant logs and monitoring

Current: key-based sanitizers and an admin audit integrity chain exist; development admin seed logs a password. Missing: complete redaction, restricted/immutable sink, synchronized time, retention and alerts. Owner: Security + DevOps.

Steps: 1. eliminate credential output. 2. classify sensitive fields and recursively redact. 3. configure restricted append-only centralized storage. 4. synchronize clocks and alert on integrity/abuse events. 5. verify access and retention.

Validation/exit: synthetic secret-marker test absent from logs; unauthorized log mutation denied; alert and integrity check evidence.

### P-15 — CERT-In incident process

Current: checklist mentions six hours for specified incidents; no runbook/legal record exists. Missing: current scope, owners, clock and contact route. Owner: Legal + Security.

Steps: 1. obtain current legal advice on applicability and reportable events. 2. document detection-to-decision timeline and six-hour clock where applicable. 3. prepare authority account/contact and evidence requirements. 4. assign primary/backup reporter. 5. tabletop test and revise.

Validation/exit: approved procedure with dated authoritative sources and exercise record. Do not treat checklist text alone as legal confirmation.

### P-16 — Minimize collected data and permissions

Current: Android declares location, camera, media and notification permissions. Missing: necessity map, contextual rationale and reviewed actual collection. Owner: Product + Mobile + Privacy.

Steps: 1. map each permission to a feature and field. 2. remove unused/broad access. 3. request only in context and explain purpose. 4. test denial/limited access. 5. update notice and store forms.

Validation/exit: permission-to-purpose register, device test evidence and no unnecessary contacts/full-gallery access.

### P-17 — Approved privacy notice and Terms

Current: versioned in-app docs and notice API exist, but legal entity/contact/disclosures conflict with project naming and actual data flows. Missing: approval and publication. Owner: Legal + Product.

Steps: 1. reconcile company identity and responsible contact. 2. map collection, purposes, sharing, retention, rights and AI. 3. have counsel approve Terms/notice. 4. publish stable URLs and link in app/store. 5. compare disclosures to runtime SDK/API behavior.

Validation/exit: signed approval and public URL snapshots matching the code inventory. No legal conclusion from repository text alone.

### P-18 — Consent and withdrawal

Current: signup event registry exists; legacy purpose-consent API updates mutable records. Missing: canonical event history and downstream stop behavior. Owner: Product + Backend + Legal.

Steps: 1. define which processing needs consent versus notice/contract. 2. consolidate routes and schema. 3. record immutable grants/withdrawals with exact version/purpose. 4. propagate withdrawal to features/processors. 5. test re-consent and withdrawal end-to-end.

Validation/exit: API/UI tests, event history and downstream processing proof; legal approval of purpose mapping.

### P-19 — Deletion lifecycle

Current: OTP-confirmed anonymization and many row/file deletions are implemented. Missing: complete relation inventory, retention exceptions, asynchronous file failure handling, backup/vendor expiry evidence. Owner: Backend + Privacy + Legal.

Steps: 1. map all tables/files/vendors to account ID. 2. approve retained statutory/security records. 3. delete/anonymize each relation and remove media with retryable tasks. 4. expire backups/processor copies per approved policy. 5. verify residual records and audit closure.

Validation/exit: seeded-user deletion test across schema/storage/vendors; legal retention schedule and completion record.

### P-20 — Deactivation lifecycle

Current: local-password reauth, status change, token/device removal and reactivation exist. Missing: provider-neutral step-up and verified visibility/retention behavior. Owner: Product + Backend + Privacy.

Steps: 1. design reauth for local and Google accounts. 2. define discovery/chat/event/payment behavior while inactive. 3. enforce account status across all routes/jobs. 4. define retained data and reactivation period. 5. test deactivate/reactivate/revoke cases.

Validation/exit: full lifecycle tests and approved user-facing policy.

### P-21 — Data inventory and retention schedule

Current: an inventory document exists but is not reliable evidence of current schema/jobs. Missing: verified field map and implemented retention. Owner: Privacy + Backend + Legal.

Steps: 1. enumerate live models/tables/files/events. 2. map purpose/legal basis, location, recipients and retention. 3. obtain approval. 4. implement scheduled deletion/archival per decision. 5. verify jobs and failures.

Validation/exit: schema-reconciled register, approved retention schedule and job execution evidence.

### P-22 — Rights/request handling

Current: routes/models/confirmation/export artifacts exist; UI and complete operational workflow remain unclear. Missing: canonical intake/status/SLA, complete data scope, tested privacy boundary. Owner: Privacy + Backend + Product.

Steps: 1. select canonical flow and disable legacy duplicate. 2. define access/correction/erasure/withdrawal types. 3. implement authenticated step-up, assignment, status and outcome. 4. protect expiring exports. 5. test cross-user access and deadline tracking.

Validation/exit: end-to-end requests for dummy accounts, authorization matrix, expiry/deletion evidence and counsel-approved deadlines.

### P-23 — Processor/vendor register

Current: integrations can be inferred from code/manifests; no authoritative register or contract proof. Missing: vendor purpose/region/DPA/security/deletion review. Owner: Legal + Procurement + Security.

Steps: 1. inventory every processor/SDK. 2. map data categories and regions. 3. review security and contracts/DPAs. 4. restrict payloads and configure deletion. 5. schedule reassessment.

Validation/exit: approved register and executed agreements/review records.

### P-24 — AI and automated processing disclosures

Current: matching logic/features exist; outbound data use and provider handling are not documented. Missing: trace, processor inventory and accurate notice. Owner: Product + Backend + Privacy.

Steps: 1. trace inputs to each algorithm/vendor. 2. identify retention/region/training/logging. 3. minimize and protect payloads. 4. update notice and user-facing explanations. 5. review recommendation/moderation impacts and controls.

Validation/exit: approved AI data-flow map and notice aligned to observed outbound requests.

### P-25 — Server-enforced age gate

Current: Flutter validates 18+; backend onboarding age handler stores date without demonstrated server enforcement. Missing: trusted server rejection and underage lifecycle. Owner: Product + Backend.

Steps: 1. validate date format and age at server boundary. 2. enforce on all signup/update/import paths. 3. reject underage before profile activation. 4. define reporting/deletion/appeal. 5. add boundary-date tests.

Validation/exit: API tests show under-18 cannot create/activate or discover account; approved policy.

### P-26 — Phone uniqueness and recycled numbers

Current: phone OTP and uniqueness exist. Missing: number change/recycling recovery policy. Owner: Product + Backend.

Steps: 1. document one-account-per-number rules. 2. require re-verification and step-up for number change. 3. protect old account recovery. 4. define recycled-number resolution. 5. test duplicates and reassignment.

Validation/exit: uniqueness constraints plus takeover/reassignment tests and support procedure.

### P-27 — Identity verification governance

Current: Aadhaar/selfie upload and admin review exist. Missing: liveness, vendor, retention, encryption, EXIF/scanning, necessity and deletion controls. Owner: Product + Privacy + Backend.

Steps: 1. decide whether raw ID is necessary and choose provider. 2. define retention/access and deletion. 3. implement private encrypted storage and metadata/malware controls. 4. document liveness/badge criteria. 5. verify staff permission and deletion paths.

Validation/exit: approved privacy assessment, retention job evidence, access tests and no unsupported liveness claims.

### P-28 — Bot/fake-account risk controls

Current: device registration and rate limits exist. Missing: platform attestation and risk monitoring. Owner: Mobile + Backend + Security.

Steps: 1. privacy-review risk signals. 2. add server-verified Play Integrity where justified. 3. add bot/fraud indicators and rate-limit telemetry. 4. define review/appeal. 5. test abuse scenarios on staging.

Validation/exit: signed attestation verification and measured test outcomes; policy disclosure if data is processed.

### P-29 — Human moderation and report response

Current: report/block and admin moderation surfaces exist. Missing: operating coverage/SLA and full photo/profile/chat enforcement proof. Owner: Safety + Operations.

Steps: 1. set report categories and severity. 2. assign trained reviewers and response targets. 3. cover profile, image and chat reports. 4. define evidence retention and appeal. 5. run test reports and escalation drills.

Validation/exit: reviewer roster, queue SLA evidence, user-facing controls and tested resolution path.

### P-30 — Scam/spam/impersonation controls

Current: report endpoints and throttling are baseline controls. Missing: repeat-abuse detection and documented enforcement. Owner: Safety + Product + Backend.

Steps: 1. define scam/spam/financial-solicitation policy. 2. detect repeated behavior safely. 3. implement case escalation and enforcement. 4. publish safety guidance. 5. review appeals and false positives.

Validation/exit: abuse test cases, action logs, support playbook and policy surface.

### P-31 — Location exposure and visibility

Current: discovery uses stored matching coordinates and derived distance. Missing: complete response/log/export review and incognito verification. Owner: Backend + Product + Security.

Steps: 1. inventory coordinate reads/writes. 2. remove precise values from public serializers/logs. 3. quantize distance and implement visibility controls. 4. test inference/triangulation and blocks. 5. verify deactivated/deleted profiles excluded.

Validation/exit: response snapshots for every public route show no exact location; negative access tests and product sign-off.

### P-32 — Grievance channel and status confidentiality

Current: grievance API exists; contact identity is unverified and ticket status route lacks demonstrated owner proof. Missing: validated contact and safe case retrieval. Owner: Legal + Support + Backend.

Steps: 1. verify legal officer/contact identity. 2. require requester-bound secret/auth for status. 3. throttle public submission and prevent enumeration. 4. define SLA and assignment. 5. test cross-ticket access.

Validation/exit: published verified details and tests proving another user cannot read case content.

### P-33 — Production distributed rate limiting

Current: express-rate-limit in-process controls cover many endpoints. Missing: shared store and deployed proxy/alert proof. Owner: Backend + DevOps.

Steps: 1. map auth/OTP/message/sensitive endpoints. 2. configure shared store and trusted proxy hops. 3. choose thresholds and lockout behavior. 4. add monitoring. 5. test multi-instance bypass and recovery.

Validation/exit: staging multi-instance tests show shared limits and correct 429/alert behavior.

### P-34 — Revoke sessions after password change

Current: password reset destroys refresh tokens; change-password does not. Missing: revoke existing sessions and client cleanup. Owner: Backend + Mobile.

Steps: 1. increment token version on change. 2. destroy refresh rows in the transaction. 3. invalidate current client session or issue replacement securely. 4. clear stored tokens on logout/delete. 5. test old access/refresh rejection.

Validation/exit: previous session credentials cannot refresh and access is invalidated within documented window.

### P-35 — Injection review

Current: Sequelize ORM widely used; raw SQL/literals exist. Missing: complete review and runtime tests. Owner: Backend + Security.

Steps: 1. inventory raw SQL and dynamic query pieces. 2. verify bind parameters/ORM escaping. 3. constrain dynamic columns/order to allowlists. 4. add regression tests for all input boundaries. 5. review findings independently.

Validation/exit: code review and isolated SQL injection regression suite with no unsafe interpolation.

### P-36 — Route-wide API hardening

Current: Helmet, request size limits, validators and generic 500 handling exist; legacy paths and production HTTP CORS exception remain. Missing: every route's validation/authorization/error behavior and tested headers. Owner: Backend + DevOps.

Steps: 1. inventory route-method-input/auth. 2. validate and authorize all parameters and object IDs. 3. remove HTTP CORS exception and restrict origins. 4. sanitize explicit production errors. 5. run staging header/error/CORS checks.

Validation/exit: route matrix signed off; no stack/secrets in responses and expected CSP/HSTS/CORS headers verified.

### P-37 — Admin operational hardening

Current: RBAC/MFA/session models exist; global enforcement/roster/idle timeout and approvals unverified. Missing: full route map and hardened lifecycle. Owner: Admin + Backend + Security.

Steps: 1. map admin routes to permission and MFA step-up. 2. remove default seed credential. 3. configure idle/max session timeout and reauth. 4. require approval for destructive actions. 5. review staff access and test escalation attempts.

Validation/exit: all routes have approved permission mapping, sensitive routes require fresh MFA, no shared/default accounts and audit evidence for destructive approvals.

### P-38 — Company account ownership and access register

Current: not inferable from source. Missing: ownership, MFA, least privilege, offboarding and recertification evidence. Owner: Management + IT/Security.

Steps: 1. inventory repository, cloud, DNS, DB, store, analytics and vendor accounts. 2. transfer control to company organization. 3. enforce MFA and named identities. 4. record access and recovery owners. 5. rehearse offboarding and review quarterly.

Validation/exit: signed register, account screenshots/export and offboarding/review evidence.

### P-39 — Admin audit integrity/retention

Current: admin audit service and hash-chain verification exist. Missing: full capture coverage, PII minimization, append-only storage, retention and alerting. Owner: Security + Backend + DevOps.

Steps: 1. map mutations/access to events. 2. redact message/PII/token values. 3. restrict update/delete at DB role. 4. set retention/central sink/alerts. 5. test chain verification and unauthorized alteration.

Validation/exit: audit route coverage, redaction fixtures, integrity report and operational retention proof.

### P-40 — Database network and identity controls

Current: MySQL env-configured; no topology evidence. Missing: private network, firewall rules and grants proof. Owner: Database + Infrastructure.

Steps: 1. verify public exposure through authorized cloud/DB console. 2. restrict network to app workloads. 3. use least-privilege app identity and separate backup identity. 4. enable TLS. 5. record periodic review.

Validation/exit: sanitized DB/network policy evidence and negative public connection check from approved vantage.

### P-41 — Store account and declaration readiness

Current: source has app-store-relevant features, but no external submissions or declarations. Missing: organization status, forms, deletion URL, privacy page, reviewer notes, rating/permissions. Owner: Product + Legal + Release.

Steps: 1. verify company-owned Play/Apple organization accounts. 2. publish policy and web deletion request. 3. complete Data Safety/App Privacy from SDK and runtime inventory. 4. complete UGC/age/permissions forms. 5. provide reviewer account/OTP steps and verify review access.

Validation/exit: submitted current forms, stable URLs and store-console evidence matching actual app behavior.

### P-42 — Release build hardening

Current: Android release uses debug signing; backup is enabled; launcher activity is exported. Missing: production signing and complete merged-manifest/local data review. Owner: Mobile + Release.

Steps: 1. create company-controlled signing key custody. 2. configure release signing. 3. inspect merged manifest and plugin exported components/deep links. 4. review Android backup/iOS backup and token storage. 5. scan signed release artifact.

Validation/exit: reproducible release build metadata, signing verification, manifest review and no debug secrets/config.

### P-43 — Branch and dependency assurance

Current: dependency lockfiles exist; no visible CI/branch protection/SAST/SBOM configuration. Missing: enforced reviews, scan policies and patch SLAs. Owner: Engineering + DevOps.

Steps: 1. protect default/release branches and require reviews. 2. add SAST, dependency and secret scans. 3. produce SBOM/inventory. 4. set vulnerability remediation SLA. 5. review unused/outdated packages and release exceptions.

Validation/exit: branch/CI settings export and clean release-commit scan/SBOM with tracked exceptions.

### P-44 — Controlled release and rollback

Current: no deployment workflow/changelog approval evidence. Missing: deployment gate, restricted secrets, approver and tested rollback. Owner: Release + DevOps.

Steps: 1. establish build/release pipeline. 2. restrict production secrets and deploy identity. 3. require production approval and changelog. 4. prohibit direct unreviewed push. 5. rehearse rollback/restore on staging.

Validation/exit: protected pipeline settings and dated rollback drill evidence.

### P-45 — Monitoring and alerting

Current: logging is primarily console-based; no production alert config found. Missing: abuse, admin, export, API failure, storage and outage alerts. Owner: SRE + Security.

Steps: 1. define alert signals and severity. 2. wire sanitized telemetry to monitoring. 3. assign on-call routes. 4. test alerts with staging events. 5. review false positives and outages.

Validation/exit: alert delivery records, runbooks and monitored dashboard for every required signal family.

### P-46 — External VAPT

Current: no valid independent report found. Missing: authorized independent assessment. Why/risk: source inspection cannot validate deployed attack surface. Owner: Security + Management.

Steps: 1. select qualified independent provider (CERT-In empanelled auditor is recommended by supplied checklist). 2. define authorization, assets and timing. 3. cover Android/iOS, API, admin, cloud/IAM, DB/storage, OTP/session, IDOR/BOLA, injection, throttling, uploads and business logic. 4. execute pre-launch assessment. 5. archive signed report securely.

Validation/exit: authentic provider report matching production candidate build and full agreed scope; no certificate may be inferred from code review.

### P-47 — VAPT remediation and retest

Current: no findings/closure register or retest evidence found. Missing: owners, severity, dates, decisions and independent closure. Owner: Security + Engineering + Management.

Steps: 1. create finding register with severity/owner/date/status. 2. fix all Critical before release. 3. fix High or document authorized risk acceptance/compensating control. 4. obtain independent retest. 5. retain closure evidence and residual-risk signoff.

Validation/exit: retest report confirms closure; no unresolved Critical and all High formally closed or approved.

### P-48 — Incident response plan

Current: no written runbook found. Missing: complete incident workflow/evidence procedure. Owner: Security + Backend + SRE.

Steps: 1. define detection/intake and severity. 2. document account/token/secret containment and isolation. 3. preserve logs/cloud/DB/file/config snapshots and chain of custody. 4. investigate scope/data volume/users/duration/exfiltration and recover. 5. record root cause, corrective actions and post-incident review.

Validation/exit: approved, versioned playbook plus tabletop evidence and completed action register.

### P-49 — Named incident owners

Current: checklist proposes roles but project has no named assignment record. Missing: primary/backup owners and always-available contact path. Owner: Management.

Steps: 1. appoint incident commander/security lead. 2. assign backend/infrastructure and product/operations leads. 3. assign legal/DPDP and communications/support leads. 4. name management approver and backups. 5. publish and test 24/7 critical escalation.

Validation/exit: approved roster, reachable contact test and on-call/escalation schedule.

### P-50 — Breach notification and legal readiness

Current: legal requirements are described in supplied documents but require current official/legal verification. Missing: verified rule register, deadlines, templates, contacts and tests. Owner: Legal + Support + Security.

Steps: 1. counsel verifies CERT-In applicability and current DPDP/DPB rules from official sources. 2. record exact source, effective date, trigger, deadline computation and owner. 3. prepare authority/user notices and support scripts. 4. maintain regulator, counsel, cloud and vendor contacts. 5. tabletop deadline tracking and approval workflow.

Validation/exit: counsel-approved current register and tested notification pack. Specifically mark the video claims “DPDP full enforcement May 13, 2027,” “DPB breach notification within 72 hours,” and “₹250 crore per instance” as `PENDING — LEGAL VERIFICATION REQUIRED` until supported by current official/legal evidence.

### P-51 — Security tabletop drills

Current implementation: none found. What is missing: exercises, incident-team participation and closure tracking. Why it matters: written steps may fail under pressure. Risk: delayed containment, lost evidence and missed reporting windows. Files/modules: incident runbook and action register. Recommended owner: Security + Legal + Operations.

Steps to complete:
1. Schedule periodic exercises and after significant organizational or architecture changes.
2. Run credential leak, public media, admin compromise, database exfiltration, OTP abuse, server compromise and third-party breach scenarios.
3. Test owner identification, containment, evidence preservation, affected-user scope and deadline calculation.
4. Prepare authority/user communications and support responses in the exercise.
5. Assign actions with owners/dates and track them to verified closure.

Validation: tabletop record includes timeline, participants, decisions, communication path and action owners. Exit criteria: exercise completed and all material actions have closure evidence.

## 4. Recommended Completion Order

### Stage 1 — Immediate Critical Security

Tasks: remove seed credential/logging (P-01); remove HTTP admin origin and prove TLS (P-02/P-03); secure database and media (P-04/P-06); address exports, secrets, mobile transport, log redaction and session revocation (P-07/P-09/P-10/P-11/P-14/P-34); verify age and location controls (P-25/P-31); close injection and route authorization gaps (P-35/P-36).

Dependencies: company-controlled credentials and staging environment. Files/modules: backend seed/config/auth/storage/routes, Flutter networking, Android release config. Owner: Engineering, Security, DevOps. Verification: isolated security regression tests, staging transport/media/auth checks, secret scan. Exit: no exposed credentials, secure transport/data paths, auth/IDOR and injection checks pass; critical source findings closed.

### Stage 2 — Data Protection

Tasks: database/media/export encryption, backup encryption/restore, key separation, retention/deletion, data inventory and 180-day logging interpretation/implementation (P-04–P-08, P-12–P-14, P-19, P-21, P-39–P-40).

Dependencies: infrastructure/KMS and legal retention decisions. Files/modules: DB/storage config, deletion services/jobs, logging/audit services, inventory docs. Owner: DevOps, Database, Backend, Privacy/Legal. Verification: encryption/access evidence, deletion/restore exercise and sanitized retention configuration. Exit: approved data map, tested lifecycle, restricted logs and recoverable encrypted backups.

### Stage 3 — Identity and Access

Tasks: company account ownership, least privilege, RBAC/MFA coverage, admin session/approval controls, access register and offboarding (P-37–P-40).

Dependencies: management account access. Files/modules: admin routes/middleware, role catalog, company account register. Owner: Management, IT, Security. Verification: route-permission matrix, MFA enforcement test and access review. Exit: company ownership, named individual accounts, MFA and revocation evidence.

### Stage 4 — Dating Safety

Tasks: phone/age/identity verification; anti-bot controls; report/block/unmatch; human moderation; anti-scam; private location and safety/support channels (P-25–P-32).

Dependencies: product policy, privacy review, vendor selection and trained operations staff. Files/modules: auth/onboarding, device, identity verification, discovery, reports, admin safety and Flutter safety screens. Owner: Product, Safety, Backend, Mobile. Verification: underage/duplicate/abuse/location-privacy test scenarios and staffed queue check. Exit: no exact-location exposure, working safety controls, named operational SLA and approved verification claims.

### Stage 5 — DPDP and Legal Readiness

Tasks: accurate policy/Terms, consent and withdrawal, deletion/retention, rights requests, vendor map, grievance, AI disclosures, 18+ response and legal verification (P-17–P-27, P-32, P-50).

Dependencies: counsel and data-flow/vendor inventory. Files/modules: consent/privacy services, Flutter legal/privacy flows, models/migrations, vendor register. Owner: Legal/Privacy, Product, Backend. Verification: counsel approval and end-to-end rights/consent tests. Exit: published accurate notices, verified contacts and functioning governed request/withdrawal/deletion workflows. The three video-stated legal claims remain pending until independently verified.

### Stage 6 — Incident Response

Tasks: incident plan, owners, CERT-In process, DPB/user notification readiness, evidence preservation, log retention, contacts and tabletop drills (P-12–P-15, P-45, P-48–P-50).

Dependencies: named owners, monitoring, legal analysis and cloud/vendor contacts. Files/modules: incident runbook, alert configuration, contact tree, templates. Owner: Security, Legal, SRE, Management, Support. Verification: scenario exercise tracking containment, evidence, scope, deadline calculation and communications. Exit: approved runbook, reachable escalation and closed exercise actions.

### Stage 7 — VAPT

Tasks: independent VAPT, Critical/High remediation, formal risk acceptance where authorized, independent retest and closure evidence (P-46/P-47).

Dependencies: stable release candidate, written scope/authorization, staging or approved target. Files/modules: Flutter app, API, admin, cloud/IAM, DB/storage, media/chat/auth. Owner: Security + Management + Engineering. Verification: provider report and retest. Exit: no Critical open; High findings fixed or formally accepted with compensating controls; evidence retained.

### Stage 8 — App Stores

Tasks: organization accounts, UGC/report/block/moderation policy, deletion web path, privacy URL, Play Data Safety, Apple App Privacy, age rating, permissions, reviewer access/OTP notes, billing/IAP terms, closed testing/TestFlight/real-device tests (P-41/P-42).

Dependencies: accurate policies, release build, reviewer account, current store rules and company accounts. Files/modules: Android/iOS app, privacy/deletion web endpoints, store console records. Owner: Product, Legal, Mobile, Release. Verification: completed store forms and reviewer/test evidence. Exit: declarations match observed behavior; reviewer can access app; closed beta/test flight findings closed.

### Stage 9 — Final Release Gate

Tasks: verify every P0 and required P1, release scans, encryption/access/logging evidence, privacy/Terms/grievance, incident/regulatory procedure, store declarations, named risk owners, rollback and restore evidence.

Dependencies: completion of prior stages and management signoff. Files/modules: complete evidence pack and release record. Owner: Release approver + Management. Verification: signed release checklist against this report and exact build commit. Exit: all launch blockers closed, accepted residual risk documented, tested rollback/restore, and no unsupported security/legal claims.

## 5. Legal Verification Register

The supplied documents explicitly label these as video-stated claims requiring current official/legal verification. None is confirmed by repository evidence:

| Claim | Status | Evidence required |
|---|---|---|
| DPDP full enforcement on May 13, 2027 | PENDING — LEGAL VERIFICATION REQUIRED | Current official commencement notification/rules and counsel interpretation, source and effective date |
| DPB breach notification within 72 hours | PENDING — LEGAL VERIFICATION REQUIRED | Current official rule text, exact trigger/deadline and legal calculation |
| ₹250 crore per-instance penalty description | PENDING — LEGAL VERIFICATION REQUIRED | Current statutory text and counsel mapping to contravention/penalty scope |
| CERT-In 180-day log retention/in-country location and six-hour reporting for specified incidents | PENDING — LEGAL VERIFICATION REQUIRED | Counsel/security confirmation of applicable entity, log categories, incident types, location, clocks and process |

## 6. Audit Scope and Evidence Limitations

- Both supplied Word checklists were read in full, including tables. Their proposed controls were merged; their “Pending” statuses were not adopted without source review.
- Repository source and relevant documentation were inspected. No production system, external account, database, cloud console, app store, or deployed endpoint was accessed.
- `Backend/docs/SECURITY_ARCHITECTURE.md`, `Backend/docs/DPDP_CONTROL_MATRIX.md`, and `Backend/docs/DATA_INVENTORY.md` contain broad statements that exceed what current source and deployment evidence establish. Treat them as design/context documents, not verification artifacts, until reconciled and approved.
- The root package has no test suite; backend test files exist but were not run. Flutter analysis/tests, Node tests, dependency audits, and binary scans are not claimed as passed.
- The security-audit execution sandbox required by repository instructions is not available through this host, so target-controlled builds/tests and package installers were not executed. Safe next validation is an isolated CI/staging run with dummy accounts and no production data.
- Static keyword searches can miss secrets in Git history, ignored files, binaries, external services, and runtime environment. No secret value is printed here.

