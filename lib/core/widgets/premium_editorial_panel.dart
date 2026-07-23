import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/premium_image_card.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class PremiumEditorialPanel extends StatelessWidget {
  const PremiumEditorialPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    this.badge,
    this.cta,
    this.icon = Icons.auto_awesome_rounded,
    this.aspectRatio = 1.72,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final String? badge;
  final String? cta;
  final IconData icon;
  final double aspectRatio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = AmoraRadius.card;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The editorial copy needs a little more vertical breathing room on
        // compact phones; otherwise the two-line title and subtitle can clip.
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final responsiveAspectRatio = textScale > 1.2
            ? 1.32
            : constraints.maxWidth < 340
            ? 1.54
            : constraints.maxWidth < 360
            ? 1.72
            : aspectRatio;
        return PressableScale(
          enabled: onTap != null,
          child: AspectRatio(
            aspectRatio: responsiveAspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: AmoraShadows.premiumCard,
              ),
              child: PremiumImageCard(
                assetPath: assetPath,
                fallbackAsset: AppImages.fallbackDateSpot,
                initials: 'AI',
                borderRadius: radius,
                gradientColors: [
                  AppColors.deepWine.withValues(alpha: .14),
                  AppColors.deepWine.withValues(alpha: .12),
                  AppColors.deepWine.withValues(alpha: .46),
                  AppColors.deepNavy.withValues(alpha: .88),
                ],
                onTap: onTap,
                overlayChild: Padding(
                  padding: AmoraSpacing.compactCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _SolidBadge(icon: icon, label: badge ?? 'AMORA AI'),
                          const Spacer(),
                          if (cta != null)
                            _SolidAction(label: cta!, onTap: onTap),
                        ],
                      ),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 330),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AmoraTextStyles.headlineSmall.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                            const SizedBox(height: AmoraSpacing.space8),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AmoraTextStyles.bodySmall.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SolidBadge extends StatelessWidget {
  const _SolidBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.deepWine,
          borderRadius: AmoraRadius.pillBorder,
          border: Border.all(color: AppColors.deepWine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AmoraIconSizes.small,
              color: AppColors.premiumGold,
            ),
            const SizedBox(width: AmoraSpacing.space8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidAction extends StatelessWidget {
  const _SolidAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AmoraRadius.pillBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AmoraRadius.pillBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
              vertical: AmoraSpacing.space8,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.deepWine,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
