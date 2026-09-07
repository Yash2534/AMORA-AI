# AMORA DPDP Implementation Plan for Senior Leadership

## 1. Document header

| Item | Assessment |
| --- | --- |
| Project | AMORA AI / AMORAA |
| Assessment date | 7 September 2026 |
| Assessment type | Read-only technical implementation assessment (source review; not a legal opinion or penetration test) |
| Repository / branch inspected | `D:\Projects\amora_ai`, branch `main` |
| Scope | Flutter client, Node/Express API, Sequelize/MySQL models and migrations, media storage utilities, admin API, and repository operations documentation/configuration. |
| Source report used | `AMORA_DPDP_COMPLIANCE_REPORT.md` (the repository contains this name; the supplied request referred to a `(2)` variant). |
| Read-only status | No application, database, deployment, legal-document, dependency, or configuration changes were made. This file is the sole assessment artifact. |

### Evidence standard and boundaries

“Implemented” means the cited source contains the control. It does **not** prove it is deployed, configured, operated, or effective. Items labeled **DEPLOYMENT VERIFICATION REQUIRED**, **OPERATIONAL / INFRASTRUCTURE VERIFICATION REQUIRED**, **LEGAL REVIEW REQUIRED**, and **SECURITY TEST REQUIRED** require evidence outside this repository. The prior report was used as a requirements source and was rechecked against current code; it was not copied as proof.

## 2. Executive summary

AMORAA has a stronger privacy/security base than a prototype: server-side age checks, password hashing, hashed/expiring OTPs, a production test-OTP startup guard, token-version invalidation, private verification/chat-media paths, report/block controls, authenticated conversation checks, and a substantial permission/MFA/audit foundation for admins are present.

It is **not ready for a public launch from a DPDP technical-readiness perspective**. The principal blockers are: an incomplete deletion lifecycle, no durable versioned privacy/consent evidence, and no production proof for OTP/provider/secrets/TLS/storage/backup controls. The visible export workflow is explicitly local/simulated and no privacy-request backend workflow was found. No retention schedule or scheduled lifecycle cleanup service was found.

| Priority | Verified items requiring work / decision | Summary |
| --- | ---: | --- |
| P0 | 4 | Deletion lifecycle, deletion re-authentication, versioned legal/consent evidence, KYC/Aadhaar lifecycle and production OTP proof. |
| P1 | 10 | Privacy requests/export, retention/jobs, sessions, chat/privacy, authorization testing, admin governance, deployment/database/logging, backup/incident/processors. |
| P2/P3 | 5 | Image hardening, notification preview minimization, usability/status history, monitoring and routine assurance. |

**Strongest verified controls:** `Backend/src/services/otpService.js` hashes OTPs and limits use; `Backend/src/config/otpTestConfig.js` rejects fixed/skip OTP settings in production; `Backend/src/middleware/profileValidation.js` enforces 18+ on profile writes; KYC and chat attachments use non-public authenticated routes; and admin actions are gated by RBAC with MFA step-up middleware and audit records.

**Launch blockers:** P0 completion evidence should include an approved data lifecycle and legal retention decisions, a tested destructive-action re-authentication path, consent/legal version records, a KYC necessity/access/retention decision, and a production configuration attestation proving test OTP settings cannot be active. Engineering alone cannot close the legal and operations portions.

## 3. Senior management decision summary

| Area | Current status | Business risk | Required decision | Owner | Priority |
| --- | --- | --- | --- | --- | --- |
| Erasure lifecycle | Partial: user anonymized and matches/tokens/OTP rows treated, most linked data not | Deleted accounts can leave sensitive content/files and inconsistent disclosures | Approve category-by-category delete/anonymize/retain policy and implementation acceptance criteria | Founder / MD, Legal/Privacy, CTO | P0 |
| Legal notices / consent | Partial: single checkbox and Terms timestamp only | Cannot evidence the document/version/purpose accepted | Approve canonical documents, versioning/re-consent policy and consent purposes | Legal/Privacy, Product, Backend, Flutter | P0 |
| Aadhaar/selfie | Private files/RBAC exist; retention/deletion/encryption at-rest unproven | High-risk identity data persists after deletion | Decide necessity, lawful purpose, access roles, retention and exception process | Legal/Privacy, Security, CTO | P0 |
| OTP production safety | Source guard is good; runtime values/provider state unknown | Test mode or development delivery/logging may undermine account security | Produce pre-launch environment attestation and negative test | DevOps, Security | P0 |
| Privacy rights | Export UI only; no request ledger | Rights cannot be reliably fulfilled/tracked | Approve request scope, identity assurance, service process and sensitive chat treatment | Legal/Privacy, Product, Backend | P1 |
| Retention/backups/incident response | No schedule/jobs/runbooks found | Data persists without governed lifecycle or recovery/breach evidence | Approve retention and recovery/incident ownership, exercises and evidence | Founder / MD, CTO, DevOps, Legal/Privacy | P1 |
| Admin/data access | RBAC/MFA/audit source exists; operational roles/monitoring need proof | Excessive staff access or audit leakage | Approve least-privilege role matrix and periodic review | Security, Admin Team | P1 |

