# AMORA AI – DPDP & Privacy Compliance Readiness Report

- **Report date:** 7 September 2026
- **Project name:** AMORA AI (some in-app labels use “AMORAA”)
- **Application type:** Dating / Matchmaking Application
- **Assessment type:** Technical/Product Compliance Readiness
- **Scope:** Read-only review of the supplied Flutter client and Node/Express backend repository. Deployment, cloud, database instance, app-store, operational, and legal evidence were not inspected unless present in source.
- **Overall readiness:** **HIGH RISK — NOT READY for an unconditional public MVP launch**

> This document is a technical and product compliance-readiness assessment and is not a substitute for advice from qualified legal/privacy counsel.

The Digital Personal Data Protection framework places material responsibility on the company acting as data fiduciary. Privacy or security failures can expose AMORA to regulatory action, financial penalties, user complaints, investor and app-store concerns, reputation damage, loss of trust, and business disruption. Legal interpretation, notice wording, lawful-purpose analysis, retention exceptions, and notification obligations require counsel confirmation: **LEGAL REVIEW REQUIRED**.

## Executive Summary

AMORA already has a meaningful security foundation: authenticated APIs, server-side 18+ validation in onboarding and profile editing, bcrypt password/OTP/refresh-token hashing, short-lived access tokens, refresh-token revocation, production guards for test OTP mode, rate limits, private chat/KYC media storage, report/block workflows, and an unusually substantial administrator RBAC/MFA/audit-log foundation.

The main launch blockers are not the absence of all controls; they are incomplete lifecycle governance for highly sensitive dating data. The delete-account endpoint anonymizes the `Users` record and removes matches/tokens, but repository evidence does **not** show cascading removal, anonymization, or documented retention of the onboarding profile, public photo files, messages/conversations, verification files/records, reports, likes/saves/roses, payments, notifications, device data, or backups. The UI describes permanent removal, creating a material expectation mismatch. Consent is recorded only as a terms timestamp—not as separate privacy acceptance, versions, or withdrawal history. The “Data Export” page declares itself a future local UI and has no backend workflow. No repository documentation establishes retention, backups, incident response, or deployed TLS/database encryption.

**Critical risk:** 1. **High-priority gaps:** 7. **Medium findings:** 6. **Low findings:** 2. These counts are findings, not legal conclusions.

### Existing strengths

- Server-side authenticated workflows and validation for major user actions.
- 18+ checks are enforced by backend routes, not merely the Flutter UI.
- Passwords, OTP codes, and refresh tokens are bcrypt-hashed; access tokens are 15 minutes and invalidated through `tokenVersion`.
- Fixed test OTP mode is configuration-guarded and startup rejects it in production.
- Chat and verification media are stored outside the publicly served upload directory and retrieved through authenticated routes.
- Admin permissions, MFA step-up, audit logging, report handling, and moderation data models are present.

### Recommended pre-launch actions

1. **P0:** make account deletion truthful and complete: define, implement, test, and disclose deletion/anonymization/retention behavior for every data store and private file.
2. **P0:** obtain legal/privacy counsel review and publish approved, versioned Privacy Policy and Terms notices; record separate acceptance/version/timestamp evidence.
3. **P1:** build a real authenticated data-access/export and correction-request workflow.
4. **P1:** approve and operationalize retention, backup/restore, incident-response, and deployment-security controls.
5. **P1:** complete production verification for HTTPS, CORS, secrets, database TLS/at-rest protection, storage access, monitoring, and third-party contracts.

## Managing Director / Founder Summary

For a dating application, privacy is product safety. Photos, identity material, city/location, gender and dating preferences, matches, and private conversations can cause disproportionate harm if disclosed, retained unexpectedly, or accessed by the wrong person. AMORA has promising engineering controls, but the company must be able to explain—accurately and consistently—what it collects, why, who can access it, how long it keeps it, and what actually happens after deletion.

- **User privacy risk:** deletion and export promises are not yet matched by demonstrated backend lifecycle handling.
- **Security risk:** core controls are good, but hosting/TLS/database/storage/backup operations remain unverified.
- **Regulatory/compliance risk:** absence of consent versioning, documented retention, access/export workflow, and incident procedure weakens readiness.
- **Reputation risk:** a visible “permanent delete” statement while photos, conversations, or Aadhaar/selfie records may remain is especially damaging in dating.
- **Investor due-diligence risk:** diligence will ask for data maps, third-party processor contracts, security testing, retention schedules, deletion evidence, and incident/backup procedures.
- **Operational responsibility:** these responsibilities sit with AMORA/the company, not the user or a UI checkbox.

### Founder Action List

- [ ] Sponsor a data inventory and deletion/retention decision for every model, file store, log, and backup.
- [ ] Obtain **LEGAL REVIEW REQUIRED** for policy/terms, consent design, identity-verification necessity, and retention exceptions.
- [ ] Fund and test end-to-end deletion, access/export, security testing, backup restore, and incident response before public launch.
- [ ] Assign accountable owners for privacy requests, moderation, security incidents, and vendor management.

