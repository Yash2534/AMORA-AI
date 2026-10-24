# AMORAA Phase S1 Repository Fix Report

Date: 2026-10-12

Scope: repository-only changes. No production mutation, production load test, Redis, object storage, queue, CDN, load balancer, or monitoring vendor was deployed. No concurrency capacity is claimed.

## Outcome

S1 removes the most direct unbounded repository paths and adds lifecycle/configuration boundaries needed for staging. It does not make AMORAA horizontally scalable: realtime fanout/presence, rate limiting, media/export storage, background work, and telemetry still need shared infrastructure and controlled staging tests.

## Fix register

| Issue | Original risk | Fix implemented and files | Test evidence | Remaining dependency | Status |
|---|---|---|---|---|---|
| AI discovery candidate loading | AI Matches loaded/ranked every eligible user in Node memory. | `discoverController.js` applies all rules in SQL, stable canonical ordering, and `AI_DISCOVERY_CANDIDATE_WINDOW` (default 500, hard range 30–2,000) before local ranking. | Integration regression proves exactly 500 of 501 candidates are considered; config hard-bound unit test. | Larger/global ranking needs evaluated versioned precomputation. | COMPLETE — REPOSITORY VERIFIED |
| Growing user lists | Matches, blocks, and privacy history were unbounded. | Validated page/limit, default 20, maximum 50, stable timestamp/id ordering, pagination metadata. | Unit cap test and existing list integrations. | Deep offsets are S2 keyset candidates. | COMPLETE — REPOSITORY VERIFIED |
| DB connection growth | Implicit Sequelize pool defaults. | Validated max/min/acquire/idle settings, bounded defaults, safe startup logging, close/readiness helpers. | Pool default/custom/invalid tests. | Staging measurement and DB-wide connection budget. | COMPLETE — REPOSITORY VERIFIED |
| Shutdown | Signals did not drain resources. | Idempotent SIGTERM/SIGINT drain: HTTP, Socket.IO, Sequelize; configurable failsafe and sanitized logs. | Ordered/idempotent unit test. | Orchestrator grace-period configuration. | COMPLETE — REPOSITORY VERIFIED |
| Health/readiness | Health could pass before DB/startup. | `/health/live` plus DB-backed `/health/ready`; 503 before init/during drain; no migrations. | Loopback HTTP test. | Load balancer must adopt the endpoints. | COMPLETE — REPOSITORY VERIFIED |
| Migration race | Workers silently migrated concurrently. | Production defaults to verification-only and fails on pending migrations; explicit migration command remains. | Migration-mode and existing migration tests. | Release-job adoption and least-privilege roles. | COMPLETE — REPOSITORY VERIFIED |
| Offer consistency | Mutable Map and synchronous local JSON writes. | Offers read/written through existing `PlatformSettings`; JSON is immutable bootstrap fallback. | Admin financial/full suite evidence. | S2 can strengthen simultaneous-edit conflict semantics. | COMPLETE — REPOSITORY VERIFIED |
| Rate limiting | MemoryStore is per process. | Named replaceable store factory; production can require distribution and fails closed while no adapter exists; P-33 limits unchanged. | Store-factory/config tests. | Shared atomic store and 2+ node test. | PARTIAL — INFRASTRUCTURE REQUIRED |
| Realtime | Local rooms/presence; overlapping reconnect loop. | Encapsulated registry, adapter injection, idempotent subscriptions, randomized capped client backoff, socket metric. | Registry test, existing realtime integration, Flutter suite. | Shared Socket.IO adapter/global presence. | PARTIAL — INFRASTRUCTURE REQUIRED |
| Upload memory | `memoryStorage` buffers files. | Existing strict size/count/MIME/signature boundaries retained and oversize rejection tested. | Multipart limit test returns `LIMIT_FILE_SIZE`. | Direct private object upload/streaming and workers. | PARTIAL — INFRASTRUCTURE REQUIRED |
| Privacy export | Download buffered whole file and consumed before delivery. | Read stream, private/no-store response, consume after finish. | Privacy integrations/full suite. | Generation remains synchronous/local; durable job + private object storage. | PARTIAL — INFRASTRUCTURE REQUIRED |
| Providers | Email/SMS could wait on defaults. | SMTP connect/greeting/socket timeouts; Twilio 10-second timeout/no auto retry; duration/outcome hooks. | Provider failure tests/full suite. | Durable delivery queue. | COMPLETE — REPOSITORY VERIFIED |
| Admin reporting | Full-table totals/reconciliation. | Revenue totals use DB `SUM`; reconciliation detail reads capped at 1,000 per source. | Admin integrations/full suite. | DB-side grouped/keyset rewrite and async exports. | DEFERRED — PHASE S2 |
| Flutter cache | Chat media Future map unbounded. | Chat LRU 64 items/32 MiB; global image cache 300 items/100 MiB. | Changed files analyze cleanly; Flutter suite. | Representative device profiling. | COMPLETE — REPOSITORY VERIFIED |
| Flutter reconnect/duplicates | Fixed reconnect could overlap; repeated subscriptions. | Socket.IO owns capped backoff; desired rooms restored once and active subscriptions deduplicated. | Flutter suite/analysis. | Cross-node soak test. | COMPLETE — REPOSITORY VERIFIED |
| Observability | No standard performance hooks. | Vendor-neutral HTTP/DB/provider/rate-limit/socket hooks with bounded non-PII labels. | Focused/full tests exercise hooks. | Exporter, centralized logs, dashboards, alerts, traces. | PARTIAL — INFRASTRUCTURE REQUIRED |
| Discovery SQL/index design | JSON/function/distance expressions limit indexes. | DB-side eligibility retained; no risky broad S1 schema change. | SQL-vs-JS and EXPLAIN regression tests. | Generated/indexed primitives and staged EXPLAIN work. | DEFERRED — PHASE S2 |

## Configuration

Added to `Backend/.env.example`: `DB_POOL_MAX`, `DB_POOL_MIN`, `DB_POOL_ACQUIRE_MS`, `DB_POOL_IDLE_MS`, `DB_MIGRATION_STARTUP_MODE`, `AI_DISCOVERY_CANDIDATE_WINDOW`, `SHUTDOWN_TIMEOUT_MS`, `REQUIRE_DISTRIBUTED_RATE_LIMIT`, and `ENABLE_PERFORMANCE_METRICS`. None assumes production capacity.

## Verification and remaining gates

Baseline: `evidence/S1_BASELINE.md`. Final evidence: `evidence/S1_FINAL.md`. The backend finished at 365/365 tests; Flutter finished at 659 passed, 14 skipped, and 0 failed; Flutter analysis remained at the baseline 44 warning/informational findings. Repository tests are regression evidence, not capacity evidence.

Remaining gates are shared Socket.IO/presence, shared rate limits, private object storage/CDN, durable queues/workers, S2 query/index work, centralized observability, and production-like staging load tests.

Horizontal scaling status: **NO**. Production scalability verified: **NO**.
