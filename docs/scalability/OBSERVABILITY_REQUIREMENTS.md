# Observability Requirements

Status: **PARTIAL — EXPORTER/PLATFORM REQUIRED**

S1 adds vendor-neutral in-process hooks for HTTP request counts/status classes and latency, opt-in Sequelize query duration, provider success/failure and latency, rate-limit events, and local socket connection count. Labels are bounded and contain no URL IDs, user IDs, tokens, phone numbers, emails, or request bodies.

Required production metrics:

- HTTP request rate, p50/p95/p99 latency, 4xx/5xx rate, active requests, timeout/abort count;
- DB query latency by bounded operation class, pool size/in-use/waiting/acquire timeout, connection failures, DB CPU/connections, and slow-query log;
- event-loop lag, process CPU/RSS/heap/GC, restart and graceful-drain outcomes;
- current sockets per instance, reconnects, adapter errors, fanout rate, presence transitions;
- login/OTP failure and rate-limit counts without identity labels;
- email/SMS/push latency/failure categories;
- job queue depth, oldest-job age, retry and DLQ counts after queues exist;
- object-storage/CDN latency/error rate and cache hit rate after media migration.

The in-process registry is a hook, not durable monitoring. Production still needs a metrics exporter/scraper, centralized structured logs, dashboards, alert routing, retention, and correlation IDs. Alert thresholds must be calibrated in staging load tests rather than invented from repository inspection.
