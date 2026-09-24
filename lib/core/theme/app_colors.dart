import 'package:flutter/material.dart';

/// Amoraa Premium Plum Theme palette.
///
/// Centralized brand color definitions based on official Amoraa design specs.
abstract final class AppColors {
  // 1. FINAL AMORAA CORE COLOR PALETTE
  static const Color primary = Color(0xFF713F62);
  static const Color primaryDark = Color(0xFF4B1F45);
  static const Color primaryLight = Color(0xFF8F5A88);
  static const Color plumBlack = Color(0xFF35152F);
  static const Color accentLavender = Color(0xFFE8D4E5);
  static const Color softLavender = Color(0xFFF3DCEB);
  static const Color pageBackground = Color(0xFFFEFCFF);
  static const Color softBackground = Color(0xFFF7EFF6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF735F70);
  static const Color border = Color(0xFFE9DFE7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color glassShadow = Color(0xFF6B4E71);
  static const Color success = Color(0xFF5E806D);
  static const Color error = Color(0xFFC94F5A);
  static const Color premium = Color(0xFF8B2F8F);
  
  static const Color transparent = Colors.transparent;

  // Base aliases & Flutter theme shortcuts mapped to CORE palette
  static const Color primaryColor = primary;
  static const Color secondary = accentLavender;
  static const Color tertiary = softLavender;
  static const Color textPrimary = plumBlack;
  static const Color textSecondary = secondaryText;
  static const Color text = textPrimary;
  static const Color background = pageBackground;
  static const Color surface = card;

  // Legacy mappings for backwards compatibility
  static const Color accent = accentLavender;
  static const Color accentSoft = softLavender;
  
  // Logo Brand Tokens
  static const Color logoPrimary = primary; 
  static const Color logoSecondary = accentLavender; 
  static const Color logoHighlight = white; 
  static const Color logoGlow = plumBlack; 

  // Material 3 roles.
  static const Color onPrimary = white;
  static const Color primaryContainer = softLavender;
  static const Color onPrimaryContainer = plumBlack;

  static const Color onSecondary = white;
  static const Color secondaryContainer = softLavender;
  static const Color onSecondaryContainer = plumBlack;

  static const Color onTertiary = primary;
  static const Color tertiaryContainer = pageBackground;
  static const Color onTertiaryContainer = primary;

  static const Color onError = white;
  static const Color errorContainer = softLavender;
  static const Color onErrorContainer = error;

  static const Color outline = border;
  static const Color outlineVariant = border;
  static const Color shadow = Color(0x1A35152F); // Slightly transparent Plum Black
  static const Color scrim = plumBlack;

  // Interaction.
  static const Color active = primary;
  static const Color onActive = white;
  static const Color activeContainer = Color(0x14713F62);
  static const Color selectedContainer = Color(0x14713F62);
  static const Color focus = primary;
  static const Color hover = softLavender;
  static const Color pressed = primaryDark;
  static const Color disabled = border;

  // Surfaces.
  static const Color onBackground = plumBlack;
  static const Color onSurface = plumBlack;
  static const Color surfaceSoft = softBackground;
  static const Color surfaceDim = pageBackground;
  static const Color surfaceBright = white;
  static const Color surfaceContainerLowest = white;
  static const Color surfaceContainerLow = white;
  static const Color surfaceContainer = white;
  static const Color surfaceContainerHigh = pageBackground;
  static const Color surfaceContainerHighest = softLavender;
  static const Color cardBackground = white;
  static const Color inputBackground = white;
  static const Color chipBackground = white;
  static const Color splashBackground = pageBackground;
  static const Color splashGlow = softLavender;

  // Content.
  static const Color textMuted = secondaryText;
  static const Color textDisabled = Color(0x80735F70);
  static const Color borderStrong = primary;
  static const Color divider = border;
  static const Color overlayDark = plumBlack;
  static const Color overlayLight = white;

  // Status.
  static const Color onSuccess = white;
  static const Color successContainer = Color(0x265E806D);
  static const Color onSuccessContainer = plumBlack;

  static const Color warning = Color(0xFFFFB74D);
  static const Color onWarning = white;
  static const Color warningContainer = softLavender;
  static const Color onWarningContainer = primary;

  static const Color info = primaryLight;
  static const Color onInfo = white;
  static const Color infoContainer = softLavender;
  static const Color onInfoContainer = primary;

  static const Color online = success;
  static const Color offline = secondaryText;
  static const Color unread = primary;

  // Super Like. (Must use Amoraa theme: Icon primary, active soft lavender, premium state)
  static const Color superLike = primary;
  static const Color onSuperLike = white;
  static const Color superLikeContainer = softLavender;
  static const Color onSuperLikeContainer = primary;

  // Premium.
  static const Color onPremium = white;
  static const Color premiumContainer = accentLavender;
  static const Color onPremiumContainer = premium;

  // Existing compatibility aliases.
  static const Color textNeutral = plumBlack;
  static const Color roseQuartz = accentLavender;
  static const Color blush = softLavender;
  static const Color mist = pageBackground;
  static const Color plum = primary;
  static const Color mauve = secondaryText;
  static const Color champagneGold = primaryLight;
  static const Color sage = success;
  static const Color amber = warning;
  static const Color coral = error;
  static const Color gradientEnd = primaryLight;
  static const Color tertiarySoft = softLavender;
  static const Color primaryPurple = primary;
  static const Color deepWine = primaryDark;
  static const Color primaryRose = accentLavender;
  static const Color roseRed = error;
  static const Color softPink = softLavender;
  static const Color lavenderBackground = pageBackground;
  static const Color lightPinkBackground = pageBackground;
  static const Color porcelain = white;
  static const Color warmIvory = pageBackground;
  static const Color blushMist = pageBackground;
  static const Color mutedPlum = secondaryText;
  static const Color deepNavy = plumBlack;
  static const Color charcoal = plumBlack;
  static const Color ink = plumBlack;
  static const Color champagne = accentLavender;
  static const Color black = plumBlack;
  static const Color premiumGold = accentLavender;
  static const Color successGreen = success;
  static const Color errorRed = error;
  static const Color warningAmber = warning;
  static const Color textDark = plumBlack;
  static const Color textGray = secondaryText;
  static const Color grey = secondaryText;
  static const Color borderGray = border;
  static const Color lightGray = pageBackground;
}

typedef AmoraaColors = AppColors;
