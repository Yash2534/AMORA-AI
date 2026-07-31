import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:flutter/material.dart';

class AmoraProfileImage extends StatelessWidget {
  const AmoraProfileImage({
    super.key,
    required this.imageUrl,
    required this.assetPath,
    required this.initials,
    this.fit = BoxFit.cover,
    this.alignment = const Alignment(0, -0.12),
    this.borderRadius,
    this.width,
    this.height,
    this.semanticLabel,
  });

  final String imageUrl;
  final String assetPath;
  final String initials;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width == null
        ? null
        : (width! * devicePixelRatio).round();
    final cacheHeight = height == null
        ? null
        : (height! * devicePixelRatio).round();

    return Semantics(
      image: true,
      label: semanticLabel ?? 'Profile photo',
      child: ExcludeSemantics(
        child: PremiumImage(
          imageUrl: imageUrl,
          assetPath: assetPath,
          fallbackAsset: assetPath,
          initials: initials,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          borderRadius: borderRadius ?? BorderRadius.zero,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
        ),
      ),
    );
  }
}