## 4. Changes required by priority

### P0 — must complete before public launch

#### P0-1: Approved and complete account-deletion lifecycle

- **Current behavior:** `DELETE /api/account` in `Backend/src/routes/accountRoutes.js` needs only a bearer-token authenticated session. `accountController.remove` anonymizes `Users` identity fields, removes refresh tokens, matching OTP rows, and `Matches`. It does not invoke profile-photo, chat-media, KYC-file, notification/device, conversation/message, report/block, payment/subscription, rose/saved-profile, audit, login-event, or backup lifecycle handling.
- **Risk:** The UI can tell a user their account is deleted while direct identifiers, sensitive content, files, relationship records, or linked technical data remain. Foreign-key restrictions may also obstruct a future hard delete.
- **Required change:** Create an approved deletion-orchestration service and a lifecycle policy. It must atomically record the request/status, revoke access, action each category below, enqueue durable file cleanup, retain only legally approved records with a documented pseudonymization/exception rationale, and evidence completion/failure. Do not select retention periods without counsel.
- **Exact locations:** Flutter: `lib/features/settings/presentation/widgets/amoraa_delete_account_flow.dart` and `lib/core/api/phase_two_api_service.dart`. Backend: `Backend/src/routes/accountRoutes.js`, `Backend/src/controllers/accountController.js`, proposed new `Backend/src/services/accountDeletionService.js`, and proposed job directory matched to the project (`Backend/src/jobs/`). Models/migrations: current `Backend/src/models/index.js` and models listed in Section 11; proposed `AccountDeletionRequest`/lifecycle event model and migration.
- **Admin/server/legal:** Admin needs exception/legal-hold status, not raw data by default. Deployment needs worker scheduling and storage/back-up deletion evidence. **LEGAL REVIEW REQUIRED** for every retention exception.
- **Testing/evidence:** integration tests per data category; object/file absence or retention-state proof; retry/idempotency tests; access-token rejection; records of approval and job completion.

#### P0-2: Re-authenticate before destructive deletion

- **Current behavior:** Account deletion uses `requireAuth` only. There is no password, OTP, recent-authentication, Google re-authentication, or user MFA confirmation in the route/controller.
- **Required change:** Add a short-lived “deletion confirmation” challenge: local users re-enter password or verified OTP; Google users re-authenticate with a validated Google token; record a recent-auth timestamp/challenge and consume it on deletion. Avoid accepting a client-only confirmation.
- **Exact locations:** `lib/features/settings/presentation/widgets/amoraa_delete_account_flow.dart`; `lib/core/auth/auth_service.dart`; `lib/core/api/phase_two_api_service.dart`; `Backend/src/routes/accountRoutes.js`; `Backend/src/controllers/accountController.js`; `Backend/src/controllers/authController.js` or a proposed `accountSecurityService.js`; proposed `DeletionChallenge` table/migration if a durable nonce is selected.
- **Dependencies/testing:** user authentication design and Google configuration. Test expired/replayed challenge, wrong credentials, bearer token alone, local and Google accounts, and audit/log redaction.

#### P0-3: Versioned Terms, Privacy acknowledgement and consent ledger

