# AMORAA staging load-test plan

## Safety and authorization

Run only against an explicitly authorized, isolated staging environment with synthetic accounts, synthetic media, isolated provider credentials/sandboxes, disposable queues/storage, and a production-like schema/data distribution. Do not point scripts, DNS, credentials, or mobile builds at production. Add an environment allowlist and destructive-test kill switch.

This document is a plan. No load test was run and no capacity is claimed.

## Prerequisites

- S1 release-blocking repository fixes completed, especially bounded AI matching, graceful shutdown, readiness, and query limits.
- At least two API instances for shared-state validation; later repeat with the intended topology.
- Production-like MySQL version/config and anonymized/synthetic scale datasets at 10k, 100k, and—when feasible—1m registered-user shapes.
- Shared rate-limit and Socket.IO adapter service; object storage; queue/workers where introduced.
- Fixed pool sizes and instance CPU/RAM limits documented.
- Central metrics/logs/traces, DB slow-query collection, and synchronized clocks.
- Synthetic users partitioned per scenario so state collisions do not dominate results.
- SMS/email/push stub or sandbox with controlled latency/error injection; never send to real recipients.

## Workload model

Create a measured mix rather than sending every endpoint equally. Start with a proposed mix, observe real staging/product analytics when available, then revise. Include think time, mobile network latency, token refresh, and realistic payload/image sizes.

Scenarios:

1. Signup and login: unique synthetic identities; OTP provider stub; separate steady login from lower-rate signup.
2. Profile fetch: own profile and authorized public profile.
3. Discovery: recommended, near-you, and high-compatibility; first page plus cursor continuation; broad and narrow filters.
4. Filters: read and controlled update using disposable users.
5. Like/super-like/match: deterministic user pairs; idempotency and race cases.
6. Conversation list: 0, 20, 100, and 500-conversation users with unread distribution.
7. Send message: text and a small controlled media percentage; verify recipient event and persistence.
8. Privacy request: create/status reads in main mix; export generation tested as a low-rate queued workload after redesign.
9. Admin read-only: bounded dashboard, moderation queue, and transaction list with capped date ranges.

Do not repeatedly create reports, delete accounts, charge payments, or invoke real external delivery. Mutation data must be reset by an authorized staging fixture process.

## Stages

Each stage includes a 10–15 minute warm-up, at least 30 minutes steady state, and a controlled cool-down. Extend stable stages to soak tests after correctness is established.

| Stage | Concurrent virtual users | Purpose |
|---|---:|---|
| A | 50 | Validate scripts, telemetry, correctness, and baseline resource shape |
| B | 100 | First concurrency/pool/socket interaction check |
| C | 250 | Identify query, provider, queue, and event-loop knees |
| D | 500 | Validate autoscaling/backpressure and multi-node shared state |
| E | 1,000 | Candidate release-capacity evidence only if earlier gates pass |
| Optional later | 5,000 | Separate authorized exercise after architecture and Stage E stability |

Stop escalation when any abort gate triggers. Fix, rerun the failed stage, then repeat the preceding stage to check regression.

## Correctness assertions

- No duplicate user, match, conversation, payment-like idempotent record, or message when a client id is introduced.
- Every successful like/message/privacy action is durably visible.
- Unauthorized/blocked/deactivated profiles never appear or receive chat events.
- Cursor pages contain no unexpected duplicates/skips under the defined consistency contract.
- Online recipients receive one deduplicatable event across different API/socket nodes.
- Presence remains correct within the approved TTL/heartbeat contract.
- Rate limit threshold is consistent when requests alternate across nodes and recovers after the window.
- Media uploaded through one node is readable through another.
- Queue jobs are not lost; retries and DLQ behavior match policy.

## Metrics to collect

- HTTP count, RPS, p50/p95/p99 by normalized route/status, and error/timeout rate.
- Node CPU, RSS, heap, external memory, GC pauses, event-loop lag, active handles.
- DB CPU/IO, buffer/cache behavior, connections, pool used/idle/pending, acquire latency/timeouts, locks/deadlocks, rows examined/returned, slow queries.
- Socket current/connections/disconnections/auth failures/reconnects/events/fanout latency per node and fleet.
- Queue depth, oldest age, processing latency, retries, failures, DLQ.
- Redis/shared-service latency, errors, connections, memory, evictions, pub/sub throughput, rate-limit operations.
- Object-storage request latency/errors/bytes and CDN hit rate where applicable.
- SMTP/SMS/push latency/errors, strictly through stubs/sandboxes.
- Flutter/device network bytes, memory, CPU, frames/jank for a parallel mobile endurance run.

## Project targets

Use the proposed targets in `AMORAA_SCALABILITY_AUDIT.md`. Additionally:

- no unexpected 5xx/data-integrity failure;
- <1% unexpected error rate per stage;
- p95/p99 do not grow without bound across the steady window;
- CPU and DB pool return toward baseline during cool-down;
- no monotonic memory growth or unbounded queue growth;
- graceful scale-in causes no lost acknowledged write;
- distributed limits and socket events remain correct across nodes.

These are project gates, not measured facts.

## Failure and resilience exercises

After steady-state performance passes, repeat a lower safe stage while:

- terminating one API node gracefully and then abruptly;
- restarting one worker;
- injecting bounded DB latency and one failover if the staging provider supports it;
- pausing the shared store briefly according to an approved test plan;
- adding provider latency/429/5xx through stubs;
- causing a controlled reconnect wave;
- expiring tokens during active chat/discovery sessions.

Document whether each dependency fails open or closed, user-visible behavior, recovery time, and alert delivery.

## Abort gates

Immediately stop ramp-up for data corruption, cross-user data exposure, sustained DB saturation, repeated deadlocks, pool starvation, runaway queue growth, event-loop lag above the approved limit, uncontrolled provider calls, or inability to restore the environment. Preserve metrics/logs and tag the failed run.

## Test report template

For every run record commit SHA, migration set, dataset shape, infrastructure sizes, node/worker counts, pool settings, scenario mix, tool version, start/end time, raw artifact links, p50/p95/p99/RPS/errors, peak resources, slow queries, correctness failures, aborts, and conclusions. Capacity is verified only for the exact tested configuration and workload, with stated safety headroom and confidence limits.
