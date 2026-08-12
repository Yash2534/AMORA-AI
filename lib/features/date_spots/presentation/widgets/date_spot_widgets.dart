import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:flutter/material.dart';

void showDashboardSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

String _dateSpotImageFor(String name) {
  return ImageRepository.venueByName(name).imageUrl;
}

String _dateSpotAssetFor(String name) {
  return ImageRepository.venueByName(name).fallbackAsset;
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space8,
        vertical: AmoraSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AmoraTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AmoraTextStyles.titleLarge.copyWith(
            color: AppColors.deepWine,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            subtitle!,
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class DateSpotCard extends StatelessWidget {
  const DateSpotCard({
    super.key,
    required this.name,
    required this.rating,
    required this.distance,
    required this.price,
    required this.bestFor,
    required this.score,
    required this.packagePrice,
    required this.saved,
    required this.onDetails,
    required this.onBuy,
    required this.onSave,
  });

  final String name;
  final String rating;
  final String distance;
  final String price;
  final String bestFor;
  final int score;
  final String packagePrice;
  final bool saved;
  final VoidCallback onDetails;
  final VoidCallback onBuy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(30),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        radius: 30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.72,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PremiumAssetImage(
                      imageUrl: _dateSpotImageFor(name),
                      fallbackAsset: _dateSpotAssetFor(name),
                      initials: name.substring(0, 1),
                      borderRadius: BorderRadius.zero,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .40),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: StatusChip(
                        label: 'AMORAA $score',
                        color: AppColors.premiumGold,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        tooltip: saved ? 'Saved' : 'Save',
                        onPressed: onSave,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primaryRose,
                        ),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 24,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$rating star - $distance - $price',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best for $bestFor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const StatusChip(
                        label: 'Safety checked',
                        color: AppColors.successGreen,
                      ),
                      StatusChip(
                        label: packagePrice,
                        color: AppColors.premiumGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Details',
                          icon: Icons.info_outline_rounded,
                          size: AmoraButtonSize.compact,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: onDetails,
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space8),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Reserve',
                          icon: AmoraIcons.events,
                          size: AmoraButtonSize.compact,
                          onPressed: onBuy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VenueMapPreviewCard extends StatelessWidget {
  const VenueMapPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final venue = ImageRepository.venues[4];
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.surface),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumAssetImage(
              imageUrl: venue.imageUrl,
              fallbackAsset: venue.fallbackAsset,
              initials: 'V',
              borderRadius: BorderRadius.zero,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .38),
              ),
            ),
            const _MapPin(left: 42, top: 52, label: 'Mocha'),
            const _MapPin(left: 210, top: 70, label: 'Makeba'),
            const _MapPin(left: 132, top: 142, label: 'Zen'),
            const Positioned(
              right: 16,
              bottom: 14,
              child: StatusChip(
                label: 'Venue heatmap',
                color: AppColors.premiumGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.left, required this.top, required this.label});

  final double left;
  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.primaryRose,
            size: 36,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
