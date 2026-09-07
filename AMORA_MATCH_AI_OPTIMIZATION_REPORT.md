# AMORA AI – Match Engine, AI Suggestions & App Optimization Report

**Project name:** AMORA AI  
**Application type:** Dating / matchmaking application  
**Assessment type:** Technical and product implementation review  
**Assessment scope:** Repository inspection only, including Flutter client, Node/Express API, Sequelize models/migrations, tests, and existing project documentation. No runtime production environment, database contents, deployment settings, or third-party-provider console was available; those items are marked **NEEDS VERIFICATION**.

## Executive summary

**Overall readiness: PARTIALLY IMPLEMENTED.** AMORA has a meaningful rule-based Discover engine, not merely a static UI: it requires completed onboarding, excludes the viewer, excludes users with an action history, requires active accounts, hides both sides of blocks, applies age and many profile filters, applies reciprocal gender-interest preferences when configured, calculates deterministic compatibility, pages the result, and persists passes/likes/super likes. Mutual likes create a match and direct conversation transactionally.

The principal launch gap is that the eligibility and swipe paths are not fully equivalent. `GET /api/discover/feed` applies discovery preferences and score filtering, while `POST /api/discover/swipe` verifies only active/onboarded/not-blocked status. A client could attempt a like against an otherwise preference-ineligible profile by ID. Location distance is represented as a user preference and query parameter but no latitude/longitude or radius calculation appears in the inspected feed query. Reports are stored and rate-limited but do not currently suppress a reported profile from Discover. AI-branded surfaces are frontend deterministic/profile-driven experiences; no server-side LLM, embedding, vector search, AI match endpoint, AI cache, or AI provider integration was found.

The app already has several practical foundations: authenticated API calls with timeouts, Discover pagination, a swipe limiter, report limiter, image resize hints and fallback states, secure-token storage, Socket.IO dependencies, message/conversation indexes, migrations, and substantial backend/Flutter test coverage. It is not yet production ready because safety eligibility parity, location, observability, cache strategy, and production AI controls need hardening.

### Readiness at a glance

| Area | Status | Assessment |
|---|---|---|
| Match Engine | **PARTIALLY IMPLEMENTED** | Sound deterministic baseline; location and server-side eligibility parity need work. |
| AI Suggestions | **PARTIALLY IMPLEMENTED** | AI-labelled UI and explainable deterministic compatibility exist; operational AI/ML is not found. |
| App Optimization | **PARTIALLY IMPLEMENTED** | Good client primitives and pagination; production caching, observability, query profiling, and image delivery need verification/work. |

**Main technical risks:** swipe eligibility bypass, no coordinate-based distance enforcement, JSON-heavy filter queries at scale, offset pagination under changing data, and no verified production monitoring/cache layer.  
**Main product risks:** calling deterministic suggestions “AI” without clear disclosure, profile repetition after rewind/unmatch semantics, no evidence that reports affect recommendations, and a default `verifiedOnly: true` setting that may exhaust supply in new markets.  
**Recommended order:** 1) close P0 eligibility/safety gaps, 2) make rule-based ranking/location reliable and observable, 3) optimize Discover/image/chat paths, 4) add AI only as a bounded re-ranker or generation service with fallback.

## Evidence base and status conventions

**IMPLEMENTED** means code and its path were directly observed. **PARTIALLY IMPLEMENTED** means an implemented capability has material gaps. **NOT FOUND** means the inspected repository has no implementation evidence. **NEEDS VERIFICATION** means it requires runtime, infrastructure, or data inspection. **NOT APPLICABLE** means the concept is not represented by the current product architecture.

Key evidence includes:

- Backend discovery: `Backend/src/controllers/discoverController.js`, `Backend/src/routes/discoverRoutes.js`, `Backend/src/services/discoverPreferenceService.js`.
- Compatibility: `Backend/src/utils/computeCompatibilityScore.js`, `Backend/src/services/compatibilityService.js`.
- Safety and relationships: `Backend/src/services/accessControlService.js`, `Backend/src/controllers/blockController.js`, `Backend/src/controllers/reportController.js`, `Backend/src/controllers/matchController.js`.
- Data: `Backend/src/models/User.js`, `OnboardingProfile.js`, `DiscoverAction.js`, `Match.js`, `Block.js`, `Report.js`, `Conversation.js`, and `Message.js`; migrations under `Backend/src/migrations/`.
- Flutter Discover: `lib/features/discover/presentation/browse_grid_screen.dart`, `discover_screen.dart`, `discover_action_controller.dart`, and `data/discover_api_service.dart`.
- Flutter AI surfaces: `lib/features/matches/presentation/matches_screen.dart`, `lib/features/match/presentation/why_we_matched_screen.dart`, and `lib/features/ai_coach/presentation/ai_icebreakers_screen.dart`.
- Image/rendering: `lib/core/widgets/amoraa_adaptive_image.dart`; app dependencies: `pubspec.yaml`, `Backend/package.json`.

