# AMORAA S4 load-test readiness checklist

Date: 2026-10-12

Overall status: **NO — BLOCKED BY STAGING INFRASTRUCTURE**

No full load test is authorized by this document. Do not target production.

## Mandatory gates

- [ ] Written approval identifies isolated staging hostnames, owner, budget and test window.
- [ ] Production DNS, credentials, database, storage, providers and customer data are excluded and technically blocked.
- [ ] Two API instances, MySQL 8, shared rate-limit/realtime service, private object storage and required workers are deployed.
- [ ] Synthetic dataset tier and manifest are verified; reusable test users/tokens are isolated by scenario.
- [ ] Migration status, immutable artifact/image digest and rollback are recorded.
- [ ] Central logs, metrics, traces, slow-query visibility, DB/pool, queue and socket dashboards are ingesting.
- [ ] Alert destinations and stop authority are named and tested.
- [ ] Cross-node correctness, contention and dependency-failure tests pass.
- [ ] Provider delivery is disabled/stubbed or restricted to approved sandbox destinations.
- [ ] Load generator source IP, resource ceiling and environment allowlist/kill switch are approved.
- [ ] Cleanup/reset process is rehearsed and storage/queue/database recovery is verified.

## Prepared scenarios

| Scenario | Proposed request mix | Think time | Synthetic data | Project success criteria / abort threshold |
|---|---:|---:|---|---|
| A Authentication | 8% login/refresh; signup separately at low rate | 3–10 s | valid/invalid users, sandbox OTP | correct auth/429; abort on provider escape, lockout corruption or unexpected 5xx |
| B Profile read | 16% own/public reads | 2–8 s | varied complete/visibility states | authorization and bounded payload; abort on cross-user leakage |
| C Discovery | 20% first/cursor pages | 5–15 s | broad/narrow/dense/sparse cohorts | eligibility, no cursor corruption; abort on blocked/inactive leakage |
| D Filters | 5% reads/controlled updates | 5–20 s | disposable preferences | persisted bounded filters; abort on semantic drift |
| E Likes | 8% idempotent/reciprocal actions | 3–12 s | partitioned actor-target pairs | one action/match; abort on duplicates/lost writes |
| F Matches | 7% list/profile reads | 3–10 s | 0/20/100 match cohorts | bounded stable pages and authorization |
| G Conversation list | 10% list/cursor reads | 2–8 s | 0/20/100/500 conversation cohorts | correct order/unread; abort on pool/DB sustained saturation |
| H Message send/read | 12% text/read, small approved media subset | 1–6 s | paired users across nodes | durable authorized write plus deduplicatable event; abort on lost/duplicate unauthorized delivery |
| I Realtime | connection/subscribe/reconnect alongside H | session 5–30 min | sockets split across nodes | cross-node fanout/presence; abort on event loss/leak or reconnect storm |
| J Privacy request | 2% create/list/status; export separate low-rate job | 10–30 s | disposable owner records | idempotent owner-only state; abort on synchronous queue/storage runaway |
| K Admin read-only | 4% bounded dashboard/moderation/financial reads | 5–20 s | synthetic admin and bounded dates | RBAC and bounded impact; abort if user traffic is materially starved |

Percentages are a starting project workload model and must be approved/revised from available non-sensitive analytics. They do not describe real traffic.

## Stage controls

Follow `LOAD_TEST_PLAN.md`: A=50, B=100, C=250, D=500, E=1,000 concurrent virtual users; optional 5,000 only under separate later authorization. Each stage needs warm-up, steady window, cool-down and correctness assertions. Stop escalation for data integrity/security failure, sustained DB/pool/event-loop/queue saturation, uncontrolled provider traffic, missing observability or inability to cleanly restore.

## Result record

Capture exact topology/resources, commit/image/migrations, dataset, tool/scripts, mix/think time, start/end, p50/p95/p99/RPS/errors, resource peaks, slow queries, queue/socket/shared-store behavior, correctness failures, alerts and cleanup. Capacity conclusions apply only to that exact controlled run with stated headroom. Current readiness remains NO.

