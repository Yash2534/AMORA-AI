# AMORAA database scalability audit

> Phase S2 update (2026-10-12): migration `202610120001-add-s2-query-indexes.js` adds location, user creation, match chronology, subscription chronology, moderation status chronology, and stable privacy history indexes; removes one exact duplicate block index and one superseded privacy prefix index. Discovery now uses a bounding box before exact distance, financial overview uses grouped aggregates, admin date ranges are bounded, and statement timeout support is opt-in. See `S2_INDEX_AUDIT.md` and `evidence/S2/S2_QUERY_PLAN_COMPARISON.md`. Status remains **PARTIAL — STAGING REQUIRED**.

## Verdict

The schema has a useful index and foreign-key foundation, but query scalability is uneven. Transactional lookups are generally well supported; discovery, reverse-reaction lists, global/admin analytics, full counts, substring search, and several unbounded exports/lists are not. No capacity is verified without a production-like dataset and query plans.

## Existing strengths

- Unique pair indexes protect `Matches`, `DiscoverActions`, `Blocks`, `SavedProfiles`, conversations, membership, and payment/provider idempotency.
- Chat has `(userId, conversationId)`, `(conversationId, userId)`, `(conversationId, id)`, and `(conversationId, senderId, id)` indexes.
- Review/queue tables commonly have status-time indexes: identity verification, notification delivery, deletion tasks, event waitlist, and privacy export expiry.
- Financial history and provider references have useful composite indexes.
- Reverse indexes were added for matches and blocks, which is necessary for symmetric relationship checks.
- Foreign keys and transactions cover many ownership/lifecycle operations.

## Critical query risks

### Discovery

The query calculates compatibility and optional distance for candidates, orders by calculated expressions, applies `LOWER`, `CAST`, JSON functions, profile-completeness expressions, correlated reciprocal-preference queries, `NOT EXISTS` blocks, reaction exclusion, match exclusion, and optional event registration. The eligibility index `(onboardingCompleted, birthDate, communicationStyle, userId)` helps only part of the predicate. It cannot make function-heavy score/distance/JSON ordering cheap.

Required direction:

1. Bound candidate generation before expensive scoring.
2. Store normalized scalar fields for case-insensitive equality and height.
3. Replace frequently queried JSON arrays with junction tables or justified generated/indexed columns.
4. Use an appropriate geospatial/indexable bounding strategy before exact distance calculation.
5. Precompute/version compatible features or recommendation snapshots where freshness requirements allow.
6. Run `EXPLAIN ANALYZE` for every surface and realistic selectivity distribution.

### AI matching

Phase S1 added a hard configurable SQL candidate window before Node ranking. Phase S2 preserves all eligibility and exclusion rules and adds a location bounding box before exact distance. The residual risk is function/JSON/compatibility work inside that bounded window and the quality/cost tradeoff of window selection; it is no longer an unbounded whole-population read.

### Admin analytics

Global `COUNT`, date grouping, and complete-table materialization remain in dashboards and recommendation metrics. `matchRecommendationMetricsService` still loads complete recommendation, reaction, rose, and match tables. Phase S2 changes financial overview to grouped SQL over bounded periods and removes per-plan N+1 counts; dashboard exact counts and recommendation attribution still need rollups or offline reporting when staging evidence justifies them.

## Confirm with migration plus live-schema inspection

The following are proposed indexes/query changes, not instructions to add every index blindly. Validate cardinality, selectivity, write cost, and overlap using the staging schema and query plans.

| Priority | Table / access path | Current evidence | Candidate action |
|---|---|---|---|
| P0 | `DiscoverActions` received likes | Only unique `(actorUserId,targetUserId)` is evident | Test `(targetUserId, action, createdAt, id)` |
| P0 | Discovery candidate/profile search | One broad eligibility index; many functions/JSON expressions | Normalize/filter tables, generated columns where appropriate, bounded candidate query, geospatial strategy |
| P1 | `Matches` user history ordered by `matchedAt` | Pair indexes, no user+time index | Test `(userOneId, matchedAt, id)` and `(userTwoId, matchedAt, id)` or redesign participant relation |
| P1 | `Messages` unread/history | Conversation indexes exist; `deletedAt` is residual | Test `(conversationId, deletedAt, id)`; retain sender variant only if plans prove benefit |
| P1 | `Users` admin recent/date counts | No explicit `createdAt` index found | Test `(createdAt, id)` |
| P1 | `Users` online-active | Separate status/id and lastActive/id indexes | Test `(accountStatus, lastActiveAt, id)` |
| P1 | `DiscoverActions` admin/global metrics | No action+time index evident | Test `(action, createdAt, id)` |
| P1 | `Matches` time-range metrics | No `matchedAt` index evident | Test `(matchedAt, id)` |
| P1 | `Messages` admin time-range metrics | No global created-time index evident | Test `(createdAt, id)` or aggregate out of OLTP |
| P1 | `Reports` moderation queue | Duplicate/reported-user indexes do not match general status-time queue | Test `(status, createdAt, id)` and actual sort columns |
| P1 | `PrivacyGrievances` queues | Single-column status only | Test `(status, createdAt, id)` and `(assignedAdministratorId,status,updatedAt)` if used |
| P1 | `PrivacyRequests` admin assignment/queue | `(requestType,status)` lacks time/assignment | Test `(requestType,status,requestedAt,id)` and assignment workflow index |
| P2 | `ConversationParticipants` list with hidden state | Migrations add user+hidden but model metadata lags | Verify live index and plans; use keyset conversation listing |
| P2 | `Notifications` admin global time order | User-first history index is not a global-time index | Test `(createdAt,id)` only if admin endpoint stays on primary |

