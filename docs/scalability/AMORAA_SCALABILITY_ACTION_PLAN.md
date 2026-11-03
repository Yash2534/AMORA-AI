# AMORAA scalability action plan

> Phase S3 update (2026-10-12): the staging architecture and validation pack is prepared, but the actual environment is unapproved/unavailable. Build and evidence collection are blocked on DevOps/management resources; S4 remains gated. Do not treat planning documents as deployed infrastructure.

> Phase S2 update (2026-10-12): the first plan-supported index/query pass is implemented and locally verified. Remaining S2-style work—MySQL 8 representative plans, slow-query review, JSON/compatibility strategy, recommendation rollups, keyset API contracts, and contention evidence—moves into the S3 staging gate rather than receiving speculative schema changes.

> Phase S1 update (2026-10-12): code-side lifecycle, bounds, configuration, adapter seams, Flutter protections, and instrumentation hooks are implemented. Proceed to Phase S2 database/query optimization while preparing Phase S3 staging shared services. Capacity claims remain blocked until controlled S4 staging tests.

## Prioritization rule

P0 means a production or horizontal-scaling gate. P1 means required before material traffic growth or before load-test escalation. P2 may wait until evidence shows pressure. No infrastructure is introduced solely for fashion; each service below maps to a verified repository limitation.

## Phase S1 — Repository scalability fixes

Required before serious staging load tests:

- Redesign `/api/discover/ai-matches` so database and Node work are bounded independently of total eligible users.
- Enforce pagination on match, block, privacy history, matching/admin grievance, and all other growing lists.
- Replace in-memory filtering/slicing of admin matching failures and full-table recommendation metrics with bounded SQL aggregates.
- Remove full-table financial analytics and per-plan N+1 counts from request paths.
- Add graceful SIGTERM/SIGINT handling and configurable HTTP/header/keepalive/drain timeouts.
- Split liveness and readiness; readiness must verify required dependencies with short deadlines.
- Remove automatic migration execution from API startup; add a single migration command/job and keep startup schema validation read-only.
- Move offers from the source-tree JSON file/process `Map` into a shared transactional store.
- Add explicit Sequelize pool configuration and metrics hooks.
- Add request-level route/status/duration metrics, event-loop lag, memory, pool state, and real socket counts.
- Bound Flutter media caches, coalesce event-driven refreshes, and fix reconnect ownership/backoff.
- Introduce client message idempotency before retry-heavy load tests.

Exit evidence: unit/integration tests, static route inventory showing every growing list bounded, two rolling shutdown tests locally/staging, and no API-start DDL.

## Phase S2 — Database and index optimization

- Capture staging query plans for discovery, relationships, chat/unread, admin, financial, moderation, and privacy paths.
- Add only plan-proven indexes listed in `DATABASE_SCALABILITY_AUDIT.md`.
- Resolve duplicate block reverse indexes and schema/model drift.
- Normalize high-value discovery filters; create an indexable location prefilter and bounded candidate generation.
- Replace deep offsets with keyset cursors for conversations, users, reactions, payments, audit/moderation queues.
- Add aggregate/rollup tables or jobs for dashboards and match metrics.
- Define retention/archival for recommendation telemetry, audit logs, notifications/deliveries, OTPs, and operational events.

Exit evidence: reviewed migrations, before/after `EXPLAIN ANALYZE`, slow-query results, write-cost assessment, and rollback plan.

## Phase S3 — Staging infrastructure

This phase is required because repository changes cannot prove horizontal behavior:

- isolated production-like staging with two or more API nodes;
- MySQL HA/failover-capable staging shape where feasible;
- shared Socket.IO adapter/pub-sub and distributed rate-limit store;
- object storage for profile/chat/verification/export artifacts;
- durable queue with separately deployable workers;
- TLS/WSS load balancer, exact proxy-hop configuration, health checks, and drain settings;
- centralized logs/metrics/traces, dashboards, alerts, and on-call ownership;
- synthetic scale datasets and stubbed/sandbox external providers.

Exit evidence: cross-node socket/rate/media tests, object lifecycle/deletion tests, queue retry/DLQ tests, migration job proof, rolling deploy proof, and monitoring screenshots/exports.

## Phase S4 — Load testing

Execute Stages A–E from `LOAD_TEST_PLAN.md`, stopping on abort gates. Repeat each failed stage after remediation. Run dataset-shape tests separately from concurrency tests so population and concurrency effects are distinguishable.

Exit evidence: immutable run reports with commit/config/dataset, raw metrics, slow queries, correctness checks, bottleneck analysis, and approved safety headroom. This phase is the first point at which measured capacity claims may be made for the tested configuration.

## Phase S5 — Horizontal scaling and shared services

Only the shared services proven necessary by this audit are included:

- Socket.IO adapter/pub-sub;
- distributed rate-limit store (P-33);
- object storage and authorized delivery/CDN policy;
- queue/workers for provider delivery, media work, cleanup, and privacy export;
- DB read replica/reporting isolation if S4 shows admin/reporting contention;
- cache only for measured hot, safely invalidated reference data.

Validate autoscaling inputs, connection budgets, backpressure, dependency failure modes, and cost. Do not use sticky sessions as the correctness mechanism.

Exit evidence: 2/5/10-node functional tests as applicable, failover/reconnect results, consistent limits/presence/fanout, and no local durable state.

## Phase S6 — Production capacity and monitoring gate

- Approve explicit SLOs and alert thresholds.
- Establish tested capacity for the exact production topology/workload with safety headroom; never generalize beyond evidence.
- Verify dashboards for HTTP, DB, Node, sockets, shared store, object storage, workers/queues, providers, and mobile release health.
- Verify backups/restores, DB failover, shared-store failure policy, queue replay/DLQ, object deletion, and incident runbooks.
- Set release rollback thresholds and named owners.

Exit: signed engineering/DevOps/product gate with links to load evidence. Until then, production scalability verified remains NO.

## What can wait

P2 work may wait until monitoring or load evidence justifies it: broad application caching, dedicated search infrastructure for low-volume admin reference search, table partitioning before retention/index tuning is exhausted, multi-region deployment, and sophisticated recommendation serving. Do not defer P0 local-state, unbounded AI discovery, pool, migration, readiness, shutdown, storage, rate-limit, or observability work.
