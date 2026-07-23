import 'package:flutter/material.dart';

<<<<<<< HEAD
/// AMORA_AI's 2027 semantic color system.
///
/// Feature code should consume roles, not hexadecimal values. Compatibility
/// aliases remain at the bottom while older screens migrate to semantic names;
/// every alias resolves to this approved palette or an intentional status role.
abstract final class AppColors {
  // Approved brand foundation.
  static const primary = Color(0xFF3D0B3F); // Deep Plum
  static const primaryDark = Color(0xFF29072B);
  static const primaryLight = Color(0xFF5A235C);
  static const primaryStrong = primaryDark;
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFCE8F1);
  static const onPrimaryContainer = primary;

  static const secondary = Color(0xFFEC5FA8); // Vibrant Pink
  static const secondaryDark = Color(0xFFD74288);
  static const secondaryLight = Color(0xFFF58CC0);
  static const onSecondary = primary;
  static const secondaryContainer = Color(0xFFFCE8F1);
  static const onSecondaryContainer = primary;

  static const tertiary = Color(0xFFF4A9CE); // Blush Pink
  static const tertiaryLight = Color(0xFFF9CFE2);
  static const tertiarySoft = Color(0xFFFCE8F1);
  static const onTertiary = primary;
  static const tertiaryContainer = tertiarySoft;
  static const onTertiaryContainer = primary;

  // Interaction and selection roles.
  static const active = secondary;
  static const onActive = onSecondary;
  static const activeContainer = secondaryContainer;
  static const selected = primary;
  static const onSelected = onPrimary;
  static const selectedContainer = tertiary;
  static const hover = Color(0xFFFBE6F0);
  static const pressed = Color(0xFFF7D3E4);
  static const focus = secondary;
  static const disabled = Color(0xFFE2D8DE);

  // Surfaces.
  static const background = Color(0xFFFDF1F7);
  static const onBackground = Color(0xFF2B2B2B);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = onBackground;
  static const surfaceSoft = Color(0xFFFFF8FB);
  static const surfaceElevated = surface;
  static const surfaceSelected = secondaryContainer;
  static const surfaceDim = Color(0xFFF3E8EE);
  static const surfaceBright = surface;
  static const surfaceContainerLowest = surface;
  static const surfaceContainerLow = surfaceSoft;
  static const surfaceContainer = secondaryContainer;
  static const surfaceContainerHigh = Color(0xFFF8EAF1);
  static const surfaceContainerHighest = Color(0xFFF1E4EB);
  static const cardBackground = surface;
  static const inputBackground = surface;
  static const chipBackground = surfaceSoft;

  // Content, borders, and overlays.
  static const textPrimary = onBackground;
  static const textSecondary = Color(0xFF6E626D);
  static const textMuted = Color(0xFF91858F);
  static const textOnPrimary = onPrimary;
  static const textOnSecondary = onSecondary;
  static const textDisabled = Color(0xFFB7ABB4);
  static const outline = Color(0xFF91858F);
  static const outlineVariant = Color(0xFFEADAE3);
  static const border = outlineVariant;
  static const borderStrong = Color(0xFFD9C1CE);
  static const divider = Color(0xFFF0E4EA);
  static const scrim = Color(0xFF000000);
  static const shadow = primary;
  static const overlayDark = Color(0x66000000);
  static const overlayLight = Color(0x99FFFFFF);
  static const transparent = Color(0x00000000);

  // Feedback and status roles. These are deliberate semantic exceptions to the
  // brand palette and are never used as decorative accents.
  static const error = Color(0xFFB32645);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFDE8EC);
  static const onErrorContainer = Color(0xFF5B1421);
  static const success = Color(0xFF247A59);
  static const onSuccess = Color(0xFFFFFFFF);
  static const successContainer = Color(0xFFE6F6EF);
  static const onSuccessContainer = Color(0xFF103E2E);
  static const warning = Color(0xFFD9972F);
  static const onWarning = Color(0xFF3D2A08);
  static const warningContainer = Color(0xFFFFF3DE);
  static const onWarningContainer = Color(0xFF513807);
  static const info = Color(0xFF4561B0);
  static const onInfo = Color(0xFFFFFFFF);
  static const infoContainer = Color(0xFFEAF0FF);
  static const onInfoContainer = Color(0xFF172B64);
  static const online = success;
  static const offline = textDisabled;
  static const unread = active;

  // Premium is intentionally reserved for paid tier and verified status cues.
  static const premium = Color(0xFFE1AA45);
  static const onPremium = Color(0xFF3E2B05);
  static const premiumContainer = Color(0xFFFFF4D8);
  static const onPremiumContainer = Color(0xFF4D3506);
  static const premiumGoldSoft = premiumContainer;

  // Compatibility aliases. Do not introduce new usages of these names.
  static const text = textPrimary;
  static const roseQuartz = primaryContainer;
  static const blush = tertiary;
  static const mist = surfaceContainer;
