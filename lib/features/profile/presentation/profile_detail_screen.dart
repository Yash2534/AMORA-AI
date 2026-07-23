<<<<<<< HEAD
=======
import 'dart:ui' as ui;

import 'package:amora_ai/core/access/amora_access.dart';
>>>>>>> main
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_badge.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
<<<<<<< HEAD
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
=======
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/commerce/presentation/send_gift_screen.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/discovery/presentation/super_like_screen.dart';
import 'package:amora_ai/features/match/presentation/why_we_matched_screen.dart';
import 'package:amora_ai/features/safety/presentation/blocked_user_success_sheet.dart';
>>>>>>> main
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';

enum ProfileDetailDecision { reject, like }
=======
import 'package:flutter/physics.dart';
>>>>>>> main

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key, this.profile});

  static const routeName = '/profile-detail';
  final DummyProfile? profile;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
<<<<<<< HEAD
=======
  final PageController _galleryController = PageController();

  int _photoIndex = 0;
  bool _liked = false;
  bool _superLiked = false;
  bool _saved = false;
  bool _blocked = false;
  bool _routeProfileApplied = false;
>>>>>>> main
  DummyProfile? _routeProfile;
  bool _argumentsRead = false;
  bool _processing = false;

<<<<<<< HEAD
  DummyProfile get _profile =>
      widget.profile ??
      _routeProfile ??
      ImageRepository.profileByName('Aadhya');
=======
  DummyProfile get _profile => _routeProfile ?? _detailProfile;
>>>>>>> main

  List<String> get _photos {
    final seen = <String>{};
    final photos = <String>[];
    for (final photo in <String>[_profile.imageUrl, ..._profile.gallery]) {
      final value = photo.trim();
      if (value.isNotEmpty && seen.add(value)) photos.add(value);
    }
    if (photos.isEmpty) photos.add(_profile.fallbackAsset);
    return photos;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    _argumentsRead = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is DummyProfile) {
      _routeProfile = arguments;
      return;
    }
    try {
      final dynamic value = arguments;
      final name = value?.name as String?;
      if (name != null && name.trim().isNotEmpty) {
        _routeProfile = ImageRepository.profileByName(name);
      }
    } catch (_) {
      _routeProfile = null;
    }
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final profile = _profile;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _goBack,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: ResponsiveMobileFrame(
            maxWidth: 760,
            child: CustomScrollView(
              key: const PageStorageKey('profile-details-scroll'),
              slivers: [
                _ProfileHeroAppBar(profile: profile, onBack: _goBack),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AmoraSpacing.space20,
                    AmoraSpacing.space20,
                    AmoraSpacing.space20,
                    AmoraSpacing.space32,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _IdentitySection(profile: profile),
                      const SizedBox(height: AmoraSpacing.space16),
                      _EditorialSection(
                        title: 'About ${profile.name.split(' ').first}',
                        child: Text(
                          profile.bio,
                          style: AmoraTextStyles.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      _EditorialSection(
                        title: 'Shared interests',
                        child: _PillWrap(values: profile.interests),
                      ),
                      if (profile.gallery.length > 1) ...[
                        const SizedBox(height: AmoraSpacing.space20),
                        _EditorialPhoto(
                          key: const Key('profile-detail-image-1'),
                          profile: profile,
                          imageUrl: profile.gallery[1],
                        ),
                      ],
                      const SizedBox(height: AmoraSpacing.space20),
                      _PromptSection(profile: profile),
                      if (profile.gallery.length > 2) ...[
                        const SizedBox(height: AmoraSpacing.space20),
                        _EditorialPhoto(
                          key: const Key('profile-detail-image-2'),
                          profile: profile,
                          imageUrl: profile.gallery[2],
                        ),
                      ],
                      const SizedBox(height: AmoraSpacing.space20),
                      _LifestyleSection(profile: profile),
                      const SizedBox(height: AmoraSpacing.space16),
                      _CompatibilitySection(profile: profile),
                      for (
                        var index = 3;
                        index < profile.gallery.length;
                        index++
                      ) ...[
                        const SizedBox(height: AmoraSpacing.space20),
                        _EditorialPhoto(
                          key: Key('profile-detail-image-$index'),
                          profile: profile,
                          imageUrl: profile.gallery[index],
                        ),
                      ],
                      const SizedBox(height: AmoraSpacing.space20),
                      _SafetySection(
                        onSafety: () => Navigator.of(
                          context,
                        ).pushNamed(ReportFlowScreen.routeName),
                      ),
                    ],
=======
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 1080,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 760;
              final horizontalPadding = desktop
                  ? AmoraSpacing.space24
                  : constraints.maxWidth < 360
                  ? AmoraSpacing.space16
                  : AmoraSpacing.space20;
              return Stack(
                children: [
                  SingleChildScrollView(
                    key: const ValueKey('profile-detail-scroll'),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      desktop ? AmoraSpacing.space24 : 0,
                      horizontalPadding,
                      ProfileActionBar.contentInset,
                    ),
                    child: desktop
                        ? _buildDesktop(context, constraints)
                        : _buildMobile(context, constraints),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        AmoraSpacing.space8,
                      ),
                      child: ProfileActionBar(
                        liked: _liked,
                        superLiked: _superLiked,
                        onLike: _toggleLike,
                        onSuperLike: _openSuperLike,
                        onGift: _openGift,
                        onDate: () => _snack('Date booking draft created'),
                        onMessage: _startChat,
                      ),
                    ),
>>>>>>> main
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: _StickyProfileActions(
            enabled: !_processing,
            onReject: () => _complete(ProfileDetailDecision.reject),
            onLike: () => _complete(ProfileDetailDecision.like),
          ),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, BoxConstraints constraints) {
    final galleryHeight = (constraints.maxHeight * .62).clamp(420.0, 620.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileMediaGallery(
          key: const ValueKey('profile-media-gallery'),
          height: galleryHeight,
          profile: _profile,
          photos: _photos,
          controller: _galleryController,
          selectedIndex: _photoIndex,
          saved: _saved,
          onPageChanged: (index) => setState(() => _photoIndex = index),
          onBack: _goBack,
          onSave: _toggleSave,
          onMore: _showReportSheet,
          onOpen: _openFullScreenGallery,
          onDoubleTap: _toggleLike,
        ),
        const SizedBox(height: AmoraSpacing.space20),
        _ProfileStory(
          profile: _profile,
          blocked: _blocked,
          onPromptReact: _snack,
          onWhyMatched: _openWhyMatched,
          onReport: _showReportSheet,
          onBlock: _showBlockDialog,
        ),
      ],
    );
  }

  Widget _buildDesktop(BuildContext context, BoxConstraints constraints) {
    final galleryHeight = (constraints.maxHeight - 48).clamp(560.0, 760.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 10,
          child: ProfileMediaGallery(
            key: const ValueKey('profile-media-gallery'),
            height: galleryHeight,
            profile: _profile,
            photos: _photos,
            controller: _galleryController,
            selectedIndex: _photoIndex,
            saved: _saved,
            onPageChanged: (index) => setState(() => _photoIndex = index),
            onBack: _goBack,
            onSave: _toggleSave,
            onMore: _showReportSheet,
            onOpen: _openFullScreenGallery,
            onDoubleTap: _toggleLike,
          ),
        ),
        const SizedBox(width: AmoraSpacing.space24),
        Expanded(
          flex: 11,
          child: _ProfileStory(
            profile: _profile,
            blocked: _blocked,
            onPromptReact: _snack,
            onWhyMatched: _openWhyMatched,
            onReport: _showReportSheet,
            onBlock: _showBlockDialog,
          ),
        ),
      ],
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
<<<<<<< HEAD
      navigator.pushReplacementNamed('/browse');
=======
      navigator.pushReplacementNamed(BrowseGridScreen.routeName);
>>>>>>> main
    }
  }

  Future<void> _complete(ProfileDetailDecision decision) async {
    if (_processing) return;
    setState(() => _processing = true);
    await Future<void>.delayed(AmoraMotion.fast);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(decision);
    } else {
      navigator.pushReplacementNamed('/browse');
    }
