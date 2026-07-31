import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Material 3-aligned type scale using the platform's native UI font.
abstract final class AmoraTextStyles {
  static const String? fontFamily = null;

  static const displayLarge = TextStyle(
    fontSize: 48,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );
  static const displayMedium = TextStyle(
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: AppColors.primary,
  );
  static const displaySmall = TextStyle(
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const headlineLarge = TextStyle(
    fontSize: 32,
    height: 1.16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const headlineMedium = TextStyle(
    fontSize: 28,
    height: 1.18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const headlineSmall = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const titleLarge = TextStyle(
    fontSize: 22,
    height: 1.24,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const titleMedium = TextStyle(
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.primary,
  );
  static const titleSmall = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.primary,
  );
  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: AppColors.text,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: AppColors.text,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.text,
  );
  static const labelLarge = TextStyle(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.text,
  );
  static const labelMedium = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.text,
  );
  static const labelSmall = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.text,
  );

  static const button = labelLarge;
  static const navigation = labelSmall;
  static const caption = bodySmall;
  static const dialogTitle = headlineSmall;
  static const dialogBody = bodyLarge;
  static const bottomSheetTitle = titleLarge;
  static const screenTitle = headlineMedium;
  static const sectionTitle = titleLarge;
  static const cardTitle = titleMedium;
  static const supportingText = bodyMedium;
  static const inputLabel = labelMedium;
  static const badge = labelSmall;
  static const profileName = headlineSmall;
  static const metadata = bodySmall;
  static const buttonLabel = button;
  static const navigationLabel = navigation;
  static const buttonLabelOnPrimary = TextStyle(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.surface,
  );
  static const accentText = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
  );

  // Compatibility aliases.
  static const display = displaySmall;
  static const heading = headlineMedium;
  static const title = titleLarge;
  static const subtitle = titleMedium;
  static const body = bodyLarge;

  static const textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
