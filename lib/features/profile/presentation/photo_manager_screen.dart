import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({super.key});

  static const routeName = '/photo-manager';

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  late List<String> _photos;
  late int _primary;

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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 560 ? 3 : 2,
                      mainAxisSpacing: AmoraSpacing.space12,
                      crossAxisSpacing: AmoraSpacing.space12,
                      childAspectRatio: .78,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= _photos.length) {
                        return _AddPhotoTile(onTap: _addPhoto);
                      }
                      return _PhotoTile(
                        photo: _photos[index],
                        primary: _primary == index,
                        onPrimary: () => setState(() => _primary = index),
                        onDelete: () => _delete(index),
                        onMove: () => _moveEarlier(index),
                      );
                    },
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI photo guidance',
                          style: AmoraTextStyles.titleLarge.copyWith(
                            color: AppColors.deepWine,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AmoraSpacing.space12),
                        _Tip(
                          'Best photo suggestion: your primary image has the strongest face clarity.',
                        ),
                        _Tip('Quality indicator: 92% profile-photo readiness.'),
                        _Tip(
                          'Face detection placeholder is ready for production ML integration.',
                        ),
                        _Tip('Use one clear face photo as primary.'),
                        _Tip('Add lifestyle photos: events, travel, hobbies.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  AppPrimaryButton(
                    label: 'Save Changes',
                    icon: AmoraIcons.check,
                    onPressed: _saveChanges,
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
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _LocalPhotoPicker(selected: _photos.toSet()),
    );
    if (!mounted || selected == null) return;
    setState(() => _photos.add(selected));
    _snack('Photo added to this local draft');
  }

  void _delete(int index) {
    setState(() {
      _photos.removeAt(index);
      if (_photos.isEmpty) {
        _primary = 0;
      } else {
        _primary = _primary.clamp(0, _photos.length - 1).toInt();
      }
    });
    _snack('Photo removed');
  }

  void _moveEarlier(int index) {
    if (index == 0) return _snack('Already first');
    setState(() {
      final item = _photos.removeAt(index);
      _photos.insert(index - 1, item);
      if (_primary == index) _primary = index - 1;
    });
    _snack('Reorder placeholder applied');
  }

  void _saveChanges() {
    if (_photos.length < 2) {
      _snack('Add at least two profile photos before saving');
      return;
    }
    LocalProfileRepository.instance.updatePhotos(_photos, _primary);
    AmoraSession.completeProfileStep(40);
    _snack('Photo changes saved locally');
    Navigator.of(context).pop(true);
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
                'Curate a strong, verified first impression.',
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
    required this.photo,
    required this.primary,
    required this.onPrimary,
    required this.onDelete,
    required this.onMove,
  });

  final String photo;
  final bool primary;
  final VoidCallback onPrimary;
  final VoidCallback onDelete;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: PremiumAssetImage(
            imageUrl: photo,
            fallbackAsset: photo,
            initials: 'AM',
            borderRadius: AmoraRadius.card,
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
              IconButton.filledTonal(
                tooltip: 'Move earlier',
                onPressed: onMove,
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
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

class _LocalPhotoPicker extends StatelessWidget {
  const _LocalPhotoPicker({required this.selected});

  final Set<String> selected;

  static const choices = [
    AppImages.profileYash,
    'assets/images/profiles/male/male_06.jpg',
    'assets/images/profiles/male/male_08.jpg',
    'assets/images/profiles/male/male_11.jpg',
    'assets/images/profiles/male/male_14.jpg',
    'assets/images/profiles/male/male_17.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      minChildSize: .45,
      maxChildSize: .92,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewPaddingOf(context).bottom + 24,
        ),
        children: [
          Text(
            'Choose a local demo photo',
            style: AmoraTextStyles.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The selection stays on this device and is not uploaded.',
            style: AmoraTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: choices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .84,
            ),
            itemBuilder: (context, index) {
              final choice = choices[index];
              final disabled = selected.contains(choice);
              return Semantics(
                button: true,
                enabled: !disabled,
                label: 'Local profile photo ${index + 1}',
                child: InkWell(
                  onTap: disabled
                      ? null
                      : () => Navigator.of(context).pop(choice),
                  borderRadius: AmoraRadius.card,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PremiumAssetImage(
                        imageUrl: choice,
                        fallbackAsset: choice,
                        initials: 'YA',
                        borderRadius: AmoraRadius.card,
                      ),
                      if (disabled)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.deepWine.withValues(alpha: .5),
                            borderRadius: AmoraRadius.card,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

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
        child: const Icon(
          Icons.add_photo_alternate_rounded,
          color: AppColors.primaryPurple,
          size: AmoraIconSizes.large,
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
