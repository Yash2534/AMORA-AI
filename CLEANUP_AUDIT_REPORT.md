# AMORA AI Complete Cleanup Audit

## Scope and rules

This was a read-only audit. No Dart file, asset, route, package declaration, or business logic was deleted or modified. Every candidate was checked against the SOW route inventory and feature-flow document before classification.

Inventory observed:

- 117 Dart files under `lib/`.
- 69 SOW production routes in `docs/AMORA_AI_Feature_Flow_Document.md` (including aliases and roadmap placeholders).
- 163 asset files under `assets/`.
- `flutter analyze`: passed with 0 issues.
- Existing route and responsive widget tests: previously verified green.

## KEEP

These are referenced by the SOW, route registry, shared architecture, or dynamic asset resolution and should not be removed.

### Screens and routes

- All 69 registered SOW routes in `lib/main.dart`, including `/discover` → Browse Grid, `/events` → Events Browse, `/ai-coach` → AI Dating Coach, and `/liked-you` → Liked You Paywall aliases.
- Roadmap screens (`/trusted-contacts`, `/stories`, `/liveness-check`, `/twenty-questions`, `/poll-prompts`, `/video-speed-dating`) because the SOW explicitly documents them as roadmap/placeholder routes.
- Admin and host dashboards because the SOW includes operational roles and workflows.
- Auth, KYC, safety, events, AI coach, monetization, wallet, referral, and support screens because each is explicitly present in the feature-flow document.

### Data and repositories

- `lib/core/data/image_repository.dart` — active source for profiles, events, venues, galleries, fallbacks, and deterministic demo data.
- `lib/core/constants/app_images.dart` — active dynamic asset resolver; gallery assets are constructed by `galleryForIndex`, so filename-only searches falsely classify them as unused.
- `lib/core/data/amora_image_data.dart` — referenced by admin/shared profile presentation.
- `lib/features/*/data/*_dummy_data.dart` and monetization data — KEEP for the current frontend-only/demo scope; these are not production repositories but are active UI fixtures.

### Shared design system

- `lib/core/theme/amora_theme.dart`, `app_colors.dart`, `amora_spacing.dart`, `amora_text_styles.dart`, `amora_shadows.dart`, `amora_icons.dart`.
- Shared widgets such as `PremiumCard`, `AppPrimaryButton`, `AppTextField`, `ResponsiveMobileFrame`, `FloatingBottomNav`, `PremiumAssetImage`, `PremiumAvatar`, `PremiumEditorialPanel`, `AmoraProfileImage`, and `PremiumMotion`.
- `lib/core/widgets/amora_design_system.dart` as a public barrel candidate: although no current screen imports the barrel directly, it exports the shared component surface and should be retained or deliberately adopted before removal.

### Assets

- All `profile_gallery` images are KEEP: `AppImages.galleryForIndex` builds their paths dynamically.
- Profile, event, date-spot, fallback, and launch assets referenced by `AppImages`, `ImageRepository`, or `AmoraImageData` are KEEP.
- Hash audit found no byte-identical duplicate assets.

### Tooling

- `flutter_lints` is KEEP because `analysis_options.yaml` includes it.
- Flutter Material/Cupertino SDK usage is KEEP. The project does not import the external `cupertino_icons` package directly.

## REMOVE candidates — no deletion performed

These are high-confidence candidates, but require an explicit cleanup change and a final `flutter pub get`/build check before removal.

| Candidate | Evidence | Confidence |
|---|---|---|
| `cupertino_icons: ^1.0.8` in `pubspec.yaml` | No `package:cupertino_icons/cupertino_icons.dart` import was found; icons use Flutter SDK Cupertino icons or `AmoraIcons`. | High |

No Dart screen, widget, model, repository, service, provider/BLoC/controller, extension, or utility file was marked safe for immediate deletion solely from static filename/reference evidence. The SOW intentionally includes roadmap placeholders and frontend-only demo fixtures.

## REFACTOR

### Dead navigation

- `lib/features/profile/presentation/profile_screen.dart:1521` pushes the literal route `/support`, but `lib/main.dart` registers `FaqSupportScreen.routeName` (`/faq-support`) and no `/support` route was found. This is a dead navigation target and should be changed to the named route constant in a separate fix.

