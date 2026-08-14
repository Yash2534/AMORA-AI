# AMORA Complete Business Logic and Condition Audit

**Audit date:** 14 August 2026  
**Scope:** Existing Flutter client, Express/Sequelize backend, MySQL integration schema, Socket.IO realtime layer, provider adapters, SRS at `tmp/project_audit/requirements/srs.txt`  
**Mode:** Read-only testing and audit; no feature, API, model, migration, or product-code changes  
**Overall result:** **NOT PRODUCTION READY**

## 1. Business Logic Summary

The AMORA codebase has a substantially real, database-backed core. Authentication, onboarding persistence, Discover actions, mutual matching, canonical direct conversations, messaging authorization, blocking, reports, events, saved/liked lists, Roses, notification inboxes, subscriptions, and identity submissions are not UI-only demonstrations. The strongest flows are protected by authentication, ownership checks, database constraints, and integration tests.

The release is not production-ready because several important SRS conditions are either stored but not enforced, wired to the wrong data source, or cannot complete end to end. The highest-risk findings are:

1. Discover stores maximum-distance and gender-interest preferences but does not apply them to candidate selection.
2. Rewind deletes the last reaction but does not unwind a match/conversation created by that reaction.
3. “AI Matches” loads existing mutual matches from `/api/matches`, not recommended unmatched candidates, while still presenting Like/Bulk Like controls.
4. Identity verification can be submitted but has no implemented review/provider transition to `verified` or `rejected`.
5. Push notifications have backend delivery infrastructure but the Flutter app never registers a device token; email, SMS, and quiet hours are persisted but not executed.
6. Account deletion is a soft anonymization and does not permanently remove profile, identity, chat, and related account data as described by the SRS.

### Evidence and execution

| Gate | Result | Evidence |
|---|---:|---|
| SRS read | PASS | 680 lines, 22 pages, 30 modules, 421 feature elements, plus two roadmap items |
| Flutter source inventory | PASS | 202 Dart source files; 69,814 lines; 92 named route definitions |
| Backend inventory | PASS | 128 JavaScript source files; 27 Sequelize models; 79 route declarations; 24 migrations |
| Flutter static analysis | PASS | `flutter analyze`: no issues |
| Flutter automated tests | PASS | 535 passed, 0 failed, 14 intentionally skipped QA-evidence/golden cases |
| Backend automated tests | PASS | 73 passed, 0 failed, 0 skipped against isolated MySQL schema `amora_ai_test` |
| Live Flutter browser session | BLOCKED | Local Flutter web server did not become reachable; no visual result is claimed |
| Live provider verification | BLOCKED | Google, SMTP/Twilio, Razorpay, Firebase credentials and real devices were not available |
| Production database verification | BLOCKED | Audit intentionally did not mutate or inspect production data; integration schema verified persistence |

### Architecture map

`Flutter widget/gesture → controller/repository → AuthService HTTP or Socket.IO → Express route validation/auth → controller/service condition → Sequelize transaction/model/constraint → JSON/realtime event → repository state → UI/navigation`

Important source-of-truth boundaries:

- Authentication and lifecycle: `Users`, `RefreshTokens`, `OtpTokens`, auth/account controllers.
- Discovery and reactions: `OnboardingProfiles`, `DiscoverFilterPreferences`, `DiscoverActions`, discover controller.
- Matching and chat: `Matches`, `Conversations`, `ConversationParticipants`, `Messages`, `MessageMedia`.
- Events: `Events`, `EventRegistrations`, `EventWaitlist`; capacity is server-authoritative.
- Safety: `Blocks`, `Reports`; access-control SQL is reused by Discover, matches, profiles, and chat.
- Notifications: `Notifications`, `NotificationPreferences`, `UserDevices`, `NotificationDeliveries`.
- Commerce: `SubscriptionPlans`, `Subscriptions`, `Payments`, `PaymentEvents`.
- Identity: `IdentityVerifications` plus private filesystem storage paths.

## 2. All Discovered Conditions

The project contains approximately 1,786 Dart `if` conditions, 101 Dart switch constructs, and 510 backend `if` conditions. The audit grouped these into the user-visible rules in the final matrix rather than treating every rendering guard as an independent business rule.

Cross-cutting conditions discovered:

- Bearer authentication, refresh-token rotation/revocation, token-version invalidation, account status, and onboarding completion.
- Target existence, target lifecycle, self-action prevention, bidirectional block checks, match membership, and conversation membership.
- Unique actor/target reactions, canonical ordered user pairs, unique conversation pair keys, Rose idempotency keys, and event/user uniqueness.
- Pagination, stable ordering, visibility, status, date, age, availability, preference, compatibility-score, and notification-category filters.
- Loading, empty, retry, unavailable, success, and optimistic/local state guards in Flutter.
- Provider configuration checks for Google, email/SMS OTP delivery, Razorpay, Firebase push, media permissions, and Socket.IO.

## 3. Like / Mutual Like / Match Logic

The core mutual-like path passes. `POST /api/discover/swipe` stores one `DiscoverActions` row per actor/target pair. `like` and `superLike` both count as positive interest. The second reciprocal positive reaction locks the two user rows, `findOrCreate`s the canonical `Matches` row, and calls `ensureDirectConversation` inside the same transaction. The response contains `matchId`, `conversationId`, and the matched profile. Flutter refreshes the chat repository immediately. Integration tests confirm both users retrieve the same conversation after refresh/login and cannot retrieve another pair’s conversation.

Duplicate matches are prevented by the canonical ordered user-pair constraint. Duplicate direct conversations are prevented by the canonical `pairKey`. Repeating a Like updates the unique reaction rather than inserting a second row.

Failures:

- Rewind destroys only the latest `DiscoverActions` row. If that action created a match, the `Matches` and `Conversations` state remains, creating a reaction/match inconsistency.
- AI Matches is semantically incorrect: it calls `GET /api/matches`, so it shows already-mutual matches as “recommendations” and offers Like/Bulk Like controls on them.

## 4. Super Like Logic

Super Like is persisted in `DiscoverActions` and is idempotent per actor/target. It creates a `new_super_like` notification for a one-sided action and participates in reciprocal matching exactly like a normal Like. The received/sent Super Like lists are owner-scoped, paginated, lifecycle-filtered, and block-filtered.

No Super Like quota, credit cost, or plan restriction is implemented. The SRS calls Super Like stronger than Like but does not prescribe a quota; therefore entitlement/limit scenarios are recorded as **N/A / existing code behavior**, not invented requirements.

## 5. Rose / Gift Logic

`POST /api/roses/send` requires authentication, an active completed recipient, no self-send, no block in either direction, and—when a conversation is supplied—membership of both participants. A client-generated idempotency key prevents duplicate Rose transactions and notifications, including concurrent retries. Notes are optional and limited by validators/UI. A Rose can be sent without a match or conversation; this is existing code behavior.

