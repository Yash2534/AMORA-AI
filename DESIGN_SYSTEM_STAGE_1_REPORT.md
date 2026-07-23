# AMORA AI — Stage 1 Design System Foundation Report

Date: 14 July 2026

Target: 2027 production UI foundation

Scope: Shared tokens, global Material 3 theming, and reusable UI primitives only

## 1. Design Tokens Created

- One semantic `ColorScheme` source with 52 canonical base roles and compatibility aliases.
- Complete Material 3 typography scale with 15 canonical roles plus product aliases.
- Four-point sub-grid constrained to the 8-point layout rhythm: 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, and 64.
- Semantic control sizes for 48 dp touch targets, 56 dp standard controls, app bars, navigation, and state illustrations.
- Semantic radius roles: none, small, medium, large, extra-large, and full.
- Elevation roles: level 0–3, floating, dialog, bottom sheet, and premium card.
- Icon-size roles: small, medium, standard, large, and extra-large.
- Motion roles for fast, standard, slow, emphasized, and skeleton animation.

## 2. Color System Improvements

- Replaced the earlier brand-color collection with Material 3 roles for primary, secondary, tertiary, containers, surfaces, content, outlines, and scrims.
- Added semantic success, warning, info, error, online, offline, unread, premium, card, input, chip, divider, border, and disabled roles.
- Centralized all literal color values in `app_colors.dart`; no raw color literals remain elsewhere in `lib`.
- Retained legacy color names as references to canonical roles so existing workflows remain visually and functionally stable during Stage 2 migration.
- Reduced shared gradients to restrained tonal transitions or solid brand treatments.

## 3. Typography Improvements

- Added the full Material 3 hierarchy: display large/medium/small, headline large/medium/small, title large/medium/small, body large/medium/small, and label large/medium/small.
- Added explicit product roles for buttons, navigation, captions, dialogs, and bottom sheets.
- Standardized line height, weight, and letter spacing.
- Removed reliance on an undeclared custom font and now uses the accessible platform UI font.

## 4. Spacing Improvements

- Established one 4/8-point token scale and semantic screen, card, field, button, dialog, and bottom-sheet insets.
- Added shared component dimensions and navigation content insets.
- Preserved old spacing symbols as aliases to support incremental screen migration without layout changes.

## 5. Radius Improvements

- Added semantic radius tokens and reusable `BorderRadius` constants for cards, inputs, buttons, dialogs, sheets, and pills.
- Shared components now consume radius tokens instead of defining new shapes locally.

## 6. Shadow Improvements

- Replaced soft/medium/glow-only shadows with purpose-driven elevation levels.
- Added dedicated floating, dialog, bottom-sheet, and premium-card elevation.
- Shadows use one semantic shadow color and restrained opacity.

## 7. Button Improvements

- Standardized contained, tonal, outlined, text, destructive, and dark variants.
- Added compact and standard sizes, full-width behavior, loading state, disabled state, icon alignment, semantics, and animated state changes.
- Global Material themes now define pressed, focused, hovered, and disabled treatment.
- Standardized icon buttons and FABs with accessible targets.

## 8. Card Improvements

- Added `AmoraCard` with standard, profile, premium, statistic, info, settings, event, wallet, and revenue variants.
- Standardized padding, border, radius, elevation, clipping, interaction, and semantic labeling.
- Updated premium cards and banners to use the shared token system.

## 9. Input Improvements

- Standardized filled fields, labels, hints, helper/error copy, focus/error/disabled borders, and icon colors globally.
- Expanded the reusable text field API for enabled state, actions, callbacks, suffixes, and autofill.
- Added shared password, OTP, and generic dropdown fields.
- Standardized checkbox, radio, switch, slider, chip, and filter-chip states through Material themes.

## 10. Navigation Improvements

- Standardized Material 3 navigation bar and rail colors, indicators, typography, icon sizes, height, and selected state.
- Updated the existing floating navigation wrapper to shared spacing, icon, type, radius, shadow, and motion tokens without changing routes or replacement behavior.

## 11. Dialog Improvements

- Standardized inset, 24 dp radius, padding, typography, elevation, action spacing, scrim, and transition timing.
- Existing dialog APIs and callbacks remain unchanged.

