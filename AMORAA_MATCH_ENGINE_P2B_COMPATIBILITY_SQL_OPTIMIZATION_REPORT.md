# AMORAA MATCH ENGINE — PHASE 4 P2-B
# COMPATIBILITY SCORING SQL OPTIMIZATION REPORT

**Document Version:** 1.0.0  
**Date:** November 2, 2026  
**Status:** COMPLETE & INDEPENDENTLY VERIFIED  
**Final Verdict:** **PASS — P2-B COMPLETE**  
**Authorized Branch:** `p0-safety-remediation`  
**Test Environment:** Isolated Local Database (`amora_ai_test` @ `127.0.0.1:3306`)  
**Production Status:** STRICTLY UNTOUCHED (Zero network connections, zero SSH, zero deployments)

---

## 1. EXECUTIVE SUMMARY

Phase 4 P2-B (Compatibility Scoring SQL Optimization) of the AMORAA Match Engine has been successfully audited, optimized, benchmarked, and verified.

The primary objective of P2-B was to eliminate repeated correlated subqueries, redundant JSON extractions, and duplicate availability checks in the database-backed compatibility scoring engine without altering any compatibility formulas, factor weights, candidate rankings, or public API contracts.

### Key Performance & Architectural Achievements:
1. **-28.9% Query Latency Reduction:** Query execution time for candidate compatibility evaluation and ordering decreased from **480.78 ms to 342.04 ms median** (a net latency reduction of **-138.74 ms**) and P95 latency dropped from **554.53 ms to 410.89 ms** (**-143.64 ms / -25.9%**).
2. **-56.3% Dependent Subquery Reduction in Execution Plan:** Total EXPLAIN plan rows dropped from **32 rows (30 dependent subqueries)** down to **14 rows (12 dependent subqueries)** per candidate row evaluation.
3. **-66.7% Score Subquery Reduction:** The number of correlated subqueries inside `scoreSql` dropped from **9 subqueries down to 3 subqueries** (1 unified subquery per list factor instead of 3).
4. **-40.1% Query Text Footprint:** The generated SQL expression string for `scoreSql` shrank from **19,181 characters to 11,486 characters**, reducing SQL parser overhead and client-server wire payload.
5. **Fast Short-Circuiting Availability (`EXISTS`):** List factor availability checking in `coverage` now uses `EXISTS (SELECT 1 ... LIMIT 1)` instead of full sequence table scans with `COUNT(DISTINCT item) > 0`, terminating immediately on the first valid list element.
6. **100% Numerical Equivalence:** Automated testing against all eight factors independently, an exhaustive 64-profile matrix, and a deterministic 128-profile dirty matrix verified zero mathematical drift between the JavaScript reference oracle and optimized SQL.
7. **Complete Regression Verification:** All 12 automated test suites passed with **233 / 233 tests passing (100%)**, verifying total continuity with P0, P1-A, P1-B, P1-C, P1-D, P1-E, and P2-A controls.

---

## 2. INITIAL COMPATIBILITY SQL ARCHITECTURE & AUDIT

### 2.1. Environment Versions
- **Database Engine:** MariaDB `10.4.32-MariaDB` (host `127.0.0.1:3306`, schema `amora_ai_test`)
- **Sequelize Version:** `6.37.5`
- **Storage Engine:** InnoDB
- **Dialect:** MySQL / MariaDB compatible

### 2.2. Scoring Formula Reference
The Match Engine evaluates eight weighted compatibility factors summing to 100:

| Factor | Weight | Type | Max Items | Comparison Semantics |
| :--- | :---: | :---: | :---: | :--- |
| **Interests** | 35 | List | 20 | Distinct usable intersection / GREATEST(viewerCount, candidateCount) |
| **Relationship Goals** | 25 | List | 30 | Distinct usable intersection / GREATEST(viewerCount, candidateCount) |
| **Communication Style** | 10 | Scalar | N/A | Exact match on `LOWER(TRIM(val)) != 'prefer not to say'` |
| **Languages** | 10 | List | 30 | Distinct usable intersection / GREATEST(viewerCount, candidateCount) |
| **City** | 5 | Scalar | N/A | Case-insensitive exact match |
| **Smoking** | 5 | Scalar | N/A | Exact match on normalized lifestyle value |
| **Drinking** | 5 | Scalar | N/A | Exact match on normalized lifestyle value |
| **Weed** | 5 | Scalar | N/A | Exact match on normalized lifestyle value |
| **TOTAL** | **100** | — | — | $\sum W_i = 100$ |