- **Current behavior:** `signup_screen.dart` shows a combined checkbox and locally sets both `_terms` and `_privacy`; the signup API receives no acceptance/version fields. `User.termsAcceptedAt` is server-set in `authController.signup`; there is no Terms version, privacy acceptance/timestamp/version, source, re-consent, or withdrawal history. Google account creation does not establish equivalent evidence in the inspected flow. The in-app documents have effective-date text in `legal_document_screen.dart`, not a canonical immutable version store.
- **Risk:** Document/version acceptance and purpose-specific consent cannot be reconstructed, and policy updates cannot be reliably re-consented.
- **Required change:** Counsel-approved document registry and immutable acceptance/consent events. Record subject, document/purpose key, version/hash or publication ID, action, timestamp, source/platform, policy surface and actor/system evidence; represent withdrawal as a new event rather than overwriting history. Terms/Privacy wording and whether each is consent vs acknowledgement are **LEGAL REVIEW REQUIRED**.
- **Exact locations:** Flutter `lib/features/auth/presentation/signup_screen.dart`, `lib/features/legal/presentation/legal_document_screen.dart`, and settings/legal navigation; backend `Backend/src/routes/authRoutes.js`, `Backend/src/controllers/authController.js`, `Backend/src/models/User.js`; proposed `Backend/src/models/LegalDocumentVersion.js`, `ConsentEvent.js`, routes/controllers/migration. Admin must publish versions and view evidence under scoped permission.
- **Completion evidence:** API rejects missing mandatory current acknowledgements, UI displays actual version, immutable event records exist for local/Google, version-update re-consent blocks affected processing as product/legal specify.

#### P0-4: Identity verification/Aadhaar/selfie governance and production OTP proof

- **Current behavior:** `identityVerificationStorage.js` stores MIME/signature-checked Aadhaar/selfie files under `Backend/private-uploads/identity-verification` with mode `0600`; `identityVerificationRoutes.js` requires auth; `adminVerificationController.media` checks explicit Aadhaar/selfie permissions and writes an audit event. `IdentityVerification` retains storage paths and review fields. Account deletion does not call `removeStored`. No encryption-at-rest configuration, retention job, malware scan, metadata stripping, legal purpose/necessity evidence, or user deletion behavior exists in source.
- **OTP evidence:** OTP values are bcrypt hashed, expire in ten minutes, allow five attempts, consume on use, and have endpoint resend/rate limits. `otpTestConfig.js` throws if production has any fixed/test/skip OTP setting. `authController.success` only returns `devOtp` for `NODE_ENV=development`. `sendSms.js`/`sendEmail.js` log OTP values only outside production when providers are unconfigured. Runtime environment and process-manager configuration are not in the repository.
- **Required change:** Counsel and security must approve whether this verification is necessary, exact purposes, retention/deletion exceptions, staff access and file security; implement resulting lifecycle. DevOps must prove production starts with `NODE_ENV=production`, all `TEST_FIXED_OTP_*` variables absent, real SMS/email providers configured, and no development fallback output is reachable.
- **Completion evidence:** controlled KYC access test/audit record; deletion/retention job evidence; deployment startup negative tests for prohibited OTP environment variables; provider delivery and log-redaction review without exposing credentials.

### P1 — high priority

#### P1-1: Privacy requests, access/export and correction workflow

- **Current behavior:** `lib/features/privacy/presentation/data_export_screen.dart` changes in-memory `_requested/_ready` state and says it “prepares future backend” work. No export/privacy routes, model, worker, secure artifact, request status, expiry, or audit flow was found. Users can directly edit many profile fields through profile/onboarding routes, but not account records, verification records, safety reports, payment/event history, messages, device records, or staff-held notes.
- **Required change:** A request ledger with `ACCESS`, `EXPORT`, `CORRECTION`, `DELETE`, and `CONSENT_WITHDRAWAL`; authenticated intake, identity assurance/step-up where needed, case assignment, outcomes, deadlines configured only after legal review, and immutable event history. Export architecture: **User → Privacy Request → backend authorization/scope → queued generator → encrypted/private temporary artifact → expiring authenticated download → completion/audit record**. Scope must exclude or carefully redact other users’ personal data in chats, reports, matches and moderation material. **LEGAL REVIEW REQUIRED**.
- **Locations:** Replace the local UI in `lib/features/privacy/presentation/data_export_screen.dart`; add request screens from `lib/features/settings/presentation/safety_privacy_screen.dart`; proposed backend `privacyRequestRoutes.js`, controller/service/worker, `PrivacyRequest`, `PrivacyExportArtifact`, and migration; admin privacy queue/permissions.

#### P1-2: Retention schedule and scheduled cleanup jobs

- **Current behavior:** No retention configuration, worker/cron directory, scheduled cleanup, backup policy, or expiry cleanup job was found. OTP expiry is checked on verification but expired rows are not scheduled for deletion. Refresh-token, notification, device, KYC, media and audit aging are not scheduled.
- **Required change:** Legal-approved retention configuration (not hard-coded statutory periods) and idempotent jobs in proposed `Backend/src/jobs/`, invoked by a separately managed worker/scheduler. Cover expired OTPs, expired/revoked refresh sessions, final deletion queues, KYC files/records, completed export artifacts, stale notifications/delivery data, orphaned photos/chat files and approved audit/log aging. Job execution must emit operational metrics and failure alerts.