## Match Engine – Current State

### Actual current flow

1. Flutter requests `/api/discover/feed` through `DiscoverApiService`, with a 10-second client timeout.
2. `discoverController.getFeed` requires a completed onboarding profile.
3. It loads saved/runtime discovery preferences, builds candidate filters, excludes the viewer and all targets in the viewer's `DiscoverActions`, restricts `User.accountStatus` to `active`, and uses `notBlockedUserSql` to exclude either direction of blocking.
4. It requires the candidate's completed onboarding profile; applies age, city and optional profile/lifestyle filters; then applies viewer interest-in gender and candidate reciprocal `interestedIn` where present.
5. It computes a deterministic SQL score based on overlap in interests, goals, languages, and valued qualities; applies `minScore`, sorts descending, and returns `limit + 1` records with page metadata.
6. A pass, like, or super like upserts `DiscoverAction`. A reciprocal like/super-like creates a unique normalized-pair `Match` and direct `Conversation` inside a transaction.

### Discovery/input coverage

| Capability | Status | Evidence / current behavior |
|---|---|---|
| Same account exclusion | IMPLEMENTED | `discoverController.getFeed` excludes `User.id == req.user.sub`; `swipe` rejects self-action. |
| Completed profile | IMPLEMENTED | Viewer and candidate require `onboardingCompleted: true`. |
| Active/deactivated/deleted account handling | IMPLEMENTED | Feed and swipe target require `accountStatus: 'active'`; model has active/deactivated/deleted. No `banned` enum was found. |
| Blocks, both directions | IMPLEMENTED | SQL anti-join in feed and `areUsersBlocked` in swipe; matches also use `visibleMatchSql`. |
| Reports | PARTIALLY IMPLEMENTED | `Report` storage, dedupe and 5/hour rate limit exist; no Discover exclusion on report was found. |
| Already liked/passed/super-liked | IMPLEMENTED | Feed excludes every target in viewer's `DiscoverActions`. |
| Already matched | IMPLEMENTED indirectly | Matching follows a like action, which is excluded from future feed. No separate Match anti-join is present. |
| Rewind | IMPLEMENTED with risk | Last action is deleted, so that profile can return immediately; no cooldown policy exists. |
| Gender/interested-in compatibility | IMPLEMENTED | Viewer `interestedIn` and candidate reciprocal `interestedIn` are server-side predicates. |
| Sexuality | PARTIALLY IMPLEMENTED | It is an optional candidate field/filter but is not used as reciprocal compatibility logic. |
| Age | IMPLEMENTED | Birth-date range is enforced in the feed. |
| City | IMPLEMENTED | Exact case-insensitive candidate city filter. |
| Geographic distance | NOT FOUND | Preference field/query validator exists, but `maxDistanceKm` is not used by `buildProfileWhere`; profile has city, not latitude/longitude. |
| Verification | IMPLEMENTED as optional filter | `verifiedOnly` maps to `identityVerifiedAt`; default is true in preference service. |
| Activity | IMPLEMENTED as optional filter | `onlineNow` uses `lastActiveAt` and a runtime/configurable window. |
| Interests, values, lifestyle/goals | IMPLEMENTED | Filter predicates and score use profile JSON fields. |
| Prompts | PARTIALLY IMPLEMENTED | `hasPrompts` filters JSON length; prompts are not score inputs. |
| Premium/subscription | NOT APPLICABLE to candidate ranking | Subscription is serialized/included but not a feed rank factor. |
| Behavioural ranking | NOT FOUND | Actions are used for exclusion/match creation, not scoring; no views/dwell/chat outcome ranker found. |

## Match eligibility filter

