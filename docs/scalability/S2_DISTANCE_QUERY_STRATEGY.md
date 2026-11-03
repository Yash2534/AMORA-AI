# AMORAA S2 distance query strategy

## Current schema and behavior

`OnboardingProfiles` stores nullable `DECIMAL(9,6)` `matchLatitude` and `matchLongitude`. Before S2, the query validated coordinate ranges but evaluated the exact spherical cosine expression for every otherwise eligible located profile. No location index existed.

## S2 implementation

The repository now computes a latitude/longitude bounding box from the viewer coordinates and configured maximum distance. The database applies the box through ordinary range predicates before the existing exact distance expression. Antimeridian crossing and polar longitude ranges are handled. The exact distance comparison remains authoritative, so the box can only exclude points that cannot be inside the viewer's circle.

Index: `onboarding_profiles_match_location (matchLatitude, matchLongitude,userId)`.

Local temporary-table evidence with 10,000 synthetic profiles changed the box predicate from `ALL` with 10,000 actual rows visited to `range` on the location index with 96 actual rows in that synthetic distribution. This is query-shape evidence only; it is not a production latency or capacity result.

## Why no spatial redesign in S2

MySQL `POINT SRID 4326`, a spatial index, geohash cells, or a normalized location table may outperform the two-column range approach, but each requires data backfill, coordinate-order validation, migration/rollback planning, and production-like selectivity evidence. That work is deferred until staging plans show the B-tree box is insufficient.

## Remaining work

- Capture MySQL 8 `EXPLAIN ANALYZE` on representative staging distributions.
- Measure bounding-box false-positive rates by geography and radius.
- Ensure location privacy/precision policy before any derived cell is stored.
- Consider spatial/geohash design only with a benchmark and backfill plan.