<<<<<<< HEAD
  }
}

class _ProfileHeroAppBar extends StatelessWidget {
  const _ProfileHeroAppBar({required this.profile, required this.onBack});

  final DummyProfile profile;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final heroImage = AmoraProfileImage(
      imageUrl: profile.gallery.first,
      assetPath: profile.fallbackAsset,
      initials: profile.initials,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
    final image = Hero(tag: 'profile-image-${profile.id}', child: heroImage);
    return SliverAppBar(
      pinned: true,
      expandedHeight: 520,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primary,
      leading: IconButton(
        key: const Key('profile-detail-back'),
        tooltip: 'Return to Discover',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          tooltip: 'Safety options',
          onPressed: () =>
              Navigator.of(context).pushNamed(ReportFlowScreen.routeName),
          icon: const Icon(Icons.shield_outlined),
=======
    setState(() => _liked = !_liked);
    _snack(_liked ? 'Profile liked successfully' : 'Like removed');
  }

  void _openSuperLike() {
    if (AmoraSession.isGuest) {
      _requireAuth(_openSuperLike);
      return;
    }
    setState(() => _superLiked = true);
    Navigator.of(context).pushNamed(SuperLikeScreen.routeName);
  }

  void _openGift() {
    if (AmoraSession.isGuest) {
      _requireAuth(_openGift);
      return;
    }
    Navigator.of(context).pushNamed(SendGiftScreen.routeName);
  }

  void _startChat() {
    if (AmoraSession.isGuest) {
      _requireAuth(_startChat);
      return;
    }
    Navigator.of(context).pushNamed(ChatDetailScreen.routeName);
  }

  void _toggleSave() {
    if (AmoraSession.isGuest) {
      _requireAuth(_toggleSave);
      return;
    }
    setState(() => _saved = !_saved);
  }

  void _openWhyMatched() {
    if (AmoraSession.isGuest) {
      _requireAuth(_openWhyMatched);
      return;
    }
    Navigator.of(context).pushNamed(WhyWeMatchedScreen.routeName);
  }

  Future<void> _requireAuth(VoidCallback action) {
    return AmoraSession.requireAuth(context: context, onAuthenticated: action);
  }

  void _openFullScreenGallery(int initialIndex) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenGallery(
          profile: _profile,
          photos: _photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Safety actions',
                  style: AmoraTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Text(
                  'Report or block if something feels off. Amora keeps respectful conversations first.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .70),
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space20),
                AppPrimaryButton(
                  label: 'Report Profile',
                  icon: Icons.flag_rounded,
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).pushNamed(ReportFlowScreen.routeName);
                  },
                ),
                const SizedBox(height: AmoraSpacing.space12),
                AppPrimaryButton(
                  label: _blocked ? 'Blocked' : 'Block Profile',
                  icon: Icons.block_rounded,
                  variant: AppPrimaryButtonVariant.dark,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showBlockDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            message,
            style: const TextStyle(color: AppColors.surface),
          ),
        ),
      );
  }

  void _showBlockDialog() {
    showBlockConfirmationDialog(context: context, userName: _profile.name).then(
      (blocked) {
        if (blocked != true || !mounted) return;
        setState(() => _blocked = true);
        showBlockedUserSuccessSheet(context: context, userName: _profile.name);
      },
    );
  }
}

