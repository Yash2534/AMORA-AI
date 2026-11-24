# CLAUDE.md — AMORA-AI (AMORAA)

Project knowledge for Claude Code sessions. Written 2026-11-16 from static discovery
(`AMORA-AI-QA/discovery/*.md`), spot checks of the code, and live QA observations on client
staging. Where something was not verified it says **unverified**. The code wins over older
docs (several docs have drifted; see "Doc drift").

> **Security rule:** never write secret values (passwords, tokens, keys, OTP allowlists, DB
> credentials, QA or demo account passwords) into this file, reports, commits or chat. Refer to
> them as "credentials supplied separately". `.env` files are git-ignored. Keep it that way.

---

## 1. Overview

- **AMORAA / Amora AI**: a dating and matchmaking app for India (`pubspec.yaml` description:
  "Premium AI-powered dating and matchmaking platform for India."). App title `AMORAA`.
- Two parts in one repo:
  - **Flutter client** at the repo root (`lib/`, `test/`, `android/`, `ios/`, `web/`, ...). Package `amora_ai`.
  - **Node.js backend** in `Backend/` (Express, Sequelize, MySQL, socket.io).
- The shipped target is the **native mobile app** (Android first). The Flutter web build exists
  but is not hosted. QA uses it only as a harness (§14).
- Indian market assumptions: phone numbers must be `+91[6-9]XXXXXXXXX`. Payments go through Razorpay.
- Branch `main`. HEAD at discovery time was `09db0094`. `AMORA-AI-QA/` is an **untracked** QA workspace.

## 2. Tech stack

| Layer | Tech |
|---|---|
| Client | Flutter / Dart (SDK `^3.12.0`). Plain `MaterialApp.routes`. `http`, `socket_io_client`, `flutter_secure_storage`, `shared_preferences`, `image_picker`, `geolocator`, `permission_handler`, `firebase_core` / `firebase_messaging`, `google_sign_in`, `razorpay_flutter`, `share_plus`, `url_launcher`, `emoji_picker_flutter` |
| API | Node >= 18, Express 4, Helmet, cors, express-validator, express-rate-limit (in-memory), jsonwebtoken, bcrypt, multer, google-auth-library, nodemailer, twilio |
| Realtime | socket.io 4 attached to the same HTTP server |
| DB | MySQL through Sequelize 6 (`mysql2`). 63 dated migrations plus a custom runner (`src/migrations/run.js`). No `sequelize.sync()` at startup |
| Ops (staging) | PM2 (fork mode, 1 instance) behind nginx, TLS via certbot. Files in `Backend/deploy/client-staging/` |

## 3. Repository layout (top level)

```
lib/                Flutter app (core/ + features/)
test/               Flutter tests (86 *_test.dart files)
web/ android/ ios/  Platform shells (no android/app/google-services.json)
Backend/            Node API: src/, test/, scripts/, deploy/, postman/, docs/
docs/               Audits, SRS gap audit, client-release reports, security/compliance docs
AMORAA_*.md         Many root-level reports (match engine, security, roadmap). Read-only history
amora_ai.sql        SQL dump (not inspected for data)
AMORA-AI-QA/        QA workspace (untracked): discovery, tools, evidence, reports, webbuild
```

The repo root also contains `Backend.zip`, `lib.zip`, `node_modules/`, `tmp/` and `output/`.
They are not part of the app source. Do not edit them.

## 4. Frontend structure & navigation

- `lib/main.dart`:
  - `main()` initialises push (mobile only). It then awaits `AuthService.initialize()`,
    `AmoraSession.restore()` (`/api/auth/me` plus membership), and the profile, relationship,
    onboarding and chat repositories, all **before `runApp`**. A slow backend means a long blank start.
  - It registers **60 named routes**, aliases included.
  - `initialRoute` comes from `resolveAmoraInitialRoute`. It is always `/splash`, except that web
    hash URLs `#/profile-completion` and `#/photo-manager` open directly.
  - `onUnknownRoute` goes to `BrowseGridScreen` without the bottom nav.
- `lib/core/`: `auth/` (AuthService, secure storage), `access/amora_access.dart` (AmoraSession,
  `requireAuth`, `authenticatedRecoveryRoute`), `api/`, `config/` (`amora_api_config.dart`,
  `app_feature_flags.dart`), `navigation/main_shell.dart`, `theme/`, `widgets/`, `data/` (dummy models).