| Eligibility Rule | Current Status | Evidence | Risk | Recommendation |
|---|---|---|---|---|
| Exclude self | IMPLEMENTED | Feed and swipe controller | Low | Retain unit/integration test. |
| Active account only | IMPLEMENTED | `User.accountStatus: 'active'` | Medium: no banned state | Add explicit suspension/ban state and a centralized visibility predicate. |
| Completed profiles only | IMPLEMENTED | `OnboardingProfile.onboardingCompleted` | Low | Define minimum public-profile completeness separately from onboarding completion. |
| Two-way block | IMPLEMENTED | `accessControlService` | Low | Reuse same service in every recommendation and direct-profile route. |
| Reported target policy | PARTIALLY IMPLEMENTED | Reports do not feed candidate eligibility | High safety/UX | Define whether reporter hides target immediately; usually remove from reporter's feed while keeping moderator workflow. |
| Viewer preferences | IMPLEMENTED in feed | `discoveryPreferenceClauses` | **P0:** absent from swipe endpoint | Centralize and execute eligibility on both feed and actions. |
| Candidate reciprocal preference | IMPLEMENTED in feed | Candidate `interestedIn` predicate | **P0:** absent from swipe endpoint | Same centralized eligibility check. |
| Age | IMPLEMENTED in feed | Birth-date predicate | **P0:** absent from swipe endpoint | Enforce pair eligibility at action time too. |
| Distance | NOT FOUND | No coordinates/calculation | **P0:** misleading distance filter | Add backend geospatial eligibility before launch. |
| Previous action exclusion | IMPLEMENTED in feed | `DiscoverActions` anti-join | Low | Add timestamp/cooldown semantics rather than deleting history on rewind. |
| Matched exclusion | PARTIALLY IMPLEMENTED | Indirectly via action history | Medium | Add explicit Match/active conversation exclusion for defensive correctness. |
| Privacy/hidden discoverability | NOT FOUND | No discoverability flag found | High | Add an account/profile discoverability policy and enforce it centrally. |

## Hard filters versus ranking

AMORA already has the beginning of this separation. Current hard filters include status, completed onboarding, blocks, age, viewer/candidate gender-interest conditions, past action exclusion, and optional user filters. Current ranking is deterministic compatibility score: a base of 55 plus capped overlap contributions for interests, relationship goals, languages, and valued qualities. The score is implemented by `computeCompatibilityScore.js`/`compatibilityScoreSql`, not AI.

Recommended production order:

```text
Eligibility Service (status, consent, age, block, report, privacy, distance)
        ↓
Candidate Generation (geo/indexed coarse candidates, keyset cursor)
        ↓
Rule-Based Match Scoring (transparent factors)
        ↓
Optional AI/ML Re-ranking (never expands candidate set)
        ↓
Safety and Diversity Re-check
        ↓
DiscoverCard DTO + cursor
```

## Recommended Match Score Architecture

This is a proposal, not current behavior. It preserves the four profile fields AMORA actually stores and avoids claiming certainty.

| Factor | Proposed weight | Current support |
|---|---:|---|
| Mutual preference compatibility | Gate, not score | Stronger server-side enforcement required at swipe time. |
| Relationship-goal overlap | 20% | Implemented data and score input. |
| Interest overlap | 20% | Implemented data and score input. |
| Values/lifestyle/communication style | 15% | Implemented data; lifestyle/communication not presently in SQL score. |
| Location relevance | 15% | City exists; precise distance missing. |
| Profile quality/completeness | 10% | Data exists; separate score not found. |
| Recent meaningful activity | 8% | `lastActiveAt` exists; only binary online filter now. |
| Behavioural signal | 7% | Event storage incomplete for this purpose; future only. |
| Optional AI re-ranking | 5% | Not found; do not enable until adequate consented outcome data exists. |

Expose reasons such as shared goals/interests, never a “perfect partner” claim. `compatibilityService.js` already returns an appropriate disclaimer: a deterministic profile-based estimate, not relationship certainty.

## Location-based matching

**Current status: NOT FOUND for actual distance calculation.** `OnboardingProfile` stores `city` and `preferredDistance`; `DiscoverFilterPreference` stores `maxDistanceKm`; route validation accepts `maxDistanceKm`. The inspected feed query does not consume it, and no latitude, longitude, geohash, spatial index, current-location service, or Haversine/database-distance expression was found. The UI may show a textual `distance`, but that is not evidence of backend geographic filtering.

Before public MVP, obtain consented current/last-known coordinates with accuracy/timestamp, store a coarse geospatial representation, and query on the server using a bounding box plus indexed distance calculation (or a database geospatial type). Fall back to city-only discovery with an honest label when coordinates are unavailable. Do not calculate eligibility solely on the Flutter client. Keep exact coordinates private; round/display distance and expire stale location.

## Discovery preferences

