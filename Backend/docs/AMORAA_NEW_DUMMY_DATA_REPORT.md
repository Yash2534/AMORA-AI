# AMORAA NEW DUMMY DATA + MATCH ENGINE + AI MATCH REPORT

Generated from the local `amora_ai` development database on 2026-09-22. No production system or external delivery/payment/push provider was used.

## MASTER AMORAA TEST LOGIN

- Email: `master@seed.amoraa.example.test`
- Password: `Amoraa-Dev-Only-2026!`
- Development OTP: `111111` (enabled only by the current guarded development configuration; normal OTP challenge creation and verification are still required)
- Profile name: Aisha Mehta
- Age: 27
- Profile completion: 100%
- Account: ACTIVE
- Onboarding: COMPLETE
- Legal consent: VALID current Terms + Privacy (two append-only consent events)
- Discover ready: YES
- AI Matches ready: YES — deterministic LOCAL provider
- Likes / Super Like / Saved Profile / Rose ready: YES
- Reciprocal Match trigger ready: YES — Neel Vyas has liked MASTER; no Match exists until MASTER uses the normal Like flow
- Existing Matches: 7
- Conversations: 7
- Unread conversations: 1
- Notifications: 3
- Premium test state: active `AMORAA Platinum Monthly`
- Verification test state: verified

## DATASET

- Old controlled dummy namespace replaced: YES
- New dummy users: 40
- Complete profiles: 39
- Intentionally incomplete profiles: 1
- Profile images: 80 (two per profile)
- Image verification: PASS — 80/80 served with HTTP 200, 80 unique SHA-256 hashes
- Age-appropriate images: PASS by curated generation metadata and visual assignment
- Verified profiles: 6
- Premium profiles: 4
- Legal consent events: 80
- Seed fingerprint: `e41af6baa509`
- Idempotent reseeding: PASS

The dataset uses only the deterministic `@seed.amoraa.example.test` namespace. Reset refuses production, requires an explicit database allowlist and command confirmation, and deletes only that namespace plus media prefixed `amoraa-v2-profile-` and the seeded chat image.

## DISCOVER

- Eligible profiles for MASTER: 26
- Excluded: 13
- Pagination: PASS — 3 pages at limit 10; pages 1 and 2 verified through HTTP
- Hardcoded fallback profiles: NONE in the backend seed/API path
- Exclusion reasons: previous action 8; block 1; reciprocal-preference mismatch 1; age mismatch 1; incomplete profile 1; inactive account 1
- Existing-match profiles are represented by the previous-action group because the normal reciprocal actions backing those matches exclude them first.

## MATCH ENGINE

- Scoring changed: NO
- Coverage: 100% for all 26 eligible MASTER candidates
- Calculated range: 48%–92%
- Under 50%: 2
- 50–59%: 7
- 60–69%: 4
- 70–79%: 8
- 80–89%: 4
- 90–100%: 1
- Minimum / median / average / maximum: 48 / 66 / 67.54 / 92
- Reciprocal preference enforcement: PASS
- Eligibility enforcement: PASS
- Stable pagination/ranking: PASS through API verifier and 216-test backend suite

Actual examples:

- Dhruv Shah → 92%: 7 shared interests, same relationship goal, compatible communication, shared language, same city, similar smoking preference.
- Kabir Menon → 62%: 4 shared interests, same relationship goal, compatible communication, shared language, same city, similar smoking preference.
- Jay Shah → 53%: 2 shared interests, same relationship goal, compatible communication, shared language, same city, similar smoking preference.
- Naina Rao → 48%: 2 shared interests, same relationship goal, compatible communication, shared language, similar smoking and weed preferences; the city difference accounts for part of the lower result.

## AI MATCHES

- Provider: LOCAL deterministic provider, not external/model-backed AI
- Candidates entering ranking: 26
- Returned across all pages: 26
- Pagination: PASS — 3 pages at limit 10; pages 1 and 2 verified through HTTP
- Eligibility: PASS; the candidate set is the same restricted database pool used by Discover
- Top order: Dhruv Shah (92 compatibility / 96 AI score), followed by Rhea Patel, Mira Joshi, Siddharth Soni and Diya Trivedi (87 / 91)
- `aiConfidence`: present, but currently 80 for every seeded recommendation
- Current AI reason: generic `Potential match based on shared platform presence.` for every recommendation