Canonical Mathematical Formulation:
Let $S = \sum (\text{weight}_i \times \text{agreement}_i)$ and $A = \sum \text{availableWeight}_i$.
$$\text{Score} = \text{clamp}\left(50 + S - \frac{A}{2}, 0, 100\right)$$
$$\text{Coverage} = \text{clamp}\left(\text{ROUND}\left(\frac{100 \times A}{100}\right), 0, 100\right)$$

### 2.3. Initial Correlated Subquery & JSON Inventory
In the pre-optimization implementation of `sqlCompatibilityExpressions`:
- For each list factor ($k \in \{\text{interests, relationshipGoals, languages}\}$):
  1. `candidateCount`: `(SELECT COUNT(DISTINCT item) FROM indexSource WHERE usable)`
  2. `sharedCount`: `(SELECT COUNT(DISTINCT item) FROM indexSource WHERE usable AND item IN (viewerList))`
  3. `available`: `(CASE WHEN (SELECT COUNT(DISTINCT item) FROM indexSource WHERE usable) > 0 THEN weight ELSE 0 END)`
- Because `candidateCount` was injected into both `weighted` (as denominator) and `available`, the exact same correlated subquery was repeated twice per factor in `scoreSql`.
- Across the 3 list factors, `scoreSql` contained $3 \times 3 = 9$ correlated subqueries.
- Because `scoreSql` is evaluated in `SELECT`, `WHERE (scoreSql >= minScore)`, and `ORDER BY (scoreSql DESC)`, MySQL evaluated **30 dependent subqueries** per candidate row ($9 + 3 + 9 + 9 = 30$).

---

## 3. IMPLEMENTED SQL OPTIMIZATIONS

### 3.1. Unified Single-Subquery Net Score Contribution (`P2-B-01` & `P2-B-06`)
Because addition and subtraction are linear, the global score expression $50 + \sum S_i - \frac{\sum A_i}{2}$ is mathematically identical to $50 + \sum \left( S_i - \frac{A_i}{2} \right)$.

For list factors, instead of evaluating `candidateCount` twice and `sharedCount` once in separate subqueries, a **single subquery** now computes the factor's net score contribution in one pass over `indexSource`:

```sql
(SELECT (
  (definition.weight * (COUNT(DISTINCT CASE WHEN item IN (viewerList) THEN item END) / GREATEST(viewerLength, COUNT(DISTINCT item))))
  -
  (CASE WHEN COUNT(DISTINCT item) > 0 THEN (definition.weight / 2) ELSE 0 END)
) FROM indexSource AS indexAlias WHERE boundedIndex AND usable)
```

**Mechanics:**
- If candidate has 0 usable items: `COUNT(DISTINCT item) = 0`, `COUNT(DISTINCT CASE ...) = 0`, GREATEST evaluates to `viewerLength`, yielding $0 - 0 = 0$.
- If candidate has usable items: `COUNT(DISTINCT item)` and `sharedCount` are computed simultaneously in a single scan of `indexSource`, and $\frac{\text{weight}}{2}$ is subtracted.
- **Result:** Subqueries in `scoreSql` reduced from **9 subqueries to 3 subqueries** (-66.7%).

### 3.2. Scalar Net Contribution Folding (`P2-B-05`)
For scalar factors (City, Smoking, Drinking, Weed, Communication Style), the net contribution is:
$$\text{Net} = \text{weighted} - \frac{\text{available}}{2}$$
- If available and matches: $+\frac{\text{weight}}{2}$.
- If available and mismatches: $-\frac{\text{weight}}{2}$.
- If unavailable: $0$.

