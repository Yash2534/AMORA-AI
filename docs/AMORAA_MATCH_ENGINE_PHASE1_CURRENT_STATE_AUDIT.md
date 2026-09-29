# AMORAA MATCH ENGINE — PHASE 1 CURRENT STATE AUDIT

Audit date: 2026-09-29  
Audited tree: current working tree on branch `main`  
Reference plan status: `AMORAA_MATCH_ENGINE_FINAL_COMPLETION_PLAN.md` is not present anywhere in the current repository. Findings below are therefore grounded in current source, migrations, tests, and the existing seed-report artifact only.

## 1. EXECUTIVE SUMMARY

Current Match Engine status: **PARTIAL / NOT COMPLETE**

Major completed areas:

- One central JavaScript compatibility engine with explicit weights, coverage, neutral missing-data behavior, bounded scores, explanations, and deterministic tie-breakers (`Backend/src/services/matchEngineService.js:1-84`).
- SQL-side eligibility, hard filtering, minimum-score filtering, stable normal-Discover ordering, and bidirectional block/existing-match/previous-action exclusions (`Backend/src/controllers/discoverController.js:76-205,207-320`).
- AI Matches reuses the same eligible candidate query, performs deterministic LOCAL reranking over the complete eligible set, then paginates (`Backend/src/controllers/discoverController.js:257-315`; `Backend/src/services/aiMatchProvider.js:38-65`).
- Active-account and completed-onboarding gates exist for viewers and candidates; deactivated/deleted users are excluded by `accountStatus = active` (`Backend/src/middleware/authMiddleware.js:16-29`; `Backend/src/controllers/discoverController.js:52-59,237-245`).
- Flutter normal Discover consumes server pages and supports page 2+, while preserving the order of returned profiles before optional local quick filters (`lib/features/discover/presentation/browse_grid_screen.dart:198-280,283-331`).

Major gaps:

- No user/profile latitude or longitude exists. `maxDistanceKm` and onboarding `preferredDistance` are stored but never used in eligibility; serialized distance is always `null`.
- Reciprocal gender interest is implemented, but reciprocal age, distance, and other dealbreakers are not.
- There are no profile visibility, discovery-disabled, incognito, paused-discovery, or hidden-profile fields/contracts enforced by the engine.
- Reports and Roses do not exclude candidates. Saves do not exclude candidates. Any DiscoverAction (Pass, Like, Super Like) does.
- Profile eligibility trusts persistent `onboardingCompleted=true` and `stage='complete'`; it does not revalidate required fields, photo count, or the separately calculated 100% profile-completion score.
- SQL and JavaScript scoring are intended to be equivalent but are not a single implementation: dirty/duplicate candidate list values are normalized differently.
- AI Matches Flutter fetches only the default first page and drops pagination metadata.

Highest-priority blockers:

1. Define one canonical eligibility/filter contract, including explicit safety/visibility/report policy and reciprocal rules.
2. Add canonical profile coordinates and real distance calculation before treating distance as a hard filter or exposing `near_you`.
3. Eliminate SQL/JS scoring divergence or prove equivalence through a shared normalized representation.
4. Make ranking/pagination snapshot-safe (or cursor-based), especially because actions mutate the eligible set between offset pages.
5. Add AI Matches pagination/load-more on Flutter and return/consume a complete pagination contract.

## 2. ACTUAL PIPELINE

### Normal Discover

`GET /api/discover/feed`  
→ `requireAuth` validates JWT, rejects deleted/deactivated users, validates token version, and updates `lastActiveAt` at most once per 30 seconds (`Backend/src/routes/discoverRoutes.js:13-15`; `Backend/src/middleware/authMiddleware.js:4-34`)  
→ route validators normalize `page`, `limit`, age, distance, score and booleans (`Backend/src/routes/discoverRoutes.js:14-15`)  
→ `discoverController.getFeed` (`Backend/src/controllers/discoverController.js:207`)  
→ `requireCompleted` loads `OnboardingProfile` and requires `onboardingCompleted` plus `stage === 'complete'` (`:25-59`)  
→ `discoverPreferenceService.filtersFor` loads admin runtime defaults, `findOrCreate`s `DiscoverFilterPreference`, normalizes stored ranges, overlays allowed request values, and resets disabled filters to defaults (`Backend/src/services/discoverPreferenceService.js:42-126`)  
→ optional `reset=true` deletes all of the viewer's Pass actions only (`Backend/src/controllers/discoverController.js:222-229`)  
→ `buildProfileWhere` builds age and saved hard filters; `discoveryPreferenceClauses` applies viewer gender interest and permissive reciprocal gender interest (`:76-165`)  
→ `User.findAll` applies self exclusion, every previous DiscoverAction, active-account status, bidirectional blocks, existing Matches, verified/online/event filters, completed-profile flags, hard profile filters, and SQL minimum score (`:231-281`)  
→ SQL orders by compatibility score descending then user ID ascending and applies offset/`limit + 1` before materialization (`:273-280`)  
→ queried SQL score is used, with `scoreCompatibility` only as fallback (`:283-290`)  
→ `serializePublicProfile` builds the public contract and deterministic compatibility explanation/coverage (`Backend/src/services/publicProfileService.js:20-78`)  
→ `{profiles, pagination}` response; no `total` (`Backend/src/controllers/discoverController.js:317-320`)  
→ Flutter `DiscoverApiService.getFeed` sends page/limit and maps pagination (`lib/features/discover/data/discover_api_service.dart:24-39,106-140`)  
→ `DiscoverScreen` delegates to `BrowseGridScreen` (`lib/features/discover/presentation/discover_screen.dart:4-11`)  
→ `_loadProfiles`/`_loadNextPage` preserve server order and append later pages (`lib/features/discover/presentation/browse_grid_screen.dart:198-280`)  
→ `_filteredProfiles` may locally filter by quick filters; `publicProfileFromJson` maps the candidate ID directly (`:283-331`; `lib/features/profile/data/public_profile_mapper.dart:44-132`)  
→ `DiscoverActionController` sends Pass/Like/Super Like with that user ID; View Profile receives the same `DummyProfile` (`lib/features/discover/presentation/discover_action_controller.dart:84-174`; `lib/features/discover/presentation/browse_grid_screen.dart:913-949`).