- `lib/features/<feature>/{data,domain,presentation}`. Features include auth, onboarding, splash,
  discover, match, chat, profile, settings, safety, notifications, subscription, payment,
  monetization, rose, events, legal, support, ai_coach, preferences, theme, plus several unregistered folders (§12).
- **MainShell (`/main`) has 4 tabs:** Discover (`BrowseGridScreen`), Chats (`ChatListScreen`),
  AI Matches (`MatchesScreen`), Profile (`ProfileScreen`). The Events tab is compiled out by
  `AppFeatureFlags.eventsEnabled = false` (`main_shell.dart:33-39`).
- **Key routes:**
  - Auth: `/splash`, `/login`, `/signup`, `/account-verification` (OTP), `/forgot-password`,
    `/reset-password`, `/change-password`, `/welcome-back-reactivation`.
  - Onboarding and profile: `/profile-onboarding` (6 steps), `/profile-completion`, `/edit-profile`,
    `/photo-manager`, `/kyc`.
  - Discover and matching: `/browse`, `/filters`, `/profile-detail`, `/chat-detail`, `/notifications`.
  - Membership: `/subscription` (aliases `/membership`, `/manage-subscription`), `/payment`.
  - Settings and safety: `/profile-settings`, `/report-flow`, `/safety-center`, `/support`.
  - Legal: `/terms`, `/privacy-policy`, `/community-guidelines`.
  - Account: `/logout`, `/deactivate-account`, `/delete-account`.
- **No route guards.** Auth is enforced per action (`AmoraSession.requireAuth`) and by the splash
  redirect: guest goes to `/login`; unverified goes to `/account-verification`; onboarding incomplete
  goes to `/profile-onboarding`; otherwise `/main`.
- API base URL is set at compile time with `--dart-define=AMORA_API_BASE_URL`:
  - Debug default is `http://localhost:5000`, or `http://10.0.2.2:5000` on the Android emulator.
  - Release builds default to `https://api.searchenginemonks.com` and reject non-HTTPS overrides.
  - Staging builds must explicitly set `AMORA_API_BASE_URL=https://client-api.searchenginemonks.com`.

## 5. Backend structure (`Backend/src`)

| Path | Role |
|---|---|
| `server.js` | Env validation, middleware chain, health routes, route mounts, 404 JSON, error handler, socket.io attach, graceful shutdown |
| `config/` | `env.js` (startup validation), `originPolicy.js` (CORS), `otpTestConfig.js`, `liveTestOtpConfig.js`, `db.js`, `mailer.js`, `trustProxy.js`, `seedDefaultAdmin.js`, `bootstrapEnv.js` |
| `routes/` | 37 modules (25 consumer, 12 admin) |
| `controllers/` | 41 controllers |
| `services/` | Match engine and compatibility, OTP, payments (`razorpayProvider.js`), push (`firebasePushProvider.js`), AI (`aiMatchProvider.js`, LOCAL only), privacy and consent, admin, platform settings |
| `middleware/` | `authMiddleware` (user JWT), admin auth/MFA/RBAC/origin/audit, `rateLimiter`, validators, `publicMaintenanceMiddleware`, `errorHandler`, metrics |
| `policies/` | Account status and age policy |
| `realtime/realtimeHub.js` | socket.io auth, rooms, events |
| `models/` | 64 Sequelize models |
| `migrations/` | 63 migrations (2026-08-09 to 2026-10-12) plus `run.js` |
| `Backend/scripts/` | Schema verifiers, seeders, admin creation, e2e fixtures |
| `Backend/postman/` | Postman collection |

**Middleware order:** trust proxy, Helmet, CORS, security event, performance metrics,
`express.json` (100 kb; raw body is kept for `/api/payments/webhook`).

**Maintenance mode:** every consumer router is wrapped in `publicMaintenance`, except `/api/auth`,
`/api/app-config`, `/api/privacy` and `/api/admin/v1`.

## 6. Database overview (MySQL)

