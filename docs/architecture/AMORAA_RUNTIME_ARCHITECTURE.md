# AMORAA high-level runtime architecture

This document describes the runtime architecture evidenced by repository source at commit `3eece809667c4f62247b9cd055e94e965d2d4b7c`. It intentionally excludes demo data, seed scripts, test fixtures, and implementation-level controller/model expansion.

The interactive Archify diagram is [AMORAA_RUNTIME_ARCHITECTURE.html](./AMORAA_RUNTIME_ARCHITECTURE.html). Its checked source candidate is [amoraa-runtime.architecture.json](./amoraa-runtime.architecture.json).

## Executive view

The primary confirmed runtime path is:

`Flutter Mobile App -> Authentication / Session -> Node.js / Express API -> Discover Eligibility -> Match Engine / LOCAL AI Ranking -> MySQL -> ranked profiles returned to Flutter through the API response`

The “LOCAL AI” label is literal repository behavior, not a claim that a hosted model is involved. `rankCandidates` is an in-process deterministic ranker layered over the compatibility score. No network call to an AI provider occurs in the discover ranking path.

## Trust boundaries

- **User device / Flutter:** UI, API clients, secure access/refresh-token storage, Google client sign-in, Firebase Messaging client, and Razorpay checkout SDK.
- **Public HTTPS API:** the deployment-facing Express interface. The repository requires an absolute `AMORA_API_BASE_URL` in Flutter release mode but does not contain a production URL.
- **Trusted backend environment:** authenticated Express handlers, eligibility/ranking logic, account lifecycle, notification orchestration, and the in-process Socket.IO hub.
- **MySQL / private persistence:** Sequelize-backed authoritative state for users, profiles, preferences, actions, matches, conversations, messages, notifications, devices, OTPs, sessions, payments, and deletion archives.
- **Third-party services:** Google OAuth, Firebase/FCM, Twilio SMS, SMTP, and Razorpay. Code paths exist, but the tracked configuration defaults are disabled or blank.

## Confirmed runtime behavior

### Authentication and session

- Flutter `AuthService.initialize` reads access and refresh tokens from secure credential storage; `_performRefresh` rotates them through `/api/auth/refresh-token` (`lib/core/auth/auth_service.dart`, `AuthService.initialize`, lines 182-199; `AuthService._performRefresh`, lines 648-668).
- The API authentication middleware verifies the JWT with `JWT_SECRET`, loads the user, checks `tokenVersion`, rejects deleted/deactivated accounts, and records recent activity (`Backend/src/middleware/authMiddleware.js`, `authenticationMiddleware`, lines 4-30).
- The backend issues persisted refresh sessions and rotates a used refresh token inside a transaction (`Backend/src/controllers/authController.js`, `refreshToken`, lines 411-445; `Backend/src/utils/generateTokens.js`, `issueTokens`).
- Google sign-in exists on both clients and server, but the tracked default `GOOGLE_CLIENT_IDS=skip-for-now` makes the server path return `GOOGLE_AUTH_NOT_CONFIGURED` (`lib/core/auth/auth_service.dart`, `AuthService.googleSignIn`, lines 330-357; `Backend/src/controllers/authController.js`, `google`, lines 251-275; `Backend/.env.example`, lines 65-66).

### Profile and onboarding

- Authenticated onboarding routes persist age, gender, interested-in preferences, relationship goals, location, starter profile, completion fields, and photos (`Backend/src/routes/onboardingRoutes.js`, route registrations, lines 7-18; `Backend/src/controllers/onboardingController.js`, onboarding handlers, lines 10-24).
- Completion validates required profile fields before setting `onboardingCompleted=true` and `stage='complete'` (`Backend/src/controllers/onboardingController.js`, `complete`, line 24; `Backend/src/services/discoverEligibilityPolicy.js`, `profileCompletionErrors`/`isDiscoverComplete`, lines 133-149).
- Own-profile reads and updates are exposed separately from public profile serialization (`Backend/src/controllers/profileController.js`, `getOwnProfile`/`updateOwnProfile`, lines 52-119).

### Discover eligibility