## Privacy Policy

The app contains an in-app policy at `lib/features/legal/presentation/legal_document_screen.dart` (`PrivacyPolicyScreen`, route `/privacy-policy`, effective 31 July 2026). It describes account/profile/verification/interactions, approximate location, device/diagnostic information, choices, retention, sharing, and support contact. It is reachable through routing (`lib/main.dart`) and linked from the signup legal control. It remains a static in-app document: no repository evidence of a hosted policy, policy-acceptance record, policy version, acceptance timestamp, or change-notice delivery mechanism.

| Requirement | Status | Evidence | Gap | Recommendation |
|---|---|---|---|---|
| Policy exists and is readable in app | IMPLEMENTED | `legal_document_screen.dart`; `/privacy-policy` route | Hosted/web accessibility not evidenced | Publish counsel-approved canonical policy and retain accessible historical versions. |
| Signup can open policy | IMPLEMENTED | `signup_screen.dart` imports and links `PrivacyPolicyScreen` | One combined legal checkbox | Separate Terms and Privacy acknowledgement where counsel requires. |
| Privacy acceptance recorded | NOT FOUND | `User` has `termsAcceptedAt` only | No privacy field/timestamp | Persist privacy acceptance, policy version, source, timestamp and account ID. |
| Policy version recorded | NOT FOUND | Static effective date only | No database/version record | Version legal text and acceptance records. |
| Later user access | IMPLEMENTED | App route and Safety/Privacy navigation | Availability after web/app changes needs verification | Maintain in-app and web access. |

**LEGAL REVIEW REQUIRED:** Confirm whether the supplied notice covers all actual processing, Aadhaar/selfie handling, sharing, requests, contact/grievance mechanism, children/age treatment, transfers, retention, and third-party processors.

## Terms & Conditions

Terms are implemented as an in-app static screen in `lib/features/legal/presentation/legal_document_screen.dart`, routed at `/terms` and `/terms-and-conditions`. Signup requires `acceptedTerms: true` at `Backend/src/routes/authRoutes.js`; account creation sets `Users.termsAcceptedAt` in `Backend/src/controllers/authController.js`.

The Flutter signup control combines Terms and Privacy into one checkbox (`lib/features/auth/presentation/signup_screen.dart`), and the API neither accepts nor stores a Terms document version nor a Privacy acceptance. There is no evidence of a re-consent process after material changes. **LEGAL REVIEW REQUIRED** for enforceability, wording, versioning, and whether separate acceptance is appropriate.

## Age Gate – 18+

**Status: IMPLEMENTED (with an important lifecycle limitation).** Flutter onboarding blocks under-18 selection (`lib/features/onboarding/presentation/profile_onboarding_flow.dart`), but more importantly the backend rejects a DOB less than 18 on `PUT /api/onboarding/age` (`Backend/src/routes/onboardingRoutes.js`). `Backend/src/middleware/profileValidation.js` also enforces 18+ when a user edits `birthdate` via their own profile. A direct API caller therefore cannot bypass those two routes merely by skipping frontend validation.

The completion route only checks that a birth date exists, relying on its earlier validated write; this is acceptable only while no other write path can set `birthDate`. Retest after any API expansion. No age/identity-verification cross-check, fraud controls, or documented underage-account handling was found. **P1 / LEGAL REVIEW REQUIRED** for age-assurance and minor-report handling.

## Consent Management

| Consent / permission | Status | Evidence and limitation |
|---|---|---|
| Terms | PARTIALLY IMPLEMENTED | Required at signup and timestamped, but no document version. |
| Privacy | PARTIALLY IMPLEMENTED | UI combines it with Terms; backend stores no separate privacy consent. |
| Marketing | NOT FOUND | No dedicated marketing consent or withdrawal record located. |
| Notifications | PARTIALLY IMPLEMENTED | Flutter requests OS permission and has preference UI/API; no general consent ledger. |
| Location | PARTIALLY IMPLEMENTED | City is collected in onboarding; safety check-in requests OS location permission. Exact-location storage was not found. |
| Profile/data processing | PARTIALLY IMPLEMENTED | Signup/legal UI and policy language exist, but no purpose/versioned record. |
| Verification | PARTIALLY IMPLEMENTED | Upload is explicit/authenticated, but no recorded verification-processing acknowledgement was found. |
| Analytics | NOT FOUND | No analytics SDK identified in dependency manifests; operational analytics remains to verify. |

Checkboxes alone are not proof of compliance. Consent should be purpose-specific where required, explicit, stored, timestamped, versioned, auditable, and withdrawable where applicable. **LEGAL REVIEW REQUIRED.**

## Delete Account & Data Deletion

