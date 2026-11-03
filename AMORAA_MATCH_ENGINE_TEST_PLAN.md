# AMORAA — Match Engine Test Suite & Verification Plan

**Document:** `AMORAA_MATCH_ENGINE_TEST_PLAN.md`  
**Project:** AMORAA Dating Application  
**Repository:** `D:\Projects\amora_ai`  
**Author:** DeepMind Agentic Coding Assistant (Antigravity)  
**Date:** November 2026  
**Status:** PROPOSED TEST SPECIFICATION (Strictly Read-Only Design)

---

## 1. Overview & Test Architecture

This document defines the comprehensive test specification for the AMORAA Match Engine. It covers unit, integration, concurrency, security, and load testing across the Flutter client, Node.js API, and MySQL persistence layer.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TEST EXECUTION HIERARCHY                        │
│                                                                        │
│  [Security & Privacy Unit Tests]  ──► Cursor decryption, PII filters  │
│  [Mathematical Scoring Unit Tests] ──► 8-factor score determinism      │
│  [Eligibility Integration Tests]  ──► Feed & swipe reciprocal filters │
│  [Transaction & Mutual Match Tests]──► Concurrency, row-locking       │
│  [Rewind & State Integrity Tests] ──► Match & conversation consistency│
│  [Staging Load & Capacity Tests]  ──► 100–1,000 req/s, 1M candidates │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Test Suites Specification

### 3.1 Eligibility Test Suite

Test File: `Backend/test/match-engine-eligibility.integration.test.js`

| Test ID | Test Scenario | Input Conditions | Expected Outcome | HTTP Code / DB State |
| :---: | :--- | :--- | :--- | :---: |
| **ELIG-01** | Candidate outside viewer acceptable age range | Viewer seeks 21–25; Candidate age is 28. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-02** | Viewer outside candidate reciprocal age range | Viewer age is 22; Candidate preference is 25–35. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-03** | Incompatible viewer gender preference | Viewer seeks 'female'; Candidate gender is 'male'. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-04** | Incompatible candidate reciprocal gender preference | Candidate seeks 'female'; Viewer gender is 'male'. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-05** | Universal gender preference handling | Viewer seeks 'everyone' or 'all'. | Candidate of any gender included. | `200 OK` (Feed returned) |
| **ELIG-06** | Distance exceeds viewer maximum distance | Candidate located 65 km away; viewer max is 50 km. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-07** | Distance exceeds candidate reciprocal distance | Viewer located 45 km away; candidate max is 30 km. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-08** | Missing viewer location coordinates | Viewer has `matchLatitude = null` on surface `near_you`. | Request rejected with error. | `409 LOCATION_REQUIRED` |
| **ELIG-09** | Incomplete candidate profile | Candidate has $< 2$ photos or `stage != 'complete'`. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-10** | Deactivated or deleted candidate account | Candidate `accountStatus = 'deactivated'` or `'deleted'`. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-11** | Self-swipe attempt | Actor attempts `POST /api/discover/swipe` with `targetUserId = actorId`. | Request rejected; recorded in action failures. | `400 INVALID_TARGET` |
| **ELIG-12** | Two-way block exclusion | Candidate blocked viewer, or viewer blocked candidate. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-13** | Reported user exclusion | Viewer previously submitted report against candidate. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-14** | Previously passed profile exclusion | Viewer previously swiped 'pass' on candidate. | Excluded from feed; swipe rejected. | `404 PROFILE_NOT_DISCOVERABLE` |
| **ELIG-15** | Previously liked profile exclusion | Viewer previously swiped 'like' on candidate. | Excluded from feed; swipe idempotent. | `200 OK {"likeStatus": "already_liked"}` |
| **ELIG-16** | Existing mutual match exclusion | Candidate is already matched with viewer in `Matches`. | Excluded from feed. | `200 OK` (Candidate not in list) |
| **ELIG-17** | Concurrent swipe requests from same user | 5 concurrent identical swipe requests for same target. | Exactly 1 `DiscoverAction` upserted; no race error. | `200 OK` (All return consistent state) |

---

### 3.2 Compatibility Scoring Test Suite

Test File: `Backend/test/compatibility-scoring.unit.test.js`

All test calculations are verified independently from the source implementation:
$$\text{Score} = \text{clamp}\left(50 + S - \frac{A}{2}, \, 0, \, 100\right)$$
where $S = \sum (w_i \cdot v_i)$ and $A = \sum (w_i \cdot a_i)$.

