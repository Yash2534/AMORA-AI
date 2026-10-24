# AMORAA S2 database query inventory

Date: 2026-10-12

Scope: Sequelize models, migrations, controllers, services, and routes in the local repository. Priority is runtime impact, not endpoint sensitivity. This inventory does not assert production frequency or capacity.

| Priority | Query / function and endpoint | Tables | Filters / joins | Order / group / bound | Functions, JSON, distance | Existing or S2 index support | Risk / disposition |
|---|---|---|---|---|---|---|---|
| P0 | Discover feed / `GET /api/discover/feed` | Users, OnboardingProfiles, Subscriptions, DiscoverActions, Matches, Blocks, DiscoverFilterPreferences | Active account, completed profile, age, reciprocal preferences, blocks, interactions, matches, optional filters | Compatibility/distance plus id; cursor; limit <=30 | `LOWER`, `CAST`, JSON expressions, correlated preference reads, exact trigonometric distance | User status/activity; profile eligibility; pair indexes; S2 location index | Still CPU-heavy; S2 adds an indexable bounding box before exact distance. JSON/scoring remains staging work. |
| P0 | AI matches / `GET /api/discover/ai-matches` | Same as Discover | Same safety and eligibility rules | Stable SQL order; hard candidate window 30-2,000, default 500 | Same calculated score/distance/JSON | Same | Bounded since S1; S2 reduces distance candidates without changing final exact distance. |
| P0 | Swipe/mutual match transaction | DiscoverActions, Matches, Conversations, ConversationParticipants | Canonical user pair, block/account checks | Unique pair writes | None | Unique actor-target, canonical match pair, conversation pair | Correctly transactional; uniqueness is the race arbiter. Deadlock/retry behavior still needs staging contention tests. |
| P0 | Conversation list / `GET /api/conversations` | Conversations, ConversationParticipants, Users, Profiles, Matches, Blocks, Messages | Membership, visible conversation, exact pair, active match, blocks | lastMessageAt/id; limit<=50; offset | Correlated unread count | Membership, conversation activity, message conversation/sender/id, pair indexes | Index-supported but correlated unread counts and offset can grow; convert later if evidence warrants. |
| P0 | Message history / `GET .../messages` | Messages, MessageMedia | conversationId, optional id<cursor | id DESC; keyset; limit<=50 | None | `(conversationId,id)`, media `(messageId,id)` | Strong current pattern. |
| P0 | Mark read / message delivery | Messages, ConversationParticipants | conversation, sender!=viewer, id range, status | id range | None | `(conversationId,senderId,id)` | Range update can touch many messages after long offline periods; measure lock duration. |
| P0 | Block visibility/exclusion | Blocks | Both pair directions | existence / pair lookup | OR across directions | Unique blocker-blocked plus one reverse pair index after S2 dedupe | Correct index symmetry; exact duplicate removed. |
| P1 | Match list / `GET /api/matches` | Matches, Users, Profiles | Participant membership | matchedAt/id; bounded page | None | Canonical/reverse pair; S2 `(matchedAt,id)` | User list is bounded. Admin matching still has derived filtering capped at 1,000. |
| P1 | Likes/super-likes | DiscoverActions, Users, Profiles | actor/target/action | createdAt/id; bounded list | None | Unique actor-target; target FK index | Reverse action/status chronology may need a plan-proven composite later. |
| P1 | Roses | RoseTransactions | sender/recipient/status | createdAt/id; bounded list | None | sender idempotency, recipient history | Current recipient history is supported. Sender chronology relies on unique idempotency prefix. |
| P1 | Notifications list/unread | Notifications, Users, Profiles | userId, deletedAt, optional isRead/category | createdAt/id; limit<=50; offset | JSON payload returned, not filtered | Inbox order and unread lookup | Exact unread count runs per request; offset and count become candidates for keyset/derived counters. |
| P1 | Admin users | Users, Profiles, verification/subscription relations | status, verification, search, dates | bounded page plus exact count | substring `LIKE` | status/id, verification/id, createdAt/id S2 | Exact count and contains search remain scale risks. |
| P1 | Verification queue | IdentityVerifications | status/reviewer/date | submittedAt/id; bounded page/count | None | review queue/status updated/reviewer indexes | Good alignment. |
| P1 | Moderation reports | Reports, AdminReportCases, Users | status, reported user, case state, dates | bounded page/count; createdAt/id | optional contains search | S2 `(status,createdAt,id)` plus reported-user status | Joined search/count still requires staging plans. |
| P1 | Matching failures | MatchingActionFailures, Users | action type, code, dates, optional names | createdAt/id; S2 hard in-memory cap 1,000 | contains search after enrichment | type/code/actor plus time | No longer unbounded; search remains capped/in-memory and should become SQL-backed. |
| P1 | Admin matches | Matches, Users, Profiles, Conversations | dates plus derived score/conversation/source filters | createdAt or score; S2 hard cap 1,000 | compatibility calculated in Node | S2 `(matchedAt,id)` | Chronology improves; score/derived filtering needs reporting design. |
| P1 | Match recommendation metrics | RecommendationEvents, DiscoverActions, Roses, Matches | experiment/variant | whole-universe attribution | in-memory attribution | event metrics index and pair indexes | Still unbounded and intentionally deferred to rollup/offline computation. |
| P1 | Analytics user registrations | Users | createdAt range | `GROUP BY DATE(createdAt)` | `DATE` in group/order | S2 `(createdAt,id)` | Range becomes indexed; grouping still uses temporary/filesort in local evidence. |
| P1 | Analytics subscription trend | Subscriptions | createdAt range | `GROUP BY DATE(createdAt)` | `DATE` | S2 `(createdAt,id)` | Same residual grouping cost. |
| P1 | Revenue overview | Payments, Subscriptions, Plans | status and bounded period | grouped by plan; exact sums/counts | aggregate SQL | payment status/history; subscription chronology/entitlement | S2 removes full payment materialization, empty-period all-time fallback, and per-plan count N+1. |
| P1 | Payment transaction list | Payments, Users, Plans, Events | status/currency/plan/provider/date/search | bounded page/count, stable id | contains search | status/time, currency/time, user/time, provider unique | Date spans now capped at 366 days. Exact counts and broad search remain. |
| P1 | Reconciliation | Payments, Subscriptions, Users, Plans | date/provider/status/search | input capped; source reads capped 1,000 | in-memory cross-source reconciliation | payment/subscription indexes | Still a bounded interim implementation; durable offline reconciliation is preferred. |
| P1 | Privacy request history | PrivacyRequests | owner userId | requestedAt/id; limit<=50; offset | None | S2 `(userId,requestedAt,id)` | Stable index added; deep offset conversion can wait. |
| P1 | Privacy artifact lifecycle | PrivacyExportArtifacts | owner/request/status/expiry | status+expiry or owner+created | None | status/expiry, owner/created, unique request/key | Index alignment is good; storage/job architecture remains external. |
| P1 | Audit logs | AdminAuditLogs | actor/action/target/date | bounded page/count | optional contains filters | actor/action/target chronology | Exact count and arbitrary sorting can be expensive. |
| P2 | Catalog/configuration reads | PlatformSettings, taxonomy, plans, legal docs | key/state | small ordered catalogs | occasional JSON value | unique keys and catalog indexes | Small reference sets; safe cache candidates. |
| P2 | Events | Events, registrations, waitlist | status/visibility/category/city/date | start/id; bounded pages | None | browse/filter/host/capacity/waitlist indexes | Generally aligned; contains search is residual. |

## Pagination classification

- CONVERT NOW: none beyond the already implemented discovery/message keysets. No additional API was changed because compatible cursor contracts and clients were not available.
- KEEP OFFSET: small reference catalogs and explicitly bounded administrative pages where exact page navigation is a product requirement.
- CONVERT LATER: conversations, notifications, privacy history, admin users, payments, audit logs, matching actions, and moderation queues. Add cursor contracts without removing existing page parameters.

## Count classification

- EXACT REQUIRED: billing/reconciliation totals, compliance workflow totals, and admin audit result totals when exported as authoritative reports.
- APPROXIMATE ALLOWED after product approval: dashboard population cards and operational trend panels.
- NO TOTAL REQUIRED: infinite-scroll discovery, messages, notifications, matches, blocks, and privacy-history mobile lists; `hasMore` is sufficient.