The ranking is meaningful primarily because the LOCAL provider preserves Match Engine order and adds the same effective adjustment to each profile. It does not currently add meaningful differentiation beyond Match Engine compatibility.

## OTHER DATA

- Likes: 22
- Super Likes: 3
- Saved profiles: 1
- Roses: 2
- Matches: 7
- Conversations: 7
- Messages: 89
- Image messages: 1
- Structured Rose messages: 1 with a valid `roseTransactionId`
- Notifications: 3
- Blocks: 1
- Reports: 1

Chat fixtures around MASTER include no-message, short, long (55 messages), unread, read, structured Rose, and image-message conversations. Every conversation is backed by a real Match and reciprocal positive Discover actions.

## NEW ACCOUNT END-TO-END TEST

The guarded HTTP verifier created three temporary accounts through the real signup and OTP endpoints, fetched and accepted the current legal documents, completed every onboarding endpoint, uploaded photos, updated discovery preferences, loaded Discover and LOCAL AI Matches, created a reciprocal Match through Likes, opened chat, sent messages and a Rose, logged out, restarted the backend, and verified persistence. It then removed only its temporary `full-flow-*` accounts.

- Create Account: PASS — API + automated verifier
- OTP: PASS — real development challenge with delivery skipped; no bypass added
- Legal consent: PASS
- Onboarding / complete profile: PASS
- Discover: PASS
- LOCAL AI Matches: PASS
- Reciprocal Match and chat: PASS
- Physical-phone execution: NOT VERIFIED

## MASTER ACCOUNT TEST COVERAGE

Status meanings: `API VERIFIED` means a real local HTTP request and persisted database state were checked; `AUTOMATED TEST VERIFIED` means an automated suite also covers the behavior; `DATA READY` means the seed supports manual execution; `MANUAL PHONE VERIFIED` is intentionally not claimed.

- Login / logout / login persistence: API VERIFIED + AUTOMATED TEST VERIFIED
- Profile / edit: API VERIFIED + AUTOMATED TEST VERIFIED
- Discover / pagination / filters / profile detail: API VERIFIED + AUTOMATED TEST VERIFIED
- Like / Super Like / Save / Unsave / Rose: API VERIFIED + AUTOMATED TEST VERIFIED
- AI Matches / pagination: API VERIFIED + AUTOMATED TEST VERIFIED
- AI multi-select / Like Selected: DATA READY; NOT VERIFIED as a physical UI interaction
- Reciprocal Match creation: API VERIFIED through the normal Like business logic
- Matches / conversation / text / image / Rose-in-chat: API VERIFIED + AUTOMATED TEST VERIFIED
- Incoming unread / mark read / notifications: API VERIFIED + AUTOMATED TEST VERIFIED
- Mute / unmute: API VERIFIED + AUTOMATED TEST VERIFIED
- Block / unblock / report: API VERIFIED + AUTOMATED TEST VERIFIED
- Settings and physical UI navigation: DATA READY; MANUAL PHONE NOT VERIFIED

## MATCH ENGINE IMPROVEMENT REPORT

### Recommendation 1 — Low-band calibration visibility

- Issue: two realistic, complete candidates score 48%, just below the requested 50% target.
- Current behavior: city and limited interest overlap legitimately reduce otherwise aligned profiles.
- Evidence: Naina Rao and Tara Menon each score 48% with full field coverage.
- Suggested improvement: add distribution monitoring and product-level labeling research before changing weights.
- Expected benefit: clearer interpretation of low-but-plausible recommendations.
- Risk: changing weights solely to hit bins would distort the authoritative engine.
- Priority: MEDIUM; analysis only.

### Recommendation 2 — Explanation completeness

- Issue: negative/mismatched factors are omitted from explanations.
- Current behavior: reasons list only positive overlap, so a 48% result can sound stronger than it is.
- Evidence: the 48% candidate explanation lists six positives but does not say that city/drinking/interests reduced the score.
- Suggested improvement: expose a bounded “differences considered” section from existing factors.
- Expected benefit: more trustworthy, comprehensible scores.
- Risk: explanations may feel overly judgmental without careful copy.
- Priority: HIGH.

### Recommendation 3 — Diversity-aware ties