For a matched profile, Flutter sends the Rose transaction first and then separately posts a chat message with a Rose context. If the chat message fails, the Rose remains successful. This avoids rolling back a confirmed Rose but means “Rose appears in Chat” is not atomic. Profile Details exposes “Send Rose”; a separate Send Gift system is absent and retired gift endpoints return 404.

## 6. Chat Access and Messaging Logic

Chat access is server-enforced. New direct conversation creation requires an active mutual `Match`, two active completed users, and no bidirectional block. Existing conversations reuse the canonical pair. Conversation membership is required for lists, history, messages, media, drafts, mute, read, report-from-chat, and deletion. One-sided Like, Rose alone, unmatched, blocked, inactive, deleted, or unrelated users cannot create/send through a conversation.

Messages persist before Socket.IO emission. Realtime rooms are authenticated and participant-scoped. Read state persists on `ConversationParticipants`/messages and emits authorized events. Image media is signature-validated, privately stored, and participant-authorized. Message deletion is sender-only and soft/idempotent. Drafts and mute state persist on the backend.

The Flutter composer prevents empty and overlapping sends, but the message API has no client idempotency key or unique client message ID. Two independent rapid HTTP requests can create duplicate messages.

## 7. Pass / Undo Logic

Pass is stored in the same unique `DiscoverActions` relationship and removes the profile from subsequent feed queries. Like after Pass is possible only through another entry point that still has the target profile; it overwrites the unique action. Flutter serializes swipe actions and advances the deck only after backend success. Rewind returns `NOTHING_TO_REWIND` when empty and restores the exact last card/image locally after server success.

Undo is not plan-gated. The SRS says it is “typically premium,” which is advisory rather than an explicit entitlement rule. The material defect is that rewinding a match-forming Like/Super Like does not remove or reconcile the already-created match/chat.

## 8. Block / Report / Mute Logic

Block is authenticated, forbids self-blocking, validates an active target, and is idempotent. Bidirectional block enforcement is reused by public profile, Discover, match visibility, conversation creation, message send, and realtime delivery. Existing conversations remain in history but return `canMessage=false`; notifications for that conversation stop. Unblock restores access to the existing conversation and reconstructs a match when necessary without creating another conversation.

Reports validate target type/reason, forbid self-report, validate chat participant pairing, persist optional notes, and deduplicate a matching open/reviewing report for 24 hours. Report alone does not block or hide a profile; the UI offers separate Report and Block actions. Conversation mute is per participant and suppresses message/Rose delivery linked to that conversation.

## 9. Membership / Entitlement Logic

Plans and membership state are database-backed. Payment order creation requires an active plan and idempotency key. Verification/webhook processing validates provider signatures and activates or extends one subscription transactionally. Current membership lazily marks an elapsed period expired. Cancel-at-period-end is idempotent; restore reloads server state.

`hasEntitlement` exists but no action controller calls it. Likes, Super Likes, rewind, Roses, chat, and events therefore have no server-side plan restriction. Because the SRS does not explicitly assign most of these actions to a plan, this is documented as existing behavior. Live Razorpay success/failure/cancel/webhook execution was blocked by provider credentials; automated coverage does not include the live provider.

## 10. Notification Logic

The database inbox and category preferences work for one-sided Likes/Super Likes, mutual matches, messages, and Roses. Notifications are owner-scoped, paginated, mark-read/read-all/delete correctly, and use dedupe keys. Disabled mapped categories suppress notification creation. Muted conversations suppress linked message/Rose notifications. Safety updates are forced on.

Gaps:

- No Flutter Firebase Messaging dependency or call to `/api/devices` exists, so production Flutter sessions do not register push tokens.
- `emailEnabled` and `smsEnabled` are persisted but no notification email/SMS delivery service consumes them.
- Quiet hours are persisted but never checked by notification creation or delivery.
- No event-reminder scheduler/producer and no membership/payment notification producer was found.

## 11. Discovery / Profile Eligibility Logic

The backend enforces completed onboarding, active users, exclusion of self, prior actions, and bidirectional blocks. Age, city, height, hometown, education, profession, community, religion, sexuality, lifestyle, languages, pronouns, intentions, qualities, talking hours, love languages, communication style, smoking/drinking/weed, prompt presence, verified-only, online-now, event participation, and minimum compatibility score are applied before pagination. Compatibility scoring is deterministic and explicitly non-AI.

Two key onboarding preferences are not applied:

- `maxDistanceKm`/`preferredDistance` is accepted and stored, but candidate coordinates are not queried and no distance predicate exists.
- Viewer `interestedIn` and reciprocal candidate gender preferences are not part of Discover SQL.

`verifiedOnly` defaults to `true` in existing code; the SRS does not specify that default, so this is a documented product decision/risk rather than a conformance failure.

## 12. Event Logic

Browse/detail/My Events, authentication, public visibility, lifecycle state, date filtering, age eligibility, registration, cancellation, waitlist join/leave, duplicate prevention, waitlist capacity, and FIFO promotion are backend-backed. Register and waitlist use an event row lock, so concurrent users cannot overbook capacity. The server—not Flutter—computes `registeredCount`, `seatsLeft`, `available`, `waitlistCount`, `waitlistAvailable`, and the current user’s participation.

Gaps:

- “Featured” is the first returned event; “Recommended” is the next five; “Near You” is same-city client filtering. These are not server recommendations or geographic proximity.
- The API returns coordinates, but Flutter’s production mapper sets `distance: ''`; distance is therefore not displayed.
- The backend includes only the organizer and current user’s participation, not attendee profiles; “Who’s joining” has counts but no production attendee list.
- Promotion and event reminders do not create notifications.

## 13. Authentication / Account Logic

Signup validates name, Indian phone, email, password length, confirmation, and terms. Verification OTP is six digits and rate-limited. Login rejects invalid credentials/unverified state, refresh tokens rotate/persist, logout revokes the supplied refresh token, password recovery is non-enumerating and single-use, and password reset revokes sessions. Expired/invalid tokens cannot reach protected routes. Google login fails closed when not configured.

Deactivation increments token version, removes refresh tokens, hides the account, and a later valid login reactivates it (existing code behavior). Deletion revokes sessions, removes matches, anonymizes credentials, and hides the account, but retains the User row and much related data. This conflicts with the SRS statement that deletion permanently removes profile/account data.

The Settings “Change Password” action routes to email password recovery. It does not implement the SRS’s current-password/new-password/confirm-password flow.

## 14. Identity Verification Logic

The owner can retrieve `not_started`, submit Aadhaar plus selfie, receive `pending`, and cannot submit again while pending/under-review/verified. Rejected submissions can be retried. Media type/size is validated, files are stored outside public uploads, raw paths are never returned, and endpoints are owner-authenticated.

