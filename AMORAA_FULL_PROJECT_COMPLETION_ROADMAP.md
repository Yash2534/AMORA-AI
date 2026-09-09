# AMORAA Full Project Completion Roadmap

**Audit basis and scope.** This is a documentation-only repository re-audit completed 2026-09-08. It examines reconciled `main` and `origin/main`, both at `81a0ec30fcf48a62bfe63fa12acc7f4fae7ad613`, along with Flutter/Node source, migrations, tests, and non-secret configuration templates. Current main includes `16d0ac14` (account deletion/file cleanup) and `49a6ec46` (production hardening). Supplied production is also `81a0ec30`, clean, and has the five 20260907 DPDP P0 migrations applied. No service, database, build, package installation, deployment, or production source was changed by this audit.

## 1. Executive Summary

AMORAA has a substantial Flutter application and a Node/Express/Sequelize API. The current checkout implements core account onboarding, deterministic discovery, relationship actions, mutual-match conversation creation, chat, report/block flows, notifications, KYC review foundation, payment foundation, and a backend-oriented administrator API with RBAC and MFA. Events are implemented but explicitly hidden in Flutter by `AppFeatureFlags.eventsEnabled = false`.

The application is not release-ready. DPDP P0 source and migrations are present in current main, and its deployment/hardening state is supplied as verified. Final P0 operational verification is incomplete because SMTP is intentionally unconfigured: live email OTP and forgot-password smoke tests cannot yet pass. The Android application ID remains `com.example.amora_ai` and release signing deliberately uses the debug key. Production provider credentials other than supplied SMTP status, Hostinger/Nginx/PM2 detail, real device testing, external admin UI deployment, and release/Play Console evidence are not available in this repository.

| Area | Current Status | Remaining Work | Priority | Launch Blocker |
| ---- | -------------- | -------------- | -------- | -------------- |
| DPDP/privacy | PARTIAL | Complete P0 SMTP/live-email verification; add access/export/correction/withdrawal program and approved retention | P0 | Yes |
| Match engine | PARTIAL | Evolve deterministic feed into measured, safe, stable ranking | P1 | Yes for dating-product quality |
| AI suggestions | NOT IMPLEMENTED | Provider-backed, safe and observable feature or hide AI claims | P1 | Yes if marketed/released |
| Admin dashboard | PARTIAL | Deliver/verify operator UI and complete queues, support and operational workflows | P1 | Yes for safe launch operations |
| App optimization | PARTIAL | Measure and remediate release performance/reliability | P1 | Yes until QA gate passes |
| Third-party APIs | THIRD-PARTY DEPENDENCY | Configure and smoke-test SMTP, SMS, Google, FCM, Razorpay | P0 | Yes |
| Security | PARTIAL | Run auth/IDOR/dependency/infra review after P0 operational verification | P0 | Yes |
| QA/release | PARTIAL | Execute controlled test matrix and device/beta evidence | P0 | Yes |
| Play Store | NOT IMPLEMENTED | Correct identity/signing, AAB, policy/listing/declarations | P0 | Yes |

**Highest risks:** email OTP unavailability and incomplete final P0 operational verification; missing formal privacy workflows and retention decisions; debug-signed/example-ID Android release; third-party failure paths; no evidence of a deployable admin web UI; and no production performance/security/Play certification evidence.

**Recommended order:** complete P0 live production verification by configuring/testing SMTP; configure/test critical providers; close privacy/legal decisions; harden the match engine and AI scope; make operations/admin complete; execute security/performance/QA gates; then package, beta-test, and submit the signed AAB.

## 2. Current Architecture and Repository Audit

### Flutter

The Flutter app is feature-organized under `lib/features` with `main.dart` named-route registration and `MainShell` navigation. It uses direct service/repository-style data layers (`core/api`, `features/*/data`) and stateful presentation controllers; no single dedicated state-management package is declared in `pubspec.yaml`. Authentication is represented by `core/auth/auth_service.dart` with `flutter_secure_storage`; normal preferences use `shared_preferences`. `AmoraApiConfig` requires an absolute HTTPS `AMORA_API_BASE_URL` in release mode. Core packages include HTTP, Socket.IO, image picker, Google Sign-In, Razorpay, permission handler, and secure storage.

Visible mobile routes include authentication/OTP/reset, onboarding/profile/KYC, discover/filters, matches, chat, notifications, subscriptions/payments, saved/blocked/liked profiles, safety/report/settings and legal pages. The AI coach/icebreaker screens exist, but no AI provider call was found. `data_export_screen.dart` exists as UI; no corresponding backend privacy/export route/model is present in this checkout. Image picking and backend upload URLs exist; server static uploads have a seven-day immutable cache header. The app uses an explicit events flag set to false, so event source is not currently product-visible. Release error/crash telemetry configuration was not found: **NEEDS VERIFICATION**.

### Backend

`Backend/src/server.js` boots environment checks, Express, Helmet, CORS, JSON parsing, `/uploads`, `/health`, route modules, error middleware, HTTP/Socket.IO realtime, and Sequelize initialization. API domains include auth, onboarding, discover, profiles, blocks/reports, account, matches, conversations/messages, events, subscriptions/payments/roses, relationship actions, notification preferences/notifications, identity verification, devices, and `/api/admin/v1`.

JWT access/refresh paths, bcrypt passwords, hashed refresh-token records, OTP tokens, Google ID-token verification, rate limiting, validation, Helmet, upload handling, Socket.IO, local upload storage, SMTP/Twilio OTP utilities, FCM HTTP v1 push, and Razorpay provider logic are present. In current main, production config requires DB/JWT/admin secrets, SMTP and MFA encryption; Admin Web reset configuration is optional, but if supplied it must use HTTPS. Browser CORS rejects wildcard/non-HTTPS configured origins in production and fails closed when an Origin is not allowlisted. Hostinger PM2/Nginx/TLS/database operational detail remains **NEEDS VERIFICATION**; supplied P0 migration state is verified.