Current preferences include age, city, height, hometown, dating intentions, lifestyle tags, education, profession, community, religion, languages, pronouns, sexuality, qualities, talking hours, love languages, communication styles, smoking/drinking/weed, verified-only, online-now, prompts, and event interest. They are persisted in `DiscoverFilterPreference`, controlled by runtime admin configuration, and enforced backend-side for the feed.

Important exception: frontend `DiscoverApiService.getFeed` only transmits page/limit/communication styles; other saved preferences are server-loaded, which is correct. However the action endpoint does not revalidate the filter/pair policy. Treat an ID submitted to `/swipe` as untrusted and recalculate discoverability server-side.

## User interaction signals and repetition prevention

| Signal | Storage/use now | Safe future use |
|---|---|---|
| Pass/like/super like | `DiscoverAction`; excludes from feed; mutual like creates match | Use aggregated, rate-limited preferences, never as a sensitive-attribute proxy. |
| Match/unmatch | `Match`; direct conversation | Measure match-to-conversation conversion, not raw swipes alone. |
| Block/report | `Block`/`Report`; blocks exclude; reports do not | Safety gate; never use as a desirability signal. |
| Rose | `RoseTransaction` and route exist | Keep entitlement/rate checks separate from rank. |
| Saved profile | `SavedProfile` model exists | Candidate intent indicator only with consent and retention policy. |
| Views, dwell time | NOT FOUND | Add only with transparent analytics/privacy controls. |
| Chat initiation/activity | Messages/conversations exist; no rank usage found | Aggregate post-match engagement, avoid reading private content. |

Current behavior prevents the viewer from seeing any already-actioned target. The practical defect is rewind: deleting the most recent action permits immediate rediscovery. Recommended policy: retain an action ledger; hide passes for 30–90 days, only reintroduce an eligible person after a controlled cooldown or substantive profile update, never reintroduce blocks, and make undo a short server-authorized grace window rather than history deletion.

## Cold Start Matching, fairness, and abuse protection

For a new user, use hard filters first, then city/geo relevance, reciprocal preference, goals, interests, profile quality, and recent activity. Do not require AI. For a new region with few candidates, expand radius only with clear consent, then broaden low-priority filters; never relax age, blocks, account status, or reciprocal preferences. For low-data profiles, lower confidence/explanation detail, not safety standards.

Apply diversity after relevance: cap repeated exposure of the same profile type, ensure recent eligible new users get bounded exploration traffic, rotate similarly scored candidates, and measure exposure distribution. Do not infer protected/sensitive attributes beyond fields users deliberately supply for matching.

Current abuse controls include a 120-swipes/5-minutes per-user limiter, report limiter, photo limiter, auth/OTP limits, and transactional mutual-match creation. **PARTIALLY IMPLEMENTED** protections should add daily free/premium action quotas, device/session anomaly signals, duplicate-account review, bot/scanning detection, IP/device risk controls, server-side entitlement checks for premium actions, and audit alerts. Keep false-positive review paths.

## AI Suggestions – Current Implementation

**Status: PARTIALLY IMPLEMENTED as deterministic/profile-driven product surfaces; NOT FOUND as an operational LLM/ML system.** Repository search found no OpenAI/Anthropic/Gemini/LLM SDK, prompt service, AI API route, embeddings, vector database, model worker, AI cache, or provider credentials/configuration in the inspected source/dependencies.

The “AI Matches” screen (`matches_screen.dart`) presents match cards, threshold/filter UI, loading/error/offline/locked states, and compatibility reasons. Compatibility evidence comes from deterministic profile overlap calculated by backend services. `why_we_matched_screen.dart` appropriately describes a compatibility estimate. `ai_icebreakers_screen.dart` generates suggestions locally from supplied profile arguments; it does not call an AI service. The app has an `iceBreaker` profile field, which is user profile content, not generated AI.

### AI Matches assessment

| Question | Finding |
|---|---|
| Source of suggestions | Existing match/profile presentation plus deterministic compatibility data; no AI recommendation endpoint found. |
| Actual AI/ML | NOT FOUND. |
| Personalized profile factors | PARTIALLY IMPLEMENTED through deterministic compatibility inputs. |
| Backend ranking | IMPLEMENTED for Discover, deterministic only. |
| Compatibility score | IMPLEMENTED deterministic, explainable. |
| Cache/dynamic refresh | NEEDS VERIFICATION / no dedicated AI cache found. |
| Blocked/matched safety | Discover is blocked-aware; AI screen's data source should be explicitly verified against same eligibility service. |
| Product-label gap | High: “AI Matches” may overstate present implementation unless UI clearly says deterministic profile-based recommendations. |

