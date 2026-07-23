import 'package:amora_ai/core/theme/amora_gradients.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';

enum AmoraBadgeTone { primary, secondary, success, warning, error, neutral }

enum AmoraBadgeStyle { standard, premiumVerified, verified3d }

class AmoraBadge extends StatelessWidget {
  const AmoraBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AmoraBadgeTone.primary,
  }) : style = AmoraBadgeStyle.standard;

  const AmoraBadge.notification({super.key, required this.label})
    : icon = Icons.notifications_rounded,
      tone = AmoraBadgeTone.error,
      style = AmoraBadgeStyle.standard;

  const AmoraBadge.premium({super.key, this.label = 'Premium'})
    : icon = Icons.workspace_premium_rounded,
      tone = AmoraBadgeTone.warning,
      style = AmoraBadgeStyle.standard;

  const AmoraBadge.premiumVerified({super.key, this.label = 'Premium Verified'})
    : icon = AmoraIcons.crown,
      tone = AmoraBadgeTone.warning,
      style = AmoraBadgeStyle.premiumVerified;

  const AmoraBadge.verified3d({super.key, this.label = 'Verified'})
    : icon = AmoraIcons.verified,
      tone = AmoraBadgeTone.primary,
      style = AmoraBadgeStyle.verified3d;

  const AmoraBadge.online({super.key, this.label = 'Online'})
    : icon = Icons.circle,
      tone = AmoraBadgeTone.success,
      style = AmoraBadgeStyle.standard;

  const AmoraBadge.status({
    super.key,
    required this.label,
    this.icon,
    this.tone = AmoraBadgeTone.neutral,
  }) : style = AmoraBadgeStyle.standard;

  const AmoraBadge.unread({super.key, required this.label})
    : icon = null,
      tone = AmoraBadgeTone.primary,
      style = AmoraBadgeStyle.standard;

  final String label;
  final IconData? icon;
  final AmoraBadgeTone tone;
  final AmoraBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      AmoraBadgeTone.primary => AppColors.primary,
      AmoraBadgeTone.secondary => AppColors.secondary,
      AmoraBadgeTone.success => AppColors.success,
      AmoraBadgeTone.warning => AppColors.warning,
      AmoraBadgeTone.error => AppColors.error,
      AmoraBadgeTone.neutral => AppColors.grey,
    };

    final foreground = switch (style) {
      AmoraBadgeStyle.premiumVerified => AppColors.onPremiumContainer,
      AmoraBadgeStyle.verified3d => AppColors.onInfo,
      AmoraBadgeStyle.standard => color,
    };
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: style == AmoraBadgeStyle.standard
            ? color.withValues(alpha: .10)
            : null,
        gradient: switch (style) {
          AmoraBadgeStyle.premiumVerified => AmoraGradients.premiumBadge,
          AmoraBadgeStyle.verified3d => AmoraGradients.verifiedBadge,
          AmoraBadgeStyle.standard => null,
        },
        borderRadius: BorderRadius.circular(AmoraRadius.pill),
        border: Border.all(
          color: style == AmoraBadgeStyle.standard
              ? color.withValues(alpha: .22)
              : AppColors.surface.withValues(alpha: .72),
        ),
        boxShadow: style == AmoraBadgeStyle.standard
            ? AmoraShadows.level0
            : AmoraShadows.level2,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.x3,
          vertical: AmoraSpacing.x2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: AmoraIconSizes.small),
              const SizedBox(width: AmoraSpacing.x1),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (style != AmoraBadgeStyle.verified3d) return badge;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .94, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Stack(
        children: [
          badge,
          Positioned(
            left: AmoraSpacing.space12,
            right: AmoraSpacing.space12,
            top: AmoraSpacing.space4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: .42),
                borderRadius: AmoraRadius.pillBorder,
              ),
              child: const SizedBox(height: AmoraSpacing.space4),
            ),
          ),
        ],
      ),
    );
  }
}