Optimized SQL expression:
```sql
(CASE WHEN available THEN (CASE WHEN match THEN (weight / 2) ELSE -(weight / 2) END) ELSE 0 END)
```
Eliminates duplicate evaluation of the `available` condition inside the scalar score term.

### 3.3. Fast Short-Circuiting Factor Availability with `EXISTS` (`P2-B-01`)
In `availableWeights` (used by `coverage` and `rawScore`), the previous logic executed:
```sql
(CASE WHEN (SELECT COUNT(DISTINCT item) FROM indexSource WHERE usable) > 0 THEN weight ELSE 0 END)
```
This required scanning all 20 or 30 sequence rows and building a DISTINCT temporary structure just to check if the count was $> 0$.

Optimized expression:
```sql
(CASE WHEN EXISTS (SELECT 1 FROM indexSource AS indexAlias WHERE boundedIndex AND usable) THEN weight ELSE 0 END)
```
MySQL/MariaDB aborts the scan immediately upon reading the first valid row (`LIMIT 1` optimization), eliminating 95% of row examinations for active profiles.

---

## 4. BEFORE VS. AFTER BENCHMARK & TIMING MEASUREMENTS

Benchmarks were conducted on the isolated local database `amora_ai_test` using the complete Discover feed candidate scoring query across 15 measured iterations after warmup.

### Performance Summary Table

| Metric | Pre-Optimization (Baseline) | Post-Optimization (P2-B) | Delta / Improvement |
| :--- | :---: | :---: | :---: |
| **Score Subqueries Count** | 9 subqueries | **3 subqueries** | **-6 subqueries (-66.7%)** |
| **Total Query Subqueries (EXPLAIN)** | 30 dependent subqueries | **12 dependent subqueries** | **-18 subqueries (-60.0%)** |
| **Total EXPLAIN Rows** | 32 rows | **14 rows** | **-18 rows (-56.3%)** |
| **Score SQL Text Length** | 19,181 characters | **11,486 characters** | **-7,695 chars (-40.1%)** |
| **Median Execution Latency** | 480.78 ms | **342.04 ms** | **-138.74 ms (-28.9%)** |
| **P95 Execution Latency** | 554.53 ms | **410.89 ms** | **-143.64 ms (-25.9%)** |
| **Min Execution Latency** | 451.20 ms | **320.15 ms** | **-131.05 ms (-29.0%)** |
| **Full Discover Suite Duration** | 17.57 s | **15.61 s** | **-1.96 s (-11.2%)** |

---

## 5. NUMERICAL EQUIVALENCE & VERIFICATION

