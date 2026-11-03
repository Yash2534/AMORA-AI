# AMORAA S3 staging architecture

Date: 2026-10-12

Status: **BLOCKED — INFRASTRUCTURE REQUIRED**

This is the executable architecture contract for an isolated, production-like staging environment. It does not prove that any resource exists. It reuses `security-remediation/STAGING_ENVIRONMENT_BUILD_PLAN.md` and does not authorize deployment, production access, or cloud spend.

## Isolation boundary

- Separate staging DNS names for API and Admin; names are assigned by management/DevOps, not this document.
- HTTPS and WSS only, with an edge load balancer/reverse proxy and explicitly configured trusted-proxy hop count.
- Separate network, MySQL 8 database, credentials/workload identities, private object storage, shared Redis-compatible service, queue, logs, metrics, traces, KMS/secrets and provider sandboxes.
- Synthetic identities and media only. Never restore a production database or copy customer objects, credentials, tokens, admin accounts, logs or signing material.
- Email/SMS/push must use delivery-disabled stubs or approved sandbox/allowlisted destinations with spend caps.
- `DB_MIGRATION_STARTUP_MODE=verify` on API and worker processes. One separately authorized migration job applies migrations.

## Logical topology

1. The edge terminates TLS, rejects or redirects HTTP, preserves WebSocket upgrades and routes health checks.
2. At least two identical API instances sit behind the edge. They use JWT authentication and no instance affinity for HTTP correctness.
3. Both instances use a shared Socket.IO adapter/pub-sub service and shared atomic rate-limit store. Presence uses TTL-backed shared membership rather than local zero-connection inference.
4. API and worker identities connect to a private MySQL 8 endpoint using verified TLS and separate bounded pools.
5. API instances store object keys in MySQL and use private object storage for profile, chat, verification and export artifacts. Instance disks are disposable.
6. API processes enqueue durable jobs; independently deployed workers claim them with acknowledgement, retry, timeout, idempotency and DLQ behavior.
7. Structured logs, metrics and traces are exported to restricted staging systems. No request body, token, OTP, contact value or raw profile field may be a label or log field.
8. Heavy reporting is initially bounded on the primary database; rollups/read replica/reporting database are introduced only after S3 evidence shows interference.

## Required workloads

- `api`: two instances minimum; readiness at `/health/ready`, liveness at `/health/live`, graceful drain on termination.
- `migration`: single-run release task with DDL identity; never runs concurrently in application replicas.
- `worker`: at least one staging worker for each implemented durable queue; API and worker concurrency are independently bounded.
- `mysql8`: empty migrated schema populated only by the S3 synthetic process.
- `shared-store`: authenticated/TLS shared rate-limit and Socket.IO adapter service, with HA or an explicit documented outage mode.
- `object-store`: private-by-default buckets/containers separated by data class or prefix and lifecycle policy.
- `telemetry`: central logs, metrics, traces, dashboards and alert routing with named owners.

## Configuration contract

Record, without secret values: commit SHA, migration set, image digest, instance count/CPU/RAM, `DB_POOL_*`, worker pools, DB `max_connections`, statement timeout, proxy hop count, adapter/store mode, queue names and concurrency, object-store region/class, retention settings and telemetry destinations. Secrets are injected from a managed store.

## Deployment sequence

1. Obtain written staging scope, owner, budget, window and exclusions.
2. Build isolated network, edge, MySQL 8, shared store, object storage, queue and telemetry.
3. Review IAM, TLS, firewall, CORS, proxy, provider and redaction configuration.
4. Apply migrations once to the empty database and record `db:migrate:status`.
5. Create the smallest supported synthetic dataset, verify invariants, then deploy two API instances and workers.
6. Prove health/drain, cross-node rate limits, realtime fanout, shared storage, queue semantics and telemetry before any load test.
7. Expand to 50k/100k datasets only when storage, generation duration and cleanup headroom are approved.

## Exit evidence

Sanitized topology/config exports, certificate/WSS checks, migration record, data manifest, DB connection worksheet, MySQL 8 plans, slow-query fingerprints, cross-node validation records, object/queue failure tests, dashboards/alerts and cleanup confirmation. Until these artifacts exist, staging is not available and S4 is not ready.

