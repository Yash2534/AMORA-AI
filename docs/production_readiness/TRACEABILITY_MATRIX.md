# AMORA production-readiness traceability matrix

Source baseline: `AMORA_SRS_COMPLETE_AUDIT_REPORT.docx` (11 August 2026), checked against repository `main` at `5b8b6599` before implementation changes. Runtime results are intentionally marked pending until the baseline commands complete.

| Audit issue | SRS requirement | Frontend evidence | API contract | Backend evidence | Database evidence | Existing tests | Current status before remediation |
|---|---|---|---|---|---|---|---|
| P0 Identity/KYC is UI-only | Module 19: Aadhaar, selfie, processing, reviewed verification | `lib/features/profile/presentation/kyc_verification_screen.dart`; profile/completion entry points | No KYC route registered | No KYC controller, storage service, or review service | No verification submission/document/review model or migration; `Users.isVerified` currently also represents account OTP verification | UI-only identity tests; no KYC API integration test | **OPEN / BLOCKING.** The screen accepts an injected submitter but the production route supplies none. There is no authoritative KYC lifecycle. |
| P0 Discover boost contract failure | Module 3: paid/premium Discover action must persist and be retry-safe | `lib/features/discover/data/discover_api_service.dart`; `profile_boost_screen.dart` | `POST /api/discover/boost`, `Idempotency-Key` header | `discoverController.boost` validates the key, locks the user, consumes one entitlement, and reuses the keyed activation | `Boosts(userId,idempotencyKey)` unique index and `BoostEntitlements` | `test/discover_api_service_boost_test.dart`; `test/profile_boost_screen_test.dart`; `Backend/test/phase5.integration.test.js` | **CODE ADDRESSED; RUNTIME PENDING.** Flutter now sends the header and the backend retains idempotency. |
| P1 Presence-dependent Discover/chat status lacked authority | Modules 4 and 5: Online Now / Active Now / truthful chat presence | chat repository consumes `participant.online` and `presence.updated`; Discover filter sends `onlineNow` | authenticated APIs update activity; realtime token/socket connection | `authMiddleware` throttles `lastActiveAt` updates; `realtimeHub` tracks active sockets and emits membership-scoped presence; Discover uses a configurable activity window; conversation summaries use live socket state | `Users.lastActiveAt` plus index | `Backend/test/partial-integrations.integration.test.js`; Discover and phase-3 chat tests | **PARTIAL.** Core server authority now exists, but public profile `status` is still null, last-seen semantics are not exposed, and disconnect/presence behavior still needs runtime coverage. |
| P1 Event-interest Discover filter had no truth source | Module 4: event-interest filter must reflect actual event activity | `advanced_filters_screen.dart`; Discover API filter model | `GET /api/discover/feed?hasEventInterest=true` | Discover query checks active registration/waitlist rows | `EventRegistrations`, `EventWaitlist` | `Backend/test/partial-integrations.integration.test.js` | **CODE ADDRESSED; RUNTIME PENDING.** No fabricated boolean is used by the query. |
| P1 Compatibility and “Why we matched” were local/heuristic | Modules 6 and 13: compatibility score, recommendation, and explainable rationale | `matches_screen.dart`; `profile_detail_screen.dart`; `why_we_matched_screen.dart` | Match list/detail and public-profile responses contain only a scalar score | Deterministic score exists in `computeCompatibilityScore.js`; no factor/reason service or authoritative explanation endpoint/response | No factor snapshot or explanation fields (persistence may not be necessary if deterministic and versioned) | score/filter tests only | **OPEN / HIGH.** `why_we_matched_screen.dart` still contains hard-coded percentages and an unsupported “AI summary.” |
| P1 Notification producer/delivery lifecycle missing | Module 14: notification inbox plus category/channel preferences and delivery | notification inbox/preferences repositories and screens | inbox/read/delete and preference endpoints exist | notification CRUD controllers exist; no business-action producer, device-token registration, delivery service, or push adapter was found | `Notifications`, `NotificationPreferences`; no device-token/delivery-event table | `Backend/test/notifications-preferences.integration.test.js`; Flutter inbox/preference tests | **OPEN / HIGH.** Inbox persistence is real, but business actions do not create notifications and push delivery cannot be operated. |
| P1 Profile prompt reply action missing | Module 13: reply to a visible profile prompt | `profile_detail_screen.dart` opens/creates a real conversation with `ChatMessageContext.profilePrompt`; chat composer sends it | existing `POST /api/conversations` and `POST /api/conversations/:id/messages` | normal conversation authorization and message persistence are reused; message context is stored with the message | `Messages.context` | `test/profile_detail_interactions_test.dart`; phase-3 message tests | **CODE ADDRESSED; RUNTIME PENDING.** A separate prompt-reply table/API is unnecessary because the SRS action naturally creates a contextual chat message. Backend context-shape validation needs hardening. |
| P1/P2 Chat mute is UI-only | Module 5: mute/unmute per conversation | chat menu currently displays success locally | No mute endpoint | No mute controller behavior or notification suppression | `ConversationParticipants` has no mute fields | none | **OPEN.** The UI currently makes a false persistence claim. |
| P2 Duplicate own-profile endpoint families | Modules 8–12/25: one authoritative own-profile contract | `local_profile_repository.dart` uses `/api/me/profile` | both `GET/PUT /api/profiles/me` and `GET/PUT /api/me/profile` remain | both route families call the same controller methods (business logic is shared) | same `Users` and `OnboardingProfiles` rows | `Backend/test/own-profile.integration.test.js`; partial-integration tests still exercise legacy route | **PARTIAL.** Contract drift is reduced by shared handlers, but the legacy family is still undocumented and not explicitly deprecated. |
| P2 Password-reset identifier differs from SRS | Module 27 says registered email | forgot/reset screens and `AuthService` use phone | `/api/auth/forgot-password`, `/verify-reset-code`, `/reset-password` require `phoneNumber` | OTP hashing, expiry/attempt handling, and recovery-token flow are phone-based | `OtpTokens` keyed by phone purpose | auth integration tests | **PRODUCT DECISION REQUIRED.** The implementation is internally consistent, but changing to email without owner confirmation would violate the master prompt. |
| P2 Runtime mock/local data remains | Functional SRS screens must use server-authoritative user/event/chat data | `amora_home_screen.dart` directly uses `ImageRepository.profiles`; event dummy catalog and admin/social-proof fixtures remain; test-only chat fixtures are gated | real Discover/chat/event/profile APIs exist | production APIs are available | real domain tables exist | production-release acceptance and many repository tests | **OPEN / MEDIUM.** Home still renders static people in a user-facing production path; legitimate test fixtures/static editorial content must be separated from runtime data. |
| P3 Extra scope (wallet, boosts, hosting, rich profile surface) | Change control; do not remove working extras | extra screens are present | wallet/boost/host/gift routes | transactional services/controllers exist | commerce/host tables | phase 4/5 integration tests | **REVIEW.** Preserve working features; verify security and provider readiness rather than deleting them. |