Saved filters are actually read/written by Flutter through `/api/me/preferences`, not `/api/discover/filters` (`lib/features/discover/data/discover_api_service.dart:178-210`; `Backend/src/routes/mePreferenceRoutes.js:7-9`). Both backend endpoints call the same preference service.

### AI Matches

`GET /api/discover/ai-matches`  
→ same `requireAuth` and feed validators  
→ middleware sets `req.aiMatches=true` and forces `req.query.surface='high_compatibility'` (`Backend/src/routes/discoverRoutes.js:16`)  
→ same `discoverController.getFeed`, viewer-completion gate, preference loading, candidate query, exclusions, reciprocal gender rule, hard filters, and minimum compatibility (`Backend/src/controllers/discoverController.js:207-281`)  
→ no SQL offset/limit is applied; all eligible rows are loaded (`:276-280`)  
→ `scoreCompatibility` produces JS factors/score/coverage for every eligible candidate (`:291-297`)  
→ `aiMatchProvider.rankCandidates` applies LOCAL AI fields and sorts by `aiMatchScore DESC`, `aiConfidence DESC`, numeric user ID `ASC` (`Backend/src/services/aiMatchProvider.js:38-65`)  
→ controller slices the globally ranked list for the requested page and serializes wrapper plus nested public profile (`Backend/src/controllers/discoverController.js:298-315`)  
→ Flutter `PhaseTwoApiService.aiRecommendations` calls the endpoint with no page or limit, maps only `recommendations`, and discards `pagination` (`lib/core/api/phase_two_api_service.dart:37-55,97-109`)  
→ `MatchesScreen._loadMatches` loads once; API items remain in server order (`lib/features/matches/presentation/matches_screen.dart:78-114`)  
→ UI applies a local default compatibility threshold and All/Best Match/Active Now/Verified filters (`:116-135`)  
→ View Profile uses `profile.id`; Message asks `ChatRepository` for a real conversation and handles `MATCH_REQUIRED` rather than treating recommendation ID as a conversation ID (`:719-756`).

## 3. ELIGIBILITY MATRIX

| Rule | Status | Enforcement Location | Notes |
|------|--------|----------------------|-------|
| Self exclusion | IMPLEMENTED | SQL, `discoverController.getFeed` (`:237-239`) | `User.id != viewer`.
| Active users only | IMPLEMENTED | SQL (`:239`) | Exact `accountStatus='active'`.
| Deleted users excluded | IMPLEMENTED | Auth middleware + SQL (`authMiddleware.js:18-23`; controller `:239`) | Immediate deletion also destroys the onboarding profile (`immediateAccountDeletionService.js:74-75`).
| Deactivated users excluded | IMPLEMENTED | Auth middleware + SQL | Viewer rejected; candidates fail active status.
| Incomplete profiles excluded | PARTIAL | SQL (`discoverController.js:80-86,263-270`) | Checks flags and age-bearing DOB, not current mandatory fields/photos/100% completion.
| Onboarding requirements | PARTIAL | Controller/SQL | Completion endpoint requires six items; feed only trusts flags.
| Age | IMPLEMENTED | SQL `birthDate` range (`:78-86`) | Viewer-selected/default range only; UTC date-boundary method.
| Viewer `interestedIn` | IMPLEMENTED | SQL (`:137-150`) | Gender synonyms supported; universal tokens supported.
| Reciprocal `interestedIn` | PARTIAL | SQL (`:152-163`) | Candidate null/empty preference is accepted; only gender reciprocity exists.
| Reciprocal age | NOT IMPLEMENTED | Not enforced | Candidate has no preferred-age fields in profile; candidate saved filters are not consulted.
| Reciprocal distance | NOT IMPLEMENTED | Not enforced | No profile coordinates; candidate preferences are not consulted.
| Reciprocal dealbreakers | NOT IMPLEMENTED | Not enforced | Only viewer filters are applied.
| Block viewer → candidate | IMPLEMENTED | SQL `NOT EXISTS` (`accessControlService.js:26-31`) | Both directions in one predicate.
| Block candidate → viewer | IMPLEMENTED | SQL `NOT EXISTS` | Both directions.
| Existing Matches | IMPLEMENTED | SQL subquery (`discoverController.js:234-243`) | Either pair orientation excluded.
| Previous Like | IMPLEMENTED | SQL DiscoverAction subquery (`:233,237-239`) | All action types excluded.
| Previous Pass | IMPLEMENTED | SQL DiscoverAction subquery | Reversible by rewind, reaction removal where applicable, or normal-feed `reset=true` for all passes.
| Previous Super Like | IMPLEMENTED | SQL DiscoverAction subquery | Same row can be upserted from Like to Super Like.
| Previous Rose | NOT IMPLEMENTED | Not enforced | `RoseTransactions` is absent from candidate query.
| Saved profiles | NOT APPLICABLE as exclusion | Not enforced | Save is a separate relationship; saved candidates remain eligible unless another exclusion applies.
| Reports | NOT IMPLEMENTED | Not enforced | Report creation does not create a block/action and `Reports` is absent from candidate query.
| Moderation restrictions | PARTIAL | Account lifecycle only | Admin moderation suspend/freeze maps to deactivation; no independent consumer moderation status is queried.
| Hidden profiles | NOT IMPLEMENTED | No model/API/engine field | No equivalent found.
| Discovery disabled | NOT IMPLEMENTED | No model/API/engine field | No equivalent found.
| Incognito | NOT IMPLEMENTED | Marketing/UI text only | No persistence or eligibility behavior found.
| Paused account/discovery | PARTIAL | Account deactivation only | Deactivated account is excluded; no separate discovery pause.
| Verified-only | IMPLEMENTED | SQL User field (`discoverController.js:245`) | Uses `identityVerifiedAt`, not signup `isVerified`.
| Online/recent activity | IMPLEMENTED as recent activity | SQL User field (`:246-250`) | Not realtime presence; configurable default five-minute window.
| Minimum compatibility | IMPLEMENTED | SQL score expression (`:270`) | Saved/request `minScore`, 0-100.
| Event filter | IMPLEMENTED | SQL `EXISTS` (`:251-255`) | Requires `EventRegistration.status='registered'`; `promoted` does not qualify.
| City, height, hometown, education, profession, community, religion, sexuality, habits, lists, prompts | IMPLEMENTED | SQL in `buildProfileWhere` (`:76-134`) | All are viewer-side hard filters when non-empty.
| `surface` variants | NOT IMPLEMENTED | Route validation only | Accepted values do not alter candidate query, ranking, or serialization.

