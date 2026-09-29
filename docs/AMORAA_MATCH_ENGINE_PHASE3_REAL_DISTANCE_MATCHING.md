# AMORAA MATCH ENGINE — PHASE 3 REAL DISTANCE MATCHING

## Coordinate model

Private match coordinates are owned by `OnboardingProfile`:

- `matchLatitude DECIMAL(9,6) NULL`
- `matchLongitude DECIMAL(9,6) NULL`
- `locationUpdatedAt DATETIME NULL`

Migration `Backend/src/migrations/202609290002-add-profile-match-location.js` adds the nullable columns without backfilling historical users and supports rollback. GPS coordinates are optional and do not change the canonical profile-completion contract. `OnboardingProfile.preferredDistance` remains a legacy onboarding value; the Match Engine's only authoritative distance preference is `DiscoverFilterPreference.maxDistanceKm` (1–300 km).

## Permission and capture flow

Flutter uses `geolocator 14.0.2` to obtain one foreground position after the user taps **Use Current Location** in Filters. The existing typed `permission_handler` service checks that location services are enabled and requests when-in-use permission. No request occurs at startup and no background position stream is used.

The flow handles denial, permanent denial, device services being disabled, a 15-second position timeout, unavailable location, and backend upload failure. Permanent denial and disabled services offer the existing settings guidance. Android declares only coarse and fine foreground location permissions. iOS declares `NSLocationWhenInUseUsageDescription` and enables the permission-handler location macro; it does not declare Always/background location.

## Authenticated location API

`GET /api/me/location` returns only `locationAvailable` and `locationUpdatedAt`. `PUT /api/me/location` accepts exactly numeric, finite `latitude` and `longitude` values within -90…90 and -180…180 for the authenticated user. There is no target-user parameter. The server sets `locationUpdatedAt`; client timestamps and extra fields are rejected. `DELETE /api/me/location` clears all three private fields without changing city.

## Privacy contract

Raw `matchLatitude` and `matchLongitude` never appear in public profile, Discover, AI Matches, likes, saves, blocks, matches, notifications, chat, or onboarding responses. The local AI provider receives precomputed compatibility plus an opaque user ID, not user/profile objects or coordinates. No coordinate values are logged, added to tokens, notifications, attribution, or recommendation events.

Own-profile and preference responses expose only location availability and the server update time. Public recommendation responses expose derived whole-kilometre `distanceKm` and the backward-compatible `distance` field. Filtering always uses the unrounded distance. Flutter accepts integer, double, numeric-string, null, and malformed optional distance values; zero renders as “Less than 1 km”.

## Distance engine

`Backend/src/utils/geoDistance.js` is the canonical Haversine utility. Its JavaScript implementation is used for unit/equivalence verification. The Discover query uses the equivalent SQL expression with Earth radius 6371.0088 km, parameter-safe escaped viewer coordinates, coordinate bounds, and an `ACOS` input clamped to [-1, 1].

When the viewer has valid saved coordinates, geographic filtering is active for normal Discover and AI Matches. A candidate must have valid coordinates and precise `distanceKm <= maxDistanceKm`; the boundary is inclusive. Missing or invalid candidate coordinates do not satisfy an active geographic filter. City remains an independent exact hard filter and is never used to estimate distance.

The SQL calculation is part of the existing candidate query and introduces no N+1 processing. No coordinate index is added because scalar latitude/longitude B-tree indexes do not accelerate the current trigonometric expression. At larger scale, Phase 6 should consider a parameterized bounding-box prefilter or a supported spatial index before the precise Haversine predicate.

## Migration-safe missing-location behavior

For default Discover and AI Matches, a viewer without coordinates keeps the existing non-distance eligibility flow. The API reports `viewerLocationAvailable: false`, `distanceFilterActive: false`, and candidate distance is null. Existing users are not assigned fabricated coordinates and do not lose their feed.

Once the viewer explicitly saves coordinates, `distanceFilterActive` becomes true and `maxDistanceKm` is authoritative. Clearing location restores the migration-safe non-distance behavior. Coordinates have no automatic freshness expiry: `locationUpdatedAt` records the latest explicit update, and the latest saved position remains in use until replaced or cleared.

## Recommendation surfaces and ranking

Default Discover retains compatibility score descending, then stable user ID ascending. Distance is an eligibility constraint, not its primary rank.

`surface=near_you` is supported only when the viewer has coordinates. Otherwise the endpoint returns HTTP 409 with `LOCATION_REQUIRED`. It shares all canonical eligibility and hard filters, requires candidate coordinates inside `maxDistanceKm`, and ranks deterministically by:

1. precise distance ascending;
2. compatibility score descending;
3. stable user ID ascending.

AI Matches uses the same distance-aware candidate query and cannot reintroduce an excluded candidate. LOCAL AI ranking remains `aiMatchScore DESC`, `aiConfidence DESC`, stable user ID ascending. `similar_interests`, `new_here`, and `recently_active` remain controlled unsupported surfaces.

## Deferred to Phase 4 and later

Phase 3 applies only the viewer's real geographic distance preference. Candidate reciprocal distance, reciprocal age, and reciprocal dealbreakers remain Phase 4 work. Compatibility score unification, cursor/snapshot pagination, AI Matches Flutter load-more, and external AI remain later phases.