| Domain | Main tables |
|---|---|
| Identity/auth | `Users`, `OtpTokens`, `RefreshTokens`, `UserDevices`, `UserLoginEvents`, `DeletedUsers` |
| Profile | `OnboardingProfiles` (includes match-location columns), `ProfileTaxonomy*` |
| Discover/match | `DiscoverActions`, `DiscoverFilterPreferences`, `Matches`, `MatchRecommendationEvents`, `SavedProfiles`, `AdminDiscover*` |
| Chat | `Conversations`, `ConversationParticipants`, `Messages`, `MessageMedia` |
| Safety | `Blocks`, `Reports`, `AdminReportCases`, `AdminReportNotes` |
| Notifications | `Notifications`, `NotificationDeliveries`, `NotificationPreferences` |
| Events | `Events`, `EventRegistrations`, `EventWaitlist` |
| Monetization | `SubscriptionPlans`, `Subscriptions`, `Payments`, `PaymentEvents`, `RoseTransactions` |
| KYC | `IdentityVerifications`, `IdentityVerification*` |
| Privacy/DPDP | `LegalDocumentVersions`, `ConsentEvents`, `UserConsents`, `PrivacyRequests*`, `AccountDeletion*`, `PrivacyGrievances` |
| Admin | `Administrators`, `AdminRoles`, `AdminPermissions`, `AdminMfa*`, `AdminAuditLogs`, ... |
| Platform | `PlatformSettings` (`maintenance_mode_enabled`, `registration_enabled`, support email) |

Migrations are explicit: `npm run db:migrate`, `db:migrate:status`, `db:migrate:undo`. The staging
template uses `DB_MIGRATION_STARTUP_MODE=verify`.

## 7. API conventions

- **Envelope:**
  - Success: `{ success: true, message, data }`.
  - Error: `{ success: false, message, code, errors: [] }`.
  - Unknown route: 404 `NOT_FOUND`.
  - `devOtp` is included **only** when `NODE_ENV=development`.
- **Auth:** `Authorization: Bearer <access JWT>`.
  - The access token lasts 15 min and carries `{sub, email, ver}`. Every request checks it against
    `User.tokenVersion` and the account status.
  - **Refresh:** an opaque `selector.secret`, bcrypt-hashed, valid for 30 days. It is **rotated** on
    every `POST /api/auth/refresh-token {refreshToken}`; the old row is deleted.
  - Logout deletes the refresh row. The access JWT stays valid until it expires.
- **Health:** `GET /health`, `/health/live`, `/health/ready` (returns 503 until the DB is ready).
- **Public config:** `GET /api/app-config` returns `maintenanceModeEnabled`, `registrationEnabled` and the support email.
- **Rate limits:** in-memory, keyed by IP plus identity. They reset when PM2 restarts. Examples:
  - login: 5 per 15 min
  - signup: 10 per 15 min per IP
  - OTP resend: 1 per 45 s
  - OTP verify: 5 per 15 min
  - swipe: 120 per 5 min
  - messages: 60 per min
  - reports: 5 per hour
- **Main consumer prefixes:**
  - Auth and onboarding: `/api/auth`, `/api/onboarding`.
  - Discovery and profiles: `/api/discover` (`feed`, `ai-matches`, `swipe`, `rewind`, `filters`),
    `/api/profiles/:id`, `/api/me/*` (`profile`, `preferences`, `location`, `likes`, `saved-profiles`).
  - Relationships and chat: `/api/matches`, `/api/conversations`, `/api/messages`, `/api/roses/send`,
    `/api/blocks`, `/api/reports`.
  - Notifications and devices: `/api/notifications`, `/api/notification-preferences`, `/api/devices`.
  - Monetization: `/api/subscriptions`, `/api/payments` (`orders`, `verify`, `webhook`).
  - Account, KYC and privacy: `/api/identity-verification`, `/api/account/*`, `/api/privacy-requests/*`,
    `/api/privacy` (and `/api/v1/privacy`).
  - Other: `/api/media`, `/api/events`.
- Full endpoint table: `AMORA-AI-QA/discovery/project-architecture.md` §6.

## 8. Auth & OTP flow

1. **Signup** (`POST /api/auth/signup`):
   - Fields: name (at least 2 characters), email (`normalizeEmail`, so Gmail dots and +tags collapse),
     Indian phone, password (at least 8 characters, no complexity rule), `confirmPassword`,
     `acceptedTerms=true`, and versioned legal docs from `GET /api/auth/legal-documents/signup`.
   - Errors:
     - 403 `REGISTRATION_DISABLED`
     - 409 `EMAIL_EXISTS` / `PHONE_EXISTS`. The UI shows "An account with this phone number already exists."
   - The user, consent and OTP rows are created in a transaction. **If OTP delivery fails, the rows
     are deleted**, and the call returns 502 `OTP_PROVIDER_AUTH_ERROR`, 429, 400 `INVALID_PHONE_NUMBER` or 503.
