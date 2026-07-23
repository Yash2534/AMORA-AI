# AMORA_AI 2027 brand color migration

## Scope and safety

- Approved workspace: `D:\Projects\amora_ai` only.
- Safety branch: `amora-ai-global-brand-theme-2027`.
- The independent `D:\Projects\amora` project was not inspected or changed.
- Product flows, route names, repositories, models, package identity, Android
  application ID, signing, API behavior, and dependencies were left unchanged.
- Existing theme filenames (`amora_theme.dart`, `amora_gradients.dart`, and the
  existing Amora token files) were retained to avoid a duplicate design system.

## Baseline

- `flutter pub get`: passed; four packages reported newer incompatible releases.
- `flutter analyze`: passed with `No issues found`.
- `flutter test --reporter compact`: all 22 baseline tests passed in 86.4 seconds.

## Audit result

The complete Dart source was searched for raw `Color(0x...)`, direct
`Colors.*`, color properties, gradients, and theme definitions.

- Feature-level raw `Color(0x...)` literals: **0**.
- Direct Material `Colors.*` usages: **0**.
- Centralized literal definitions after migration: **53 declarations / 46
  unique values**, all contained in `app_colors.dart`.
- Feature files consuming `AppColors`: **70** across **35 feature modules**.
- The main inconsistency was therefore not scattered literals; it was the old
  palette and legacy semantic aliases resolving to rose, purple, wine, and
  mustard values. Updating the central roles migrated every consuming module
  without screen-specific color forks.

## Replacement ledger

| Original value | Previous role / affected components | Replacement token | Reason and accessibility |
|---|---|---|---|
| `#E8306B` | Primary actions and active states | `AppColors.primary` = `#3D0B3F`; active uses `AppColors.active` | Restores Deep Plum hierarchy; white on Plum passes AA. |
| `#D62360` | Strong primary | `AppColors.primaryDark` = `#29072B` | Approved derived Plum state. |
| `#F75B91` | Rose secondary | `AppColors.secondary` = `#EC5FA8` | Approved Vibrant Pink accent. Pink uses Plum content for AA small-text contrast. |
| `#941A9F` | Purple tertiary, gradients, active controls | `AppColors.primary`, `secondary`, or `tertiary` by semantic role | Removes unapproved random purple and inconsistent active color. |
| `#FFF9FC` | Scaffold background | `AppColors.background` = `#FDF1F7` | Approved page background. |
| `#27172C` | Primary text | `AppColors.textPrimary` = `#2B2B2B` | Approved Charcoal body text. |
| `#351039` | Wine headings/icons | `AppColors.primary` = `#3D0B3F` | Consolidates important content under Deep Plum. |
| `#FDE8EF` | Selected and active containers | `AppColors.activeContainer` = `#FCE8F1` | Approved soft interaction surface. |
| `#F7E8FA` | Lavender containers | `AppColors.tertiarySoft` = `#FCE8F1` | Removes lavender cast and aligns soft accents. |
| `#6D6071` | Secondary text | `AppColors.textSecondary` = `#6E626D` | Approved neutral; AA on white. |
| `#918594` | Muted text and outlines | `AppColors.textMuted` = `#91858F` | Neutralized hue; reserved for metadata and non-body content. |
| `#C9BDC6` | Disabled text | `AppColors.textDisabled` = `#B7ABB4` | Clearer disabled hierarchy without implying interactivity. |
| `#EEDDE7` | Borders | `AppColors.border` = `#EADAE3` | Approved pink-grey border. |
| `#F2E8EE` | Dividers / raised containers | `AppColors.divider` / `surfaceContainerHighest` | Separates structure from elevation semantics. |
| `#F05261` | Error | `AppColors.error` = `#B32645` | Darkened derived error so white destructive-button content meets AA. |
| `#31C979` | Success | `AppColors.success` = `#247A59` | Darkened for readable white success content; remains semantically green. |
| `#E6A83A` | Warning | `AppColors.warning` = `#D9972F` | Preserves warning meaning; dark foreground is used instead of white. |
| `#5579D8` | Information / verification | `AppColors.info` = `#4561B0` | Retains semantic blue only for information; darkened for contrast. |
| `#E9A72E` | Premium labels | `AppColors.premium` = `#E1AA45` | Gold remains restricted to premium and verified experiences. |
| `#FFEDC6` | Premium containers | `AppColors.premiumContainer` = `#FFF4D8` | Approved restrained premium surface. |

