import 'package:flutter/material.dart';

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
  static const text = Color(0xFF2B2B2B);

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

  // Interaction and selection roles.
  static const active = secondary;
  static const onActive = surface;
  static const activeContainer = tertiary;
  static const selectedContainer = tertiary;
  static const focus = secondary;
  static const hover = background;
  static const pressed = tertiary;
  static const disabled = tertiary;

  // Surfaces.
  static const onBackground = textNeutral;
  static const onSurface = textNeutral;
  static const surfaceSoft = background;
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
  static const textMuted = textNeutral;
  static const textDisabled = tertiary;
  static const outline = secondary;
  static const outlineVariant = tertiary;
  static const border = tertiary;
  static const borderStrong = tertiary;
  static const divider = tertiary;
  static const scrim = primary;
  static const shadow = primary;
  static const overlayDark = primary;
  static const overlayLight = surface;
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
  static const textNeutral = text;
  static const roseQuartz = tertiary;
  static const blush = background;
  static const mist = background;
  static const plum = primary;
  static const mauve = textNeutral;
  static const champagneGold = secondary;
  static const sage = primary;
  static const amber = secondary;
  static const coral = secondary;
  static const gradientEnd = secondary;
  static const primaryLight = tertiary;
  static const tertiarySoft = background;
  static const primaryPurple = primary;
  static const deepWine = primary;
  static const primaryRose = secondary;
  static const roseRed = secondary;
  static const softPink = tertiary;
  static const lavenderBackground = background;
  static const lightPinkBackground = background;
  static const porcelain = surface;
  static const warmIvory = surface;
  static const blushMist = background;
  static const mutedPlum = textNeutral;
  static const deepNavy = primary;
  static const charcoal = textNeutral;
  static const ink = textNeutral;
  static const champagne = tertiary;
  static const white = surface;
  static const black = textNeutral;
  static const premiumGold = tertiary;
  static const successGreen = secondary;
  static const errorRed = secondary;
  static const warningAmber = tertiary;
  static const textDark = textNeutral;
  static const textGray = textNeutral;
  static const grey = textNeutral;
  static const borderGray = tertiary;
  static const lightGray = background;
}
