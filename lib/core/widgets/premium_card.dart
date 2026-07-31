import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = AmoraSpacing.card,
    this.radius = AmoraRadius.extraLarge,
    this.color,
    this.borderColor,
    this.shadowOpacity = .06,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color ?? theme.cardTheme.color ?? theme.colorScheme.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: shadowOpacity <= 0 ? 0 : 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: shadowOpacity),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