=======
/// AMORA's approved semantic colour palette.
///
/// Every visible role resolves to one of the six approved brand colours. The
/// compatibility aliases keep existing screens stable while allowing new UI
/// to use concise semantic names.
abstract final class AppColors {
  // Approved brand palette.
  static const primary = Color(0xFF3D0B3F);
  static const secondary = Color(0xFFEC5FA8);
  static const tertiary = Color(0xFFF4A9CE);
  static const background = Color(0xFFFDF1F7);
  static const surface = Color(0xFFFFFFFF);
  static const textNeutral = Color(0xFF2B2B2B);

  // Material 3 brand roles.
  static const onPrimary = surface;
  static const primaryContainer = tertiary;
  static const onPrimaryContainer = primary;
  static const onSecondary = surface;
  static const secondaryContainer = tertiary;
  static const onSecondaryContainer = primary;
  static const onTertiary = primary;
  static const tertiaryContainer = background;
  static const onTertiaryContainer = primary;

  // Surfaces.
  static const onBackground = textNeutral;
  static const onSurface = textNeutral;
  static const surfaceDim = background;
  static const surfaceBright = surface;
  static const surfaceContainerLowest = surface;
  static const surfaceContainerLow = background;
  static const surfaceContainer = background;
  static const surfaceContainerHigh = tertiary;
  static const surfaceContainerHighest = tertiary;
  static const cardBackground = surface;
  static const inputBackground = surface;
  static const chipBackground = background;

  // Content and outlines.
  static const textPrimary = textNeutral;
  static const textSecondary = textNeutral;
  static const textDisabled = tertiary;
  static const outline = secondary;
  static const outlineVariant = tertiary;
  static const border = tertiary;
  static const divider = tertiary;
  static const scrim = primary;
  static const shadow = primary;
  static const transparent = Color(0x00000000);

  // Feedback and status roles use approved brand colours.
  static const error = secondary;
  static const onError = surface;
  static const errorContainer = background;
  static const onErrorContainer = primary;
  static const success = primary;
  static const onSuccess = surface;
  static const successContainer = tertiary;
  static const onSuccessContainer = primary;
  static const warning = secondary;
  static const onWarning = surface;
  static const warningContainer = tertiary;
  static const onWarningContainer = primary;
  static const info = primary;
  static const onInfo = surface;
  static const infoContainer = background;
  static const onInfoContainer = primary;
  static const online = success;
  static const offline = textNeutral;
  static const unread = primary;

  // Premium product accents.
  static const premium = secondary;
  static const onPremium = surface;
  static const premiumContainer = tertiary;
  static const onPremiumContainer = primary;

  // Compatibility aliases. Do not introduce new usages of these names.
  static const text = textPrimary;
  static const roseQuartz = tertiary;
  static const blush = background;
  static const mist = background;
>>>>>>> main
  static const plum = primary;
  static const mauve = textNeutral;
  static const champagneGold = secondary;
  static const sage = primary;
  static const amber = secondary;
  static const coral = secondary;
  static const gradientEnd = secondary;
  static const primaryPurple = primary;
  static const deepWine = primary;
  static const primaryRose = secondary;
<<<<<<< HEAD
  static const roseRed = secondaryDark;
  static const softPink = activeContainer;
  static const lavenderBackground = tertiarySoft;
  static const lightPinkBackground = background;
  static const porcelain = surfaceSoft;
  static const warmIvory = surface;
  static const blushMist = tertiarySoft;
  static const mutedPlum = textSecondary;
  static const deepNavy = primary;
  static const charcoal = textPrimary;
  static const ink = textPrimary;
  static const champagne = premiumContainer;
  static const white = surface;
  static const black = textPrimary;
  static const premiumGold = premium;
  static const successGreen = success;
  static const errorRed = error;
  static const warningAmber = warning;
  static const textDark = textPrimary;
  static const textGray = textSecondary;
  static const grey = textSecondary;
  static const borderGray = border;
  static const lightGray = surfaceContainerHighest;
=======
  static const roseRed = secondary;
  static const softPink = tertiary;
  static const lavenderBackground = background;
  static const lightPinkBackground = background;
  static const porcelain = background;
  static const warmIvory = surface;
  static const blushMist = background;
  static const mutedPlum = textNeutral;
  static const deepNavy = textNeutral;
  static const charcoal = textNeutral;
  static const ink = textNeutral;
  static const champagne = tertiary;
  static const white = surface;
  static const black = textNeutral;
  static const premiumGold = secondary;
  static const successGreen = primary;
  static const errorRed = secondary;
  static const warningAmber = secondary;
  static const textDark = textNeutral;
  static const textGray = textNeutral;
  static const grey = textNeutral;
  static const borderGray = tertiary;
  static const lightGray = background;
>>>>>>> main
}
