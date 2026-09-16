import 'package:flutter/material.dart';

/// Amoraa Premium Plum Theme palette.
///
/// Centralized brand color definitions based on official Amoraa design specs.
abstract final class AppColors {
  // Amoraa Core Brand Colors
  static const Color primary = Color(0xFF713F62); // Deep Plum
  static const Color primaryDark = Color(0xFF5F2F63); // Dark Berry Plum
  static const Color primaryLight = Color(0xFF8F5A88); // Soft Mauve
  static const Color accent = Color(0xFFCFAFC4); // Dusty Rose
  static const Color accentSoft = Color(0xFFF6E4F0); // Blush Lavender
  static const Color background = Color(0xFFFEFCFF); // Warm Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF35152F); // Deep Plum Black
  static const Color textSecondary = Color(0xFF735F70); // Muted Mauve
  static const Color border = Color(0xFFE9DFE7); // Soft Lavender Gray
  static const Color success = Color(0xFF18C98A); // Fresh Mint Green
  static const Color error = Color(0xFFD9535F); // Soft Red

  static const Color transparent = Colors.transparent;

  // Base aliases & Flutter theme shortcuts
  static const Color primaryColor = primary;
  static const Color secondary = accent;
  static const Color tertiary = accentSoft;
  static const Color text = textPrimary;

  // Logo Brand Tokens (Primary Plum + Supporting Soft Lavender)
  static const Color logoPrimary = primary; // 1. Deep Amoraa Plum (#713F62) [Dominant 50%]
  static const Color logoSecondary = accent; // 2. Soft Lavender / Dusty Rose (#CFAFC4) [Supporting 25%]
  static const Color logoHighlight = surface; // 3. Warm Off-White / Pure White (#FFFFFF) [Light Detail 10%]
  static const Color logoGlow = textPrimary; // 4. Deep Plum Black (#35152F) [Dark Contrast Detail 15%]



  // Material 3 roles.
  static const Color onPrimary = surface;
  static const Color primaryContainer = accentSoft;
  static const Color onPrimaryContainer = textPrimary;

  static const Color onSecondary = surface;
  static const Color secondaryContainer = accentSoft;
  static const Color onSecondaryContainer = textPrimary;

  static const Color onTertiary = primary;
  static const Color tertiaryContainer = background;
  static const Color onTertiaryContainer = primary;

  static const Color onError = surface;
  static const Color errorContainer = accentSoft;
  static const Color onErrorContainer = error;

  static const Color outline = border;
  static const Color outlineVariant = border;
  static const Color shadow = Color(0x1A35152F);
  static const Color scrim = textPrimary;

  // Interaction.
  static const Color active = primary;
  static const Color onActive = surface;
  static const Color activeContainer = accentSoft;
  static const Color selectedContainer = accentSoft;
  static const Color focus = primary;
  static const Color hover = accentSoft;
  static const Color pressed = primaryDark;
  static const Color disabled = border;

  // Surfaces.
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;
  static const Color surfaceSoft = background;
  static const Color surfaceDim = background;
  static const Color surfaceBright = surface;
  static const Color surfaceContainerLowest = surface;
  static const Color surfaceContainerLow = surface;
  static const Color surfaceContainer = surface;
  static const Color surfaceContainerHigh = background;
  static const Color surfaceContainerHighest = accentSoft;
  static const Color cardBackground = surface;
  static const Color inputBackground = surface;
  static const Color chipBackground = surface;
  static const Color splashBackground = background;
  static const Color splashGlow = accentSoft;

  // Content.
  static const Color textMuted = textSecondary;
  static const Color textDisabled = Color(0x80735F70);
  static const Color borderStrong = primary;
  static const Color divider = border;
  static const Color overlayDark = textPrimary;
  static const Color overlayLight = surface;

  // Status.
  static const Color onSuccess = surface;
  static const Color successContainer = Color(0x2618C98A);
  static const Color onSuccessContainer = textPrimary;

  static const Color warning = Color(0xFFFFB74D);
  static const Color onWarning = surface;
  static const Color warningContainer = accentSoft;
  static const Color onWarningContainer = primary;

  static const Color info = primaryLight;
  static const Color onInfo = surface;
  static const Color infoContainer = accentSoft;
  static const Color onInfoContainer = primary;

  static const Color online = success;
  static const Color offline = textSecondary;
  static const Color unread = primary;

  // Super Like.
  static const Color superLike = primary;
  static const Color onSuperLike = surface;
  static const Color superLikeContainer = accentSoft;
  static const Color onSuperLikeContainer = primary;

  // Premium.
  static const Color premium = primary;
  static const Color onPremium = surface;
  static const Color premiumContainer = accentSoft;
  static const Color onPremiumContainer = primary;

  // Existing compatibility aliases.
  static const Color textNeutral = textPrimary;
  static const Color roseQuartz = accent;
  static const Color blush = accentSoft;
  static const Color mist = background;
  static const Color plum = primary;
  static const Color mauve = textSecondary;
  static const Color champagneGold = primaryLight;
  static const Color sage = success;
  static const Color amber = warning;
  static const Color coral = error;
  static const Color gradientEnd = primaryLight;
  static const Color tertiarySoft = accentSoft;
  static const Color primaryPurple = primary;
  static const Color deepWine = primaryDark;
  static const Color primaryRose = accent;
  static const Color roseRed = error;
  static const Color softPink = accentSoft;
  static const Color lavenderBackground = background;
  static const Color lightPinkBackground = background;
  static const Color porcelain = surface;
  static const Color warmIvory = background;
  static const Color blushMist = background;
  static const Color mutedPlum = textSecondary;
  static const Color deepNavy = textPrimary;
  static const Color charcoal = textPrimary;
  static const Color ink = textPrimary;
  static const Color champagne = accent;
  static const Color white = surface;
  static const Color black = textPrimary;
  static const Color premiumGold = accent;
  static const Color successGreen = success;
  static const Color errorRed = error;
  static const Color warningAmber = warning;
  static const Color textDark = textPrimary;
  static const Color textGray = textSecondary;
  static const Color grey = textSecondary;
  static const Color borderGray = border;
  static const Color lightGray = background;
}
