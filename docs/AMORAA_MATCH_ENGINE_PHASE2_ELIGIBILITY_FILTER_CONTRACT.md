# AMORAA MATCH ENGINE — PHASE 2 ELIGIBILITY + FILTER CONTRACT

## Scope and authority

The executable policy is `Backend/src/services/discoverEligibilityPolicy.js`. Normal Discover and AI Matches both enter `discoverController.getFeed`; AI Matches sets `req.aiMatches = true` and reranks only the eligible set returned by that shared query. Compatibility mathematics, geographic distance, reciprocal age/distance, cursor pagination, and external AI are outside Phase 2.

## Canonical eligibility

A candidate is eligible only when all of these conditions hold:

- The candidate user is not the authenticated viewer.
- `User.accountStatus` is `active`. `deactivated` and `deleted` are ineligible. A reactivated user becomes eligible again through the same retained onboarding profile when all other rules pass.
- The candidate passes the canonical current profile-completion contract below.
- The candidate is inside the viewer's effective age range and passes every requested/saved hard filter.
- The viewer's non-universal `interestedIn` accepts the candidate's gender.
- The candidate's `interestedIn` accepts the viewer's gender. The reciprocal rule recognizes gender aliases and `everyone`, `all`, `any`, and `both`. At the reciprocal-rule level, null/empty candidate preferences remain permissive for backward compatibility; canonical candidate completion independently requires a usable non-empty `interestedIn` list.
- Neither user has blocked the other.
- The users do not already have a `Match`.
- The viewer has no excluding `DiscoverAction` for the candidate.
- Any enabled verified, recent-activity, event-registration, or minimum-score rule passes.

These checks are applied before pagination. AI Match reranking cannot add a candidate that the shared query excluded.

## Action and relationship policy

| State | Excluded from Discover and AI Matches | Enforcement |
|---|---:|---|
| Pass | Yes | `DiscoverActions.action IN ('pass', 'like', 'superLike')` |
| Like | Yes | Same shared candidate subquery |
| Super Like | Yes | Same shared candidate subquery |
| Existing Match | Yes | Bidirectional `Matches` subquery |
| Block in either direction | Yes | Shared access-control SQL |
| Rose | No | Deliberately absent from recommendation exclusions |
| Saved profile | No | Deliberately absent from recommendation exclusions |
| Report alone | No | Deliberately absent from recommendation exclusions; reporting is not converted into blocking |

Rewind retains its existing behavior: it removes the viewer's most recent `DiscoverAction`, so that candidate may become eligible again if no other rule excludes them.

## Candidate and viewer completion

`profileCompletionErrors` is shared by onboarding completion and recommendation eligibility. A Discover-complete profile requires:

- a valid birth date representing an adult aged at least 18;
- `gender` equal to `Male`, `Female`, or `Other`, compared case-insensitively;
- at least one trimmed, non-empty, usable `interestedIn` value;
- at least one trimmed, non-empty, usable `relationshipGoals` value;
- a trimmed, non-empty `city`;
- at least two trimmed, non-empty usable photo paths;
- `onboardingCompleted = true`; and
- `stage = 'complete'`.

`Prefer not to say` and blank list entries are not usable completion values. Onboarding completion uses the same required-content function before setting the two historical flags. Discover independently revalidates current content in the SQL candidate query, so removing a required value or reducing photos to one makes a stale completed profile ineligible without forcing the user back through onboarding. Restoring the content makes it eligible again.

The authenticated viewer must pass the same current completion contract before Discover filters, swipes, or AI Matches can be used.

## Filter ranges and normalization

The canonical backend ranges in `discoverFilterRanges.js` are:

| Filter | Backend range | Phase 2 behavior |
|---|---:|---|
| Age | 18–99 | Hard candidate filter; Flutter currently projects 18–45 |
| Distance preference | 1–300 km | Accepted and persisted, but not geographically enforced until Phase 3 |
| Minimum height | 137–213 cm | Hard candidate filter |
| Minimum compatibility | 0–100 | Hard threshold before return; Flutter may expose a narrower control |

Discover query validation, Discover preference updates, `/api/me/preferences`, and administrator Discover configuration expose these ranges from the central contract. Stale stored numeric values are clamped safely.

String values are trimmed. String and enum lists accept arrays (and comma-separated query strings where supported), trim entries, remove blanks, and deduplicate case-insensitively while preserving the first safe display spelling. Malformed non-list stored values normalize to empty lists. Boolean strings use an explicit case-insensitive `true` comparison; null/empty optional height remains null.

## Hard filters

The viewer-side hard filters are `minAge`, `maxAge`, `minHeight`, `city`, `datingIntentions`, `sexuality`, `education`, `profession`, `community`, `religion`, `smoking`, `drinking`, `weed`, `languages`, `pronouns`, `qualities`, `preferredTalkingHours`, `loveLanguages`, `lifestyleTags`, `communicationStyles`, `hasPrompts`, `verifiedOnly`, `onlineNow`, `hasEventInterest`, and `minScore`.

`maxDistanceKm` is intentionally not classified as an enforced hard filter in Phase 2 because there are no coordinates and no real distance calculation. City remains an exact case-insensitive hard filter when selected; it is not a distance substitute. Event interest requires `EventRegistration.status = 'registered'`; `promoted` is not included.

Compatibility preferences used only by the existing scoring algorithm remain scoring concerns. Phase 2 does not change score weights or resolve the known SQL/JavaScript scoring duplication.

## Recent activity

Recent activity is not realtime socket presence. It is derived from `User.lastActiveAt` using the administrator-configured `onlineWindowMinutes`, with the environment/default fallback of five minutes and a minimum of one minute. Authentication middleware maintains `lastActiveAt` with its existing write throttle.

Discover uses the same resolved window for the `onlineNow` hard filter and response serialization. Public candidate JSON now includes `recentlyActive: true|false`. The legacy `status` field remains for compatibility and is `Recently active` when true or null when false. Exact activity timestamps are not exposed.

Flutter maps `recentlyActive` directly. Discover's Active/Recently Active quick filters and AI Matches' Recently Active filter use that boolean and do not infer activity from the legacy status string. Server order is preserved among remaining profiles.

## Surfaces

| Surface | Phase 2 behavior |
|---|---|
| omitted / `recommended` | Standard deterministic Discover eligibility and compatibility ordering |
| `high_compatibility` | Supported; AI Matches forces this surface and applies deterministic LOCAL reranking after shared eligibility |
| `near_you` | Rejected with HTTP 400 / `DISCOVER_SURFACE_UNSUPPORTED`; reserved for Phase 3 real distance |
| `similar_interests` | Rejected with the same controlled error; no silent no-op |
| `new_here` | Rejected with the same controlled error; no silent no-op |
| `recently_active` | Rejected as a ranking surface with the same controlled error; use the activity filter for current hard-filter behavior |

Unknown surface values fail route validation. No accepted surface is silently ignored.

## City contract

The backend stores one `city` preference. Flutter's city selector is therefore single-select and submits that one value. No schema expansion or multi-city semantics are introduced in Phase 2.

## Reserved for later phases

- Phase 3: latitude/longitude, real distance, `maxDistanceKm` exclusion, and `near_you` semantics.
- Phase 4: reciprocal age, reciprocal distance, and reciprocal dealbreakers.
- Phase 5: compatibility scoring and normalization unification.
- Later phases: cursor pagination, AI Matches load-more, new visibility/incognito features, changed report safety semantics, new ranking surfaces, and external AI.

