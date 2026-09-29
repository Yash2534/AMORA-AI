# AMORAA MATCH ENGINE — FINAL CERTIFICATION

Certification date: 2026-09-29  
Contract version: `v2`  
Ranking/cursor version: `v2:cursor-1`  
AI provider: `LOCAL`

## 1. Certified architecture

Normal Discover is `GET /api/discover/feed` → authentication and active-account validation → canonical current viewer completion → saved preferences plus validated request overrides → shared SQL candidate eligibility → canonical SQL compatibility/minimum score → deterministic surface ranking → signed keyset pagination → `serializePublicProfile` → Flutter cursor consumption.

AI Matches is `GET /api/discover/ai-matches` → the same authentication, completion, preferences, candidate eligibility, reciprocal rules, distance rules, hard filters, and canonical compatibility query → deterministic LOCAL reranking over the complete eligible set → AI keyset pagination → the same public profile serializer → Flutter cursor consumption. The provider receives candidate user ID plus canonical structured compatibility evidence; it never receives profile objects, coordinates, credentials, messages, payments, KYC, or moderation cases.

There is no alternate eligibility path and no external model path. `Backend/src/services/matchEngineContract.js` is the single technical version source. `Backend/src/services/discoverEligibilityPolicy.js`, `Backend/src/services/compatibilityScoringService.js`, and `Backend/src/services/recommendationCursorService.js` are the respective canonical policy, scoring, and pagination implementations.

## 2. Eligibility and lifecycle

A recommendation excludes the authenticated viewer; any candidate whose `User.accountStatus` is not `active`; any candidate failing current canonical completion; either-direction blocks; either-orientation existing Matches; and viewer-created `pass`, `like`, or `superLike` DiscoverActions. Deactivated and deleted accounts cannot authenticate normally and cannot appear. Reactivation preserves the same user/profile identity and restores eligibility only when the current profile and preferences pass every rule.

Canonical recommendation completion requires a valid adult DOB, supported gender, at least one usable `interestedIn` value, at least one usable relationship goal, a nonblank city, at least two usable photos, `onboardingCompleted=true`, and `stage='complete'`. The optional 100% profile-richness score is not recommendation eligibility. SQL and JavaScript use the same completion definition, so stale flags cannot bypass removed required data.

Action policy is explicit:

- Pass, Like, Super Like, Match, and either-direction Block exclude.
- Rose does not independently exclude.
- Save does not exclude.
- Report alone does not automatically exclude or silently create a Block.
- Rewind removes the most recent DiscoverAction and can restore eligibility if no other rule excludes the candidate.

## 3. Filters and reciprocal eligibility

Server eligibility is authoritative. The canonical ranges are age 18–99, distance 1–300 km, height 137–213 cm, compatibility 0–100, and page size 1–30. Saved values and request overrides share normalization. Lists trim, compare case-insensitively, remove blanks and duplicates, and tolerate malformed legacy storage without throwing.

Viewer hard filters are age, maximum distance when location is available, minimum height, city, dating intentions, sexuality, education, profession, community, religion, smoking, drinking, weed, languages, pronouns, valued qualities, preferred talking hours, love languages, lifestyle tags, communication styles, prompts, verified-only, recent activity, registered-event interest, and minimum compatibility.

Reciprocity is deliberately limited to gender interest, age, and geographic distance. Candidate `DiscoverFilterPreference.minAge`, `maxAge`, and `maxDistanceKm` use runtime-aware canonical defaults when no row exists; recommendation reads never create preference rows. Profession, education, community, religion, languages, prompts, verification, activity, minimum score, and other ordinary viewer filters are not reversed.

Supported surfaces are standard/default (`recommended` internally), `high_compatibility`, and `near_you`. `similar_interests`, `new_here`, and `recently_active` ranking surfaces return controlled unsupported-surface errors rather than silent no-ops.

## 4. Location and privacy

