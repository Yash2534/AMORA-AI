import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/image_fallback.dart';
import 'package:flutter/material.dart';

class PremiumImage extends StatefulWidget {
  const PremiumImage({
    super.key,
    this.imageUrl,
    this.assetPath,
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
       );

  final String? imageUrl;
  final String? assetPath;
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

  @override
  State<PremiumImage> createState() => _PremiumImageState();
}

class _PremiumImageState extends State<PremiumImage> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    Widget image = ClipRRect(
      borderRadius: widget.borderRadius,
      child: _buildImage(),
    );

    image = RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(key: ValueKey(_retryKey), child: image),
      ),
    );

    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }

    return image;
  }

  Widget _buildImage() {
    final assetPath = AppImages.resolveAsset(
      widget.assetPath ?? widget.imageUrl,
      fallback: widget.fallbackAsset,
    );

    return Image.asset(
      assetPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      frameBuilder: _fadeFrame,
      errorBuilder: (_, _, _) => _fallbackAsset(),
    );
  }

  Widget _fallbackAsset() {
    final fallback = AppImages.resolveAsset(
      widget.fallbackAsset,
      fallback: AppImages.defaultAvatar,
    );
    return Image.asset(
      fallback,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      frameBuilder: _fadeFrame,
      errorBuilder: (_, _, _) =>
          _gradientFallback(showRetry: widget.enableRetry),
    );
  }

  Widget _fadeFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _gradientFallback({required bool showRetry}) {
    final fallback = ImageFallback(
      initials: widget.initials,
      width: widget.width,
      height: widget.height,
      showRetry: showRetry,
    );
    if (!showRetry || !widget.enableRetry) return fallback;
    return Material(
      color: AppColors.transparent,
      child: InkWell(onTap: () => setState(() => _retryKey++), child: fallback),
    );
  }
}