2. **Verify** (`POST /api/auth/verify-account`):
   - The code is 6 digits and expires after 10 min.
   - 5 failed attempts consume the challenge.
   - Resend has a 45 s cooldown.
   - Success marks the user verified and **returns tokens**, so the user is logged in.
3. **Login** is **email and password only** (`POST /api/auth/login`). There is no phone or OTP login.
   - Errors: 401 `INVALID_CREDENTIALS`, 403 `ACCOUNT_NOT_VERIFIED` (the app routes to OTP), and
     403 `ACCOUNT_DEACTIVATED` with a `reactivationToken` (the app routes to reactivation).
4. **Forgot/reset:** an email OTP, then `verify-reset-code` (returns a `recoveryToken` valid for
   10 min), then `reset-password`. **Requires SMTP.**
5. **Change password** (auth required) bumps `tokenVersion` and revokes all refresh tokens.
6. **Google:** `POST /api/auth/google {idToken}` returns 503 `GOOGLE_AUTH_NOT_CONFIGURED` unless `GOOGLE_CLIENT_IDS` is set.
7. **Test OTP modes.** `otpService.verifyOtp` accepts a code if any of three checks passes:
   - **Generic fixed OTP** (`TEST_FIXED_OTP_ENABLED`): allowed in development, test, qa and staging.
     It has **no phone check**.
   - **Restricted live test OTP** (`LIVE_TEST_OTP_*`): staging only. It is limited to an allowlist of
     phones and has an expiry.
   - The real bcrypt-hashed code.

   Production refuses to start if any test-OTP variable is set. A real challenge row is always required.

## 9. WebSocket (socket.io)

- Same host and port, path `/socket.io`. The server allows websocket and polling; the Flutter client
  uses **websocket only**. CORS follows the same policy as HTTP.
- Handshake: `auth.token` or a Bearer header. Admin tokens (`typ=admin_access`) are verified
  separately. Failure gives `AUTHENTICATION_FAILED`.
- Client to server: `conversation.subscribe {conversationId}`, acked with `{success}` or `CONVERSATION_NOT_AVAILABLE`.
- Server to client:
  - Messages: `message.created`, `message.delivered`, `message.read`, `message.deleted`.
  - Conversations: `conversation.updated` (also sent on a new mutual match) and `conversation.severed`
    (block or unmatch).
  - Presence: `presence.updated`.
  - Admin rooms get `admin.*` events.
- The connection registry is in-process. There is no Redis adapter, so it supports a single instance only.

## 10. User roles

- **User:** a consumer account using the JWT and `authMiddleware`. Account states are active,
  unverified, deactivated and deleted.
- **Admin:** a separate auth stack under `/api/admin/v1/*`, with about 165 handlers.
  - It has its own `ADMIN_JWT_SECRET`, MFA, RBAC permissions, origin middleware, audit log and refresh tokens.
  - Created with `npm run admin:create`.
  - **No admin web is deployed for staging**, and staging CORS lists no admin origin.

## 11. Key workflows

1. Signup, phone OTP, 6-step profile onboarding (age 18+, gender, interested-in, goal,
   city and distance, 2-6 photos), "Start discovering", then the Discover tab.
2. Discover: actions are like, pass ("Not Now"), super like and rewind. A mutual like creates a match
   and a conversation and emits a socket event. Filters are saved server-side.
3. AI Matches: `/api/discover/ai-matches` returns a **deterministic LOCAL** score (no LLM).
   Multi-select "Send Likes" is available.
4. Chat: **messaging requires a match.** Supports text, media, read receipts, mute, draft, delete
   and report. Block or unmatch severs the chat in real time.
5. Profile, roses, saved profiles, likes lists, report and block, notifications inbox and preferences.
6. Membership: plans (must be seeded), then a Razorpay order, checkout (mobile SDK) and verify.
7. KYC: Aadhaar plus selfie upload, which creates a **pending** record for manual admin review.
8. Account: logout, deactivate (re-auth), delete (reason, method, OTP, confirm), and DPDP privacy
   requests (`/api/privacy-requests`).

## 12. Implementation status (summary of `implementation-status.md` register)