## Cross-layer module map

The 30-module audit matrix in the source report remains the authoritative module list. The remediation order is: KYC and boost verification (P0), then compatibility/notifications/presence/prompt-reply/mute (P1), then profile-contract/mock cleanup and the password-reset product decision (P2), then extra-scope change control (P3).

## Baseline gates still to run

1. Backend unit/integration suite against the configured test database.
2. Migration status and clean-schema migration where an isolated MySQL database is available.
3. `flutter analyze` and the complete Flutter test suite.
4. Android release and web release builds with an explicit production API URL.
5. Live Google/SMS/email/push/payment/media-provider checks only when safe credentials are present.

No code issue is marked runtime-passed in this matrix until those commands and post-mutation database assertions complete.

## Post-remediation disposition — 12 August 2026

This section supersedes the baseline-status column above while preserving the original audit trail.

| Audit issue | Final evidence | Disposition |
|---|---|---|
| Identity/KYC | Private signature-validated storage; owner status; admin queue/document/review APIs; authoritative `identityVerifiedAt`; migration `202608180001`; two integration tests | **CODE AND LOCAL RUNTIME PASSED.** Live identity-provider/manual-review operations remain an external deployment requirement. |
| Discover boost/idempotency | Header enforced in Flutter/backend; entitlement locking and unique key; E2E reject/retry checks | **PASSED.** |
| Presence and event-interest | `lastActiveAt`, scoped realtime presence, and event registration/waitlist queries | **PARTIAL.** Discover/chat authority passes; public-profile last-seen semantics and live disconnect tests remain. |
| Compatibility/Why matched | Versioned deterministic compatibility response with factual reasons/disclaimer; hard-coded AI claims removed | **PASSED LOCALLY.** No generative-AI claim remains. |
| Notification lifecycle | Business producers, preference evaluation, device registration, delivery rows, FCM adapter, mute suppression | **CODE PASSED / CREDENTIALS REQUIRED.** FCM credentials and Flutter push-token integration are not configured. |
| Prompt replies | Contextual messages persist through the existing authorized conversation/message contract | **PASSED FOR CURRENT CONTRACT.** Additional context-schema hardening remains desirable. |
| Chat mute | Per-participant fields, PUT/DELETE endpoints, persisted Flutter action, delivery suppression | **PASSED.** |
| Own-profile duplication | `/api/me/profile` is canonical; legacy family shares handlers and emits `Deprecation`, `Sunset`, and successor `Link` headers | **MIGRATION PATH ACTIVE.** Legacy removal is scheduled, not yet performed. |
| Password reset identifier | Registered-email UI/API, hashed expiring OTP, cooldown, attempt cap, refresh-token revocation, single-use recovery token | **PASSED.** |
| Runtime mock/local data | Production repositories fail honestly without server data; QA seed is explicitly development-only; dead demo home is not registered | **ACTIVE RUNTIME PASSED.** Dead fixture code can still be removed as cleanup. |

## Executed release evidence

- Backend: 76/76 tests passed.
- Deterministic development E2E: 82/82 HTTP/database checks passed with 15 personas and 15 KYC records.
- Migrations: all 18 applied to the configured development schema and to a newly created empty verification schema; the temporary schema was removed.
- Flutter static analysis: no issues.
- Flutter tests: 525 passed, 14 intentionally skipped, 6 failed in the final aggregate run. The suite is therefore **not green**.
- Android release APK and standard web release build compiled using a non-live HTTPS placeholder API URL.
- Live email, SMS, Google OAuth, Razorpay, and Firebase push credentials are missing, so provider E2E was not attempted.

Overall verdict: **NOT YET 100% PRODUCTION READY.**