## Recommended AI recommendation architecture

Use AI only after the existing hard-filter candidate set is produced:

```text
Eligibility filtering → candidate generation → deterministic ranking
→ optional constrained AI/ML re-ranking → safety re-check → diversity adjustment
→ explainable response and cache
```

AI must never bypass blocks, report/safety restrictions, age, account status, mutual discovery preferences, location, or privacy/discoverability settings. Initially, an AI service should receive a minimized, structured profile summary—not raw chats, contact details, tokens, payments, or exact location—and return validated JSON containing a bounded score adjustment and permitted explanation keys. A standard ranked response is the fallback.

### AI compatibility and explanations

Current `compatibilityService` reasons cover goals, interests, languages, values, communication style, and lifestyle overlap. Keep the wording as “recommendation signal”/“compatibility estimate.” Suitable examples: “You both enjoy travel and outdoor activities” and “You share similar relationship goals.” Do not claim emotional prediction, destiny, or guaranteed fit.

### AI Icebreakers, safety, cost and fallback

Current icebreakers are local deterministic suggestions. If provider-backed generation is introduced, add profile-context minimization, moderation of input/output, prompt-injection resistant structured prompts, schema validation, 5–10 second timeout, one retry maximum, request deduplication/idempotency, per-user and daily quotas, and audit-safe telemetry that excludes raw private content.

| AI Feature | Current status | Frequency/caching | Cost risk | Recommendation |
|---|---|---|---|---|
| AI Matches | UI label only / deterministic source | No dedicated cache found | Low now; high if LLM per feed request | Cache candidate results; use deterministic fallback. |
| Compatibility explanations | Deterministic | Computed from profile fields | Low | Preserve explainable local/backend logic; optionally cache by profile-version pair. |
| Icebreakers | Local template-style generation | No provider/cache found | Low now | Rate limit and cache provider outputs by profile pair if AI is added. |
| Dating coach | UI exists; provider integration not found | NEEDS VERIFICATION | Potentially unbounded | Do not launch paid/provider generation without quotas and moderation. |

If AI fails: return normal ranked recommendations for AI Matches; show manual curated/template icebreakers plus Retry; hide an AI explanation and retain the standard compatibility factors. AI must not be a single point of failure.

## AI Safety & Privacy

No external AI transmission was found, so no current provider-data exposure is evidenced. Before integration, prohibit sending passwords, OTPs, auth tokens, payment details, unredacted private conversations, contact data, or precise coordinates. Establish provider DPA/retention review, consent/notice, regional transfer assessment, moderation and response validation, prompt-injection boundaries, token/PII redaction, timeout/fallback, and deletion/retention behavior. Log request metadata and safety outcomes, not sensitive prompt bodies by default.

## App Optimization – Current State

### Flutter

**Implemented foundations:** feature-oriented Dart layout; `ChangeNotifier` Discover action controller; `ListView.builder`/`GridView.builder` usage in inspected discovery/match UI; skeleton, empty, retry and error states; `const` use throughout; shared `AmoraaAdaptiveImage`; `ResizeImage.resizeIfNeeded`, `cacheWidth/cacheHeight`, image placeholders/fallback/retry, `RepaintBoundary`, and disposal of its image-stream listener. Discover client requests 10-item pages and has a 10-second timeout.

**Risks/gaps:** no package-level disk image cache/CDN integration is declared; `NetworkImage` relies on Flutter in-memory caching only. Image source may be a data URI/memory image, which is costly if persisted or repeatedly decoded. `DiscoverActionController` holds an unbounded in-memory history for the screen session. The inspected client call does not demonstrate retry/backoff orchestration or request coalescing. Full screen performance needs profile-mode measurement; static inspection cannot establish rebuild, GPU, memory, or startup metrics.

### API and database

Discover returns a lightweight serialized public profile and pagination metadata, which aligns with the target DTO pattern. It uses offset pagination (`page`, `offset`), however, so inserts/updates can cause boundary duplicates or gaps during browsing. Compatibility and rich filters use SQL functions over JSON fields (`LOWER`, `JSON_CONTAINS`, `JSON_SEARCH`), which can become non-sargable and expensive as the candidate population grows. `limit` is bounded to 30.

