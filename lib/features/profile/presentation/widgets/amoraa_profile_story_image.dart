import 'dart:convert';
import 'dart:math' as math;

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:flutter/material.dart';

class AmoraaProfileStoryImage extends StatefulWidget {
  const AmoraaProfileStoryImage({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.initials = 'AM',
    this.aspectRatio,
    this.photo,
  });

  final String image;
  final String semanticLabel;
  final String initials;
  final ProfilePhotoViewData? photo;

  /// Optional known ratio, primarily useful when image metadata is already
  /// available. Otherwise the widget resolves the existing image provider.
  final double? aspectRatio;

  static const double minimumAspectRatio = 4 / 5;
  static const double maximumAspectRatio = 16 / 9;
  static const double maximumWidth = 720;
  static const double maximumHeight = 560;

  @override
  State<AmoraaProfileStoryImage> createState() =>
      _AmoraaProfileStoryImageState();
}

class _AmoraaProfileStoryImageState extends State<AmoraaProfileStoryImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double _resolvedRatio = AmoraaProfileStoryImage.minimumAspectRatio;

  double get _safeRatio => (widget.aspectRatio ?? _resolvedRatio).clamp(
    AmoraaProfileStoryImage.minimumAspectRatio,
    AmoraaProfileStoryImage.maximumAspectRatio,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.aspectRatio == null) _resolveRatio();
  }

  @override
  void didUpdateWidget(covariant AmoraaProfileStoryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image ||
        oldWidget.photo?.bytes != widget.photo?.bytes ||
        oldWidget.photo?.source != widget.photo?.source ||
        oldWidget.aspectRatio != widget.aspectRatio) {
      _removeListener();
      _resolvedRatio = AmoraaProfileStoryImage.minimumAspectRatio;
      if (widget.aspectRatio == null) _resolveRatio();
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.min(
          constraints.maxWidth,
          AmoraaProfileStoryImage.maximumWidth,
        );
        final width = math.min(
          availableWidth,
          AmoraaProfileStoryImage.maximumHeight * _safeRatio,
        );
        return Align(
          alignment: Alignment.center,
          child: AnimatedContainer(
            key: const ValueKey('adaptive-profile-story-image'),
            width: width,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AspectRatio(
              aspectRatio: _safeRatio,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: .60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: .10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AmoraaProfilePhotoView(
                    photo:
                        widget.photo ??
                        ProfilePhotoViewData(
                          id: 'profile-story-${widget.image.hashCode}',
                          source: widget.image,
                          order: 0,
                          isPrimary: false,
                          uploadState: ProfilePhotoUploadState.bundled,
                        ),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.12),
                    borderRadius: BorderRadius.circular(24),
                    semanticLabel: widget.semanticLabel,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _resolveRatio() {
    final provider = _providerFor(widget.photo, widget.image);
    if (provider == null) return;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((image, _) {
      final width = image.image.width;
      final height = image.image.height;
      if (!mounted || width <= 0 || height <= 0) return;
      final nextRatio = width / height;
      if ((_resolvedRatio - nextRatio).abs() < .001) return;
      setState(() => _resolvedRatio = nextRatio);
    }, onError: (_, _) {});
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  ImageProvider<Object>? _providerFor(
    ProfilePhotoViewData? photo,
    String source,
  ) {
    if (photo?.bytes case final bytes? when bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
    final value = (photo?.source ?? source).trim();
    if (value.startsWith('data:image/')) {
      final comma = value.indexOf(',');
      if (comma < 0) return null;
      try {
        return MemoryImage(base64Decode(value.substring(comma + 1)));
      } on FormatException {
        return null;
      }
    }
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:')) {
      return NetworkImage(value);
    }
    return AssetImage(
      AppImages.resolveAsset(value, fallback: AppImages.fallbackProfile),
    );
  }

  void _removeListener() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }
}
