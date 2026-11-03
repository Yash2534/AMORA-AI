# AMORAA database connection budget

S1 sets a default `DB_POOL_MAX=10`, `DB_POOL_MIN=0`, a 30-second acquire timeout, and a 10-second idle timeout. These are bounded repository defaults, not approved production sizing.

Formula:

`total_app_connections = API_instances × DB_POOL_MAX`

Broader deployment formula:

`total_possible_connections = (API_instances × API_pool_max) + (worker_instances × worker_pool_max) + migration_job_pool + reporting_pool + operational_reserve`

Example arithmetic may be performed during deployment planning, but the repository does not invent the database provider's maximum. The selected provider limit must exceed the calculated total plus explicit administrative/failover reserve.

Required staging evidence:

- pool used/idle/pending/acquire duration per instance;
- database active/idle connection count and configured maximum;
- failover/reconnect behavior;
- migration job isolation;
- worker and reporting pool budgets;
- rejection/backpressure behavior when the pool is saturated.

Increasing `DB_POOL_MAX` is not a latency fix unless the database has spare CPU/I/O and connection capacity. Horizontal scaling multiplies the budget.
