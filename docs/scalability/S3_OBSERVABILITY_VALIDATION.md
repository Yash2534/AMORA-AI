# AMORAA S3 observability validation

Date: 2026-10-12

Status: **BLOCKED — EXPORTERS AND CENTRAL PLATFORMS REQUIRED**

S1 provides bounded in-process HTTP/DB/provider/rate-limit/socket hooks. They are ephemeral and do not provide fleet percentiles, persistence, tracing or alerts.

## Required signals

- HTTP: normalized route/method/status count, active requests, p50/p95/p99, timeouts/aborts and 4xx/5xx.
- Runtime: instance/build, CPU, RSS/heap/external memory, GC, event-loop lag, restart and graceful-drain outcome.
- Database: query class latency, pool max/in-use/idle/waiting/acquire duration/timeouts, connections, CPU/IO, locks/deadlocks and slow-query digests.
- Realtime: per-instance/fleet sockets, auth failures, reconnects, fanout latency/errors, adapter and presence-store errors.
- Shared store: latency/errors/connections/memory/eviction and rate-limit operation/error counts.
- Queue: depth, oldest age, enqueue/process latency, active, retry, timeout, failure and DLQ.
- Storage/provider: request latency/errors/bytes, lifecycle failures, email/SMS/push latency/error class.

## Logging and tracing

Centralize structured logs with correlation ID, sanitized normalized route, bounded error category, instance ID, build and environment. Restrict access and document retention/immutability/time synchronization. Redaction tests must cover passwords, JWT/cookies, OTP, MFA, contact fields, exact location, payment/provider secrets, message/profile text and signed URLs.

Trace edge → API → DB/shared store/queue → worker → storage/provider using sampled traces and propagated correlation. Do not place SQL bind values, request bodies or sensitive identifiers in spans. Sampling and retention require an owner.

## Dashboards and alerts

Create API, database, realtime/shared-store, queue/worker, storage/provider and security-abuse dashboards. Alert rules must be calibrated during S3/S4, routed to named owners and tested. Initial gates include sustained 5xx, readiness failures, pool acquire failures, deadlocks, adapter/store outage, queue age/DLQ growth, storage failures and missing telemetry. Exact thresholds are not invented here.

Pass requires configuration exports, sample ingestion, redaction negatives, dashboard links, alert delivery/acknowledgement and linked runbooks. None is currently available.

