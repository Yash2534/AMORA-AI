import 'package:flutter/material.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';

class PremiumAssetImage extends StatelessWidget {
  const PremiumAssetImage({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.initials,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final String imageUrl;
  final String fallbackAsset;
  final String initials;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width == null
        ? null
        : (width! * devicePixelRatio).round();
    final cacheHeight = height == null
        ? null
        : (height! * devicePixelRatio).round();

    return PremiumImage.asset(
      assetPath: imageUrl,
      fallbackAsset: fallbackAsset,
      initials: initials,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      borderRadius: borderRadius,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}