Matching coordinates are `OnboardingProfile.matchLatitude`, `matchLongitude`, and server-owned `locationUpdatedAt`. Coordinates are supplied only by an explicit authenticated location action. There is no background tracking and no automatic expiry rule.

When the viewer has valid coordinates, the engine calculates one exact great-circle distance and requires it to be within both the viewer's and candidate's effective limits. Candidates without valid coordinates are excluded while geographic filtering is active. `near_you` requires viewer coordinates. Default Discover and AI Matches remain migration-safe when a legacy viewer has no coordinates and do not substitute city equality for GPS.

Exact coordinates, timestamps, candidate reciprocal limits, and raw location context never enter public recommendation JSON, AI evidence, logs, or cursor payloads. Public distance is rounded to whole kilometres. Private location/filter inputs participate in cursor binding only through a SHA-256 context fingerprint.

## 5. Compatibility

`Backend/src/services/compatibilityScoringService.js` is authoritative; `matchEngineService.js` is only a compatibility re-export. Factors and weights are Interests 35, Relationship Goals 25, Communication Style 10, Languages 10, City 5, Smoking 5, Drinking 5, and Weed 5, totalling 100.

Scalars trim/lowercase and treat blank, non-string, null, and `Prefer not to say` as unavailable. Lists are bounded, accept strings only, normalize identically, remove unavailable values and duplicates, and compare normalized intersections. Available list agreement is intersection size divided by the larger normalized list. Scalar agreement is exact normalized equality.

`availableWeight` is the sum of comparable weights and `weightedAgreement` is the sum of `weight × agreement`. No comparable data gives raw score 50, final score 50, and coverage 0. Otherwise:

`raw = 100 × weightedAgreement / availableWeight`  
`coverage = availableWeight / 100`  
`final = clamp(round(50 + (raw - 50) × coverage), 0, 100)`

The generated SQL and JavaScript implementations share factor metadata and are certified equivalent across clean data, every optional-factor subset, duplicates, whitespace, casing, declined answers, nulls, empty/malformed arrays, and non-string members. A deterministic 128-profile dirty matrix agrees for score and coverage. Known clean fixtures remain 92, 87, 62, 53, and 48.

## 6. Ranking and pagination

- Default Discover: compatibility score descending, numeric candidate user ID ascending.
- Near You: six-decimal internal distance ascending, compatibility score descending, numeric candidate user ID ascending.
- AI Matches: AI match score descending, AI confidence descending, numeric candidate user ID ascending.

No recommendation path uses random order, shuffle, or `ORDER BY RAND`. Recommendation `id` is always the candidate User ID, never a Match, conversation, action, or recommendation-event ID. Messaging still requires the actual Match/conversation contract.

All surfaces use signed opaque keyset cursors. Cursors are HMAC-SHA256 signed with the existing server secret, bounded to 2,048 characters, versioned, viewer-bound, surface-bound, ranking-bound, and bound to effective filters plus viewer/location context. They contain only technical version fields, a one-way context hash, and the last ranking tuple. Tampering, malformed values, cross-viewer/surface replay, changed filters/location, and obsolete versions fail with controlled errors.

Live keyset semantics prevent offset skips when earlier candidates are Passed, Liked, Super Liked, Matched, Blocked, or deactivated. They do not freeze later profile/score edits into a historical snapshot. Full walks certify exactly-once exhaustion for 100+ default, Near You, and AI candidates; final pages return `hasMore=false` and `nextCursor=null`.

## 7. LOCAL AI contract

The only executable provider is `LOCAL`; environment or client values cannot select an external provider. AI operates only after shared eligibility and canonical compatibility. It cannot restore excluded candidates.

`aiMatchScore`, `aiConfidence`, level, highlights, and reasons are deterministic. Confidence is an evidence coverage/support index, not a probability of matching, relationship success, or scientific certainty. Reasons use only available canonical factor evidence, are bounded to three highlights, and fall back truthfully to “Explore this profile to learn more about each other.” when no grounded reason exists.

