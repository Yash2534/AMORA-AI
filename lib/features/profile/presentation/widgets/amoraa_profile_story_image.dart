import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_adaptive_image.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

class AmoraaProfileStoryImage extends StatelessWidget {
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
  final double? aspectRatio;

  static const double minimumAspectRatio =
      AmoraaAdaptiveImage.minimumAdaptiveRatio;
  static const double maximumAspectRatio =
      AmoraaAdaptiveImage.maximumAdaptiveRatio;
  static const double maximumWidth = 720;
  static const double minimumHeight = 180;
  static const double maximumHeight = 560;

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    final source = currentPhoto?.source ?? image;
    final stateLabel = switch (currentPhoto?.uploadState) {
      ProfilePhotoUploadState.uploading => ', uploading',
      ProfilePhotoUploadState.failed => ', upload failed',
      ProfilePhotoUploadState.localOnly => ', stored on this device',
      ProfilePhotoUploadState.deleting => ', deleting',
      _ => '',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .60)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AmoraaAdaptiveImage(
        key: const ValueKey('adaptive-profile-story-image'),
        source: source,
        assetPath: source,
        bytes: currentPhoto?.bytes,
        fallbackAsset: AppImages.fallbackProfile,
        initials: initials,
        aspectMode: AmoraaImageAspectMode.adaptive,
        originalAspectRatio: aspectRatio,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.12),
        borderRadius: BorderRadius.circular(24),
        maxWidth: maximumWidth,
        minHeight: minimumHeight,
        maxHeight: maximumHeight,
        semanticLabel:
            '$semanticLabel${currentPhoto?.isPrimary == true ? ', primary' : ''}$stateLabel',
        overlay: currentPhoto == null
            ? null
            : _StoryTransferOverlay(photo: currentPhoto),
      ),
    );
  }
}

class _StoryTransferOverlay extends StatelessWidget {
  const _StoryTransferOverlay({required this.photo});

  final ProfilePhotoViewData photo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photo.uploadState == ProfilePhotoUploadState.uploading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        if (photo.uploadState == ProfilePhotoUploadState.failed)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: AppColors.surface.withValues(alpha: .94),
              padding: const EdgeInsets.all(AmoraSpacing.space8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AmoraSpacing.space4),
                  Flexible(
                    child: Text(
                      photo.errorMessage ?? 'Upload failed',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