Models include useful indexes: unique `DiscoverActions(actorUserId,targetUserId)`, unique match pair, unique block pair, conversation `pairKey`, conversation last-message ordering, and message indexes by conversation/id. A baseline/index migration exists (`202608110001-add-phase1-query-indexes.js`) plus later targeted migrations. Exact applied indexes and query plans are **NEEDS VERIFICATION** against the target database; no Redis/cache/queue dependency or worker implementation was found.

### Images

The client has good rendering resilience but no evidence of server-side thumbnail derivatives, CDN, cache-control headers, signed URLs, format conversion (WebP/AVIF), or preload policy. The likely largest risk is full-resolution profile photos on multiple Discover cards. Serve fixed card/avatar sizes, responsive derivatives, modern formats, explicit cache headers, a CDN/object storage origin, placeholders, and preload only the next 2–3 eligible cards. Fetch full gallery media only after profile open.

### Chat

Backend conversations/messages and Socket.IO are present. Message schema has appropriate conversation-indexed ordering; realtime hub usage is present in mutual-match handling. Current chat pagination, client local cache behavior, reconnect logic, duplicate-event idempotency, and media delivery performance require dedicated runtime/API inspection; do not assume them from dependencies alone. Treat message listing pagination and stable cursors as a launch-scale requirement.

### Pagination and caching status

| Surface | Status | Finding |
|---|---|---|
| Discover | IMPLEMENTED | Page/limit, `limit + 1`, hasMore/nextPage. Replace offset with cursor/keyset at scale. |
| Matches | NEEDS VERIFICATION | Backend list observed without visible pagination in `matchController.list`. |
| Messages | NEEDS VERIFICATION | Indexed data model; inspect route/controller behavior in runtime follow-up. |
| Chat list | NEEDS VERIFICATION | Models/repositories exist; page strategy not established in this inspection. |
| Likes/super likes/roses | PARTIALLY IMPLEMENTED / NEEDS VERIFICATION | Relationship routes/models exist; pagination should be verified endpoint by endpoint. |
| Notifications | NEEDS VERIFICATION | Route/model exists; pagination not established here. |
| Profile images | PARTIALLY IMPLEMENTED | Flutter memory cache hints/fallbacks; no durable/cache-delivery evidence. |
| Discover/AI result caching | NOT FOUND | No Redis/cache dependency or dedicated recommendation cache found. |

Cache static taxonomy/settings aggressively with versioning; cache short-lived candidate IDs/results only after safety revalidation; cache image derivatives with immutable URLs. Do not aggressively cache account status, block/report state, live presence, permissions, balances, unread counts, or exact location.

## Backend scalability, monitoring, and failure handling

The backend is an Express/Sequelize/MySQL application with routes/controllers/services, migrations, validation, Helmet/CORS dependencies, rate limiting, Socket.IO, and a substantial Node test suite. This is a workable MVP architecture. **NOT FOUND:** background job queue, distributed cache, structured observability/APM stack, production connection-pool settings confirmation, PM2/container orchestration evidence, or horizontal-scale/session-adapter configuration. These require infrastructure inspection.

Flutter screens include identifiable loading/error/empty states for Discover and AI Matches; Discover API translates timeout/network/auth failures into user messages. Image failures have fallback/retry. Exact no-internet handling, partial failure behavior, chat retry/offline queue, and server error telemetry remain **NEEDS VERIFICATION** with device and integration tests.

Monitor frontend startup/screen load/API latency/crashes/image errors; backend p50/p95/p99 latency, 4xx/5xx, DB query duration, pool saturation, CPU/memory, slow endpoints, queue lag if introduced, and Socket connection health; product Discover latency, feed exhaustion, repetition, like/match/conversation conversion, block/report rate, and AI engagement/acceptance. Do not optimize only swipe volume.

## Existing Match / AI / Optimization Improvements Already Present

- Server-side completed-profile, active-account, block, age, interest/gender preference, prior-action, optional verified/online/event eligibility in Discover.
- Deterministic and explainable compatibility score/reasons with a non-guarantee disclaimer.
- Transactional reciprocal-like match creation with unique pair records and conversation provisioning.
- Action, report, chat, upload, authentication, and payment rate-limit middleware.
- Validation via `express-validator`; account lifecycle and identity verification models/migrations.
- Discover pagination and bounded page size.
- Flutter API timeouts, typed result objects, loading/empty/error/retry UI states.
- Shared adaptive image component with resize hints, placeholder, fallback, retry, `RepaintBoundary`, and listener disposal.
- Conversation/message indexes and backend/Flutter tests, including `Backend/test/discover.integration.test.js`, `compatibilityService.test.js`, and numerous UI tests.

## Current versus target architecture

### Current architecture