### Database

Sequelize migrations model the principal domains: `Users`, onboarding profiles and discover preferences/actions; blocks/reports/evidence; matches, conversations, participants, messages/media; notifications/deliveries/preferences; devices/login/timeline events; events/registration/waitlist; subscriptions/plans/payments/payment events/rose transactions; identity verification/decisions/reasons; account-deletion confirmations/requests/file tasks; legal document versions/consent events; and administrator, role, permission, session, MFA, audit, user-note, matching configuration, platform-setting and safety-case entities. Composite indexes exist in multiple migrations, notably admin/read and several discovery/relationship domains. The five P0 migration files are supplied as applied in production; full schema migration state remains **NEEDS VERIFICATION**.

### Admin Panel

The repository contains a protected admin API and Flutter admin-related feature folders, but no separately identifiable deployable admin web application/build configuration was found: **NEEDS VERIFICATION**. The API has administrator login/invitation/reset, refresh sessions, MFA enrollment/challenge/recovery, roles/permissions, audit logging, users/profile/verification/matching/financial/safety/system-setting/dashboard routes. The permission catalog is expansive, but a permission name does not prove every UX/workflow exists. Seeded `super_admin` is evidenced; Operations, Support, Finance, Marketing, Events, Content and Technical Administration roles require explicit role configuration and UI/workflow verification.

### Deployment

Known intended topology is Flutter clients → `https://api.searchenginemonks.com` → Node/Express/PM2 behind Nginx/HTTPS → MySQL, with local file uploads. This repository cannot prove DNS, certificate renewal, Nginx proxy/WebSocket configuration, PM2 startup/save, server Node version, backup jobs, persistent uploads, monitoring, or production secrets. All are **NEEDS VERIFICATION**.

# PHASE 0 — BASELINE / RELEASE INVENTORY

1. Record `git status --short`, current branch/commit, remote tracking commit and release tag. At audit time local `main` and `origin/main` both equal `81a0ec30fcf48a62bfe63fa12acc7f4fae7ad613`; this report is the only untracked project file. Repository provenance is reconciled.
2. Preserve supplied production evidence: deployment is `81a0ec30`, working tree is clean, and migrations `202609070001` through `202609070005` are applied. The hardening regression baseline is `161 PASS / 0 FAIL`; rerun it for the final release candidate after SMTP configuration.
3. Record lockfile dependency audit results (Flutter `pubspec.lock`, backend `package-lock.json`), Node/Flutter/JDK versions, and vulnerability findings. **BASELINE MEASUREMENT REQUIRED**.
4. Record migration status against a production-safe read-only connection; compare all migration filenames with the `SequelizeMeta` equivalent. Never infer from source files.
5. Record `flutter analyze`, Flutter test results, backend `npm test` results, and exact commands/log artifacts. Historical supplied result is `161 PASS / 0 FAIL` after production hardening; it is **NEEDS VERIFICATION** for this checkout and release candidate.
6. Inventory each UI feature, API route, provider environment variable (names only), public domain, permissions, feature flag, asset/upload location, secret owner and rotation date. Capture actual production configuration values only in an access-controlled inventory, never in Git.

**Phase 0 exit criteria:** clean/reconciled release tree (satisfied for supplied production deployment); signed commit/tag chosen; migration state evidenced (P0 migrations supplied as applied); final test/analyze/dependency reports recorded; feature/API/provider inventories approved; production configuration ownership established.

# PHASE 1 — DPDP / PRIVACY COMPLIANCE COMPLETION

## P0 implemented in source

Current main `81a0ec30` contains the P0 implementation and migrations. `AccountDeletionConfirmation` issues purpose-bound, hashed, short-lived deletion re-authentication confirmations; `AccountDeletionRequest` provides correlation and status lifecycle; `AccountDeletionFileTask` records idempotent profile-photo cleanup. `accountDeletionService` revokes sessions/OTPs/devices, deletes or anonymizes supported categories, prevents duplicate processing, and blocks unresolved retention categories rather than destructively guessing.

`LegalDocumentVersion` and append-only `ConsentEvent` models/services record required signup document acceptance. `authController` validates required legal documents for local and Google signup and records consent metadata/source/platform. OTP delivery-failure handling and production test-OTP guards are present. `env.js` rejects production without `EMAIL_HOST`, `EMAIL_USER`, and `EMAIL_PASS`; `originPolicy.js` rejects wildcard/non-HTTPS browser origins in production and fails closed for unconfigured browser origins. Supplied production evidence confirms `NODE_ENV=production`, the three test-OTP variables are absent, hardening `49a6ec46` is deployed, and all five P0 migrations were applied.

## P0 still pending operational verification

Production SMTP is intentionally unconfigured: `EMAIL_HOST`, `EMAIL_USER`, `EMAIL_PASS`, and `EMAIL_FROM` are empty. Live production email OTP and forgot-password delivery smoke tests are therefore incomplete. The supplied `161 PASS / 0 FAIL` hardening regression result is useful baseline evidence but does not replace controlled live delivery verification. The P0 release gate is **not PASS**, and P1 remains blocked until the agreed P0 gate is completed. Fixed OTP `111111` is development/testing only and must never be recommended or enabled in production.

## Partially Completed

Current source has terms/privacy UI, signup legal-consent tests, account deactivation/deletion, token versioning, blocks/reports, KYC storage/review and auth/login device activity. Consent withdrawal is not represented by a current consent-event purpose/action workflow. The data-export screen is not backed by an export API/job/download flow. No durable general privacy ledger is found.

## Still Required

