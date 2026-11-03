# Flutter Analyzer Triage — Phase 3

Command: `flutter analyze --no-pub`  
Date: 2026-10-09  
Exit code: 1  
Result: 44 findings (warnings/info), unchanged in count from Phase 2.

## Classification

| Class | Count | Findings | Security relevance | Action/status |
|---|---:|---|---|---|
| Security-relevant | 0 | None identified | No analyzer item concerns transport, token storage, credential logging, permissions, authorization, or cryptography | No Phase 3 security fix required |
| Functional | 4 | Dead/null-aware expression in `discover_action_controller.dart` (2); async `BuildContext` use in two event screens (2) | Functional correctness/lifecycle risk, not demonstrated security impact | Open product-engineering cleanup; not changed in this security-only phase |
| Deprecation | 0 | None | N/A | None |
| Style/info | 40 | Unused imports, fields, locals/elements/parameters; unnecessary import/underscores; prefer-final hint | No direct security impact | Retained to avoid unrelated broad refactoring |

## Finding inventory

- Functional: `lib/features/discover/presentation/discover_action_controller.dart:146` (`dead_code`, `dead_null_aware_expression`).
- Functional: `lib/features/events/presentation/event_detail_screen.dart:503` and `my_events_screen.dart:158` (`use_build_context_synchronously`).
- Style/info: 40 remaining analyzer findings across shared widgets, Discover, Home, Legal, Matches, Onboarding, Profile, and one test import. These are unused-code/import/parameter or style diagnostics.

Disposition: analyzer remains exit 1, but no finding was classified as security-relevant or as blocking the database security validation. The full Flutter test result from Phase 2 remains 658 passed, 14 skipped, 0 failed; it was not rerun in Phase 3 because this phase did not modify Flutter source.