**Implemented and testable**
- Auth (signup, OTP verify, email login, change password, reactivation).
- Onboarding, profile, Discover, AI Matches (deterministic), chat and realtime.
- Roses, report and block, notifications inbox, account actions and DPDP requests.
- Location and distance filtering (PEND-012), change password (PEND-013).
- Maintenance and registration switches (PEND-026), match-gated messaging as designed (PEND-027).

**Partial**
- KYC is a manual workflow (PEND-009).
- Discover filter gaps: icebreaker, height maximum, Zodiac, gift vs rose (PEND-015).
- Notification quiet hours (PEND-017).
- Profile completion % differs between client and server (PEND-018).
- Rate limiting is not distributed (PEND-021).
- Media is stored on local disk (PEND-022).
- DPDP, legal and retention (PEND-024).
- Safety Center shows "unavailable" cards (PEND-014).

**Pending / not implemented**
- Phone or OTP login from the SRS (PEND-010).
- No support-ticket endpoint (PEND-011).
- No analytics or crash reporting (PEND-025).
- Android identity and signing: package is still `com.example.amora_ai` (PEND-023).
- Admin web not deployed (PEND-019).
- Deployed staging SHA undocumented (PEND-028).
- No external AI provider (PEND-008).

**Needs provider config**
- Twilio SMS (PEND-001)
- SMTP (PEND-003)
- Firebase FCM (PEND-004)
- Razorpay (PEND-005)
- Google Sign-In (PEND-006)

**Disabled**
- **Events:** frontend flag off, backend live (PEND-007). The flag leaks: entry points remain via
  payment success "Explore Events", the membership card `onEvents`, and notification deep links.
- Legacy `/api/privacy/consents*` and `/data-export` return 410 (PEND-016).
- Membership test mode (`AMORA_MEMBERSHIP_TEST`) is off by default.

**Dead code (unregistered or unreachable screens)**
- Unregistered: `/home`, `/ai-coach`, `/date-spots`, `/dating-recap`, `/match`, `/data-export`,
  `/refer-earn`, `/sos-checkin`, `/language-selection`, `/offline-mode`, `/accessibility-settings`,
  and 25 `features/roadmap/*` concept screens.
- Registered but unreachable: `/onboarding`, `/settings`, `/dark-mode-settings`, `/compatibility`,
  `/profile-setup`, `/bio-builder`, `/dealbreakers`, `/liked-you*`.
- The Profile tab "AI Coach" button opens FAQ/Support.

## 13. Known limitations

- Two "Change Password" entries go to different flows: Profile tab goes to forgot-password by email,
  and Profile Settings goes to `/change-password`.
- Dark mode is not effective: the app forces `AmoraTheme.light()` and provides no `darkTheme`.
- Quick filter chips on Discover filter only the list already fetched, on the client.
- Web-only issues:
  - Razorpay has no web plugin, so the payment screen likely hangs.
  - The KYC selfie is camera-only and blocked.
  - Location is unavailable.
  - FCM is disabled.
  - Google sign-in has no `client_id` meta.
  - Tokens are kept in localStorage via secure storage, which needs HTTPS or localhost.
  - Refresh resets to splash, except for the two direct hash routes.
- Firebase config files are absent (`google-services.json` and `firebase_options.dart`), but
  `Firebase.initializeApp()` is still called. Check that the app degrades gracefully.
- Rate limits are per process and reset on restart. Testers behind a shared NAT can trip them sooner.

## 14. Environment setup & how to run

**Backend** (in `Backend/`):
```bash
npm install
npm run db:migrate          # explicit; also db:migrate:status / db:migrate:undo
npm run dev                 # nodemon src/server.js  (npm start = node src/server.js)
```
- Local quickstart in `Backend/README.md` assumes XAMPP MySQL at `localhost:3306`. A Docker MySQL
  alternative is also documented there.
