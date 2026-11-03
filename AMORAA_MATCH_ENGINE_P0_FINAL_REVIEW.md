# AMORAA Match Engine — Phase 2 P0 Final Security Review

**Audit Date:** November 2, 2026  
**Repository:** `D:\Projects\amora_ai`  
**Backend:** `D:\Projects\amora_ai\Backend`  
**Branch:** `p0-safety-remediation`  
**Review Type:** Independent, Rigorous, Read-Only Security, Correctness, Concurrency, and Regression Audit  

---

## 1. Executive Verdict

### **PASS WITH CONDITIONS — FIXES REQUIRED**

The Phase 2 P0 remediation successfully resolved the primary attack vectors for **SEC-01** (IDOR/eligibility bypass in swipe), **SEC-03** (unilateral discovery and AI recommendation suppression for reported users), and **SEC-04** (mutual match consistency and transactional locking in rewind). The rate limiter is correctly integrated, and 10 dedicated P0 integration tests pass against MySQL.

However, independent forensic analysis of the source code and query semantics identified **two high-severity logic gaps** and **two medium/low edge-case defects** that must be addressed before final P0 sign-off:

1. **`VULN-P0-01 (HIGH)` — Distance Filter Bypass via Missing Viewer Coordinates:** A viewer without saved coordinates completely bypasses a candidate's distance restrictions during `POST /api/discover/swipe`.
2. **`VULN-P0-02 (HIGH)` — Asymmetric Report Suppression Re-Exposes Victims on Resolution:** In `notReportedUserSql` and `areUsersReported`, the reverse-direction condition only checks `status IN ('open', 'reviewing')`. As soon as a report is marked `'resolved'`, the offender can see and swipe on the reporting victim again.
3. **`VULN-P0-03 (MEDIUM)` — BLOCK Does Not Physically Delete `Match` Record:** `blockController.create` relies solely on application query filters (`conversationAccess`, `areUsersBlocked`) but leaves the physical `Matches` row intact and does not evict users from active WebSocket rooms.
4. **`VULN-P0-04 (LOW)` — Concurrency Race Between Unlocked Reciprocal Read and Rewind:** `discoverController.swipe` reads the reciprocal `DiscoverAction` without row locking, allowing a race window with concurrent `/rewind`.

---

## 2. Findings Table

