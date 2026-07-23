import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = AmoraSpacing.card,
    this.radius = AmoraRadius.extraLarge,
    this.color = AppColors.cardBackground,
    this.borderColor,
    this.shadowOpacity = .06,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color? borderColor;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final shadows = shadowOpacity <= 0
        ? AmoraShadows.level0
        : AmoraShadows.premiumCard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadows,
      ),
      child: Material(
        color: AppColors.transparent,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
