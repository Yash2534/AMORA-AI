# AMORAA Phase S3 staging infrastructure report

Date: 2026-10-12

Scope: repository and local configuration inspection only. No production or staging endpoint, cloud console, customer data, real provider, infrastructure mutation or load test was accessed.

## 1. Executive Summary

S3 repository preparation is complete, but S3 infrastructure acceptance is **BLOCKED — INFRASTRUCTURE REQUIRED**. The repository is locally configured for development. The security Phase 8 record independently reports no approved staging hostname, resources, identities or evidence. Therefore no MySQL 8 plan, slow query, multi-instance, shared-service, storage, queue, observability, contention, timeout or failure test is represented as passed.

The deliverable is an execution-ready architecture and validation pack that reuses existing security requirements, identifies exact evidence, protects production/PII boundaries and prepares S4 scenarios. Production scalability remains unverified.

## 2. Staging Architecture

Defined in `S3_STAGING_ARCHITECTURE.md`: isolated HTTPS/WSS edge; two API replicas; private MySQL 8; shared pub/sub/rate-limit store; private object storage; durable workers; central logs/metrics/traces; synthetic data; separate identities/providers; single migration job. Status: **BLOCKED — APPROVAL/INFRASTRUCTURE REQUIRED**.

## 3. Multi-instance API

Repository-ready: JWT-based HTTP, bounded DB pool configuration, verify-only production-style migration startup, liveness/readiness and graceful shutdown. Not ready: shared realtime/presence, distributed limits, shared files, queues and fleet telemetry. No two-node test was run. Status: **PARTIAL**.

## 4. Synthetic Dataset

10k/50k/100k deterministic tiers, distributions, integrity invariants and cleanup gates are defined. No tier was generated because only local development is configured and staging resources are unapproved. Status: **PLAN READY; GENERATION BLOCKED**.

## 5. MySQL 8 Query Plans

The full discovery, relationship, chat, moderation, privacy, chronology, analytics and financial capture matrix is prepared. No MySQL 8 staging exists. Local MariaDB S2 evidence is not reused as MySQL 8 evidence. Status: **BLOCKED**.

## 6. Slow Queries

Fingerprint/digest fields, redaction, correlation, review and evidence requirements are defined. No DB telemetry or top staging bottleneck evidence exists. Status: **BLOCKED**.

## 7. Discovery

Staging procedure covers bounded candidate selection, location box, exact distance, preference/JSON filters, block/match/inactive/deleted/visibility exclusions and unchanged compatibility semantics across dense/sparse/boundary cohorts. Execution time and plans require MySQL 8 staging; no capacity is claimed. Status: **BLOCKED**.

## 8. Admin Analytics

The decision ladder is primary bounded reads → short-lived non-authoritative cache → rollups/jobs → replica → reporting database. S2 improvements remain; dashboard counts, date grouping, search, recommendation attribution and reconciliation need representative measurements. No reporting infrastructure was introduced. Status: **PARTIAL — STAGING REQUIRED**.

## 9. Realtime

Adapter injection exists, but no adapter client/config or shared presence is present. Cross-node fanout, duplicate handling, reconnect, cleanup and node failure procedures are specified. Status: **BLOCKED**.

## 10. Distributed Rate Limiting

Named store injection and fail-closed configuration exist; current store remains process local. Cross-node login/OTP/signup/privacy/media tests and proxy/outage checks are specified. P-33 remains pending. Status: **BLOCKED**.

## 11. Object Storage

Private access, signed/authenticated delivery, encryption/IAM, metadata, lifecycle, access logs, cross-node and outage tests are specified for profile/chat/verification/export data. The application still uses local paths. P-06/P-07 infrastructure proof remains absent. Status: **BLOCKED**.

## 12. Queue/Workers

Job ordering, safe envelope, at-least-once/idempotency, retry/timeout/DLQ, restart and duplicate tests are defined. No durable queue or worker exists; provider delivery must remain disabled in tests. Status: **BLOCKED**.

## 13. Observability

Required HTTP/runtime/DB/realtime/store/queue/storage/provider metrics, structured logging/redaction, tracing, dashboards and alert evidence are defined. Current counters are process-local only. Status: **BLOCKED**.

## 14. DB Connection Budget

The exact worksheet is prepared. Two APIs at repository default pool maximum imply 20 possible API connections as arithmetic only; real DB maximum, worker/migration/reporting/monitoring consumption and reserve are unknown. Status: **BLOCKED**.

## 15. Contention Tests

Required controlled tests: concurrent phone claims, reciprocal/duplicate likes and match creation, offer/config row locking, OTP single consumption, privacy request idempotency and admin lifecycle transitions. Capture deadlocks, lock waits, retries, duplicate rows and lost updates with small controlled concurrency only. Repository tests cover several invariants, but no two-instance MySQL 8 contention exercise was run. Status: **BLOCKED**.

## 16. Timeout Validation

S2 statement timeout support remains default-disabled. Capture normal and outlier durations separately for user queries, bounded admin reads and offline jobs, then test interruption/rollback/error mapping before recommending thresholds. No staging duration distribution exists. Status: **BLOCKED**.

## 17. Failure Tests

Planned: graceful/abrupt API stop, worker restart, shared-store outage, object-store outage, DB connection failure and provider timeout. Observe readiness, bounded errors, retry/recovery, data correctness, user impact and alerts. No approved chaos/failure environment exists. Status: **BLOCKED**.

## 18. S4 Readiness

Scenario mix, think time, data and abort criteria are documented. Mandatory prerequisites—approved staging, synthetic identities, two nodes/shared services, scripts, dashboards, slow queries, DB/queue/socket metrics and cleanup—are not met. Status: **NO**.

S3 changed documentation only. The immediately preceding repository baseline remains 370/370 backend tests. Focused post-documentation checks passed: 9/9 scalability units and 10/10 isolated chat/realtime database integrations. Within the unit set, distributed-store configuration/factory coverage passed, but this is not a cross-node rate-limit test. A combined ad-hoc invocation caused the chat fixture not to accept loopback requests; the canonical isolated `npm run test:phase3` rerun passed 10/10. Flutter was not rerun because no application/API behavior changed.

## 19. Remaining Blockers

- Written staging authorization, owners, hostnames, budget and test window.
- Isolated MySQL 8 and representative synthetic dataset.
- Two backend instances and intended edge/proxy topology.
- Shared Socket.IO adapter/presence and atomic rate-limit store.
- Object-storage application integration and private staging store.
- Durable queue/worker implementation and provider sandboxes.
- Central logs, metrics, tracing, dashboards, alerts and slow-query digests.
- Completed connection budget, contention/timeout/failure evidence and load scripts.

## 20. Production Recommendation

Do not approve production scalability or horizontal scaling. Complete the external S3 build and validation gates, then run Phase S4 controlled staging load tests. Do not claim concurrency capacity until those measured tests pass.

