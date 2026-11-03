# AMORAA scalability and performance audit

> Phase S3 update (2026-10-12): an execution-ready isolated staging architecture, synthetic-data tiers, MySQL 8/slow-query capture protocol, multi-instance/shared-service validation plans, reporting-isolation ladder, observability contract, DB budget worksheet and S4 checklist now exist. No approved staging infrastructure is available, so every external runtime gate remains **BLOCKED — INFRASTRUCTURE REQUIRED**. Horizontal scaling remains **NO** and no capacity is claimed.

> Phase S2 update (2026-10-12): local/repository database work adds geographic bounding before exact distance, six plan-supported indexes, duplicate-index removal, stable privacy chronology, bounded admin date domains, grouped financial aggregates, transactional offer mutation, and opt-in statement timeouts. Local synthetic `EXPLAIN`/`ANALYZE` validates access-path changes but does not establish production latency or capacity. Database status remains **PARTIAL — STAGING REQUIRED**; horizontal scaling remains **NO**.

> Phase S1 update (2026-10-12): repository fixes now bound AI candidate loading; cap matches/blocks/privacy lists; configure the DB pool; separate liveness/readiness; drain HTTP/realtime/DB on signals; verify rather than auto-migrate in production; store offers in MySQL; stream privacy downloads; bound Flutter caches/reconnects; and add metrics hooks. Shared realtime, rate-limit, media/export, queue, and monitoring infrastructure remains unresolved. Horizontal scaling and production capacity remain **not verified**. See `AMORAA_PHASE_S1_REPOSITORY_FIX_REPORT.md`.

Audit date: 2026-10-12  
Scope: repository-only static audit of the Flutter client and the Node.js, Express, Socket.IO, Sequelize, and MySQL backend.  
Safety boundary: no production access, production mutation, production load test, cloud change, or capacity claim was performed.

## Executive verdict

AMORAA is **partially scalable at repository level but is not horizontally ready and production scalability is not verified**. The code already has several sound foundations: authenticated stateless REST calls, bounded request bodies, cursor pagination for discovery and message history, bounded page sizes on many user/admin lists, transactional state changes, useful composite indexes, connection-safe ORM use, and asynchronous filesystem APIs on most request paths.

The remaining release blockers are architectural rather than cosmetic:

1. Discovery is now candidate-bounded and geographically prefiltered, but calculated compatibility, JSON operations, reciprocal preference checks and final distance/score ordering still need representative MySQL 8 evidence.
2. Socket.IO fanout and presence remain process-local because no shared adapter/presence store is deployed.
3. Rate-limit policy stores remain local memory because no shared atomic store is deployed. P-33 remains incomplete.
4. Profile, chat, identity-verification and privacy-export files remain on instance-local filesystems.
5. Privacy export, provider delivery, push fanout, media processing and heavy reporting still lack durable queue/worker execution.
6. Pool configuration, readiness, graceful shutdown and local metrics hooks now exist, but HTTP timeout completion, fleet telemetry, slow-query monitoring and real alerting remain incomplete.
7. Residual exact counts, date grouping, contains searches, correlated unread counts and deep offsets require staging plans/measurements and selective rollup or keyset work.

## Evidence basis and important limitations

Evidence was taken from current source, models, migrations, routes, tests, `amora_ai.sql`, and existing security documents. `tmp/project_audit/mysql_schema.json` describes a 33-table local snapshot, while current migrations define many later tables. It is useful evidence of one past local schema, not proof of the current staging or production schema.

No live `EXPLAIN`/`EXPLAIN ANALYZE`, production row counts, traffic distribution, CPU profile, heap profile, slow-query log, database configuration, proxy topology, or deployment topology was available. Every capacity statement below is therefore a risk assessment, not a throughput guarantee.

## What is already scalable

- REST authentication is JWT-based and does not depend on an Express session stored in one process.
- Most mutation paths use database transactions and row locks where race conditions matter, including payments, privacy workflow, conversation creation, OTP verification, and account lifecycle changes.
- Discovery's non-AI path uses signed keyset/cursor pagination and limits responses to at most 30 candidates.
- Message history uses `beforeId` keyset pagination and appropriate `(conversationId, id)` indexing.
- Most list endpoints cap page size. Admin shared pagination caps at 100.
- Important uniqueness/idempotency indexes exist for matches, reactions, conversation pairs, conversation membership, payments, notifications, roses, saved profiles, and provider events.
- MySQL TLS is required in production and database access uses Sequelize parameterization or bound replacements.
- Upload type and size checks exist, request JSON is limited to 100 KB, and private media routes enforce authorization.
- Flutter reuses an HTTP client, coalesces token refresh, uses paginated discovery/chat APIs, uses render-size image decoding when dimensions are supplied, and has no continuous application-data polling loop in the audited code.