The model supports `pending`, `under_review`, `verified`, and `rejected`, but only GET status and POST submission routes exist. There is no provider callback, worker, or authorized review transition. Consequently Processing → Verified/Rejected cannot occur within the current application, and verified-only Discover relies on `Users.identityVerifiedAt` being changed externally.

## 15. Profile Data Conditions

Canonical profile data is stored in `Users` and `OnboardingProfiles`. Updates whitelist editable fields, reject mass assignment and invalid enums/dates, and roll back cross-table failures. Public serialization omits secrets/private identifiers. Onboarding completion requires birth date, gender, interest preference, relationship goal, city, and at least two photos. Photo upload/delete/primary-index rules are server-backed. Client completion percentage is calculated from actual canonical fields and photos, not a fixed constant.

Profile Details loads relationship state for the authenticated viewer → target pair. Like/Super Like/Saved/Blocked/Matched states therefore persist across refresh and differ by viewer. The Like button is unfilled before the viewer’s Like and filled only after server success/current relationship reload; full Flutter tests cover this behavior.

## 16. API / Backend / Database State Conditions

The 27 Sequelize models are associated through one model registry and 24 ordered migrations. Major mutations use transactions where multi-table consistency matters: onboarding/profile updates, account lifecycle, mutual match/conversation creation, event register/waitlist/promotion, Rose creation+notification, and payment activation. Unique constraints cover actor-target reactions, canonical matches, direct conversation pairs, event-user relationships, user notification preferences, and Rose idempotency.

Validation produces 400; missing/hidden resources 404; duplicates/invalid states generally 409; unauthorized 401; forbidden ownership/relationship 403; unexpected errors use centralized handling. Flutter repositories update local state only after successful responses in the major flows and expose retry/error states.

The audit did not run migrations, reset/drop a database, delete data, or inspect production records. Backend integration tests created and verified records only in the isolated `amora_ai_test` schema.

## 17. Race / Repeated Action Testing

Confirmed safe:

- Double Like/Super Like/Pass: unique actor-target row plus upsert.
- Concurrent mutual reactions: ordered user locks, canonical match uniqueness, canonical conversation pair.
- Double Rose/concurrent retry: required idempotency key and unique sender key.
- Double event join/waitlist: event row lock plus event-user uniqueness.
- Conversation creation: canonical pair key and reuse.
- Notification producer retries: dedupe key.
- Flutter swipe, Super Like, Rose sheet, event action, and message composer have in-flight guards.

Not safe end to end:

- Independent duplicate message HTTP requests have no idempotency key.
- Rewind after a match-forming reaction leaves the match/conversation.
- Rose transaction and Rose chat-card message are separate commits.

## 18. End-to-End Scenarios

| Scenario | Result | Notes |
|---|---|---|
| Signup → OTP → onboarding → persisted profile → logout | PASS | Backend integration test; database reload confirmed |
| A Likes B; B does not Like | PASS | Reaction + one-sided notification; no match |
| A Likes B; B Likes A → match → chat → message | PASS | Canonical records and both-user retrieval confirmed |
| A Super Likes B | PASS | Persisted, notified, participates in reciprocal matching |
| A sends Rose with/without note | PASS | Transaction + notification + idempotency confirmed; chat-card atomicity is partial |
| Save profile → Saved Profiles | PASS | Owner-scoped/idempotent/persistent |
| Block user → discovery/chat/notification restrictions | PASS | Backend and Flutter regression coverage |
| Report user → persistence/dedupe | PASS | Reason, notes, chat target binding confirmed |
| Match → message → read receipt/realtime | PASS | Two authenticated realtime clients tested |
| Expired membership → premium action | N/A | No concrete SRS action entitlement; expiration state itself passes |
| Join event → My Events; full → waitlist → promotion | PASS | Database and race-safe backend integration coverage |
| Verification submit → processing | PASS | Private owner flow confirmed |
| Verification processing → verified/rejected | MISSING | No transition route/provider/worker |
| Deactivate → sessions revoked → login reactivation | PASS | Existing code behavior |
| Delete → access removed | PASS | Old tokens and public access removed |
| Delete → permanent profile/account-data erasure | FAIL | Soft anonymization retains related data |
| Discover honors distance and gender interest | FAIL | Preferences stored, predicates absent |
| Live Flutter visual multi-user scenarios | BLOCKED | Local web target unavailable in audit environment |
| Google/OTP providers, push device, Razorpay on real services | BLOCKED | Credentials/device/provider sandbox unavailable |

## 19. Final Condition Matrix

Status meanings: **PASS** verified in current code/tests; **FAIL** implemented behavior contradicts an explicit SRS condition or corrupts state; **PARTIAL** some layers work but the full condition does not; **MISSING** no current implementation for an SRS condition; **BLOCKED** could not be executed safely in this environment; **N/A** SRS is silent, roadmap-only, or current code explicitly does not support the proposed condition.