A dedicated test suite, [`compatibility-scoring-equivalence.test.js`](file:///d:/Projects/amora_ai/Backend/test/compatibility-scoring-equivalence.test.js), was developed and executed to ensure 100% mathematical fidelity.

### Verification Categories:
1. **Factor-by-Factor Tests (All 8 Factors):**
   - Interests (weight 35): Exact matches, partial intersections, disjoint sets, nulls, empty arrays, duplicate removal, decline filtering. **PASS**
   - Relationship Goals (weight 25): Subset matching, disjoint goals, nulls, casing. **PASS**
   - Communication Style (weight 10): Scalar match, mismatch, whitespace trimming, casing. **PASS**
   - Languages (weight 10): Exact match, subset, empty, null. **PASS**
   - City (weight 5): Case-insensitive match, mismatch, null. **PASS**
   - Smoking (weight 5): Exact match, mismatch, null. **PASS**
   - Drinking (weight 5): Exact match, mismatch, null. **PASS**
   - Weed (weight 5): Exact match, mismatch, null. **PASS**
2. **Formula Edge Cases:**
   - 100% agreement on all 8 factors $\to$ Score 100, Coverage 100. **PASS**
   - 0% agreement on all 8 factors $\to$ Score 0, Coverage 100. **PASS**
   - 0 factors available $\to$ Baseline Score 50, Coverage 0. **PASS**
   - Partial factor availability (interests only) $\to$ Calibrated Score 68, Coverage 35. **PASS**
   - Scalar-only profile $\to$ Exact fractional score aggregation. **PASS**
3. **Dirty Data & Matrix Verification:**
   - 128-profile dirty matrix across null arrays, declined answers, whitespace, booleans, and numbers: **0 mismatches across 128 profiles**.
   - 64-profile combinatorial matrix: **0 mismatches across 64 profiles**.

---

## 6. COMPLETE REGRESSION TEST SUITE (233 / 233 PASS)

All 12 Match Engine test suites were executed sequentially against `amora_ai_test`:

| # | Test Suite | File Path | Tests Passed | Status |
| :-: | :--- | :--- | :-: | :-: |
| 1 | Chat Access & Severance | `test/chat-access-severance.test.js` | 52 / 52 | **PASS** |
| 2 | Rewind Expiration Policy | `test/rewind-expiration.test.js` | 35 / 35 | **PASS** |
| 3 | Recommendation Cursor | `test/recommendation-cursor.test.js` | 22 / 22 | **PASS** |
| 4 | Location Privacy | `test/location-privacy.test.js` | 10 / 10 | **PASS** |
| 5 | Location & Distance Integration | `test/location-distance.integration.test.js` | 12 / 12 | **PASS** |
| 6 | P0 Security Remediation | `test/p0-safety-remediation.integration.test.js` | 21 / 21 | **PASS** |
| 7 | Discover Eligibility Policy | `test/discover-eligibility-policy.test.js` | 11 / 11 | **PASS** |
| 8 | Discover Integration | `test/discover.integration.test.js` | 24 / 24 | **PASS** |
| 9 | Like Persistence | `test/like-persistence.integration.test.js` | 6 / 6 | **PASS** |
| 10 | Mutual Like Chat | `test/mutual-like-chat.integration.test.js` | 3 / 3 | **PASS** |
| 11 | Candidate Materialization (P2-A) | `test/candidate-materialization.test.js` | 20 / 20 | **PASS** |
| 12 | Compatibility Scoring Equivalence (P2-B) | `test/compatibility-scoring-equivalence.test.js` | 17 / 17 | **PASS** |
| **TOTAL** | **Comprehensive Match Engine Suite** | **12 Test Suites** | **233 / 233 (100%)** | **PASS** |

---

## 7. RECOMMENDATIONS RESERVED FOR P2-C AND P2-D

1. **Reserved for P2-C (Indexes & Schema Optimization):**
   - Candidate sorting currently requires a filesort (`Using temporary; Using filesort`) because `compatibilityScore` is dynamically computed from JSON expressions and cannot use a standard B-Tree index. In P2-C, investigate whether precomputed or generated composite indexes on commonly filtered attributes (`city`, `gender`, `identityVerifiedAt`) can further reduce candidate set sizes prior to sorting.
2. **Reserved for P2-D (Load & Concurrency Stress Testing):**
   - High concurrent swipe and recommendation loads should be benchmarked under simulated 1,000-user concurrent traffic in P2-D.

---

## 8. ENVIRONMENT & SAFETY CONFIRMATION

- **Production VPS `195.35.23.132`:** Never contacted, zero SSH sessions, zero deployments.
- **Database Isolation:** All benchmarks and test runs operated solely on local `amora_ai_test` at `127.0.0.1:3306`.
- **Zero Frontend Changes:** Zero modifications to Flutter/Dart files.
- **Zero Schema Changes:** No migrations or index alterations introduced.

---

## 9. FINAL VERDICT

### **PASS — P2-B COMPLETE**

Phase 4 P2-B optimizations are fully implemented, verified, and benchmarked. Query latency dropped by **28.9%**, dependent subqueries dropped by **60%**, generated SQL text shrank by **40.1%**, numerical equivalence is 100% preserved, and all **233 automated tests pass cleanly**.

### Next Phase Transition:
Work is stopped. Standing by for authorization before beginning **Phase 4 P2-C (Database Index & Schema Optimization)**.
