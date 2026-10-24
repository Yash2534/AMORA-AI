# AMORAA S2 index audit

Date: 2026-10-12

Evidence sources: all Sequelize migrations/models plus read-only `information_schema.STATISTICS` from the local `amora_ai` MariaDB 10.4 schema. The schema contained 54 applied migrations before S2 and small development data; index presence is verified, production use is not.

## S2 migration result

Migration: `Backend/src/migrations/202610120001-add-s2-query-indexes.js`

| Table | Change | Justification | Write-cost note |
|---|---|---|---|
| OnboardingProfiles | ADD `(matchLatitude, matchLongitude, userId)` | Supports the new bounding-box prefilter before exact distance. | Profile/location updates maintain one additional secondary index. |
| Users | ADD `(createdAt, id)` | Registration range analytics and chronological administration. | User creation only; low update cost. |
| Matches | ADD `(matchedAt, id)` | Stable chronological match/admin reads. | One write per match. |
| Subscriptions | ADD `(createdAt, id)` | Chronological subscription/admin reads and bounded trend ranges. | One write per subscription; `createdAt` immutable. |
| Reports | ADD `(status, createdAt, id)` | Moderation queue status filter plus stable chronology. | Status changes rewrite this index. |
| PrivacyRequests | REPLACE `(userId, requestedAt)` with `(userId, requestedAt, id)` | Covers the stable tie-breaker used by owner history. | Small extra key width. |
| Blocks | REMOVE exact duplicate `blocks_blocked_blocker`; retain `blocks_blocked_blocker_lookup` | `information_schema` showed both were identical `(blockedUserId, blockerUserId)`. | Reduces duplicate write/storage cost without removing coverage. |

Rollback was executed successfully on the local development schema and the migration was then reapplied. Final migration status is `up`.

## Existing coverage retained

- Users: unique email/google/phone identity; account status/id; identity verification/id; last activity/id.
- Profiles: unique user; discovery eligibility `(onboardingCompleted,birthDate,communicationStyle,userId)`.
- Relationships: unique/reverse match pairs, unique/reverse block pairs, unique discover actor-target, saved-profile pairs, rose sender idempotency and recipient chronology.
- Chat: participant pair and user/conversation, conversation activity, messages conversation/id and conversation/sender/id, message media.
- Notifications: user inbox order, unread lookup, dedupe uniqueness, delivery retry queue.
- Admin/moderation: verification queues, report-case state, matching failures, audit actor/action/target chronology.
- Finance: payment status/currency/user chronology and provider/idempotency uniqueness; subscription entitlement and provider/user uniqueness.
- Privacy: owner chronology, request type/status, artifact status/expiry and owner chronology, confirmation expiry.

## Duplicate or redundant findings

- REMOVED: exact duplicate reverse block pair index, verified by identical ordered columns.
- RETAINED: overlapping notification inbox/unread indexes because one preserves chronological feed order and the other serves unread state.
- RETAINED: payment status/history and currency/history because they serve distinct leading predicates.
- RETAINED: user account-status, verification, activity, and creation indexes; all represent separate high-value filters.
- No other index is removed without slow-query/usage evidence from staging.

## Index limitations

- `LOWER(column)`, `CAST(height)`, JSON search/extraction, `DATE(createdAt)` grouping, trigonometric distance, and calculated compatibility ordering cannot be fully solved by ordinary B-tree indexes.
- Leading-wildcard `LIKE '%term%'` searches remain scans within their bounded/date-filtered domains.
- Low-cardinality leading columns such as status are useful only when paired with chronology and selective queues; production distributions must be checked.
- More indexes increase write amplification. S2 deliberately avoids speculative indexes on every JSON/filter column.
