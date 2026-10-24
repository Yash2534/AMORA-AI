# AMORAA S3 MySQL 8 query-plan validation

Date: 2026-10-12

Status: **BLOCKED — MYSQL 8 STAGING AND REPRESENTATIVE DATA REQUIRED**

No MySQL 8 staging endpoint or approved representative dataset is available. S2 evidence came from local MariaDB temporary tables and is not relabeled as MySQL 8 evidence.

## Capture protocol

For each query below, capture sanitized SQL/fingerprint, dataset tier/distribution, MySQL exact version/config, migration set, bind-value classes (not sensitive values), `EXPLAIN FORMAT=JSON`, `EXPLAIN ANALYZE`, cold/warm context, execution duration, index/join type, estimated and actual rows, loops, rows examined/returned, temporary table, filesort and lock time. Run read-only statements or roll back controlled synthetic mutations.

| Family | Required variants | Expected question |
|---|---|---|
| Discovery | broad/narrow/default/near-you/AI window | Does the location box and eligibility reduce work before exact score/distance? |
| Distance | dense/sparse/antimeridian/radius boundary | Is the S2 location index used without semantic drift? |
| Compatibility/JSON | each optional filter and combinations | Which expressions dominate rows/CPU and require normalization? |
| Likes/matches/blocks | forward/reverse/exclusion/mutual write | Are pair indexes selective and lock behavior bounded? |
| Chat | conversation list, unread correlation, history keyset, mark-read | Does unread correlation or offline range update dominate? |
| Moderation | status/date/search with bounded pages | Does status/time index avoid large sort/count work? |
| Privacy | owner history and artifact lifecycle | Is owner/time/id stable and selective? |
| Subscription/registration analytics | 30/90/366-day windows | Quantify `GROUP BY DATE` temporary/filesort cost. |
| Admin/dashboard | counts, date groups and searches | Identify queries that compete with user traffic. |
| Financial | overview, transactions, reconciliation | Verify grouped aggregates and bounded source reads. |

## Result register

| Family | Dataset | Index | Est. rows | Actual rows | Temp/filesort | Duration | Result |
|---|---|---|---:|---:|---|---:|---|
| All families | Not run | — | — | — | — | — | BLOCKED — INFRASTRUCTURE REQUIRED |

Pass requires plans attached for every critical family, no unexplained full scans of high-cardinality tables, no severe estimate/actual divergence left uninvestigated, and a remediation decision for every material temporary table/filesort. Results establish behavior only for the recorded staging configuration; they do not establish concurrent capacity.

