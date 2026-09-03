import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/image_fallback.dart';
import 'package:amora_ai/core/widgets/profile_photo_file_provider_stub.dart'
    if (dart.library.io) 'package:amora_ai/core/widgets/profile_photo_file_provider_io.dart';
import 'package:flutter/material.dart';

enum AmoraaImageAspectMode { free, portrait, square, event, adaptive }

/// Card-first image renderer shared by profile, event, avatar, local-photo,
/// and editorial surfaces.
///
/// Source priority is bytes, data URI, remote URL, mobile file, explicit
/// provider, asset, and finally the approved fallback asset.
class AmoraaAdaptiveImage extends StatefulWidget {
  const AmoraaAdaptiveImage({
    super.key,
    this.source,
    this.assetPath,
    this.bytes,
    this.imageProvider,
    this.fallbackAsset = AppImages.fallbackProfile,
    this.initials = 'AM',
    this.aspectMode = AmoraaImageAspectMode.free,
    this.originalAspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = BorderRadius.zero,
    this.width,
    this.height,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.cacheWidth,
    this.cacheHeight,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.enableRetry = true,
    this.overlay,
  });

  static const double minimumAdaptiveRatio = .72;
  static const double maximumAdaptiveRatio = 1.78;

  final String? source;
  final String? assetPath;
  final Uint8List? bytes;
  final ImageProvider<Object>? imageProvider;
  final String fallbackAsset;
  final String initials;
  final AmoraaImageAspectMode aspectMode;
  final double? originalAspectRatio;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final int? cacheWidth;
  final int? cacheHeight;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final bool enableRetry;
  final Widget? overlay;

  @override
  State<AmoraaAdaptiveImage> createState() => _AmoraaAdaptiveImageState();
}

class _AmoraaAdaptiveImageState extends State<AmoraaAdaptiveImage> {
  ImageStream? _ratioStream;
  ImageStreamListener? _ratioListener;
  double _resolvedRatio = 4 / 5;
  int _retryKey = 0;