A future external provider may only rerank already-eligible IDs and explain structured safe evidence. It must never decide eligibility or receive passwords, OTPs, tokens, exact GPS, KYC, private messages, payment information, private reciprocal limits, or moderation details.

## 8. Public API and error contract

Discover returns `profiles` and `pagination.{hasMore,nextCursor,limit,rankingVersion}`. Public profiles include candidate user ID, public profile content, age, city, rounded distance, compatibility score/coverage/reasons, verification, premium/public activity state, and no private account fields.

AI Matches returns `provider=LOCAL`, `recommendations`, location capability state, and the same pagination metadata. Each item adds `aiMatchScore`, `aiConfidence`, `aiMatchLevel`, `aiHighlights`, and `aiReasons`; nested profile IDs and wrapper IDs are the same canonical candidate User ID.

Controlled errors cover authentication, incomplete viewer, location required, unsupported surface, invalid filters, malformed/invalid/context-changed cursor, pagination without a cursor, and invalid candidate actions. Raw database, crypto, or stack details are not returned. Zero eligible candidates remains a true empty array; pagination exhaustion is not an error and API errors do not become empty states.

## 9. Recent activity and Flutter

Recent activity is derived from `User.lastActiveAt` using the configured bounded window, default five minutes. It is not socket presence. The public boolean is `recentlyActive`; the legacy `status` field is preserved safely.

Flutter preserves API result order, does not calculate compatibility or server eligibility, consumes opaque cursors, loads Discover and AI page 2+, deduplicates candidate IDs defensively, resets pagination when filters/location context change, and keeps continuation errors separate from loaded content. Local quick filters only hide already-eligible results and boundedly request later pages while `hasMore` is true. View Profile uses candidate User ID. Message uses the real conversation/Match flow. Empty, local-filter-empty, loading, load-more, and API-error states remain distinct.

Focused widget tests cover 320 px Discover, compact and desktop filters, AI pagination/order, location state, and load-more behavior without overflow.

## 10. Observability and secrecy

`matchEngineObservabilityService` emits only when `MATCH_ENGINE_OBSERVABILITY_ENABLED=true`. Its structured event uses bounded labels for surface, provider, duration bucket, error class, score buckets, and coverage buckets. It records counts before eligibility, after non-distance eligibility, after distance, and returned; continuation state; request duration; and LOCAL AI ranking duration.

Observability never logs user/candidate IDs, city, filters, cursor values/payloads, coordinates, sexuality, profile content, reciprocal limits, deletion reasons, credentials, KYC, messages, or payments. Unknown surface/provider/error values collapse to bounded safe labels. Candidate-stage measurements add a constant number of aggregate queries only while observability is explicitly enabled; default request query count is unchanged.

Legacy impression telemetry is separately opt-in and is not a metrics-label source. No user ID, candidate ID, city, score combination, cursor, or coordinate is used as a metrics label.

## 11. Query and performance certification

Local MariaDB test measurements are regression evidence, not production latency promises:

| Eligible pool | Default Discover | Near You | LOCAL AI |
|---:|---:|---:|---:|
| 100 | 564 ms / 10 queries | 626 ms / 10 queries | 509 ms / 10 queries |
| 500 | 1,962 ms / 10 queries | 1,964 ms / 11 queries | 2,129 ms / 10 queries |
| 1,000 | 3,773 ms / 11 queries | 3,669 ms / 10 queries | 3,760 ms / 11 queries |

The two-query variation is the bounded authentication `lastActiveAt` refresh that can occur once per 30-second window, not candidate-proportional work. Candidate preferences, coordinates, compatibility, reciprocity, and serialization introduce no N+1. Observed heap deltas are GC-sensitive; the largest positive delta in the focused run was approximately 28 MB for 1,000-candidate AI ranking.