## 4. PROFILE COMPLETION

The authoritative onboarding completion mutation is `onboardingController.complete` (`Backend/src/controllers/onboardingController.js:18`). It requires:

- `birthDate`
- `gender`
- at least one `interestedIn`
- at least one `relationshipGoals`
- `city`
- at least **2 photos**

It then writes both `onboardingCompleted=true` and `stage='complete'`. Profession, education, bio, interests, prompts, lifestyle, communication style, etc. are not required for onboarding completion.

Candidate-side Discover requires `onboardingCompleted=true`, `stage='complete'`, and a DOB inside the selected age range (`discoverController.js:80-86`). It does **not** call `calculateProfileCompletion`, re-count photos, or re-check the six fields. Photo deletion and profile editing also do not unset the completion flags. Consequently, a once-complete profile can remain Discover-eligible after falling below two photos or losing other required content.

The separate profile completion percentage (`Backend/src/services/profileCompletionService.js:19-35`) is a 100-point UI/own-profile metric:

- up to 2 photos: 15
- name/adult DOB/gender: 15
- profession/education: 10
- city/relationship goal: 10
- lifestyle Height/Languages/Religion: 15
- bio of at least 40 characters: 10
- up to 5 interests: 10
- another lifestyle item: 5
- at least one prompt: 10

That percentage is not used by backend Discover. Flutter gates its empty-state CTA through `requiredProfileComplete`, preferring server percentage `==100` (`lib/features/profile/data/local_profile_repository.dart:77-120`), but it still sends the feed request first and the backend's `requireCompleted` flag gate is authoritative (`browse_grid_screen.dart:198-233`). Thus backend onboarding completion and Flutter 100% completion are distinct rules.

## 5. ACCOUNT LIFECYCLE

Active: authenticated and eligible if other rules pass. Candidate query explicitly requires active status (`discoverController.js:237-245`).

Deactivated: auth middleware rejects the viewer with `ACCOUNT_DEACTIVATED`; candidate SQL excludes them. Deactivation preserves the `User` and `OnboardingProfile` and only changes status/time/token version plus session/device cleanup (`Backend/src/controllers/accountController.js:56-86`).

Deleted: auth middleware rejects the viewer and candidate SQL excludes the row. Current immediate deletion also archives minimal identity, destroys the onboarding profile and recommendation-related rows, anonymizes identity, and marks the user `deleted` (`Backend/src/services/immediateAccountDeletionService.js:19-124`).

Reactivated: `authController.reactivate` changes the same User row from deactivated to active, clears `deactivatedAt`, increments token version, and issues new tokens without recreating or modifying the profile (`Backend/src/controllers/authController.js:277-305`). Therefore an unchanged previously complete profile becomes eligible again. This is directly covered by `Backend/test/account-deactivation-reactivation.integration.test.js`.

Lifecycle compatibility status: **IMPLEMENTED for active/deactivated/deleted/reactivated states**, subject to the separate stale-completion-flag issue.

## 6. LOCATION

Coordinates: no `latitude`, `longitude`, or `locationUpdatedAt` exists on `User`, `OnboardingProfile`, onboarding/edit-profile APIs, serializer, or seed profiles. The only persisted coordinates found are on `Event` (`Backend/src/models/Event.js:11-12`).

Real distance: **not calculated**.

`maxDistanceKm`: persisted in `DiscoverFilterPreference`, accepted as 1-300 on Discover routes, and normalized/clamped to 1-300 by the preference service (`discoverFilterRanges.js:1-6`; `discoverPreferenceService.js:64-68`). `/api/me/preferences` validation nominally accepts 1-500, but service normalization clamps it to 300 (`discoverPreferenceValidation.js:20`). It is never referenced by `buildProfileWhere` or candidate eligibility.

`preferredDistance`: stored on `OnboardingProfile` with default 50 and onboarding range 5-200 (`OnboardingProfile.js:65-69`; `onboardingRoutes.js:12`). It is never read by the match engine.

City filtering: both. A non-empty saved city is a case-insensitive exact hard filter (`discoverController.js:89`), and city exact equality is also a 5-point compatibility factor (`matchEngineService.js:35`). Flutter presents multi-city selection but persists only `_cities.first` (`advanced_filters_screen.dart:443-461,1599`), so the API remains single-city.

`near_you`: `surface=near_you` passes route validation, but `getFeed` never reads `surface`; it has no behavioral effect.

Serializer distance: always `null` (`publicProfileService.js:46`).

Flutter distance: mapper supports numeric or string distance and Discover/profile/AI screens display it only when non-empty (`public_profile_mapper.dart:87-89`; `browse_grid_screen.dart:1380-1383`; `matches_screen.dart:1504,2221-2222`). With the current backend it is empty. The local Nearby quick filter also allows null-distance profiles through because it rejects only known distances over 50 (`browse_grid_screen.dart:283-297`).

Coordinate exposure: no user coordinates exist to expose. Event coordinates are outside the candidate profile contract.

Onboarding GPS: no; city text and preferred-distance slider only (`onboardingController.js:12`; Flutter `onboarding_api_service.dart:74-81`).

Edit Profile GPS: no; Flutter `location` maps to backend profile `city` (`profileController.js:66-75`).

Seed location: city/hometown only; factory/config/report contain no profile coordinates. Real distance tests cannot be created from the current profile schema without adding data fields.

Final location status: **NOT IMPLEMENTED for distance; PARTIAL for city-only location**.

## 7. FILTER CONTRACT

Unless noted, populated filters are viewer-only hard eligibility filters. String comparisons are trimmed at write/request boundaries and lowercased in SQL; list filters are comma-parsed for query overrides, lowercased/deduplicated for query construction, and use “contains any” semantics. Runtime admin configuration can disable a filter, in which case `filtersFor` replaces it with its runtime default (`discoverPreferenceService.js:122`).