Flutter calls Express endpoints directly using authenticated HTTP; Discover builds a Sequelize query over `Users`, `OnboardingProfiles`, `DiscoverActions`, `Blocks`, subscriptions, and optional event registrations. It calculates profile-overlap compatibility in SQL, serializes public profiles, and returns offset pages. Swipe writes the action then conditionally creates match/conversation. AI-labelled client screens consume deterministic/profile data and local suggestion logic.

### Recommended target architecture

Retain the current API/Flutter separation, but introduce logical services following existing backend conventions: `MatchEligibilityService`, `CandidateGenerationService`, `MatchScoringService`, `RecommendationService`, `BehaviorSignalService`, `RecommendationDiversityService`, `AISuggestionService`, and `RecommendationCacheService`. Start with services within the existing backend; only split workers/services when measured scale requires it. Use a cursor response, cache candidate IDs briefly, re-run safety eligibility before return/action, and put optional AI behind a feature flag and bounded provider adapter.

## Risk register

| Risk | Area | Severity | Current Evidence | Impact | Recommendation |
|---|---|---|---|---|---|
| Swipe does not apply full feed eligibility | Matching/safety | P0 | `swipe` checks only active/onboarded/block | Ineligible profile may be liked/matched by ID | Shared eligibility service used in feed and action. |
| Distance preference is not enforced | Matching/product | P0 | `maxDistanceKm` stored/validated but unused in feed query; no coordinates | Users can see distant profiles despite filter | Server-side geo fields/index/query and stale-location policy. |
| Reports do not hide/re-rank target | Safety | P1 | Report controller stores report only | Repeated unwanted exposure; safety trust loss | Immediate reporter-side suppression policy. |
| No hidden/discoverability control found | Privacy | P1 | No model/predicate evidence | Users may be shown without a privacy opt-out | Add discoverability state and enforce centrally. |
| “AI Matches” without AI backend | Product/trust | P1 | No provider/ML integration found | Misleading claim/compliance concern | Relabel clearly or implement constrained AI architecture. |
| JSON-function filtering | DB/performance | P1 | `JSON_CONTAINS/SEARCH/LOWER` in candidate query | Slow queries at scale | Measure EXPLAIN; normalize/index hot filters or precompute features. |
| Offset paging | Discover UX | P2 | `offset: (page-1)*limit` | Duplicates/gaps under concurrent updates | Cursor/keyset using score/tie-breaker/profile version. |
| No cache/queue/APM evidence | Scale/operations | P1 | Dependencies/source inspection | Latency/cost/outage blind spots | Add observability first; cache/queues based on measurements. |
| Full-size image risk | Flutter/network | P1 | NetworkImage; no CDN/derivatives found | Slow Discover, memory/bandwidth costs | Derivatives/CDN/cache headers/preload budget. |
| Rewind deletes action | Product | P2 | `action.destroy()` | Immediate profile repetition/data-loss semantics | Grace undo and cooldown ledger. |

## Recommended Changes Before MVP Launch

### MUST FIX BEFORE LAUNCH (P0: 2 findings)

1. Centralize pair eligibility and call it in both candidate feed and swipe/match creation: self, account status, completed profile, reciprocal preferences, age, blocks, reports policy, privacy, and location.
2. Either implement server-side geographic radius matching with consented coordinates or remove/disable the distance promise until it is truthful; city-only is acceptable when accurately presented.

### SHOULD FIX BEFORE SCALE (P1: 6 findings)

1. Define report-to-discovery suppression and discoverability/privacy controls.
2. Align AI labels with deterministic reality or introduce bounded provider-backed features with safety/fallback/cost control.
3. Profile/optimize JSON-heavy Discover queries; add only evidence-backed indexes or normalized hot fields after EXPLAIN.
4. Establish CDN derivatives, image cache policy, and Discover preload budget.
5. Add structured logs, tracing, metrics, alerts, database slow-query monitoring, and deployment/pool verification.
6. Add rate/entitlement/device-abuse controls beyond the current short-window limiter.

### POST-LAUNCH IMPROVEMENTS (P2: 2 findings)

1. Cursor pagination, action cooldown/re-entry policy, diversity controls, and controlled behavioural ranking experiments.
2. Optional AI/ML re-ranking after sufficient consented outcome data; never build a costly ML platform before that data exists.

## Implementation priority and roadmap

**Phase 1 – Matching reliability:** central eligibility service; correct geo/city policy; blocks/reports/privacy; action/match duplicate defense; stable pagination contract; tests for every disqualifier.