class ProfileMediaGallery extends StatelessWidget {
  const ProfileMediaGallery({
    super.key,
    required this.height,
    required this.profile,
    required this.photos,
    required this.controller,
    required this.selectedIndex,
    required this.saved,
    required this.onPageChanged,
    required this.onBack,
    required this.onSave,
    required this.onMore,
    required this.onOpen,
    required this.onDoubleTap,
  });

  final double height;
  final DummyProfile profile;
  final List<String> photos;
  final PageController controller;
  final int selectedIndex;
  final bool saved;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onMore;
  final ValueChanged<int> onOpen;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.tertiary.withValues(alpha: .38),
              child: PageView.builder(
                controller: controller,
                itemCount: photos.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    key: ValueKey('profile-photo-$index'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpen(index),
                    onDoubleTap: onDoubleTap,
                    child: Semantics(
                      image: true,
                      label:
                          '${profile.name} profile photo ${index + 1} of ${photos.length}',
                      child: LayoutBuilder(
                        builder: (context, imageConstraints) {
                          return AmoraProfileImage(
                            imageUrl: photos[index],
                            assetPath: profile.fallbackAsset,
                            initials: profile.initials,
                            width: imageConstraints.maxWidth,
                            height: imageConstraints.maxHeight,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: _MediaReadabilityOverlay()),
            ),
            Positioned(
              left: AmoraSpacing.space12,
              right: AmoraSpacing.space12,
              top: AmoraSpacing.space12,
              child: ProfileTopControls(
                saved: saved,
                onBack: onBack,
                onSave: onSave,
                onMore: onMore,
              ),
            ),
            Positioned(
              left: AmoraSpacing.space20,
              right: AmoraSpacing.space20,
              bottom: AmoraSpacing.space20,
              child: ProfileIdentityHeader(profile: profile),
            ),
            Positioned(
              top: AmoraSpacing.space20,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: _GalleryCounter(
                    current: selectedIndex + 1,
                    total: photos.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaReadabilityOverlay extends StatelessWidget {
  const _MediaReadabilityOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [.45, 1],
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: .90),
          ],
        ),
      ),
    );
  }
}

class ProfileTopControls extends StatelessWidget {
  const ProfileTopControls({
    super.key,
    required this.saved,
    required this.onBack,
    required this.onSave,
    required this.onMore,
  });

  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(
          key: const ValueKey('profile-back-button'),
          tooltip: 'Back',
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        _GlassIconButton(
          key: const ValueKey('profile-save-button'),
          tooltip: saved ? 'Remove saved profile' : 'Save profile',
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          selected: saved,
          onTap: onSave,
        ),
        const SizedBox(width: AmoraSpacing.space8),
        _GlassIconButton(
          key: const ValueKey('profile-more-button'),
          tooltip: 'Safety actions',
          icon: Icons.more_horiz_rounded,
          onTap: onMore,
>>>>>>> main
        ),
        const SizedBox(width: AmoraSpacing.space8),
      ],
<<<<<<< HEAD
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            image,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.overlayDark,
                    AppColors.transparent,
                    AppColors.overlayDark,
                  ],
                  stops: [0, .28, 1],
                ),
              ),
            ),
            Positioned(
              left: AmoraSpacing.space20,
              right: AmoraSpacing.space20,
              bottom: AmoraSpacing.space20,
              child: Text(
                '${profile.name}, ${profile.age}',
=======
    );
  }
}

