# AMORAA end-to-end internal-flow audit

Audit date: 12 August 2026  
Application database: `amora_ai`  
Excluded scope: external third-party provider integration and credential provisioning

## Executive verdict

All active, internally implemented product flows pass their Flutter, HTTP API, authentication/business-logic, MySQL persistence, response-model, UI-state, restart-persistence, and user-isolation checks after the fixes in this audit. No active internal module remains in `FAIL` state.

External SMS/email delivery, Google OAuth, Razorpay checkout, Firebase push delivery, and final identity review remain `THIRD-PARTY BLOCKED`. Their surrounding internal validation, persistence, failure reporting, and status flows were still audited. No provider-dependent feature was marked internally broken merely because credentials or a provider are absent.

The audit used three real temporary development accounts created through the public signup and OTP-verification APIs against `amora_ai`. It stopped and restarted the backend HTTP listener, logged the accounts back in, and reloaded profile, preferences, saved profiles, matches, messages/read receipts, event registrations, notifications, device state, and roses before exact cleanup. The script removed only its own rows/files; a post-run check found zero audit-account/event leftovers and zero checked orphan rows.

## Module disposition

| Module | Status | Root cause / remaining boundary | APIs and database evidence | Test evidence |
|---|---|---|---|---|
| Signup / password login | PASS | No remaining internal defect. Duplicate email/phone, unverified login, invalid credentials, and validation errors are explicit. | `POST /api/auth/signup`, `/verify-account`, `/login`; `Users`, `OtpTokens`, `RefreshTokens` | Backend auth integration; three-account live flow |
| Authentication / sessions | PASS | Fixed Discover bypassing refresh, concurrent refresh rotation, refresh/logout races, and unindexed global refresh-token scanning. Refresh tokens now have an indexed non-secret selector while retaining a bcrypt hash. | `POST /api/auth/refresh-token`, `/logout`; `RefreshTokens.tokenSelector`, `Users.tokenVersion` | Concurrent replay test proves one `200` and one `401`; Flutter refresh-capable Discover tests; live logout/relogin/restart |
| Account verification logic | PASS | Internal hashed OTP creation, expiry, attempt caps, cooldown, consumption, and verification work. | `POST /api/auth/verify-account`, `/resend-verification-code`; `OtpTokens`, `Users.isVerified` | Auth integration and live development OTP flow |
| SMS/email OTP delivery | THIRD-PARTY BLOCKED | Internal delivery adapters fail explicitly outside development, but provider credentials are not configured. Development exposes OTP only in guarded development mode. | SMS/email adapters plus auth endpoints | Internal provider stubs and error paths tested; no live external delivery attempted |
| Google sign-in | THIRD-PARTY BLOCKED | Backend returns `GOOGLE_AUTH_NOT_CONFIGURED` when OAuth is absent; internal account collision/deleted/reactivation logic is present. | `POST /api/auth/google`; `Users` | Configuration/error contract inspected; no external OAuth call attempted |
| Password recovery | PASS / THIRD-PARTY BLOCKED delivery | Email-based recovery is non-enumerating, expiring, attempt-limited, single-use, and revokes sessions; external email delivery needs credentials. | `/forgot-password`, `/verify-reset-code`, `/reset-password`; `OtpTokens`, `Users`, `RefreshTokens` | Backend auth integration |
| Onboarding | PASS | All stages, validation, completion prerequisites, and restart persistence are server-authoritative. | `/api/onboarding/*`; `OnboardingProfiles` | Auth/onboarding integration; live three-account flow |
| Complete Profile / Edit Profile / Profile | PASS | Canonical `/api/me/profile` is used; partial updates preserve omitted fields and reject mass assignment. | `GET/PUT /api/me/profile`; `Users`, `OnboardingProfiles` | Own-profile integration; live isolated A/B profile update/reload |
| Preview Profile / Profile Detail | PASS | Public detail is authenticated, lifecycle-aware, block-aware, private-field safe, and maps the backend response to the Flutter domain model. | `GET /api/profiles/:userId`; `Users`, `OnboardingProfiles`, relationship tables | Phase-2 integration; Flutter route suite; live block visibility test |
| Photos | PASS | Uploads are signature-validated, limited to six, reorderable, removable, and persisted as profile references; failures do not invent fallback records. | `/api/onboarding/photos`, `/photos/:index`, `/photos/primary`, `PUT /api/me/profile`; `OnboardingProfiles.photos` plus upload storage | Auth/onboarding integration; live two-photo uploads per account |
| Discover | PASS | Fixed production Discover requests so expired access tokens use the common authenticated refresh/retry client. Static demo home is no longer a production route. | `/api/discover/feed`, `/swipe`, `/rewind`; `DiscoverActions`, `OnboardingProfiles`, `Users` | Discover integration; Flutter requester tests; live feed/pass/rewind/like flow |
| Discover filters / preferences | PASS | Preferences are owner-scoped, validated, persistent, and applied in database queries before pagination. | `GET/PUT /api/me/preferences`, `/api/discover/filters`; `DiscoverFilterPreferences` | Notifications/preferences and Discover integration; live isolated persistence/restart |
| Likes / passes / Super Likes / saved profiles | PASS | CRUD is owner-scoped, idempotent, block/lifecycle aware, and database-backed. | `/api/discover/swipe`, `/rewind`, `/api/me/likes`, `/super-likes`, `/received-likes`, `/saved-profiles`; `DiscoverActions`, `SavedProfiles` | Relationships integration; live A/B/C isolation |
| Matches / deterministic compatibility | PASS | Reciprocal reactions create one canonical pair; explainable profile-based compatibility is deterministic and does not claim an external AI result. Removed a reachable prototype page with hardcoded metric percentages. | `GET/DELETE /api/matches`, public-profile compatibility; `Matches`, profile fields | Compatibility/unit, phase-2 and relationships integration; live reciprocal match/restart |
| External AI-generated matching/coaching | THIRD-PARTY BLOCKED | No external AI provider is integrated. Active conversation starters now truthfully run on-device from the real matched profile and open a real chat with prefilled—not falsely sent—text. | Existing match/profile/chat APIs | Flutter analysis/routes; backend deterministic compatibility tests |
| Chat / messages | PASS | Conversations require an active match, are pair-idempotent, and hide non-members. Text/media/drafts/mute/delete are persistent. | `/api/conversations`, `/:id/messages`, `/media`, `/draft`, `/mute`, `/api/messages/:id`; chat tables | Phase-3 integration, live chat-history probe, live full flow |
| Message persistence / read receipts / realtime | PASS | Message state is persisted before authorized realtime emission; read state and unread counts reload correctly; a third user receives no history or events. | message/read endpoints and Socket.IO; `Messages`, `ConversationParticipants`, `Conversations`, `MessageMedia` | Phase-3 integration plus normal-DB chat and restart probes |
| Notifications / notification preferences | PASS | In-app notifications, actor mapping, read/read-all/delete, filtering, preferences, dedupe, and user isolation are internal and persistent. | `/api/notifications`, `/api/notification-preferences`; `Notifications`, `NotificationPreferences` | Notification integration, live like probe, full flow |
| Push delivery | THIRD-PARTY BLOCKED | Internal device and delivery rows work and honestly record `credentials_required`; Flutter does not have a live Firebase token without provider setup. | `/api/devices`; `UserDevices`, `NotificationDeliveries`; Firebase adapter | Backend delivery/mute integration and live device CRUD |
| Events | PASS | Browse/detail/eligibility/availability/register/My Events/cancel are database-backed and owner-scoped. Fixed cached registrations surviving account switches. | `/api/events`, `/api/events/me`, `/:id/registration`; `Events`, `EventRegistrations` | Phase-4 integration; Flutter account-switch test; live restart flow |
| Event feedback | NOT APPLICABLE | The endpoint/UI/table were explicitly retired; current routes return `404`, and the retirement migration removed the table. | No active API; migration `202608210001-remove-retired-features.js` | Phase-4 retired-route test |
| Membership / plans | PASS | Plans, membership status, cancel/restore, and owner isolation are database-backed. | `/api/subscriptions/plans`, `/me`, `/cancel`, `/restore`; `SubscriptionPlans`, `Subscriptions` | Phase-5 integration and normal-DB membership probe |
| Paid membership checkout | THIRD-PARTY BLOCKED | Razorpay order/verification/webhook logic exists, but real checkout and settlement require provider credentials. The UI shows real failures and does not grant membership locally. | `/api/payments/orders`, `/verify`, `/webhook`; `Payments`, `PaymentEvents`, `Subscriptions` | Internal integration only; no live provider payment attempted |
| Roses | PASS | Standalone and matched-conversation roses persist without fake commerce state. Fixed idempotent replays to return `200`/“already sent” instead of a false `201` creation response. | `POST /api/roses/send`; `RoseTransactions`, `Notifications` | Rose integration, normal-DB rose probe, live full flow |
| Settings / preferences | PASS | Active settings routes use backend repositories for persistent values; theme remains intentionally device-local. Errors do not display fake save success. | profile, Discover, notification, membership, account APIs and tables | Flutter settings/account tests plus live preference persistence |
| Blocks / reports / safety | PASS | Blocks apply bidirectionally across visibility, Discover, match/chat access; reports validate and dedupe. | `/api/blocks`, `/api/reports`; `Blocks`, `Reports`, related match visibility | Phase-2 integration; live block/report flow |
| Identity submission | PASS | Aadhaar/selfie media is private, signature-validated, owner-scoped, and status-persistent. | `/api/identity-verification/me`, `/submissions`; `IdentityVerifications`, private upload storage | Identity integration and live submission |
| Final identity review | THIRD-PARTY BLOCKED | No internal admin/review UI/API is active; pending submissions cannot be forged into verified state. A provider or separately authorized review system is required. | Review/document APIs intentionally return `404` | Identity integration |
| Deactivate account | PASS | Fixed deactivation to transactionally increment token version and revoke all refresh tokens. Valid credentials now intentionally reactivate the hidden account. | `POST /api/account/deactivate`, login/refresh; `Users`, `RefreshTokens` | Phase-2 lifecycle test and live deactivate/reactivate |
| Delete account | PASS | Soft-deletion preserves referential/audit integrity while revoking sessions, removing matches/public visibility, and anonymizing name/email/phone/password/Google identity. | `DELETE /api/account`; `Users`, `RefreshTokens`, `OtpTokens`, `Matches` | Phase-2 lifecycle test and live deletion |
| Retired prototype flows (recap, SOS, social proof, referral leaderboard, old match dashboard) | NOT APPLICABLE | They had no backend contracts and contained fabricated “prepared/success” states. Their dormant files remain for design reference, but all production route registrations were removed. | No active APIs/tables | Full Flutter registered-route suite confirms active routes build |