Create a separate durable PrivacyRequest workflow for `ACCESS`, `EXPORT`, `CORRECTION`, and `WITHDRAWAL`—not a duplicate deletion request—with subject ID, request evidence, identity-verification state, assignee, status/SLA, response/secure-delivery records and immutable audit events. Build export request, step-up identity verification, async bounded generation, encrypted/object-storage download, expiry/revocation, audit/failure/notification flow. Permit direct correction of supported profile fields and a queue for restricted corrections. Add explicit marketing/optional-processing preference withdrawal with consequence copy and evidentiary consent history.

No retention schedule is found for messages, deleted accounts, reports/evidence, KYC, payments, admin logs, uploads or backups. Do not automate retention/deletion until legal approves categories, legal holds, retention duration, anonymization, backup expiry and restoration behavior. KYC destructive cleanup remains blocked until policy establishes retention grounds and approved procedure: **LEGAL REVIEW REQUIRED**. Add privacy queue RBAC, assignment, SLA/escalation, redacted views, and breach/incident runbook. Add active-session/device list, remote logout/token invalidation and suspicious-login alert/review, and ownership/IDOR tests for every data-revealing endpoint. Define redaction tests for password hashes, OTPs, JWTs, KYC, PII and provider secrets. Establish processor register, DPAs/data-transfer assessment, backup restore privacy procedure and incident evidence chain.

## Legal / Policy Decisions Required

Legal must approve lawful bases/purposes, legal-document text/version publication, consent taxonomy, age/child policy, response SLAs, identity proof for requests, scope of export, correction restrictions, retention/holds, KYC retention and deletion, processor contracts, cross-border transfers, breach escalation/notification, and backup handling. These are **LEGAL REVIEW REQUIRED**.

| Task | Current State | Required Change | Backend | Flutter | Admin | Database | Tests | Legal Dependency | Release Blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0 operational verification | PARTIAL | Configure SMTP and complete real production OTP/reset smoke and final gate evidence | Yes | Yes | Maybe | No | Yes | No | Yes |
| Privacy request ledger | NOT IMPLEMENTED | Request/SLA/audit/assignment lifecycle | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Data export | NOT IMPLEMENTED | Verified async export and expiring secure download | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Access/correction | PARTIAL | Supported edit plus restricted request process | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Consent withdrawal | PARTIAL | Granular withdrawal and evidence | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Retention/KYC/backup | BLOCKED | Approved schedule, legal holds and safe jobs | Yes | Maybe | Yes | Yes | Yes | Yes | Yes |
| Session/privacy controls | PARTIAL | Device/session listing, remote logout, alerts | Yes | Yes | Yes | Maybe | Yes | No | Yes |
| Logs/incident/processors | NEEDS VERIFICATION | Redaction, register, incident/restore runbooks | Yes | No | Yes | No | Yes | Yes | Yes |

**DPDP exit criteria:** P0 source/migration/deployment proof (currently supplied) and SMTP-backed production smoke tests recorded; legal approvals published; privacy ledger/export/correction/withdrawal work end-to-end; KYC policy executed only as approved; retention/backup/incident controls tested; authorization/redaction tests pass.

# PHASE 2 — MATCH ENGINE

## Current Match Engine

`discoverController.getFeed` selects active, completed profiles excluding self, prior `DiscoverAction` targets and blocks. It applies age, city, height, hometown, education, profession, community, religion, sexuality, smoking/drinking/weed, arrays such as intentions/languages/pronouns/qualities/talking hours/love languages, lifestyle, communication style, prompts, verified-only, online-now and event-interest filters. It additionally applies the viewer's `interestedIn` and an optional reciprocal `interestedIn` constraint. It computes deterministic compatibility in SQL from shared interests, relationship goals, languages and qualities; feeds are score-descending then ID-ascending, offset paginated. Account state and blocks are enforced; visibility/hide state beyond account completion/active state is not evidenced. `swipe` validates target active/completed and unblocked, upserts pass/like/super-like, creates reciprocal match/conversation transactionally and notifies. Rose handling exists in a separate route. Distance/location radius is not found in this pipeline. Premium entitlement is used in adjacent monetization actions but is not evidenced as ranking logic. Safety signals, moderation score, diversity, exploration, impression tracking, response behavior and stable cursor pagination are absent.

## Required Production Match Engine

Implement versioned stages: eligibility (account/KYC/visibility/age), hard reciprocal preferences, blocks/reports/safety eligibility, indexed candidate generation, deterministic compatibility, behavioral/activity/quality scoring, diversity/freshness/exploration, final rank, opaque cursor pagination, impression logging and feedback learning. Use `FinalScore = compatibility + preference + behavioral + activity + quality + exploration - penalties`; all weights are **PRODUCT / DATA DECISION REQUIRED**, feature-flagged and versioned. Never let AI bypass deterministic safety and eligibility.

Handle cold start/sparse profiles with transparent defaults and bounded broadening; exclude already-swiped, blocked, deleted, hidden and unsafe users; prevent duplicate recommendations; retain a snapshot/cursor rank key for pagination stability; add cache invalidation on profile/preference/block/action updates; restrict sensitive attributes and assess fairness. Add indexes based on measured query plans, normalized/geospatial location only with approved consent, candidate/impression/action tables, score/rule version fields and retention policy. Track impressions, opens, likes, super likes, roses, passes, matches, conversations and response rates with privacy-safe event schemas. A/B test only with pre-approved metric/guardrail design, assignment persistence, kill switch and no disparate-impact regression.

**Acceptance/exit criteria:** documented eligibility rules; ownership/block/deleted/hidden tests; deterministic test fixtures; cursor does not repeat/skip within snapshot; p95/p99 and query plans meet agreed targets; ranking events reconcile; experiment governance approved; safety and fairness review passes.

# PHASE 3 — AI SUGGESTIONS / AI MATCHES