#### P1-3: Device and session control

- **Current behavior:** `RefreshTokens` stores selector/hash/expiry/IP but no user list/revoke endpoint. `UserDevice` records push token/platform/install ID/last seen; `deviceRoutes.js` only registers/unregisters the caller’s push token. Deletion destroys RefreshToken rows but does not deactivate UserDevices.
- **Required change:** User-facing session list showing coarse device/platform and last activity (do not show raw IP), revoke selected session, and “log out other sessions”; tie refresh-token/session rows to device/session metadata and invalidate push registrations on deletion/log-out as appropriate. Locations: `Backend/src/models/RefreshToken.js`, `UserDevice.js`, `routes/deviceRoutes.js`, `controllers/deviceController.js`, `utils/generateTokens.js`; proposed Flutter session-management screen under `lib/features/settings/`.

#### P1-4: Chat, message and notification privacy

- **Current behavior:** Conversation access checks membership, active counterpart, active match and blocks (`conversationAccessService.js`). Messages are sender-soft-deleted (`Message.deletedAt`) and files are removed on sender delete, but `MessageMedia` row remains and account deletion does not act on chats. Text notifications persist/send the first 160 characters: `messageController.send` passes `message: text.slice(0, 160)` to `notificationService`, which relays that body to Firebase when configured. Source does not establish end-to-end encryption.
- **Required change:** Define account-delete treatment of conversations/messages/attachments; govern staff/chat access; default push previews to “New message from …” or a user-controlled preview preference; distinguish notification-inbox text from lock-screen push. Add a product/privacy review for mutual-chat export and report evidence.

#### P1-5: Authorization assurance / IDOR testing

- **Current source evidence:** Sensitive user routes consistently use `requireAuth`; messages use membership access; chat-media download verifies the message/conversation relationship; KYC is owner-status only for user route and permissions for admin media. This is positive source evidence, not proof of complete IDOR safety. Admin API applies authentication/origin/RBAC at router level.
- **Required change:** Create a route-by-route authorization test matrix for profiles/photos, conversations/messages/media, matches, reports, KYC, payments/subscriptions, privacy requests and admin endpoints, including swapped IDs and revoked/deleted/blocked users. **SECURITY TEST REQUIRED:** authenticated and unauthenticated IDOR/API penetration test, with remediate/retest evidence.

#### P1-6: Admin security and audit governance

- **Current behavior:** Admin routes have `requireAdminAuth`, trusted-origin middleware for mutating browser requests, permission checks, MFA/step-up middleware for routes that use it, and `AdminAuditLog`. KYC media requires `verifications.aadhaar.view` / `verifications.selfie.view` and logs viewing. `adminAuditService` redacts keys matching password/token/secret/OTP/authorization/cookie/card/aadhaar/identitydocument, but generic PII fields (name, email, phone, message, location) can still enter values/metadata. No source evidence of audit retention, append-only database controls, integrity chaining, SIEM alerting, staff offboarding review, or admin UI deployment was found.
- **Required change:** Map every sensitive operation to explicit permissions and `requireRecentAdminMfa`; least-privilege KYC, chat, payment and private-profile access; redact broader PII/message fields; database-level restricted write access/immutability evidence; audit retention/monitoring/export policy. Admin should receive privacy/deletion/export queues and exception controls only with permissions.

#### P1-7: API, TLS, database and deployment verification

- **SOURCE CODE VERIFIED:** `server.js` uses Helmet, 100kb JSON limit and explicit production HSTS; `env.js` requires distinct long JWT secrets, HTTPS admin reset URL, explicit HTTPS CORS origins and MFA encryption key in production; database startup requires all migrations. `server.js` itself creates `http.createServer`, therefore TLS termination is expected upstream.
- **DEPLOYMENT VERIFICATION REQUIRED:** reverse proxy/load balancer HTTPS and HTTP redirect; HSTS actually emitted over HTTPS; WSS proxying; certificate renewal; no mixed-content Flutter/API URLs; PM2/process environment; CORS allowlist; secret source/rotation; production Firebase/Twilio/SMTP/Razorpay configuration; MySQL TLS, encryption at rest, least-privilege DB account/network access; storage mount/encryption/access controls; webhook inbound verification. `db.js` provides no MySQL TLS options in source.

