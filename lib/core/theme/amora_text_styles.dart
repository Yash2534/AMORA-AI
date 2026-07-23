import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Material 3-aligned type scale using the platform's native UI font.
abstract final class AmoraTextStyles {
  static const String? fontFamily = null;

  static const displayLarge = TextStyle(
    color: AppColors.primary,
    fontSize: 48,
    height: 1.08,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
  static const displayMedium = TextStyle(
    color: AppColors.primary,
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );
  static const displaySmall = TextStyle(
    color: AppColors.primary,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w600,
  );
  static const headlineLarge = TextStyle(
    color: AppColors.primary,
    fontSize: 32,
    height: 1.16,
    fontWeight: FontWeight.w600,
  );
  static const headlineMedium = TextStyle(
    color: AppColors.primary,
    fontSize: 28,
    height: 1.18,
    fontWeight: FontWeight.w600,
  );
  static const headlineSmall = TextStyle(
    color: AppColors.primary,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const titleLarge = TextStyle(
    color: AppColors.primary,
    fontSize: 22,
    height: 1.24,
    fontWeight: FontWeight.w600,
  );
  static const titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  static const titleSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  static const bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );
  static const bodyMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );
  static const bodySmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
  static const labelLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  static const labelMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  static const labelSmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static const button = labelLarge;
  static const navigation = labelSmall;
  static const caption = bodySmall;
  static const dialogTitle = headlineSmall;
  static const dialogBody = bodyLarge;
  static const bottomSheetTitle = titleLarge;
  static const screenTitle = headlineMedium;
  static const sectionTitle = titleLarge;
  static const profileName = headlineSmall;
  static const metadata = bodySmall;
  static const buttonLabel = button;
  static const navigationLabel = navigation;

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