## Defects fixed

1. Event registrations cached by a singleton could briefly leak from User A into User B's session.
2. Discover used a separate token path and could fail after access-token expiry while the rest of the app remained authenticated.
3. Simultaneous `401` responses could rotate one refresh token more than once; logout/account switching could race a late refresh.
4. Refresh-token verification scanned and bcrypt-compared every active token. A migration adds an indexed random selector; the secret remains bcrypt-hashed.
5. Deactivation left refresh tokens alive and had no valid reactivation path.
6. Account deletion retained direct identifiers. Deleted accounts are now anonymized while safety/audit relationships remain intact.
7. Rose idempotent replay returned a false “created” status.
8. Reachable prototype routes exposed static profiles, hardcoded compatibility metrics, fake “prepared” actions, or unsupported AI claims.
9. Conversation starters used generic static content and a hardcoded score; they now use the real matched profile and deterministic on-device text.
10. Event sharing claimed preparation without a share integration; the UI now says nothing was shared.

## API changes

- `POST /api/auth/login`: reactivates a correctly authenticated deactivated account and returns `reactivated`.
- `POST /api/auth/refresh-token`: only active accounts; serialized atomic rotation; indexed selector lookup.
- `POST /api/auth/logout`: selector lookup for current-format tokens, with legacy-token compatibility.
- `POST /api/account/deactivate`: transactional token-version bump plus refresh-token revocation.
- `DELETE /api/account`: identifier anonymization and OTP/session cleanup in addition to public removal.
- `POST /api/roses/send`: `201` for first creation, `200` for an identical idempotent replay, `409` for key conflicts.
- Discover Flutter requests: production path now uses `AuthService.authenticatedRequest` for refresh/retry and canonical errors.