**Status: PARTIALLY IMPLEMENTED — P0 critical finding.** The Flutter flow selects a reason and final confirmation (`lib/features/settings/presentation/widgets/amoraa_delete_account_flow.dart`); it does not require password/MFA re-authentication. `DELETE /api/account` requires a valid current bearer token and validates reason/details (`Backend/src/routes/accountRoutes.js`).

`Backend/src/controllers/accountController.js` marks the account deleted; overwrites name/email/phone; clears password and Google ID; invalidates refresh/access tokens via `tokenVersion`; removes OTP records tied to old identifiers; and deletes match rows. This is a soft-delete/anonymization pattern for `Users`, not demonstrated full erasure.

| Data | Apparent post-delete behavior | Status / risk |
|---|---|---|
| User account identifiers and password | Replaced/nullified; account row retained as deleted | PARTIALLY IMPLEMENTED |
| Sessions / refresh tokens / OTPs | Refresh tokens destroyed; old-identifier OTPs destroyed | IMPLEMENTED |
| Matches | Rows destroyed | IMPLEMENTED |
| Onboarding profile and public photo references | No deletion/anonymization shown | UNKNOWN — P0 |
| Public photo files in `uploads/onboarding-photos` | No deletion loop shown | UNKNOWN — P0 |
| Messages, conversations, drafts, chat media | No deletion/anonymization shown | UNKNOWN — P0 |
| Likes, Super Likes, Roses, saved profiles | No deletion/anonymization shown | UNKNOWN — P0 |
| Identity verification record and private Aadhaar/selfie files | No deletion/anonymization shown | UNKNOWN — P0 |
| Reports, moderation evidence, audit records | No deletion/anonymization shown | UNKNOWN — P0; counsel must define permitted retention |
| Notifications, devices, login events, payment/subscription records | No deletion/anonymization shown | UNKNOWN — P0 |
| Backups | Not documented | NEEDS VERIFICATION |

The UI says account/access will be permanently removed, while the source does not demonstrate a complete record/file lifecycle. Do not represent deletion as permanent until behavior and lawful retained records are precisely documented and tested. Require re-authentication or another proportionate high-assurance confirmation for a destructive request.

## User Access / Correction

Users can retrieve and update their own profile through authenticated routes (`Backend/src/routes/meProfileRoutes.js`, `Backend/src/controllers/profileController.js`) and can edit data in profile screens. The Privacy Policy claims available access, correction, export, and deletion controls.

The `lib/features/privacy/presentation/data_export_screen.dart` explicitly states it is a **local UI preparing future backend request and secure download workflows**. No backend export/access-request API, secure delivery, request case management, or correction workflow beyond ordinary profile editing was found. **Status: PARTIALLY IMPLEMENTED; P1.**

## Report & Block

**Status: IMPLEMENTED.** Authenticated report creation validates target, reason, notes length, conversation association, duplicate reports, and applies a per-user rate limit (`Backend/src/routes/reportRoutes.js`, `Backend/src/controllers/reportController.js`). Blocks are authenticated, prevent self-blocking, are idempotent, listable, removable, and access controls use blocks to prevent conversation access (`Backend/src/routes/blockRoutes.js`, `Backend/src/controllers/blockController.js`, `Backend/src/services/conversationAccessService.js`). Flutter surfaces report/block/unblock actions.

Potential gap: unblock can restore a match when a direct conversation exists. Product/safety review should confirm that restoration is intended and does not surprise a user. Admin safety/report-case infrastructure exists, but moderation SLAs, escalation, evidence retention, and abuse monitoring are **NEEDS VERIFICATION**.

## Password Security

**Status: IMPLEMENTED.** Local passwords are bcrypt-hashed at cost 12 on signup and compared with bcrypt on login (`Backend/src/controllers/authController.js`); admin passwords use bcrypt (`Backend/src/services/adminAuthService.js`, `adminManagementService.js`). Password reset uses email OTP challenge logic; OTPs expire and are one-time/attempt-limited. Login, signup, OTP, and admin-auth endpoints have rate limits. No plaintext password storage was found in reviewed model/controller source.

Password policy is minimum eight characters at the backend signup route. Strength/compromise-password requirements, reset audit/alerting, credential-stuffing monitoring, and production test results are **NEEDS VERIFICATION**.

## OTP Security

**Status: IMPLEMENTED, pending deployment verification.** OTPs are randomly generated, bcrypt-hashed, expire after 10 minutes, are consumed after use, have five-attempt maximum, have resend cooldown, and use request rate limits (`Backend/src/services/otpService.js`, `Backend/src/controllers/authController.js`, `Backend/src/middleware/rateLimiter.js`). The source documents a fixed test OTP mode but `Backend/src/config/otpTestConfig.js` rejects fixed OTP, enablement, or delivery-skip configuration when `NODE_ENV=production`; `devOtp` is emitted only in development.