## Backend architecture findings

### P0 / release-gate findings

**B-01 — Discovery calculations remain expensive.** S1 bounds AI candidate loading and S2 adds an indexable geographic prefilter, but compatibility/JSON expressions, reciprocal checks and exact distance/ordering remain within the bounded window. Representative MySQL 8 plans and controlled load evidence are still required.

**B-02 — Graceful shutdown requires deployment proof.** The repository now handles SIGTERM/SIGINT, marks unready and closes HTTP, Socket.IO and Sequelize with a bounded deadline. Load-balancer removal and orchestrator grace-period behavior remain unverified in staging.

**B-03 — Migration separation requires deployment adoption.** Production-style startup now defaults to verification and fails on pending migrations. A single migration job and least-privilege application identities must still be proven in staging.

**B-04 — Readiness is repository-ready but not wired.** `/health/live` is process-only and `/health/ready` checks initialization, shutdown and database connectivity. Edge health-check behavior and dependency time budgets remain staging work; sample admin job/storage health responses are not infrastructure evidence.

### P1 findings

- Sequelize pool settings are not explicit. The effective pool size, acquire timeout, idle timeout, validation, and total fleet connection budget depend on library defaults and deployment instance count.
- HTTP `requestTimeout`, `headersTimeout`, `keepAliveTimeout`, maximum connections, and shutdown drain deadline are not configured.
- `bootstrapEnv.js`, database CA loading, storage directory creation, and the offer store use synchronous filesystem calls. Startup-only reads are low risk, but `adminFinancialService.js` performs synchronous JSON persistence for offers on request paths and keeps an instance-local `Map`.
- Multer uses `memoryStorage`: profile uploads can buffer up to six 12 MB files, identity verification up to two 12 MB files, and chat media up to 10 MB per request. Concurrency can produce large transient heap/external-memory pressure.
- Password/OTP bcrypt work is asynchronous but consumes the libuv worker pool and CPU. Login/OTP concurrency must be measured; it must not share an undersized worker pool with other expensive work unnoticed.
- Privacy export builds arrays, pretty-prints one JSON string, hashes it, writes it, later reads the complete artifact into a `Buffer`, and sends it. This is synchronous workflow at the API level and scales with a user's history.
- Push delivery loops across devices and waits for network requests. SMTP, SMS, and admin password mail also execute in request workflows. Provider latency directly affects API latency.
- `securityEventMiddleware` performs a database audit write after every classified response. It is non-blocking for the response but adds DB write load and has no durable buffer if the DB/sink is unavailable.
- No general request de-duplication/idempotency exists for chat messages; client/network retries can create duplicate messages.

## Discovery and matching by growth stage

These stages refer to registered-user population, not concurrent capacity.

### Around 10,000 users

The standard feed may remain operational with selective filters, current cursor limits, appropriate data distribution, and adequate DB resources, but this must be measured. Likely early pain points are function-based compatibility ordering, Haversine distance over many profiles, JSON filtering, AI-match full-pool ranking, and count-based observability. The AI path can already be materially expensive if a viewer has a broad eligible pool.

### Around 100,000 users

The current AI path is a high-confidence bottleneck. Standard discovery is also likely to spend substantial DB CPU calculating a score and distance for many rows before it can select the top page. `LOWER`, `CAST`, `JSON_SEARCH`, `JSON_CONTAINS`, JSON extraction, and calculated ordering prevent ordinary B-tree indexes from solving most of the work. Reverse likes need a target-first index. Admin/reporting counts and full-table match metrics compete with user traffic.

### Around 1,000,000 users

The current design requires architectural change: bounded candidate generation, geospatial/indexable filtering, normalized searchable attributes, precomputed or asynchronously refreshed features/scores, versioned recommendation snapshots or a candidate cache, partition/retention strategy for high-volume event/audit/message tables, and isolated reporting. This is a design requirement, not evidence that any specific alternative will meet capacity.

## Chat and realtime behavior by backend instance count

### One instance

Basic Socket.IO delivery works. Presence is derived from a local connection counter and generates multiple DB reads per connected user's conversation membership. A connect/disconnect can fan out through an N+1 pattern: list memberships, then for each conversation query participants, blocks, and active match. Large-contact users amplify DB work. Message fanout also revalidates participants/block/match after message persistence.

### Two instances