class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? .92 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Material(
                color: widget.selected
                    ? AppColors.secondary
                    : AppColors.surface.withValues(alpha: .90),
                child: InkWell(
                  onTap: widget.onTap,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      widget.icon,
                      color: widget.selected
                          ? AppColors.surface
                          : AppColors.primary,
                      size: 23,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryCounter extends StatelessWidget {
  const _GalleryCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surface.withValues(alpha: .38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          '$current / $total',
          style: AmoraTextStyles.labelMedium.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final verified = profile.verified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${profile.name.split(' ').first}, ${profile.age}',
>>>>>>> main
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.headlineLarge.copyWith(
                  color: AppColors.surface,
<<<<<<< HEAD
                ),
              ),
            ),
          ],
=======
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
            ),
            if (verified) ...[
              const SizedBox(width: AmoraSpacing.space8),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.tertiary,
                size: 24,
                semanticLabel: 'Verified profile',
              ),
            ],
          ],
        ),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          profile.profession,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.titleMedium.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Wrap(
          spacing: AmoraSpacing.space12,
          runSpacing: AmoraSpacing.space4,
          children: [
            _OverlayMeta(
              icon: Icons.location_on_rounded,
              text: profile.distance,
            ),
            _OverlayMeta(
              icon: Icons.circle,
              text: profile.status,
              smallIcon: true,
            ),
            _OverlayMeta(icon: Icons.location_city_rounded, text: profile.city),
          ],
        ),
      ],
    );
  }
}

class _OverlayMeta extends StatelessWidget {
  const _OverlayMeta({
    required this.icon,
    required this.text,
    this.smallIcon = false,
  });

  final IconData icon;
  final String text;
  final bool smallIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: smallIcon ? 8 : 16,
          color: smallIcon ? AppColors.secondary : AppColors.tertiary,
        ),
        const SizedBox(width: AmoraSpacing.space4),
        Text(
          text,
          style: AmoraTextStyles.labelMedium.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileStory extends StatelessWidget {
  const _ProfileStory({
    required this.profile,
    required this.blocked,
    required this.onPromptReact,
    required this.onWhyMatched,
    required this.onReport,
    required this.onBlock,
  });

  final DummyProfile profile;
  final bool blocked;
  final ValueChanged<String> onPromptReact;
  final VoidCallback onWhyMatched;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionReveal(child: ProfileQuickFacts(profile: profile)),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(child: ProfileAboutSection(profile: profile)),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(child: RelationshipIntentionsSection(profile: profile)),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(child: LifestyleGrid(profile: profile)),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(child: _InterestsSection(profile: profile)),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(
          child: _ProfilePromptsSection(
            profile: profile,
            onReact: onPromptReact,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(
          child: CompatibilitySection(
            profile: profile,
            onWhyMatched: onWhyMatched,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space24),
        _SectionReveal(
          child: TrustAndSafetySection(
            profile: profile,
            blocked: blocked,
            onReport: onReport,
            onBlock: onBlock,
          ),
        ),
      ],
    );
  }
}

class _SectionReveal extends StatelessWidget {
  const _SectionReveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ProfileQuickFacts extends StatelessWidget {
  const ProfileQuickFacts({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final facts = <_SymbolicFact>[
      _SymbolicFact(Icons.straighten_rounded, 'Height', profile.height),
      _SymbolicFact(Icons.school_rounded, 'Education', profile.education),
      _SymbolicFact(
        Icons.language_rounded,
        'Languages',
        profile.languages.join(' · '),
      ),
      _SymbolicFact(
        Icons.favorite_border_rounded,
        'Looking for',
        profile.intent,
      ),
      _SymbolicFact(Icons.smoke_free_rounded, 'Smoking', profile.smoking),
      _SymbolicFact(Icons.local_bar_outlined, 'Drinking', profile.drinking),
      _SymbolicFact(Icons.child_care_rounded, 'Children', profile.children),
    ].where((fact) => fact.value.trim().isNotEmpty).toList(growable: false);

    return SizedBox(
      key: const ValueKey('profile-quick-facts'),
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: facts.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AmoraSpacing.space8),
        itemBuilder: (context, index) => _SymbolicInfoTile(fact: facts[index]),
      ),
    );
  }
}

class _SymbolicInfoTile extends StatelessWidget {
  const _SymbolicInfoTile({required this.fact});

  final _SymbolicFact fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(AmoraSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .62)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 16,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(fact.icon, color: AppColors.secondary, size: 18),
              const SizedBox(width: AmoraSpacing.space8),
              Expanded(
                child: Text(
                  fact.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.labelSmall.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .58),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            fact.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.textNeutral,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAboutSection extends StatefulWidget {
  const ProfileAboutSection({super.key, required this.profile});

  final DummyProfile profile;

  @override
  State<ProfileAboutSection> createState() => _ProfileAboutSectionState();
}

class _ProfileAboutSectionState extends State<ProfileAboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.profile.bio.trim();
    if (bio.isEmpty) return const SizedBox.shrink();
    final long = bio.length > 150;
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'About me',
          ),
          const SizedBox(height: AmoraSpacing.space12),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Text(
              bio,
              maxLines: long && !_expanded ? 4 : null,
              overflow: long && !_expanded ? TextOverflow.ellipsis : null,
              style: AmoraTextStyles.bodyLarge.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .82),
                height: 1.55,
              ),
            ),
          ),
          if (long)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Read more'),
            ),
        ],
      ),
    );
  }
}

