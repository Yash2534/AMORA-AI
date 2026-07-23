import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PremiumBannerCard extends StatelessWidget {
  const PremiumBannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
    this.badge,
    this.icon = Icons.auto_awesome_rounded,
    this.gradient = const [AppColors.primary, AppColors.primary],
  });

  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;
  final String? badge;
  final IconData icon;

  /// Retained for API compatibility. The first color is used as a solid tonal
  /// surface to avoid heavy gradients in the foundation system.
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final background = gradient.isEmpty ? AppColors.primary : gradient.first;
    return Semantics(
      button: true,
      label: '$title. $cta',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AmoraRadius.card,
          boxShadow: AmoraShadows.premiumCard,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: AmoraRadius.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: AmoraSpacing.card,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (badge != null) ...[
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: AmoraRadius.pillBorder,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AmoraSpacing.space12,
                                vertical: AmoraSpacing.space8,
                              ),
                              child: Text(
                                badge!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AmoraTextStyles.labelMedium.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space12),
                        ],
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AmoraTextStyles.titleLarge.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AmoraTextStyles.bodyMedium.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: .86),
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space16),
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AmoraRadius.pillBorder,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AmoraSpacing.space16,
                              vertical: AmoraSpacing.space12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    cta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AmoraTextStyles.labelLarge.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AmoraSpacing.space8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: AmoraIconSizes.small,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space16),
                  Container(
                    width: AmoraSpacing.space56,
                    height: AmoraSpacing.space56,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.onPrimary,
                      size: AmoraIconSizes.large,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