AI-branded Flutter screens (`ai_coach`, `ai_icebreakers`, dating coach and floating assistant) exist. Current compatibility is `deterministic_explainable_v1`, using shared profile attributes and explanatory labels. No OpenAI/other AI SDK, API endpoint, model configuration, provider service, provider secret, prompt pipeline or provider test is found. Therefore AI Matches and generated icebreakers are **NOT IMPLEMENTED**; any UI that implies generation must be disabled or accurately labeled until complete.

Production AI must receive only deterministic eligible/safety-filtered candidates and data-minimized, consent-authorized profile fields. Generate bounded explanations that cite only supplied non-sensitive facts, never infer protected/sensitive traits, and clearly label suggestions as non-deterministic advice. Build server-side provider abstraction, allowlisted structured prompts, output schema validation, moderation before/after generation, per-user quotas, budgets, timeout/circuit-breaker, cache and deterministic fallback. Treat profile text as untrusted prompt data; use instruction isolation and prompt-injection test cases. Store only minimal audit metadata/redacted prompts according to approved policy. Required configuration names should include provider key, model, base URL if applicable, timeout, budget/rate limits and moderation configuration—values must never reach Flutter.

Instrument latency, errors, timeouts, fallback, input/output token/cost, moderation action and engagement. Required tests: deterministic unit selection; mocked provider contract/schema failures; malformed/unsafe output; timeout/rate-limit/provider outage; prompt injection; privacy minimization; authorization; cache and budget behavior.

**Exit criteria:** provider/legal/security approval; safe deterministic prefilter; fallback works; observability/cost caps alert; red-team safety tests and product acceptance pass; accurate UX disclosure.

# PHASE 4 — ADMIN DASHBOARD FEATURES

Implemented API evidence includes a seeded Super Admin role, permission catalog, role assignment, admin sessions, MFA and audit middleware; users/profile activity/notes; verification decision history; financial read surfaces; matching configuration/action-failure investigation; safety reports/cases/notes/actions; system settings; dashboard overview/notifications; and audit-log read endpoints. Browser-origin protection is required for authenticated admin routes. No evidence proves equivalent complete front-end screens, support ticketing, marketing campaigns, operational time tracking, finance refund execution, events/content management UI, or technical-admin dashboard UX.

| Capability | Repository evidence | Remaining decision/work |
| --- | --- | --- |
| Super Admin / roles / RBAC | COMPLETE API foundation | Verify least-privilege production role matrix and UI |
| Operations/User management | PARTIAL | Complete queue UX, statuses, assignment/SLA |
| Verification/Moderation/Safety | PARTIAL | Verify operator UI/evidence access/review load and escalation |
| Finance | PARTIAL | Reconcile/refund approvals, webhook operations and UI |
| Support/Marketing/Content/Events | NEEDS VERIFICATION | Build only proven product requirements and queues |
| Analytics dashboard | PARTIAL | Define metric provenance, DAU/WAU/MAU, revenue/failure/privacy/safety views |
| Work management | NOT IMPLEMENTED | Assignment, priority, SLA, escalation, approvals/time metrics |
| Auditability | PARTIAL | Before/after/redaction, IP/device context, high-risk recent-MFA checks |
| Dashboard UX | NEEDS VERIFICATION | Route inventory; loading/error/empty/responsive/accessibility testing |

Required dashboard metrics: total/active/new users, DAU/WAU/MAU, matches/messages/reports, pending KYC, subscriptions/revenue/failed payments, privacy requests and safety incidents—only after their definitions/source-of-truth queries are reviewed. Enforce MFA/session/recent-auth, RBAC at both route and service layer, CSRF/origin handling, secure recovery, audit coverage and sensitive-data minimization.

**Exit criteria:** deployable protected operator UI verified against all API guards; critical verification/report/safety/payment/privacy queues staffed; assignment/SLA/audit flows tested; dashboards agree with reconciled database data; no blank/404/error-state failures in operator journeys.

# PHASE 5 — APP OPTIMIZATION

Source contains retry-oriented discover work, pagination, backend static-image cache headers and indexed migrations; however no measured startup, rendering, memory, network, battery, APK/AAB, crash or API p95 baseline is in the repository. **BASELINE MEASUREMENT REQUIRED** for all numeric targets.

Profile Flutter cold start/first frame, rebuilds, navigation, image decode/cache, list virtualization/pagination, API duplication, memory/battery/background behavior, animation jank, unused assets, debug/release logging, offline/reconnect and crash capture on release artifacts. Profile HTTP timeout/retry/backoff/cancellation/connection reuse/compression/cache semantics. On backend, capture endpoint latency/query count/query plans, N+1 queries, payload sizes, connection pool/transactions/deadlocks, upload processing and Socket.IO concurrent load. Review high-volume users/actions/matches/conversations/messages/notifications/reports/audit logs for access paths and indexes before adding indexes. For images, introduce measured upload limits, validation, thumbnails, unique keys, durable storage/CDN decision, broken/duplicate handling and cache policy. Set concrete p50/p95/p99, first-frame, crash-free/ANR, memory and release-size targets only after baseline and product SLO approval.

**Exit criteria:** release profile baselines published; agreed budgets met on device/network matrix; query plans approved; no known leak/jank/high-volume query blocker; image/upload and offline/error behavior tested.

# PHASE 6 — THIRD-PARTY API INTEGRATIONS

