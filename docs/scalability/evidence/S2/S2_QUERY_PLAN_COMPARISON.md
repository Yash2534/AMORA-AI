# AMORAA S2 query-plan comparison

Recorded: 2026-10-12. Tool: `Backend/scripts/s2-query-plan-evidence.js`.

Environment: local MariaDB 10.4.32. Dataset: deterministic, session-scoped temporary tables, 10,000 synthetic rows per table, never persisted. Commands used `EXPLAIN FORMAT=JSON` and MariaDB `ANALYZE FORMAT=JSON`. No credentials, real users, production system, or production data were used.

| Query shape | Before | After | Residual |
|---|---|---|---|
| Discovery bounding box | `ALL`, no key; ANALYZE visited 10,000 rows | `range`, location index; ANALYZE reported 96 rows for the synthetic box | Exact distance, compatibility, JSON, and final sort still execute on survivors. |
| User registration date range | `ALL`, about 10,458 estimated / 10,000 actual; temporary + filesort | `range`, creation index; 3,333 estimated/actual | `GROUP BY DATE(createdAt)` still uses temporary/filesort. |
| Admin match chronology, limit 20 | `ALL`, filesort; ANALYZE scanned 10,000 | index order on match-time index; 20 result rows, no filesort | Joined/derived AI-score filters are separate work. |
| Subscription chronology, limit 20 | `ALL`, filesort; ANALYZE scanned 10,000 | index order on subscription-time index; 20 result rows, no filesort | Status-specific reports may need different composites if plans prove it. |
| Moderation open queue, limit 20 | `ALL`, filesort; ANALYZE scanned 10,000 | `ref` on status/time index; 20 result rows, no filesort | Low-cardinality status distribution must be rechecked on staging. |
| Privacy owner history, limit 20 | `ALL`, filesort; ANALYZE scanned 10,000 | `ref` on owner/time/id; 100 matching synthetic rows estimated, 20 returned, no filesort | API still offers offset pages; keyset is a later compatible enhancement. |

The local development schema itself contains only about 65 users and small related tables, so its optimizer choices cannot represent production distributions. These comparisons demonstrate access-path changes, not latency, throughput, or capacity.
