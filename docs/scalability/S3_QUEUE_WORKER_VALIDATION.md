# AMORAA S3 queue and worker validation

Date: 2026-10-12

Status: **BLOCKED — DURABLE QUEUE/WORKER IMPLEMENTATION REQUIRED**

## Candidate order

1. Privacy export generation and expiry/deletion.
2. Push and non-login transactional notifications.
3. Media processing/scanning/derivatives.
4. Large admin reports and reconciliation.
5. Moderation enrichment and AI feature/snapshot preparation.
6. Email/SMS only where product semantics allow asynchronous delivery; OTP expiry and user feedback require special care.

## Job envelope

Versioned job type, opaque job ID, idempotency key, resource IDs rather than sensitive payloads, created/deadline time, attempt/max attempts and trace/correlation reference. Secrets and access tokens never enter job bodies. The worker re-authorizes current resource state before sensitive work.

## Semantics

Durable enqueue acknowledgement; at-least-once consumption; transactional/outbox boundary where losing intent is unacceptable; lease/visibility timeout; bounded exponential backoff with jitter; per-job timeout; idempotent completion; explicit terminal/non-retryable errors; DLQ with restricted inspection/redrive; graceful worker drain; queue/age/retry/DLQ metrics; and provider sandbox/delivery-disabled mode.

## Validation

Prove enqueue/consume, duplicate delivery, worker crash before/after side effect, timeout, transient retry, permanent DLQ, redrive, broker outage, worker restart, cancellation/expiry and two-worker concurrency. Verify one final artifact/notification state per idempotency key and no real email/SMS/push delivery.

No admin sample-job response is accepted as queue evidence. No queue package or broker is currently present.