| API field | Type / range | Enforcement and normalization | Reciprocal / scoring | Flutter UI |
|---|---|---|---|---|
| `minAge`, `maxAge` | int 18-99; defaults 18/45 | SQL DOB hard range; stored values bounded; min ≤ max validated | Viewer-only; not scored | YES |
| `maxDistanceKm` | int 1-300 effective; default 80 | Persisted and bounded, **not enforced** | Neither reciprocal nor scored | YES |
| `minHeight` | nullable int 137-213 effective | SQL casts candidate string height to decimal and applies `>=` | Viewer-only; not scored | YES |
| `city` | single string | SQL lowercase exact hard filter | Viewer-only; also exact 5-point score | YES, but UI selects multiple and sends first |
| implicit profile `interestedIn` | JSON string list | SQL gender synonym matching | Reciprocal only for gender; not scored | Onboarding/profile, no Discover filter control |
| `datingIntentions` | string list | SQL candidate `relationshipGoals` contains any | Viewer-only hard; relationship goals also 25-point score | YES |
| `sexuality` | string | SQL lowercase exact | Viewer-only | YES |
| `education` | string | SQL lowercase exact | Viewer-only | YES |
| `profession` | string | SQL lowercase exact | Viewer-only | YES |
| `community` | string | SQL lowercase exact | Viewer-only | YES |
| `religion` | string | SQL lowercase exact | Viewer-only | YES |
| `smoking`, `drinking`, `weed` | strings | SQL lowercase exact when selected | Viewer-only hard; each also 5-point exact score | YES |
| `languages` | string list | SQL JSON contains any | Viewer-only hard; also 10-point overlap score | YES |
| `pronouns` | string list | SQL JSON contains any | Viewer-only | YES |
| `qualities` | string list | SQL candidate `valuedQualities` contains any | Viewer-only | YES |
| `preferredTalkingHours` | string list | SQL JSON contains any | Viewer-only | YES |
| `loveLanguages` | string list | SQL JSON contains any | Viewer-only | YES |
| `lifestyleTags` | string list | SQL `JSON_SEARCH` over candidate lifestyle object, any | Viewer-only | YES |
| `communicationStyles` | approved enum list | SQL candidate scalar `communicationStyle IN (...)` | Viewer-only hard; scalar exact 10-point score | YES |
| `hasPrompts` | bool | SQL `JSON_LENGTH(prompts) > 0` | Viewer-only | YES |
| `verifiedOnly` | bool; service default true | SQL `User.identityVerifiedAt IS NOT NULL` | Viewer-only | YES |
| `onlineNow` | bool | SQL `lastActiveAt >= now-window` | Viewer-only | YES |
| `hasEventInterest` | bool | SQL registered-event existence | Viewer-only | YES |
| `minScore` | int 0-100; default 0 | SQL compatibility expression `>=` threshold | Viewer-only | YES (“Minimum AI score”) |
| `surface` | enum query | Validated only; ignored by engine | None | NO direct backend-surface request |
| `reset` | bool query | Normal Discover deletes viewer Pass rows; AI ignores reset mutation | Action-state mutation, not a filter | NO; current Flutter feed client never sends it |

The feed GET route permits direct request overrides only for page/limit, age, max distance, min score, communication styles, verified, online, event interest, reset, and surface (`discoverRoutes.js:14`). All other values must first be persisted via preferences. `HARD_FILTERS` declares distance and reported users but is not consumed by `getFeed`; this declaration does not make either enforced (`discoverPreferenceService.js:5,124-126`).

## 8. COMPATIBILITY ENGINE

Factors and weights are current as stated:

| Factor | Weight | Agreement | Missing-data behavior |
|---|---:|---|---|
| Interests | 35 | normalized set intersection / `max(viewerCount,candidateCount)` | unavailable unless both normalized lists non-empty |
| Relationship Goals | 25 | same list formula | unavailable unless both non-empty |
| Communication Style | 10 | trimmed lowercase exact match | unavailable unless both usable |
| Languages | 10 | same list formula | unavailable unless both non-empty |
| City | 5 | trimmed lowercase exact match | unavailable unless both usable |
| Smoking | 5 | trimmed lowercase exact match | unavailable unless both usable |
| Drinking | 5 | trimmed lowercase exact match | unavailable unless both usable |
| Weed | 5 | trimmed lowercase exact match | unavailable unless both usable |

Source: `Backend/src/services/matchEngineService.js:1-43`.

Normalization: strings are trimmed and lowercased; exact text `prefer not to say` becomes unavailable; arrays remove empty/declined entries and duplicates (`:5-13`). Other dirty values remain distinct strings.

Formula:

1. `availableWeight = Σ weight` for comparable factors.
2. `weightedValue = Σ(weight × agreement)`.
3. `rawScore = availableWeight ? 100 × weightedValue / availableWeight : 50`.
4. `coverage = availableWeight / 100`.
5. `score = round/clamp[0,100](50 + (rawScore - 50) × coverage)`.
6. Returned `rawScore` and `coverage × 100` are also rounded/clamped.

Unavailable factors are neutral because they contribute neither numerator nor available weight, and final coverage pulls sparse scores toward 50 (`:40-63`). No comparable data produces score 50, rawScore 50, coverage 0. Scores are rounded and clamped. A low-coverage profile can have a high raw score but cannot retain the same extreme final score: for example, one perfect 5-point factor yields about 53, while a perfect 35-point interest comparison yields about 68. List normalization is consistent inside the JS engine, but not fully consistent with SQL candidate-list handling (next section).

## 9. DUPLICATE SCORING PATHS

Finding: **MULTIPLE POTENTIALLY CONFLICTING IMPLEMENTATIONS**.

- Canonical JS: `scoreCompatibility` (`matchEngineService.js:27-63`).
- SQL clone used for filtering, ordering, and normal Discover response score: `compatibilityScoreSql` (`discoverController.js:168-205`).
- AI uses canonical JS factors/score (`aiMatchProvider.js:38-60`).
- `computeCompatibilityScore.js` is only a forwarding wrapper to the canonical JS engine, not a fourth formula.
- Flutter does not calculate compatibility; it maps server score. It locally sorts only injected preview fixtures in AI Matches (`matches_screen.dart:78-84`).