| Service | Purpose | Current Status | Dev Config | Production Config | Secret Required | Webhook | Privacy Review | Test Required | Launch Blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SMTP/Nodemailer | Email verification/reset OTP | THIRD-PARTY DEPENDENCY | Template supports blank/dev fallback | Host/user/pass required by production env; actual state unverified | Yes | No | Yes | Delivery/failure smoke | Yes |
| Twilio SMS | SMS OTP | PARTIAL | Optional `SMS_PROVIDER`/Twilio vars | Credentials/from number unverified | Yes | No | Yes | Expiry/resend/rate/failure | Yes if SMS launch path |
| Google Sign-In | Google identity | PARTIAL | Flutter plugin and backend ID-token verifier | Client IDs/SHA fingerprints/Cloud setup unverified | Client IDs | No | Yes | Token/audience/failure | Yes if shown |
| Firebase FCM | Push | PARTIAL | Backend HTTP v1 provider exists | Project/service credentials and Android setup unverified | Yes | No | Yes | Register/invalid token/delivery | Yes for notifications |
| Razorpay | Payments/subscriptions | PARTIAL | Flutter package/backend provider | Live keys, webhook secret, reconciliation unverified | Yes | Yes | Yes | Signature/idempotency/refund/failure | Yes if monetization launched |
| AI provider | AI features | NOT IMPLEMENTED | None | None | Yes | Maybe | Yes | Full provider suite | Yes if marketed |
| File storage | Profile/chat/KYC media | PARTIAL | Local uploads/private uploads | Object storage/CDN/backup/persistence unverified | Maybe | No | Yes | Auth/retention/recovery | Yes |
| Maps/location | Location filtering | NOT IMPLEMENTED | Permissions only | Provider not found | Maybe | No | Yes | Consent/accuracy | No unless launched |
| Analytics/crash reporting | Quality telemetry | NOT IMPLEMENTED | No dependency/config found | Vendor/consent required | Yes | No | Yes | Release event/crash test | Yes |
| KYC provider | Identity checks | PARTIAL | Internal upload/review workflow | External provider not found | Maybe | Maybe | Yes | Sensitive-data workflow | Yes |

For every provider, nominate an owner; maintain credential rotation/contact/escalation record outside Git; test sandbox and production separately; monitor delivery/error/latency; implement idempotency and signed webhooks where relevant. Production SMTP integration is the confirmed current blocker: `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, `EMAIL_PASS`, and `EMAIL_FROM` must be configured securely and real forgot-password OTP delivery must pass.

**Exit criteria:** each launch provider has approved privacy/security review, live credential verification, failure fallback/runbook, alerting and production smoke evidence; no secret is committed or bundled in Flutter.

# PHASE 7 — SECURITY HARDENING

**P0 launch blockers:** (1) final SMTP-backed production email OTP/reset smoke and P0 operational gate; (2) change Android example ID/debug signing; (3) production infra/TLS/backup/secret verification; (4) authorization/IDOR coverage for all user/admin/media/privacy endpoints; (5) security review of uploads, private KYC/media and provider webhooks. Commit/migration/deployment provenance itself is resolved.

**P1 before public launch:** verify access/refresh rotation/revocation and concurrent sessions; password/OTP enumeration and brute-force limits; route/service RBAC and recent MFA for high-risk admin actions; CSRF/origin/CORS behavior; input validation/SQL query safety; MIME/content/size validation, malware process and path traversal; XSS in user content/admin rendering; SSRF review; log redaction; dependency vulnerability remediation; Helmet/header/TLS/Nginx/PM2 and database least privilege; Google token audience; Razorpay webhook signature/idempotency; abuse/rate/report controls. **P2:** continuous SAST/DAST, key rotation drills, formal penetration test cadence, anomaly detection and threat-model updates.

**Security exit criteria:** no known P0; P1 risk acceptance is explicit and time-bounded; independent auth/IDOR/admin/upload/webhook tests pass; secrets scan/dependency audit/infra checklist clean; restore and incident exercises documented.

# PHASE 8 — COMPLETE QA / TESTING

Build a versioned release matrix covering backend unit/integration/migrations/authorization/IDOR; signup/login/password reset/OTP/Google; deletion/DPDP; discover/matching/relationships/roses; chat/realtime/messages/media; notification/device/push; KYC; subscriptions/Razorpay/webhooks; admin/MFA/RBAC/audit/safety; and every provider failure. Existing backend test files evidence coverage in many of these areas but do not prove current green status.

Flutter needs unit/widget/navigation/responsive/API-contract tests plus release-device testing on small/normal/large Android phones, supported Android versions, low-memory device, slow/offline/reconnect networks and permission denial. Execute full journey: Create Account → Verify → Onboarding → Discover → Profile → Like/Super Like/Rose → Match → Chat → Notification → Subscription → Settings → Privacy → Deletion. Execute admin journey: Login → MFA → Dashboard → Users → Verification → Moderation → Safety → Reports → Audit Log. Force API timeout/outage, SMTP/OTP, Google, payment, AI, push and upload failures.

**Release QA gate:** frozen candidate; all automated suites green with recorded environment; zero open P0/P1 defects; manual device/provider journeys pass; accessibility and permission outcomes reviewed; rollback validated; product/security/legal sign-off attached.

# PHASE 9 — PRODUCTION INFRASTRUCTURE

Before deployment, identify a signed Git release commit, exact Node version, production environment checksum (names/status only), MySQL migration ledger and backup. Verify restrictive file permissions, non-root DB user, persistent/private upload locations, PM2 ecosystem/startup/save/restart strategy, log rotation/disk alerts, Nginx proxy plus WebSocket upgrade, HTTPS/TLS renewal, and monitoring/uptime alerts. Plan an atomic migration with backup, maintenance posture, forward-only rollback plan and tested restoration; do not improvise rollback by destructive migration down operations.

Health evidence must include local and public HTTPS `/health`, PM2 process state/restart count, DB query, authenticated realtime, upload/private-media authorization, SMTP OTP, push, Google and payment sandbox/live-safe checks. Hostinger-specific state remains **NEEDS VERIFICATION**.

**Deployment gate:** backup/restore evidence; approved change window/owners/runbook; health and integration checks pass after deployment; alerts/log rotation/disk/database backups active; rollback decision criteria agreed.

# PHASE 10 — ANDROID RELEASE BUILD

The potential API build define is valid only after production verification: `flutter build appbundle --release --dart-define=AMORA_API_BASE_URL=https://api.searchenginemonks.com`. Play release should use AAB, not a debug-signed APK. Current `android/app/build.gradle.kts` has namespace/application ID `com.example.amora_ai`, inherits Flutter SDK defaults, and explicitly signs release with debug config. This is a hard stop.

