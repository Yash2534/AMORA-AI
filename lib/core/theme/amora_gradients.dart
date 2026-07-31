import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AmoraGradients {
  const AmoraGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.secondary, AppColors.primary],
  );

  static const LinearGradient primaryDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.primary],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.surface],
  );

  static const LinearGradient warmSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.background, AppColors.surface],
  );

  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.tertiary, AppColors.primary],
  );

  static const LinearGradient premiumBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.tertiary, AppColors.primary],
  );

  static const LinearGradient verifiedBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.primary],
  );
}
