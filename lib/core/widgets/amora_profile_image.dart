import 'dart:typed_data';

import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/core/widgets/profile_photo_file_provider_stub.dart'
    if (dart.library.io) 'package:amora_ai/core/widgets/profile_photo_file_provider_io.dart';
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

    final source = assetPath.trim().isNotEmpty ? assetPath : imageUrl;
    final localProvider = memoryBytes == null
        ? localProfilePhotoFileProvider(source)
        : null;
    final fallback = PremiumImage(
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
    );
    final image = memoryBytes != null || localProvider != null
        ? ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Image(
              image: memoryBytes != null
                  ? MemoryImage(memoryBytes!)
                  : localProvider!,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => fallback,
            ),
          )
        : fallback;

    return Semantics(
      image: true,
      label: semanticLabel ?? 'Profile photo',
      child: ExcludeSemantics(child: image),
    );
  }
}