Set and register the final unique application ID, version name/code policy, supported min/target/compile SDK, secure upload keystore/signing config held outside source, Play App Signing posture, R8/ProGuard and symbol upload, adaptive icon/splash, and release logging/crash capture. Audit declared INTERNET, CAMERA, coarse/fine location, notification, image/video permissions and remove any not essential; no microphone permission is declared. Verify no debug API URL, test OTP, development keys or secret in the AAB; release code already rejects non-HTTPS API base URL.

**Android release gate:** signed reproducible AAB with final ID/version, verified manifest/permissions, production endpoint, no debug signing/secrets/test OTP, device install/upgrade/uninstall tests and Play pre-launch results.

# PHASE 11 — GOOGLE PLAY CONSOLE READINESS

Create/verify developer account, organization/business data where applicable, app identity/language/category/free-paid/contact records, store title/descriptions, icon, feature graphic, phone/tablet screenshots as applicable and reviewer access instructions. Publish public Privacy Policy and Terms URLs and provide a reachable account-deletion mechanism/page if current Play policy requires it. Complete Data Safety using the actual processor/data inventory, encryption, sharing, deletion and retention facts—not assumptions.

For dating/UGC, document adult/minimum-age positioning, user-generated content moderation, block/report, child-safety process and sexual-content declarations. Complete content rating, target audience, ads declaration, sensitive-permission declarations and app access instructions. If subscriptions/digital benefits are sold, assess Google Play Billing requirements versus Razorpay: **POLICY REVIEW REQUIRED**. Use Internal then Closed testing (Open testing only if appropriate), and mark any account-specific tester/production-access requirements **VERIFY IN CURRENT PLAY CONSOLE**.

# PHASE 12 — INTERNAL / CLOSED BETA

Freeze a release candidate; create non-production tester accounts and privacy-safe seeded data; establish support/feedback and triage SLA; enable crash/ANR/API/provider monitoring; run test plans and regression handling; classify blocker severity; track known issues and consent to beta disclosures. Do not use real KYC/payment data without approved controls.

**Beta exit criteria:** agreed tester coverage/duration, no unresolved P0/P1, monitored crash/ANR/API/payment/OTP targets met, high-risk dating safety flows tested, feedback resolved or explicitly accepted, release/governance approvals logged.

# PHASE 13 — PRODUCTION LAUNCH

1. Freeze and tag approved release candidate.
2. Verify production commit, configuration inventory, backup and migration ledger.
3. Deploy backend under approved PM2/Nginx procedure; run health/realtime/upload/provider checks.
4. Build and verify signed production AAB.
5. Complete Play declarations/listing/access instructions; upload testing/release artifact and submit.
6. Monitor review; roll out only under approved staged rollout conditions.
7. Monitor API/mobile/provider/safety health with on-call and rollback owners.

These are launch-day documentation steps only; none were run in this audit.

# PHASE 14 — POST-LAUNCH

Monitor at 24 hours, 72 hours, 7 days and 30 days: crash-free/ANR, API error/latency, signup and OTP delivery, profile completion, discover impression→match and chat engagement, report/block/safety incidents, subscription conversion/payment failures, push/SMTP delivery, AI cost/latency if enabled, support backlog and infrastructure capacity. Escalate/rollback for account/authentication failure, privacy/safety incident, payment integrity issue, material data loss, sustained provider outage, severe crash/ANR regression or breached SLO. Preserve incident evidence and communicate through approved legal/support channels.

# MASTER DEPENDENCY ORDER

P0 live production verification (SMTP/email OTP) → critical third-party integrations → DPDP P1/privacy completion → safe deterministic match-engine completion → AI implementation or disable/hide → admin operational completion → optimization → security hardening → full QA → production infrastructure verification → signed AAB → Play Console → internal/closed beta → staged production release.

# MASTER TASK TABLE

