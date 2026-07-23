# AMORA_AI QA Frontend Fix Plan

Project: `D:\Projects\amora_ai`  
Source: `Amora_QA_Comparison_Report.docx` (19 issues: 5 critical, 2 high, 8 medium, 4 low)  
Safety branch: `amora-ai-qa-frontend-2027`

## Baseline

- Git: clean `main` at `604c18b` before branching.
- Flutter: 3.44.6 stable; Dart 3.12.2.
- `flutter pub get`: passed.
- `flutter analyze`: passed with `No issues found!`.
- `flutter test`: passed, 11 tests.
- Architecture: feature folders with named `MaterialApp` routes, local widget state/`ValueNotifier` session state, semantic theme tokens, and local dummy repositories. No external state-management package is installed.

## Final verification

- All 19 report items implemented on `amora-ai-qa-frontend-2027`.
- `dart format .`: passed, 133 Dart files checked with no changes required.
- `flutter analyze`: passed with `No issues found!`.
- `flutter test`: passed, 22 tests including all production routes at 320, 360, 375, 390, 412, 414, 768, and 1024 px.
- Chrome debug launch: passed with a successful debug-service connection.
- Android device run: not available because no Android device or emulator is installed.
- Release APK: built successfully at `build/app/outputs/flutter-apk/app-release.apk`.

The matrix below records the initial audit and planned implementation. Its status column is the pre-implementation checkpoint; the final verification above supersedes it.

## Issue matrix