| Test ID | Test Scenario | Profile Inputs | Independent Mathematical Derivation | Expected Score | Expected Coverage | Expected Confidence |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: |
| **SCORE-01** | **Perfect Match** | All 8 factors present and 100% identical. | $A = 100$, $S = 100$<br/>$\text{Score} = 50 + 100 - 50 = 100$ | **100** | **100%** | **High** |
| **SCORE-02** | **Zero Agreement** | All 8 factors present, zero overlapping values. | $A = 100$, $S = 0$<br/>$\text{Score} = 50 + 0 - 50 = 0$ | **0** | **100%** | **High** |
| **SCORE-03** | **Neutral Baseline** | All 8 factors missing on both profiles. | $A = 0$, $S = 0$<br/>$\text{Score} = 50 + 0 - 0 = 50$ | **50** | **0%** | **Low** |
| **SCORE-04** | **Partial Overlap** | - Interests: 2 of 4 shared ($v=0.5, w=35 \to 17.5$)<br/>- Goals: 1 of 2 shared ($v=0.5, w=25 \to 12.5$)<br/>- Style: Match ($v=1.0, w=10 \to 10$)<br/>- City: Match ($v=1.0, w=5 \to 5$)<br/>- Others: Missing ($a=0$) | $A = 35+25+10+5 = 75$<br/>$S = 17.5+12.5+10+5 = 45$<br/>$\text{Score} = 50 + 45 - 37.5 = 57.5 \to 58$ | **58** | **75%** | **Medium** |
| **SCORE-05** | **Missing Scalar Factors** | Interests (100%), Goals (100%), Languages (100%), Style (100%). Smoking, Drinking, Weed, City missing. | $A = 35+25+10+10 = 80$<br/>$S = 80$<br/>$\text{Score} = 50 + 80 - 40 = 90$ | **90** | **80%** | **High** |
| **SCORE-06** | **"Prefer Not To Say" Handling** | Viewer: `smoking: 'no'`. Candidate: `smoking: 'prefer not to say'`. | Treated as missing ($a=0$); does not penalize agreement. | Factor excluded from $A$ | Reduced by 5% | Neutral contribution |
| **SCORE-07** | **Case & Whitespace Insensitivity** | Viewer: `city: ' Ahmedabad '`. Candidate: `city: 'ahmedabad'`. | Normalized to lowercase trimmed: agreement $v=1.0$. | $5 / 5$ points | Included in $A$ | Positive contribution |
| **SCORE-08** | **Duplicate List Values** | Viewer: `['music', 'music', 'Travel']`. Candidate: `['Music', 'TRAVEL']`. | Deduplicated sets: 2 shared, length 2 $\to v=1.0$. | $35 / 35$ points | Included in $A$ | Positive contribution |
| **SCORE-09** | **Symmetry / Bi-directionality** | Calculate `scoreCompatibility(A, B)` and `scoreCompatibility(B, A)`. | Formula uses symmetric set intersections and max lengths. | Exact match: $Score(A, B) \equiv Score(B, A)$ | Same | Same |
| **SCORE-10** | **AI Matches Heuristic Adjustment** | Candidate has `baseScore = 80`, `coverage = 100%`. | $\text{Adjustment} = \text{round}((100 - 50) \times 0.08) = +4$<br/>$\text{aiMatchScore} = 80 + 4 = 84$ | **84** | **100%** | **High** |

---

### 3.3 Mutual Matching Test Suite

Test File: `Backend/test/mutual-matching.integration.test.js`

| Test ID | Test Scenario | Execution Steps | Expected System State | Verification Queries |
| :---: | :--- | :--- | :--- | :--- |
| **MATCH-01** | Unilateral Like | User A likes User B. | `DiscoverActions` has row `(A, B, 'like')`. Notification sent to B. No Match or Conversation created. | `SELECT COUNT(*) FROM Matches WHERE userOneId = min(A,B)` returns `0`. |
| **MATCH-02** | Reciprocal Like Completion | User A likes User B. Subsequently, User B likes User A. | `Matches` row created with `userOneId = min(A,B)`. Direct `Conversations` row created with `pairKey = 'min:max'`. Socket event emitted. | `SELECT COUNT(*) FROM Matches` returns `1`. `SELECT COUNT(*) FROM Conversations` returns `1`. |
| **MATCH-03** | Simultaneous Concurrent Likes | User A and User B swipe like on each other at the exact same millisecond. | Row locks (`ORDER BY id ASC`) serialize execution. Exactly 1 `Matches` row created; zero duplicate key errors. | `SELECT COUNT(*) FROM Matches` returns `1`. |
| **MATCH-04** | Super Like Reciprocal Completion | User A superLikes User B. User B likes User A. | Match created successfully. User B received `new_super_like` notification. | Notification category is `'Super Likes'`. |
| **MATCH-05** | Transaction Rollback on Failure | Conversation participant mapping deliberately fails during match transaction. | Transaction rolls back completely; neither `Matches` nor partial `Conversations` rows persist. | DB state remains at unilateral like. |
| **MATCH-06** | Deactivated User During Swipe | Target user account status changes to `'deactivated'` immediately before swipe commit. | Transaction aborts; returns `404 PROFILE_NOT_DISCOVERABLE`. No match created. | Target status enforced inside lock. |

