# AMORAA MATCH ENGINE — PHASE 5 COMPATIBILITY SCORING

## Purpose and authority

`Backend/src/services/compatibilityScoringService.js` is the authoritative compatibility contract. `matchEngineService.js` is a backward-compatible re-export only. The canonical module owns factor definitions, normalization, JavaScript factor construction, score/coverage calculation, reason derivation, and generation of the equivalent SQL expressions used by Discover.

Normal Discover keeps hard eligibility, `minScore`, ordering, and pagination in SQL. AI Matches receives the already-created canonical compatibility object for every candidate returned by the same eligibility query and may only rerank that eligible set.

## Factor contract

| Factor | Type | Weight | Candidate read bound |
|---|---:|---:|---:|
| Interests | list | 35 | 20 |
| Relationship goals | list | 25 | 30 |
| Communication style | scalar | 10 | n/a |
| Languages | list | 10 | 30 |
| City | scalar | 5 | n/a |
| Smoking | scalar | 5 | n/a |
| Drinking | scalar | 5 | n/a |
| Weed | scalar | 5 | n/a |

The total weight is 100. The bounds make SQL work deterministic and bounded; JavaScript uses the same bounds. Interests remains aligned with its existing 20-item API maximum. The larger 30-item bounds safely cover legacy relationship-goal and language arrays without unbounded SQL expansion.

## Canonical normalization

Scalars accept strings only, then trim and lowercase them. Null, undefined, non-string values, blank strings, and the exact normalized value `prefer not to say` are unavailable.

Lists must be arrays. The engine applies the factor read bound, accepts string elements only, applies scalar normalization to each element, removes unavailable elements, and deduplicates while preserving first occurrence order. Nulls, scalar/malformed JSON shapes, and mixed non-string elements cannot create evidence and cannot throw. Shared values come only from the normalized intersection; public shared strings have control characters removed and are deduplicated again before explanation use.

## Agreement, score, and coverage

For an available list factor:

`agreement = intersection size / max(viewer normalized size, candidate normalized size)`

For an available scalar factor, agreement is 1 for exact normalized equality and 0 otherwise. A factor is available only when both sides have usable data. Unavailable factors add neither positive nor negative evidence.

The engine calculates:

```
availableWeight = sum(weight of available factors)
weightedAgreement = sum(weight * agreement)
rawScore = availableWeight > 0
  ? 100 * weightedAgreement / availableWeight
  : 50
coverageFraction = availableWeight / 100
finalScore = clamp(round(50 + (rawScore - 50) * coverageFraction), 0, 100)
```

The final expression is mathematically equivalent to `50 + weightedAgreement - availableWeight / 2`. JavaScript removes only sub-picosecond binary floating-point drift before rounding so exact mathematical half values agree with SQL `ROUND`. No comparable data returns score 50, raw score 50, and coverage 0. One perfect 5-point factor returns score 53 rather than an unsupported 100.

The returned canonical object preserves `score`, `rawScore`, and `coverage` and also exposes the explicit aliases `compatibilityScore`, `compatibilityRawScore`, and `compatibilityCoverage`. Each factor carries `key`, `type`, `weight`, `available`, `agreement`/`value`, `weightedAgreement`, and bounded shared values.

## SQL strategy and database compatibility

`sqlCompatibilityExpressions()` is generated from the same `MATCH_FACTORS` definitions. Viewer data is normalized once. Candidate scalar SQL mirrors trim/lowercase/unavailable semantics. Candidate list SQL extracts only JSON string elements, normalizes them, excludes blanks and declined values, and uses `COUNT(DISTINCT ...)` for both candidate cardinality and intersection cardinality. It never uses raw `JSON_LENGTH` as the agreement denominator.

The local/test server was verified as MariaDB `10.4.32-MariaDB`. It does not provide MySQL `JSON_TABLE`; it does provide bounded sequence tables, which the MariaDB path uses (`seq_0_to_19` and `seq_0_to_29`). The repository's documented Docker-compatible runtime is MySQL 8. The MySQL 8 path uses `JSON_TABLE` only as the bounded ordinal source and feeds those ordinals into the same normalization/count expression. The runtime major version selects the supported path. No CTE, window function, generated column, stored function, data rewrite, or migration is required.

All viewer literals are escaped with Sequelize. Candidate columns are guarded by `JSON_VALID` and `JSON_TYPE = 'ARRAY'`, so SQL nulls and valid malformed legacy JSON shapes become empty/unavailable rather than errors.

## Discover, filtering, and ranking

The SQL final score is used for `minScore`, the selected `compatibilityScore`, and ranking. Therefore a returned score S is included at `minScore=S` and excluded at `minScore=S+1`, subject to other eligibility rules.

Default Discover order remains compatibility descending, then numeric user ID ascending. Near You remains distance ascending, compatibility descending, then numeric user ID ascending. SQL applies offset/limit for normal Discover; no full eligible population is loaded into JavaScript. JavaScript constructs canonical factors only for the selected response rows so serialization and reasons share the same object; this adds no database queries.

## AI Matches and serialization

AI Matches uses the same SQL eligibility/minimum-score path and the same canonical compatibility object. The LOCAL AI provider does not recompute a different compatibility score. Its existing score, confidence, level, highlight, reason, and tie-break formulas are unchanged.

`publicProfileService` accepts an already-canonical compatibility object. When called elsewhere without one, it falls back to the same authoritative engine. `compatibilityScore`, `compatibilityCoverage`, `compatibilityReasons`, and the existing structured `compatibility` response remain backward compatible. Reasons are derived from canonical factors rather than an independent overlap calculation. The legacy `computeCompatibilityScore` utility is only a delegate to the authoritative engine.

## Equivalence and regression evidence

Focused tests cover all factor definitions, every optional-factor subset, symmetry, determinism, malformed values, duplicate/blank/declined/case/whitespace list values, scalar normalization, no-data neutrality, low-coverage calibration, reasons, and the unchanged deterministic seed examples.

Database integration verifies SQL score and coverage against JavaScript for a fixed 128-profile dirty-data matrix, plus rich/cold-start, null/empty, malformed-list-shape, declined, whitespace, duplicate, mixed-element, and zero-score cases. Integration also locks exact `minScore` boundaries, dirty-data ordering, Discover/AI equality, public serialization, eligibility, reciprocal rules, and Near You ordering.

The known clean deterministic seed expectations remain unchanged: Dhruv Shah 92, Rhea Patel 87, Kabir Menon 62, Jay Shah 53, and Naina Rao 48.

## Performance considerations

Recommendation query count remains 10 for both 50- and 100-candidate normal Discover measurements, and 10 in the observed 25/50/100 AI measurements. No candidate-proportional query or N+1 path was added. Normal Discover remains SQL-paginated.

The normalization expressions deliberately trade more database CPU for exact legacy-data semantics. The 100-candidate Discover regression test completes in roughly four seconds on the local MariaDB test environment, and `EXPLAIN` shows repeated bounded sequence scans plus a filesort for computed ranking. This is acceptable for the current correctness phase but is a documented scale risk. A future production optimization may persist normalized projections or cache ranking only if it preserves this contract and is measured against production-like volume.

## Deferred work

Phase 5 does not change offset-pagination mutation drift, cursor/snapshot pagination, AI Matches Flutter load-more, total-count semantics, external AI providers, or ranking snapshots. Those remain Phase 6/7 concerns.
