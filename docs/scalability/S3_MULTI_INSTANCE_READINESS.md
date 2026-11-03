# AMORAA S3 multi-instance readiness

Date: 2026-10-12

Overall status: **PARTIAL — INFRASTRUCTURE REQUIRED**

| Concern | Repository state | Two-instance requirement | Status |
|---|---|---|---|
| HTTP state | JWT-authenticated REST; no Express session dependency | Alternate requests between instances without affinity | READY FOR STAGING VALIDATION |
| Database pool | Explicit bounded pool configuration | Calculate fleet budget against real MySQL 8 `max_connections` | PARTIAL |
| Migrations | Production-style startup defaults to verification | One migration job; API/worker identities have no DDL | REPOSITORY READY |
| Health | Separate liveness/readiness; readiness checks DB and shutdown state | Edge removes unready node and observes recovery | READY FOR STAGING VALIDATION |
| Shutdown | HTTP, Socket.IO and DB drain service exists | Validate acknowledged writes and reconnect during scale-in | READY FOR STAGING VALIDATION |
| JWT/session | JWT plus database token-version/account-state checks | Same secrets and authoritative DB across replicas | READY FOR STAGING VALIDATION |
| Realtime | Adapter injection exists; presence remains local | Shared adapter plus shared TTL presence | BLOCKED — INFRASTRUCTURE REQUIRED |
| Rate limiting | Named store factory exists; default is local memory | Shared atomic store; cross-node threshold test | BLOCKED — INFRASTRUCTURE REQUIRED |
| Files | Profile/chat/verification/export paths are local | Private shared object storage and object-key persistence | BLOCKED — IMPLEMENTATION/INFRASTRUCTURE REQUIRED |
| Jobs | No durable queue/worker | Broker, worker, retry, idempotency and DLQ | BLOCKED — IMPLEMENTATION/INFRASTRUCTURE REQUIRED |
| Observability | In-process counters/durations only | Exporters, fleet aggregation and instance identity | BLOCKED — INFRASTRUCTURE REQUIRED |

## Validation procedure

Deploy the same immutable artifact as instances A and B. Confirm both report ready, then send authenticated reads and idempotent writes while alternating nodes. Establish sockets on different nodes and validate message/read/admin/presence behavior. Exhaust a named limit while alternating nodes. Upload through A and read through B. Enqueue on A and consume on the worker. Terminate A first gracefully and then in a separately approved abrupt test; confirm the edge removes it, B continues, sockets reconnect, no acknowledged write is lost and alerts fire.

Record instance IDs only in telemetry, never as an authorization input. Sticky sessions may be used for transport efficiency but are not accepted as a substitute for shared state.

## Acceptance

Pass requires the above checks against two staging instances with artifact links. Repository inspection alone cannot change horizontal scaling to YES.