class RelationshipIntentionsSection extends StatelessWidget {
  const RelationshipIntentionsSection({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final intentions = <_SymbolicFact>[
      _SymbolicFact(
        Icons.favorite_border_rounded,
        'Dating intention',
        profile.intent,
      ),
      _SymbolicFact(Icons.home_outlined, 'Family values', profile.familyValues),
      if (profile.dateIdeas.isNotEmpty)
        _SymbolicFact(
          Icons.coffee_rounded,
          'Meaningful dates',
          profile.dateIdeas.first,
        ),
    ].where((item) => item.value.trim().isNotEmpty).toList(growable: false);
    if (intentions.isEmpty) return const SizedBox.shrink();
    return _SectionSurface(
      color: AppColors.tertiary.withValues(alpha: .24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.volunteer_activism_rounded,
            title: 'Relationship intentions',
          ),
          const SizedBox(height: AmoraSpacing.space16),
          for (final item in intentions)
            Padding(
              padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
              child: _IconValueRow(item: item),
            ),
        ],
      ),
    );
  }
}

class LifestyleGrid extends StatelessWidget {
  const LifestyleGrid({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = <_SymbolicFact>[
      _SymbolicFact(
        Icons.directions_run_rounded,
        'Activity',
        profile.fitnessLevel,
      ),
      _SymbolicFact(Icons.restaurant_rounded, 'Food', profile.foodPreference),
      _SymbolicFact(Icons.smoke_free_rounded, 'Smoking', profile.smoking),
      _SymbolicFact(Icons.local_bar_outlined, 'Drinking', profile.drinking),
      _SymbolicFact(Icons.pets_rounded, 'Pets', profile.petPreference),
      _SymbolicFact(
        Icons.self_improvement_rounded,
        'Beliefs',
        profile.religion,
      ),
      _SymbolicFact(
        Icons.psychology_alt_rounded,
        'Personality',
        profile.personality,
      ),
      _SymbolicFact(
        Icons.favorite_outline_rounded,
        'Love language',
        profile.loveLanguage,
      ),
      _SymbolicFact(Icons.weekend_outlined, 'Weekend', profile.weekendPlan),
    ].where((item) => item.value.trim().isNotEmpty).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.dashboard_customize_outlined,
          title: 'Lifestyle & personality',
        ),
        const SizedBox(height: AmoraSpacing.space16),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AmoraSpacing.space8) / 2;
            return Wrap(
              spacing: AmoraSpacing.space8,
              runSpacing: AmoraSpacing.space8,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    child: _LifestyleTile(item: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LifestyleTile extends StatelessWidget {
  const _LifestyleTile({required this.item});

  final _SymbolicFact item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(AmoraSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: .32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(item.icon, color: AppColors.primary, size: 19),
            ),
          ),
          const SizedBox(width: AmoraSpacing.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AmoraTextStyles.labelSmall.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .54),
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  item.value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: AppColors.textNeutral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestsSection extends StatelessWidget {
  const _InterestsSection({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final interests = profile.interests
        .map((interest) => interest.trim())
        .where(
          (interest) => interest.isNotEmpty && seen.add(interest.toLowerCase()),
        )
        .toList(growable: false);
    if (interests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.interests_rounded, title: 'Interests'),
        const SizedBox(height: AmoraSpacing.space16),
        Wrap(
          spacing: AmoraSpacing.space8,
          runSpacing: AmoraSpacing.space8,
          children: [
            for (final interest in interests) InterestChip(label: interest),
          ],
        ),
      ],
    );
  }
}

class InterestChip extends StatelessWidget {
  const InterestChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.secondary.withValues(alpha: .72)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_interestIcon(label), color: AppColors.secondary, size: 17),
            const SizedBox(width: AmoraSpacing.space8),
            Text(
              label,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.textNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePromptsSection extends StatelessWidget {
  const _ProfilePromptsSection({required this.profile, required this.onReact});

  final DummyProfile profile;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final prompts = profile.promptAnswers.entries
        .where(
          (entry) =>
              entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (prompts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.format_quote_rounded,
          title: 'Profile prompts',
        ),
        const SizedBox(height: AmoraSpacing.space16),
        for (final prompt in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
            child: ProfilePromptCard(
              prompt: prompt.key,
              answer: prompt.value,
              onLike: () => onReact('Prompt liked'),
              onReply: () => onReact('Reply shortcut opened'),
            ),
          ),
        _MatchNoteComposer(onSend: () => onReact('Match note drafted')),
      ],
    );
  }
}

class ProfilePromptCard extends StatelessWidget {
  const ProfilePromptCard({
    super.key,
    required this.prompt,
    required this.answer,
    required this.onLike,
    required this.onReply,
  });

