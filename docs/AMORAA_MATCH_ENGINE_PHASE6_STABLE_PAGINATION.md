# AMORAA MATCH ENGINE — PHASE 6 STABLE PAGINATION

## Scope

Phase 6 replaces recommendation offset paging with signed opaque keyset cursors for default Discover, Near You, and LOCAL AI Matches. It does not change eligibility, compatibility, distance eligibility, reciprocal rules, or LOCAL AI formulas.

## Why offset paging was removed

Offset continuation is unsafe for a mutable eligible set. If page one contains A–E and those rows become excluded through Pass, Like, Super Like, Match, or Block, a later `OFFSET 5` starts after a shifted set and can skip F–J. Keyset continuation instead resumes strictly after the last ranking tuple returned by the server.

## Cursor contract

`Backend/src/services/recommendationCursorService.js` owns cursor creation and validation. A cursor is a bounded base64url payload plus an HMAC-SHA256 signature made with the existing `JWT_SECRET`. It contains only technical fields: cursor version, ranking version, viewer ID, surface, a SHA-256 context fingerprint, and the last ranking tuple.

The cursor contains no coordinates, birth date, sexuality, tokens, OTPs, or candidate profile data. Private viewer inputs participate only in the one-way context fingerprint.

The cursor is bound to:

- the authenticated viewer ID;
- the canonical surface;
- `MATCH_ENGINE_VERSION` through `MATCH_RANKING_VERSION`;
- effective saved/request filters;
- runtime filter defaults and recent-activity window;
- viewer inputs that affect eligibility, compatibility, or distance.

Malformed, over-size, incorrectly signed, wrong-viewer, wrong-surface, and unsupported-version cursors return a controlled `400`. A changed viewer/filter/location context returns `PAGINATION_CONTEXT_CHANGED`. Cursors have no short time expiry; signing, versioning, and context binding provide technical validity.

## Ranking and continuation

### Default Discover

Order remains `compatibilityScore DESC, User.id ASC`. The SQL continuation predicate is:

`score < lastScore OR (score = lastScore AND userId > lastUserId)`.

The predicate uses the Phase 5 canonical SQL compatibility expression. Normal Discover remains SQL-paginated with `limit + 1`; it does not load the full user table and uses no continuation offset.

### Near You

Order remains `distance ASC, compatibilityScore DESC, User.id ASC`. Distance is calculated by the Phase 3 SQL Haversine expression and normalized to six decimal places for both ordering and cursor comparison. This stable internal precision is approximately millimetre-level and is independent of the rounded whole-kilometre public distance.

Continuation compares distance, then canonical compatibility score, then user ID in the same directions as the order.

### LOCAL AI Matches

The backend continues to load the complete eligible set and apply the existing deterministic LOCAL ranker globally. Order remains `aiMatchScore DESC, aiConfidence DESC, userId ASC`. Cursor filtering is applied to that globally ranked list before taking `limit + 1` semantics. No AI score, confidence, explanation, or provider formula changed.

## Live mutation semantics

Pagination uses live eligibility plus stable keyset continuation; it does not persist candidate snapshots.

- Removing an earlier result through an action, Match, Block, or lifecycle change does not shift the continuation point and therefore does not skip later ranking tuples.
- A candidate after the cursor who becomes ineligible disappears naturally.
- A new candidate ranked before the cursor is not injected into later pages.
- A new candidate ranked after the cursor may appear in a later page.
- Candidate profile edits can change a candidate's score or distance between requests. Live keyset paging intentionally does not promise an immutable historical snapshot for such edits.
- A continuation with no remaining eligible rows returns an empty list, `hasMore: false`, and `nextCursor: null`.

## HTTP request and response

The default and maximum limits remain 10 and 30. Canonical pagination metadata is:

```json
{
  "hasMore": true,
  "nextCursor": "opaque-signed-value",
  "limit": 10,
  "rankingVersion": "v2:cursor-1"
}
```

No total count is returned or calculated. `page` absent or `page=1` starts a first page for transitional compatibility. `page>1` without a cursor returns `PAGINATION_CURSOR_REQUIRED`; offset continuation is not retained.

## Flutter Discover

`DiscoverApiService` sends an optional opaque cursor and retains `hasMore`, `nextCursor`, and ranking version. `BrowseGridScreen` resets the cursor on a fresh/filter-driven reload, keeps the current cursor while swiping, prefetches through the saved cursor, guards concurrent page requests, and deduplicates appended candidate user IDs while preserving server order.

Initial-load errors retain the existing full error state. A continuation failure keeps already loaded cards and records a separate load-more error; retry uses the same cursor. A failed swipe still leaves the current card in place.

## Flutter AI Matches

`AiRecommendationsPage` retains recommendations and pagination metadata. `MatchesScreen` stores `hasMore` and `nextCursor`, appends unique candidate IDs without sorting API results, and provides a load-more control with a separate progress state and retryable error. Existing recommendations remain visible if a later request fails.

If local threshold/quick filtering hides every loaded recommendation while the server reports more pages, the screen continues loading bounded cursor pages until a visible result is found or the server is exhausted. A local empty result therefore does not prematurely declare the server feed empty.

## Query and index notes

Primary user IDs, account status, profile/user foreign keys, DiscoverAction actor/target indexes, Match participant indexes, and bidirectional Block indexes continue to support eligibility joins and exclusions. Compatibility and distance are computed expressions, so the database can still require a filesort; Phase 6 adds no speculative index. Query-count tests confirm candidate-pool growth does not introduce N+1 behavior.

## Backward compatibility

Current Flutter callers use cursors only. First-page legacy callers remain safe. Legacy page 2+ calls fail explicitly instead of silently using mutation-unsafe offset paging. Cursor errors use the existing structured API failure format and never expose decode, JSON, or HMAC internals.