### Duplicate/alias routes

- `/discover` and `/browse` intentionally share Browse Grid implementation — KEEP alias, but document one canonical route constant.
- `/events` and the `EventsScreen` alias intentionally share Events Browse implementation — KEEP alias.
- `/ai-coach` and `AiCoachScreen` alias intentionally share AI Dating Coach implementation — KEEP alias.
- `/liked-you` and `/liked-you-paywall` intentionally share the paywall implementation — KEEP alias.

### Duplicate components

- `lib/core/widgets/amora_app_bar.dart`, `amora_badge.dart`, `amora_empty_state.dart`, `amora_filter_chip.dart`, `amora_loading.dart`, and `amora_search_bar.dart` coexist with many screen-local headers, badges, loading states, filters, and search bars. They are not proven unused; consolidate adopters into the shared components before considering removal.
- `lib/core/widgets/profile_card.dart` is active in Home, while Discover uses `_DiscoverProfileCard`; refactor toward one profile-card contract rather than deleting either.
- `AppPrimaryButton` coexists with approximately 93 direct `FilledButton`/`OutlinedButton`/`TextButton` usages. Audit and migrate only where behavior and semantics are equivalent.
- `PremiumCard` coexists with direct `Card`/custom `DecoratedBox` surfaces (approximately 427 card references). Consolidation should be incremental and screenshot-tested.

### Duplicate tokens

- `AppColors` contains numerous compatibility aliases (`primaryPurple`, `deepWine`, `primaryRose`, `roseRed`, `textDark`, `grey`, etc.) pointing to the same underlying colors. Keep aliases until callers migrate; then collapse to canonical tokens.
- `AmoraTextStyles` is centralized, but many feature files still declare direct `fontSize`/`fontWeight` values. Migrate by semantic role, not mechanical replacement.
- Spacing is tokenized in `AmoraSpacing`, but feature files still contain many bespoke `SizedBox`, `EdgeInsets`, and padding literals. Refactor screen-by-screen with visual regression coverage.
- `AmoraIcons` exists, but direct Material `Icons.*` usage remains widespread. Migrate only after confirming icon semantics and accessibility labels.

### Theme and visual architecture

- `AmoraGradients` is active through `image_fallback.dart`; do not remove it.
- `AmoraTheme` is active from `main.dart`; no unused theme file was identified.
- Add the declared Plus Jakarta Sans font asset/package before production; the theme references the family but `pubspec.yaml` does not declare the font.

### Debug/demo/placeholder code

- `_demoRole = 'admin'` and `_demoRole = 'host'` are intentional demo gates in admin/host screens; keep for frontend-only scope, refactor behind an environment/session capability before release.
- Placeholder copy and simulated flows are widespread in chat media/calls, payment, KYC, photo management, data export, notifications, map integration, events, support, and SOS. These belong to SOW future/backend scope; replace integrations, not delete screens.
- No `TODO`, `FIXME`, `HACK`, `debugPrint`, `print()`, `printStackTrace`, or commented-out executable code was found. The eight `//` lines found are explanatory comments or a lint suppression.

## Unused/duplicate asset conclusion

A direct filename reference scan reports most `profile_gallery` files as unreferenced, but this is a false positive because `AppImages.galleryForIndex` constructs paths dynamically. A byte hash comparison found no duplicate files. Do not remove gallery or fallback assets without runtime gallery screenshot verification.

## Final recommendations

1. Remove only `cupertino_icons` after confirming `flutter pub get` and a release build.
2. Fix the `/support` dead navigation target.
3. Migrate direct buttons/cards/icons/colors/styles to shared primitives incrementally.
4. Add the font asset/package and verify typography on physical devices.
5. Keep all SOW roadmap routes and demo fixtures until backend replacement work is explicitly approved.

## Classification summary

- **KEEP:** all SOW routes, roadmap placeholders, active repositories/fixtures, dynamic assets, shared design system, active aliases, and tooling.
- **REMOVE candidate:** one high-confidence package (`cupertino_icons`); nothing was deleted.
- **REFACTOR:** one dead navigation target, alias documentation, duplicate component families, compatibility token aliases, direct icon/button/card usage, demo gates, and placeholder integrations.
