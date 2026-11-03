# AMORAA Match Engine — Phase 2 P0 Remediation & Final Sign-Off Report

**Document Version:** 2.0.0  
**Date:** November 2, 2026  
**Branch:** `p0-safety-remediation`  
**Repository:** `D:\Projects\amora_ai`  
**Environment:** Local Isolated Test Environment (`amora_ai_test` on `127.0.0.1:3306`)  
**Production Isolation:** Fully preserved. VPS `195.35.23.132` untouched; zero production deployments, zero SSH commands, zero PM2 restarts, zero production DB operations.  
**Frontend Scope:** 0 Flutter/frontend files modified.  

---

## 1. Executive Summary & Verdict

### Final Verdict: **`PASS — READY FOR P0 SIGN-OFF`**

All four P0 security, data integrity, and correctness vulnerabilities (`VULN-P0-01`, `VULN-P0-02`, `VULN-P0-03`, `VULN-P0-04`) and the legacy test discrepancy (`TEST-P0-01`) identified in `AMORAA_MATCH_ENGINE_P0_FINAL_REVIEW.md` have been comprehensively remediated, audited, and verified across all four relevant backend test suites.

| Finding ID | Severity | Title | Status | Verification Summary |
| :--- | :---: | :--- | :---: | :--- |
| **`VULN-P0-01`** | **HIGH** | Missing Coordinates Distance Bypass | **RESOLVED** | All 4 permutations of viewer/target coordinate presence with active distance limits strictly validated; fail-safe defaults prevent distance bypass. |
| **`VULN-P0-02`** | **HIGH** | Report Suppression Status Semantics | **RESOLVED** | Asymmetric suppression covers `'open'`, `'reviewing'`, and `'resolved'` in both directions; reporter retains suppression on `'dismissed'` without false platform-wide penalty to accused. |
| **`VULN-P0-03`** | **MEDIUM** | BLOCK Must Enforce Complete Bilateral Severance | **RESOLVED** | Atomic `Match.destroy` and `DiscoverAction.destroy`, notification soft-deletion, WebSocket eviction via `severRealtimePair`, and zero match revival on unblock. |
| **`VULN-P0-04`** | **LOW** | Reciprocal Swipe Concurrency & Lock Ordering | **RESOLVED** | Added `transaction.LOCK.UPDATE` to reciprocal `DiscoverAction.findOne`. Deterministic canonical user ordering prevents deadlocks across like-vs-like and like-vs-rewind races. |
| **`TEST-P0-01`** | **LOW (TEST)** | Stale Legacy Assertion in Discover Suite | **RESOLVED** | Assertion updated to expect exclusion of reported profiles; user fixtures populated with valid test coordinates. |

---

## 2. Test Execution & Verification Summary

### Comprehensive Test Run
```bash
node --test Backend/test/discover-eligibility-policy.test.js Backend/test/like-persistence.integration.test.js Backend/test/p0-safety-remediation.integration.test.js Backend/test/discover.integration.test.js
```

### Execution Results
- **Suites:** 4
- **Total Tests:** 62
- **Passed:** 62 (100%)
- **Failed:** 0
- **Duration:** 42.02 seconds
- **Database Schema:** `amora_ai_test` (`127.0.0.1:3306`)
- **Production Server:** Completely untouched (zero network egress to VPS `195.35.23.132`)

### Test Suite Breakdown
1. **`Backend/test/discover-eligibility-policy.test.js`**: 11 passed (100%)
2. **`Backend/test/like-persistence.integration.test.js`**: 6 passed (100%)
3. **`Backend/test/p0-safety-remediation.integration.test.js`**: 21 passed (100%)
4. **`Backend/test/discover.integration.test.js`**: 24 passed (100%)

---

## 3. Detailed Remediation Analysis (Before vs. After)

### Fix 1 — `VULN-P0-01`: Missing Coordinates Distance Bypass
- **Target File:** [`Backend/src/services/discoverEligibilityPolicy.js`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js)
- **Function Changed:** `validateSwipeEligibility`
- **Root Cause:**
  When a candidate had missing coordinates, the function checked if the viewer had a distance restriction; however, when the *viewer* lacked coordinates or *neither* user had coordinates, the logic fell through to `return { eligible: true }`. Consequently, users with strict maximum distance limits could be swiped by or matched with users anywhere globally without verified proximity.
