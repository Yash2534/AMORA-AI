import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Tonal, low-opacity elevation appropriate for Material 3 surfaces.
abstract final class AmoraShadows {
  static List<BoxShadow> get level0 => const [];

  static List<BoxShadow> get level1 => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: .06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get level2 => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: .08),
      blurRadius: 16,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get level3 => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: .1),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get floating => level3;
  static List<BoxShadow> get dialog => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: .14),
      blurRadius: 32,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    ),
  ];
  static List<BoxShadow> get bottomSheet => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: .1),
      blurRadius: 28,
      spreadRadius: -8,
      offset: const Offset(0, -8),
    ),
  ];
  static List<BoxShadow> get premiumCard => level2;

  // Compatibility aliases.
  static List<BoxShadow> get none => level0;
  static List<BoxShadow> get soft => level1;
  static List<BoxShadow> get medium => level2;
  static List<BoxShadow> get glow => premiumCard;
}
