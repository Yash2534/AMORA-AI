import 'dart:typed_data';

import 'package:amora_ai/core/constants/app_images.dart';
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
    this.memoryBytes,
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
  final Uint8List? memoryBytes;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width == null
        ? null
        : (width! * devicePixelRatio).round();
    final cacheHeight = height == null
        ? null
        : (height! * devicePixelRatio).round();
    final fallbackAsset = assetPath.trim().startsWith('assets/')
        ? assetPath
        : AppImages.fallbackProfile;

    return PremiumImage(
      imageUrl: imageUrl,
      assetPath: assetPath,
      memoryBytes: memoryBytes,
      fallbackAsset: fallbackAsset,
      initials: initials,
      fit: fit,
      alignment: alignment,
      borderRadius: borderRadius ?? BorderRadius.zero,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      semanticLabel: semanticLabel ?? 'Profile photo',
    );
  }
}
