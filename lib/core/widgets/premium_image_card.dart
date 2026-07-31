import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:flutter/material.dart';

class PremiumImageCard extends StatelessWidget {
  const PremiumImageCard({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.fallbackAsset = AppImages.fallbackProfile,
    this.initials = 'AM',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AmoraRadius.card,
    this.overlayChild,
    this.onTap,
  });

  final String? imageUrl;
  final String? assetPath;
  final String fallbackAsset;
  final String initials;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? overlayChild;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final overlay = overlayChild;
    Widget card = Stack(
      fit: StackFit.expand,
      children: [
        PremiumImage(
          imageUrl: imageUrl,
          assetPath: assetPath,
          fallbackAsset: fallbackAsset,
          initials: initials,
          width: width,
          height: height,
          fit: fit,
          borderRadius: borderRadius,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: AppColors.primary.withValues(alpha: .34),
              ),
            ),
          ),
        ),
        // ignore: use_null_aware_elements
        if (overlay != null) overlay,
      ],
    );

    if (onTap != null) {
      card = InkWell(onTap: onTap, borderRadius: borderRadius, child: card);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: card),
    );
  }
}