- **Before Behavior:**
  - `!viewerHasCoords && targetHasCoords` returned `{ eligible: true }` unless target specifically configured a restriction.
  - `!viewerHasCoords && !targetHasCoords` fell through to `{ eligible: true }`.
  - A user with no coordinates could swipe candidates worldwide, bypassing the candidate's distance filters.
- **After Behavior:**
  - Evaluates all 4 combinations of coordinate availability:
    1. **Viewer Coords & Target Coords:** Calculates Haversine distance; returns `{ eligible: false, reason: 'distance_exceeded' }` if $d > \min(\text{viewerMax}, \text{targetMax})$.
    2. **Viewer Coords & No Target Coords:** If either viewer OR target has configured a distance restriction: returns `{ eligible: false, code: 'PROFILE_NOT_DISCOVERABLE', reason: 'target_location_missing' }`.
    3. **No Viewer Coords & Target Coords:** If either viewer OR target has configured a distance restriction: returns `{ eligible: false, code: 'PROFILE_NOT_DISCOVERABLE', reason: 'viewer_location_missing' }`.
    4. **No Viewer Coords & No Target Coords:** If either party has configured a distance restriction: returns `{ eligible: false, code: 'PROFILE_NOT_DISCOVERABLE', reason: 'location_required' }`.
    5. If neither party has a distance restriction configured (`maxDistanceKm == null`), the check allows global matching (`{ eligible: true }`).
- **Tests Added/Updated:**
  - `discover-eligibility-policy.test.js`:
    - Viewer missing coordinates with target restriction configured $\rightarrow$ `viewer_location_missing`.
    - Viewer missing coordinates with viewer restriction configured $\rightarrow$ `viewer_location_missing`.
    - Target missing coordinates with viewer restriction configured $\rightarrow$ `target_location_missing`.
    - Target missing coordinates with target restriction configured $\rightarrow$ `target_location_missing`.
    - Both missing coordinates with restriction configured $\rightarrow$ `location_required`.
    - Both missing coordinates with no restriction configured $\rightarrow$ `eligible: true`.
    - One missing coordinates with no restriction configured $\rightarrow$ `eligible: true`.
    - Exact boundary distance ($1.22\text{ km} \le 1.25\text{ km}$) $\rightarrow$ `eligible: true`.
    - Outside boundary distance ($1.22\text{ km} > 1.20\text{ km}$) $\rightarrow$ `distance_exceeded`.
  - `p0-safety-remediation.integration.test.js`:
    - `Fix 1 (VULN-P0-01): Missing coordinates cannot bypass distance restriction` $\rightarrow$ verifies HTTP 404 response on `/api/discover/swipe`.

---