#### P1-8: Logging, backup/recovery and incident response

- **Current behavior:** `sendSms.js` and `sendEmail.js` deliberately log OTPs in non-production fallback modes; errors log `err.message`; audit sanitization is limited as above. There are no backup/restore scripts, encryption policy, RPO/RTO documentation, restore-test evidence, breach/incident runbook, or backup-retention configuration in the inspected source.
- **Required change:** Central structured PII redaction policy, controlled log access/retention, production log review; operational backup/restore plan with encryption, access controls, RPO/RTO and recurring restore tests; incident runbook covering detection, classification, containment, credential/session revocation, evidence preservation, investigation, affected-data assessment, management escalation, legal/privacy assessment, notification decision, remediation and post-incident review. Notification obligations are **LEGAL REVIEW REQUIRED**.

#### P1-9: Processor register

Verified integration evidence: Twilio (`Backend/src/utils/sendSms.js`, dependency), Nodemailer/SMTP (`utils/sendEmail.js`, dependency), Google Sign-In (`authController.js`, `google-auth-library`), Firebase push (`services/firebasePushProvider.js`, `notificationService.js`), Razorpay (`Payment.provider` and payment service/configuration), Socket.IO (`realtime/realtimeHub.js` and dependency), and MySQL/Sequelize (`config/db.js`). SMTP host, Firebase and payment processors receive data only when configured/used; source does not establish contracts or actual production provider selection. Maintain a processor register of provider, purpose, data categories, country/transfer and agreement review — **LEGAL/PROCUREMENT REVIEW REQUIRED**.

### P2 — hardening

1. **Image handling:** Profile images are public under `/uploads` with seven-day immutable cache; MIME/signature, count and 12MB limit exist in `photoStorage.js`, but no EXIF stripping/re-encoding, malware scanning or moderation service was found. Add approved scanning/re-encoding/moderation and deletion/orphan cleanup. KYC/chat media are private/authenticated, but share the metadata/scanning gap.
2. **Notification minimization:** remove message text from push bodies by default and review inbox retention.
3. **Security operations:** dependency/vulnerability monitoring, rate-limit observability, periodic permission/access review, API abuse alerts and security regression tests.
4. **Safety/product review:** `blockController.remove` recreates a match if a direct conversation exists (`restoredMatch`), so unblock can restore matching. Confirm this is intended; otherwise change only after Product/Safety review.

### P3 — future improvement

1. Let users view privacy-request status and consent/withdrawal history without exposing sensitive internal notes.
2. Add an approved, privacy-preserving data inventory and minimization review for new discovery/AI features.

## 5. Exact file-by-file change map

| File / directory | Current purpose | Required change | Priority | Change type | Owner |
| --- | --- | --- | --- | --- | --- |
| `lib/features/settings/presentation/widgets/amoraa_delete_account_flow.dart` | Delete-account UI | Add backend-driven re-auth/challenge, lifecycle status and truthful wording after counsel approval | P0 | Flutter | Flutter/Product |
| `lib/core/api/phase_two_api_service.dart` | Account API client | Send/consume deletion challenge and request-status API calls | P0 | Flutter | Flutter |
| `Backend/src/routes/accountRoutes.js` | Account deactivate/delete endpoints | Require deletion proof; expose lifecycle status/request endpoint | P0 | Backend | Backend |
| `Backend/src/controllers/accountController.js` | Current anonymization/token/OTP/match handling | Delegate to approved lifecycle orchestrator; preserve idempotency/error evidence | P0 | Backend | Backend |
| **PROPOSED NEW FILE** `Backend/src/services/accountDeletionService.js` | — | Coordinate category actions, legal holds, file cleanup and durable lifecycle events | P0 | Backend | Backend |
| `lib/features/auth/presentation/signup_screen.dart` | Combined legal checkbox | Show separate/versioned mandatory acknowledgements as legally approved | P0 | Flutter | Flutter/Legal |
| `Backend/src/controllers/authController.js` / `models/User.js` | Signup and single Terms timestamp | Persist consent/document evidence via new service; include Google path | P0 | Backend/DB | Backend |
| **PROPOSED NEW FILES** `Backend/src/models/LegalDocumentVersion.js`, `ConsentEvent.js` | — | Immutable legal/consent registry and history | P0 | DB | Backend/Legal |
| `lib/features/privacy/presentation/data_export_screen.dart` | Local simulated export UI | Replace with request/status/download workflow | P1 | Flutter | Flutter |
| **PROPOSED NEW FILES** `Backend/src/routes/privacyRequestRoutes.js`, `controllers/privacyRequestController.js`, `services/privacyExportService.js` | — | Request ledger, authorization, export generation and signed/temporary artifact control | P1 | Backend | Backend |
| **PROPOSED NEW DIRECTORY** `Backend/src/jobs/` | — | Idempotent retention/export/deletion/media cleanup jobs | P1 | Backend/server | Backend/DevOps |
| `Backend/src/utils/identityVerificationStorage.js` / `controllers/identityVerificationController.js` | Private KYC upload/storage | Implement approved lifecycle and storage encryption/scanning/metadata controls | P0 | Backend/server | Backend/Security |
| `Backend/src/controllers/messageController.js` / `services/notificationService.js` | Chat and push notification creation | Minimize previews, apply deletion/retention policy | P1 | Backend | Backend/Product |
| `Backend/src/routes/deviceRoutes.js`, `controllers/deviceController.js`, `models/UserDevice.js`, `models/RefreshToken.js` | Device push registration and refresh tokens | Session list/revoke/all-other logout and lifecycle cleanup | P1 | Backend/DB | Backend |
| `Backend/src/services/adminAuditService.js` / `models/AdminAuditLog.js` | Admin audit capture | Expand PII redaction; establish integrity/retention/monitoring | P1 | Backend/ops | Security |
| `Backend/src/server.js`, `config/env.js`, `config/db.js` | Security headers/config/database bootstrap | No code conclusion for infrastructure; execute deployment checklist and evaluate DB TLS config | P1 | Server/deployment | DevOps |

