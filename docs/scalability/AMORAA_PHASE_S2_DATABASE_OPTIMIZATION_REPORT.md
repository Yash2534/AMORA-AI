# AMORAA Phase S2 database optimization report

Date: 2026-10-12

Scope: repository and local/test database only. No production database, production data, production load, cloud service, or capacity claim was used.

## Outcome

S2 adds a reversible six-index migration, removes two superseded/duplicate indexes, applies an indexable discovery distance prefilter, bounds administrative date and in-memory analysis domains, converts financial overview scans/N+1 counts to grouped aggregates, closes the S1 offer read-modify-write race with a row lock, and adds opt-in cross-dialect statement-timeout support. The database remains **PARTIAL — STAGING REQUIRED** because JSON/calculated discovery, exact dashboard counts, reporting isolation, representative MySQL 8 plans, slow-query evidence, and controlled load evidence are missing.

## Change register

| Area | Change and evidence | Status |
|---|---|---|
| Discovery SQL | Existing eligibility/security clauses preserved; an indexable geographic box reduces rows before exact distance. AI window remains hard-bounded. Discovery/AI integrations pass. | PARTIAL — STAGING REQUIRED |
| Distance | Bounding-box utility handles antimeridian/poles and retains exact spherical comparison. Local synthetic plan changes `ALL` to `range`. | COMPLETE — LOCAL DB VERIFIED |
| JSON hot paths | All hot JSON expressions inventoried; no speculative normalization or semantics change. | PARTIAL — STAGING REQUIRED |
| Relationship indexes | Canonical/reverse match and block pairs verified; exact duplicate reverse block index removed. Unique interaction constraints retained. | COMPLETE — LOCAL DB VERIFIED |
| Chat | Message history keyset and conversation/sender indexes verified. Conversation-list unread correlation remains a measured staging candidate. | COMPLETE — REPOSITORY VERIFIED |
| Admin lists/moderation | 366-day date ceiling, 1,000-row derived matching cap, user/match/subscription/report chronology indexes. | PARTIAL — STAGING REQUIRED |
| Admin analytics | Creation-time range indexes added; remaining `DATE()` grouping temporary/filesort documented. Recommendation attribution rollup deferred. | PARTIAL — STAGING REQUIRED |
| Financial reporting | Period payment/refund/subscription metrics now use SQL aggregates; per-plan N+1 and empty-period global fallback removed; reconciliation remains capped interim work. | COMPLETE — REPOSITORY VERIFIED |
| Privacy | Stable owner-history index includes id tie-breaker; artifact ownership/status/expiry indexes verified. | COMPLETE — LOCAL DB VERIFIED |
| Pagination | Discovery/messages already use keysets. Remaining offset endpoints classified; none converted without a compatible client cursor contract. | PARTIAL — STAGING REQUIRED |
| Counts | Exact/approximate/not-required consumers classified. Exact compliance/finance totals preserved. | COMPLETE — REPOSITORY VERIFIED |
| Transactions | High-value flows audited. Provider delivery is generally outside DB transactions. Offer mutations now lock and mutate the shared row within one transaction. | COMPLETE — REPOSITORY VERIFIED |
| Concurrency | Unique constraints remain primary race arbiters for phone, pairs, OTP selectors, payments, and idempotency. Offer lost-update window closed. Deadlock retry needs contention testing. | PARTIAL — STAGING REQUIRED |
| Query timeout | Opt-in, bounded MariaDB/MySQL session statement ceiling added; default disabled pending staging threshold evidence. | PARTIAL — STAGING REQUIRED |

## Index migration

Added:

- `onboarding_profiles_match_location (matchLatitude,matchLongitude,userId)`
- `users_created_at_id (createdAt,id)`
- `matches_matched_at_id (matchedAt,id)`
- `subscriptions_created_at_id (createdAt,id)`
- `reports_status_created_id (status,createdAt,id)`
- `privacy_requests_user_requested_id (userId,requestedAt,id)`

Removed after replacement/equivalence proof:

- `privacy_requests_user_requested (userId,requestedAt)`; superseded by the stable id-bearing index.
- `blocks_blocked_blocker (blockedUserId,blockerUserId)`; exact duplicate of retained `blocks_blocked_blocker_lookup`.

The local migration was applied, rolled back successfully, reapplied, and confirmed `up`.

## Transaction and lock audit

- Signup/OTP/phone ownership: uniqueness plus row locks/transactions are present; provider delivery happens after commit where applicable.
- Like/match/conversation creation: canonical unique keys and one transaction prevent duplicate pairs; deadlock retry is not generalized.
- Payment creation/events: idempotency/provider unique constraints are present; external provider workflows must retain short transaction boundaries.
- Account deactivation/deletion and admin lifecycle: user row is locked; related token/device mutations occur transactionally.
- Privacy workflow: owner/request transitions and artifact uniqueness are enforced; generation remains synchronous/local infrastructure debt.
- Chat media writes still perform filesystem work around a database transaction and require the S3 object/worker design rather than a risky S2 rewrite.
- Offers now lock the `PlatformSettings` row before reading/mutating/writing, preventing the S1 multi-writer lost-update window.

## Validation

- S2 unit tests: 5/5 passed.
- S2-affected integration slice: 54/54 passed.
- Full backend regression suite: 370/370 passed against the local test database.
- Local migration: up/down/up succeeded; final status `up`.
- Synthetic plan evidence: six before/after shapes captured with 10,000 temporary rows per table.
- Changed S2 JavaScript syntax checks: passed.
- `git diff --check`: passed (line-ending conversion notices only; no whitespace errors).
- Flutter tests: not rerun because S2 did not change Flutter code or API response shapes; the S1 baseline remains 659 passed / 14 skipped.
- Flutter analyzer: completed with the unchanged 44 pre-existing issues and no S2 Flutter changes.

These are correctness and repository-regression checks only. They are not load-test results or capacity evidence.

## Remaining database bottlenecks

- Compatibility ordering, reciprocal correlated preference reads, and multi-value JSON discovery filters.
- Exact distance/scoring sort after bounding.
- Recommendation attribution/full telemetry aggregation.
- Exact global dashboard counts and `GROUP BY DATE` temporary/filesort.
- Joined contains searches and deep admin offsets/counts.
- Conversation-list correlated unread counts.
- In-process capped financial reconciliation rather than durable/offline reconciliation.
- No production-like MySQL 8 plan, slow-query log, row distribution, contention, or load evidence.

Production scalability verified: **NO**. Horizontal scaling status remains **NO** because realtime, rate limits, storage, queues, and observability still require shared infrastructure.
