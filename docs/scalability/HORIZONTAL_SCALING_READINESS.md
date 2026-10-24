# AMORAA horizontal scaling readiness

> Phase S3 update (2026-10-12): the two-instance validation contract is complete, but no staging nodes/shared services exist. Realtime/presence, rate limiting, media/export storage, workers and centralized telemetry remain external blockers. Status remains **NO**.

> Phase S1 update (2026-10-12): status remains **NO**. HTTP lifecycle and migration startup are safer, DB pool limits are explicit, offers are DB-backed, and adapter seams exist. A second instance would still have incorrect global realtime presence/fanout, per-instance rate limits, and instance-local media/export artifacts.

Overall status: **NO**

The REST authentication model is mostly stateless, but three hard blockers prevent safe multi-instance operation: local Socket.IO state, process-local rate limits, and local files. Phase S1 removed mutable process-local offer state and added repository lifecycle/migration safeguards, but those safeguards still require staging deployment adoption.

## Readiness matrix

| Area | Status | Evidence / required action |
|---|---|---|
| JWT REST authentication | READY WITH CONDITIONS | Tokens are self-contained; requests still query account/token state where needed. Shared DB and synchronized secrets required. |
| Express sessions | READY | No server-side Express session dependency found. |
| Database access | PARTIAL | Phase S1 adds explicit validated per-process pool limits and query-duration hooks; fleet budgeting, HA/failover, and staging saturation evidence remain absent. |
| Migrations | READY WITH DEPLOYMENT CONDITION | Production API startup is verification-only and fails on pending migrations; deployment must run the explicit migration command once before traffic. |
| Graceful shutdown | READY WITH DEPLOYMENT CONDITION | Tested idempotent SIGTERM/SIGINT handling marks unready and closes HTTP, Socket.IO, and Sequelize with a deadline; the orchestrator grace period still needs staging proof. |
| Liveness/readiness | READY WITH CONDITIONS | `/health/live` is process-only and `/health/ready` checks initialization/drain state plus `SELECT 1`; load balancer wiring and timeout behavior need staging proof. |
| HTTP timeouts | NOT READY | Server request/header/keepalive/drain limits not explicit. |
| Socket.IO fanout | NOT READY | Default in-process adapter; rooms/events do not cross nodes. Add shared adapter/pub-sub and failure tests. |
| Presence | NOT READY | Process-local `connections` map. Define shared presence TTL/heartbeat or derived model. |
| Reconnect behavior | PARTIAL | Phase S1 removes the overlapping manual loop, deduplicates room subscriptions, and configures jittered capped backoff; test a fleet reconnect storm. |
| Rate limiting | NOT READY | Default in-memory stores, including admin auth. Implement shared distributed store; close P-33. |
| Profile/chat/verification media | NOT READY | Instance-local filesystem and memory-buffered uploads. Move to object storage. |
| Privacy exports | NOT READY | Generated/read/deleted on local disk in request process. Move to queued object-storage workflow. |
| Caches | READY WITH CONDITIONS | No critical app cache dependency found; any future cache must be shared or safely per-node. |
| Offer configuration | READY WITH CONDITIONS | Offers use shared `PlatformSettings`; the JSON file is bootstrap-only. Concurrent administrative edit conflict semantics remain an S2 hardening item. |
| Scheduled/background jobs | NOT READY | No real scheduler/queue/worker; sample admin job responses are not infrastructure. |
| Logging/metrics | NOT READY | Phase S1 adds bounded vendor-neutral hooks, but no exporter, central metrics/logging/tracing, alerting, or fleet-level socket view exists. |

## Required multi-instance architecture

1. Load balancer with TLS/WSS, health checks, connection draining, known proxy-hop topology, and WebSocket support.
2. Stateless API nodes with identical secrets/config, explicit resource limits, and graceful shutdown.
3. Managed/HA MySQL topology sized from measured workload, with pool budgets per API/worker instance.
4. Redis-compatible shared service (or equivalent) for Socket.IO adapter/pub-sub and distributed rate limits. Cache use should remain separately namespaced and optional.
5. Object storage for all user media, verification files, and exports; CDN only where authorization permits.
6. Durable queue and separately scalable workers for provider delivery, privacy exports, media processing, and cleanup.
7. One controlled migration job before traffic shift; backward-compatible expand/migrate/contract releases.
8. Central logs, metrics, traces, dashboards, alerts, and per-instance plus fleet-level labels.

Sticky sessions are not a substitute for the shared Socket.IO adapter, distributed rate limiter, or object storage. They may reduce transport churn but preserve failure and imbalance risks.

## Instance-count expectations before remediation

- **1 instance:** coherent local realtime/rate/file behavior, but a single point of failure and no verified capacity.
- **2 instances:** missed cross-node socket events, incorrect presence, doubled/resettable limits, and media/export 404s on the wrong node. Offers are now shared through the database, subject to the documented concurrent-edit hardening item.
- **5 instances:** frequent inconsistency and operational dependence on routing affinity; DB pool multiplication becomes significant.
- **10+ instances:** unsafe without shared services, explicit connection budgets, autoscaling signals, queue backpressure, and reconnect-storm validation.

## Graceful shutdown contract

Implement and test:

1. mark readiness false;
2. stop accepting new HTTP/WebSocket connections;
3. allow a bounded drain window for in-flight HTTP requests;
4. notify/close sockets so clients back off and reconnect;
5. stop claiming queue work and finish/return leased jobs;
6. close Socket.IO, HTTP server, and Sequelize;
7. force exit only after a logged deadline.

## Readiness gate

Horizontal scaling may change from NO to PARTIAL after repository blockers are fixed and a two-node staging test proves cross-node REST, socket fanout, presence, distributed rate limiting, media access, migration safety, and rolling shutdown. It becomes YES only after the target production-like topology passes staged load/failure tests with monitoring evidence.