  final String prompt;
  final String answer;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: AppColors.secondary,
            size: 28,
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            prompt,
            style: AmoraTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            answer,
            style: AmoraTextStyles.titleMedium.copyWith(
              color: AppColors.textNeutral,
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Row(
            children: [
              _PromptAction(
                tooltip: 'Like prompt',
                icon: Icons.favorite_border_rounded,
                onTap: onLike,
              ),
              const SizedBox(width: AmoraSpacing.space8),
              _PromptAction(
                tooltip: 'Reply to prompt',
                icon: Icons.reply_rounded,
                onTap: onReply,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptAction extends StatelessWidget {
  const _PromptAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.tertiary.withValues(alpha: .30),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: AppColors.primary, size: 20),
>>>>>>> main
        ),
      ),
    );
  }
}

<<<<<<< HEAD
class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.profession} · ${profile.city}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.titleLarge,
                ),
              ),
              if (profile.verified) const AmoraBadge.verified3d(),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space8),
          _MetadataLine(
            icon: Icons.location_on_outlined,
            text: '${profile.distance} away',
          ),
          _MetadataLine(
            icon: Icons.favorite_border_rounded,
            text: profile.intent,
=======
class _MatchNoteComposer extends StatelessWidget {
  const _MatchNoteComposer({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      color: AppColors.tertiary.withValues(alpha: .22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.edit_note_rounded,
            title: 'Match note',
          ),
          const SizedBox(height: AmoraSpacing.space12),
          const TextField(
            minLines: 2,
            maxLines: 4,
            maxLength: 180,
            decoration: InputDecoration(
              hintText: 'Add a thoughtful note before sending a like',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Attach note'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompatibilitySection extends StatelessWidget {
  const CompatibilitySection({
    super.key,
    required this.profile,
    required this.onWhyMatched,
  });

  final DummyProfile profile;
  final VoidCallback onWhyMatched;

  @override
  Widget build(BuildContext context) {
    if (profile.score <= 0) return const SizedBox.shrink();
    final signals = <String>{
      profile.intent,
      profile.loveLanguage,
      ...profile.interests.take(3),
    }.where((value) => value.trim().isNotEmpty).toList(growable: false);
    return _SectionSurface(
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: 'Compatibility insight',
            foreground: AppColors.surface,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Row(
            children: [
              _CompatibilityRing(score: profile.score),
              const SizedBox(width: AmoraSpacing.space16),
              Expanded(
                child: Text(
                  'Amora’s supplied match score reflects the profile signals already available for this connection.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface.withValues(alpha: .82),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          if (signals.isNotEmpty) ...[
            const SizedBox(height: AmoraSpacing.space16),
            Wrap(
              spacing: AmoraSpacing.space8,
              runSpacing: AmoraSpacing.space8,
              children: [
                for (final signal in signals)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.tertiary.withValues(alpha: .42),
                      ),
                    ),
                    child: Text(
                      signal,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AmoraSpacing.space16),
          OutlinedButton.icon(
            key: const ValueKey('profile-why-matched-button'),
            onPressed: onWhyMatched,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Why we matched'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.surface,
              side: BorderSide(
                color: AppColors.tertiary.withValues(alpha: .72),
              ),
            ),
>>>>>>> main
          ),
          _MetadataLine(icon: Icons.school_outlined, text: profile.education),
        ],
      ),
    );
  }
}

<<<<<<< HEAD
class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.icon, required this.text});
=======
class _CompatibilityRing extends StatelessWidget {
  const _CompatibilityRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              value: score.clamp(0, 100) / 100,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surface.withValues(alpha: .16),
              color: AppColors.secondary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'match',
                style: AmoraTextStyles.labelSmall.copyWith(
                  color: AppColors.surface.withValues(alpha: .72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrustAndSafetySection extends StatelessWidget {
  const TrustAndSafetySection({
    super.key,
    required this.profile,
    required this.blocked,
    required this.onReport,
    required this.onBlock,
  });

  final DummyProfile profile;
  final bool blocked;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final verification = profile.verification.trim();
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.shield_outlined,
            title: 'Safety & trust',
          ),
          if (verification.isNotEmpty) ...[
            const SizedBox(height: AmoraSpacing.space16),
            _TrustRow(icon: Icons.verified_user_rounded, text: verification),
          ],
          const SizedBox(height: AmoraSpacing.space8),
          _TrustRow(icon: Icons.schedule_rounded, text: profile.status),
          const SizedBox(height: AmoraSpacing.space16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('profile-report-button'),
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.tertiary),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: AmoraSpacing.space8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('profile-block-button'),
                  onPressed: onBlock,
                  icon: const Icon(Icons.block_rounded),
                  label: Text(blocked ? 'Blocked' : 'Block'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.tertiary),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});
>>>>>>> main

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.activeContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.bodyMedium,
=======
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: .32),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileActionBar extends StatelessWidget {
  const ProfileActionBar({
    super.key,
    required this.liked,
    required this.superLiked,
    required this.onLike,
    required this.onSuperLike,
    required this.onGift,
    required this.onDate,
    required this.onMessage,
  });

  static const double height = 82;
  static const double contentInset = 106;

  final bool liked;
  final bool superLiked;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onGift;
  final VoidCallback onDate;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .72)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .14),
              blurRadius: 28,
              spreadRadius: -10,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: _ProfileActionButton(
                  label: 'Gift',
                  icon: Icons.card_giftcard_rounded,
                  onTap: onGift,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  label: superLiked ? 'Supered' : 'Super',
                  icon: Icons.star_rounded,
                  selected: superLiked,
                  onTap: onSuperLike,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  key: const ValueKey('profile-like-button'),
                  label: liked ? 'Liked' : 'Like',
                  icon: Icons.favorite_rounded,
                  selected: liked,
                  dominant: true,
                  onTap: onLike,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  label: 'Date',
                  icon: Icons.event_available_rounded,
                  onTap: onDate,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  key: const ValueKey('profile-message-button'),
                  label: 'Message',
                  icon: Icons.chat_bubble_rounded,
                  onTap: onMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatefulWidget {
  const _ProfileActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.dominant = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool dominant;

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _animate(double target) {
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .8, stiffness: 520, damping: 30),
        _scale.value,
        target,
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.selected || widget.dominant;
    return Tooltip(
      message: widget.label,
      child: Listener(
        onPointerDown: (_) => _animate(.92),
        onPointerUp: (_) => _animate(1),
        onPointerCancel: (_) => _animate(1),
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: SizedBox(
                height: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: widget.dominant ? 42 : 36,
                      height: widget.dominant ? 42 : 36,
                      decoration: BoxDecoration(
                        color: filled ? AppColors.secondary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: filled
                              ? AppColors.secondary
                              : AppColors.tertiary,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: filled ? AppColors.surface : AppColors.primary,
                        size: widget.dominant ? 22 : 19,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: AmoraTextStyles.labelSmall.copyWith(
                        color: widget.dominant
                            ? AppColors.secondary
                            : AppColors.textNeutral,
                        fontSize: 10,
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

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({
    required this.profile,
    required this.photos,
    required this.initialIndex,
  });

  final DummyProfile profile;
  final List<String> photos;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              key: const ValueKey('profile-fullscreen-gallery'),
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: LayoutBuilder(
                    builder: (context, imageConstraints) {
                      return AmoraProfileImage(
                        imageUrl: widget.photos[index],
                        assetPath: widget.profile.fallbackAsset,
                        initials: widget.profile.initials,
                        width: imageConstraints.maxWidth,
                        height: imageConstraints.maxHeight,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              left: AmoraSpacing.space16,
              top: AmoraSpacing.space16,
              child: _GlassIconButton(
                tooltip: 'Close gallery',
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: AmoraSpacing.space20,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: _GalleryCounter(
                    current: _index + 1,
                    total: widget.photos.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({required this.child, this.color = AppColors.surface});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .48)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 24,
            spreadRadius: -12,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.foreground = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: foreground, size: 21),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: Text(
            title,
            style: AmoraTextStyles.titleMedium.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconValueRow extends StatelessWidget {
  const _IconValueRow({required this.item});

  final _SymbolicFact item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.tertiary),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(item.icon, color: AppColors.secondary, size: 20),
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: AmoraTextStyles.labelSmall.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .54),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space4),
              Text(
                item.value,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textNeutral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SymbolicFact {
  const _SymbolicFact(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

IconData _interestIcon(String label) {
  final value = label.toLowerCase();
  if (value.contains('travel') || value.contains('road')) {
    return Icons.flight_takeoff_rounded;
  }
  if (value.contains('coffee')) return Icons.coffee_rounded;
  if (value.contains('music') || value.contains('concert')) {
    return Icons.music_note_rounded;
  }
  if (value.contains('fitness') || value.contains('gym')) {
    return Icons.fitness_center_rounded;
  }
  if (value.contains('movie') || value.contains('cinema')) {
    return Icons.movie_outlined;
  }
  if (value.contains('art') || value.contains('design')) {
    return Icons.palette_outlined;
  }
  if (value.contains('food') || value.contains('dining')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('pet')) return Icons.pets_rounded;
  if (value.contains('game')) return Icons.sports_esports_rounded;
  if (value.contains('book')) return Icons.menu_book_rounded;
  return Icons.favorite_border_rounded;
}

final _detailProfile = ImageRepository.profileByName('Aadhya');

/// Reusable loading composition for a future real profile loading state.
class ProfileDetailSkeleton extends StatelessWidget {
  const ProfileDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ColoredBox(color: AppColors.tertiary.withValues(alpha: .36)),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AmoraSpacing.space20),
              child: Column(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: .48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ],
              ),
>>>>>>> main
            ),
          ),
        ],
      ),
    );
  }
}

<<<<<<< HEAD
class _EditorialSection extends StatelessWidget {
  const _EditorialSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AmoraTextStyles.sectionTitle),
          const SizedBox(height: AmoraSpacing.space12),
          child,
        ],
      ),
    );
  }
}

class _EditorialPhoto extends StatelessWidget {
  const _EditorialPhoto({
    super.key,
    required this.profile,
    required this.imageUrl,
  });

  final DummyProfile profile;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: AspectRatio(
        aspectRatio: .8,
        child: AmoraProfileImage(
          imageUrl: imageUrl,
          assetPath: profile.fallbackAsset,
          initials: profile.initials,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _PromptSection extends StatelessWidget {
  const _PromptSection({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final prompts = profile.promptAnswers.entries.take(3);
    return Column(
      children: [
        for (final prompt in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
            child: PremiumCard(
              color: AppColors.surfaceSelected,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt.key,
                    style: AmoraTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space8),
                  Text(prompt.value, style: AmoraTextStyles.bodyLarge),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LifestyleSection extends StatelessWidget {
  const _LifestyleSection({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return _EditorialSection(
      title: 'Lifestyle',
      child: _PillWrap(
        values: [
          ...profile.lifestyle,
          profile.travelPreference,
          profile.musicTaste,
          profile.coffeePreference,
          profile.petPreference,
        ],
      ),
    );
  }
}

class _CompatibilitySection extends StatelessWidget {
  const _CompatibilitySection({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return _EditorialSection(
      title: 'What you may connect on',
      child: Column(
        children: [
          _CompatibilityRow(
            label: 'Shared interests',
            value: profile.score / 100,
          ),
          _CompatibilityRow(
            label: 'Relationship intention',
            value: ((profile.score - 4).clamp(0, 100)) / 100,
          ),
          _CompatibilityRow(
            label: 'Conversation energy',
            value: ((profile.score - 7).clamp(0, 100)) / 100,
          ),
        ],
=======
class ProfileDetailErrorState extends StatelessWidget {
  const ProfileDetailErrorState({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: AppColors.primary,
              size: 52,
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text(
              'Profile unavailable',
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              'This profile could not be displayed right now.',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .68),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go back'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
            ),
          ],
        ),
>>>>>>> main
      ),
    );
  }
}
<<<<<<< HEAD

class _CompatibilityRow extends StatelessWidget {
  const _CompatibilityRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AmoraTextStyles.bodyMedium),
          const SizedBox(height: AmoraSpacing.space8),
          LinearProgressIndicator(
            value: value,
            minHeight: 7,
            borderRadius: AmoraRadius.pillBorder,
            backgroundColor: AppColors.tertiarySoft,
            color: AppColors.active,
          ),
        ],
      ),
    );
  }
}

class _SafetySection extends StatelessWidget {
  const _SafetySection({required this.onSafety});

  final VoidCallback onSafety;

  @override
  Widget build(BuildContext context) {
    return _EditorialSection(
      title: 'Safety and respect',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your comfort comes first. Report or block a profile whenever something feels off.',
          ),
          const SizedBox(height: AmoraSpacing.space16),
          AppPrimaryButton(
            label: 'Safety options',
            icon: Icons.shield_outlined,
            variant: AppPrimaryButtonVariant.outlined,
            onPressed: onSafety,
          ),
        ],
      ),
    );
  }
}

class _PillWrap extends StatelessWidget {
  const _PillWrap({required this.values});

  final Iterable<String> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AmoraSpacing.space8,
      runSpacing: AmoraSpacing.space8,
      children: [
        for (final value in values)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.activeContainer,
              borderRadius: AmoraRadius.pillBorder,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space12,
                vertical: AmoraSpacing.space8,
              ),
              child: Text(value, style: AmoraTextStyles.labelMedium),
            ),
          ),
      ],
    );
  }
}

class _StickyProfileActions extends StatelessWidget {
  const _StickyProfileActions({
    required this.enabled,
    required this.onReject,
    required this.onLike,
  });

  final bool enabled;
  final VoidCallback onReject;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space12,
                AmoraSpacing.space20,
                AmoraSpacing.space12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      key: const Key('profile-detail-reject'),
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      variant: AppPrimaryButtonVariant.outlined,
                      onPressed: enabled ? onReject : null,
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: AppPrimaryButton(
                      key: const Key('profile-detail-like'),
                      label: 'Like',
                      icon: Icons.favorite_rounded,
                      onPressed: enabled ? onLike : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
=======
>>>>>>> main
