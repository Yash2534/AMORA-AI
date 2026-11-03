# AMORAA S3 representative synthetic data plan

Date: 2026-10-12

Status: **PLAN READY — GENERATION BLOCKED PENDING APPROVED STAGING RESOURCES**

No production-derived data, copied identifiers, real contact destinations, customer media or production distributions are permitted. The datasets are engineered test shapes, not claims of production equivalence.

## Dataset tiers

| Tier | Registered users | Use | Promotion gate |
|---|---:|---|---|
| S3-10K | 10,000 | Seed verification, initial plans, correctness and telemetry | Approved storage/DB budget and successful cleanup rehearsal |
| S3-50K | 50,000 | Selectivity, JSON/distance/admin/reporting plans | 10K integrity and resource review pass |
| S3-100K | 100,000 | Final S3 representative plan corpus | 50K remains within approved staging time/storage headroom |

Do not generate a tier solely because it appears here. Record seed version, random seed, commit, migration set, generation duration, table counts, bytes, DB resources and cleanup result.

## Proposed distributions

- Account state: 82% active, 10% deactivated, 8% deleted; deleted data follows the repository lifecycle model.
- Profile completion among active users: 88% complete, 12% incomplete.
- Gender values follow schema-supported values with a non-zero minority for every supported value; exact ratios are synthetic parameters.
- Ages: weighted bands 18–24, 25–34, 35–44, 45–54 and 55+, with boundary birthdays included.
- Locations: several dense clusters, medium clusters, sparse/rural points, missing coordinates, antimeridian fixtures and exact-radius boundary fixtures. Coordinates must be synthetic/non-identifying.
- Preferences: broad, medium and narrow age/distance/gender sets; include reciprocal failures and legacy/default values.
- Interactions: zero/low/medium/high-activity cohorts; deterministic actor-target uniqueness and valid timestamps.
- Conversations/messages: 0, 20, 100 and 500-conversation cohorts; unread/read/deleted/media states and long-offline readers.
- Moderation/privacy: mostly closed history plus selective active queues; no sensitive free text.
- Subscriptions/payments: sandbox-only statuses/currencies/plans and deterministic idempotency keys; no provider calls or chargeable tokens.
- Administrators: minimal synthetic role set, MFA/test delivery disabled unless an approved dummy-admin exercise requires it.

## Referential and security invariants

No self-like/block/match; canonical match/conversation pairs remain unique; blocked or inactive users are excluded where policy requires; participant/message ownership is valid; privacy artifacts use non-secret dummy objects; all contact data uses reserved invalid domains/numbers and cannot route externally. Seed passwords are injected, not written into reports.

## Generation strategy

Extend the existing deterministic dummy-seed concepts only after staging approval. Use chunked bulk inserts with explicit transaction boundaries, bounded memory, deterministic IDs and resumable checkpoints. Disable provider delivery and media generation by default. Generate tiny placeholder images with stripped metadata only when storage flows are under test. Never run against a database name not explicitly allowlisted as staging/test, and require a typed confirmation plus `NODE_ENV != production`.

## Validation and cleanup

After generation, compare manifest counts to database counts, check orphan rows and unique constraints, sample every cohort, run canonical discovery/privacy/chat authorization tests and hash a sanitized manifest. Cleanup must delete the dataset, queue jobs and objects by run ID, then prove no residual synthetic objects remain. SQL timings from seeding are not application-capacity evidence.