| # | Screen | Severity | Current root cause | Files involved | Planned frontend fix | Reusable component / service | Test required | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Profile / Home | Critical | Edit Profile routes to the read-only profile-detail screen. Photo edits are screen-local and do not update the visible avatar or profile completion. | `main.dart`, `profile_screen.dart`, `profile_setup_screen.dart`, `photo_manager_screen.dart`, home/profile image widgets | Route Edit Profile to a real editable screen; persist draft fields/photos locally; update avatar and completion after save; preserve edits on cancel. | `LocalProfileRepository`, shared photo grid/slot widgets | Edit route, save, cancel, avatar/completion updates | In progress |
| 2 | Advanced Filters | Low | Reset is placed in a crowded title `Row`; compact button geometry can misalign icon/text at narrow widths and text scale. | `advanced_filters_screen.dart`, button widgets | Use a shared semantic text action with a 48dp target, tooltip, focus/pressed states, and responsive header wrapping. | `AmoraTextAction` | 320dp and 1.3 text scale alignment | Pending |
| 3 | Advanced Filters | Medium | Feature code overrides the theme with `activeThumbColor: primaryPurple`. | `advanced_filters_screen.dart`, `amora_theme.dart`, `app_colors.dart` | Centralize selected switch colors using active tokens and remove feature override. | shared switch theme | Active toggle color | Pending |
| 4 | Home / Discover | High | Trending rail assumes fixed 158x238 cards; compact content can overflow and final peeking is not derived from viewport width. | `amora_home_screen.dart`, `profile_card.dart` | Derive card width/height with `LayoutBuilder`, constrain flexible text, use stable keys/placeholders, and retain intentional next-card peek. | responsive rail helper | 320/360/390/430dp and text scale 1.3 | Pending |
| 5 | Discover | Critical | Pass only shows a snackbar, Like/Super Like only toggle sets, Rewind just pages backward, Boost claims activation, gestures and buttons do not share a guarded action state, and deck exhaustion is not modeled. | `browse_grid_screen.dart`, new discover controller/service | Add `DiscoverActionController`; unify buttons and gestures; animate pass/like/super-like; maintain stable-ID history and photo index; guard rapid taps; provide empty deck, rewind state, match demo, and Boost demo sheet without payment claims. | `DiscoverActionController`, local boost sheet | Pass, Like, Super Like, Rewind, Boost, empty deck, rapid taps | In progress |
| 6 | Discover | Medium | Selected filters use feature-specific primary/maroon rather than an explicit shared active token. | `amora_filter_chip.dart`, `app_colors.dart`, `amora_theme.dart` | Add active/activeContainer/onActive tokens and apply them to chips and theme. | shared filter/choice chip | Active chip color | Pending |
| 7 | Home header | Low | Shared avatar defaults to top-center alignment, causing face crop inconsistency even though `BoxFit.cover` is used. | `amora_profile_image.dart`, home avatar use | Use centered `BoxFit.cover`, semantic label, loading/error fallback for circular avatars. | shared `AmoraProfileImage` / avatar | Avatar fit and semantics | Pending |
| 8 | Discover card | Medium | Warning token is literal `#825500`; compatibility bars and Super Like use warning/premium gold for ordinary interaction/progress. | `app_colors.dart`, `browse_grid_screen.dart` | Remove `#825500`; use primary/purple for progress and active pink for Super Like; reserve premium gold for membership. | semantic palette | No `825500` usage | Pending |
| 9 | Events | Medium | Hero/page presentation applies nested fixed sizing/padding; image fill behavior is not asserted responsively. | `events_browse_screen.dart`, `events_widgets.dart`, `premium_editorial_panel.dart` | Ensure image panel fills its bounded card with centered cover, radius, and no internal horizontal gap; derive hero height from width. | shared image panel | Hero fill at compact and wide sizes | Pending |
| 10 | Featured Events | Critical | Horizontal cards live in a fixed 322dp rail and use fixed image heights; large text can consume the CTA area. | `events_browse_screen.dart`, `events_widgets.dart` | Separate image, flexible metadata, price/capacity, and CTA sections; calculate safe rail height for width/text scale; keep Book target >=48dp. | `EventCard` | Book visible/tappable at compact width and large text | In progress |
| 11 | Events recommendations | Medium | Ticket action relies on default filled-icon theme, which can become dark-on-dark across palette/theme changes. | `events_browse_screen.dart`, theme | Set explicit high-contrast foreground/background, tooltip and semantic label. | shared icon button style | Ticket contrast/tooltip | Pending |
| 12 | Profile prompts | High | Preview and Update only show snackbars; no playback/selection state exists. | `profile_screen.dart`, new local media service/widgets | Add keyboard-safe voice preview with deterministic playback progress/replay/missing state; add local video picker/preview/replace/cancel that preserves previous selection. | `LocalPromptMediaService`, prompt modal widgets | Voice preview controls; video update/cancel | In progress |
| 13 | Profile Studio | Critical | Every Open button only emits a snackbar and AI copy is embedded in the widget. | `profile_screen.dart`, new mock service/screen | Route/open a real deterministic preview sheet per tool; keep generated results in mock service; label all results as local previews. | `MockProfileStudioService`, result sheet | All five Open actions | In progress |
| 14 | Premium Membership | Medium | Existing CTA now has text but needs explicit readable states and route verification. | `profile_screen.dart`, button widget | Use `Manage Membership`, high-contrast outlined state, >=48dp height, and subscription route. | shared primary button | CTA label/route/large text | Pending |
| 15 | Safety & Privacy | Low | Safety Center uses a tight fixed-aspect grid while Trust metrics use another card structure; text/alignment diverge. | `safety_privacy_screen.dart`, `settings_support_widgets.dart` | Use one responsive `AmoraSafetyCard` geometry, adaptive columns, consistent icon width/padding/baselines, content-driven height. | `AmoraSafetyCard` | Compact width and text wrap | Pending |
| 16 | Safety & Privacy | Medium | Privacy toggle explicitly overrides active thumb with primaryPurple. | `settings_support_widgets.dart`, theme | Remove local override and use shared active switch theme. | shared toggle theme | Safety toggle active color | Pending |
| 17 | Profile Settings | Medium | `TrustPill` uses translucent accent plus dark text on a dark gradient; completion is hardcoded and the old warning token can leak into progress. | `profile_settings_screen.dart`, `settings_support_widgets.dart`, profile repository | Use opaque high-contrast badge containers, visible icons/text, shared completion state, and semantic active/premium tokens. | shared badge/progress components | Badge visibility and completion color/state | Pending |
| 18 | AI Assistant | Critical | Bottom sheet contains an unconstrained non-scrollable `Column` and fixed-width action tiles; compact heights overflow by 249px. | `floating_ai_assistant.dart`, bottom-sheet widget | Use `DraggableScrollableSheet` + controller-backed `ListView`, safe/keyboard padding, drag handle, adaptive two-column actions, focus handling, and semantic labels. | responsive modal sheet | Compact-height scroll and all actions reachable | In progress |
| 19 | AI Dating Coach | Low | Date carousel reserves 268dp while content occupies much less; cards have no content-driven rule. | `ai_dating_coach_screen.dart` | Reduce rail/card height to content-safe responsive size; keep tags adjacent to copy; no decorative dead CTA. | compact date-idea card | No excessive empty space / no overflow | Pending |

## Structural phase gate

Home/Profile/navigation/onboarding restructuring will start only after tests for all 19 report issues pass. The existing named-route architecture and local-state approach will be preserved. Backend-dependent features will remain clearly labeled local demos or previews and will not claim upload, payment, AI, verification, booking, message-delivery, or notification success.