- Issue: repeated score bands create large ties (eight profiles at 70–79%).
- Current behavior: ties fall back to user ID.
- Evidence: deterministic seeded ranking contains several identical scores.
- Suggested improvement: research a stable, transparent diversity tie-breaker after compatibility, without weakening eligibility.
- Expected benefit: more varied pages and fewer near-duplicate recommendation sequences.
- Risk: unstable ordering can harm pagination unless a persisted cursor/tie key is used.
- Priority: MEDIUM.

## AI SUGGESTION IMPROVEMENT REPORT

### Recommendation 1 — Preserve Match Engine factors at the provider boundary

- Issue: the AI controller passes `{ score, coverage: 100, factors: [] }` to the LOCAL provider.
- Current behavior: all 26 recommendations receive confidence 80 and the same generic reason.
- Evidence: Dhruv at 92%, Kabir at 62%, and Naina at 48% all have identical AI confidence and explanation copy.
- Suggested improvement: pass the already-calculated Match Engine factors/coverage to the LOCAL provider and add contract tests.
- Expected benefit: differentiated, evidence-based reasons and confidence without an external model.
- Risk: response text/order may change; mobile snapshots and pagination assertions need review.
- Priority: HIGH.

### Recommendation 2 — Make ranking contribution observable

- Issue: LOCAL AI score currently behaves like compatibility plus a nearly constant adjustment in this dataset.
- Current behavior: AI ranking duplicates Match Engine ranking.
- Evidence: 92→96, 87→91, 62→66, 53→57, 48→52; confidence is always 80.
- Suggested improvement: instrument provider component scores before changing the algorithm.
- Expected benefit: proves whether the provider adds meaningful ranking value.
- Risk: logging must avoid sensitive profile content.
- Priority: HIGH.

### Recommendation 3 — Cursor-stable ranking if diversification is added

- Issue: future dynamic AI tie-breaking could repeat or skip profiles between offset pages.
- Current behavior: current deterministic ordering is stable and passes pagination.
- Evidence: three pages are available and repeated calls preserve the order.
- Suggested improvement: keep a deterministic final tie key or move to an opaque cursor before adding stochastic diversity.
- Expected benefit: stable multi-page recommendations.
- Risk: API contract migration.
- Priority: MEDIUM.

## IMAGE REPORT

Every profile owns two 800×1000 WebP images. Images are synthetic/generated local development assets, assigned using age and gender/presentation metadata, copied into the existing uploads architecture, and never fetched at app runtime.

Important mappings:

- Aisha Mehta, 27, Female: `amoraa-v2-profile-001-01.webp` (primary), `amoraa-v2-profile-001-02.webp` (secondary), age appropriate YES.
- Arjun Desai, 28, Male: `002-01` primary, `002-02` secondary, YES.
- Rohan Shah, 29, Male: `003-01` primary, `003-02` secondary, YES.
- Kabir Menon, 30, Male: `004-01` primary, `004-02` secondary, YES.
- Dev Nair, 26, Male: `005-01` primary, `005-02` secondary, YES.
- Ishaan Patel, 31, Male: `006-01` primary, `006-02` secondary, YES.
- Neel Vyas, 28, Male: `007-01` primary, `007-02` secondary, YES.
- Veer Kapoor, 30, Male: `008-01` primary, `008-02` secondary, YES.
- Mihir Joshi, 27, Male: `009-01` primary, `009-02` secondary, YES.
- Samir Khan through Dhruv Shah (Candidates I–T): profiles `010` through `021`, each with `-01` primary and `-02` secondary, age appropriate YES.

The complete 40-profile mapping, absolute local paths, ages, presentation metadata, media order and verification results are in `Backend/tmp/demo-profile-image-verification.json`. The calculated data/AI/image report is in `Backend/tmp/amoraa-v2-seed-report.json`.

## BACKEND REGRESSION AND SAFETY

- Backend tests: 216/216 PASS
- Seed validation: PASS
- Seed HTTP verification: PASS
- MASTER destructive-flow verifier: PASS, followed by pristine reseed
- New-account verifier: PASS, followed by isolated cleanup
- Flutter suite: 497 passed, 51 failed, 14 skipped; failures are existing/stale UI expectation and layout issues outside this data task, so they were not modified or reported as PASS
- Production data changed: NO
- Runtime external SMS/email/payment/push providers called: NONE
- Backend architecture changed: NO; seed, verification and reporting only
- Match Engine scoring changed: NO
- AI algorithm changed: NO
- Commit / push / merge / deployment: NONE