## 6. Backend changes

| Feature | Route | Controller | Service | Model | Migration | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| Deletion lifecycle | Existing `/api/account` plus proposed status/request routes | `accountController` | **Proposed** `accountDeletionService` | **Proposed** request/event model; existing linked models | **Proposed** | P0 |
| Re-auth deletion | **Proposed** `/api/account/deletion-challenge` | **Proposed** account/security controller | **Proposed** challenge service | **Proposed** challenge or recent-auth data | **Proposed** if persistent | P0 |
| Legal/consent | Signup/auth + **proposed** consent APIs | `authController` | **Proposed** legal/consent service | `User`; **proposed** document/event models | **Proposed** | P0 |
| Privacy request/export | **Proposed** `/api/privacy-requests` | **Proposed** | **Proposed** generator/artifact service | **Proposed** request/artifact/event models | **Proposed** | P1 |
| Retention | No current route | — | **Proposed** jobs/retention policy service | All scoped models | **Proposed** config/event fields | P1 |
| Sessions | Extend `/api/devices` or proposed `/api/sessions` | `deviceController` | token/session service | `RefreshToken`, `UserDevice` | **Proposed** | P1 |
| KYC lifecycle | Existing `/api/identity-verification` | `identityVerificationController` | storage + **proposed** lifecycle service | `IdentityVerification` | **Proposed** | P0 |
| Notification privacy | Existing notification flow | `messageController` | `notificationService` | `Notification`, delivery/preferences | May be needed | P1 |

## 7. Flutter changes

| Screen / feature | Current behavior | Required UI change | API dependency | Priority |
| --- | --- | --- | --- | --- |
| Signup legal controls | Combined local Terms/Privacy checkbox | Separate/versioned display and submission; handle re-consent | Legal registry/acceptance API | P0 |
| Terms/privacy screens | Static Dart document text/effective date | Render counsel-approved canonical version metadata and update notices | Legal registry | P0 |
| Delete account | Reason/details and bearer-token call | Re-auth, lifecycle expectations/status, failure/retry support | Challenge/deletion API | P0 |
| Data export | Simulated two-click state | Request/status/expired-download flow and scope explanation | Privacy-request/export API | P1 |
| Privacy requests | No dedicated workflow found | Access/correction/withdrawal/delete request intake/status | Privacy-request API | P1 |
| Devices/sessions | No session-management surface found | Coarse device list/revoke/all-others action | Session API | P1 |
| Notification privacy | Preference UI exists | Add preview-content preference if product approves | Notification preference API | P1 |

## 8. Database changes (proposals only — do not apply)