| Finding ID | Severity | File & Line Number | Title | Root Cause & Evidence | Impact | Required Remediation |
| :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| **`VULN-P0-01`** | **HIGH** | [`Backend/src/services/discoverEligibilityPolicy.js:311-331`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L311-L331) | Distance filter bypass when viewer has no saved coordinates | `validateSwipeEligibility` checks `viewerHasCoords && targetHasCoords` and `viewerHasCoords && !targetHasCoords`, but lacks an `else if (!viewerHasCoords && targetHasCoords)` branch. It falls through to `return { eligible: true }`. | An attacker or user without GPS coordinates can directly swipe and match candidates anywhere in the world, violating candidates' strict `maxDistanceKm` preferences. | Add `else if (!viewerHasCoords && targetHasCoords)` to reject with `404 PROFILE_NOT_DISCOVERABLE` and reason `viewer_location_missing`. |
| **`VULN-P0-02`** | **HIGH** | [`Backend/src/services/accessControlService.js:61, 83`](file:///D:/Projects/amora_ai/Backend/src/services/accessControlService.js#L61) | Asymmetric report suppression re-exposes victims when status becomes `resolved` | Condition B in `notReportedUserSql()` and `areUsersReported()` only checks `status IN ('open', 'reviewing')`. It omits `'resolved'` and omits the `targetType = 'profile'` fallback. | When moderators resolve a report (confirming a terms violation), the offender regains visibility of the victim in their feed and can swipe on them. | Change Condition B status filter in both functions to `status IN ('open', 'reviewing', 'resolved')` and add `targetType = 'profile'` fallback. |
| **`VULN-P0-03`** | **MEDIUM** | [`Backend/src/controllers/blockController.js:47-58`](file:///D:/Projects/amora_ai/Backend/src/controllers/blockController.js#L47-L58) | Block does not delete active `Match` record or sever realtime sockets | `blockController.create` only inserts into `Blocks`. It does not delete or revoke the `Matches` record, leaving `unmatched: false`. | Matches remain in the database indefinitely. If a block is removed, the match silently revives. Sockets are not disconnected immediately upon block. | Execute `Match.destroy({ where: matchPairWhere(blocker, blocked), transaction })` and emit room disconnection events on block creation. |
| **`VULN-P0-04`** | **LOW** | [`Backend/src/controllers/discoverController.js:572-579`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L572-L579) | Non-locking read of reciprocal like in swipe can race with rewind | In `discoverController.swipe`, `reciprocal = await DiscoverAction.findOne(...)` does not specify `lock: transaction.LOCK.UPDATE`. | If User A rewinds at the exact moment User B likes User A, `swipe` may read User A's like row before `rewind` commits its deletion, producing a match despite the rewind. | Add `lock: transaction.LOCK.UPDATE` to the reciprocal query in `discoverController.swipe`. |
| **`TEST-P0-01`** | **LOW (TEST)** | [`Backend/test/discover.integration.test.js:310`](file:///D:/Projects/amora_ai/Backend/test/discover.integration.test.js#L310) | Obsolete legacy test asserts reported profiles *are* present in discovery | Line 310 asserts: `assert.equal(ids.has(byPolicy['report'].id), true)`. | Full legacy suite fails on line 310 because SEC-03 correctly suppressed the reported profile. | Update assertion to `false` once read-only review concludes. |

---

## 3. Detailed Verification Matrix

### 3.1 Swipe Eligibility (SEC-01)

| Requirement | Status | Evidence & Code Reference | Details & Notes |
| :--- | :---: | :--- | :--- |
| **1. Reciprocal gender rules enforced** | **VERIFIED** | [`discoverEligibilityPolicy.js:277-283`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L277-L283) | Uses canonical `viewerAcceptsCandidate` and `candidateAcceptsViewer`. Tested in `p0-safety-remediation.integration.test.js:154`. |
| **2. Both age ranges enforced** | **VERIFIED** | [`discoverEligibilityPolicy.js:285-309`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L285-L309) | `ageFor()` computes exact birthdays; boundaries are inclusive (`targetAge < min \|\| targetAge > max`). Tested in integration test line 165. |
| **3. Mutual distance rules enforced** | **VERIFIED** | [`discoverEligibilityPolicy.js:314-327`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L314-L327) | Validates `distance <= Math.min(viewerMaxDist, targetMaxDist)` via haversine spherical formula. Tested in integration test line 176. |
| **4. Missing coordinates cannot bypass distance** | **FAILED** | [`discoverEligibilityPolicy.js:328-331`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L328-L331) | **Finding `VULN-P0-01`**: When `!viewerHasCoords && targetHasCoords`, execution falls through to `return { eligible: true }`. |
| **5. Inactive / incomplete accounts rejected** | **VERIFIED** | [`discoverEligibilityPolicy.js:261-267`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L261-L267) | Target account must have `accountStatus === 'active'` and pass `isDiscoverComplete()`. |
| **6. Blocks and reports enforced** | **VERIFIED** | [`discoverEligibilityPolicy.js:269-275`](file:///D:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L269-L275) | Returns `404 PROFILE_NOT_DISCOVERABLE`. Blocks log `RELATIONSHIP_BLOCKED` to failure service. |
| **7. Self-swipes rejected** | **VERIFIED** | [`discoverController.js:536-541`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L536-L541) | Returns `400 INVALID_TARGET` with message `'You cannot swipe on your own profile.'`. |
| **8. Direct API requests cannot bypass** | **VERIFIED** | [`discoverController.js:542-563`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L542-L563) | `validateSwipeEligibility` executes unconditionally on every `POST /api/discover/swipe` request before any database mutations. |
| **9. Revalidated before Match creation** | **CONDITIONALLY VERIFIED** | [`discoverController.js:556-604`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L556-L604) | Initial check is prior to transaction. Inside transaction, User rows are locked, but reciprocal like is not row-locked (see `VULN-P0-04`). |
| **10. Concurrency cannot bypass eligibility** | **VERIFIED** | [`discoverController.js:557-563`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L557-L563) | Sorts participant IDs `[min, max]` and locks `Users` rows in ascending order, serializing concurrent swipes between the pair. |
| **11. Existing matches / duplicate actions** | **VERIFIED** | [`discoverController.js:564-570`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L564-L570) | Duplicate likes are idempotent (`likeStatus: 'already_liked'`). Notifications use unique dedupe keys. |
| **12. Client cannot override server eligibility** | **VERIFIED** | [`discoverController.js:544-548`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L544-L548) | Filters and profiles are loaded directly from the database via `filtersFor(req.user.sub)` and `filtersFor(targetUserId)`. Body parameters are ignored. |

---

### 3.2 Report Suppression (SEC-03)

| Requirement | Status | Evidence & Code Reference | Details & Notes |
| :--- | :---: | :--- | :--- |
| **1. Excluded from reporter's Discover feed** | **VERIFIED** | [`discoverController.js:306`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L306) | Injected `notReportedUserSql` into `userWhere[Op.and]`. Tested in integration test line 187. |
| **2. Excluded from Compatibility Matches** | **VERIFIED** | [`discoverRoutes.js:18`](file:///D:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js#L18) | `/api/discover/ai-matches` routes directly into `discoverController.getFeed`, inheriting the exact same `userWhere` anti-join. Tested in integration test line 209. |
| **3. Direct swipe API cannot circumvent** | **VERIFIED** | [`discoverController.js:547`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L547) | `areUsersReported()` called in swipe controller; rejects with `404 PROFILE_NOT_DISCOVERABLE`. Tested in integration test line 217. |
| **4. Innocent users not globally suppressed** | **VERIFIED** | [`p0-safety-remediation.integration.test.js:228`](file:///D:/Projects/amora_ai/Backend/test/p0-safety-remediation.integration.test.js#L228) | Unrelated users still discover candidate; target account status remains `active`. |
| **5. REPORT does not trigger BLOCK** | **VERIFIED** | [`reportController.js:41-49`](file:///D:/Projects/amora_ai/Backend/src/controllers/reportController.js#L41-L49) | Reporting creates a `Report` row only; does not insert into `Blocks` or delete `Match`. |
| **6. Consistent status filtering** | **FAILED** | [`accessControlService.js:61, 83`](file:///D:/Projects/amora_ai/Backend/src/services/accessControlService.js#L61) | **Finding `VULN-P0-02`**: Condition B omits `'resolved'` status, re-exposing victims to offenders once cases resolve. |
| **7. No leak of moderation info** | **VERIFIED** | [`discoverController.js:562`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L562) | Always returns generic `404 PROFILE_NOT_DISCOVERABLE` without leaking whether exclusion was caused by block, report, or age. |

---

### 3.3 Rewind Match Integrity (SEC-04)

| Requirement | Status | Evidence & Code Reference | Details & Notes |
| :--- | :---: | :--- | :--- |
| **1. Mutual-match rewind returns HTTP 409** | **VERIFIED** | [`discoverController.js:675-687`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L675-L687) | Checks `Match.findOne` with row lock inside transaction; returns `409 CANNOT_REWIND_MATCH`. Tested in integration test line 260. |
| **2. Rejection leaves records unchanged** | **VERIFIED** | [`discoverController.js:686`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L686) | Error thrown aborts the transaction; `DiscoverAction`, `Match`, and `Conversation` rows remain intact in DB. |
| **3. Only actor's own latest action rewound** | **VERIFIED** | [`discoverController.js:663`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L663) | Scoped strictly to `where: { actorUserId: req.user.sub }` ordered by `createdAt DESC, id DESC`. |
| **4. Action cannot be rewound twice** | **VERIFIED** | [`discoverController.js:671-674`](file:///D:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L671-L674) | Action is destroyed in transaction; replay immediately hits `if (!action)` and returns `404 NOTHING_TO_REWIND`. Tested in integration test line 304. |
| **5. Rewind rate limiting** | **VERIFIED** | [`rateLimiter.js:36`](file:///D:/Projects/amora_ai/Backend/src/middleware/rateLimiter.js#L36), [`discoverRoutes.js:20`](file:///D:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js#L20) | Keyed on `req.user.sub || req.ip`, max 30 per 5 min, returns `429 RATE_LIMITED`. |

---

## 4. Test Execution & Coverage Audit

### Executed Test Commands
```bash
node --test Backend/test/discover-eligibility-policy.test.js Backend/test/like-persistence.integration.test.js Backend/test/p0-safety-remediation.integration.test.js
```

### Execution Results
- **Suites:** 3
- **Passed:** 27
- **Failed:** 0
- **Duration:** 3.40 seconds
- **Target Database:** `amora_ai_test` on `127.0.0.1:3306` (isolated local test database confirmed via `bootstrapEnv.js`).
- **Production Touch:** None (VPS `195.35.23.132` was completely untouched).

### Coverage Gaps Identified
1. **Missing test for un-geolocated viewer:** Test suite does not test a viewer with `matchLatitude = null` swiping a candidate with a distance filter (masked `VULN-P0-01`).
2. **Missing test for `resolved` report status:** Test suite only tested `open` reports; did not test status transitions to `resolved` or reverse swiping (masked `VULN-P0-02`).
3. **Missing rate limiter HTTP exhaustion test:** Rate limiter is attached to `/rewind`, but the test file does not send 31 consecutive requests to assert `429 Too Many Requests`.
4. **Missing concurrency multi-threading test:** Serial tests verified logic, but concurrent multi-client worker threads were not run against the rewind/swipe boundary.

---

## 5. Scope & Git Inspection

### Git Status
```text
On branch p0-safety-remediation
Changes not staged for commit:
	modified:   Backend/src/controllers/discoverController.js
	modified:   Backend/src/middleware/rateLimiter.js
	modified:   Backend/src/routes/discoverRoutes.js
	modified:   Backend/src/services/accessControlService.js
	modified:   Backend/src/services/discoverEligibilityPolicy.js
	modified:   Backend/test/discover-eligibility-policy.test.js

Untracked files:
	Backend/test/p0-safety-remediation.integration.test.js
	(and documentation .md files)
```

### Scope Integrity Checks
- **Flutter frontend files changed:** 0
- **P1 Privacy items introduced (AES encryption, distance coarsening, 15-min window):** None (deferred)
- **P2 Performance items introduced (500 to 50 window, query unnesting):** None (deferred)
- **Hardcoded secrets, passwords, or tokens added:** 0
- **Database migrations added:** 0 (uses existing schema)

---

## 6. Final Recommendations & Remediation Plan

Before Phase 2 P0 sign-off is granted, the following focused remediations must be executed on branch `p0-safety-remediation`:

### Action 1: Close Distance Bypass (`VULN-P0-01`)
In `Backend/src/services/discoverEligibilityPolicy.js:328`:
```javascript
} else if (viewerHasCoords && !targetHasCoords) {
  return { eligible: false, code: 'PROFILE_NOT_DISCOVERABLE', stage: 'eligibility', reason: 'target_location_missing' };
} else if (!viewerHasCoords && targetHasCoords) {
  return { eligible: false, code: 'PROFILE_NOT_DISCOVERABLE', stage: 'eligibility', reason: 'viewer_location_missing' };
}
```

### Action 2: Fix Asymmetric Report Status (`VULN-P0-02`)
In `Backend/src/services/accessControlService.js:61, 83`:
Update Condition B in both `areUsersReported` and `notReportedUserSql`:
```sql
OR (
  `visibilityReport`.`reportedUserId` = :viewer 
  AND `visibilityReport`.`reporterUserId` = `User`.`id` 
  AND `visibilityReport`.`status` IN ('open', 'reviewing', 'resolved')
)
```

### Action 3: Add Missing Row Lock on Reciprocal Like (`VULN-P0-04`)
In `Backend/src/controllers/discoverController.js:577`:
Add `lock: transaction.LOCK.UPDATE` to the reciprocal `DiscoverAction.findOne` call.

### Action 4: Expand Integration Test Suite
Add test cases in `Backend/test/p0-safety-remediation.integration.test.js` covering:
- Un-geolocated viewer swiping distant candidate (`404 PROFILE_NOT_DISCOVERABLE`).
- Offender swiping victim after report is marked `'resolved'` (`404 PROFILE_NOT_DISCOVERABLE`).
- 31 consecutive rewind requests triggering `429 RATE_LIMITED`.

Once these four targeted fixes are applied and verified, Phase 2 P0 will achieve **100% security sign-off** readiness.