- `/api/discover/feed` and `/api/discover/ai-matches` are JWT-protected (`Backend/src/routes/discoverRoutes.js`, router middleware and feed routes, lines 15-19).
- The viewer must have a complete onboarding profile (`Backend/src/controllers/discoverController.js`, `requireCompleted`, lines 53-60; `getFeed`, lines 238-239).
- Candidate selection excludes self, previous excluding actions, existing matches, blocked relationships, and non-active accounts; optional verified, online, event-interest, distance, and saved preference filters are applied (`Backend/src/controllers/discoverController.js`, `getFeed`, lines 246-354).
- Reciprocal eligibility is implemented in SQL, including candidate preference constraints for viewer age and distance (`Backend/src/services/discoverEligibilityPolicy.js`, `reciprocalEligibilitySqlClauses`, lines 101-131; `reciprocalPreferenceClauses`, lines 191-213).

### Match ranking

- Normal discover calculates SQL compatibility expressions, filters by minimum score, and orders candidates by score (or distance then score for “near you”) (`Backend/src/controllers/discoverController.js`, `getFeed`, lines 270-398).
- Compatibility uses weighted interests, relationship goals, communication style, languages, city, smoking, drinking, and weed preferences (`Backend/src/services/compatibilityScoringService.js`, `MATCH_FACTORS`, lines 3-14; `scoreCompatibility`, lines 81-128).
- The AI Matches surface ranks the entire eligible set before pagination and returns `provider: 'LOCAL'` (`Backend/src/controllers/discoverController.js`, `getFeed`, lines 393-485).
- `localAiMatch` derives score, confidence, highlights, and reasons from already calculated compatibility evidence; `rankCandidates` sorts deterministically (`Backend/src/services/aiMatchProvider.js`, `localAiMatch`/`rankCandidates`, lines 38-65).

### Like to match to conversation

- A swipe upserts `DiscoverAction`. For like/super-like, the backend looks for a reciprocal action inside a transaction (`Backend/src/controllers/discoverController.js`, `swipe`, lines 545-582).
- A reciprocal like creates or finds a canonical `Match` and ensures a direct `Conversation` in the same transaction (`Backend/src/controllers/discoverController.js`, `swipe`, lines 583-592).
- A separate conversation creation request is allowed only when the target is eligible, neither user has blocked the other, and an active match exists (`Backend/src/controllers/conversationController.js`, `create`, lines 99-134).

### Chat and realtime messaging

- Sending a message validates conversation access, persists `Message`, updates the conversation’s last-message fields, then emits `message.created` and `conversation.updated` (`Backend/src/controllers/messageController.js`, `send`, lines 134-161).
- Read/delivery status is persisted and emitted as realtime events (`Backend/src/controllers/messageController.js`, `history`/`read`, lines 48-118 and 167-192).
- Socket.IO is attached to the same HTTP server, accepts WebSocket or polling transports, verifies JWTs and token versions, maintains in-process connection counts, and emits presence (`Backend/src/server.js`, `createHttpServer`, lines 129-132; `Backend/src/realtime/realtimeHub.js`, `attachRealtimeServer`, lines 76-160).
- Flutter connects over WebSocket and listens for messages, conversation updates, presence, notifications, likes, super-likes, and matches (`lib/features/chat/data/chat_repository.dart`, `_connectRealtime`, lines 677-719).

### Notifications and push

- In-app notifications are authoritative database records governed by category preferences and conversation mute state (`Backend/src/services/notificationService.js`, `createNotification`, lines 63-82).
- Push delivery is attempted after commit for active registered devices. If Firebase credentials are absent, delivery is explicitly marked `credentials_required` (`Backend/src/services/notificationService.js`, `deliverPush`, lines 26-60).
- Server-side FCM uses Firebase HTTP v1 with a service-account access token only when all three required environment values exist (`Backend/src/services/firebasePushProvider.js`, `configuration`/`send`, lines 3-44).
- Flutter initializes Firebase Messaging but deliberately tolerates absent native Firebase configuration (`lib/features/notifications/data/push_notification_service.dart`, `PushNotificationService.initialize`, lines 163-193).