Presence becomes inconsistent: each process sees only its own sockets. A user connected to instance A can be reported offline when their connection to instance B changes. `io.to(userRoom)` only reaches sockets in the emitting process, so REST writes landing on one instance can miss recipients connected to another. Rate limits also double in effective allowance.

### Five instances

Missed fanout and presence flapping become routine rather than edge cases. Restarting one node erases its counters and rate-limit buckets. Local media affinity becomes a major availability problem unless sticky routing is attempted; sticky routing does not solve failover or REST/event fanout.

### Ten or more instances

A shared Socket.IO adapter/pub-sub layer and durable/derived presence strategy are mandatory. Shared distributed rate limiting and object storage are also mandatory. Capacity must include pub/sub fanout, adapter failure behavior, reconnect storms, DB authentication queries on reconnect, and load-balancer WebSocket limits.

Delivery acknowledgements exist only for `conversation.subscribe`. There is no client-generated message id, end-to-end delivery acknowledgement protocol, or exactly-once guarantee. Event payloads for most user events lack a universal event id, so deduplication after reconnect is incomplete.

## Rate limiting and P-33

`rateLimiter.js` defines useful separate policies for login, signup, OTP request/verify/reset, account deletion, profile/chat media, swipes, messages, reports, events, payments, roses, verification, downloads, grievances, and privacy requests. Trusted proxy hops are bounded to 0–3 and fail closed on malformed configuration.

However, every limiter uses the default in-memory store. Enforcement is per process, lost on restart, and multiplied by fleet size. The admin-auth route defines additional local in-memory limiters. Google login, refresh-token, logout, several read-heavy endpoints, and some sensitive admin mutations do not use a shared global abuse policy. Proxy correctness depends on the deployed `TRUST_PROXY_HOPS`, which is not proven in repository evidence.

P-33 therefore remains **PARTIAL / infrastructure evidence required**, consistent with the existing security ledger. Production requires a shared store, exact proxy topology validation, deterministic cross-instance threshold/recovery tests, bounded failure behavior if the store is unavailable, and rate-limit/abuse alerting.

## Media and file storage

The backend stores profile photos under `Backend/uploads`, chat and identity media under `Backend/private-uploads`, privacy exports under `Backend/private-exports`, and offers under a source-tree JSON file. These are single-instance dependencies.

Required production architecture:

- Object storage for profile, chat, verification, and export artifacts.
- Private buckets/containers for chat, verification, and exports; profile media policy should be explicit rather than implicitly public.
- Short-lived signed URLs or an authenticated media gateway; CDN only for content whose authorization and cache key policy are correct.
- Streaming upload/download, image re-encoding/metadata stripping, thumbnails/variants, lifecycle expiry, malware/content scanning where appropriate, and deletion jobs with retries.
- Database-stored object keys and states; never instance-local absolute paths.

Cloud configuration is not implemented by this audit.

## Background work and queues

| Work | Current behavior | Required direction |
|---|---|---|
| Email/SMS/OTP | Provider call awaited by API | Queue after durable OTP creation where product flow permits; retry with expiry-aware policy; DLQ/provider telemetry |
| Push notifications | Device fanout performed from API process | Queue per notification/batch; bounded concurrency; retry invalid/transient outcomes; DLQ |
| AI matching | SQL plus full-pool Node ranking in request | Bounded online retrieval plus asynchronous feature/snapshot preparation |
| Privacy export | Generated in request; local file | Durable job, object storage, status polling/event, retry, expiry/deletion workflow |
| Media processing | Memory upload and raw file write | Direct/signed upload where justified, worker-based validation/re-encoding/thumbnails/scanning |
| Account file deletion | Task row created and executed inline | Worker claims persisted tasks; lease timeout, retry/backoff, DLQ/manual repair |
| Moderation/reporting | Mostly request-time DB work | Queue media analysis and large report generation; keep transactional state changes synchronous |

The admin `/system/jobs` response is sample data and the retry endpoint only audits a request; it is not evidence of a queue or active worker.

## Caching

Good shared-cache candidates are platform/app configuration, active legal documents, taxonomy/filter catalogs, subscription/rose reference catalogs, and short-lived admin reference data. Discovery configuration may be cached with versioned invalidation. Public profile fragments can be cached only with viewer-independent fields and explicit invalidation.

Do not broadly cache authentication/session validity, token version, account status, permissions/MFA state, block relationships, match/message authorization, privacy artifacts, identity documents, or full private profiles. These require authoritative reads or narrowly scoped, short-lived caches with invalidation. Redis is justified first for distributed rate limiting and Socket.IO pub/sub; application caching is secondary and must have a stale-data policy.

