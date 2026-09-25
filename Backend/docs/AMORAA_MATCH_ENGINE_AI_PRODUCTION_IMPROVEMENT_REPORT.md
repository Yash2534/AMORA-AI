# AMORAA Match Engine + AI Suggestions Production Improvement Report

Engineering audit started 2026-09-23. This permanent report records source evidence before implementation and will be completed with measured results. No external model is used.

## 1. Executive Summary

Reproduced the deterministic development seed: 26 eligible, 13 excluded; compatibility 48–92, mean 67.54, median 66. The reported AI defect is confirmed. Compatibility weights do not require tuning to manufacture higher scores.

## 2. Current Architecture

`lib/features/matches/presentation/matches_screen.dart` calls `PhaseTwoApiService.aiRecommendations` in `lib/core/api/phase_two_api_service.dart`. Authenticated GET `/api/discover/ai-matches` enters `Backend/src/routes/discoverRoutes.js`, sets `req.aiMatches`, then calls `discoverController.getFeed`. SQL eligibility precedes compatibility and LOCAL ranking. `aiMatchProvider.rankCandidates` orders candidates before controller page slicing; `publicProfileService.serializePublicProfile` serializes public profiles; `public_profile_mapper.dart` parses them in Flutter.

## 3. Current Eligibility Pipeline

`discoverPreferenceService.filtersFor` merges runtime defaults, stored filters, enabled filters and request overrides. `buildProfileWhere` enforces age, completed stage and optional filters. `discoveryPreferenceClauses` applies viewer gender acceptance and reciprocal candidate gender acceptance (empty candidate acceptance currently means unrestricted). User SQL excludes self, inactive accounts, bidirectional blocks (`accessControlService.notBlockedUserSql`), prior actions and existing matches. Verified/online/event filters are optional. There is no account-level visibility field in the current User/OnboardingProfile models; block/account/onboarding rules define discoverability. Reciprocal saved age filters and geographic distance are not implemented. These limitations must not be described as supported behavior.

## 4. Current Match Engine

`matchEngineService.scoreCompatibility`, version v2, weights: interests 35; relationshipGoals 25; communicationStyle 10; languages 10; city 5; smoking 5; drinking 5; weed 5. Total 100. Lists are trimmed, lowercased, deduplicated; overlap divided by the larger list size. Scalars use case-insensitive trimmed equality. Both sides must supply a factor for it to be available. Missing factors do not count as mismatch.

Let A be available weight, W weighted agreement. Raw score is 100W/A (50 if A=0), coverage A/100, final score round(50+(raw−50)×coverage), clamped 0–100. Thus missing information shrinks estimates toward neutral 50. Score and coverage are different quantities. No diet, exercise, pets, education, personality, core-values or behavioral score factors exist. City is categorical, not distance-based. All comparisons are symmetric pair comparisons, not reciprocal eligibility checks.

## 5. Current LOCAL AI Provider

`aiMatchProvider.localAiMatch` computes score=clamp(compatibility+round((coverage−50)×0.08)); confidence=clamp(0.8×coverage+20×highlightCount/3). Provider only executes LOCAL regardless of external environment switches. Its labels/reason switch mostly refer to obsolete factor names (intent, communication, values, etc.).

## 6. Current API Contract

Envelope: success/message/data; data.provider, recommendations, pagination. Recommendation fields: id, profile, compatibilityScore, compatibilityCoverage, aiMatchScore, aiConfidence, aiMatchLevel, aiHighlights, aiReasons. Preserve `aiConfidence`; do not introduce `aiConfidenceScore`. Internal factor detail should not enter public JSON. Flutter currently discards AI-specific fields, loads only the first page and re-sorts profiles by compatibility; this is an end-to-end consumption gap.

## 7. Current Dummy Dataset Results

Fresh `node scripts/report-dummy-seed.js --confirm-development-db`: 40 users, 39 completed, one incomplete, 26 eligible, 13 excluded. Distribution: <50=2, 50–59=7, 60–69=4, 70–79=8, 80–89=4, 90–100=1. Dhruv 92, Rhea 87, Kabir 62, Jay 53, Naina 48. Master: master@seed.amoraa.example.test. No password belongs in this report.