No production bypass was found in the source reviewed. **NEEDS DEPLOYMENT VERIFICATION:** prove production environment variables, logging, build pipeline, and `NODE_ENV` cannot enable test delivery/fixed OTP. Do not log delivery codes or identifiers in production.

## Authentication & Session Security

**Status: PARTIALLY IMPLEMENTED.** User access JWTs expire in 15 minutes; refresh tokens have a 30-day expiry, random selector, bcrypt hash, IP metadata, rotation/revocation logic, and deletion on account actions (`Backend/src/utils/generateTokens.js`, `Backend/src/models/RefreshToken.js`, `authController.js`). `authMiddleware` verifies JWT, user state, and `tokenVersion`, invalidating sessions on deletion/deactivation. Flutter includes `flutter_secure_storage` in `pubspec.yaml`, but token-storage behavior and web security require inspection/testing.

No visible user-facing device/session list or “logout all devices” mechanism was found. `RefreshToken.createdByIp` exists, but device session management remains **NOT FOUND**. Admin session/MFA implementation is stronger; see below.

## Authorization

**Status: PARTIALLY IMPLEMENTED.** Major routes apply `requireAuth`. Direct object identifiers are parsed/validated. Private chat history, sending, media download, read state, and deletion call `conversationAccess`, which checks membership, active counterpart, active match, and block state (`Backend/src/services/conversationAccessService.js`, `messageController.js`). Own profile routes use `req.user.sub`; public profile access checks active status/blocking.

This is positive IDOR resistance for reviewed paths. A full endpoint-by-endpoint authorization test, admin-route test, and independent penetration test are still **NEEDS VERIFICATION**; do not treat code review as proof of absence of IDORs.

## Admin Panel Security

**Status: IMPLEMENTED foundation / PARTIALLY IMPLEMENTED operationally.** The repository contains dedicated admin JWT authentication, administrator roles/permissions, origin middleware, RBAC middleware, refresh sessions, password reset, MFA TOTP/recovery-code functionality, rate limits, and sensitive-action MFA step-up (`Backend/src/routes/adminAuthRoutes.js`, `middleware/adminAuthMiddleware.js`, `adminRbacMiddleware.js`, `adminMfaMiddleware.js`, and `services/adminAuthService.js`). Permission checks produce 403 where not granted.

MFA enrollment and recent step-up are required by middleware on protected sensitive actions, but exact route coverage, staff provisioning/offboarding, production admin origin/CORS values, alerting, and independent verification remain **NEEDS VERIFICATION**.

## Admin Audit Logs

**Status: IMPLEMENTED.** `AdminAuditLogs` stores actor, action, target, before/after values, reason/metadata, IP, user agent, and correlation ID (`Backend/src/models/AdminAuditLog.js`). `adminAuditService.js` strips key names matching password, token, secret, OTP, authorization, cookie, card, Aadhaar, and identity-document before recording. Routes expose permission-protected audit-log views, and services call `recordAudit` for administrator, user, financial, verification, matching, profile, MFA, and discover-setting actions.

Gap: retention, integrity/immutability, centralized monitoring, alerting, access review, and export safeguards need documented operational verification. Audit logs may include personal data in values not matching the sensitive-key filter; review field-level minimization.

## Chat & Private Message Privacy

**Status: PARTIALLY IMPLEMENTED.** Messages are stored in `Messages` with sender/conversation, text/context, delivery/read fields, and soft-delete timestamp. Access is authenticated and participant/match/block constrained. Chat attachments use a private directory and authenticated download route with `Cache-Control: private` (`Backend/src/utils/chatMediaStorage.js`, `messageController.js`). Sender-only deletion nulls returned content and removes attached private files.

No end-to-end encryption is indicated; messages are server-readable. Admin message-content access was not confirmed in reviewed routes, so treat it as **NEEDS VERIFICATION**, not “no access.” Message text is also used in push-notification creation (truncated to 160 characters in `messageController.js`), which can expose content to a notification provider/device lock screen depending on configuration; review and minimize this. Conversation deletion/hide semantics and account-deletion handling are incomplete/unknown.

## Location Privacy

**Status: PARTIALLY IMPLEMENTED.** The backend model stores `city` and preferred discovery distance, not coordinates (`Backend/src/models/OnboardingProfile.js`). Onboarding writes a city string; public profile serialization and UI use location/city. A safety check-in asks OS location permission through the Flutter permission service, but source reviewed did not demonstrate backend coordinate collection/storage. This reduces precision risk, but real device permissions, map/date-spots, any SDK use, and API telemetry are **NEEDS VERIFICATION**.

Recommendation: do not expose exact location; use minimum necessary city/distance or coarse representation, default safety settings conservatively, and clearly explain purpose/withdrawal.

## Profile Photos & File Storage