---

### 3.4 Rewind Test Suite

Test File: `Backend/test/discover-rewind.integration.test.js`

| Test ID | Test Scenario | Input & Preconditions | Expected Outcome | HTTP Code / DB Verification |
| :---: | :--- | :--- | :--- | :---: |
| **RWND-01** | Rewind standard pass | User swiped 'pass' 2 minutes ago; calls `/rewind`. | Action destroyed; passed profile immediately reappears in next `/feed` call. | `200 OK {"action": "pass"}` |
| **RWND-02** | Rewind unilateral like | User swiped 'like' 1 minute ago (no mutual match). | Action destroyed; like record removed from `DiscoverActions`. | `200 OK {"action": "like"}` |
| **RWND-03** | Rewind when no action exists | User has never swiped or already rewound last action. | Request rejected. | `404 NOTHING_TO_REWIND` |
| **RWND-04** | Rewind mutual match attempt | User A and B matched; User A attempts `/rewind`. | **Rejected.** Confirmed mutual match cannot be rewound. | `409 CANNOT_REWIND_MATCH` |
| **RWND-05** | Rewind outside permitted window | Last action occurred 25 minutes ago (limit is 15 min). | **Rejected.** Rewind window expired. | `400 REWIND_WINDOW_EXPIRED` |
| **RWND-06** | Rate limit enforcement on rewind | Client submits 15 `/rewind` requests in 10 seconds. | 11th request throttled by rate limiter. | `429 Too Many Requests` |
| **RWND-07** | Concurrent rewind and reciprocal like | User A calls rewind while User B simultaneously likes A. | Serialized via database locks; either match is blocked cleanly or rewind fails with 409. | Zero orphaned records in DB. |

---

### 3.5 Report, Block, and Safety Test Suite

Test File: `Backend/test/safety-access-control.integration.test.js`

| Test ID | Test Scenario | Execution Steps | Expected Outcome | Verification |
| :---: | :--- | :--- | :--- | :--- |
| **SAFE-01** | Report excludes from Discover Feed | User A files report on User B. User A calls `GET /api/discover/feed`. | User B is not present anywhere in returned candidate profiles. | User B excluded via SQL anti-join. |
| **SAFE-02** | Report excludes from AI Matches | User A files report on User B. User A calls `GET /api/discover/ai-matches`. | User B is not present in AI recommendations. | User B excluded via SQL anti-join. |
| **SAFE-03** | Two-way block bilateral exclusion | User A blocks User B. | User B cannot see User A; User A cannot see User B. | Bilateral feed suppression verified. |
| **SAFE-04** | Block terminates conversation access | User A blocks matched partner User B. User A attempts to view chat. | Conversation access returns `404` / access denied via `conversationAccessService`. | `activeMatch` / block check returns `null`. |
| **SAFE-05** | Duplicate report rate limiting | User A attempts to submit 10 reports against User B in 1 minute. | Rate limiter throttles excess reports. | `429 Too Many Requests` |
| **SAFE-06** | Moderator dismissal of report | Admin resolves report as `dismissed`. | Target user status restored (if suspended); remains excluded from reporter's personal feed. | Reporter preference respected. |

---

### 3.6 Pagination and Privacy Test Suite

Test File: `Backend/test/cursor-privacy-pagination.unit.test.js`

