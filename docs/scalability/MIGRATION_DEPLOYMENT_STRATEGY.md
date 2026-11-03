# Migration Deployment Strategy

Status: **COMPLETE — REPOSITORY VERIFIED; deployment adoption required**

Production application workers now default `DB_MIGRATION_STARTUP_MODE` to `verify`. Startup authenticates, reads `SequelizeMeta`, and fails clearly when migrations are pending; it does not apply them. Development and test default to `apply` to preserve local workflows. An explicit override to `apply` exists but must not be used for a multi-worker production rollout.

Deployment order:

1. Back up and validate the target schema using the operator's normal database controls.
2. Run one release job: `cd Backend && npm run db:migrate`.
3. Confirm `npm run db:migrate:status` reports every repository migration as `up`.
4. Start application workers with `DB_MIGRATION_STARTUP_MODE=verify`.
5. Use `/health/ready` as the load-balancer gate; a worker is not ready before initialization and DB verification.

Migrations must remain backward-compatible across a rolling release. Destructive column removal or semantic rewrites require an expand/migrate/contract sequence in a later release. The release job needs the same TLS and database identity controls as the application but should have migration-specific DDL permission; application workers should not need DDL permission.

Rollback means rolling the application back to a schema-compatible release. `db:migrate:undo` is an operator tool, not an automatic deployment rollback, because data-destructive reversals require explicit review.