**Status: PARTIALLY IMPLEMENTED.** Profile uploads limit count to six and size to 12 MB, allow JPEG/PNG/WebP, verify content magic bytes against MIME type, and use random names (`Backend/src/utils/photoStorage.js`). The public upload directory is served under `/uploads` with seven-day immutable cache headers (`Backend/src/server.js`). Deleting an individual photo removes its file.

Public serving is expected for discovery photos but needs access/design review: URLs are not per-user authorized and cached copies may persist. Virus/malware scanning, image re-encoding/EXIF stripping, abuse/moderation scanning, storage encryption, and account-deletion file cleanup are **NOT FOUND / NEEDS VERIFICATION**.

## Identity Verification Data

**Status: PARTIALLY IMPLEMENTED with high sensitivity.** AMORA collects Aadhaar and selfie images for verification. Inputs are authenticated, rate-limited, JPEG/PNG/WebP-only, size-limited, magic-byte checked, written with owner-only permissions (`0o600` for verification files), and stored outside public static files (`Backend/src/utils/identityVerificationStorage.js`, `identityVerificationController.js`). A verification model records storage paths, status, reviewer, versions, and reasons. Administrator verification services/audits are present.

No repository evidence shows explicit verification consent record, retention/deletion schedule, encrypted storage/key management, redaction/minimization, data-export exclusion design, or deletion integration. Given Aadhaar/selfie sensitivity, these are **P0/P1 and LEGAL REVIEW REQUIRED**. Confirm whether collection is necessary and permitted for the product purpose before launch.

## Data Minimization

| Data Category | Why AMORA Collects It | Necessary? | Risk | Recommendation |
|---|---|---|---|---|
| Name, email, phone | Account creation/authentication | Likely, but confirm each field/purpose | High | Document purpose and limit display/access. |
| DOB | 18+ eligibility and age display | Likely | High | Store full DOB only if needed; expose only age. |
| Photos/profile prompts/preferences | Profile/discovery/matching | Likely | High | Make optional fields genuinely optional; minimize public visibility. |
| City and preferred distance | Discovery | Likely | High | Avoid exact coordinates; disclose precision and retention. |
| Gender, sexuality, relationship goals | Matching preferences | Purpose-dependent | High | Apply heightened access/minimization review. |
| Chats/media | Messaging | Necessary for feature | Very high | Define retention/deletion and limit notification/log exposure. |
| Aadhaar/selfie | Identity verification | **LEGAL REVIEW REQUIRED** | Very high | Prove necessity; isolate access; set short retention. |
| Device/session/IP data | Security/session management | Likely | Medium | Document purpose, retention, and access controls. |
| Payment/subscription identifiers | Payments/entitlements | Likely | High | Keep card data out of AMORA; document provider and retention. |

## Data Retention

**Status: NOT FOUND.** The policy contains a general statement that data is retained as needed, but no repository retention schedule/job/document was found for accounts, deleted users, photos, chats, OTPs, tokens, verification material, reports, notifications, payments, admin logs, or backups. OTP expiry/consumption and token expiry are implemented, but expiry is not a demonstrated data purge process.

Create a counsel-approved retention schedule, model-by-model deletion/anonymization jobs, backup expiry/restore handling, legal-hold exception process, and evidence of execution. **P1; LEGAL REVIEW REQUIRED.**

## Database Security

**Status: PARTIALLY IMPLEMENTED.** Database credentials are sourced from environment variables (`Backend/src/config/db.js`), and Sequelize logging is disabled. Migrations are required at startup. No hardcoded credential was found in reviewed source files; values were not reproduced or inspected for this report.

Database TLS, encryption at rest, least-privilege accounts, network isolation, production secret rotation, access audit, and managed-backup controls are **NEEDS DEPLOYMENT VERIFICATION**. `bootstrapEnv.js` can create/copy a local `.env` and write generated JWT secrets when placeholders are present; deployment should ensure immutable managed secrets and no automatic production secret generation/replacement.

## API Security

**Status: PARTIALLY IMPLEMENTED.** Express uses Helmet, JSON request size limit (100 KB), CORS configuration, input validation, an error handler, authentication middleware, endpoint-specific rate limits, upload restrictions, and payment webhook raw-body handling (`Backend/src/server.js`, `middleware/rateLimiter.js`, `validateRequest.js`).

The server defaults CORS origin to `*` when `CORS_ORIGIN` is absent, with a development warning. Production allowed origins must be explicit. API security testing, CORS deployment values, error/PII leakage tests, dependency scanning, webhook signing, WAF/DDoS, and monitoring remain **NEEDS VERIFICATION**.

## HTTPS & Transport Security

**Status: NEEDS DEPLOYMENT VERIFICATION.** Helmet enables HSTS only when `NODE_ENV=production`; the Node app itself creates an HTTP server, implying TLS likely terminates at a reverse proxy/load balancer. No deployment manifest/proxy/production URL proving TLS was found. Verify HTTPS everywhere, TLS policy, redirect behavior, HSTS delivery, secure cookies where used, WebSocket `wss`, certificate renewal, and no mixed-content API base URLs.

