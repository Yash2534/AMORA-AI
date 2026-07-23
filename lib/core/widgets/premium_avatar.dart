import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:flutter/material.dart';

enum AmoraAvatarSize { small, medium, large, extraLarge }

extension AmoraAvatarSizeValue on AmoraAvatarSize {
  double get radius => switch (this) {
    AmoraAvatarSize.small => 20,
    AmoraAvatarSize.medium => 28,
    AmoraAvatarSize.large => 36,
    AmoraAvatarSize.extraLarge => 48,
  };
}

class PremiumAvatar extends StatelessWidget {
  const PremiumAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.initials,
    this.radius,
    this.size = AmoraAvatarSize.medium,
    this.online = false,
    this.verified = false,
    this.goldRing = false,
    this.semanticLabel,
  });

  final String imageUrl;
  final String fallbackAsset;
  final String initials;
  final double? radius;
  final AmoraAvatarSize size;
  final bool online;
  final bool verified;
  final bool goldRing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? size.radius;
    final dimension = effectiveRadius * 2;
    final indicatorSize = (dimension * .24).clamp(12.0, 20.0);
    return Semantics(
      image: true,
      label: semanticLabel ?? '$initials profile photo',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: dimension,
            height: dimension,
            padding: EdgeInsets.all(goldRing ? 3 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goldRing ? AppColors.premium : AppColors.transparent,
            ),
            child: PremiumAssetImage(
              imageUrl: imageUrl,
              fallbackAsset: fallbackAsset,
              initials: initials,
              width: dimension,
              height: dimension,
              borderRadius: BorderRadius.circular(AmoraRadius.full),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: _AvatarIndicator(
                size: indicatorSize,
                color: AppColors.online,
              ),
            ),
          if (verified)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: indicatorSize,
                height: indicatorSize,
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: AmoraIconSizes.small,
                  color: AppColors.onInfo,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarIndicator extends StatelessWidget {
  const _AvatarIndicator({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.surface, width: 2),
    ),
  );
}