## Semantic system

The six immutable brand colors are `primary`, `secondary`, `tertiary`,
`background`, `surface`, and `textPrimary`. Derived roles cover:

- primary/secondary light and dark states;
- text, surface, border, divider, and elevation levels;
- active, selected, hover, pressed, focus, and disabled states;
- success, warning, error, and info with matching containers/content colors;
- premium and overlay roles.

Compatibility aliases remain temporarily for older feature call sites, but all
now resolve to an approved semantic role. A regression test prevents new raw
feature colors or direct Material colors.

## Global component migration

- Material 3 `ColorScheme` now uses the approved foundation.
- App bars and scaffolds use the Light Pink background; surfaces remain white.
- Primary buttons use Deep Plum with white content. Secondary/tonal actions use
  Vibrant Pink with Deep Plum content for AA contrast. Outlined buttons use a
  Deep Plum border.
- Inputs use white surfaces, pink-grey borders, and a Vibrant Pink focus border.
- tabs, progress, selection controls, and navigation share Vibrant Pink active
  emphasis.
- cards, dialogs, bottom sheets, menus, dropdowns, search, tooltips, snackbars,
  switches, checkboxes, radio buttons, sliders, and chips inherit centralized
  theme roles.
- the shared floating navigation uses a white surface, pink active container,
  Vibrant Pink active label, and Deep Plum icon content.
- badge status colors remain semantic. Premium Gold is limited to premium roles.
- gradients are restrained to Plum-to-Pink primary, soft hero, Plum premium,
  premium-badge, and verified-badge contexts.

## Typography, spacing, radius, shadows, and motion

- The existing platform UI font is retained; no package or second typography
  system was added. Display/headline styles now default to Deep Plum, while body
  copy remains Charcoal.
- Named roles were added for screen title, section title, profile name,
  metadata, button label, and navigation label.
- Existing 4/8-point spacing and 48 dp minimum target were retained. Shared
  radii now use 8/12/16/20 dp, 24 dp hero corners, 28 dp sheet corners, and pill
  rounding; motion exposes 160 ms fast, 200 ms selection, 280 ms page, and
  380 ms reveal roles with reduced-motion-aware transitions.

## Accessibility and regression coverage

- Core foreground/background pairs are programmatically checked against WCAG AA.
- Active pink controls use Deep Plum content rather than inaccessible white
  small text.
- 48 dp controls, semantic labels, tooltips, text scaling, ellipsis/flexible
  layouts, and reduced-motion behavior remain in the shared primitives.
- The route smoke suite covers `320x568`, `360x800`, `375x812`, `390x844`,
  `412x915`, `430x932`, `600x960`, `768x1024`, and `1024x1366`.

## Verification record

- `dart format .`: passed; 134 files checked, 0 changed.
- `flutter clean`: passed.
- `flutter pub get`: passed; four newer incompatible package versions noted.
- `flutter analyze`: passed with `No issues found`.
- `flutter test --reporter compact`: all 27 tests passed in 89.3 seconds.
- `flutter run -d chrome --no-resident`: compiled, connected to Chrome's debug
  service, launched, and exited successfully.
- Android runtime: not run because `flutter devices` found no Android device and
  `flutter emulators` found no configured emulator.
- `flutter build apk --release`: passed; 77.0 MB release APK generated at
  `D:\Projects\amora_ai\build\app\outputs\flutter-apk\app-release.apk`.