For clean normalized arrays, SQL and JS are designed to be mathematically equivalent and integration tests compare them. For dirty candidate arrays they can diverge: JS `normalise(candidateList)` removes duplicates and `prefer not to say`; SQL uses candidate `JSON_LENGTH(column)` as the denominator and does not normalize/deduplicate candidate elements before the length calculation (`discoverController.js:171-185`). The SQL numerator checks normalized viewer values with `JSON_CONTAINS`, while JS normalizes both sides. Thus duplicate candidate entries, declined values mixed into an array, and some malformed stored shapes can change SQL score/order/minScore without changing the JS AI score. Existing dirty-data tests cover nulls/declined/whitespace but do not establish equivalence for duplicate candidate list elements.

## 10. AI MATCH PROVIDER

Mode: **LOCAL**

Inputs: viewer profile, eligible candidate profile, and optionally a precomputed canonical compatibility object (`aiMatchProvider.js:38-40`). Only the eight canonical public structured factors are admitted. Bio/private/account/moderation data is not used.

Formula:

- `coverage = 100 × availableWeight / 100`
- `support = 100 × Σ(weight × agreement) / 100`
- `aiConfidence = round/clamp(0.8 × coverage + 0.2 × support)`; this is explicitly an evidence-support index, not probability.
- `aiMatchScore = round/clamp(compatibilityScore + round((coverage - 50) × 0.08))`
- `aiConfidenceLevel`: High ≥80, Medium ≥50, otherwise Low (computed but not serialized by the controller).
- `aiMatchLevel`: EXCELLENT ≥90, STRONG ≥80, GOOD ≥70, POTENTIAL ≥60, otherwise EXPLORATORY.

Highlights/reasons: up to three positive available factors, priority order relationship goals, communication style, interests, languages, smoking, drinking, weed, city. Highlights include uppercase type, label, and 0-100 strength. Shared display values are length/control-character constrained and sorted. If no reason exists, fallback is `Explore this profile to learn more about each other.` (`aiMatchProvider.js:9-60`).

Ranking: `aiMatchScore DESC`, `aiConfidence DESC`, numeric candidate user ID `ASC` (`:63-65`). Behavior is deterministic.

Eligibility boundary: AI receives only rows returned by the same `User.findAll` eligibility query. `rankCandidates` maps/sorts that array and has no database access or candidate creation, so it cannot reintroduce an excluded candidate (`discoverController.js:257-315`).

## 11. EXTERNAL AI

Status: **NOT IMPLEMENTED**.

`PROVIDER` is hard-coded to `LOCAL`; `configuredProvider()` always returns LOCAL and comments explicitly state no external provider is executable (`Backend/src/services/aiMatchProvider.js:3-7`). Repository search found no OpenAI, Anthropic/Claude, Gemini, Vertex, Bedrock, Azure OpenAI, or custom matching endpoint integration in the recommendation flow. The unrelated “Gemini” zodiac string is not an AI integration.

## 12. RANKING

Discover:

- Primary: SQL compatibility score descending.
- Secondary/final tie-breaker: `User.id` ascending.
- Deterministic: yes for a fixed database snapshot and clock (`discoverController.js:275`). Age and online thresholds are time-dependent eligibility inputs, not randomness.

AI Matches:

- Primary: `aiMatchScore` descending.
- Secondary: `aiConfidence` descending.
- Final tie-breaker: numeric candidate user ID ascending.
- Deterministic: yes (`aiMatchProvider.js:63-65`).

Randomness: no `Math.random`, `Random`, shuffle, or SQL RAND occurs in Discover/AI recommendation source. Randomness found elsewhere is test fixture identity, deterministic seed generation, realtime event IDs, and unrelated privacy ticket IDs—not ranking.

## 13. PAGINATION

Discover:

- Default page: 1.
- Default limit: 10.
- Maximum limit: 30; page maximum 100000 (`discoverRoutes.js:14`; controller `:213-214`).
- Filtering and ordering happen before SQL offset/limit. Query requests `limit+1`, slices to limit, and derives `hasMore`/`nextPage` (`discoverController.js:257-320`).
- `total`: not returned.
- Duplicate/skip risk: offset pagination is stable only for an unchanged eligible set. Swiping page-one candidates immediately removes them from the eligible query. A later `page=2` offset can therefore skip candidates shifted forward; concurrent profile/action/score changes can also create skips or duplicates. There is no snapshot/cursor.

AI Matches:

- Candidate pool: all currently eligible candidates; no 500-user cap (`discoverController.js:276-280`).
- Global ranking before pagination: YES.
- Default page/limit: 1/10; max limit 30.
- `hasMore` and `nextPage`: returned. `total`: not returned (`:298-315`).
- Every page request reloads, rescales, and reranks the full eligible set, so it has the same between-request mutation drift and increasing memory/CPU cost.

Flutter:

- Normal Discover explicitly sends page and default limit 10, stores `hasMore`/`nextPage`, and loads page 2+ (`discover_api_service.dart:106-140`; `browse_grid_screen.dart:198-277`).
- It frequently preloads the next offset page after a successful action (`browse_grid_screen.dart:769-795,898-902`), precisely when the server eligible set has just shrunk, creating a concrete skip risk.
- AI Matches sends neither `page` nor `limit`, discards pagination, stores no metadata, and has no load-more; only the default first ten recommendations are reachable (`phase_two_api_service.dart:97-109`; `matches_screen.dart:87-114`).

## 14. ACTION EXCLUSIONS

| Action | Discover | AI Matches | Enforcement | Duration / reversal |
|---|---|---|---|---|
| Like | Excluded | Excluded | Any viewer `DiscoverAction` target is excluded in SQL | Until action removed; `/api/me` reaction removal or rewind can delete it. Mutual Match may still exclude after removal. |
| Pass | Excluded | Excluded | Same | Rewind deletes latest action; normal `reset=true` deletes all viewer Pass rows. AI reset cannot mutate passes. |
| Super Like | Excluded | Excluded | Same | Until removed/rewound; action upsert can replace an existing action. |
| Rose | Not excluded | Not excluded | `RoseTransactions` not queried | Rose status is sent/reversed, but neither affects recommendations. |
| Save | Not excluded | Not excluded | `SavedProfiles` not queried | Unsave is reversible; save is intentionally separate from swipe state in current source. |
| Match | Excluded | Excluded | Match pair SQL subquery | While Match row exists. Unmatch removes Match, but original Like/Super Like actions normally continue to exclude. |

