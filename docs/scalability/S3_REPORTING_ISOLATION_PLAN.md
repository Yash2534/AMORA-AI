# AMORAA S3 reporting isolation plan

Date: 2026-10-12

Status: **PARTIAL — STAGING MEASUREMENT REQUIRED**

S2 bounded date ranges and in-memory result sets and converted core financial metrics to SQL aggregates. Remaining dashboard counts, date grouping, joined search, recommendation attribution and reconciliation must be measured before introducing infrastructure.

## Decision ladder

1. Keep bounded operational reads on the primary when plans and resource impact are acceptable.
2. Cache non-authoritative dashboard summaries for a short, explicit TTL with version/invalidation and visible freshness time.
3. Add transactionally maintained or scheduled rollup tables for repeated time buckets. Jobs must be idempotent and backfillable.
4. Use asynchronous report jobs for large exports/reconciliation, with private expiring artifacts.
5. Introduce a read replica only when staging demonstrates primary interference and acceptable replica lag/consistency semantics.
6. Use a reporting database/warehouse only when rollups/replica cannot meet the workload and governance requirements.

## S3 measurements

Capture query duration, rows examined/returned, temporary/filesort, DB CPU/IO, pool acquisition, lock impact and concurrent user-query latency for 30-, 90- and 366-day windows at each approved dataset tier. Test dashboard counts, user/subscription/report daily groups, moderation pages/counts, recommendation attribution, financial overview/transactions and reconciliation. Writes and authoritative compliance/billing totals must never silently read stale replicas/caches.

## Initial recommendations

- Registration/subscription/report daily groups: candidate daily rollups if MySQL 8 evidence shows material repeated cost.
- Dashboard population cards: candidate short-lived cached summaries after product approves staleness.
- Recommendation attribution: strong candidate for scheduled rollup/offline computation.
- Financial reconciliation and exports: durable asynchronous job; retain exact source-of-truth checks.
- Moderation queue: remain primary/strongly consistent; improve search/indexing from evidence rather than move it blindly.

No read replica, rollup or reporting database is implemented or approved in S3 repository work.

