# Background Job Architecture

Status: **PARTIAL — INFRASTRUCTURE REQUIRED**

S1 does not introduce an in-memory fake queue. Privacy export download now streams from disk and deletes/consumes only after the response finishes, but export generation and several providers still execute in request scope.

| Work | Current S1 classification | Target behavior |
|---|---|---|
| Login/signup OTP delivery | SYNC OK for correctness today | Queue only with challenge-bound idempotency and strict expiry; provider timeouts remain mandatory. |
| Transactional email/SMS | SHOULD QUEUE | Durable retry with provider idempotency where available; no blind duplicate retry. |
| Push notifications | SHOULD QUEUE | Persist delivery intent, retry transient errors, retire invalid tokens. |
| Privacy export generation | MUST QUEUE AT SCALE | Durable job, bounded/chunked reads, private object storage, TTL, owner-bound signed download. |
| AI matching precomputation | SHOULD QUEUE | Versioned snapshots; never weaken live eligibility/block checks. |
| Media processing | MUST QUEUE AT SCALE | Virus/content checks, metadata stripping, resize/transcode, retry/DLQ. |
| Moderation processing | SHOULD QUEUE | Durable evidence reference, audit trail, priority and retry policy. |
| Admin reports/exports | MUST QUEUE AT SCALE | Bounded query windows, asynchronous artifact generation, expiry. |

Future queue requirements: durable acknowledgement, idempotency key, attempt count, exponential backoff with jitter, dead-letter handling, job timeout, cancellation policy, queue-depth/age metrics, and separate worker concurrency budgets. A single worker or broker is still a single point of failure.