The generic rewind deletes the latest DiscoverAction, including Pass/Like/Super Like (`discoverController.js:432-446`). A block itself also hides both sides; unblocking may restore an existing Match from the direct conversation (`blockController.js:60-89`), which continues exclusion.

## 15. BLOCK / REPORT / SAFETY

- Blocks are two-way for visibility and action eligibility. `notBlockedUserSql` excludes either direction; `areUsersBlocked` does the same for individual actions (`accessControlService.js:12-31`).
- Blocking does not delete the Match in `blockController.create`; matches/conversations are hidden via block predicates. Unblocking can recreate a missing Match if a direct conversation exists (`blockController.js:30-89`).
- Reports validate an active target, optionally bind it to the reporter's two-party conversation, deduplicate same reason/target for 24 hours while open/reviewing, and persist status (`reportController.js:4-54`).
- A report alone does **not** block or exclude the reported candidate from Discover/AI Matches.
- Consumer `User.accountStatus` has only active/deactivated/deleted. There is no separate banned/suspended/moderation field. Admin safety “suspend/freeze” ultimately changes lifecycle status, so the engine sees it only through `accountStatus`.
- No additional safety-profile-hidden flag is present.

## 16. VISIBILITY

No consumer-profile model field, migration, API, Flutter setting contract, or engine condition was found for `isVisible`, `discoverable`, `hideProfile`, `incognito`, `paused`, `discoveryEnabled`, `showMe`, or equivalent. “Incognito” appears only in plan marketing/UI copy. Support copy claims visibility controls, but there is no corresponding backend implementation. Account deactivation is the only effective whole-account hiding mechanism.

Visibility status: **NOT IMPLEMENTED as a distinct feature**.

## 17. ONLINE STATUS

Online Now is **recent authenticated HTTP activity**, not socket presence. `requireAuth` updates `User.lastActiveAt` when at least 30 seconds stale (`authMiddleware.js:26-29`). The filter requires `lastActiveAt` newer than a runtime window; migration default is five minutes, admin-configurable from 1 to 60, with environment/default fallback five (`discoverController.js:246-250`; `adminDiscoverConfigurationService.js:5-15`; migration `202609010001-create-admin-discover-configuration.js:1-7`).

The public serializer nevertheless returns `status: null` for every candidate (`publicProfileService.js:53`). Therefore Flutter’s local Online/Recently Active quick filters and AI “Active Now” filter cannot identify server profiles even when backend `onlineNow=true` was used; those local filters compare display `status` strings (`browse_grid_screen.dart:292-305`; `matches_screen.dart:127-133`).

## 18. SERIALIZER CONTRACT

Discover `serializePublicProfile` returns (`Backend/src/services/publicProfileService.js:37-78`):

- `id` (stringified **USER ID**), gender/customGender, name, age, city, profession, education
- `distance` (`null`), `score`, `compatibilityScore`, `compatibilityCoverage`, `compatibilityReasons`, structured `compatibility`
- first relationship goal as `intent`, `status` (`null`), bio, interests
- `imageUrl`, `gallery`, languages, verification string, premium
- lifestyle, promptAnswers, religion, community, height, smoking, drinking, weed, hometown
- valuedQualities, pronouns, sexuality, preferredTalkingHours, loveLanguages, iceBreaker, communicationStyle
- optional `relationship` only on relationship-aware callers; Discover feed does not pass one.

AI Matches returns top-level `provider: LOCAL`; each recommendation wrapper contains:

- `id`: stringified candidate **USER ID**
- `profile`: the complete Discover public profile above; its `id` is the same USER ID
- `compatibilityScore`, `compatibilityCoverage`
- `aiMatchScore`, `aiConfidence`, `aiMatchLevel`, `aiHighlights`, `aiReasons`

It does not serialize per-item `provider` or computed `aiConfidenceLevel`. Distance and status remain nested `null`. Verification is nested as `profile.verification`, not top-level. Neither recommendation ID is a `matchId` or `conversationId` (`discoverController.js:301-315`).

## 19. FLUTTER CONTRACT

Server rank: normal Discover preserves server order while appending pages. AI API items preserve server order. `MatchesScreen` sorts only injected preview profiles, then appends them after API results (`matches_screen.dart:78-84`).

Local filtering: Discover quick filters locally apply Verified, Online, Nearby, Most Compatible, Recently Active, and interest/intention filters (`browse_grid_screen.dart:283-331`). AI Matches locally applies default compatibility threshold `defaultCompatibilityThreshold` (70 in its centralized widget contract) plus All/Best Match/Active Now/Verified (`matches_screen.dart:116-135`). Consequently Flutter can hide valid server-ranked AI results below its local threshold.

Pagination: normal Discover stores/loads metadata and page 2+. AI Matches is first page only and discards metadata.

ID mapping: `publicProfileFromJson` maps only `json['id']` to `DummyProfile.id` (`public_profile_mapper.dart:79-90`). `MatchApiItem.fromAiRecommendation` separately stores wrapper ID and maps nested profile ID (`phase_two_api_service.dart:43-53`). Both are candidate user IDs.

View Profile: receives the candidate `DummyProfile`, so it uses candidate user identity and not a match/conversation ID (`matches_screen.dart:719-724`; Discover `browse_grid_screen.dart:913-949`).

Message: AI Match “Message” calls `ChatRepository.createConversationForProfile(profile)`. The backend conversation contract requires a real active Match and Flutter reports `MATCH_REQUIRED`; it does not treat candidate ID as conversation ID (`matches_screen.dart:726-756`).

Distance: mapper and UI support it, but backend always emits null; no distance displays in production responses.

Empty/error: both screens have separate loading, empty, filtered/threshold-empty, and API-error states. Discover preserves API failure as retry error rather than declaring empty (`browse_grid_screen.dart:439-465`). AI has distinct `AiMatchesEmptyState`, filtered/threshold states, and `AiMatchesErrorState` (`matches_screen.dart:205-241,2296-2363`).