Query plans confirm indexed profile/preference joins and bounded JSON sequence scans, with computed compatibility/distance ranking requiring temporary/filesort work. Phase 7 adds complementary `Matches(userTwoId,userOneId)` and `Blocks(blockedUserId,blockerUserId)` indexes for bidirectional exclusions. Existing actor-first DiscoverAction, unique preference user, profile user, and primary key indexes remain appropriate.

At larger scale, SQL compatibility normalization and Haversine/filesort CPU plus full eligible-set LOCAL AI materialization are the known costs. No persisted normalization, spatial infrastructure, bounding-box approximation, snapshot cache, or speculative index was added without production evidence. A privacy-safe latitude/longitude bounding prefilter and versioned AI ranking cache remain future measured optimizations.

## 12. Deterministic seed certification

The deterministic development blueprint remains 40 canonical users with unique emails/phones and stable server-generated IDs after persistence. It now assigns deterministic matching coordinates across six cities with at least 20 distinct coordinate pairs, keeps the canonical 1–300 km preference range, and persists server-style location timestamps. Factory tests prove repeated generation is identical.

The read-only report logic now uses canonical completion, gender reciprocity, reciprocal age, reciprocal distance, and canonical compatibility/LOCAL AI. The existing tracked report was not regenerated during certification because initializing the development database would auto-apply pending migrations; no production or development seed data was modified. Disposable integration fixtures independently certify location, distance, pagination, and the 100/500/1,000 candidate scale matrix.

## 13. Security audit

Recursive public-payload regression tests prohibit credentials, token versions, OTPs, exact match coordinates/timestamps, reciprocal ranges, deletion details, report state, and account internals. Searches found no random recommendation ordering, raw user-controlled SQL interpolation in recommendation construction, unsigned cursors, hardcoded fallback candidates, or external model SDK/endpoint path.

Target candidate IDs for actions are validated positive integers, self-actions and unavailable/blocked targets fail closed, and recommendation IDs are never treated as conversation IDs. Cursor signature and parsing errors are converted to controlled public codes.

## 14. Test evidence

Focused backend gates cover policy, completion, lifecycle, actions, blocks, report/Rose/Save policy, distance, Near You, reciprocity, compatibility, 128-profile SQL/JS equivalence, AI ranking, cursor security, live mutations, recursive secrecy, observability, seed determinism, query counts, query plans, 100/500/1,000 pools, and 100-profile Near You exhaustion.

Focused Flutter certification: 82/82 passed. The clean backend suite passed 311/311; the clean Flutter suite passed 627 with 14 skipped. Analysis remained at the accepted baseline of 0 errors, 38 warnings, and 5 infos. The debug APK attempt was blocked before application compilation by a host Windows/Java loopback failure under both Java 22 and Android Studio Java 21. No Android device was connected, so physical smoke was not tested. These environment results are classified separately in the Phase 7 completion report.

## 15. Deliberate limitations

- External model-backed AI is not implemented and is not required for current Match Engine completion.
- Recent activity is not realtime socket presence.
- There is no background GPS or automatic location expiry.
- `similar_interests`, `new_here`, and `recently_active` ranking surfaces are unsupported.
- Report alone does not auto-hide; Rose alone and Save do not exclude.
- Live keyset pagination does not freeze profile/score edits into a heavyweight historical snapshot.
- AI globally ranks the live eligible set in memory; production-scale caching is future measured work.
- Computed normalized compatibility and exact distance may require database filesort; spatial/persisted projections require production evidence before adoption.

## 16. Certification verdict

The Match Engine is complete for the current defined product scope: the canonical contracts, clean backend and Flutter suites, analyzer requirements, and Git integrity gate pass. The debug APK environment failure and unavailable physical device are reported separately and do not indicate an application or Match Engine failure. External AI and the deliberate limitations above are future enhancements, not missing current eligibility or recommendation behavior.