### Account lifecycle

- Local-password accounts can deactivate after password re-authentication. Deactivation changes status, increments `tokenVersion`, and removes refresh tokens and devices (`Backend/src/controllers/accountController.js`, `deactivate`, lines 56-86).
- Login to a deactivated local or Google account returns a signed, ten-minute reactivation challenge. Successful reactivation locks the user, restores `active`, increments `tokenVersion`, and issues a new session (`Backend/src/controllers/authController.js`, `reactivationChallenge`/`deactivatedResponse`, lines 21-39; `reactivate`, lines 277-305).
- Account deletion requires a verified email or phone channel and a purpose-bound OTP (`Backend/src/controllers/accountController.js`, `sendDeletionOtp`/`confirmDeletion`, lines 108-205).
- Deletion creates a minimal `DeletedUsers` archive, deletes profile/relationship/session/device data, scrubs message content and media, anonymizes the remaining `User`, and invalidates tokens (`Backend/src/services/immediateAccountDeletionService.js`, `ImmediateAccountDeletionService.execute`, lines 11-132; `Backend/src/models/DeletedUser.js`, model definition, lines 3-18).

### OTP behavior

- OTP codes are generated, bcrypt-hashed, and stored in `OtpToken`; creating a new OTP consumes previous unconsumed OTPs for the same identifier and purpose (`Backend/src/services/otpService.js`, `createOtp`, lines 43-75).
- OTPs expire after ten minutes, allow at most five attempts, and are consumed on success (`Backend/src/services/otpService.js`, constants and `verifyOtp`, lines 10-11 and 86-139).
- Phone OTP delivery calls SMS; email OTP delivery handles password reset and account deletion (`Backend/src/services/otpService.js`, `deliverPhoneOtp`/`deliverEmailOtp`, lines 13-40).
- In development only, missing SMS/SMTP configuration causes the OTP to be logged; outside development it fails (`Backend/src/utils/sendSms.js`, `sendSms`, lines 1-15; `Backend/src/utils/sendEmail.js`, `sendEmail`, lines 2-12).

## External integration state from tracked source/config

- **Google OAuth — implemented, disabled by repository default.** Client code obtains an ID token and backend code verifies its audience, but `GOOGLE_CLIENT_IDS=skip-for-now` disables the server verifier (`lib/core/auth/auth_service.dart`, `googleSignIn`; `Backend/src/controllers/authController.js`, `google`; `Backend/.env.example`, lines 65-66).
- **Firebase / FCM — implemented, unconfigured by repository defaults.** Server delivery requires `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY`; the example leaves all blank (`Backend/src/services/firebasePushProvider.js`, `configuration`; `Backend/.env.example`, lines 68-73). Flutter startup tolerates missing native configuration (`lib/features/notifications/data/push_notification_service.dart`, `initialize`).
- **SMS provider — Twilio implemented, unconfigured by repository default.** All provider and credential fields are blank. Non-Twilio configured values are rejected (`Backend/src/utils/sendSms.js`, `sendSms`; `Backend/.env.example`, lines 59-63).
- **SMTP/email — implemented, optional and unconfigured by repository default.** Production logs a warning when host/user/password are absent; email-dependent operations fail their delivery step (`Backend/src/config/env.js`, `validateEnvironment`, lines 52-72; `Backend/src/config/mailer.js`, `getTransport`; `Backend/.env.example`, lines 53-57).
- **Payment provider — Razorpay implemented, unconfigured by repository default.** Order creation, checkout signature validation, payment fetch, webhook validation, and subscription activation are present, but credential fields are blank (`Backend/src/services/razorpayProvider.js`, `providerRequest`/`razorpay`, lines 15-53; `Backend/src/services/paymentService.js`, `createPaymentOrder`/`verifyPayment`/`processWebhook`; `Backend/.env.example`, lines 79-85).
- **Other third-party runtime dependencies — none confirmed for the requested core path.** Device geolocation, image selection, sharing, and URL launching are client/platform capabilities rather than separately deployed providers in the inspected path.