## 20. DATABASE / INDEXES

Recommendation tables/columns:

- `Users`: `id`, `accountStatus`, `lastActiveAt`, `identityVerifiedAt`.
- `OnboardingProfiles`: `userId`, completion flags/stage, DOB/gender/interestedIn, filter columns/JSON, scoring columns/JSON.
- `DiscoverFilterPreferences`: `userId` and all saved filters.
- `DiscoverActions`: actor/target/action.
- `Matches`: userOne/userTwo.
- `Blocks`: blocker/blocked.
- `EventRegistrations`: user/status for event filter.
- `Subscriptions`: optional serialization include.
- `SavedProfiles`, `Reports`, `RoseTransactions`: related product data, but not queried for recommendations.

Useful existing indexes:

- `Users(accountStatus,id)`, `Users(lastActiveAt,id)`, `Users(identityVerifiedAt,id)` (`202608120001-add-account-lifecycle.js:23`; `202608160001-complete-partial-integrations.js:24`; `202608180001-create-identity-verification.js:16`).
- Unique `OnboardingProfiles(userId)` and composite `(onboardingCompleted,birthDate,communicationStyle,userId)` (`202608090001-create-baseline-schema.js:52-104`; `202608110001-add-phase1-query-indexes.js:18-23`).
- Unique `DiscoverActions(actorUserId,targetUserId)`.
- Unique `Matches(userOneId,userTwoId)`.
- Blocks indexes in both orientations (`202608120002-create-blocks.js:16-17`).
- Unique `DiscoverFilterPreferences(userId)`.
- `EventRegistrations(userId,status,eventId)` (`202608140001-create-events-foundation.js:83-85`).

Likely risks:

- The Matches exclusion has an OR across `userOneId` and `userTwoId`, but only the `(userOneId,userTwoId)` index exists; lookups beginning with `userTwoId` lack a dedicated index.
- JSON functions, `LOWER`, `TRIM`, numeric casts, and the computed compatibility expression prevent ordinary indexes from accelerating most profile filters/scoring/order.
- Completion index omits `stage`; the query requires both completion flag and stage.
- AI Matches loads and scores every eligible candidate on every page request; memory/CPU and SQL computed-order work grow linearly with population.
- Offset pagination over a mutable eligibility set is logically unsafe even if indexed.
- There is no profile geospatial column or index.

No migrations or index changes were run or made during this audit.

## 21. CURRENT TEST COVERAGE

Tests were source-inspected, not executed, because the integration suites invoke migrations and this phase explicitly prohibits migrations.

Backend:

- `Backend/test/match-engine.service.test.js`: all optional-factor subsets, bounds/symmetry/determinism, malformed/declined values, contribution reconstruction, seed-known scores, missing-data neutrality, coverage calibration, factors and reasons.
- `Backend/test/discover.integration.test.js`: authentication; filter range boundaries/stale normalization; database eligibility/actions; pre-pagination communication/profile/JSON filters; min score; reciprocal gender; lifecycle; blocks; matches; response secrecy/IDs; 100-candidate stable pages/query bounds; SQL-vs-JS scores; dirty null/declined/whitespace/zero; persisted online state.
- `Backend/test/ai-matching.integration.test.js`: auth; shared eligibility; safe LOCAL fields; global pre-slice ranking; canonical Like/Match flow; page validation/empty; evidence/confidence; genuine zero; incomplete viewer; reset safety; bounded query counts; pools beyond 500.
- `Backend/test/ai-matching-service.test.js`: confidence/support, truthful prioritized reasons, privacy, malformed evidence, deterministic tie-breaks, bounds and sparse behavior.
- `Backend/test/match-engine-observability.test.js`: bounded/redacted diagnostic logging.
- `Backend/test/match-recommendation-metrics.test.js`: score/coverage buckets and deterministic server-configured experiment assignment.
- `Backend/test/match-recommendation-attribution.integration.test.js`: persisted experiment attribution to Likes, Super Likes, Roses, and Matches; idempotence/latest context.
- `Backend/test/match-recommendation-migration.test.js`: recommendation-event migration up/down/up and model validation.
- `Backend/test/relationships.integration.test.js`: saved, sent/received Likes, Super Likes; paging/deduplication; lifecycle/block/incomplete visibility.
- `Backend/test/send-rose.integration.test.js`: Rose authentication, persistence, notification, idempotency, invalid relationships, concurrency.
- `Backend/test/mutual-like-chat.integration.test.js`: canonical mutual Match/conversation creation and participant isolation.
- `Backend/test/account-deactivation-reactivation.integration.test.js`: deactivation, profile preservation, Discover/AI/profile exclusion, reactivation without onboarding restart, deleted-account rejection.
- `Backend/test/phase2.integration.test.js`: public profile lifecycle/safety, two-way blocks across Discover/matches, reports, lifecycle, matches/unmatch.
- `Backend/test/phase3.integration.test.js`: matched chat eligibility, block effects, message/report safety.
- `Backend/test/dummy-seed-config.test.js` and `dummy-seed-factory.test.js`: seed safety/config and deterministic/unique/onboarding-compatible generation.

Flutter:

- `test/discover_screen_test.dart`: responsive card/deck, local quick filters, navigation, swipe/pass/like/super-like/rewind and end state.
- `test/discover_action_controller_test.dart`: action advancement/rewind, canonical numeric candidate IDs, empty deck.
- `test/discover_empty_state_test.dart`: completion CTAs, distinct loading/error/empty, next-page fetch before exhaustion.
- `test/discover_id_validation_test.dart`: canonical backend ID mapping.
- `test/four_tab_discover_test.dart`: navigation shell.
- `test/advanced_filters_screen_test.dart`, `communication_style_filter_test.dart`, `filters_range_safety_test.dart`: UI filter controls, persistence callbacks, enum/query strings, reset, and malformed/stale range safety.
- `test/account_preferences_api_test.dart`: authenticated canonical `/api/me/preferences` loading/saving/failures.
- `test/matches_screen_test.dart`: AI threshold/filter UI, ordering expectations, API error vs empty, profile/message routes, evidence display and responsive layout.
- `test/likes_super_likes_test.dart`: real reaction state, uniqueness/removal, canonical profile navigation.
- `test/profile_detail_interactions_test.dart`: Rose/Super Like/Message/Like actions and Rose target/conversation behavior.
- `test/profile_preview_public_profile_test.dart`: public mapping/display consistency.

