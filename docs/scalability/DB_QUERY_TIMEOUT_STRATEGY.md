# AMORAA database query-timeout strategy

S2 adds validated `DB_QUERY_TIMEOUT_MS` configuration with range 0-300,000 ms. The default is zero (disabled) to avoid imposing an untested production ceiling. When enabled, each application connection receives a session statement limit: `max_statement_time` on MariaDB and `MAX_EXECUTION_TIME` on MySQL.

Rollout requirements:

1. Enable only in production-like staging after capturing normal p99 and known maintenance/report durations.
2. Use a conservative value above normal request-query duration; do not use it as a substitute for indexes or bounded queries.
3. Observe timeout counts by sanitized query class, HTTP outcome, pool wait, and database load.
4. Keep migrations and approved offline jobs on separate connections/policies.
5. Confirm transaction rollback and client error mapping when a statement is interrupted.

The setting is repository-supported but remains **PARTIAL — STAGING REQUIRED** until MySQL 8 behavior and operational thresholds are validated.