## Database changes

- New applied migration: `202608220001-add-refresh-token-selector.js`.
- `RefreshTokens.tokenSelector VARCHAR(32) NULL` with unique index `refresh_tokens_token_selector_unique`.
- Existing legacy rows with a null selector remain usable until logout/expiry; all newly issued tokens use selector + bcrypt hash.
- No test data was left in `amora_ai`; all 23 migrations report `up`.
- Checked orphan counts for profile users, Discover actors/targets, match participants, chat users/conversations, event registrations, notifications, saved profiles, and rose participants: all zero.

## Files changed

Backend:

- `Backend/src/controllers/accountController.js`
- `Backend/src/controllers/authController.js`
- `Backend/src/controllers/roseController.js`
- `Backend/src/models/RefreshToken.js`
- `Backend/src/utils/generateTokens.js`
- `Backend/src/migrations/202608220001-add-refresh-token-selector.js`
- `Backend/scripts/verify-full-application-flow.js`
- `Backend/package.json`
- `Backend/test/auth-onboarding.integration.test.js`
- `Backend/test/phase2.integration.test.js`
- `Backend/test/send-rose.integration.test.js`

Flutter:

- `lib/core/access/amora_access.dart`
- `lib/core/auth/auth_service.dart`
- `lib/features/discover/data/discover_api_service.dart`
- `lib/features/events/presentation/controllers/event_participation_controller.dart`
- `lib/features/events/presentation/event_detail_screen.dart`
- `lib/features/ai_coach/presentation/ai_icebreakers_screen.dart`
- `lib/features/match/presentation/why_we_matched_screen.dart`
- `lib/features/profile/presentation/bio_builder_screen.dart`
- `lib/features/settings/presentation/account_action_screens.dart`
- `lib/main.dart`
- `test/account_preferences_api_test.dart`
- `test/event_participation_controller_test.dart`

## Verification evidence

- `flutter analyze --no-pub`: no issues.
- Complete Flutter suite: 507 passed; 14 explicit QA-capture skips; no failures.
- Targeted changed Flutter flows: 18 passed.
- `flutter build web --release --no-pub --dart-define=AMORA_API_BASE_URL=https://api.example.com`: passed.
- Backend suite: 64/64 passed after final changes.
- `npm run verify:full-development-flow`: passed against `amora_ai`, three API-created accounts, backend listener restart, multi-user isolation, persistence, CRUD, lifecycle, and exact cleanup.
- Existing normal-DB probes passed for chat history/realtime isolation, like notifications, membership plans, and roses.
- Migration status: 23/23 `up` on `amora_ai`.
- Post-cleanup live schema check: zero temporary audit accounts/events and zero checked orphan rows.

## Remaining issues

There are no reproducible critical internal bugs in the active application paths covered by this audit. Production deployment still requires external provider credentials/configuration for SMS, email, Google OAuth, Razorpay, Firebase push, and the final identity-review mechanism. The web build reports optional WebAssembly incompatibilities in current secure-storage/socket dependencies; the standard JavaScript web release build succeeds.