## 22. MISSING TEST COVERAGE

- Real profile coordinates, distance calculation, max-distance eligibility, preferred-distance reciprocity, location freshness, privacy, and `near_you` behavior (schema absent).
- Reciprocal age and reciprocal non-gender dealbreakers.
- Discovery visibility/incognito/pause/hide behavior (contract absent).
- Explicit report-to-recommendation policy and Rose/save exclusion policy.
- Completion flags becoming stale after photo deletion/profile edits; candidate revalidation versus 100% metric.
- SQL-vs-JS equivalence with duplicate candidate list elements, mixed `prefer not to say`, and dirty non-array JSON.
- Flutter AI page 2+, pagination metadata, load-more, and cross-page ordering (implementation absent).
- Mutation-safe pagination after a page-one swipe/action; skip/duplicate regression.
- `surface=near_you`, `similar_interests`, `new_here`, and `recently_active` semantics.
- Public online/activity serialization and correct local Active Now behavior.
- Multi-city UI versus single-city API behavior.
- `EventRegistration.status='promoted'` expectation for event-interest filtering.
- Candidate pool performance at production scale beyond query-count assertions; AI full-pool memory/latency.
- Separate total counts/consistent total semantics (not returned).
- External-provider integration/fallback/security tests (provider absent).
- Reference-plan-specific tests cannot be enumerated because the named completion-plan file is absent.

## 23. GAP ANALYSIS

P0:

- Canonicalize eligibility/filter policy, especially reciprocal age/distance/dealbreakers, reports, visibility, and action exclusions.
- Add user/profile geolocation with consent/freshness/privacy rules and implement true distance hard filtering before exposing distance/near-you claims.
- Unify SQL and JS scoring normalization or move filtering/ranking onto one authoritative computed contract.
- Replace mutable offset pagination with a stable snapshot/cursor strategy; add AI Flutter pagination.
- Revalidate actual candidate completeness or maintain completion flags transactionally when required fields/photos change.
- Resolve online/activity contract: serialize a truthful activity signal or remove nonfunctional local filters.

P1:

- Add explicit total semantics if product/UI needs totals.
- Align filter range validators (`/api/me` 1-500/100-250 versus effective 1-300/137-213).
- Align multi-city UI with single-city backend.
- Clarify whether promoted event registrations qualify.
- Add missing indexes after measuring query plans, particularly reverse Match lookup and any normalized/filter projections.
- Version recommendation/filter contracts and expose sufficient pagination/ranking metadata.

P2:

- External AI provider behind the already safe eligible-candidate boundary, with deterministic fallback and privacy constraints.
- Cached/versioned AI ranking snapshots for large pools.
- Richer location freshness and approximate-distance display controls.
- Optional visibility/incognito product work after policy and entitlement semantics are defined.

## 24. RECOMMENDED IMPLEMENTATION PHASES

Phase 2: Canonical eligibility/filter contracts

- Decide and encode action/report/visibility/completion policy; align backend validators, persisted preferences, Flutter controls, and tests.

Phase 3: Real distance matching

- Add private coordinates/freshness, ingestion from onboarding/edit profile, geospatial calculation/indexing, max-distance rules, approximate serialization, and near-you behavior.

Phase 4: Reciprocal eligibility

- Add/define candidate-side age, distance and dealbreaker evaluation; retain explicit permissive behavior only where product policy says so.

Phase 5: Compatibility scoring unification

- Use one normalized factor representation/formula for filter/order/response/AI; add dirty-data equivalence tests.

Phase 6: Ranking + pagination

- Introduce stable snapshot/cursor semantics, totals if needed, performance/index work, and Flutter AI load-more.

Phase 7: AI Match integration hardening

- Keep LOCAL deterministic provider as fallback; add versioned provider boundary, privacy controls, timeouts/fallback, and full-pool performance strategy before any external model.

Phase 8: Full regression validation

- Run migrations in an approved environment, backend unit/integration suites, Flutter suites, deterministic seed validation/reporting, query plans, and end-to-end lifecycle/action/safety checks.

This dependency order remains appropriate from source evidence; scoring unification should be designed during Phase 2 so distance/reciprocal factors do not create another duplicate path.

## 25. FILES CHANGED

Only:

`docs/AMORAA_MATCH_ENGINE_PHASE1_CURRENT_STATE_AUDIT.md`

All pre-existing dirty files recorded at audit start were preserved and not modified by this audit.

## 26. GIT

Initial state:

- Branch: `main`
- Tracking: `main...origin/main`
- Pre-existing modified files: `Backend/src/controllers/accountController.js`, `Backend/src/models/DeletedUser.js`, `Backend/src/routes/accountRoutes.js`, `Backend/src/services/immediateAccountDeletionService.js`, `Backend/test/account-deletion-otp.integration.test.js`, `lib/core/api/phase_two_api_service.dart`, `lib/features/settings/presentation/widgets/amoraa_delete_account_flow.dart`, `test/account_actions_test.dart`.
- Pre-existing untracked files: `Backend/src/constants/accountDeletionReasons.js`, `Backend/src/migrations/202609290001-add-deleted-user-reason.js`, `test/account_deletion_reason_api_test.dart`.
- Initial `git diff --check`: no whitespace errors; Git emitted LF→CRLF warnings for several pre-existing modified files.

Audit-created change: the report file only.

Commit: **NO**  
Push: **NO**  
Deploy: **NO**

## FINAL STATUS

MATCH ENGINE COMPLETE: **NO**

READY FOR PHASE 2: **YES**

Reason: current source is sufficiently mapped to begin a controlled canonical eligibility/filter phase, but the engine cannot be called complete while distance is nonfunctional, reciprocity is incomplete, visibility/report policy is absent, scoring has SQL/JS dirty-data divergence, completion flags can become stale, and AI Flutter pagination is first-page-only.
