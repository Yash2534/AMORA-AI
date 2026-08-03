import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

class AmoraaProfilePhotoView extends StatelessWidget {
  const AmoraaProfilePhotoView({
    super.key,
    required this.photo,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.alignment = const Alignment(0, -0.12),
    this.borderRadius = BorderRadius.zero,
    this.width,
    this.height,
    this.showTransferState = true,
    this.onRetry,
  });

  final ProfilePhotoViewData photo;
  final String semanticLabel;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius borderRadius;
  final double? width;
  final double? height;
  final bool showTransferState;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final stateLabel = switch (photo.uploadState) {
      ProfilePhotoUploadState.uploading => ', uploading',
      ProfilePhotoUploadState.failed => ', upload failed',
      ProfilePhotoUploadState.localOnly => ', stored on this device',
      ProfilePhotoUploadState.deleting => ', deleting',
      _ => '',
    };
    final content = Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) => AmoraProfileImage(
              imageUrl: photo.source,
              assetPath: photo.source,
              memoryBytes: photo.bytes,
              initials: 'AM',
              fit: fit,
              alignment: alignment,
              borderRadius: borderRadius,
              width:
                  width ??
                  (constraints.hasBoundedWidth ? constraints.maxWidth : null),
              height:
                  height ??
                  (constraints.hasBoundedHeight ? constraints.maxHeight : null),
              semanticLabel: semanticLabel,
            ),
          ),
        ),
        if (showTransferState &&
            photo.uploadState == ProfilePhotoUploadState.uploading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        if (showTransferState &&
            photo.uploadState == ProfilePhotoUploadState.failed)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: AppColors.surface.withValues(alpha: .94),
              padding: const EdgeInsets.all(AmoraSpacing.space8),
              child: onRetry == null
                  ? Row(
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
                    )
                  : SizedBox(
                      height: AmoraSpacing.minimumTouchTarget,
                      child: TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ),
            ),
          ),
      ],
    );
    return Semantics(
      container: true,
      image: true,
      label: '$semanticLabel${photo.isPrimary ? ', primary' : ''}$stateLabel',
      child: width == null && height == null
          ? content
          : SizedBox(width: width, height: height, child: content),
    );
  }
}
