import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AmoraCardVariant {
  standard,
  profile,
  premium,
  statistic,
  info,
  settings,
  event,
  revenue,
}

class AmoraCard extends StatelessWidget {
  const AmoraCard({
    super.key,
    required this.child,
    this.variant = AmoraCardVariant.standard,
    this.padding = AmoraSpacing.card,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final AmoraCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(variant);
    final content = Padding(padding: padding, child: child);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: AmoraRadius.card,
          border: Border.all(color: colors.$2),
          boxShadow: variant == AmoraCardVariant.premium
              ? AmoraShadows.premiumCard
              : AmoraShadows.level1,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AmoraRadius.card,
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }

  (Color, Color) _colorsFor(AmoraCardVariant value) => switch (value) {
    AmoraCardVariant.premium => (AppColors.premiumContainer, AppColors.premium),
    AmoraCardVariant.info => (AppColors.infoContainer, AppColors.info),
    AmoraCardVariant.revenue => (
      AppColors.surfaceContainerLow,
      AppColors.premium,
    ),
    AmoraCardVariant.profile || AmoraCardVariant.event => (
      AppColors.surfaceContainerLowest,
      AppColors.outlineVariant,
    ),
    AmoraCardVariant.statistic || AmoraCardVariant.settings => (
      AppColors.surfaceContainerLow,
      AppColors.border,
    ),
    AmoraCardVariant.standard => (AppColors.cardBackground, AppColors.border),
  };
}
