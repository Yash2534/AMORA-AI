# AMORA AI Enterprise Product Audit 2026

## Scope

Reviewed the Flutter application as a production relationship ecosystem across:

- Route registration and navigation ownership.
- Shared design system primitives.
- Core premium surfaces: auth, home, profile, AI assistant, roadmap modules.
- Component consistency for buttons, cards, loading, empty states, sheets, dialogs, and motion.
- Cleanup opportunities that can be performed without disturbing the current dirty worktree.

## Findings Remediated

- Removed duplicate `features/chats` proxy files. The active chat implementation lives in `features/chat`.
- Consolidated primary button press feedback onto the shared `PressableScale` motion primitive.
- Exported `premium_motion.dart` through the design system barrel.
- Reduced default `FadeUp` motion and auth intro motion to the 150-250 ms premium interaction range.
- Preserved existing routes and backend-facing behavior.

## Current Product Architecture

- `lib/core/theme` owns AMORA colors, spacing, typography, shadows, and app theme.
- `lib/core/widgets` owns reusable product components.
- `lib/features/*/presentation` owns feature screens.
- `lib/main.dart` remains the route composition root.
- Phase 2 and Phase 3 modules are centralized in `features/roadmap/presentation/phase23_premium_screens.dart` and registered as first-class routes.

## Enterprise Risks Still Visible

- Icon usage is not yet fully centralized. `AmoraIcons` exists, but many screens still use direct `Icons.*`.
- Several long ambient animations remain in splash, onboarding, discovery, chat, and verification screens. They should be reviewed individually before shortening, because some may be intentional screen-level reveal states.
- Typography references `Plus Jakarta Sans`, but the font asset/package is not present in `pubspec.yaml`. Add the font asset or an approved package before launch.
- Some generated/backup asset directories are present. They should be pruned only after visual QA confirms no screen depends on them.
- Route registration is explicit and test-covered, but a typed route registry would reduce future maintenance risk.

## Recommended Next Pass

1. Replace direct `Icons.*` usage with the `AmoraIcons` facade or an approved installed icon package.
2. Add real font assets for Plus Jakarta Sans or Manrope and declare them in `pubspec.yaml`.
3. Convert repeated premium dashboard cards into shared `AmoraMetricCard`, `AmoraInsightCard`, and `AmoraTimeline` widgets.
4. Run visual QA on small phone, large phone, tablet, and desktop web.
5. Prune unused assets after screenshot verification.

## Verification

This pass must remain green on:

- `flutter analyze`
- `flutter test`