## Logging & Secret Exposure

**Status: PARTIALLY IMPLEMENTED.** Admin audit logging sanitizes obvious secret/identity keys. Database error output is reduced to safe codes. Fixed development OTP responses/logs are explicitly gated to development in reviewed auth code and README.

Review all runtime logging and external observability. `sendSms.js` and `sendEmail.js` print OTP details when providers are absent; that is acceptable only for isolated development, never production. No evidence of a general PII log-redaction policy or production log access/retention controls was found.

## Backup & Recovery

**Status: NOT DOCUMENTED / NEEDS OPERATIONAL VERIFICATION.** No backup schedule, encrypted backup design, restore test, disaster-recovery runbook, RPO/RTO, or backup access-control evidence was located. Implement and test these operational controls without treating source-code absence as proof that infrastructure backups do not exist.

## Data Breach Response Readiness

**Status: NOT FOUND.** No formal incident-response plan was located. AMORA should create, approve, and exercise a procedure for detection, containment, credential revocation, investigation, evidence preservation, affected-data assessment, management escalation, counsel-led user/regulatory notification review, remediation, and lessons learned. **P1; LEGAL REVIEW REQUIRED.**

## Third-Party Services

| Service | Purpose | Data Potentially Shared | Found In | Review Required |
|---|---|---|---|---|
| Twilio | SMS OTP delivery | Phone number, OTP delivery metadata | `Backend/package.json`, `utils/sendSms.js` | Yes—processor terms, India/data routing, retention. |
| SMTP/Nodemailer provider | Email OTP/support email | Email, OTP delivery metadata | `Backend/package.json`, `utils/sendEmail.js` | Yes. |
| Google Sign-In | OAuth login | Google identity token/account identifiers | `google-auth-library`, Flutter `google_sign_in` | Yes. |
| Razorpay | Payment/subscription | Order/payment identifiers, amount, user linkage | `razorpay_flutter`, `services/razorpayProvider.js` | Yes—payment/privacy obligations. |
| Firebase push provider | Push delivery | Device token, notification metadata/content | `services/firebasePushProvider.js` | Yes—avoid message content in notification payloads. |
| Socket.IO | Real-time messaging | Session/auth and message events | `socket.io` dependencies | Verify hosting and transport security. |
| MySQL | Primary data store | All stored personal data | `mysql2`, `config/db.js` | Verify hosting, encryption, access, backups. |
| Image picker / permission handler | Device media/location/notification permissions | Device-side selected media/permission state | `pubspec.yaml` | Review platform permissions and notices. |

No analytics/crash-reporting SDK was identified in the inspected dependency manifests; this is **NOT FOUND**, not a claim that no operational analytics exists.

## Existing Positive Controls

- Bcrypt at cost 12 for user/admin passwords, OTPs, and refresh tokens.
- Generic invalid-credential response for normal local login failures; verified-account gate.
- OTP expiry, consumption, five-attempt limit, resend cooldown, rate limits, and production test-mode rejection.
- Backend 18+ enforcement on onboarding and profile edit paths.
- Account deactivation/deletion endpoints invalidate sessions; deletion anonymizes principal account identifiers and removes matches.
- Report/block/unblock, report validation/deduplication, and rate limiting.
- Private authenticated chat media and private owner-only verification files.
- Image type/size/count validation plus content signature checks.
- Admin RBAC, MFA/step-up, rate limiting, audit records, and secret-field sanitization.
- Helmet, explicit production HSTS behavior, request-size limit, and migration-at-startup checks.

## DPDP-Related Changes and Updates Already Present in AMORA

