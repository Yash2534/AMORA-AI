import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({
    super.key,
    this.mediaPicker = const DeviceAmoraMediaPicker(),
  });

  static const routeName = '/photo-manager';

  final AmoraMediaPicker mediaPicker;

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  late List<String> _photos;
  late int _primary;
  bool _picking = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final profile = LocalProfileRepository.instance.profile;
    _photos = List<String>.of(profile.photos);
    _primary = profile.primaryPhotoIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
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
                          '${_photos.length} of 6 photos',
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
                  SizedBox(
                    key: const ValueKey('horizontal-photo-gallery'),
                    height: 206,
                    child: Row(
                      children: [
                        if (_photos.length < 6) ...[
                          SizedBox(
                            key: const ValueKey('add-photo-card'),
                            width: 112,
                            child: _AddPhotoTile(
                              onTap: _picking ? null : _addPhoto,
                              loading: _picking,
                            ),
                          ),
                          const SizedBox(width: AmoraSpacing.space12),
                        ],
                        Expanded(
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            buildDefaultDragHandles: false,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _photos.length,
                            onReorderItem: _reorder,
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, _) => Transform.scale(
                                  scale: 1 + animation.value * .04,
                                  child: Material(
                                    color: AppColors.transparent,
                                    elevation: animation.value * 8,
                                    borderRadius: AmoraRadius.card,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              return Padding(
                                key: ValueKey('photo-$photo'),
                                padding: const EdgeInsets.only(
                                  right: AmoraSpacing.space12,
                                ),
                                child: SizedBox(
                                  width: 144,
                                  child: _PhotoTile(
                                    index: index,
                                    photo: photo,
                                    primary: _primary == index,
                                    onPrimary: () =>
                                        setState(() => _primary = index),
                                    onDelete: () => _delete(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
    if (_photos.length >= 6) return _snack('Maximum 6 photos allowed');
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
              Text('Add a profile photo', style: AmoraTextStyles.headlineSmall),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                'Choose a clear JPEG, PNG, WebP, HEIC, or HEIF image up to 12 MB.',
                style: AmoraTextStyles.bodyMedium,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                subtitle: const Text('Camera permission is requested next'),
                onTap: () => Navigator.of(context).pop(AmoraMediaSource.camera),
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
    await _pickPhoto(source);
  }

  Future<void> _pickPhoto(AmoraMediaSource source) async {
    setState(() => _picking = true);
    final result = await widget.mediaPicker.pickImage(source: source);
    if (!mounted) return;
    setState(() => _picking = false);

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
    setState(() {
      _photos.add(media.dataUri);
      if (_photos.length == 1) _primary = 0;
    });
    _snack('Photo added. Save changes to keep it.');
  }

  void _delete(int index) {
    setState(() {
      _photos.removeAt(index);
      if (_photos.isEmpty) {
        _primary = 0;
      } else if (index < _primary) {
        _primary--;
      } else if (index == _primary) {
        _primary = index.clamp(0, _photos.length - 1).toInt();
      } else {
        _primary = _primary.clamp(0, _photos.length - 1).toInt();
      }
    });
    _snack('Photo removed');
  }

  void _reorder(int oldIndex, int newIndex) {
    if (oldIndex >= _photos.length) return;
    if (newIndex > _photos.length) newIndex = _photos.length;
    if (oldIndex == newIndex) return;
    setState(() {
      final primaryPhoto = _photos[_primary];
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
      _primary = _photos.indexOf(primaryPhoto);
      if (_primary < 0) {
        _primary = 0;
      }
    });
    _snack('Photo order updated');
  }

  Future<void> _saveChanges() async {
    if (_photos.length < 2) {
      _snack('Add at least two profile photos before saving');
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await LocalProfileRepository.instance.updatePhotosPersisted(
        _photos,
        _primary,
      );
      if (!mounted) return;
      AmoraSession.completeProfileStep(40);
      _snack('Photo changes saved on this device');
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

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.index,
    required this.photo,
    required this.primary,
    required this.onPrimary,
    required this.onDelete,
  });

  final int index;
  final String photo;
  final bool primary;
  final VoidCallback onPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AmoraProfileImage(
            imageUrl: photo,
            assetPath: photo,
            initials: 'AM',
            borderRadius: AmoraRadius.card,
            semanticLabel: primary ? 'Primary profile photo' : 'Profile photo',
          ),
        ),
        Positioned(
          left: 6,
          top: 6,
          child: ActionChip(
            label: Text(primary ? 'Primary' : 'Set'),
            onPressed: onPrimary,
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const SizedBox.square(
                  dimension: 42,
                  child: Icon(Icons.drag_indicator_rounded, size: 20),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap, required this.loading});

  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
              ? const CircularProgressIndicator()
              : const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppColors.primaryPurple,
                  size: AmoraIconSizes.large,
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