| Existing table / proposal | Proposed field/table | Relationship / purpose | Data sensitivity | Priority |
| --- | --- | --- | --- | --- |
| `Users` | Optional current-legal-version pointers only; do not replace event history | Convenience state; evidence remains event-based | High | P0 |
| **Proposed `LegalDocumentVersions`** | key, semantic version, content hash, published/effective/retired timestamps | Canonical document versions | Medium | P0 |
| **Proposed `ConsentEvents`** | userId, purpose/document, version/hash, action, source/platform, occurredAt, evidence metadata | Immutable acceptance/withdrawal history | High | P0 |
| **Proposed `PrivacyRequests`** | requester, type, status, identity-verification state, scope, assigned owner, outcome/closed dates | Rights workflow | High | P1 |
| **Proposed `PrivacyExportArtifacts`** | request, private location, checksum, expiry, downloaded/removed timestamps | Temporary export control | High | P1 |
| **Proposed deletion request/events** | user, requested/approved/completed/failed timestamps, exception/hold state, job correlation IDs | Auditable deletion orchestration | High | P0 |
| `RefreshTokens` / `UserDevices` | session/device linkage, last activity, revoked timestamp/reason | Safe session management | High | P1 |
| `IdentityVerifications` | approved retention/deletion/hold state only after legal decision | KYC lifecycle | Very high | P0 |

## 9. Admin panel changes

Existing RBAC must be extended, not bypassed. Recommended matrix:

| Admin function | Current source evidence | Required control |
| --- | --- | --- |
| KYC queue/evidence | Queue/detail permissions; separate Aadhaar/selfie view permission; view audit | MFA step-up for every evidence view/decision where not already enforced; periodic role review; no broad support role access |
| Privacy requests/export | No dedicated workflow found | Scoped privacy-case permission, assignment/status/audit; downloads short-lived and logged |
| Deletion exceptions | No lifecycle exception UI found | Legal-hold/exception reason, dual approval where required, no free-form PII disclosure |
| Reports/safety | Admin safety models/routes present | Preserve authorized safety evidence under approved retention and constrain chat/profile access |
| Consent evidence | No consent ledger found | Read-only evidence lookup; version publication restricted and audited |
| Incident/security visibility | Audit logs and dashboard routes exist | Alerting, access review, export controls and protected case records |

## 10. Deployment / Hostinger verification checklist

- [ ] `NODE_ENV=production` is set for the actual server/PM2 process, and it cannot silently start with another value.
- [ ] `TEST_FIXED_OTP_ENABLED`, `TEST_FIXED_OTP`, and `TEST_OTP_SKIP_DELIVERY` are absent from production process, deployment files and secret store; startup failure is tested if added.
- [ ] Twilio/SMTP/Firebase/payment provider production configuration is validated without exposing credentials; development fallback OTP logs are not possible.
- [ ] `CORS_ORIGIN` is an explicit HTTPS allowlist; browser and non-browser admin origin behavior is tested.
- [ ] Reverse proxy/load balancer provides HTTPS, HTTP-to-HTTPS redirect, certificate renewal, HSTS and WebSocket (`WSS`) forwarding.
- [ ] API base URLs and Flutter build configuration have no HTTP/mixed-content endpoint.
- [ ] JWT/admin/MFA keys are distinct, secret-managed, access-controlled and have a rotation procedure.
- [ ] MySQL transport TLS, database at-rest encryption, least-privilege application user, network isolation and audit access are evidenced. `config/db.js` does not establish TLS options.
- [ ] Profile `/uploads` public exposure/cache behavior is approved; private KYC/chat storage permissions, encryption, backups and lifecycle are verified.
- [ ] PM2/runtime variables, process restarts, health check and migration status are recorded; migrations are applied before service start.
- [ ] Backup encryption/access/retention, RPO/RTO and restore tests are evidenced.
- [ ] Production log destinations/access/redaction and alert ownership are approved.

## 11. Data lifecycle matrix