| ID | Phase | Task | Priority | Status | Dependency | Backend | Flutter | Admin | DB | Third Party | Legal | Tests | Launch Blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BASE-001 | 0 | Preserve reconciled release/migration baseline | P0 | COMPLETE | None | Yes | Yes | Yes | Yes | No | No | Yes | No |
| DPDP-001 | 1 | Complete P0 SMTP/live email smoke and final gate evidence | P0 | PARTIAL | BASE-001 | Yes | Yes | Maybe | No | SMTP | No | Yes | Yes |
| DPDP-002 | 1 | Privacy request/export/correction/withdrawal | P0 | NOT IMPLEMENTED | DPDP-001 | Yes | Yes | Yes | Yes | Storage | Yes | Yes | Yes |
| DPDP-003 | 1 | Retention/KYC/backup/incident program | P0 | BLOCKED | Legal approval | Yes | Maybe | Yes | Yes | Storage | Yes | Yes | Yes |
| MATCH-001 | 2 | Versioned safe ranked candidate pipeline | P1 | PARTIAL | DPDP-001 | Yes | Yes | Yes | Yes | No | Product | Yes | Yes |
| MATCH-002 | 2 | Impression analytics/experiments | P1 | NOT IMPLEMENTED | MATCH-001 | Yes | Yes | Yes | Yes | Analytics | Privacy | Yes | Yes |
| AI-001 | 3 | Provider, safety, fallback, observability | P1 | NOT IMPLEMENTED | MATCH-001 | Yes | Yes | Yes | Maybe | AI | Yes | Yes | Yes if advertised |
| ADMIN-001 | 4 | Operator dashboard/queues/SLA UX | P1 | PARTIAL | DPDP-002 | Yes | Maybe | Yes | Yes | No | No | Yes | Yes |
| OPT-001 | 5 | Measure and meet app/API/database budgets | P1 | PARTIAL | Core flows | Yes | Yes | No | Yes | CDN/telemetry | No | Yes | Yes |
| API-001 | 6 | Configure and smoke-test SMTP | P0 | THIRD-PARTY DEPENDENCY | Yes | Yes | No | No | SMTP | Yes | Yes | Yes |
| API-002 | 6 | Validate SMS/Google/FCM/Razorpay/storage | P0 | THIRD-PARTY DEPENDENCY | Yes | Yes | Yes | Maybe | Providers | Yes | Yes | Yes |
| SEC-001 | 7 | Auth/IDOR/upload/webhook/infra assessment | P0 | PARTIAL | BASE-001 | Yes | Yes | Yes | Yes | Providers | Yes | Yes | Yes |
| QA-001 | 8 | Full automated/manual release matrix | P0 | PARTIAL | Prior P0s | Yes | Yes | Yes | Yes | Providers | No | Yes | Yes |
| DEPLOY-001 | 9 | Hostinger/PM2/Nginx/backup/monitoring gate | P0 | NEEDS VERIFICATION | QA-001 | Yes | No | No | Yes | Providers | No | Yes | Yes |
| PLAY-001 | 10-11 | Final ID/signing/AAB/Console declarations | P0 | NOT IMPLEMENTED | DEPLOY-001 | No | Yes | No | No | Play | Policy | Yes | Yes |
| BETA-001 | 12 | Internal/closed beta and gates | P0 | NOT IMPLEMENTED | PLAY-001 | Yes | Yes | Yes | Maybe | Providers | No | Yes | Yes |

# LAUNCH BLOCKER TABLE

| Blocker | Why It Blocks Launch | Required Fix | Owner/Area | Verification |
| --- | --- | --- | --- | --- |
| Production SMTP integration | Forgot-password/email OTP requires real delivery; production env enforces SMTP | Secure configuration and live OTP smoke/failure monitoring | Backend/DevOps | Controlled production test evidence |
| Final P0 operational verification | P0 source/migrations/deployment are verified, but live email OTP/reset paths remain untested | Configure SMTP and record live controlled OTP/reset smoke results | Backend/DevOps | SMTP configuration status plus production smoke evidence |
| Debug Android identity/signing | Cannot safely publish example-ID, debug-signed app | Final ID, upload key, signed AAB | Android/Release | AAB/signing/Play checks |
| Unverified critical providers | Login/push/payment/Google behavior can fail at launch | Configure, test, monitor, runbooks | Backend/DevOps | Production-safe smoke tests |
| Privacy retention/KYC policy | Destructive processing cannot be lawful/safe without decisions | Legal approval and implemented controls | Legal/Privacy | Signed policy + tests |
| QA/security/infra gates | No evidence release candidate is safe/recoverable | Complete gates | Engineering/QA/DevOps | Approved release evidence |

# DEFINITION OF DONE FOR EACH MAIN AREA

- **DPDP:** approved policy and P0 live proof; request/export/correction/withdrawal and retention/incident controls pass end-to-end.
- **Match Engine:** safe/versioned ranking, stable pagination, analytics and quality/SLO acceptance pass.
- **AI Suggestions:** provider-safe, consented, bounded, moderated, fallback-capable and observable—or hidden.
- **Dashboard:** least-privilege protected workflows/queues and audit/SLA operations work in deployable UI.
- **Optimization:** measured release budgets pass on agreed devices/load/query plans.
- **Third-party APIs:** every launch provider passes production smoke, monitoring and failure runbook.
- **Security:** no P0, independently tested auth/IDOR/admin/upload/webhook/infra controls.
- **QA:** matrix green, device/provider/failure journeys signed off.
- **Production Infrastructure:** backup/restore, health, monitoring, deployment/rollback evidence complete.
- **Play Store:** final signed AAB and current Console/policy/listing/declarations completed.

# RELEASE GATES

## Gate 1 — DPDP

P0 production verification and remaining privacy/legal controls pass.

## Gate 2 — Core Product

Discover, matching, profile, relationship actions, chat and settings work on release devices.

## Gate 3 — AI

AI is safe, reliable and fallback-capable, or disabled/not marketed.

## Gate 4 — Admin

Critical operational and safety capabilities are available to authorized staff.

## Gate 5 — Third Party

All launch-critical providers work in production.

## Gate 6 — Performance

No known release-blocking performance issue; approved budgets pass.

## Gate 7 — Security

No known P0 security issue.

## Gate 8 — QA

Full release candidate passes.

## Gate 9 — Production Backend

Health, backup/restore and integrations pass.

## Gate 10 — Play Console

Listings, declarations, testing track and build checks are complete.

Only after Gate 1 through Gate 10 pass: `AMORAA READY FOR PRODUCTION RELEASE`.

# FINAL RECOMMENDED EXECUTION PLAN

## Step 1 — Immediate blocker

**Objective:** complete the outstanding P0 operational gate and restore email OTP viability. **Exact work:** preserve current `81a0ec30`/production/migration evidence, configure SMTP outside Git, execute controlled verification/reset delivery/failure tests, and record final P0 evidence. **Dependencies:** production access and email-provider credentials. **Expected areas:** release/DevOps, backend environment, auth/OTP. **Tests:** real email smoke plus failure monitoring. **Exit:** SMTP and final P0 operational blocker closed.

## Step 2 — DPDP completion

**Objective:** implement DPDP P1 after the P0 gate passes. **Exact work:** legal decisions; ledger/export/correction/withdrawal; retention/KYC/backup/incident controls. **Dependencies:** Step 1 and counsel. **Expected areas:** account/auth/privacy/admin/models/migrations/UI. **Tests:** identity, authorization, export expiry, redaction and retention tests. **Exit:** Gate 1 passes.

