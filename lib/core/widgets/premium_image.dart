import 'dart:typed_data';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/widgets/amoraa_adaptive_image.dart';
import 'package:flutter/material.dart';

/// Compatibility facade for existing call sites. All rendering is delegated
/// to the shared adaptive image system.
class PremiumImage extends StatelessWidget {
  const PremiumImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.memoryBytes,
    this.fallbackAsset = AppImages.fallbackProfile,
    this.initials = 'AM',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.heroTag,
    this.cacheWidth,
    this.cacheHeight,
    this.enableRetry = true,
    this.semanticLabel,
    this.aspectMode = AmoraaImageAspectMode.free,
    this.originalAspectRatio,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  const PremiumImage.asset({
    Key? key,
    required String assetPath,
    String fallbackAsset = AppImages.fallbackProfile,
    String initials = 'AM',
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(24)),
    Object? heroTag,
    int? cacheWidth,
    int? cacheHeight,
    bool enableRetry = true,
    String? semanticLabel,
    AmoraaImageAspectMode aspectMode = AmoraaImageAspectMode.free,
    double? originalAspectRatio,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) : this(
         key: key,
         assetPath: assetPath,
         fallbackAsset: fallbackAsset,
         initials: initials,
         width: width,
         height: height,
         fit: fit,
         alignment: alignment,
         borderRadius: borderRadius,
         heroTag: heroTag,
         cacheWidth: cacheWidth,
         cacheHeight: cacheHeight,
         enableRetry: enableRetry,
         semanticLabel: semanticLabel,
         aspectMode: aspectMode,
         originalAspectRatio: originalAspectRatio,
         maxWidth: maxWidth,
         minHeight: minHeight,
         maxHeight: maxHeight,
       );

  final String? imageUrl;
  final String? assetPath;
  final Uint8List? memoryBytes;
  final String fallbackAsset;
  final String initials;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius borderRadius;
  final Object? heroTag;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool enableRetry;
  final String? semanticLabel;
  final AmoraaImageAspectMode aspectMode;
  final double? originalAspectRatio;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    Widget image = AmoraaAdaptiveImage(
      source: imageUrl,
      assetPath: assetPath,
      bytes: memoryBytes,
      fallbackAsset: fallbackAsset,
      initials: initials,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      borderRadius: borderRadius,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      enableRetry: enableRetry,
      semanticLabel: semanticLabel,
      aspectMode: aspectMode,
      originalAspectRatio: originalAspectRatio,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return image;
  }
}