## 8. Problems Found

Controller injects `{score, coverage:100, factors:[]}`: all recommendations get confidence 80 and a platform-presence fallback. SQL score fallback `|| 85` converts legitimate zero or missing SQL scores to fake 85. Nullable SQL list numerators can propagate NULL. `requireCompleted` creates/marks incomplete viewer profiles complete during requests. AI pool truncates at 500, so ordering is not global beyond that count. AI route validates pagination only, unlike Discover filter validation. Flutter ignores AI evidence and pagination.

## 9. Match Engine Improvement Opportunities

Keep scoring weights/formula; propagate existing factors; add internal keyed breakdown and positive/neutral/negative partitions. Fix missing/malformed input handling and SQL/JavaScript parity using regression evidence.

## 10. AI Suggestion Improvement Opportunities

Generate truthful, candidate-specific reasons from actual shared factors; exclude private preference, moderation, safety and admin fields. Keep LOCAL the only executable provider.

## 11. Ranking Improvement Opportunities

Retain current score formula initially; use meaningful evidence confidence to resolve ties and stable numeric ID last. Remove silent eligible-set truncation. Measure complete-set memory cost and document scale limits.

## 12. Explanation Quality

Prioritize relationship goals, communication, interests, languages, then non-sensitive lifestyle alignment and city. Return up to three supported reasons; do not fabricate enough reasons to reach a quota for sparse profiles.

## 13. aiConfidence Quality

The provider formula is not literally a constant; its controller inputs make it effectively static. Retain its existing 80/20 evidence budget, replace UI highlight count with weighted supporting-factor strength. Document this as an evidence-support index, never probability or prediction of relationship success.

## 14. Cold-Start Behavior

No comparable fields: compatibility 50, coverage 0, confidence 0, no claimed shared traits. Incomplete onboarding must stay excluded; completed profiles with missing optional data may still qualify.

## 15. Sparse-Profile Behavior

Measure the intentionally incomplete seed profile directly without making it eligible or modifying its state. Add optional-field sparse fixtures for eligible API paths.

## 16. Diversity and Repetition

Measure city, interest and score concentration before deciding. No demographic penalty or randomized ordering is justified by current evidence. Stable repeated recommendations until data/actions change is expected.

## 17. Pagination Stability

Rank all eligible candidates before slicing. Verify pages 1–3, repeat requests, disjoint IDs, and a fixture larger than 500. Stability applies while candidate data and eligibility are unchanged; offset pagination cannot promise a snapshot during concurrent updates.

## 18. Privacy / Safety Constraints

Keep current eligibility authoritative. Use only allowlisted public shared factor values for explanations; never use bio, private preferences, messages or moderation data. Future external processing must never receive passwords, OTPs, tokens, KYC documents, private messages, payments, admin records, moderation evidence, raw records or exact private addresses.

## 19. Production Architecture Recommendation

Preserve Discover eligibility → Match Engine evidence → LOCAL ranking → global ordering → pagination → public serializer. Future external reranker/explainer must receive only privacy-minimized compatibility features, validate returned IDs against the eligible set, and fall back to LOCAL on errors. No external integration in this task.

## 20. Implementation Plan

1. Capture baseline and complete source audit (in progress).
2. Repair factor propagation, safe evidence reasons/confidence and identified eligibility/pagination defects without changing compatibility weights.
3. Verify Flutter consumption and preserve naming/backward compatibility.
4. Add focused formula, privacy, sparse, SQL parity, ranking and scale regressions.
5. Run focused and full backend suites; revalidate deterministic seed; populate metrics, ordered candidates, performance and readiness verdicts.

## 21. Before/After Metrics

Baseline captured above. After results pending implementation and actual execution; no success claim yet.

## 22. Final Recommendation

Pending validation. LOCAL deterministic recommendations are not external model-backed AI. Do not certify until regression, eligibility, global pagination, meaningful confidence and factual reasons are verified.
