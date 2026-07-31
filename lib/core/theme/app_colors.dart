import 'package:flutter/material.dart';

/// The complete approved AMORAA colour palette.
///
/// Every semantic role and compatibility alias below resolves to one of these
/// six colours. Do not add raw colour values outside this file.
abstract final class AppColors {
  static const Color primary = Color(0xFF3D0B3F);
  static const Color secondary = Color(0xFFEC5FA8);
  static const Color tertiary = Color(0xFFF4A9CE);
  static const Color background = Color(0xFFFDF1F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF2B2B2B);
  static const Color transparent = Colors.transparent;

  // Material 3 roles.
  static const Color onPrimary = surface;
  static const Color primaryContainer = tertiary;
  static const Color onPrimaryContainer = primary;
  static const Color onSecondary = surface;
  static const Color secondaryContainer = tertiary;
  static const Color onSecondaryContainer = primary;
  static const Color onTertiary = primary;
  static const Color tertiaryContainer = background;
  static const Color onTertiaryContainer = primary;
  static const Color error = primary;
  static const Color onError = surface;
  static const Color errorContainer = tertiary;
  static const Color onErrorContainer = primary;
  static const Color outline = tertiary;
  static const Color outlineVariant = tertiary;
  static const Color shadow = text;
  static const Color scrim = text;

  // Interaction and selection roles.
  static const Color active = secondary;
  static const Color onActive = surface;
  static const Color activeContainer = tertiary;
  static const Color selectedContainer = tertiary;
  static const Color focus = secondary;
  static const Color hover = background;
  static const Color pressed = tertiary;
  static const Color disabled = tertiary;

  // Surfaces.
  static const Color onBackground = text;
  static const Color onSurface = text;
  static const Color surfaceSoft = background;
  static const Color surfaceDim = background;
  static const Color surfaceBright = surface;
  static const Color surfaceContainerLowest = surface;
  static const Color surfaceContainerLow = surface;
  static const Color surfaceContainer = surface;
  static const Color surfaceContainerHigh = background;
  static const Color surfaceContainerHighest = tertiary;
  static const Color cardBackground = surface;
  static const Color inputBackground = surface;
  static const Color chipBackground = surface;
  static const Color splashBackground = background;
  static const Color splashGlow = tertiary;

  // Content and structure.
  static const Color textPrimary = text;
  static const Color textSecondary = text;
  static const Color textMuted = text;
  static const Color textDisabled = text;
  static const Color border = tertiary;
  static const Color borderStrong = tertiary;
  static const Color divider = tertiary;
  static const Color overlayDark = text;
  static const Color overlayLight = surface;

  // Feedback and status roles. Meaning is also communicated with copy/icons.
  static const Color success = primary;
  static const Color onSuccess = surface;
  static const Color successContainer = tertiary;
  static const Color onSuccessContainer = primary;
  static const Color warning = secondary;
  static const Color onWarning = surface;
  static const Color warningContainer = tertiary;
  static const Color onWarningContainer = primary;
  static const Color info = secondary;
  static const Color onInfo = surface;
  static const Color infoContainer = tertiary;
  static const Color onInfoContainer = primary;
  static const Color online = primary;
  static const Color offline = text;
  static const Color unread = primary;

  // Premium product roles.
  static const Color premium = secondary;
  static const Color onPremium = surface;
  static const Color premiumContainer = tertiary;
  static const Color onPremiumContainer = primary;

  // Compatibility aliases retained for existing feature code.
  static const Color textNeutral = text;
  static const Color roseQuartz = tertiary;
  static const Color blush = background;
  static const Color mist = background;
  static const Color plum = primary;
  static const Color mauve = text;
  static const Color champagneGold = secondary;
  static const Color sage = primary;
  static const Color amber = secondary;
  static const Color coral = secondary;
  static const Color gradientEnd = primary;
  static const Color primaryLight = tertiary;
  static const Color tertiarySoft = background;
  static const Color primaryPurple = primary;
  static const Color deepWine = primary;
  static const Color primaryRose = secondary;
  static const Color roseRed = secondary;
  static const Color softPink = tertiary;
  static const Color lavenderBackground = background;
  static const Color lightPinkBackground = background;
  static const Color porcelain = surface;
  static const Color warmIvory = surface;
  static const Color blushMist = background;
  static const Color mutedPlum = text;
  static const Color deepNavy = primary;
  static const Color charcoal = text;
  static const Color ink = text;
  static const Color champagne = tertiary;
  static const Color white = surface;
  static const Color black = text;
  static const Color premiumGold = tertiary;
  static const Color successGreen = primary;
  static const Color errorRed = primary;
  static const Color warningAmber = secondary;
  static const Color textDark = text;
  static const Color textGray = text;
  static const Color grey = text;
  static const Color borderGray = tertiary;
  static const Color lightGray = background;
}