## 12. Bottom Sheet Improvements

- Standardized top radius, handle, padding, elevation, border, safe-area behavior, and transition timing.
- Prevented duplicate framework/custom handles while preserving the existing sheet API.

## 13. Loading Components

- Standardized compact and regular circular loading indicators.
- Added accessible linear loading with progress semantics.
- Added animated base, card, profile, list, and grid skeleton components.

## 14. Empty State Components

- Standardized icon/illustration area, title, message, optional CTA, spacing, and semantic accent color.
- Supports either a supplied illustration or the shared icon treatment.

## 15. Error Components

- Added `AmoraErrorState` with semantic error color, configurable message, and optional retry action.

## 16. Avatar Improvements

- Added small, medium, large, and XL avatar roles.
- Standardized online indicator, verified badge, premium ring, fallback image, and accessibility label.
- Retained the legacy radius parameter for compatibility.

## 17. Badge Improvements

- Standardized primary, secondary, success, warning, error, and neutral tones.
- Added notification, premium, online, status, and unread constructors.
- Unified pill shape, border, padding, typography, and icon size.

## 18. Accessibility Improvements

- Enforced 48 dp minimum interactive targets at the theme level.
- Added semantic labels and state announcements to buttons, avatars, loaders, cards, OTP entry, and feedback components.
- Uses scalable Material text roles and platform fonts.
- Added high-contrast on-color roles for brand and feedback surfaces.
- Motion respects the platform disable-animations preference for route transitions.
- Responsive route QA covers widths from 320 through 1024 px.

## 19. Files Modified

### Theme and tokens

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/amora_theme.dart`
- `lib/core/theme/amora_text_styles.dart`
- `lib/core/theme/amora_spacing.dart`
- `lib/core/theme/amora_shadows.dart`
- `lib/core/theme/amora_gradients.dart`
- `lib/core/theme/amora_icons.dart`
- `lib/core/theme/amora_icon_sizes.dart` (new)

### Shared components

- `lib/core/widgets/amora_design_system.dart`
- `lib/core/widgets/app_primary_button.dart`
- `lib/core/widgets/app_text_field.dart`
- `lib/core/widgets/amora_inputs.dart` (new)
- `lib/core/widgets/amora_card.dart` (new)
- `lib/core/widgets/premium_card.dart`
- `lib/core/widgets/premium_banner_card.dart`
- `lib/core/widgets/premium_editorial_panel.dart`
- `lib/core/widgets/premium_image_card.dart`
- `lib/core/widgets/profile_card.dart`
- `lib/core/widgets/amora_app_bar.dart`
- `lib/core/widgets/floating_bottom_nav.dart`
- `lib/core/widgets/floating_ai_assistant.dart`
- `lib/core/widgets/amora_dialog.dart`
- `lib/core/widgets/amora_bottom_sheet.dart`
- `lib/core/widgets/amora_snackbar.dart` (new)
- `lib/core/widgets/amora_loading.dart`
- `lib/core/widgets/amora_empty_state.dart`
- `lib/core/widgets/amora_error_state.dart` (new)
- `lib/core/widgets/premium_avatar.dart`
- `lib/core/widgets/amora_badge.dart`
- `lib/core/widgets/amora_search_bar.dart`
- `lib/core/widgets/amora_filter_chip.dart`
- `lib/core/widgets/intent_chip.dart`
- `lib/core/widgets/lifestyle_chip.dart`
- `lib/core/widgets/image_fallback.dart`
- `lib/core/widgets/progress_header.dart`
- `lib/core/widgets/section_header.dart`
- `lib/core/widgets/premium_motion.dart`

### Verification

- `test/design_system_test.dart` (new)

## 20. Remaining Design Work

Stage 1 is ready for consumption. Stage 2 should migrate each screen's local `TextStyle`, `EdgeInsets`, `SizedBox`, radius, shadow, and one-off card/button declarations to these shared roles as part of screen-by-screen visual upgrades. That work is intentionally not performed here because it changes screen composition and belongs to the explicitly excluded redesign stage.

No business logic, backend API, repository, service, model, authentication flow, payment flow, AI behavior, route, screen, or navigation behavior was changed by this design-system foundation.
