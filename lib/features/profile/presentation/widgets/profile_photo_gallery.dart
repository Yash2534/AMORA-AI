import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Compact Profile-page gallery backed by the existing profile photo order.
class ProfilePhotoGallery extends StatefulWidget {
  const ProfilePhotoGallery({super.key, required this.profile, this.onManage});

  static const double photoWidth = 104;
  static const double photoHeight = 130;

  final LocalProfileDraft profile;
  final VoidCallback? onManage;

  @override
  State<ProfilePhotoGallery> createState() => _ProfilePhotoGalleryState();
}

class _ProfilePhotoGalleryState extends State<ProfilePhotoGallery> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) return;
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final position = _scrollController.position;
      final target = (_scrollController.offset + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final primaryIndex = widget.profile.photos.isEmpty
        ? -1
        : widget.profile.primaryPhotoIndex.clamp(
            0,
            widget.profile.photos.length - 1,
          );

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: SizedBox(
        key: const ValueKey('profile-horizontal-photo-gallery'),
        height: ProfilePhotoGallery.photoHeight + AmoraSpacing.space8,
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
            scrollbars: false,
          ),
          child: ListView.separated(
            controller: _scrollController,
            key: const PageStorageKey<String>('profile-photo-gallery-scroll'),
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AmoraSpacing.space4),
            itemCount:
                widget.profile.photos.length +
                (widget.onManage == null ? 0 : 1),
            separatorBuilder: (_, _) =>
                const SizedBox(width: AmoraSpacing.space12),
            itemBuilder: (context, index) {
              if (index == widget.profile.photos.length &&
                  widget.onManage != null) {
                return _AddPhotoCard(onTap: widget.onManage!);
              }

              final photo = widget.profile.photos[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey('profile-gallery-photo-$index-$photo'),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: .98 + (.02 * value),
                    child: child,
                  ),
                ),
                child: _ProfilePhotoCard(
                  photo: photo,
                  index: index,
                  primary: index == primaryIndex,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  const _ProfilePhotoCard({
    required this.photo,
    required this.index,
    required this.primary,
  });

  final String photo;
  final int index;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('profile-gallery-photo-$index'),
      width: ProfilePhotoGallery.photoWidth,
      height: ProfilePhotoGallery.photoHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AmoraRadius.card,
          border: Border.all(
            color: primary
                ? AppColors.secondary
                : AppColors.tertiary.withValues(alpha: .72),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: .10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AmoraRadius.card,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AmoraProfileImage(
                imageUrl: photo,
                assetPath: photo,
                initials: 'AM',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.12),
                borderRadius: AmoraRadius.card,
                width: ProfilePhotoGallery.photoWidth,
                height: ProfilePhotoGallery.photoHeight,
                semanticLabel: 'Profile photo ${index + 1}',
              ),
              if (primary)
                const Positioned(
                  left: AmoraSpacing.space8,
                  top: AmoraSpacing.space8,
                  child: _PrimaryPhotoBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryPhotoBadge extends StatelessWidget {
  const _PrimaryPhotoBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Primary photo',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .90),
            borderRadius: AmoraRadius.pillBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space8,
              vertical: AmoraSpacing.space4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: AppColors.surface,
                ),
                const SizedBox(width: AmoraSpacing.space4),
                Text(
                  'Primary',
                  style: AmoraTextStyles.labelSmall.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoCard extends StatefulWidget {
  const _AddPhotoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AddPhotoCard> createState() => _AddPhotoCardState();
}

class _AddPhotoCardState extends State<_AddPhotoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: 'Add profile photo',
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          key: const ValueKey('profile-add-photo-card'),
          width: ProfilePhotoGallery.photoWidth,
          height: ProfilePhotoGallery.photoHeight,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.tertiary),
              borderRadius: AmoraRadius.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (pressed) {
                if (_pressed != pressed) setState(() => _pressed = pressed);
              },
              focusColor: AppColors.secondary.withValues(alpha: .10),
              hoverColor: AppColors.background,
              splashColor: AppColors.secondary.withValues(alpha: .14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: AmoraSpacing.minimumTouchTarget,
                      height: AmoraSpacing.minimumTouchTarget,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space8),
                    Text(
                      'Add Photo',
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