The real deployed activation state cannot be proved from committed source alone because runtime secrets are intentionally excluded. This analysis did not inspect or modify `Backend/.env`; labels therefore describe tracked defaults and code gating, not the state of an unknown deployment.

## Inferred architecture

- **HTTPS termination is inferred as deployment infrastructure, not implemented in this repository.** Express enables production HSTS and the Flutter release build expects an absolute API URL, but no reverse proxy, load balancer, container deployment, or TLS certificate configuration is committed (`Backend/src/server.js`, Express security setup, lines 42-58; `lib/core/config/amora_api_config.dart`, `AmoraApiConfig.baseUrl`, lines 12-38).
- **The backend is effectively a modular monolith.** REST handlers, ranking, Socket.IO, notification orchestration, and account lifecycle share one Node process and one Sequelize model graph (`Backend/src/server.js`, route registration and `createHttpServer`; `Backend/src/models/index.js`, `initModels`). This is a structural inference from composition, not an explicit deployment declaration.
- **MySQL is expected to be private.** The code connects directly through `DB_HOST`/`DB_PORT`, and no public database interface is exposed. Network isolation itself is not configured in this repository (`Backend/src/config/db.js`, `initializeDatabase`, lines 23-38).
- **Socket.IO presence is instance-local.** Connection counts live in an in-memory `Map`, and no Redis adapter/message bus is configured (`Backend/src/realtime/realtimeHub.js`, module state and `attachRealtimeServer`, lines 9-14 and 76-160). Horizontal scaling would therefore require additional coordination not present in source.

## Production configuration gaps and risks

- A Flutter release build throws unless `AMORA_API_BASE_URL` is supplied; the repository contains only development localhost fallbacks (`lib/core/config/amora_api_config.dart`, `AmoraApiConfig.baseUrl`, lines 12-38).
- The tracked configuration leaves Google OAuth, Firebase server push, Twilio, SMTP, and Razorpay credentials disabled or blank (`Backend/.env.example`, lines 53-85).
- The source does not contain deployment manifests, TLS termination, a reverse proxy, secret-manager wiring, or a production API hostname. Their existence cannot be confirmed from source.
- Database startup checks `SequelizeMeta` and auto-applies pending migrations (`Backend/src/config/db.js`, `assertMigrationsApplied`, lines 4-20; `initializeDatabase`, lines 23-38). This is runtime behavior and an operational risk. No migrations were run during this analysis.
- Realtime presence is not shared across backend instances (`Backend/src/realtime/realtimeHub.js`, `connections` and `isUserOnline`, lines 9-14).
- Local profile photo, identity, and chat media storage is process-filesystem based. The code exposes `/uploads` and deletion cleanup touches local paths, but no external object store/CDN is configured (`Backend/src/server.js`, static uploads, lines 62-69; `Backend/src/services/immediateAccountDeletionService.js`, `execute`, lines 20-31; `Backend/src/controllers/accountController.js`, `confirmDeletion`, lines 191-197).

## Development, demo, and test tooling (not production runtime components)

- `Backend/package.json` contains integration tests, verification commands, schema checks, demo walkthrough setup, portrait generation, and dummy seed commands. These are operational/development scripts, not server route registrations.
- `Backend/demo-assets`, `Backend/uploads/e2e-test`, `Backend/tmp`, and the Flutter dummy/event data files are excluded from the runtime component model.
- The `membership_test_flow.dart` payment simulation is explicitly testing-oriented and is not represented as the payment runtime (`lib/features/subscription/presentation/testing/membership_test_flow.dart`).
- Fixed/test OTP behavior is gated by explicit test configuration and defaults to disabled (`Backend/.env.example`, lines 5-16; `Backend/src/config/otpTestConfig.js`, `resolveOtpTestConfig`; `Backend/src/config/liveTestOtpConfig.js`, `resolveLiveTestOtpConfig`).

## Scope and method

Only repository source, tracked configuration examples, manifests, route registration, call sites, models, and runtime adapters were used. Existing prose reports and generated audit artifacts were not treated as evidence. The worktree was clean when analysis began. No application source, `.env`, migration, database, or seed operation was modified or executed.
