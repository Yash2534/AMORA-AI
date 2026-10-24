# AMORAA S3 database connection capacity plan

Date: 2026-10-12

Status: **BLOCKED — REAL STAGING CONFIGURATION REQUIRED**

The repository default API pool maximum is 10. This is a bounded default, not approved staging or production sizing. No staging MySQL 8 `max_connections`, API/worker replica count or reporting pool is available, so the final budget cannot be calculated honestly.

## Required worksheet

`app_connections = api_instances × api_pool_max`

`worker_connections = worker_instances × worker_pool_max`

`committed = app_connections + worker_connections + migration_pool + reporting_pool + monitoring_pool`

`headroom = mysql_max_connections - committed - admin_maintenance_reserve`

| Input | Required staging value | Current evidence |
|---|---:|---|
| API instances | at least 2 | Not deployed |
| API pool max | record deployed `DB_POOL_MAX` | repository default 10 only |
| Worker instances/pool | record actual | no worker exists |
| Migration pool | record release-job cap | not deployed |
| Reporting pool | zero or separately bounded | not deployed |
| Monitoring/backup connections | provider value | unavailable |
| MySQL `max_connections` | query/config export | unavailable |
| Admin/maintenance reserve | DB owner approval | unavailable |

For illustration only, two APIs using the repository default would permit up to 20 API connections. This is arithmetic, not a recommendation; it excludes every other consumer and cannot be compared to an unknown DB limit.

## Acceptance

Record the completed worksheet, keep an explicit reserve for migration/admin/monitoring/maintenance/failover, and observe pool used/idle/waiting/acquire duration plus DB active connections under S3 validation. Saturation must produce bounded backpressure and readiness/alerts, not an uncontrolled pool increase. Recalculate for every replica or worker-concurrency change.