## Duplicate/overlapping index review

- `Blocks` has both a named reverse lookup from the original migration and another reverse index from `202609290003`; depending on actual names/live migration state, these can duplicate the same `(blockedUserId, blockerUserId)` columns. Verify with `SHOW INDEX` and remove only after plan/FK validation.
- Models often repeat migration-defined indexes. Sequelize model metadata does not create indexes at runtime here, but it can drift from migrations and confuse audits. Treat migrations/live schema as authoritative and add a schema-drift check.
- Single-column FK indexes can become redundant beneath composite indexes, but MySQL may require an index for the FK. Do not remove without checking the exact live constraint plan.

## Unbounded or high-growth queries

- `matchController.list`: all matches for a user.
- `blockController.list`: all blocked profiles for a user.
- `privacyRequestController.listMine`: complete request history.
- privacy access/export services: all consent/request history; volume grows for account lifetime.
- `adminMatchingService`: failure rows loaded, enriched, filtered, and sliced in memory; list-all match path.
- `matchRecommendationMetricsService`: complete telemetry/action/rose/match tables.
- `adminFinancialService`: multiple complete payment/subscription sets and per-plan count loops.
- legacy/admin privacy grievance listing: no pagination.
- reference tables (`PlatformSettings`, legal/taxonomy/config) are intentionally small; document maximum expected size and keep them bounded operationally.

Every high-growth list must have an enforced limit and preferably keyset pagination. Offset pagination is acceptable for small admin/reference sets but should not be the long-term design for conversations, users, payments, audit logs, reactions, or moderation queues.

## N+1 and repeated query patterns

- Realtime presence lists every conversation and then performs participant, block, and match checks per conversation.
- Notification push fanout creates/updates a delivery per device and performs provider calls serially.
- Admin matching failure serialization performs asynchronous enrichment per row.
- Financial plan breakdown performs count queries per plan.
- Public match listing queries viewer profile separately after the match join.
- Conversation list uses one summary SQL plus one user/profile query, which is a good two-query batching pattern; however its correlated unread/exact-participant counts still need plan validation.

## Counts and pagination

`findAndCountAll` doubles work and may create expensive distinct counts across joins. Returned exact totals should be removed where product UX does not require them, cached/estimated for dashboards, or computed from rollups. Received likes performs a joined exact count on every page. Deep `OFFSET` grows linearly and is unstable under inserts; replace with `(sortKey,id)` cursors.

## Transactions and concurrency

Strengths include row locks for privacy/account/payment state and unique constraints for idempotency. Risks:

- Auto-running migrations from each application process can race.
- Privacy export changes request/artifact status and filesystem state in separate transactions; crashes can leave mismatched state/file.
- Inline account file cleanup similarly spans DB and filesystem without a durable worker lease/reconciliation loop.
- OTP creation invalidates previous rows and creates a new row; ensure concurrent requests are serialized by limiter/shared store plus transaction/constraint behavior.
- Notification creation can commit before push delivery; this is correct for durability, but delivery retries are not scheduled.

## Connection pool risk

No explicit Sequelize pool exists. Before staging:

1. Choose per-instance `max/min/acquire/idle/evict` based on MySQL connection budget.
2. Reserve capacity for migrations/workers/admin jobs and leave operational headroom.
3. Export pool used/idle/pending/acquire timeouts.
4. Test startup/reconnect storms and DB failover.
5. Set query/transaction time budgets and detect leaked/long transactions.

Fleet database connections equal the sum of every API and worker pool, not a per-process number.

## Required staging query evidence

Capture SQL, bindings shape, `EXPLAIN ANALYZE`, rows examined/returned, temp tables, filesort, execution time, and index choice for:

- all discovery surfaces with broad/narrow filters and with/without coordinates;
- AI matches after bounded redesign;
- received likes, match list, conversation list/unread, and message history;
- admin dashboard/analytics/financial overview for 7/30/90-day ranges;
- moderation, verification, privacy, audit log, and payment queues;
- privacy export for a deliberately high-history test user.

Enable the slow-query log in staging with a controlled threshold and retain sanitized samples. Index changes are complete only when plans and load tests demonstrate improvement without unacceptable write amplification.
