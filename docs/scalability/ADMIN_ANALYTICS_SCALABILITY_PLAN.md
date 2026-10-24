# AMORAA admin analytics scalability plan

## S2 repository changes

- Custom analytics, matching, payment, and reconciliation date spans are capped at 366 days; defaults are 30 days.
- Revenue overview uses grouped SQL payment/subscription aggregates instead of materializing all paid/refunded rows and issuing per-plan count queries.
- The empty-period fallback that scanned all historical payments/refunds was removed.
- User-registration and subscription chronology indexes support bounded date ranges.
- Admin matching failure/derived-result paths are hard-capped at 1,000 rows pending SQL/reporting redesign.
- Moderation status chronology and match chronology indexes were added.

## Residual expensive work

- Dashboard/global cards still use exact counts and can scan large domains.
- `GROUP BY DATE(createdAt)` retains a temporary table/filesort even after the range becomes indexed.
- Recommendation attribution loads full telemetry/outcome universes and must become time-bounded rollup/offline work.
- Joined `findAndCountAll`, arbitrary sorting, and contains search can remain expensive.
- Financial reconciliation remains a bounded in-process comparison, not a durable ledger reconciliation job.

## Later architecture trigger

Introduce daily/hourly rollup tables or a reporting replica only when staging slow-query and contention evidence demonstrates need. Rollups should be idempotently keyed by metric/date/dimension/version, recomputable, and explicitly marked with freshness. User-facing primary traffic must have a separate connection/workload budget from exports and large reporting.

Production targets and refresh intervals require product/SRE approval and are not measured facts.