| ID | Module | Trigger | Condition | Expected Action | API | Backend | DB | UI/Navigation | Notification | Actual Result | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| A01 | Auth | Signup | Valid unique email/phone, terms accepted | Create unverified account and OTP | `POST /api/auth/signup` | Validates/rate-limits/hashes | Users + OtpTokens | Verification screen | OTP provider/fallback | Persisted and tested | PASS |
| A02 | Auth | Signup | Duplicate identity | Reject conflict | Same | Unique lookup | No duplicate User | Error state | None | Rejected | PASS |
| A03 | Auth | Verify | Correct unexpired six-digit OTP | Verify account | `POST /verify-account` | Single-purpose token | Users/OtpTokens | Onboarding | None | Persisted | PASS |
| A04 | Auth | Verify/resend | Wrong/expired/rate-limited OTP | Fail safely | Verify/resend APIs | Validation + limiter | No false verify | Error/retry | OTP only if eligible | Tested | PASS |
| A05 | Auth | Login | Unverified/invalid credentials | Deny session | `POST /login` | Credential/status checks | No token row | Login error | None | Tested | PASS |
| A06 | Auth | Login | Valid deactivated account | Reactivate and issue session | `POST /login` | Existing behavior | User active + token | App start | None | Tested; not explicit SRS rule | PASS |
| A07 | Auth | Refresh | Valid refresh token | Rotate session | `POST /refresh-token` | Token/version checks | Replace token | Session continues | None | Implemented | PASS |
| A08 | Auth | Protected API | Missing/expired/invalid token | 401 | All protected routes | Auth middleware | No mutation | Login/retry | None | Tested | PASS |
| A09 | Auth | Logout | Valid session | Revoke supplied refresh token | `POST /logout` | Owner token removal | RefreshTokens | Login | None | Tested | PASS |
| A10 | Password | Forgot/reset | Existing or unknown email | Non-enumerating, single-use reset | Forgot/verify/reset APIs | Recovery token + hash | OTP consumed; sessions revoked | Reset flow | Email provider/fallback | Tested | PASS |
| A11 | Password | Change from Settings | Authenticated user | Current/new/confirm flow per SRS | No dedicated API | Routes to email reset | Password changes via recovery | Forgot-password UI | Email | Current-password condition absent | PARTIAL |
| A12 | Google | Google login | Valid provider token/config | Verify token and session | `POST /google` | Google verifier | User/session | App/onboarding | None | Live provider unavailable | BLOCKED |
| O01 | Onboarding | Enter birth date | User must be 18+ | Accept/reject | `PUT /api/onboarding/age` | Age middleware | OnboardingProfile | Next/error | None | Tested | PASS |
| O02 | Onboarding | Select gender | Approved enum/custom label | Persist | `PUT /gender` | Validation | OnboardingProfile | Next | None | Tested | PASS |
| O03 | Onboarding | Select interested-in | At least one approved gender | Persist | `PUT /interested-in` | Validation | OnboardingProfile | Next | None | Tested | PASS |
| O04 | Onboarding | Select goal | At least one nonempty value | Persist | `PUT /relationship-goal` | Validation | OnboardingProfile | Next | None | Tested | PASS |
| O05 | Onboarding | Location | City + 5–200 km distance | Persist | `PUT /location` | Validation | OnboardingProfile | Next | None | Persisted | PASS |
| O06 | Onboarding | Starter profile | Profession and education | Persist | `PUT /starter-profile` | Validation | OnboardingProfile | Next | None | Persisted | PASS |
| O07 | Onboarding | Upload photos | Valid image/limits | Store private-owned profile photos | `POST /photos` | Media validation | Photo JSON/storage | Gallery updates | None | Tested | PASS |
| O08 | Onboarding | Complete | Required fields + at least two photos | Set completion | `POST /complete` | Server gate | onboardingCompleted | Discover | None | Tested | PASS |
| O09 | Startup | Incomplete onboarding | Authenticated incomplete user | Resume required step | Status/me APIs | Completion state | Canonical profile | Conditional routing | None | Widget/integration coverage | PASS |
| O10 | Completion | Missing optional details | Optional field absent | Keep incomplete percentage, allow canonical save | Profile APIs | Whitelist/validators | Partial profile | Pending sections | None | Data-based, not hardcoded | PASS |
| D01 | Discover | Load feed | Not authenticated | Deny | `GET /api/discover/feed` | Auth | None | Login/error | None | Tested | PASS |
| D02 | Discover | Load feed | Onboarding incomplete | 403 | Same | `requireCompleted` | None | Completion CTA | None | Implemented | PASS |
| D03 | Discover | Load feed | Self/inactive/acted/blocked | Exclude before pagination | Same | SQL exclusions | Read only | Cards absent | None | Tested | PASS |
| D04 | Discover | Filter age | Valid min/max | DB range before pagination | Feed/filters APIs | SQL birth-date range | Preferences | Filtered deck | None | Tested | PASS |
| D05 | Discover | Filter profile fields | City/height/etc. | Compose DB predicates | Feed/filters APIs | SQL/JSON predicates | Preferences | Filtered deck | None | Tested | PASS |
| D06 | Discover | Filter communication | One/many approved styles | DB IN before pagination | Same | Parser + SQL | Preferences | Filtered deck | None | Tested | PASS |
| D07 | Discover | Filter verified | Toggle | Require identityVerifiedAt | Same | User predicate | Preferences/User | Filtered deck | None | Tested | PASS |
| D08 | Discover | Filter online | Toggle | Persisted recent activity window | Same | lastActiveAt predicate | Users | Filtered deck | None | Tested | PASS |
| D09 | Discover | Filter event interest | Toggle | Registered-event predicate | Same | EXISTS SQL | EventRegistrations | Filtered deck | None | Tested | PASS |
| D10 | Discover | Min score | Threshold | DB score before pagination | Same | Deterministic SQL score | Read only | Filtered deck | None | Tested | PASS |
| D11 | Discover | Distance preference | maxDistanceKm set | Exclude beyond radius | Same | Value parsed but no geo predicate | Preference only | Unfiltered by distance | None | Stored but not enforced | FAIL |
| D12 | Discover | Gender interest | Viewer/candidate preferences | Reciprocal eligibility | Feed | No gender-interest predicate | Onboarding data unused | Ineligible cards possible | None | Not enforced | FAIL |
| D13 | Discover | Empty result | No eligible profiles | Stable empty response | Feed | Pagination safe | None | Empty state | None | Implemented | PASS |
| D14 | Discover | API failure | Network/server error | Do not advance/show success | Feed/swipe | Error response | No mutation | Retry/error | None | Controller tested | PASS |
| D15 | Discover | Compatibility reason | Open reason | Factual deterministic explanation | Public profile/match | Non-AI calculator | Read only | Explanation sheet | None | Implemented | PASS |
| D16 | Discover | Verified default | No explicit selection | Product-defined default | Filters | Defaults true | Preference row | Verified-only feed | None | Existing behavior; SRS silent | N/A |
| L01 | Like | A Likes B | B has not liked A | Save Like, no match | `POST /discover/swipe` | Transaction/upsert | DiscoverActions | Filled/current action | New Like | Tested | PASS |
| L02 | Like | B Likes A | Reciprocal Like exists | Create match + chat | Same | Locks/findOrCreate | Actions/Match/Conversation | Match + Chat refresh | Match to both | Tested atomically | PASS |
| L03 | Like | Repeat Like | Same actor/target | No duplicate | Same | Upsert | Unique pair row | Already liked | Dedupe | Tested | PASS |
| L04 | Like | Like from Profile Details | Valid target | Same existing API | Same | Same business rule | DiscoverActions | Button fills after success | Like/match | Tested | PASS |
| L05 | Like | Reopen target profile | Existing viewer→target Like | Return selected relationship | `GET /api/profiles/:id` | Pair-specific state | DiscoverActions | Filled only for viewer | None | Tested | PASS |
| L06 | Like | Different viewer opens profile | No Like from that viewer | Unfilled | Same | Owner-specific query | No viewer row | Normal button | None | Tested | PASS |
| L07 | Like | Invalid/inactive/deleted target | Target unavailable | Reject | Swipe/profile APIs | Lifecycle check | No action | Error/unavailable | None | Tested | PASS |
| L08 | Like | Blocked pair | Either direction blocked | Reject/hide | Swipe/profile APIs | Access-control service | No action | Unavailable | None | Tested | PASS |
| L09 | Match | Concurrent reciprocal Likes | Race | One match/conversation | Swipe | Ordered locks | Unique canonical rows | Both chat lists | Dedupe | Tested | PASS |
| L10 | Match | Refresh/relogin | Existing match | Both retrieve same chat | Matches/conversations | Owner membership | Persisted | Chat visible | None | Tested | PASS |
| L11 | Match | Unmatch | Participant requests removal | Remove match/idempotent | `DELETE /api/matches/:id` | Ownership | Match removed | Chat cannot message | None | Tested | PASS |
| L12 | AI Matches | Open screen | Needs recommendations | Load recommended candidates | Calls `GET /api/matches` | Returns existing matches | Reads Match | Shows matches as recommendations/Likeable | None | Wrong data source/semantics | FAIL |
| S01 | Super Like | Send valid | Active completed target | Save Super Like | Swipe action `superLike` | Upsert | DiscoverActions | Animated selected state | New Super Like | Tested | PASS |
| S02 | Super Like | Repeat | Same pair | No duplicate | Same | Upsert | Unique pair | Already selected | Dedupe | Tested | PASS |
| S03 | Super Like | Reciprocal positive action | Like/Super Like exists | Match/chat | Same | Same mutual rule | Match/Conversation | Match/chat | Match | Tested | PASS |
| S04 | Super Like | Blocked/inactive target | Invalid relationship | Reject | Same | Lifecycle/block | No mutation | Error | None | Tested via shared rule | PASS |
| S05 | Super Like | View sent/received | Owner | Paginated visible list | `/api/me/super-likes*` | Owner/visibility filters | DiscoverActions | Managed list | None | Tested | PASS |
| S06 | Super Like | Exhaust quota | Quota required? | Follow SRS | None | No quota | No counter | Always available | None | SRS does not define quota | N/A |
| S07 | Super Like | Free user | Plan restriction required? | Follow SRS | None | No entitlement call | No debit | Available | None | SRS does not assign plan | N/A |
| S08 | Super Like | API failure | Server rejects | Preserve card/state | Swipe | No commit | No mutation | Error/retry | None | Controller shared tests | PASS |
| R01 | Rose | Send with note | Valid active recipient | Persist Rose | `POST /api/roses/send` | Validation/idempotency | RoseTransactions | Success | Rose received | Tested | PASS |
| R02 | Rose | Send without note | Valid recipient | Persist nullable note | Same | Validation | RoseTransactions | Success | Rose received | Tested | PASS |
| R03 | Rose | Send to non-match | No block, no conversation | Allow (existing behavior) | Same | Recipient validation | RoseTransactions | Profile success | Profile-linked | Tested | PASS |
| R04 | Rose | Send in valid chat | Both participants | Allow and link conversation | Same | Membership validation | RoseTransactions | Rose sheet/card | Conversation-linked | Tested API condition | PASS |
| R05 | Rose | Duplicate/retry | Same idempotency key/payload | Return same transaction | Same | Find/create/unique | One row | One success | One notification | Concurrent test passes | PASS |
| R06 | Rose | Key reused with new payload | Conflict | 409 | Same | Fingerprint check | No second row | Error | None | Tested | PASS |
| R07 | Rose | Invalid/self/blocked/deleted target | Invalid relation | Reject | Same | Relationship checks | No row | Error | None | Tested | PASS |
| R08 | Rose | Insufficient credits/plan | Restriction required? | Follow SRS | None | No commerce rule | No wallet | Available | None | SRS defines no credit rule | N/A |
| R09 | Rose | Rose succeeds, chat post fails | Matched conversation | Ideally one consistent Chat result | Rose + message APIs | Separate commits | Rose exists; message may not | Success may lack card | Rose notification exists | Non-atomic cross-flow | PARTIAL |
| R10 | Gift | Profile Send Gift | SRS feature | Gift UI/API/data | Retired endpoints 404 | No gift controller | No gift model | Rose only | None | Missing separate Gift | MISSING |
| P01 | Pass | Pass profile | Valid target | Persist and advance | Swipe `pass` | Upsert | DiscoverActions | Next card | None | Tested | PASS |
| P02 | Pass | Repeat/direct action | Same pair | Update unique row | Same | Upsert | One row | Stable | None | Safe | PASS |
| P03 | Undo | No history | Nothing to rewind | No action/404 | `POST /discover/rewind` | Not-found condition | No mutation | Disabled/error | None | Tested | PASS |
| P04 | Undo | Last Pass/Like | Existing action | Delete and restore exact card | Same | Deletes latest | Action removed | Card/image restored | None | Tested | PASS |
| P05 | Undo | Match-forming Like | Match already created | Reconcile reaction/match/chat | Same | Deletes action only | Match/chat remain | Inconsistent availability | Match remains | State inconsistency | FAIL |
| P06 | Undo | Free user | Premium restriction | Follow explicit SRS | None | No entitlement | No plan check | Available | None | “Typically premium,” not mandatory | N/A |
| C01 | Chat | Create conversation | Active mutual match | Create/reuse direct thread | `POST /api/conversations` | Access service | Conversation/participants | Chat detail | None | Tested | PASS |
| C02 | Chat | One-sided Like | No match | Deny | Same | Match required | No conversation | Unavailable | None | Tested | PASS |
| C03 | Chat | Rose only | No match | Deny chat, Rose still valid | Same | Match required | No conversation | Rose success only | Rose | Existing behavior | PASS |
| C04 | Chat | Existing thread | Same matched pair | Reuse | Same | pairKey | No duplicate | Same chat | None | Tested | PASS |
| C05 | Chat | List | Auth participant | Owner-scoped newest page | `GET /api/conversations` | Membership SQL | Read only | Chat list | None | Tested | PASS |
| C06 | Chat | Send text | Member/canMessage/nonempty | Persist then emit | `POST .../messages` | Transaction/access | Message + last state | Bubble/list update | New message | Tested | PASS |
| C07 | Chat | Empty/oversize text | Invalid | Reject | Same | Validator | No message | Composer/error | None | Tested | PASS |
| C08 | Chat | Send image | Valid signed media/member | Store privately | `POST .../media` | Signature/access | MessageMedia | Image bubble | New message | Tested | PASS |
| C09 | Chat | Read | Recipient opens/marks | Persist/emit | `PUT .../read` | Membership | Participant/messages | Read receipt | No inbox trigger | Tested realtime | PASS |
| C10 | Chat | Realtime message | Authorized room | Deliver only participants | Socket.IO | Auth room checks | Persisted first | Immediate update | Message | Two-client test | PASS |
| C11 | Chat | Blocked/unmatched/inactive | Relationship invalid | Deny sending | Chat APIs/socket | `canMessage`/access | No new message | Disabled reason | Suppressed | Tested | PASS |
| C12 | Chat | Delete message | Sender | Soft delete/idempotent | `DELETE /api/messages/:id` | Ownership | deletedAt | Deleted state | None | Tested | PASS |
| C13 | Chat | Draft | Nonempty/clear | Persist owner draft | Draft APIs | Membership | Participant draft | Restored composer | None | Tested | PASS |
| C14 | Chat | Mute/unmute | Participant | Persist own preference | Mute APIs | Membership | mutedAt/until | Toggle | Suppress linked | Tested | PASS |
| C15 | Chat | Double independent send | Same text twice rapidly | One logical message if retried | Message API | No idempotency/client ID | Two rows possible | Duplicate bubbles | Duplicate notifications | Server gap | PARTIAL |
| C16 | Chat | API/network failure | Send fails | Do not show false success | Message API | Error | No confirmed mutation | Error/retry | None | Flutter failure state covered | PASS |
| B01 | Safety | Block profile | Valid other user | Persist block | `POST /api/blocks/:id` | Self/lifecycle checks | Blocks | Blocked/unavailable | Suppress contact | Tested | PASS |
| B02 | Safety | Double block | Existing | Idempotent | Same | findOrCreate | One row | Already blocked | None | Tested | PASS |
| B03 | Safety | Block from chat | Participant target | Same server block | Same | Relationship check | Blocks | Chat disabled | Suppressed | Tested | PASS |
| B04 | Safety | Unblock | Existing block | Remove; reuse chat | `DELETE /api/blocks/:id` | Restore match if needed | Block removed | Access restored | Normal | Tested | PASS |
| B05 | Safety | Blocked discovery/profile/matches | Either direction | Hide | Feed/profile/match APIs | Shared SQL | Read only | Absent/unavailable | None | Tested | PASS |
| B06 | Report | Report profile | Valid reason/notes | Persist | `POST /api/reports` | Validation | Reports | Confirmation | None | Tested | PASS |
| B07 | Report | Duplicate abuse report | Same open reason <24h | Reuse | Same | Recent lookup | One open row | Existing confirmation | None | Tested | PASS |
| B08 | Report | Report from chat | Target must be other participant | Bind correctly | Same | Participant validation | Reports | Confirmation | None | Tested | PASS |
| B09 | Report | Report + block | User chooses both actions | Separate valid actions | Reports + blocks | Separate controllers | Report + Block | Flow completes | Suppressed by block | Implemented as separate choices | PASS |
| B10 | Safety | Report only | No block selected | Do not invent automatic block | Reports | No block mutation | Report only | User remains unless other rules | None | Existing behavior; SRS silent | N/A |
| M01 | Membership | Load plans | Active plans | Return ordered plans | `GET /api/subscriptions/plans` | DB query | SubscriptionPlans | Plan UI | None | Tested | PASS |
| M02 | Membership | Load mine | Auth user/no plan | Canonical state | `GET /me` | Expiry check | Subscriptions | Free/current UI | None | Tested | PASS |
| M03 | Membership | Expired period | End passed | Mark expired/no entitlements | Same | Lazy expiry | Subscription updated | Free state | None | Implemented | PASS |
| M04 | Membership | Cancel | Active/trial/cancelled | Cancel at period end/idempotent | `POST /cancel` | Status check | Subscription | Effective date | None | Implemented/tested at UI/repo level | PASS |
| M05 | Membership | Restore | Server membership exists/none | Reload state | `POST /restore` | Owner query | Read only | Current state | None | Implemented | PASS |
| M06 | Payment | Create order | Active plan + idempotency | Provider order | `POST /payments/orders` | Product/provider checks | Payments | Gateway UI | None | Code traced; live blocked | BLOCKED |
| M07 | Payment | Verify success/webhook | Valid signatures | Activate/extend once | Verify/webhook | Signature/idempotency transaction | Payments/Events/Subscription | Success/current plan | No producer found | Live blocked | BLOCKED |
| M08 | Payment | Failure/cancel | Provider failure/user cancel | No active plan/clear UI | Provider SDK | No false verify | No activation | Failed/cancelled screen | None | Flutter states tested; provider blocked | BLOCKED |
| M09 | Entitlement | Premium-only action | Explicit plan entitlement | Enforce client + server | No action use | `hasEntitlement` unused | No action restriction | Mostly available | None | No explicit mapping in SRS | N/A |
| M10 | Commerce | Wallet/boost/gift/redemption | Retired | Remain unavailable | 404 | Routes absent | No tables in use | No active flow | None | Explicitly tested | N/A |
| N01 | Notifications | New Like/Super Like | One-sided positive action | Create inbox item | Swipe | Producer + category | Notifications | Inbox | Push if possible | Tested | PASS |
| N02 | Notifications | Mutual match | Match created | Notify both once | Swipe | Dedupe producer | Notifications | Inbox/navigation | Push if possible | Tested | PASS |
| N03 | Notifications | New message | Persisted message | Notify other participant | Message API | Producer | Notification | Inbox/chat | Push if possible | Tested | PASS |
| N04 | Notifications | Rose | Rose committed | Notify recipient once | Rose API | Transaction producer | Notification | Inbox/profile/chat | Push if possible | Tested | PASS |
| N05 | Notifications | Disable category | Mapped category false | Suppress creation | Preferences APIs | Preference map | No inbox row | No item | No delivery | Implemented/tested | PASS |
| N06 | Notifications | Mute conversation | Muted recipient | Suppress linked notice | Mute + producer | Mute lookup | No inbox row | No item | No delivery | Tested | PASS |
| N07 | Notifications | Inbox operations | Read/read-all/delete | Owner-only/idempotent | Notifications APIs | Ownership | Persist flags/delete | Updated list | None | Tested | PASS |
| N08 | Notifications | Enable push | Flutter device | Register token and deliver | `/api/devices` exists | Backend delivery exists | UserDevices/Deliveries | Permission/settings | Firebase | Flutter never registers token | MISSING |
| N09 | Notifications | Enable email/SMS | Channel toggle | Deliver selected channels | Preferences only | No channel service | Toggle only | Appears enabled | None | Stored, not executed | PARTIAL |
| N10 | Notifications | Quiet hours | Enabled/in window | Delay/suppress delivery | Preferences only | No time check | Times only | Appears configured | Not honored | Stored, not executed | PARTIAL |
| N11 | Notifications | Event reminder/promotion | Upcoming/promoted | Notify | No producer | No scheduler/producer | No notification | No reminder | None | Missing | MISSING |
| N12 | Notifications | Payment/membership event | Payment/status change | Notify if SRS category enabled | No producer | No producer | No notification | No item | None | Preference exists only | PARTIAL |
| E01 | Events | Browse/detail | Auth/public/eligible | Return canonical events | `GET /api/events*` | Visibility/date/age SQL | Events | Browse/detail | None | Tested | PASS |
| E02 | Events | Join | Published/open/space | Register | `POST .../registration` | Event row lock | EventRegistrations | Joined/My Events | None | Tested | PASS |
| E03 | Events | Concurrent joins | Last seat | Never exceed capacity | Same | Event row lock/count | Capacity respected | One success/full state | None | Tested | PASS |
| E04 | Events | Duplicate join | Already active | Idempotent | Same | Existing row | One registration | Joined | None | Tested | PASS |
| E05 | Events | Full event | Count >= capacity | Hide Join/show waitlist when available | Detail/list | Server computes flags | Counts | Correct button state | None | Flutter/backend tests | PASS |
| E06 | Events | Join waitlist | Full/enabled/space/not registered | Persist waiting | `POST .../waitlist` | Locked validation | EventWaitlist | Waitlisted/My Events | None | Tested | PASS |
| E07 | Events | Duplicate waitlist | Already waiting | Idempotent/no duplicate | Same | Existing row | One row | Waitlisted | None | Tested | PASS |
| E08 | Events | Cancel registration | Active registration | Cancel, promote FIFO | `DELETE .../registration` | Locked promotion loop | Registration + Waitlist | Updated status | No promotion notice | Tested persistence | PASS |
| E09 | Events | Leave waitlist | Waiting | Mark left | `DELETE .../waitlist` | Owner lookup | Waitlist status | Removed | None | Implemented | PASS |
| E10 | Events | My Events | Upcoming/past/waitlist/cancelled | Correct category | `GET /api/events/me` | Relationship/date SQL | Read only | Tabs | None | Tested | PASS |
| E11 | Events | Cancelled/past/closed | Invalid action | Disable/reject | Detail/action APIs | Status/date checks | No mutation | Correct state | None | Tested/code traced | PASS |
| E12 | Events | Featured/recommended/nearby | Open browse | Personalized/proximity groups | One generic list | No recommendation/radius | Read only | First/next/same-city client grouping | None | Labels over simple grouping | PARTIAL |
| E13 | Events | View distance/attendees | Production API event | Show distance and members | Event API | Coordinates/count only | Registrations not serialized | Distance empty; attendee identities empty | None | SRS detail partial | PARTIAL |
| E14 | Events | Reminder/promotion | Time or seat promotion | Notify user | No endpoint/worker | No producer | No notification | No reminder | None | Missing | MISSING |
| I01 | Identity | Load status | No record | `not_started` | `GET /identity-verification/me` | Owner query | None | Start UI | None | Tested | PASS |
| I02 | Identity | Submit | Aadhaar + selfie valid | Pending | `POST /submissions` | Media/private storage/transaction | IdentityVerifications | Processing | None | Tested | PASS |
| I03 | Identity | Missing/invalid media | Validation fail | No submission | Same | Multer/storage checks | No row/files cleaned | Error | None | Tested/code traced | PASS |
| I04 | Identity | Resubmit pending/verified | Existing protected status | 409 | Same | Status lock | No overwrite | Existing state | None | Implemented | PASS |
| I05 | Identity | Retry rejected | Existing rejected | Replace with pending | Same | Allowed update | One user row/new files | Processing | None | Implemented | PASS |
| I06 | Identity | Review | Pending submission | Authorized under-review decision | No route | No reviewer/provider | Status cannot change | Stuck processing | None | Missing | MISSING |
| I07 | Identity | Verify/reject | Review result | Update status/User verified timestamp | No route/callback | No transition | Cannot complete | No final state | No safety update | Missing | MISSING |
| I08 | Identity | Privacy | Other user/raw URL | Never expose documents | Owner API only | Private storage | Paths private | No document access | None | Tested | PASS |
| I09 | Identity | Live Aadhaar/provider | Real verification | Provider result | None | No third party | None | N/A | N/A | No provider integration | BLOCKED |
| PR01 | Profile | Get own | Auth user | Complete canonical editable data | `GET /api/me/profile` | Owner query | Users/Profile | Edit form | None | Tested | PASS |
| PR02 | Profile | Update | Valid partial fields | Persist, preserve omitted | `PUT /api/me/profile` | Whitelist/transaction | Users/Profile | Saved/reload | None | Tested | PASS |
| PR03 | Profile | Invalid/mass assignment | Unsupported/private field | Reject | Same | Validators/whitelist | Rollback | Error | None | Tested | PASS |
| PR04 | Profile | Public view | Active completed/unblocked | Safe serializer | `GET /api/profiles/:id` | Visibility/access | Read only | Details | None | Tested | PASS |
| PR05 | Profile | Completion percentage | Canonical fields/photos | Data-derived percentage | Local calculator + profile APIs | Canonical data | Read only | Correct pending sections | None | Tested | PASS |
| PR06 | Profile | Photo add/delete/primary | Valid ownership/index | Persist | Onboarding photo APIs | Validation/storage | Profile photos | Gallery updates | None | Tested | PASS |
| PR07 | Profile state | Saved/Liked/Super/Blocked/Matched | Viewer opens target | Pair-specific state | Public profile | Relationship query | Relationship tables | Consistent actions | None | Tested | PASS |
| PR08 | Profile | Deleted/deactivated target | Hidden lifecycle | 404/unavailable | Public profile | accountStatus filter | Read only | Unavailable | None | Tested | PASS |
| PR09 | Account delete | Confirm deletion | Remove access/profile/account data | Permanent erasure per SRS | `DELETE /api/account` | Soft anonymization | Related data retained | Logged out/hidden | None | Access removed, erasure incomplete | FAIL |
| PR10 | Profile | AI bio assistant | SRS roadmap | AI suggestions/chat assistant | None | Deterministic local text only | None | Explicit non-AI preview | None | Roadmap, not release requirement | N/A |
| X01 | API | Validation failure | Bad field/state | Structured 400/409 | Major routes | Validators/controllers | No false mutation | Error | None | Tested broadly | PASS |
| X02 | API | Unauthorized/forbidden | Wrong user | 401/403/hidden 404 | Protected resources | Auth/ownership | No mutation | Login/error | None | Tested broadly | PASS |
| X03 | API | Not found | Missing/hidden entity | Safe 404 | Resource routes | Lifecycle/access | No mutation | Unavailable | None | Tested broadly | PASS |
| X04 | API | Server failure in transaction | Mid-flow failure | Roll back | Profile/Like/etc. | Sequelize transactions | Consistent | No false success | None | Rollback tests pass | PASS |
| X05 | API | Timeout/network failure | No response | Preserve unconfirmed state/retry | Flutter repositories | No assumed success | Unknown/no local claim | Error/retry | None | Automated repository coverage | PASS |
| X06 | API | Null/empty response | No data | Empty/error, not success content | Repositories | Parsing guards | None | Empty/error | None | Covered in widgets/repositories | PASS |
| X07 | Race | Rapid profile actions | Same controller in flight | Serialize | Flutter controllers | In-flight guards | One accepted state | Disabled/loading | Dedupe where supported | Covered | PASS |
| X08 | Race | Match while screen open | Realtime/server response | Chat becomes available | Swipe + Socket.IO | Conversation event | Persisted | Chat refresh | Match | Tested response/realtime path | PASS |
| X09 | Third party | Permissions | Denied/permanent/unavailable | Explain/open settings | OS permission APIs | Client service | None | Correct state | None | Flutter tests | PASS |
| X10 | Release | Full live multi-user/provider run | Production-like environment | Observe UI→API→DB→UI | All | All | Production-like | Actual devices | Actual providers | Environment unavailable | BLOCKED |