- Copy `Backend/.env.example` to `Backend/.env` (git-ignored) and fill in the values, which are supplied separately.
- Startup requires `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `JWT_SECRET`, `JWT_REFRESH_SECRET` and `ADMIN_JWT_SECRET`.
- Seed membership plans with `npm run db:seed:subscriptions`. Create an admin with `npm run admin:create`.
- Staging deploy: `Backend/deploy/client-staging/` and `docs/client-release/STAGING_DEPLOYMENT_RUNBOOK.md`.
  The script pins a SHA, runs `npm ci --omit=dev` and `db:migrate`, then PM2 reload.

**Flutter:**
```bash
flutter run --dart-define=AMORA_API_BASE_URL=https://<api-host>
flutter build apk --release --dart-define=AMORA_API_BASE_URL=https://<api-host>
flutter analyze && flutter test
```
- **Do not run `flutter pub get` in the repo root on this machine.** The newer local Flutter SDK
  rewrites `pubspec.lock` and `analysis_options.yaml`. Use an isolated copy instead (as in `AMORA-AI-QA/webbuild/src`).
- **Web build caveats:**
  - Windows plugin builds need symlink support (Developer Mode). QA therefore built web from an
    isolated copy, in profile mode with `--dart-define=AMORA_API_BASE_URL`.
  - Staging CORS allows only its own origin, so a localhost web build cannot call staging directly.
    QA serves the build through the same-origin proxy `AMORA-AI-QA/tools/qa-proxy.js`
    (`node qa-proxy.js <webRoot> [port] [logFile]`, default port 8787). The proxy forwards
    `/api/`, `/socket.io/` and `/health` and strips `Origin`.

**Client staging:**
- API host: `https://client-api.searchenginemonks.com`. Production is a separate host running older code.
- Live checks on 2026-11-16:
  - `/health` is healthy.
  - `/api/app-config` shows registration enabled and maintenance off.
  - Fixed OTP `111111` verified a **non-allowlisted** test phone. Staging is therefore running the
    **generic fixed-OTP test mode**, not the documented allowlist-only mode. Treat this as a security
    finding for staging, not a production concern.
  - A duplicate phone at signup is rejected.
  - The login limiter (5 per 15 min per identity) returns 429.
- Not documented in the repo: the deployed SHA and the server `.env`.

## 15. Configuration (env var NAMES only — never values)

