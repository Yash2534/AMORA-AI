# AMORAA Phase S1 Baseline Evidence

Recorded: 2026-10-12 (Asia/Calcutta)

This record was created before Phase S1 runtime or application code changes. No production system was contacted and no load test was run.

## Backend full test suite

Command: `cd Backend && npm test`

- Initial sandboxed run: **119 passed, 249 failed, 368 total** in 67.5 seconds. Every observed integration failure was a test-hook failure caused by the sandbox denying the local MySQL connection (`connect EACCES 127.0.0.1:3306`), not an application assertion failure.
- Authorized local-development rerun with access to the disposable MySQL test schemas: **356 passed, 0 failed** in 207.0 seconds.
- The different discovered-test count reflects database/migration-dependent test discovery state between the denied and connected runs; the connected full-suite result is the functional baseline.

## Flutter test suite

Command: `flutter test`

- **659 passed, 0 failed, 14 skipped** in approximately 2 minutes 55 seconds.
- The 14 skips are the repository's opt-in QA evidence-capture cases, which require `AMORA_CAPTURE_QA_EVIDENCE=1` and golden regeneration.

## Flutter static analysis

Command: `flutter analyze`

- Exit status: **1**.
- Existing findings: **44 issues** (warnings and informational lints), with no compilation error reported.
- Representative pre-existing findings include unused imports/elements, dead code, unnecessary imports/underscores, and two `use_build_context_synchronously` informational findings.
- Phase S1 will not misrepresent these existing analyzer findings as introduced regressions.

## Scalability-specific coverage already present

The repository contained 169 backend and Flutter test files in total. Existing scalability-relevant backend coverage includes:

- AI recommendation deterministic ranking, cursor integrity, exclusion rules, and constant bulk-query counts.
- Exact 25/50/100 candidate pool query-count measurements.
- A 500+ candidate global-ranking regression test, demonstrating the current unbounded behavior that S1 must replace.
- 100/500/1,000 candidate Discover, Near You, and AI performance evidence with bounded query counts (not production capacity evidence).
- Stable keyset pagination for discovery, Near You, messages, and relationship lists.
- Realtime authorization/fanout integration tests.
- Upload signature/authorization tests and bounded privacy export artifact tests.

## Baseline interpretation

The connected backend and Flutter test suites are green. Static analysis is not clean at baseline. Performance observations from repository tests are local development evidence only and do not establish production throughput, concurrency, or capacity.