| Change / Feature | Current Status | Relevant File(s) | Frontend | Backend / Database | Security / Privacy Benefit | Remaining Gap |
|---|---|---|---|---|---|---|
| In-app legal documents | PARTIALLY IMPLEMENTED | `lib/features/legal/presentation/legal_document_screen.dart` | Terms/Privacy routes | None | Makes notices accessible | No stored privacy/version acceptance. |
| Required terms signup field | PARTIALLY IMPLEMENTED | `signup_screen.dart`; `authRoutes.js`; `User.js` | Combined checkbox | `termsAcceptedAt` | Evidence of Terms acknowledgement | No privacy/version record. |
| 18+ guard | IMPLEMENTED | onboarding/profile validators | DOB UI | Backend DOB checks | API-resistant age gate | No assurance/fraud process. |
| Password/OTP hardening | IMPLEMENTED | auth/OTP services | Login/reset screens | bcrypt, expiry, attempts, rate limits | Protects credentials | Production ops testing required. |
| Session invalidation | IMPLEMENTED | `generateTokens.js`, `authMiddleware.js`, `accountController.js` | Auth service | token version/refresh revocation | Limits stale sessions | Device management absent. |
| Account deletion flow | PARTIALLY IMPLEMENTED | delete flow; account route/controller | Confirmed UI | Anonymizes user/removes matches | User control and access revocation | Incomplete data/file lifecycle. |
| Report and block controls | IMPLEMENTED | safety UI, report/block controllers | Report/block/unblock UX | Validated, rate-limited records | Abuse/safety control | Moderation operations to verify. |
| Private media/KYC storage | PARTIALLY IMPLEMENTED | storage utilities/message controller | Media upload UI | Private authenticated files | Limits direct public access | Retention/encryption/deletion absent. |
| Admin accountability | IMPLEMENTED | admin services/models/middleware | Admin UI not fully assessed | RBAC, MFA, audit log | Restricts/traces staff actions | Retention/monitoring coverage to verify. |
| Data-export screen | NOT FOUND as functional service | `data_export_screen.dart` | Local simulated workflow | No export API | Signals intended user control | Must implement secure real workflow. |

## Recommended Changes Before Public MVP Launch

### P0 – Critical before launch

1. Reconcile deletion promise with an approved, tested lifecycle for profile/photos, chat/media, identity verification files, interaction records, reports, devices, notifications, subscriptions/payments, logs, and backups. Document any justified retention and expose it accurately.
2. Complete **LEGAL REVIEW REQUIRED** for Privacy Policy, Terms, consent purpose/design, identity verification (especially Aadhaar/selfie), retention, grievances, and deletion disclosures; publish canonical versioned documents and record acceptance.
3. Validate production OTP/test configuration, secret management, and environment controls; prove test OTP delivery/logging cannot occur in production.

### P1 – High priority

1. Deliver authenticated data access/export requests with secure download, expiry, request tracking, and verified scope; route non-profile correction requests to a managed process.
2. Establish retention schedule, backup/restore policy, disaster recovery, and deletion propagation evidence.
3. Establish and test incident-response/breach-response runbook.
4. Verify production HTTPS/TLS, CORS allowlist, database TLS/at-rest encryption, storage encryption/access, secret rotation, and observability/PII redaction.
5. Verify admin permissions/MFA step-up coverage and audit log access/retention; conduct authorization/IDOR penetration testing.
6. Reduce chat preview content in notifications and formally govern admin/staff access to chats and KYC material.
7. Add destructive-action re-authentication and a user session/device management path.

### P2 – Important

1. Strip image metadata/re-encode media, malware scan, and apply content/moderation workflow.
2. Create support/moderation SLAs, legal-hold procedure, safety escalation, and vendor data-processing register.
3. Add production security monitoring, abuse detection, dependency/vulnerability management, and periodic access reviews.

### P3 – Future improvement

1. Add self-service privacy-request status and withdrawal-history visibility.
2. Add granular visibility controls and privacy-preserving discovery experimentation with documented review.

## Compliance Matrix

| Area | Status | Risk | Evidence | Required Action | Priority |
|---|---|---|---|---|---|
| Privacy Policy | PARTIALLY IMPLEMENTED | High | In-app policy; no acceptance/version | Counsel review, version, record acceptance | P0 |
| Terms | PARTIALLY IMPLEMENTED | Medium | Required `acceptedTerms`, timestamp | Version and re-consent design | P0 |
| Age Gate | IMPLEMENTED | Medium | Backend 18+ checks | Test all new write paths/age operations | P1 |
| Consent | PARTIALLY IMPLEMENTED | High | Combined checkbox, Terms timestamp | Separate/versioned/auditable controls | P0 |
| Account Deletion | PARTIALLY IMPLEMENTED | Critical | Anonymized user/matches/tokens only | Full lifecycle and truthful notice | P0 |
| Data Correction | PARTIALLY IMPLEMENTED | Medium | Own-profile update | Request process for all data | P1 |
| Report & Block | IMPLEMENTED | Low | Authenticated/rate-limited APIs | Operational moderation verification | P2 |
| Password Security | IMPLEMENTED | Low | bcrypt, validation, limits | Production test/monitoring | P2 |
| OTP Security | IMPLEMENTED | High | Expiry/limits/prod guard | Deployment configuration proof | P0 |
| Authentication | PARTIALLY IMPLEMENTED | Medium | JWT/refresh/token version | Device/session management | P1 |
| Authorization | PARTIALLY IMPLEMENTED | High | Auth and conversation access service | Full IDOR/pentest coverage | P1 |
| Admin Security | PARTIALLY IMPLEMENTED | Medium | RBAC/MFA/admin JWT | Coverage/offboarding/prod verification | P1 |
| Audit Logs | IMPLEMENTED | Medium | Model/service/routes | Retention/integrity/access review | P1 |
| Chat Privacy | PARTIALLY IMPLEMENTED | High | Access checks/private media | Retention, notices, staff access, previews | P1 |
| Location Privacy | PARTIALLY IMPLEMENTED | Medium | City/distance; safety permission | Deployment/SDK and precision review | P1 |
| Image Security | PARTIALLY IMPLEMENTED | Medium | MIME/magic-byte/limits | EXIF, scan, deletion, public cache review | P2 |
| Verification Data | PARTIALLY IMPLEMENTED | Critical | Private Aadhaar/selfie storage | Necessity/retention/access/encryption | P0 |
| Data Minimization | PARTIALLY IMPLEMENTED | High | Fields/models reviewed | Approved data inventory | P1 |
| Retention | NOT FOUND | High | No schedule/job found | Create and operationalize policy | P1 |
| Database Security | PARTIALLY IMPLEMENTED | High | Env config, no logging | TLS/encryption/access verification | P1 |
| API Security | PARTIALLY IMPLEMENTED | Medium | Helmet/CORS/limits/validation | Production test/configuration | P1 |
| HTTPS | NEEDS VERIFICATION | High | HTTP server + prod HSTS config | Deployment TLS proof | P1 |
| Logging | PARTIALLY IMPLEMENTED | Medium | Audit sanitization/dev OTP logs | Central redaction/access policy | P1 |
| Backups | NOT DOCUMENTED / NEEDS OPERATIONAL VERIFICATION | High | No runbook/config found | Backup/restore/encryption tests | P1 |
| Incident Response | NOT FOUND | High | No plan found | Formal tested response plan | P1 |
| Third Parties | PARTIALLY IMPLEMENTED | High | Dependencies/providers identified | Processor/vendor review | P1 |