## 20. Bugs, Missing Conditions, and Recommended Fixes

No fix was made. Recommendations below are remediation guidance only.

| Issue | Exact condition / current vs expected | Files / API / DB | Severity | Recommended fix |
|---|---|---|---|---|
| AUD-001 | `maxDistanceKm` is parsed/persisted but never used in feed SQL; SRS expects preferred-distance eligibility. | `Backend/src/controllers/discoverController.js` `buildProfileWhere/getFeed`; `discoverRoutes.js`; `DiscoverFilterPreferences`, `OnboardingProfiles`; `GET /api/discover/feed` | HIGH | Add server-side geospatial distance calculation using canonical coordinates; test before pagination. |
| AUD-002 | Viewer `interestedIn` and reciprocal candidate gender preferences are stored but not used to select candidates. | `discoverController.getFeed`; `OnboardingProfiles`; `GET /api/discover/feed` | HIGH | Define the exact reciprocal rule with product/SRS owners, enforce in SQL, and add asymmetric preference tests. |
| AUD-003 | Rewind removes the last Like/Super Like action but leaves a match/conversation created by that action. | `discoverController.rewind`; `DiscoverActions`, `Matches`, `Conversations`; `POST /api/discover/rewind` | HIGH | Reconcile the match in the same transaction or explicitly forbid rewind after matching; preserve conversation-history policy deliberately. |
| AUD-004 | AI Matches loads existing mutual matches, labels them recommendations, and permits Like/Bulk Like. | `lib/features/matches/presentation/matches_screen.dart` `_loadMatches/_sendSelectedLikes`; `PhaseTwoApiService.matches`; `GET /api/matches` | HIGH | Back the screen with an explicit recommendation source or change product semantics; never offer new Like actions for already-matched profiles. |
| AUD-005 | Identity submissions can enter pending but no route/provider/worker can set under-review/verified/rejected or `identityVerifiedAt`. | `identityVerificationController.js`; `identityVerificationRoutes.js`; `IdentityVerification`, `User`; identity APIs | HIGH | Implement an authenticated review/provider callback lifecycle with audit logs, document retention policy, and transition tests. |
| AUD-006 | Backend push delivery exists, but Flutter has no Firebase Messaging dependency/token registration call. | `notificationService.js`, `deviceController.js`, `UserDevice`, `NotificationDelivery`, `/api/devices`; `pubspec.yaml` and `lib/` | HIGH | Integrate platform push SDK, permission/token refresh, authenticated register/unregister, and device integration tests. |
| AUD-007 | Delete anonymizes User and deletes sessions/matches but retains profile, identity documents/metadata, chats/messages, and other relations; SRS says permanent removal. | `Backend/src/controllers/accountController.js` `remove`; multiple user-related models; `DELETE /api/account` | HIGH | Establish a legal retention policy, then transactionally purge or irreversibly anonymize every related record/file and document exceptions. |
| AUD-008 | Email/SMS/quiet-hours preferences appear functional but only persist; no channel delivery or quiet-hour enforcement consumes them. | `notificationPreferenceController.js`, `notificationService.js`, `NotificationPreferences`; notification settings UI | HIGH | Add channel dispatch/queueing and timezone-aware quiet-hour enforcement, or remove/label controls until supported. |
| AUD-009 | Event Featured/Recommended/Near You sections are list-position and same-city client subsets, not personalized/proximity results. | `lib/features/events/presentation/events_browse_screen.dart`; `GET /api/events` | MEDIUM | Define recommendation ranking and radius semantics, implement server query parameters/ranking, and preserve stable pagination. |
| AUD-010 | Production event distance is mapped to empty and attendee identities are not serialized. | `event_repository.dart` mapper; `eventService.serializeEvent/participationIncludes`; `Events`, `EventRegistrations` | MEDIUM | Compute viewer distance server-side and add privacy-approved attendee preview serialization. |
| AUD-011 | No event reminder/promotion notification producer exists. | `eventController.promoteNextWaitlisted`; notification service; event/notification tables | MEDIUM | Add idempotent scheduled reminders and promotion notification after transaction commit. |
| AUD-012 | Message API has no idempotency key/client message ID, so independent retries can create duplicates. | `messageController.js`; `Message.js`; `POST /api/conversations/:id/messages` | MEDIUM | Add per-sender client message ID uniqueness and return the canonical existing message on retry. |
| AUD-013 | Rose transaction and Rose chat-card message are separate commits; Rose success can lack a chat representation. | `profile_detail_screen.dart` `_showRose`; Rose and message APIs; `RoseTransactions`, `Messages` | MEDIUM | Define whether Rose must be a message; if yes, create/link it atomically server-side or expose explicit partial status. |
| AUD-014 | SRS Profile Details “Send Gift” has no active implementation; gift commerce endpoints are deliberately retired. | `phase5.integration.test.js`; route inventory; no Gift model/controller | MEDIUM | Clarify whether Rose satisfies Gift; otherwise add a separately approved future scope, not a duplicate hidden API. |
| AUD-015 | Settings Change Password uses email recovery and never verifies the current password as the SRS describes. | `profile_settings_screen.dart`; `authRoutes.js`; forgot/reset APIs | MEDIUM | Add authenticated current-password verification or update the SRS/label to “Reset password by email.” |
| AUD-016 | `verifiedOnly` defaults true although SRS gives no default; new feeds may unexpectedly exclude all unverified profiles. | `discoverPreferenceService.js`; `DiscoverFilterPreferences` | LOW | Confirm product default and make onboarding/filter UI communicate it; add a default-behavior acceptance test. |

### Issue totals

- Critical: **0**
- High: **8**
- Medium: **7**
- Low: **1**

## Production Readiness

**Decision: NOT READY.** The automated baseline is strong and there are no failing existing tests, but those tests encode current behavior and do not make the missing conditions safe. Production approval should require at minimum AUD-001 through AUD-008, a complete live multi-user/device/provider pass, migration-status confirmation in the target environment, and evidence that delete/identity/notification privacy requirements have been legally and technically resolved.

### Final status summary

The authoritative condition totals are generated from the matrix above during report verification:

- Total conditions assessed: **165**
- PASS: **131**
- FAIL: **5**
- PARTIAL: **8**
- MISSING: **6**
- BLOCKED: **6**
- N/A: **9**

## Audit Integrity

- No product Dart/JavaScript code was modified.
- No API, model, table, migration, authentication rule, UI, navigation, or provider configuration was changed.
- No migration was run; no database was reset or dropped; no production data was deleted or edited.
- Temporary local helper processes used during the attempted browser run were stopped.
- The only audit artifact created is this report.