| Data | Collection / storage | Access | Retention status | Account delete status | Export status | Required change |
| --- | --- | --- | --- | --- | --- | --- |
| Account identifiers | `Users` | Auth/admin scoped | No policy found | Anonymized; deleted status retained | Not implemented | Approved retention/anonymization rationale |
| Profile/DOB/preferences/photos refs | `OnboardingProfiles` | User/discovery per access rules | No policy | **NOT CURRENTLY HANDLED** by controller | UI scope says profile only | Delete/anonymize and physical-photo cleanup decision |
| Profile image files | public `uploads/onboarding-photos` | Public URL/static server | No policy | **NOT CURRENTLY HANDLED** | Not implemented | File deletion/orphan job; privacy/cache hardening |
| Matches/discover/saved/roses | models in `models/index.js` | Auth/admin as implemented | No policy | Matches deleted; others **NOT CURRENTLY HANDLED** | Not implemented | Per-model action decision |
| Conversations/messages/media | DB + private chat storage | Membership/block/match checks | No policy | **NOT CURRENTLY HANDLED**; message deletion exists only sender action | Scope requires legal/product review | Define participant/third-party treatment |
| KYC Aadhaar/selfie | `IdentityVerifications` + private files | Owner status; scoped admin evidence | No policy | **NOT CURRENTLY HANDLED** | Exclude/approved controlled scope | **LEGAL REVIEW REQUIRED** lifecycle/access |
| Reports/blocks/safety cases | `Report`, `Block`, admin safety models | Reporter/admin/safety controls | No policy | **NOT CURRENTLY HANDLED** | Typically restricted pending legal review | Retention/legal-hold decision |
| Notifications/devices | `Notifications`, deliveries, `UserDevices` | Owner/admin scoped | No policy | **NOT CURRENTLY HANDLED** | Not implemented | Deactivate/revoke/purge scheme |
| Sessions/OTP/login events | `RefreshTokens`, `OtpToken`, `UserLoginEvent` | Auth/admin scope | No policy | Refresh/related OTP destroyed; login events unclear | Not implemented | Cleanup job and evidence policy |
| Payments/subscriptions | payment/subscription models | User/admin/payment provider | No policy | **NOT CURRENTLY HANDLED** | UI names payments but no backend | **LEGAL REVIEW REQUIRED** financial retention |
| Admin audit/security | `AdminAuditLogs` | Audit permissions | No policy | Retain / decision required | Not implemented | Integrity/access/retention decision |
| Backups | Not documented | Operations | Unknown | Retention decision required | N/A | Operational deletion/restore governance |

### Retention decision table

| Data category | Current retention behavior | Required decision | Proposed technical location | Legal review? |
| --- | --- | --- | --- | --- |
| OTP / refresh tokens | Expiry/revocation checked but no cleanup job | Aging and secure purge | `Backend/src/jobs/` proposed | Yes |
| KYC files/records | Private files persist until resubmission replacement; no aging | Necessity, retention, deletion/hold | KYC lifecycle service/job | **Yes** |
| Photos/chat attachments | Deleted only in limited user actions | Delete/orphan/cache lifecycle | media services/job | Yes |
| Messages/conversations | Sender soft-delete only | Participant rights/safety retention | deletion/retention service | **Yes** |
| Notifications/devices | No aging job | Expiry and revocation strategy | notification/device job | Yes |
| Audit/logs | No source retention policy | Retention, integrity and access | audit/log operations | Yes |
| Payments/subscriptions | No delete path found | Financial/dispute retention | payment lifecycle policy | **Yes** |
| Backups | Not documented | Encryption, expiry, deletion propagation | Hostinger/DevOps runbook | **Yes** |

## 12. Verified existing-control notes

### Age gate

Server-side age validation is present in `Backend/src/middleware/profileValidation.js` for `birthdate`, and the onboarding/profile routes use server validation in the reviewed architecture. All new DOB write routes must reuse this validator. Underage-account handling is **LEGAL / SAFETY REVIEW REQUIRED**; do not redesign the existing 18+ control without that decision.

### Report and block

`Backend/src/routes/reportRoutes.js` requires authentication and applies `reportCreateLimiter`; `reportController` validates self/target/conversation relationships and deduplicates a matching open/reviewing report for 24 hours. `blockController` requires auth, validates active targets, and `conversationAccessService` denies blocked conversation access. Unblock removes the block and can recreate a match from an existing direct conversation; this needs explicit Product/Safety acceptance.

### Photo privacy

`photoStorage.js` limits photos to six and 12MB, checks declared MIME against signatures and randomizes server filenames. `server.js` publishes profile uploads through static `/uploads` with immutable seven-day caching. It has no image re-encoding/EXIF removal, malware scan or moderation proof. Chat media and KYC media use authenticated paths, but neither establishes malware scanning/metadata removal.

## 13. Completion gate

Before public launch, CTO/Security should provide a traceable evidence pack: approved P0 decisions; migrations/code reviews; integration and negative-security test results; deletion and file-cleanup audit trails; privacy/consent records for local and Google flows; production OTP and runtime attestation; KYC access/lifecycle test; and DevOps proof for TLS, CORS, secrets, MySQL/storage security, backups and restore testing. Legal/Privacy should approve document wording, consent purpose, KYC necessity, retention exceptions, rights workflow, processor treatment and breach-notification decision process. A completed code review alone is insufficient.