## Admin and reporting isolation

Admin pagination is generally bounded, but high-risk exceptions exist:

- dashboard executes roughly two dozen queries concurrently, including global counts/sums and time-series aggregations;
- analytics repeats global counts and financial overview work;
- match recommendation metrics loads complete recommendation, action, rose, and match tables into Node;
- financial overview and analytics contain unbounded payment/subscription reads and per-plan count loops;
- matching failure review loads all matching failure rows then enriches/filter/slices in memory;
- admin matching list-all paths and legacy/admin privacy grievance lists are unbounded;
- substring `LIKE '%term%'` searches and joined searches cannot use normal prefix B-tree indexes effectively;
- `findAndCountAll` plus deep offsets can become expensive even when page size is bounded.

Admin traffic must use a read replica/reporting database or pre-aggregated tables once it materially competes with user traffic. Immediately, cap date ranges and result sizes, move all filtering/pagination into SQL, remove full-table in-memory metrics, cache/precompute dashboards, and set statement/query time budgets.

## Observability assessment

Present: sanitized console logger, security audit records, correlation ids, a match-engine diagnostic log with duration buckets/candidate counts, and a protected admin DB health check.

Missing for a production gate: structured central log sink, request duration/status/route metrics, p50/p95/p99, event-loop lag, CPU/RSS/heap/GC, Sequelize pool used/idle/pending/acquire latency, DB query duration/slow-query sampling, socket counts by instance and globally, reconnect/auth failures, message/event rates, queue depth/age/retry/DLQ, provider latency/error classes, object-storage errors, cache hit/latency, and alert/SLO ownership. The current admin health claims for sockets/storage/jobs must be replaced with measured states.

## Single points of failure

| Priority | Point | Failure effect |
|---|---|---|
| P0 | Single MySQL topology / no HA evidence | Whole application unavailable or data at risk |
| P0 | Local media and export files | Missing/lost user, verification, chat, and privacy artifacts across nodes or replacement |
| P0 | One effective realtime domain with local state | Missed events and incorrect presence when scaled |
| P0 | Per-process rate limits | P-33 abuse control bypass/inconsistency |
| P1 | No durable worker/queue | Slow requests, lost asynchronous intent, no controlled retries |
| P1 | One SMTP/SMS/push provider path | Authentication/notification degradation without failover or queued recovery |
| P1 | Application-start migrations | Fleet startup race and outage coupling |
| P1 | Local console logs | Incident evidence unavailable after process/host loss |
| P2 | Redis, if introduced as one unprotected node | Rate-limit/realtime/cache degradation; deploy HA or explicit fail behavior based on use |

## Project performance targets (proposed, not measured facts)

Targets are gates to validate on staging, not claims about current performance:

- User read APIs: p50 <= 200 ms, p95 <= 500 ms, p99 <= 1,000 ms.
- User write APIs excluding external-provider completion: p50 <= 250 ms, p95 <= 750 ms, p99 <= 1,500 ms.
- Discovery: p50 <= 300 ms, p95 <= 800 ms, p99 <= 1,500 ms under the tested dataset and filter mix.
- Message persistence acknowledgement: p95 <= 500 ms; realtime delivery to an online recipient measured separately, p95 <= 1,000 ms.
- Error rate excluding expected 4xx: < 1% per stage; zero data-integrity violations.
- Sustained CPU target: < 70% per app node and DB; no sustained event-loop lag > 100 ms.
- App memory: stable after steady-state warm-up; no monotonic heap/RSS growth; document maximum RSS per node from test evidence.
- DB pool: < 80% sustained utilization, acquire p95 within the configured budget, zero avoidable pool timeouts.
- Queue: oldest-job age and depth within scenario-specific SLOs; zero unexplained DLQ entries.
- Cache: track hit rate only for approved caches; no target until access patterns are measured.

Requests/sec, supported concurrency, socket capacity, and database connection limits must be established by controlled load tests, not specified here as facts.

## Production gate conclusion

Horizontal scaling ready: **NO**.  
Production scalability verified: **NO**.  
Next phase: S1 repository scalability fixes followed by S2 index/query validation and S3 staging infrastructure.

See also:

- `DATABASE_SCALABILITY_AUDIT.md`
- `FLUTTER_PERFORMANCE_AUDIT.md`
- `HORIZONTAL_SCALING_READINESS.md`
- `LOAD_TEST_PLAN.md`
- `SCALABILITY_RISK_MATRIX.md`
- `AMORAA_SCALABILITY_ACTION_PLAN.md`