| Group | Names |
|---|---|
| Runtime | `PORT`, `NODE_ENV`, `TRUST_PROXY_HOPS`, `SHUTDOWN_TIMEOUT_MS` |
| DB | `DB_HOST`, `DB_PORT`, `DB_NAME`, `TEST_DB_NAME`, `DB_USER`, `DB_PASS`, `DB_SSL_CA_FILE`, `DB_POOL_*`, `DB_QUERY_TIMEOUT_MS`, `DB_MIGRATION_STARTUP_MODE` |
| Secrets | `JWT_SECRET`, `JWT_REFRESH_SECRET`, `ADMIN_JWT_SECRET`, `ADMIN_MFA_ENCRYPTION_KEY`, `CURSOR_ENCRYPTION_SECRET`, `CURSOR_ENCRYPTION_KID`, `CURSOR_PREVIOUS_SECRETS` |
| Admin | `ADMIN_ACCESS_TOKEN_TTL_MINUTES`, `ADMIN_REFRESH_TOKEN_TTL_DAYS`, `ADMIN_PASSWORD_RESET_TTL_MINUTES`, `ADMIN_MFA_CHALLENGE_TTL_MINUTES`, `ADMIN_MFA_STEP_UP_TTL_MINUTES`, `ADMIN_WEB_RESET_URL`, `ADMIN_WEB_INVITATION_URL` |
| Test OTP | `TEST_FIXED_OTP_ENABLED`, `TEST_FIXED_OTP`, `TEST_OTP_SKIP_DELIVERY`, `LIVE_TEST_OTP_ENABLED`, `LIVE_TEST_OTP_VALUE`, `LIVE_TEST_OTP_PHONE_ALLOWLIST`, `LIVE_TEST_OTP_EXPIRES_AT` |
| Seeding | `ALLOW_DUMMY_SEED`, `DUMMY_SEED_DATABASES`, `SEED_*`, `DEV_ADMIN_SEED_*`, `MEMBERSHIP_TEST_PASSWORD`, `FULL_FLOW_TEST_PASSWORD` |
| Providers | `SMS_PROVIDER`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`, `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_FROM`, `GOOGLE_CLIENT_IDS`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `RAZORPAY_API_BASE_URL` |
| Storage/privacy | `AMORA_PRIVATE_UPLOAD_ROOT`, `AMORA_PRIVATE_EXPORT_ROOT`, `PRIVACY_EXPORT_TTL_MINUTES` |
| Perf/CORS | `CORS_ORIGIN` (comma list, exact match; production rejects `*` and http), `REQUIRE_DISTRIBUTED_RATE_LIMIT`, `ENABLE_PERFORMANCE_METRICS`, `AI_DISCOVERY_CANDIDATE_WINDOW` |
| Flutter dart-defines | `AMORA_API_BASE_URL` (HTTPS required in release), `AMORA_MEMBERSHIP_TEST` |

## 16. External dependencies (behaviour when unconfigured)

| Service | Code | Unconfigured result |
|---|---|---|
| Twilio SMS | `utils/sendSms.js` | `OTP_CONFIG_ERROR`, then signup is rolled back with 502 `OTP_PROVIDER_AUTH_ERROR` (unless test-OTP skip-delivery is on) |
| SMTP (Nodemailer) | `config/mailer.js`, `utils/sendEmail.js` | Forgot-password returns 503 `OTP_DELIVERY_FAILED`. SMTP is mandatory in production |
| Firebase FCM v1 | `services/firebasePushProvider.js` | Delivery is marked `credentials_required`. The in-app notification is still stored |
| Razorpay | `services/razorpayProvider.js` | 503 `PAYMENT_PROVIDER_NOT_CONFIGURED`. The webhook needs its secret |
| Google OAuth | `authController.js` | 503 `GOOGLE_AUTH_NOT_CONFIGURED` |
| AI | `services/aiMatchProvider.js` | Always `LOCAL` and deterministic, by design |

## 17. Existing tests

- **Backend:** `cd Backend && npm test`, which runs `node --test --test-concurrency=1` over 66 files in `Backend/test/`.
  - Needs a MySQL test DB (`TEST_DB_NAME`). The integration suites refuse to run against `DB_NAME`.
  - Subsets: `test:integration`, `test:r1-security`, `test:admin`, `test:send-rose`,
    `test:mutual-like-chat`, `test:phase3`/`4`/`5`, `test:profile`, `test:relationships`,
    `test:notifications-preferences`.
  - Last recorded result: 386/386 (2026-10-24, `CLIENT_QA_RELEASE_REPORT.md`). Not re-run in this session.
- **Flutter:** `flutter test`, covering 86 `*_test.dart` files in `test/`.
  - Last recorded result: 659 passed and 14 skipped, with `flutter analyze` clean (`CLIENT_QA_MISSION_STATUS.md`). Not re-run.
- Other: the Postman collection (`Backend/postman/`) and `verify:*` / `db:verify:*` scripts.
- QA harness (untracked): `AMORA-AI-QA/tools/`.
  - `qa_browser.py`: Playwright with a single system-Chrome instance and Flutter semantics enabled.
  - `api.py`: an API probe that never prints tokens.
  - `qa-proxy.js`
- QA plan: `AMORA-AI-QA/discovery/testing-plan.md`.

## 18. Important development notes

- **Never commit `.env`** or any secret. The root and `Backend/` `.gitignore` already exclude `.env*`
  and keep `*.env.example`. Never copy server values into docs or logs.
- **Demo and dummy seeding is guarded.** The seed commands refuse to run unless all of these hold:
  - `NODE_ENV` is development, test, qa or staging (never production);
  - `ALLOW_DUMMY_SEED=true`;
  - `DB_NAME` is in `DUMMY_SEED_DATABASES`;
  - the command includes `--confirm-development-db`.
- Seed commands: `db:seed:dummy`, `db:seed:demo-walkthrough` (with `:reset` / `:validate`), `seed:demo`.
- Demo and QA account credentials are supplied separately. Never hard-code them.
- **Events flag:** `lib/core/config/app_feature_flags.dart` sets `eventsEnabled = false`. Do not
  re-enable it without a product decision. Watch for the unguarded entry points (§12).
- **Dead code:** many screens under `lib/features/roadmap/` and related folders are unregistered.
  Pushing an unknown route falls back to the Browse grid. Do not assume a screen file is live; check
  `lib/main.dart` routes first.
- The SRS gap audit (`docs/AMORAA_SRS_VS_ACTUAL_APP_AUDIT.md`, 2026-09-24) is stale in places.
- **Doc drift:**
  - Location filtering and change-password **are** implemented, despite older docs.
  - `server.js` has no static `/uploads` mount; media is served through authenticated `/api/media/...`.
- Do not run `flutter pub get` in place (§14). Do not touch the root `*.zip`, `node_modules/` or `tmp/`.
- Mobile clients send no `Origin` header, so CORS does not affect the native app. Only browsers are affected.
- No APK named "AMORA AI.apk" was found in the workspace (2026-11-16), so Android device testing has not been done.