## File Evidence

Key reviewed evidence includes:

- `Backend/src/server.js` — Helmet, CORS, JSON limits, static public profile uploads, API route registration.
- `Backend/src/controllers/authController.js`, `routes/authRoutes.js`, `services/otpService.js`, `config/otpTestConfig.js` — signup, password bcrypt, OTP flow and production test-mode guard.
- `Backend/src/routes/onboardingRoutes.js` and `middleware/profileValidation.js` — server-side 18+ validation.
- `Backend/src/controllers/accountController.js` — actual delete/deactivate behavior and its limited deletion scope.
- `Backend/src/utils/photoStorage.js`, `chatMediaStorage.js`, `identityVerificationStorage.js` — media validation and file-access design.
- `Backend/src/controllers/messageController.js` and `services/conversationAccessService.js` — private chat authorization and sender deletion behavior.
- `Backend/src/models/User.js`, `OnboardingProfile.js`, `IdentityVerification.js`, `Message.js`, `Payment.js`, `AdminAuditLog.js` — data categories/fields reviewed.
- `Backend/src/services/adminAuditService.js`, `middleware/adminRbacMiddleware.js`, `middleware/adminMfaMiddleware.js` — staff accountability and access controls.
- `lib/features/legal/presentation/legal_document_screen.dart`, `auth/presentation/signup_screen.dart`, `privacy/presentation/data_export_screen.dart`, and delete-account flow widget — user notices, consent UI, local-only export state, and deletion wording.

# Founder / MD Pre-Launch Checklist

- [ ] Privacy Policy reviewed
- [ ] Terms reviewed
- [ ] 18+ enforcement confirmed
- [ ] Consent records confirmed
- [ ] Delete Account verified end-to-end
- [ ] Report & Block verified
- [ ] Password hashing verified
- [ ] Production OTP security verified
- [ ] Admin access control verified
- [ ] Audit logging verified
- [ ] HTTPS verified
- [ ] Backup process verified
- [ ] Data retention policy approved
- [ ] Breach-response plan approved
- [ ] Third-party processors reviewed
- [ ] Legal/privacy counsel review completed
- [ ] Security testing completed

## MVP Launch Readiness

**NOT READY**

- **Critical blockers:** End-to-end deletion/retention treatment is not evidenced for most sensitive data and files; Aadhaar/selfie verification handling lacks demonstrated necessity, retention, deletion, and access-governance decisions; legal/privacy approval and accurate versioned consent/disclosure are not evidenced.
- **Required fixes:** P0 deletion lifecycle and notices, versioned legal/consent records, production OTP/secret verification; P1 access/export, retention, backup/recovery, incident response, TLS/database/storage/CORS/authorization verification.
- **Recommended fixes:** image metadata/scanning, staff-access/log governance, device session management, notification-content minimization, ongoing security testing.
- **Items requiring legal review:** policy/terms, consent, identity verification, retention/erasure exceptions, privacy-request process, breach notification, vendor processing, and age treatment.
- **Items requiring deployment verification:** HTTPS/TLS, CORS, environment secrets/test OTP, database and storage encryption/access, backups, production logs/monitoring, providers, and admin security configuration.