### Fix 2 — `VULN-P0-02`: Report Suppression Status Semantics
- **Target Files:**
  - [`Backend/src/services/accessControlService.js`](file:///D:/Projects/amora_ai/Backend/src/services/accessControlService.js)
  - [`Backend/src/controllers/discoverController.js`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js)
- **Functions Changed:** `notReportedUserSql`, `areUsersReported`, `isUserReportedBy`
- **Root Cause:**
  Condition B (where Candidate reported Viewer) previously only checked `status IN ('open', 'reviewing')`. As soon as moderators marked a report `'resolved'` (substantiated terms violation), the offender regained visibility of the victim in Discover Feed, AI Matches, and Swiping. Furthermore, it lacked consistent handling for `'dismissed'` reports where false accusations should not penalize the accused user globally.
- **Before Behavior:**
  - Resolved reports re-exposed victims to offenders.
  - Missing `targetType = 'profile'` fallback on candidate side.
- **After Behavior:**
  - **Condition A (Viewer reported Candidate):** `status IN ('open', 'reviewing', 'resolved', 'dismissed')`. A user who reports another user never sees that user again across any report lifecycle state.
  - **Condition B (Candidate reported Viewer):** `status IN ('open', 'reviewing', 'resolved')`. While a report is pending (`open`, `reviewing`) or confirmed/substantiated (`resolved`), the accused offender cannot discover or swipe on the victim.
  - If the report was `dismissed` by moderation as unfounded, the accused user is NOT suppressed from discovering the reporter, preventing weaponized false reporting.
  - Both conditions check `(reportedUserId = :id OR (targetType = 'profile' AND targetId = CAST(:id AS CHAR)))`.
- **Tests Added/Updated:**
  - `p0-safety-remediation.integration.test.js`:
    - `Fix 2 (VULN-P0-02): Resolved report maintains bilateral suppression between offender and victim` $\rightarrow$ verifies mutual Discover feed exclusion and HTTP 404 swipe rejection.
    - `Fix 2 (VULN-P0-02): Dismissed report preserves reporter suppression without falsely punishing accused user` $\rightarrow$ verifies reporter feed exclusion while accused user remains active.
    - `Fix 2 (VULN-P0-02): Report suppression matrix across all statuses in both directions` $\rightarrow$ exhaustive 4-status matrix verifying both reporter $\to$ reported and reported $\to$ reporter paths for Discover and Swipe.

---

### Fix 3 — `VULN-P0-03`: Block Must Enforce Complete Bilateral Severance
- **Target Files:**
  - [`Backend/src/controllers/blockController.js`](file:///D:/Projects/amora_ai/Backend/src/controllers/blockController.js)
  - [`Backend/src/realtime/realtimeHub.js`](file:///D:/Projects/amora_ai/Backend/src/realtime/realtimeHub.js)
  - [`Backend/src/services/notificationService.js`](file:///D:/Projects/amora_ai/Backend/src/services/notificationService.js)
- **Functions Changed:** `blockController.create`, `blockController.remove`, `severRealtimePair`, `createNotification`
- **Root Cause:**
  `blockController.create` previously created a `Block` record and filtered conversations at query-time, but left the physical `Match` row intact in `Matches` table and left past `DiscoverAction` entries intact. If a user unblocked another user, the old match could resurrect. Furthermore, active WebSocket connections were not ejected from direct conversation rooms, and notifications could still be queued between blocked actors.
- **Before Behavior:**
  - `Matches` row remained in the database indefinitely.
  - Unblocking revived the active match.
  - WebSocket conversation rooms remained joined by connected clients.
  - Existing unread notifications between the pair remained visible.
- **After Behavior:**
  - **Atomic Transactional Severance:**
    - `Match.destroy({ where: { userOneId, userTwoId }, transaction })` permanently deletes the mutual match row.
    - `DiscoverAction.destroy` permanently purges bilateral like/superLike actions.
    - `Notification.update({ deletedAt: new Date() })` soft-deletes all existing notifications between the pair.
  - **Realtime Severance:**
    - Added `severRealtimePair(blockerUserId, blockedUserId)` to `realtimeHub.js`.
    - Evicts both users' active sockets from the direct conversation room (`socket.leave(convRoom)`).
    - Dispatches `conversation.severed` events with `{ reason: 'blocked' }` to both private user rooms.
  - **Notification Guard:**
    - `notificationService.createNotification` enforces `if (actorUserId && await areUsersBlocked(userId, actorUserId, { transaction })) return null;`, preventing any new notifications between blocked users.
  - **Permanent Unmatch on Unblock:**
    - `blockController.remove` destroys the `Block` record only; it never recreates the destroyed `Match` (`restoredMatch: false`).
- **Tests Added/Updated:**
  - `p0-safety-remediation.integration.test.js`:
    - `Fix 3 (VULN-P0-03): BLOCK enforces complete bilateral severance and deletes active Match`:
      - Asserts `Match` row deleted from DB.
      - Asserts conversation `canMessage: false`, `messages: []`, `availabilityReason` set.
      - Asserts sending messages returns HTTP 404.
      - Asserts profile view returns HTTP 404.
      - Asserts swiping returns HTTP 404.
      - Asserts unblocking leaves `Match` at 0 (`restoredMatch: false`).
    - `Fix 3 (VULN-P0-03): BLOCK enforces notification suppression, socket severance, and bilateral feed invisibility`:
      - Asserts pre-existing notification is soft-deleted upon block and excluded from notifications feed.
      - Asserts new notifications between blocked users return `null`.
      - Asserts bilateral invisibility in Discover feed.

---

### Fix 4 — `VULN-P0-04`: Reciprocal Swipe Concurrency & Lock Ordering
- **Target Files:**
  - [`Backend/src/controllers/discoverController.js`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js)
  - [`Backend/src/middleware/rateLimiter.js`](file:///D:/Projects/amora_ai/Backend/src/middleware/rateLimiter.js)
  - [`Backend/src/routes/discoverRoutes.js`](file:///D:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js)
- **Functions Changed:** `discoverController.swipe`, `discoverController.rewind`
- **Root Cause:**
  In `discoverController.swipe`, the reciprocal `DiscoverAction.findOne` was executed without a transaction row lock (`lock: transaction.LOCK.UPDATE`). If User A called `/rewind` at the exact millisecond User B liked User A, `swipe` could read User A's like row before `rewind` committed its deletion, creating an orphaned Match.
- **Before Behavior:**
  - Reciprocal `DiscoverAction.findOne` had no row lock.
  - Rewind of mutual match lacked rate limiting and could race with reciprocal swipe.
- **After Behavior:**
  - **Row-Level Lock Acquisition:**
    Added `lock: transaction.LOCK.UPDATE` to the reciprocal query in `discoverController.swipe`:
    ```javascript
    const reciprocal = await DiscoverAction.findOne({
      where: {
        actorUserId: targetUserId,
        targetUserId: req.user.sub,
        action: { [Op.in]: ['like', 'superLike'] },
      },
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    ```
  - **Deadlock-Free Canonical Ordering:**
    Swipes lock `User` rows in ascending primary key order `[min(A, B), max(A, B)]` with `order: [['id', 'ASC']]` and `lock: transaction.LOCK.UPDATE`.
    Rewind locks the actor's latest `DiscoverAction`, then checks `Match` with `lock: transaction.LOCK.UPDATE`.
    Because `swipe` locks `User` first, then `DiscoverAction`, and `Match` is only touched after reciprocal lock, there is no circular wait.
  - **Rewind Integrity (Decision 3B):**
    If a like triggered a confirmed mutual match, `/rewind` returns HTTP `409 CANNOT_REWIND_MATCH`.
  - **Rewind Rate Limiting:**
    `discoverRewindLimiter` applied on `POST /api/discover/rewind` (30 requests per 5 minutes per user/IP).
- **Tests Added/Updated:**
  - `p0-safety-remediation.integration.test.js`:
    - `Fix 4 (VULN-P0-04): Concurrent reciprocal swiping serializes safely without deadlock` $\rightarrow$ parallel simultaneous likes serialize without deadlock, creating exactly 1 Match.
    - `Fix 4 (VULN-P0-04): Concurrent rewind requests serialize cleanly (one 200, one 404)` $\rightarrow$ two simultaneous rewinds serialize: exactly one succeeds (200), the second returns 404 `NOTHING_TO_REWIND`.
    - `Fix 4 (VULN-P0-04): Like-versus-rewind race resolves consistently without deadlock or corruption` $\rightarrow$ concurrent reciprocal like vs. rewind resolves cleanly to either a confirmed match or a safe unconfirmed like.
    - `Fix 4 (VULN-P0-04): Repeated rewind immediately after successful rewind returns 404 NOTHING_TO_REWIND`.
    - `Fix 4 (VULN-P0-04): Transaction rollback preserves database consistency when swipe fails`.
    - `P0-4 Rate Limiting: Rewind rate limiter throttles excess requests` $\rightarrow$ throttles after 30 requests with HTTP 429 `RATE_LIMITED`.

---

### Fix 5 — `TEST-P0-01`: Stale Legacy Assertion
- **Target File:** [`Backend/test/discover.integration.test.js`](file:///D:/Projects/amora_ai/Backend/test/discover.integration.test.js)
- **Root Cause:**
  Lines 281 and 310 had legacy assertions expecting reported profiles to *remain visible* in Discover feed (`assert.equal(ids.has(byPolicy.report.id), true)`), which broke once SEC-03 report suppression was properly implemented.
- **Before Behavior:**
  Test expected `byPolicy.report.id` in Discover feed.
- **After Behavior:**
  Updated assertion to `assert.equal(ids.has(String(byPolicy.report.id)), false, 'report')`, correctly asserting that reports exclude candidates from Discover feed while `rose` and `save` alone do not.
- **Verification:**
  `Backend/test/discover.integration.test.js` passes all 24 tests.

---

## 4. Concurrency & Transactional Analysis

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                          LOCK ORDERING & SERIALIZATION HIERARCHY                       │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ Operation         │ Lock 1                    │ Lock 2               │ Lock 3          │
├───────────────────┼───────────────────────────┼──────────────────────┼─────────────────┤
│ POST /swipe       │ User [min(A,B), max(A,B)] │ DiscoverAction (own) │ DiscoverAction  │
│                   │                           │                      │   (reciprocal)  │
├───────────────────┼───────────────────────────┼──────────────────────┼─────────────────┤
│ POST /rewind      │ DiscoverAction (own)      │ Match [min, max]     │ -               │
├───────────────────┼───────────────────────────┼──────────────────────┼─────────────────┤
│ POST /blocks/:id  │ Block (findOrCreate)      │ Match (destroy)      │ DiscoverAction  │
│                   │                           │                      │   (destroy)     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

1. **Deadlock Prevention:**
   All operations touching dual-user state order participant IDs canonically: `userOneId = Math.min(idA, idB)` and `userTwoId = Math.max(idA, idB)`. When two users concurrently swipe each other, both threads acquire locks on `User` rows in identical primary key order ($A \to B$), completely eliminating circular wait conditions.
2. **Swipe vs. Rewind Serialization:**
   `swipe` locks reciprocal `DiscoverAction` with `transaction.LOCK.UPDATE`. A concurrent `rewind` from the other user acquires `transaction.LOCK.UPDATE` on the same row. Whichever transaction executes first commits cleanly; the subsequent transaction reads the committed state and either finds no reciprocal action or sees the confirmed match and raises `409 CANNOT_REWIND_MATCH`.
3. **Rollback Safety:**
   All multi-row database mutations execute within managed `Sequelize` transactions. If any step fails, the entire transaction rolls back atomically without partial state corruption.

---

## 5. Scope & Safety Adherence Verification

| Safety Constraint | Status | Audit Verification |
| :--- | :---: | :--- |
| **No Production Access** | **VERIFIED** | Zero SSH connections, zero PM2 restarts, zero Nginx reloads, zero network calls to VPS `195.35.23.132`. |
| **Local Test DB Only** | **VERIFIED** | All tests executed against `amora_ai_test` on `127.0.0.1:3306`. `bootstrapEnv.js` strictly guards non-test databases. |
| **No Flutter/Frontend Edits** | **VERIFIED** | `git diff --stat` confirms zero modifications to Flutter, Dart, or frontend assets. |
| **No P1/P2 Scope Creep** | **VERIFIED** | Deferred items (AES cursor encryption, coordinate bucketing/coarsening, 15-min rewind window, unnesting query optimizations) remain cleanly excluded. |
| **Non-Destructive Git** | **VERIFIED** | All work performed strictly on branch `p0-safety-remediation` without rebase or force-push. |
| **Zero Secrets Leaked** | **VERIFIED** | No passwords, tokens, API keys, or JWT secrets written to logs, tests, or documentation. |

---

## 6. Remaining Risks & Deferred Work (P1/P2 Scope)

The following items are deliberately deferred to Phase 3 (P1) and Phase 4 (P2) per the project architecture plan:

1. **Phase 3 (P1 — Privacy & UX Polish):**
   - **Recommendation Cursor Tokenization:** Migrate base64 JSON cursor to AES-256-GCM encrypted tokens to prevent ranking telemetry inspection.
   - **Coordinate Coarsening:** Introduce coordinate fuzzing/bucketing (1–2 km radius) to protect user location privacy.
   - **15-Minute Rewind Window:** Enforce time limit on `/rewind` per Product Decision 9.
   - **Chat Retention Schedule:** Implement configurable `UNMATCH_RETENTION_DAYS` once legal review confirms DPDP Act requirements.
2. **Phase 4 (P2 — Performance & Scalability):**
   - **Query Unnesting:** Optimize candidate selection subqueries in `discoverController.getFeed` for high-concurrency production scale.
   - **Compound Indexing:** Add dedicated compound indices for `(actorUserId, targetUserId, action)` on high-volume read surfaces.

---

## 7. Sign-Off Statement

All critical P0 vulnerabilities and test discrepancies have been systematically remediated and verified with 62 passing tests. The codebase on branch `p0-safety-remediation` is in a safe, consistent, and validated state.

**Verdict:** **`PASS — READY FOR P0 SIGN-OFF`**  
**Engineering Recommendation:** Ready for review and merge into the staging environment. Phase 3 (P1) work should not begin until separate authorization is received.
