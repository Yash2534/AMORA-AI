# AMORA AI — Stage 2D & 2E Design System Migration Report

## 1. Existing Screens Reviewed

### Events

- Events browse/list (`/events`)
- Event detail (`/event-detail`)
- Ticket booking (`/ticket-booking`)
- Event waitlist (`/event-waitlist`)
- My Events (`/my-events`)
- Post-event feedback (`/post-event-feedback`)
- Event group chat (`/event-group-chat`)
- Date spots (`/date-spots`)

`events_screen.dart` is a route-compatible alias of `EventsBrowseScreen`, so it required no duplicate UI implementation. No standalone Event Gallery or Event Ticket screen exists.

### Premium and Commerce

- Subscription and embedded plan comparison (`/subscription`)
- Payment checkout (`/payment`)
- Amora Wallet (`/wallet`)
- Profile Boost (`/profile-boost`)
- Liked You paywall (`/liked-you-paywall`, `/liked-you`)
- Refer & Earn (`/refer-earn`)
- Referral leaderboard (`/referral-leaderboard`)
- Gift catalog (`/gift-shop-catalog`)
- Send Gift (`/send-gift`)

No separate Revenue Plans, Packages, or Gift Details screen exists. Plan/package presentation remains embedded in the existing subscription, wallet, and boost screens.

## 2. Screens Updated

All existing screens listed above were migrated directly or through the shared event and monetization component layers. Existing screen order, route names, arguments, callbacks, selectors, calculations, and navigation destinations were retained.

## 3. Files Modified

### Shared design system

- `lib/core/theme/amora_icons.dart`
- `lib/core/widgets/amora_search_bar.dart`

### Events

- `lib/features/events/presentation/events_browse_screen.dart`
- `lib/features/events/presentation/event_detail_screen.dart`
- `lib/features/events/presentation/ticket_booking_screen.dart`
- `lib/features/events/presentation/event_waitlist_screen.dart`
- `lib/features/events/presentation/my_events_screen.dart`
- `lib/features/events/presentation/post_event_feedback_screen.dart`
- `lib/features/events/presentation/event_group_chat_screen.dart`
- `lib/features/events/presentation/widgets/events_widgets.dart`
- `lib/features/date_spots/presentation/date_spots_map_screen.dart`

### Premium, payment, wallet, referral, and gifts

- `lib/features/monetization/presentation/widgets/monetization_widgets.dart`
- `lib/features/subscription/presentation/subscription_screen.dart`
- `lib/features/payment/presentation/payment_screen.dart`
- `lib/features/wallet/presentation/amora_wallet_screen.dart`
- `lib/features/monetization/presentation/profile_boost_screen.dart`
- `lib/features/monetization/presentation/liked_you_paywall_screen.dart`
- `lib/features/referral/presentation/refer_earn_screen.dart`
- `lib/features/referral/presentation/referral_leaderboard_screen.dart`
- `lib/features/commerce/presentation/gift_catalog_screen.dart`
- `lib/features/commerce/presentation/send_gift_screen.dart`

Pre-existing Stage 2C changes in `premium_editorial_panel.dart`, chat tests, and `CHAT_UI_STAGE_2C_REPORT.md` were preserved and were not overwritten by this stage.

## 4. UI Improvements

- Migrated event and monetization headers to shared typography, icon, spacing, and touch-target tokens.
- Replaced the event CTA primitive with `AppPrimaryButton`, including compact and outlined variants.
- Replaced local event city/category chips with `AmoraFilterChip`.
- Migrated event search and date-spot search to `AmoraSearchBar`; added an optional shared clear action without changing query behavior.
- Replaced event list loading and empty presentations with `AmoraCardSkeleton` and `AmoraEmptyState`.
- Migrated event recommendation/map and wallet quick-action surfaces to shared card variants.
- Standardized event cards, badges, metadata, host details, plan cards, price hierarchy, and wallet package selection with `AmoraTextStyles`, `AmoraSpacing`, `AmoraRadius`, `AmoraShadows`, and semantic colors.
- Replaced local snackbars with `showAmoraSnackBar` through the existing event/premium helper functions.
- Replaced local cancellation, feedback-success, redemption, and payment-success dialogs with `AmoraDialog`.
- Replaced the QR pass modal with `AmoraBottomSheet`.
- Migrated booking coupon, payment coupon, feedback comment, and event group composer inputs to shared input/search components.
- Replaced raw subscription and boost outlined buttons with `AppPrimaryButton` variants.
- Removed unsupported voice and media placeholder controls from Event Group Chat; its text input and existing send callback are unchanged.

## 5. Design System Components Used

- `AmoraTextStyles`
- `AmoraSpacing` and `AmoraRadius`
- `AppColors`
- `AmoraIcons` and shared icon sizes
- `AmoraShadows`
- `AppPrimaryButton`
- `AppTextField`
- `AmoraSearchBar`
- `AmoraCard` and `PremiumCard`
- `AmoraFilterChip`
- `AmoraDialog`
- `AmoraBottomSheet`
- `AmoraEmptyState`
- `AmoraCardSkeleton`
- `PremiumAvatar` and existing premium image components

## 6. Responsive Improvements

- Replaced fixed screen gutters and bottom insets in the migrated surfaces with shared responsive spacing/navigation tokens.
- Kept scrollable layouts, safe areas, adaptive event grids, ellipsis handling, flexible rows, and full-width CTAs.
- Preserved keyboard-safe scrolling for booking, payment, feedback, search, and group text entry.
- Existing responsive regression coverage passed at 320, 360, 375, 390, 412, 414, 768, and 1024 logical pixels.

## 7. Accessibility Improvements

- Standardized interactive controls on Material/shared components with 48dp minimum targets.
- Added or retained semantic labels/tooltips for cards, search clearing, navigation, booking, and icon actions.
- Replaced local type declarations in primary hierarchy points with scalable shared text roles.
- Retained Material focus, pressed, disabled, selected, and loading behavior through shared components.
- Preserved text overflow safeguards and flexible layouts for larger font scales.

## 8. QA Results

- `dart format`: completed for all modified Stage 2D/2E Dart files.
- `flutter analyze`: **0 issues**.
- `flutter test`: **11/11 tests passed**.
- Registered-route build test: passed.
- Required-width responsive journey test: passed at 320, 360, 375, 390, 412, 414, 768, and 1024dp.
- Text-only chat regression test: passed.
- No route, navigation, analyzer, missing-icon, or tested layout exception regressions detected.

## 9. Remaining UI Improvements

No additional Stage 2D/2E screen is required. Standalone Event Gallery, Event Ticket, Revenue Plans, Packages, and Gift Details were intentionally not created because those screens do not exist in the project. Further screen-level work should continue only in the next approved stage.

## Preservation Confirmation

Business logic, backend APIs, repositories, providers, services, controllers, models, authentication, payment calculations, wallet calculations, referral behavior, booking/event registration behavior, route names, route arguments, and navigation flow remain unchanged. This stage changes frontend presentation only.