| Test ID | Test Scenario | Test Verification Method | Expected Result |
| :---: | :--- | :--- | :--- |
| **PRIV-01** | Cursor payload inspection | Base64url-decode part 0 of `nextCursor`. | **Zero plaintext coordinates, raw float distances, or third-party IDs revealed.** Payload is encrypted ciphertext or coarse token. |
| **PRIV-02** | Cursor tampering detection | Alter 1 character in the cursor payload and call `GET /api/discover/feed?cursor=<tampered>`. | Returns `400 PAGINATION_CURSOR_INVALID`. Tampered cursor rejected in constant time. |
| **PRIV-03** | Context change detection | Save cursor; update user's `minAge` preference; request next page with saved cursor. | Returns `400 PAGINATION_CONTEXT_CHANGED`. User must restart feed from page 1. |
| **PRIV-04** | Pagination duplicate prevention | Fetch page 1 (limit 10), then page 2 using `nextCursor`. Compare profile ID sets. | **Intersection of Page 1 IDs and Page 2 IDs is completely empty.** Zero duplicate cards. |
| **PRIV-05** | Zero skipped profiles | Total eligible profiles = 25. Page 1 (10) + Page 2 (10) + Page 3 (5). | Total unique IDs fetched equals exactly 25. Zero profiles skipped. |
| **PRIV-06** | Public profile coordinate stripping | Inspect JSON response of `GET /api/discover/feed` and `GET /api/profiles/:id`. | `matchLatitude` and `matchLongitude` are **undefined / omitted**. Distance is rounded to nearest 5 km. |

---

### 3.7 Security & Penetration Test Suite

Test File: `Backend/test/security-penetration.unit.test.js`

| Test ID | Vulnerability Category | Attack Vector / Injection Payload | Expected Defensive Result |
| :---: | :--- | :--- | :--- |
| **SEC-01** | **IDOR in Swipe** | Authenticated User A submits `POST /api/discover/swipe` with `targetUserId = <Random User ID>` that fails eligibility. | Returns `404 PROFILE_NOT_DISCOVERABLE`. Action rejected and logged. |
| **SEC-02** | **IDOR in Unmatch** | User C attempts `DELETE /api/matches/:matchId` for a match between User A and User B. | Returns `404 MATCH_NOT_AVAILABLE`. Match is not deleted. |
| **SEC-03** | **IDOR in Chat Access** | User C attempts `GET /api/conversations/:id` for conversation between User A and User B. | Returns `404 CONVERSATION_NOT_AVAILABLE`. |
| **SEC-04** | **Replay Attack on Rewind** | Intercept and replay `POST /api/discover/rewind` multiple times. | First request succeeds; all subsequent replays return `404 NOTHING_TO_REWIND`. |
| **SEC-05** | **Sensitive Data in Logs** | Inspect console and Winston output during user registration, login, and swiping. | Passwords, OTPs, JWTs, and exact GPS coordinates are **never logged**. |
| **SEC-06** | **User Account Enumeration** | Submit invalid profile requests with sequential IDs. | Generic error messages returned; no timing differences between missing vs. private accounts. |

---

### 3.8 Performance and Load Test Suite (Staging Only)

Tooling: k6 / Artillery scripts in `Backend/test/load/`

| Test ID | Test Scenario | Concurrency & Load Target | Candidate Pool Size | Proposed Metric & Acceptance Threshold |
| :---: | :--- | :--- | :---: | :--- |
| **LOAD-01** | Standard Discover Feed Concurrency | 100 concurrent virtual users (VUs) for 5 minutes. | 10,000 profiles | P95 Latency $< 200$ ms; Error Rate $< 0.1\%$. |
| **LOAD-02** | Peak Discover Feed Concurrency | 500 concurrent VUs ramping over 3 minutes. | 50,000 profiles | P95 Latency $< 450$ ms; Zero connection pool timeouts. |
| **LOAD-03** | Stress Load & Pool Saturation | 1,000 concurrent VUs (burst traffic). | 100,000 profiles | P99 Latency $< 1,200$ ms; MySQL CPU $< 85\%$. |
| **LOAD-04** | AI Matches Heap Memory Test | 50 concurrent requests to `/api/discover/ai-matches`. | 50 candidates per window | Node.js process heap growth $< 25$ MB; GC pauses $< 40$ ms. |
| **LOAD-05** | Swipe & Match Transaction Throughput | 250 concurrent swipe requests/second. | N/A | Zero transaction deadlocks (`ER_LOCK_DEADLOCK`); P99 $< 150$ ms. |
| **LOAD-06** | Capacity Simulation (1M Profiles) | Query planner simulation on partitioned MySQL schema. | 1,000,000 profiles | `EXPLAIN` confirms index coverage; zero table scans. |

*(Note: Thresholds are engineering targets for staging qualification, not production contractual SLAs).*