  double get _displayRatio {
    final ratio = switch (widget.aspectMode) {
      AmoraaImageAspectMode.portrait => 4 / 5,
      AmoraaImageAspectMode.square => 1,
      AmoraaImageAspectMode.event => 16 / 9,
      AmoraaImageAspectMode.adaptive =>
        widget.originalAspectRatio ?? _resolvedRatio,
      AmoraaImageAspectMode.free => 1,
    };
    return widget.aspectMode == AmoraaImageAspectMode.adaptive
        ? ratio
              .clamp(
                AmoraaAdaptiveImage.minimumAdaptiveRatio,
                AmoraaAdaptiveImage.maximumAdaptiveRatio,
              )
              .toDouble()
        : ratio.toDouble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.aspectMode == AmoraaImageAspectMode.adaptive &&
        widget.originalAspectRatio == null &&
        !_isRemote(widget.source?.trim() ?? '')) {
      _resolveNaturalRatio();
    }
  }

  @override
  void didUpdateWidget(covariant AmoraaAdaptiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.assetPath != widget.assetPath ||
        !identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.imageProvider != widget.imageProvider ||
        oldWidget.aspectMode != widget.aspectMode ||
        oldWidget.originalAspectRatio != widget.originalAspectRatio) {
      _removeRatioListener();
      _resolvedRatio = 4 / 5;
      if (widget.aspectMode == AmoraaImageAspectMode.adaptive &&
          widget.originalAspectRatio == null &&
          !_isRemote(widget.source?.trim() ?? '')) {
        _resolveNaturalRatio();
      }
    }
  }

  @override
  void dispose() {
    _removeRatioListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            KeyedSubtree(
              key: ValueKey(_retryKey),
              child: _buildResolvedImage(context),
            ),
            ?widget.overlay,
          ],
        ),
      ),
    );

    if (widget.aspectMode == AmoraaImageAspectMode.free) {
      image = SizedBox(
        width: widget.width,
        height: widget.height,
        child: image,
      );
    } else {
      image = _AspectShell(
        ratio: _displayRatio,
        width: widget.width,
        height: widget.height,
        maxWidth: widget.maxWidth,
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
        child: image,
      );
    }

    if (widget.excludeFromSemantics) {
      return ExcludeSemantics(child: image);
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel ?? 'Image',
      child: ExcludeSemantics(child: image),
    );
  }

  Widget _buildResolvedImage(BuildContext context) {
    final provider = _providerForCurrentSource();
    if (provider == null) return _fallbackAsset();
    final resized = ResizeImage.resizeIfNeeded(
      widget.cacheWidth,
      widget.cacheHeight,
      provider,
    );
    return Image(
      image: resized,
      width: widget.aspectMode == AmoraaImageAspectMode.free
          ? widget.width
          : double.infinity,
      height: widget.aspectMode == AmoraaImageAspectMode.free
          ? widget.height
          : double.infinity,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return const ColoredBox(
          key: ValueKey('amoraa-image-loading'),
          color: AppColors.background,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 20,
              color: AppColors.tertiary,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _fallbackAsset(),
    );
  }

  ImageProvider<Object>? _providerForCurrentSource() {
    final bytes = widget.bytes;
    if (bytes != null && bytes.isNotEmpty) return MemoryImage(bytes);

    final source = widget.source?.trim() ?? '';
    final dataProvider = _dataUriProvider(source);
    if (dataProvider != null) return dataProvider;
    if (_isRemote(source)) return NetworkImage(source);

    final localProvider = localProfilePhotoFileProvider(source);
    if (localProvider != null) return localProvider;
    if (widget.imageProvider != null) return widget.imageProvider;

    final candidateAsset = widget.assetPath?.trim() ?? '';
    final asset = source.startsWith('assets/')
        ? source
        : candidateAsset.startsWith('assets/')
        ? candidateAsset
        : '';
    if (asset.isEmpty) return null;
    return AssetImage(
      AppImages.resolveAsset(asset, fallback: widget.fallbackAsset),
    );
  }

  ImageProvider<Object>? _dataUriProvider(String source) {
    if (!source.startsWith('data:image/')) return null;
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    try {
      final bytes = base64Decode(source.substring(comma + 1));
      return bytes.isEmpty ? null : MemoryImage(bytes);
    } on FormatException {
      return null;
    }
  }

  bool _isRemote(String source) =>
      source.startsWith('http://') ||
      source.startsWith('https://') ||
      source.startsWith('blob:');

  Widget _fallbackAsset() {
    final fallback = AppImages.resolveAsset(
      widget.fallbackAsset,
      fallback: AppImages.defaultAvatar,
    );
    return Image.asset(
      fallback,
      width: widget.aspectMode == AmoraaImageAspectMode.free
          ? widget.width
          : double.infinity,
      height: widget.aspectMode == AmoraaImageAspectMode.free
          ? widget.height
          : double.infinity,
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      errorBuilder: (_, _, _) => _gradientFallback(),
    );
  }

  Widget _gradientFallback() {
    final fallback = ImageFallback(
      initials: widget.initials,
      width: widget.width,
      height: widget.height,
      showRetry: widget.enableRetry,
    );
    if (!widget.enableRetry) return fallback;
    return Material(
      color: AppColors.transparent,
      child: InkWell(onTap: () => setState(() => _retryKey++), child: fallback),
    );
  }

  void _resolveNaturalRatio() {
    if (_ratioListener != null) return;
    final provider = _providerForCurrentSource();
    if (provider == null) return;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((image, _) {
      final width = image.image.width;
      final height = image.image.height;
      if (!mounted || width <= 0 || height <= 0) return;
      final ratio = width / height;
      if ((_resolvedRatio - ratio).abs() < .001) return;
      setState(() => _resolvedRatio = ratio);
    }, onError: (_, _) {});
    _ratioStream = stream;
    _ratioListener = listener;
    stream.addListener(listener);
  }

  void _removeRatioListener() {
    final listener = _ratioListener;
    if (listener != null) _ratioStream?.removeListener(listener);
    _ratioStream = null;
    _ratioListener = null;
  }
}

class _AspectShell extends StatelessWidget {
  const _AspectShell({
    required this.ratio,
    required this.child,
    this.width,
    this.height,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  final double ratio;
  final Widget child;
  final double? width;
  final double? height;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    if (width != null || height != null) {
      final requestedWidth = width ?? height! * ratio;
      final resolvedWidth = math
          .min(requestedWidth, maxWidth ?? double.infinity)
          .toDouble();
      final resolvedHeight = (height ?? resolvedWidth / ratio)
          .clamp(minHeight ?? 0, maxHeight ?? double.infinity)
          .toDouble();
      return Align(
        child: SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: child,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return AspectRatio(aspectRatio: ratio, child: child);
        }
        final resolvedWidth = math
            .min(constraints.maxWidth, maxWidth ?? constraints.maxWidth)
            .toDouble();
        final resolvedHeight = (resolvedWidth / ratio)
            .clamp(minHeight ?? 0, maxHeight ?? double.infinity)
            .toDouble();
        return Align(
          child: SizedBox(
            width: resolvedWidth,
            height: resolvedHeight,
            child: child,
          ),
        );
      },
    );
  }
}