## Step 3 — Match Engine

**Objective:** deliver safe, measurable recommendations. **Exact work:** versioned eligibility/ranking/cursor/impressions and governed experiments. **Dependencies:** privacy/safety rules. **Expected areas:** discover models/controllers/services/admin configuration/UI analytics. **Tests:** deterministic fixtures, IDOR/block/deleted/fairness/load. **Exit:** measurable acceptance criteria pass.

## Step 4 — AI Suggestions

**Objective:** make AI truthful, safe and resilient. **Exact work:** provider abstraction, data minimization, moderation, limits/cache/fallback/metrics—or hide AI feature. **Dependencies:** Step 3 and legal/provider approval. **Expected areas:** new server service/routes, AI UI, configuration/admin. **Tests:** provider/safety/timeout/injection. **Exit:** Gate 3 passes.

## Step 5 — Dashboard

**Objective:** equip operations and safety staff. **Exact work:** verify/build UI for proven APIs, queues, SLA/assignment, high-risk audits and metric definitions. **Dependencies:** privacy/safety workflows. **Expected areas:** admin frontend/API/models. **Tests:** role/MFA/route/error-state operator journeys. **Exit:** Gate 4 passes.

## Step 6 — Optimization

**Objective:** meet release performance budgets. **Exact work:** profile devices/network/API/DB/images and remediate measured bottlenecks. **Dependencies:** stable core flows. **Expected areas:** Flutter/network/backend/DB/storage. **Tests:** profiling/load/device matrix. **Exit:** Gate 6 passes.

## Step 7 — Third-party production integrations

**Objective:** make all launch services dependable. **Exact work:** configure/verify SMS, Google, FCM, Razorpay, storage, telemetry and AI if enabled. **Dependencies:** Step 1, vendor accounts/legal. **Expected areas:** provider configs/backend/mobile. **Tests:** production-safe happy/failure/webhook tests. **Exit:** Gate 5 passes.

## Step 8 — Security

**Objective:** remove launch security risks. **Exact work:** threat model and P0/P1 remediation across auth, IDOR, uploads, webhooks, logs, dependencies and infrastructure. **Dependencies:** provider/config inventory. **Expected areas:** all tiers/DevOps. **Tests:** independent negative/security tests. **Exit:** Gate 7 passes.

## Step 9 — Complete QA

**Objective:** certify release candidate behavior. **Exact work:** execute Phase 8 matrix and defect closure. **Dependencies:** Steps 1–8. **Expected areas:** all tiers. **Tests:** automated/manual/device/failure. **Exit:** Gate 8 passes.

## Step 10 — Production deployment

**Objective:** prove recoverable healthy service. **Exact work:** backup, controlled deploy/migrations and health/provider checks. **Dependencies:** QA/security. **Expected areas:** Hostinger/PM2/Nginx/MySQL. **Tests:** restore/health/realtime. **Exit:** Gate 9 passes.

## Step 11 — Play Store preparation

**Objective:** create compliant release artifact/listing. **Exact work:** final app ID/signing/AAB, declarations, policy URLs/assets/reviewer instructions. **Dependencies:** backend and legal facts. **Expected areas:** Android/Play/legal. **Tests:** install/pre-launch review. **Exit:** Gate 10 passes.

## Step 12 — Beta

**Objective:** validate with controlled users. **Exact work:** internal/closed tracks, monitoring, support and issue triage. **Dependencies:** Gates 1–10. **Expected areas:** release/QA/ops. **Tests:** beta matrix/telemetry. **Exit:** beta criteria pass.

## Step 13 — Production launch

**Objective:** staged, observable public release. **Exact work:** execute Phase 13 runbook and monitor Phase 14. **Dependencies:** beta approval. **Expected areas:** all owners. **Tests:** launch smoke/rollback readiness. **Exit:** stable rollout and incident-free gate period.

# FINAL SUMMARY

`PROJECT COMPLETION REPORT: COMPLETE`

`CURRENT RELEASE STATUS: NOT READY — P0 source/deployment is verified at 81a0ec30, but SMTP/live OTP final verification and further privacy, release, QA and Play gates remain unresolved`

`CURRENT HIGHEST PRIORITY BLOCKER: Production SMTP integration and final live P0 email OTP verification`

`DPDP STATUS: PARTIAL — P0 source/migrations are in current main and deployed; SMTP-backed live P0 verification plus DPDP P1/privacy/legal work remain`

`DPDP P1.1 PRIVACY REQUEST LEDGER: IMPLEMENTED — durable authenticated ACCESS, EXPORT, CORRECTION, and WITHDRAWAL request evidence is available; each new request awaits a future approved privacy-request identity-verification workflow. No export, correction, or withdrawal processing is implemented.`

`SMTP: DEFERRED / RELEASE BLOCKER`

`PRODUCTION P0 VERIFICATION: PENDING`

`MATCH ENGINE STATUS: PARTIAL — deterministic filter/compatibility feed exists; production ranking/analytics/safety completion remains`

`AI SUGGESTION STATUS: NOT IMPLEMENTED — UI and deterministic compatibility exist, no AI provider implementation found`

`ADMIN DASHBOARD STATUS: PARTIAL — strong protected backend foundation; deployable complete operator UI/workflows need verification/completion`

`APP OPTIMIZATION STATUS: PARTIAL — implementation hints exist, release measurement and remediation are required`

`THIRD-PARTY API STATUS: THIRD-PARTY DEPENDENCY — SMTP is blocked; other live configurations are unverified`

`PLAY STORE READINESS: NOT IMPLEMENTED — example package ID and debug release signing are present`

`PRODUCTION RELEASE READY: NO`

`NEXT RECOMMENDED PHASE: Complete the P0 SMTP/live production verification gate before P1`
