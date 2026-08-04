import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef ProfilePhotoCropRenderer = Future<String> Function(GlobalKey cropKey);
typedef ProfilePhotoUploader = Future<String> Function(String localSource);

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({
    super.key,
    this.mediaPicker = const DeviceAmoraMediaPicker(),
    this.cropPreviewRenderer,
    this.photoUploader,
    this.openPickerOnStart = false,
  });

  static const routeName = '/photo-manager';

  final AmoraMediaPicker mediaPicker;
  final ProfilePhotoCropRenderer? cropPreviewRenderer;
  final ProfilePhotoUploader? photoUploader;
  final bool openPickerOnStart;

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  final _repository = LocalProfileRepository.instance;
  bool _picking = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    if (widget.openPickerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addPhoto();
      });
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final photos = _repository.currentPhotos;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 820,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${photos.length} of 6 photos',
                          style: AmoraTextStyles.titleMedium,
                        ),
                      ),
                      const Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AmoraSpacing.space4),
                      Text(
                        'Drag to reorder',
                        style: AmoraTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AmoraSpacing.space12),
                  _PhotoGrid(
                    key: const ValueKey('profile-photo-grid'),
                    photos: photos,
                    showAddTile: photos.length < 6,
                    adding: _picking,
                    onAdd: _picking ? null : _addPhoto,
                    onOpen: _openPreview,
                    onPrimary: _repository.setPrimaryPhotoInSession,
                    onDelete: _delete,
                    onRetry: _retryUpload,
                    onReorder: _repository.reorderPhotosInSession,
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  const PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photo guidance',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AmoraSpacing.space12),
                        _Tip('Use one clear face photo as primary.'),
                        _Tip(
                          'Add a warm smile, a portrait, and an outdoor moment.',
                        ),
                        _Tip(
                          'Use travel or hobby photos to make your story specific.',
                        ),
                        _Tip(
                          'Avoid screenshots, heavy filters, or repeated photos.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  if (_saveError != null) ...[
                    Text(
                      _saveError!,
                      textAlign: TextAlign.center,
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space8),
                  ],
                  AppPrimaryButton(
                    label: 'Save Changes',
                    icon: AmoraIcons.check,
                    isLoading: _saving,
                    onPressed: _saving ? null : _saveChanges,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    if (_picking) return;
    if (_repository.profile.photos.length >= 6) {
      return _snack('Maximum 6 photos allowed');
    }
    setState(() => _picking = true);
    try {
      final source = await showModalBottomSheet<AmoraMediaSource>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add a profile photo',
                  style: AmoraTextStyles.headlineSmall,
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Text(
                  'Choose a clear JPEG, PNG, or WebP image up to 12 MB.',
                  style: AmoraTextStyles.bodyMedium,
                ),
                const SizedBox(height: AmoraSpacing.space16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take a photo'),
                  subtitle: const Text('Camera permission is requested next'),
                  onTap: () =>
                      Navigator.of(context).pop(AmoraMediaSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from photo library'),
                  subtitle: const Text('Select an existing photo'),
                  onTap: () =>
                      Navigator.of(context).pop(AmoraMediaSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || source == null) return;
      await _performPick(source);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickPhoto(AmoraMediaSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      await _performPick(source);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _performPick(AmoraMediaSource source) async {
    final result = await widget.mediaPicker.pickImage(source: source);
    if (!mounted) return;

    final media = result.media;
    if (media == null) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: () => _pickPhoto(source),
      );
      return;
    }
    final selectedBytes = media.bytes;
    final selectedMimeType = AmoraImageValidation.supportedMimeType(
      selectedBytes,
    );
    if (selectedBytes.isEmpty ||
        selectedMimeType == null ||
        selectedMimeType != media.mimeType) {
      _snack('That photo could not be read. Choose another image.');
      return;
    }
    final croppedPhoto = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ProfilePhotoCropPreviewScreen(
          sourceDataUri: media.dataUri,
          sourceBytes: selectedBytes,
          previewRenderer: widget.cropPreviewRenderer,
        ),
      ),
    );
    if (!mounted || croppedPhoto == null) return;
    final croppedBytes = _decodeDataUri(croppedPhoto);
    final croppedMimeType = croppedBytes == null
        ? null
        : AmoraImageValidation.supportedMimeType(croppedBytes);
    if (croppedBytes == null ||
        croppedMimeType == null ||
        croppedBytes.lengthInBytes > DeviceAmoraMediaPicker.maximumImageBytes) {
      _snack('The prepared photo is invalid. Please choose another image.');
      return;
    }
    final uploadState = widget.photoUploader == null
        ? ProfilePhotoUploadState.localOnly
        : ProfilePhotoUploadState.uploading;
    _repository.addPhotoInSession(
      croppedPhoto,
      uploadState: uploadState,
      bytes: croppedBytes,
      mimeType: croppedMimeType,
    );
    _snack('Photo added to your profile.');
    if (widget.photoUploader != null) {
      unawaited(_uploadPhoto(croppedPhoto));
    }
  }

  void _delete(int index) {
    _repository.removePhotoInSession(index);
    _snack('Photo removed');
  }

  Future<void> _uploadPhoto(String localSource) async {
    final uploader = widget.photoUploader;
    if (uploader == null) return;
    _repository.setPhotoUploadState(
      localSource,
      ProfilePhotoUploadState.uploading,
    );
    try {
      final remoteUrl = await uploader(localSource);
      if (!_validRemoteUrl(remoteUrl)) {
        throw StateError('The upload returned no photo URL');
      }
      _repository.replacePhotoSourceInSession(localSource, remoteUrl);
      final profile = _repository.profile;
      await _repository.updatePhotosPersisted(
        profile.photos,
        profile.primaryPhotoIndex,
      );
    } catch (_) {
      _repository.setPhotoUploadState(
        localSource,
        ProfilePhotoUploadState.failed,
        errorMessage: 'Upload failed. Retry when you are ready.',
      );
      if (mounted) {
        _snack('Upload failed. Your local photo is still available.');
      }
    }
  }

  void _retryUpload(String source) {
    if (widget.photoUploader == null) return;
    unawaited(_uploadPhoto(source));
  }

  Future<void> _openPreview(int initialIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePhotoViewerScreen(
          photos: _repository.currentPhotos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final profile = _repository.profile;
    if (profile.photos.length < 2) {
      _snack('Add at least two profile photos before saving');
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await _repository.updatePhotosPersisted(
        profile.photos,
        profile.primaryPhotoIndex,
      );
      if (!mounted) return;
      AmoraSession.completeProfileStep(40);
      final hasSessionOnlyPhoto = _repository.currentPhotos.any(
        (photo) => photo.isLocal,
      );
      _snack(
        hasSessionOnlyPhoto
            ? 'Photo changes are available for this session. Upload is unavailable.'
            : 'Photo changes saved on this device',
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Could not save photo changes. Please try again.';
      });
    }
  }

  void _snack(String message) {
    showAmoraSnackBar(context, message: message);
  }

  bool _validRemoteUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(AmoraIcons.back),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photo Manager',
                style: AmoraTextStyles.headlineSmall.copyWith(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Choose clear photos that represent you.',
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    super.key,
    required this.photos,
    required this.showAddTile,
    required this.adding,
    required this.onAdd,
    required this.onOpen,
    required this.onPrimary,
    required this.onDelete,
    required this.onRetry,
    required this.onReorder,
  });

  final List<ProfilePhotoViewData> photos;
  final bool showAddTile;
  final bool adding;
  final VoidCallback? onAdd;
  final ValueChanged<int> onOpen;
  final ValueChanged<int> onPrimary;
  final ValueChanged<int> onDelete;
  final ValueChanged<String> onRetry;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final spacing = AmoraSpacing.space12;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 4 / 5,
          ),
          itemCount: photos.length + (showAddTile ? 1 : 0),
          itemBuilder: (context, index) {
            if (showAddTile && index == photos.length) {
              return _AddPhotoTile(
                key: const ValueKey('add-photo-card'),
                onTap: onAdd,
                loading: adding,
              );
            }
            final photo = photos[index];
            final tile = _PhotoTile(
              key: ValueKey(photo.id),
              photo: photo,
              onOpen: () => onOpen(index),
              onPrimary: () => onPrimary(index),
              onDelete: () => onDelete(index),
              onRetry: () => onRetry(photo.source),
            );
            return DragTarget<String>(
              onWillAcceptWithDetails: (details) => details.data != photo.id,
              onAcceptWithDetails: (details) {
                final oldIndex = photos.indexWhere(
                  (candidate) => candidate.id == details.data,
                );
                if (oldIndex >= 0) onReorder(oldIndex, index);
              },
              builder: (context, candidates, _) => AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: AmoraRadius.card,
                  border: candidates.isEmpty
                      ? null
                      : Border.all(color: AppColors.secondary, width: 2),
                ),
                child: LongPressDraggable<String>(
                  data: photo.id,
                  feedback: Material(
                    color: AppColors.transparent,
                    elevation: 8,
                    borderRadius: AmoraRadius.card,
                    child: SizedBox(
                      width: tileWidth,
                      height: tileWidth / (4 / 5),
                      child: _PhotoTile(
                        photo: photo,
                        onOpen: () {},
                        onPrimary: () {},
                        onDelete: () {},
                        onRetry: () {},
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: .35, child: tile),
                  child: tile,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.onOpen,
    required this.onPrimary,
    required this.onDelete,
    required this.onRetry,
  });

  final ProfilePhotoViewData photo;
  final VoidCallback onOpen;
  final VoidCallback onPrimary;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = switch (photo.uploadState) {
      ProfilePhotoUploadState.uploading => 'uploading',
      ProfilePhotoUploadState.failed => 'upload failed',
      _ => 'ready',
    };
    final statusBadge = photo.isPrimary
        ? (Icons.star_rounded, 'Primary')
        : switch (photo.uploadState) {
            ProfilePhotoUploadState.uploading => (
              Icons.cloud_upload_rounded,
              'Uploading',
            ),
            ProfilePhotoUploadState.failed => (
              Icons.error_outline_rounded,
              'Failed',
            ),
            ProfilePhotoUploadState.localOnly => null,
            _ => (Icons.check_rounded, 'Ready'),
          };
    return Semantics(
      button: true,
      label:
          'Profile photo ${photo.order + 1}, ${photo.isPrimary ? 'primary, ' : ''}$status',
      child: Material(
        color: AppColors.surface,
        borderRadius: AmoraRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AmoraaProfilePhotoView(
                photo: photo,
                fit: BoxFit.cover,
                borderRadius: AmoraRadius.card,
                semanticLabel: 'Profile photo ${photo.order + 1}',
                showTransferState: false,
              ),
              if (photo.uploadState == ProfilePhotoUploadState.uploading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (statusBadge case (final icon, final label))
                Positioned(
                  left: AmoraSpacing.space8,
                  top: AmoraSpacing.space8,
                  child: _PhotoStatusBadge(icon: icon, label: label),
                ),
              Positioned(
                right: 2,
                top: 2,
                child: IconButton.filledTonal(
                  tooltip: photo.isPrimary
                      ? 'Primary photo'
                      : 'Set as primary photo',
                  onPressed: photo.isPrimary ? null : onPrimary,
                  icon: Icon(
                    photo.isPrimary
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 19,
                  ),
                ),
              ),
              Positioned(
                left: 2,
                bottom: 2,
                child: const SizedBox.square(
                  dimension: 48,
                  child: Icon(Icons.drag_indicator_rounded, size: 21),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: IconButton.filledTonal(
                  tooltip: 'Delete photo',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
              ),
              if (photo.uploadState == ProfilePhotoUploadState.failed)
                Positioned(
                  left: AmoraSpacing.space8,
                  right: AmoraSpacing.space8,
                  bottom: 50,
                  child: FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoStatusBadge extends StatelessWidget {
  const _PhotoStatusBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: AmoraTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({super.key, required this.onTap, required this.loading});

  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: loading ? 'Selecting profile photo' : 'Add profile photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: AmoraRadius.card,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AmoraRadius.card,
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Center(
            child: loading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.primaryPurple,
                        size: AmoraIconSizes.large,
                      ),
                      SizedBox(height: AmoraSpacing.space8),
                      Text(
                        'Opening picker...',
                        textAlign: TextAlign.center,
                        style: AmoraTextStyles.labelSmall,
                      ),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primaryPurple,
                        size: AmoraIconSizes.large,
                      ),
                      SizedBox(height: AmoraSpacing.space8),
                      Text(
                        'Add photo',
                        textAlign: TextAlign.center,
                        style: AmoraTextStyles.labelMedium,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AmoraSpacing.space8),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.successGreen,
          size: AmoraIconSizes.medium,
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class ProfilePhotoViewerScreen extends StatefulWidget {
  const ProfilePhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  final List<ProfilePhotoViewData> photos;
  final int initialIndex;

  @override
  State<ProfilePhotoViewerScreen> createState() =>
      _ProfilePhotoViewerScreenState();
}

class _ProfilePhotoViewerScreenState extends State<ProfilePhotoViewerScreen> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      key: const ValueKey('photo-full-preview'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('photo-preview-close'),
          tooltip: 'Close photo preview',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text('${_index + 1} of ${widget.photos.length}'),
      ),
      body: SafeArea(
        top: false,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                _move(-1, reduceMotion),
            const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                _move(1, reduceMotion),
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.photos.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final photo = widget.photos[index];
                    return Padding(
                      padding: const EdgeInsets.all(AmoraSpacing.space20),
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: AmoraaProfilePhotoView(
                            key: ValueKey('photo-preview-${photo.id}'),
                            photo: photo,
                            fit: BoxFit.contain,
                            semanticLabel:
                                'Full profile photo ${index + 1}${photo.isPrimary ? ', primary' : ''}',
                            showTransferState: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (widget.photos.length > 1) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      tooltip: 'Previous photo',
                      onPressed: _index == 0
                          ? null
                          : () => _move(-1, reduceMotion),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: 'Next photo',
                      onPressed: _index == widget.photos.length - 1
                          ? null
                          : () => _move(1, reduceMotion),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _move(int delta, bool reduceMotion) {
    final next = (_index + delta).clamp(0, widget.photos.length - 1);
    if (next == _index) return;
    _pageController.animateToPage(
      next,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }
}

class ProfilePhotoCropPreviewScreen extends StatefulWidget {
  const ProfilePhotoCropPreviewScreen({
    super.key,
    required this.sourceDataUri,
    required this.sourceBytes,
    this.previewRenderer,
  });

  final String sourceDataUri;
  final Uint8List sourceBytes;
  final ProfilePhotoCropRenderer? previewRenderer;

  @override
  State<ProfilePhotoCropPreviewScreen> createState() =>
      _ProfilePhotoCropPreviewScreenState();
}

class _ProfilePhotoCropPreviewScreenState
    extends State<ProfilePhotoCropPreviewScreen> {
  static const _cropRatio = 4 / 5;
  final _captureKey = GlobalKey();
  final _transformationController = TransformationController();
  late final Uint8List _sourceBytes;
  bool _usingPhoto = false;

  @override
  void initState() {
    super.initState();
    _sourceBytes = Uint8List.fromList(widget.sourceBytes);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cancel photo crop',
          onPressed: _usingPhoto ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: const AmoraScreenTitle(
          title: 'Crop Photo',
          subtitle: 'Drag and zoom to frame your profile',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space16,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CropCanvas(
                    key: const ValueKey('photo-crop-canvas'),
                    captureKey: _captureKey,
                    sourceDataUri: widget.sourceDataUri,
                    sourceBytes: _sourceBytes,
                    transformationController: _transformationController,
                    aspectRatio: _cropRatio,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                Text(
                  'Use two fingers or the mouse wheel to zoom. Drag to reposition.',
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                AppPrimaryButton(
                  key: const ValueKey('photo-crop-use-button'),
                  label: _usingPhoto ? 'Preparing Photo' : 'Use Photo',
                  icon: Icons.check_rounded,
                  isLoading: _usingPhoto,
                  onPressed: _usingPhoto ? null : _usePhoto,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _usePhoto() async {
    setState(() => _usingPhoto = true);
    try {
      if (widget.previewRenderer case final renderer?) {
        final result = await renderer(_captureKey);
        if (!mounted) return;
        final renderedBytes = _decodeDataUri(result);
        if (renderedBytes == null ||
            AmoraImageValidation.supportedMimeType(renderedBytes) == null ||
            renderedBytes.lengthInBytes >
                DeviceAmoraMediaPicker.maximumImageBytes) {
          throw StateError('The prepared photo is invalid');
        }
        Navigator.of(context).pop(result);
        return;
      }
      if (_sourceBytes.isEmpty ||
          AmoraImageValidation.supportedMimeType(_sourceBytes) == null) {
        throw StateError('The selected photo is invalid');
      }
      await precacheImage(MemoryImage(_sourceBytes), context);
      if (!mounted) return;
      final deviceRatio = MediaQuery.devicePixelRatioOf(context);
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Crop preview is not ready');
      }
      final image = await boundary.toImage(
        pixelRatio: math.min(deviceRatio, 2.0),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw StateError('Crop preview could not be read');
      final bytes = byteData.buffer.asUint8List();
      if (!mounted) return;
      Navigator.of(context).pop('data:image/png;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _usingPhoto = false);
      showAmoraSnackBar(
        context,
        message: 'The photo could not be prepared. Please try again.',
      );
    }
  }
}

class _CropCanvas extends StatelessWidget {
  const _CropCanvas({
    super.key,
    required this.captureKey,
    required this.sourceDataUri,
    required this.sourceBytes,
    required this.transformationController,
    required this.aspectRatio,
  });

  final GlobalKey captureKey;
  final String sourceDataUri;
  final Uint8List sourceBytes;
  final TransformationController transformationController;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final photo = ProfilePhotoViewData(
      id: 'crop-photo',
      source: sourceDataUri,
      order: 0,
      isPrimary: false,
      uploadState: ProfilePhotoUploadState.localOnly,
      bytes: sourceBytes,
      mimeType: AmoraImageValidation.supportedMimeType(sourceBytes),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          math.min(constraints.maxWidth, 440.0),
          constraints.maxHeight * aspectRatio,
        );
        final height = width / aspectRatio;
        return Center(
          child: RepaintBoundary(
            key: captureKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: width,
                height: height,
                child: InteractiveViewer(
                  transformationController: transformationController,
                  minScale: 1,
                  maxScale: 4,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.hardEdge,
                  child: AmoraaProfilePhotoView(
                    photo: photo,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.zero,
                    semanticLabel: 'Adjustable profile photo crop',
                    showTransferState: false,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Uint8List? _decodeDataUri(String value) {
  final source = value.trim();
  if (!source.startsWith('data:image/')) return null;
  final comma = source.indexOf(',');
  if (comma < 0 || comma == source.length - 1) return null;
  try {
    final bytes = base64Decode(source.substring(comma + 1));
    return bytes.isEmpty ? null : bytes;
  } on FormatException {
    return null;
  }
}
