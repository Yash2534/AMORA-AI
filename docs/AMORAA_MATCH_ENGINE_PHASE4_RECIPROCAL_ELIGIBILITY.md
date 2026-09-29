# AMORAA MATCH ENGINE — PHASE 4 RECIPROCAL ELIGIBILITY

## Mutual eligibility definition

Normal Discover and AI Matches share the candidate query in `discoverController.getFeed`. A candidate must pass the canonical account, profile-completion, action, relationship, block, viewer-filter, and compatibility-threshold rules from Phase 2; the geographic rules from Phase 3; viewer-to-candidate and candidate-to-viewer gender acceptance; candidate reciprocal age; and candidate reciprocal geographic distance when distance is evaluable. Reciprocal rules are hard eligibility constraints and do not add score bonuses.

## Reciprocal gender

The existing policy remains authoritative. The viewer's `interestedIn` must accept the candidate's `gender`, and the candidate's `interestedIn` must accept the viewer's `gender`. Comparisons normalize supported male/female/other aliases and the universal tokens `everyone`, `all`, `any`, and `both`. No sexuality or orientation is inferred. Canonical completion normally excludes empty candidate `interestedIn`; the permissive null/empty handling remains defensive for malformed legacy data.

## Reciprocal age

`DiscoverFilterPreference.minAge` and `maxAge` are the sole candidate reciprocal age source. The authenticated viewer's exact age, calculated from the full birth date with the canonical `ageFor` helper, must fall inclusively within the candidate's effective range. Missing preference rows use the same runtime-aware defaults as viewer preferences without creating a row. Values outside 18–99 are clamped using the canonical stored-range normalization, and a legacy minimum greater than maximum resolves to the canonical default range.

## Reciprocal distance

`DiscoverFilterPreference.maxDistanceKm` is the sole reciprocal distance source. `OnboardingProfile.preferredDistance` remains non-authoritative. When the viewer and candidate both have valid match coordinates, one symmetric great-circle distance expression must be less than or equal to both effective limits. SQL implements this as `distance <= LEAST(viewer limit, candidate limit)`. The range is 1–300 km and the boundary is inclusive.

When the viewer has no coordinates, ordinary Discover and AI Matches remain migration-safe and do not enforce either distance direction. `near_you` still requires viewer coordinates. When the viewer has coordinates and a candidate does not, the candidate remains excluded. Missing candidate preference rows use the runtime-aware default distance without data mutation. Location has no automatic expiry and is never replaced by city equality.

## Dealbreakers audit

The Flutter `DealbreakersScreen` persists age, distance, and optional values into the ordinary Discover filter record. There is no dedicated dealbreaker model, no per-field persisted dealbreaker boolean, and no backend contract distinguishing whether smoking, drinking, relationship intention, city, education, or community originated from that screen or Advanced Filters. Consequently, Phase 4 makes only the explicitly approved age and distance fields reciprocal. All other filters remain viewer-side only; no new reciprocal semantics are inferred from UI labels.

## Viewer-only filters

Height, city, dating intentions, sexuality, education, profession, community, religion, smoking, drinking, weed, languages, pronouns, qualities, preferred talking hours, love languages, lifestyle, communication style, prompts, verified-only, recent activity, event interest, and minimum compatibility remain viewer-selected hard filters. Candidate values for these filters are not reversed against the viewer.

## Query and privacy contract

Candidate reciprocal preferences are read by indexed correlated SQL subqueries against the unique `DiscoverFilterPreferences.userId` key. Recommendation reads never call `findOrCreate` for candidates and introduce no per-candidate application query. Missing rows are represented by in-memory/runtime defaults. The candidate query remains SQL-pageable, deterministic, and shared by Normal Discover, `near_you`, and AI Matches.

Public payloads do not expose candidate age ranges, distance limits, dealbreaker state, reciprocal exclusion reasons, or exact coordinates. AI receives only candidates that have already passed reciprocal eligibility and cannot restore an excluded candidate.

## Deferred work

Compatibility scoring and SQL/JavaScript normalization unification remain Phase 5. Cursor/snapshot pagination, AI Matches Flutter page 2, visibility/incognito features, report auto-blocking, external AI, background location, location expiry, and new dealbreaker persistence are not part of Phase 4.