**Phase 2 – Compatibility ranking:** formalize existing interests/goals/languages/values score; add lifestyle/communication/profile quality/activity transparently; explanations and diversity limits.

**Phase 3 – AI suggestions:** truthful product copy first; optional AI Matches/explanations/icebreakers behind a provider adapter, feature flags, quotas, caching, moderation, fallback, and audit metrics.

**Phase 4 – Optimization:** Discover DTO/cursor, EXPLAIN-driven database work, image derivatives/CDN, short-lived safe caching, chat pagination/reconnect/idempotency, Flutter profile-mode tuning.

**Phase 5 – Scale and intelligence:** behaviour aggregation with consent, experiments, monitoring-led capacity work, ML re-ranking only when data quality and fairness controls justify it.

## Testing strategy

### Match engine

- Unit/integration tests: viewer never sees self; either-direction block; inactive/deleted/suspended/banned (after state exists); incomplete profile; reporter suppression policy; age; mutual preference/orientation policy; exact city and radius; prior pass/like/match; no duplicates across cursor/page boundary; action endpoint rejects every feed-ineligible target.
- Transaction/concurrency tests: simultaneous mutual swipes create one match and one conversation; repeated requests are idempotent; undo stays within permitted window.

### AI

- Provider unavailable, timeout, invalid JSON/schema, unsafe output, quota/rate limit, duplicate request, cache invalidation, no private data in outbound payload, and deterministic fallback tests.

### Optimization

- Profile-mode Flutter startup/Discover/image-scroll/memory tests; slow/failed image and offline tests; API p95 response budgets; DB EXPLAIN/load tests of representative dense filters; message/conversation cursor pagination; Socket reconnect/duplicate-message tests; cache correctness against blocks/status changes.

## KPI and technical metrics

Track profiles viewed/session, feed exhaustion, profile repetition, like rate, match rate, conversation start rate, reply rate, match-to-chat conversion, report/block rate, new-user exposure, AI suggestion engagement/acceptance, and cost per meaningful conversation—not swipe volume alone.

Track p50/p95/p99 API and Discover-query latency, error rate, DB query latency, connection pool saturation, cache hit rate, image load/error rate, crash-free sessions, memory, Socket reconnect rate, match creation latency, message-send latency, AI latency/failure/token/cost, and moderation/fallback frequency.

## Final checklist

- [x] Match eligibility inspected; full action-path parity remains P0.
- [x] Discovery preferences confirmed backend-enforced in feed; action revalidation is required.
- [x] Block handling verified in feed, swipe, and match visibility.
- [x] Duplicate recommendation action-history control verified; rewind cooldown is missing.
- [x] Deterministic match scoring reviewed.
- [x] AI Matches UI and underlying deterministic state reviewed.
- [x] AI fallback recommended.
- [x] AI privacy/cost controls reviewed; provider implementation not found.
- [x] Discover pagination verified.
- [ ] Chat pagination requires endpoint/runtime verification.
- [x] Image rendering/cache hints verified; delivery/CDN caching needs work.
- [x] API/database performance structure reviewed.
- [x] Database indexes reviewed from models/migrations; production application/plans need verification.
- [x] Error states reviewed from inspected Flutter components.
- [x] Monitoring plan documented.
- [x] MVP priorities defined.

# Founder / MD Technical Summary

AMORA already has the skeleton of a real dating product, not just screens: people can complete profiles, Discover candidates through backend rules, like/pass/super-like, make mutual matches, create conversations, block, and report. The matching recommendation today is a transparent rule-based score using profile similarities; it is not an AI model. That is a sensible MVP foundation.

The biggest match risk is that a person can be eligible in the swipe endpoint even when they would not be eligible in the Discover feed, and the distance setting is not actually calculated from location. Fix those first. The biggest AI risk is product trust: describe the current feature accurately or add real AI only with strict privacy, safety, spend limits, and a non-AI fallback. The biggest optimization risk is scale: image delivery and JSON-heavy discovery filters can become slow before the app has monitoring to show why.

For MVP, prioritize safe, reliable rule-based matching and truthful location handling. After launch, improve ranking, diversity, pagination, caching, and image delivery based on measured behavior. Advanced ML, embeddings, and personalized behavioural models can wait until AMORA has enough consented, high-quality outcome data.

---

**Report limitation:** conclusions are based on the checked-in repository. Production database state, real query plans, deployed environment variables, CDN/cache headers, provider accounts, telemetry, and live traffic require a separate authorized operational review.
