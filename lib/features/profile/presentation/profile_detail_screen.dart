import 'dart:ui' as ui;
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_super_like_animation.dart';
import 'package:amora_ai/core/widgets/amoraa_confirm_action_sheet.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_rose_sheet.dart';
import 'package:amora_ai/features/rose/data/rose_repository.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_preference_display.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_connection_profile_details.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_attribute_icons.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/match/presentation/why_we_matched_screen.dart';
import 'package:amora_ai/features/safety/presentation/blocked_user_success_sheet.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/safety/widgets/block_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

enum ProfileDetailDecision { reject, like }

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({
    super.key,
    this.profile,
    this.onSuperLike,
    this.api,
  });

  static const routeName = '/profile-detail';
  final DummyProfile? profile;
  final Future<bool> Function()? onSuperLike;
  final PhaseTwoApiService? api;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  final PageController _galleryController = PageController();
  late final AnimationController _superLikeAnimation;

  int _photoIndex = 0;
  bool _superLikeSending = false;
  bool _roseSheetOpen = false;
  DummyProfile? _routeProfile;
  bool _argumentsRead = false;
  PublicRelationshipState _serverRelationship = const PublicRelationshipState();
  bool _loading = false;
  String? _loadError;
  bool _profileUnavailable = false;
  bool _viewingOwnProfile = false;

  @override
  void initState() {
    super.initState();
    ProfileRelationshipController.instance.addListener(
      _handleRelationshipUpdate,
    );
    _superLikeAnimation = AnimationController(
      vsync: this,
      duration: AmoraSuperLikeAnimation.duration,
    );
  }

  DummyProfile get _profile => (_routeProfile ?? widget.profile)!;
  bool get _saved =>
      ProfileRelationshipController.instance.isSaved(_profile.id);
  bool get _blocked =>
      _serverRelationship.blocked ||
      ProfileRelationshipController.instance.isBlocked(_profile.id);
  bool get _liked =>
      ProfileRelationshipController.instance.isLiked(_profile.id);
  bool get _superLiked =>
      ProfileRelationshipController.instance.isSuperLiked(_profile.id);

  List<ProfilePhotoViewData> get _photos {
    final seen = <String>{};
    final sources = <String>[];
    for (final photo in <String>[_profile.imageUrl, ..._profile.gallery]) {
      final value = photo.trim();
      if (value.isNotEmpty && seen.add(value)) sources.add(value);
    }
    if (sources.isEmpty) sources.add(_profile.fallbackAsset);
    return <ProfilePhotoViewData>[
      for (var index = 0; index < sources.length; index++)
        ProfilePhotoViewData(
          id: 'viewed-${_profile.id}-$index',
          source: sources[index],
          order: index,
          isPrimary: index == 0,
          uploadState: ProfilePhotoUploadState.bundled,
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    _argumentsRead = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is DummyProfile) {
      _routeProfile = arguments;
      if (widget.api != null) _loadProfile(arguments.id);
      return;
    }
    final id = arguments?.toString();
    if (id != null && id.isNotEmpty && widget.api != null) _loadProfile(id);
  }

  Future<void> _loadProfile(String userId) async {
    final currentUser = AuthService.instance.currentUser;
    final loadingOwnProfile =
        currentUser != null && currentUser.id.toString() == userId;
    setState(() {
      _loading = true;
      _loadError = null;
      _profileUnavailable = false;
      _viewingOwnProfile = loadingOwnProfile;
      if (loadingOwnProfile) _routeProfile = null;
    });
    try {
      if (loadingOwnProfile) {
        final repository = LocalProfileRepository.instance;
        await repository.refreshFromServer();
        final publicProfile = AmoraaPublicProfileData.fromProfile(
          repository.profile,
          repository.currentPhotos,
          isAadhaarVerified: currentUser.isVerified,
        );
        if (!mounted) return;
        setState(() {
          _routeProfile = publicProfile.toPublicDisplayProfile();
          _serverRelationship = const PublicRelationshipState();
          _viewingOwnProfile = true;
        });
        return;
      }
      final result = await widget.api!.profile(userId);
      if (!mounted) return;
      final relationships = ProfileRelationshipController.instance;
      if (result.relationship.saved) relationships.saveProfile(result.profile);
      if (result.relationship.superLiked) {
        relationships.superLikeProfile(result.profile);
      } else if (result.relationship.liked) {
        relationships.likeProfile(result.profile);
      }
      setState(() {
        _routeProfile = result.profile;
        _serverRelationship = result.relationship;
        _viewingOwnProfile = false;
      });
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _routeProfile = null;
          _profileUnavailable = true;
          _loadError = error.userMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routeProfile = null;
          _profileUnavailable = true;
          _loadError = 'Couldn\'t load this profile.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    ProfileRelationshipController.instance.removeListener(
      _handleRelationshipUpdate,
    );
    _galleryController.dispose();
    _superLikeAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _viewingOwnProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loading && _routeProfile == null && widget.profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_profileUnavailable ||
        (_routeProfile == null && widget.profile == null)) {
      return Scaffold(
        appBar: AmoraAppBar(
          title: 'Profile',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: Center(child: Text(_loadError ?? 'Profile is unavailable.')),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _viewingOwnProfile
          ? AmoraAppBar(title: 'Profile', onBack: _goBack)
          : null,
      body: SafeArea(
        top: !_viewingOwnProfile,
        child: AmoraaPublicProfileView(
          mode: _viewingOwnProfile
              ? PublicProfileViewMode.preview
              : PublicProfileViewMode.otherUser,
          scrollKey: const ValueKey('profile-detail-scroll'),
          galleryBuilder: (context, height, desktop) => ProfileMediaGallery(
            key: const ValueKey('profile-media-gallery'),
            height: height,
            profile: _profile,
            photos: _photos,
            controller: _galleryController,
            selectedIndex: _photoIndex,
            mode: _viewingOwnProfile
                ? PublicProfileViewMode.preview
                : PublicProfileViewMode.otherUser,
            saved: _saved,
            onPageChanged: (index) => setState(() => _photoIndex = index),
            onBack: _goBack,
            onSave: _toggleSave,
            onMore: _showReportSheet,
            onOpen: _openFullScreenGallery,
            onDoubleTap: _viewingOwnProfile ? null : _toggleLike,
          ),
          story: ProfileStory(
            profile: _profile,
            mode: _viewingOwnProfile
                ? PublicProfileViewMode.preview
                : PublicProfileViewMode.otherUser,
            blocked: _blocked,
            onPromptReply: _viewingOwnProfile ? null : _replyToPrompt,
            onWhyMatched: _viewingOwnProfile ? null : _openWhyMatched,
            onReport: _viewingOwnProfile ? null : _showReportSheet,
            onBlock: _viewingOwnProfile ? null : _showBlockDialog,
          ),
          interactionBar: _viewingOwnProfile
              ? null
              : ProfileActionBar(
                  profileName: _profile.name,
                  liked: _liked,
                  superLiked: _superLiked,
                  superLikeSending: _superLikeSending,
                  roseSending: _roseSheetOpen,
                  onRose: _showRose,
                  onLike: _toggleLike,
                  onSuperLike: _sendSuperLike,
                  onMessage: _startChat,
                ),
          interactionOverlay: _viewingOwnProfile
              ? null
              : IgnorePointer(
                  child: AmoraSuperLikeAnimation(
                    animation: _superLikeAnimation,
                    profileName: _profile.name,
                  ),
                ),
        ),
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(BrowseGridScreen.routeName);
    }
  }

  Future<void> _toggleLike() async {
    final relationships = ProfileRelationshipController.instance;
    if (_liked) {
      final removed = await showAmoraaProfileActionConfirmation(
        context: context,
        action: AmoraaProfileAction.unlike,
        profileName: _profile.name,
        onConfirm: () => relationships.removeLikePersisted(_profile.id),
      );
      if (removed == true && mounted) _snack('Like removed');
      return;
    }
    try {
      await relationships.likeProfilePersisted(_profile);
      if (mounted) _snack('Profile liked successfully');
    } on AuthException catch (error) {
      if (mounted) _snack(error.message);
    }
  }

  Future<void> _sendSuperLike() async {
    if (_superLikeSending) return;
    if (_superLiked) {
      await showAmoraaProfileActionConfirmation(
        context: context,
        action: AmoraaProfileAction.removeSuperLike,
        profileName: _profile.name,
        onConfirm: () => ProfileRelationshipController.instance
            .removeSuperLikePersisted(_profile.id),
      );
      return;
    }
    if (AmoraSession.isGuest) {
      await _requireAuth(_sendSuperLike);
      return;
    }
    final callback = widget.onSuperLike;
    final api = widget.api;
    if (callback == null && api == null) {
      _snack('Super Like is unavailable for this profile');
      return;
    }

    setState(() => _superLikeSending = true);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    try {
      late final bool sent;
      if (callback == null) {
        await api!.superLikeProfile(_profile.id);
        sent = true;
      } else {
        sent = await callback();
      }
      if (!mounted) return;
      if (!sent) {
        _superLikeAnimation.reset();
        _snack('Super Like could not be sent');
        return;
      }
      ProfileRelationshipController.instance.superLikeProfile(_profile);
      if (reduceMotion) {
        _snack('Super Like sent');
      } else {
        await _superLikeAnimation.forward(from: 0);
        if (mounted) _snack('Super Like sent');
      }
    } on AuthException catch (error) {
      if (mounted) {
        _superLikeAnimation.reset();
        _snack(error.userMessage);
      }
    } catch (_) {
      if (mounted) {
        _superLikeAnimation.reset();
        _snack('Super Like could not be sent');
      }
    } finally {
      if (mounted) setState(() => _superLikeSending = false);
    }
  }

  Future<void> _startChat() async {
    if (AmoraSession.isGuest) {
      _requireAuth(_startChat);
      return;
    }
    late final String conversationId;
    try {
      conversationId = await ChatRepository.instance
          .createConversationForProfile(_profile);
    } catch (_) {
      if (mounted) _snack('Chat is unavailable for this profile.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      ChatDetailScreen.routeName,
      arguments: ChatDetailArgs(
        conversationId: conversationId,
        recipientId: _profile.id,
        profileId: _profile.id,
        recipientName: _profile.name,
        recipientImage: _profile.imageUrl,
        recipientStatus: _profile.status,
      ),
    );
  }

  Future<void> _replyToPrompt(
    String promptId,
    String prompt,
    String answer,
  ) async {
    if (AmoraSession.isGuest) {
      _requireAuth(() => _replyToPrompt(promptId, prompt, answer));
      return;
    }
    late final String conversationId;
    try {
      conversationId = await ChatRepository.instance
          .createConversationForProfile(_profile);
    } catch (_) {
      if (mounted) _snack('Chat is unavailable for this profile.');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      ChatDetailScreen.routeName,
      arguments: ChatDetailArgs(
        conversationId: conversationId,
        recipientId: _profile.id,
        profileId: _profile.id,
        recipientName: _profile.name,
        recipientImage: _profile.imageUrl,
        recipientStatus: _profile.status,
        messageContext: ChatMessageContext.profilePrompt(
          promptId: promptId,
          title: prompt,
          detail: answer,
        ),
      ),
    );
  }

  Future<void> _showRose() async {
    if (_roseSheetOpen) return;
    if (AmoraSession.isGuest) {
      await _requireAuth(_showRose);
      return;
    }
    final repository = ChatRepository.instance;
    var conversationId = repository.conversationIdForProfile(_profile.id);
    final roseKey = RoseRepository.instance.newIdempotencyKey();
    setState(() => _roseSheetOpen = true);
    final sent = await showAmoraaRoseSheet(
      context: context,
      recipientName: _profile.name,
      onSend: (note) async {
        await RoseRepository.instance.send(
          recipientId: _profile.id,
          idempotencyKey: roseKey,
          conversationId: conversationId,
          note: note,
        );
        if (conversationId == null) {
          try {
            conversationId = await repository.createConversationForProfile(
              _profile,
            );
          } catch (_) {
            // A match is not required for a server-confirmed Rose.
          }
        }
        final chatConversationId = conversationId;
        if (chatConversationId != null) {
          try {
            await repository.sendMessage(
              chatConversationId,
              note.isEmpty ? 'Rose' : note,
              context: const ChatMessageContext.rose(),
            );
          } catch (_) {
            // The server-confirmed Rose remains successful even if the
            // optional conversation card cannot be created.
          }
        }
      },
    );
    if (!mounted) return;
    setState(() => _roseSheetOpen = false);
    if (!sent) return;
    final destinationConversationId = conversationId;
    if (destinationConversationId == null) {
      _snack('Rose sent to ${_profile.name}');
      return;
    }
    Navigator.of(context).pushNamed(
      ChatDetailScreen.routeName,
      arguments: ChatDetailArgs(
        conversationId: destinationConversationId,
        recipientId: _profile.id,
        profileId: _profile.id,
        recipientName: _profile.name,
        recipientImage: _profile.imageUrl,
        recipientStatus: _profile.status,
      ),
    );
  }

  Future<void> _toggleSave() async {
    if (AmoraSession.isGuest) {
      await _requireAuth(_toggleSave);
      return;
    }
    final relationships = ProfileRelationshipController.instance;
    if (_saved) {
      await showAmoraaProfileActionConfirmation(
        context: context,
        action: AmoraaProfileAction.unsave,
        profileName: _profile.name,
        onConfirm: () => relationships.removeSavedPersisted(_profile.id),
      );
      return;
    }
    try {
      await relationships.saveProfilePersisted(_profile);
    } on AuthException catch (error) {
      if (mounted) _snack(error.message);
    }
  }

  void _openWhyMatched() {
    if (AmoraSession.isGuest) {
      _requireAuth(_openWhyMatched);
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(WhyWeMatchedScreen.routeName, arguments: _profile);
  }

  Future<void> _requireAuth(VoidCallback action) {
    return AmoraSession.requireAuth(context: context, onAuthenticated: action);
  }

  void _openFullScreenGallery(int initialIndex) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AmoraaProfileFullscreenGallery(
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
                  'Report or block if something feels off. AMORAA keeps respectful conversations first.',
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
                    Navigator.of(context).pushNamed(
                      ReportFlowScreen.routeName,
                      arguments: ReportFlowArgs.profile(_profile),
                    );
                  },
                ),
                const SizedBox(height: AmoraSpacing.space12),
                if (_serverRelationship.matched &&
                    _serverRelationship.matchId != null) ...[
                  AppPrimaryButton(
                    label: 'Unmatch',
                    icon: Icons.heart_broken_rounded,
                    variant: AppPrimaryButtonVariant.outlined,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _unmatch();
                    },
                  ),
                  const SizedBox(height: AmoraSpacing.space12),
                ],
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

  Future<void> _showBlockDialog() async {
    if (_blocked) return;
    final blocked = await showBlockConfirmationDialog(
      context: context,
      userName: _profile.name,
      onConfirm: () async {
        if (widget.api != null) await widget.api!.block(_profile.id);
        ProfileRelationshipController.instance.blockProfile(_profile);
      },
    );
    if (blocked != true || !mounted) return;
    await showBlockedUserSuccessSheet(
      context: context,
      userName: _profile.name,
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _unmatch() async {
    final matchId = _serverRelationship.matchId;
    if (matchId == null || widget.api == null) return;
    try {
      await widget.api!.unmatch(matchId);
      if (!mounted) return;
      setState(() {
        _serverRelationship = PublicRelationshipState(
          liked: _serverRelationship.liked,
          superLiked: _serverRelationship.superLiked,
        );
      });
      _snack('Match removed');
    } on AuthException catch (error) {
      if (mounted) _snack(error.message);
    }
  }

  void _handleRelationshipUpdate() {
    if (mounted) setState(() {});
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
    required this.mode,
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
  final List<ProfilePhotoViewData> photos;
  final PageController controller;
  final int selectedIndex;
  final PublicProfileViewMode mode;
  final bool saved;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onMore;
  final ValueChanged<int> onOpen;
  final VoidCallback? onDoubleTap;

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
                          return AmoraaProfilePhotoView(
                            photo: photos[index],
                            width: imageConstraints.maxWidth,
                            height: imageConstraints.maxHeight,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            showTransferState: false,
                            semanticLabel:
                                '${profile.name} profile photo ${index + 1} of ${photos.length}',
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
            if (mode == PublicProfileViewMode.otherUser)
              Positioned(
                left: AmoraSpacing.space12,
                right: AmoraSpacing.space12,
                top: AmoraSpacing.space12,
                child: ProfileTopControls(
                  profileName: profile.name,
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
        color: AppColors.primary.withValues(alpha: .42),
      ),
    );
  }
}

class ProfileTopControls extends StatelessWidget {
  const ProfileTopControls({
    super.key,
    required this.profileName,
    required this.saved,
    required this.onBack,
    required this.onSave,
    required this.onMore,
  });

  final bool saved;
  final String profileName;
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
          tooltip: saved
              ? AmoraaProfileAction.unsave.semanticLabel(
                  amoraaProfileActionName(profileName),
                )
              : 'Save $profileName',
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
        ),
        const SizedBox(width: AmoraSpacing.space8),
      ],
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
    final title = <String>[
      profile.name.trim().isEmpty
          ? 'AMORAA member'
          : profile.name.split(' ').first,
      if (profile.age > 0) '${profile.age}',
    ].join(', ');
    final hasMetadata =
        profile.distance.trim().isNotEmpty ||
        profile.status.trim().isNotEmpty ||
        ProfileFormOptions.normalizeCity(profile.city).isNotEmpty;
    final badge = resolveAmoraaIdentityBadge(
      isAadhaarVerified: profile.verified,
      isPremium: profile.premium,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.headlineLarge.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
            ),
            if (badge != AmoraaIdentityBadgeType.none) ...[
              const SizedBox(width: AmoraSpacing.space8),
              AmoraaIdentityBadge(
                isAadhaarVerified: profile.verified,
                isPremium: profile.premium,
              ),
            ],
          ],
        ),
        if (profile.profession.trim().isNotEmpty) ...[
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
        ],
        if (hasMetadata) ...[
          const SizedBox(height: AmoraSpacing.space8),
          Wrap(
            spacing: AmoraSpacing.space12,
            runSpacing: AmoraSpacing.space4,
            children: [
              if (profile.distance.trim().isNotEmpty)
                _OverlayMeta(
                  icon: Icons.location_on_rounded,
                  text: profile.distance,
                ),
              if (profile.status.trim().isNotEmpty)
                _OverlayMeta(
                  icon: Icons.circle,
                  text: profile.status,
                  smallIcon: true,
                ),
              if (ProfileFormOptions.normalizeCity(profile.city).isNotEmpty)
                _OverlayMeta(
                  icon: Icons.location_city_rounded,
                  text: ProfileFormOptions.normalizeCity(profile.city),
                ),
            ],
          ),
        ],
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

typedef ProfilePromptReply =
    void Function(String promptId, String prompt, String answer);

class ProfileStory extends StatelessWidget {
  const ProfileStory({
    super.key,
    required this.profile,
    required this.mode,
    required this.blocked,
    this.onPromptReply,
    this.onWhyMatched,
    this.onReport,
    this.onBlock,
  });

  final DummyProfile profile;
  final PublicProfileViewMode mode;
  final bool blocked;
  final ProfilePromptReply? onPromptReply;
  final VoidCallback? onWhyMatched;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final hasQuickFacts = <String>[
      profile.height,
      ProfileFormOptions.displayEducation(profile.education),
      ...profile.languages,
      profile.intent,
      profile.smoking,
      profile.drinking,
      profile.weed,
    ].any((value) => value.trim().isNotEmpty);
    final hasRelationship = profile.intent.trim().isNotEmpty;
    final hasLifestyle = <String>[
      profile.smoking,
      profile.drinking,
      profile.weed,
      profile.religion,
    ].any((value) => value.trim().isNotEmpty);
    final hasInterests = ProfileInterestPolicy.visible(
      profile.interests,
    ).isNotEmpty;
    final hasPrompts = profile.promptAnswers.entries.any(
      (entry) => entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
    );
    final hasProfilePreferences = <String>[
      profile.hometown,
      profile.sexuality,
      ...profile.valuedQualities,
      ...profile.pronouns,
      ...profile.preferredTalkingHours,
      ...profile.loveLanguages,
    ].any((value) => value.trim().isNotEmpty);
    final hasConnectionDetails =
        profile.iceBreaker.trim().isNotEmpty ||
        profile.communicationStyle != null;
    final sections = <Widget>[
      if (hasQuickFacts)
        _SectionReveal(
          key: const ValueKey('public-profile-section-quick-facts'),
          child: ProfileQuickFacts(profile: profile),
        ),
      if (profile.bio.trim().isNotEmpty)
        _SectionReveal(
          key: const ValueKey('public-profile-section-about'),
          child: ProfileAboutSection(profile: profile),
        ),
      if (hasRelationship)
        _SectionReveal(
          key: const ValueKey('public-profile-section-relationship'),
          child: RelationshipIntentionsSection(profile: profile),
        ),
      if (hasLifestyle)
        _SectionReveal(
          key: const ValueKey('public-profile-section-lifestyle'),
          child: LifestyleGrid(profile: profile),
        ),
      if (hasProfilePreferences)
        _SectionReveal(
          key: const ValueKey('public-profile-section-preferences'),
          child: AmoraaProfilePreferenceDisplay(profile: profile),
        ),
      if (hasConnectionDetails)
        _SectionReveal(
          child: AmoraaConnectionProfileDetails(
            iceBreaker: profile.iceBreaker,
            communicationStyle: profile.communicationStyle,
          ),
        ),
      if (hasInterests)
        _SectionReveal(
          key: const ValueKey('public-profile-section-interests'),
          child: _InterestsSection(profile: profile),
        ),
      if (hasPrompts)
        _SectionReveal(
          key: const ValueKey('public-profile-section-prompts'),
          child: _ProfilePromptsSection(
            profile: profile,
            onReply: onPromptReply,
          ),
        ),
      if (mode == PublicProfileViewMode.otherUser && profile.score > 0)
        _SectionReveal(
          key: const ValueKey('public-profile-section-compatibility'),
          child: CompatibilitySection(
            profile: profile,
            onWhyMatched: onWhyMatched!,
          ),
        ),
      if (profile.verification.trim().isNotEmpty ||
          profile.status.trim().isNotEmpty)
        _SectionReveal(
          key: const ValueKey('public-profile-section-trust'),
          child: TrustAndSafetySection(
            profile: profile,
            blocked: blocked,
            showActions: mode == PublicProfileViewMode.otherUser,
            onReport: onReport,
            onBlock: onBlock,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          sections[index],
          if (index != sections.length - 1)
            SizedBox(
              height:
                  sections[index].key ==
                      const ValueKey('public-profile-section-lifestyle')
                  ? AmoraSpacing.space4
                  : AmoraSpacing.space24,
            ),
        ],
      ],
    );
  }
}

class _SectionReveal extends StatelessWidget {
  const _SectionReveal({super.key, required this.child});

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
      _SymbolicFact(
        Icons.school_rounded,
        'Education',
        ProfileFormOptions.displayEducation(profile.education),
      ),
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
      _SymbolicFact(
        ProfileAttributeIcons.smoking(profile.smoking),
        'Smoking',
        profile.smoking,
      ),
      _SymbolicFact(Icons.local_bar_outlined, 'Drinking', profile.drinking),
      _SymbolicFact(Icons.grass_rounded, 'Weed', profile.weed),
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
        ProfileAttributeIcons.smoking(profile.smoking),
        'Smoking',
        profile.smoking,
      ),
      _SymbolicFact(Icons.local_bar_outlined, 'Drinking', profile.drinking),
      _SymbolicFact(Icons.grass_rounded, 'Weed', profile.weed),
      _SymbolicFact(
        Icons.self_improvement_rounded,
        'Beliefs',
        profile.religion,
      ),
    ].where((item) => item.value.trim().isNotEmpty).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.dashboard_customize_outlined,
          title: 'Lifestyle',
        ),
        const SizedBox(height: AmoraSpacing.space16),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AmoraSpacing.space8) / 2;
            final tileHeight = _tileHeight(context, items, tileWidth);
            return Wrap(
              spacing: AmoraSpacing.space8,
              runSpacing: AmoraSpacing.space8,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: _LifestyleTile(item: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  double _tileHeight(
    BuildContext context,
    List<_SymbolicFact> items,
    double tileWidth,
  ) {
    final textWidth = (tileWidth - 70).clamp(0.0, double.infinity);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final labelStyle = AmoraTextStyles.labelSmall.copyWith(
      color: AppColors.textNeutral.withValues(alpha: .54),
    );
    final valueStyle = AmoraTextStyles.labelMedium.copyWith(
      color: AppColors.textNeutral,
      fontWeight: FontWeight.w700,
    );
    var contentHeight = 36.0;

    for (final item in items) {
      final label = TextPainter(
        text: TextSpan(text: item.label, style: labelStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: textWidth);
      final value = TextPainter(
        text: TextSpan(text: item.value, style: valueStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: textWidth);
      final textHeight = label.height + AmoraSpacing.space4 + value.height;
      if (textHeight > contentHeight) contentHeight = textHeight;
    }

    return (contentHeight + AmoraSpacing.space24 + 2)
        .clamp(76.0, double.infinity)
        .toDouble();
  }
}

class _LifestyleTile extends StatelessWidget {
  const _LifestyleTile({required this.item});

  final _SymbolicFact item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.label}, ${item.value}',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(AmoraSpacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: .55),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisSize: MainAxisSize.min,
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
        ),
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
    final interests = ProfileInterestPolicy.visible(profile.interests)
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
            Icon(
              ProfileAttributeIcons.interest(label),
              color: AppColors.secondary,
              size: 17,
            ),
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
  const _ProfilePromptsSection({required this.profile, required this.onReply});

  final DummyProfile profile;
  final ProfilePromptReply? onReply;

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
        for (var index = 0; index < prompts.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
            child: ProfilePromptCard(
              promptId: '${profile.id}-prompt-$index',
              prompt: prompts[index].key,
              answer: prompts[index].value,
              onReply: onReply == null
                  ? null
                  : () => onReply!(
                      '${profile.id}-prompt-$index',
                      prompts[index].key,
                      prompts[index].value,
                    ),
            ),
          ),
      ],
    );
  }
}

class ProfilePromptCard extends StatelessWidget {
  const ProfilePromptCard({
    super.key,
    required this.promptId,
    required this.prompt,
    required this.answer,
    this.onReply,
  });

  final String promptId;
  final String prompt;
  final String answer;
  final VoidCallback? onReply;

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
          if (onReply != null) ...[
            const SizedBox(height: AmoraSpacing.space16),
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Reply to this profile prompt',
                child: TextButton.icon(
                  key: ValueKey('profile-prompt-reply-$promptId'),
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppColors.tertiary.withValues(alpha: .30),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.reply_rounded, size: 20),
                  label: const Text('Reply'),
                ),
              ),
            ),
          ],
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
      ...profile.loveLanguages,
      ...ProfileInterestPolicy.visible(profile.interests).take(3),
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
                  'AMORAA supplied match score reflects the profile signals already available for this connection.',
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
          ),
        ],
      ),
    );
  }
}

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
    required this.showActions,
    this.onReport,
    this.onBlock,
  });

  final DummyProfile profile;
  final bool blocked;
  final bool showActions;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final verification = profile.verification.trim();
    final normalizedVerification = verification.toLowerCase();
    final showVerificationDetail =
        verification.isNotEmpty &&
        normalizedVerification != 'verified' &&
        normalizedVerification != 'verified profile';
    final status = profile.status.trim();
    final showStatus =
        status.isNotEmpty &&
        !(profile.verified && status.toLowerCase() == 'verified');
    return _SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.shield_outlined,
            title: 'Safety & trust',
          ),
          if (showVerificationDetail) ...[
            const SizedBox(height: AmoraSpacing.space16),
            _TrustRow(icon: Icons.verified_user_rounded, text: verification),
          ],
          if (showStatus) ...[
            const SizedBox(height: AmoraSpacing.space8),
            _TrustRow(icon: Icons.schedule_rounded, text: status),
          ],
          if (showActions) ...[
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
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
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
    this.profileName,
    required this.liked,
    required this.superLiked,
    required this.superLikeSending,
    required this.roseSending,
    required this.onRose,
    required this.onLike,
    required this.onSuperLike,
    required this.onMessage,
  });

  static const double height = 82;
  static const double contentInset = 106;

  final bool liked;
  final String? profileName;
  final bool superLiked;
  final bool superLikeSending;
  final bool roseSending;
  final VoidCallback onRose;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final safeName = amoraaProfileActionName(profileName);
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
                  key: const ValueKey('profile-rose-button'),
                  label: 'Rose',
                  semanticLabel: 'Send a Rose',
                  icon: Icons.local_florist_rounded,
                  loading: roseSending,
                  onTap: onRose,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  key: const ValueKey('profile-super-like-button'),
                  label: 'Super Like',
                  semanticLabel: superLiked
                      ? AmoraaProfileAction.removeSuperLike.semanticLabel(
                          safeName,
                        )
                      : 'Super Like $safeName',
                  icon: Icons.star_rounded,
                  selected: superLiked,
                  loading: superLikeSending,
                  onTap: onSuperLike,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  key: const ValueKey('profile-message-button'),
                  label: 'Message',
                  semanticLabel: 'Message this profile',
                  icon: Icons.chat_bubble_rounded,
                  onTap: onMessage,
                ),
              ),
              Expanded(
                child: _ProfileActionButton(
                  key: const ValueKey('profile-like-button'),
                  label: 'Like',
                  semanticLabel: liked
                      ? AmoraaProfileAction.unlike.semanticLabel(safeName)
                      : 'Like $safeName',
                  icon: Icons.favorite_rounded,
                  selected: liked,
                  dominant: true,
                  onTap: onLike,
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
    required this.semanticLabel,
    this.selected = false,
    this.dominant = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool selected;
  final bool dominant;
  final bool loading;

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
    final filled = widget.selected;
    return Semantics(
      button: true,
      enabled: !widget.loading,
      label: widget.semanticLabel,
      child: Tooltip(
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
                onTap: widget.loading ? null : widget.onTap,
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
                          color: filled
                              ? AppColors.secondary
                              : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: filled
                                ? AppColors.secondary
                                : AppColors.tertiary,
                          ),
                        ),
                        child: widget.loading
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary,
                                ),
                              )
                            : Icon(
                                widget.icon,
                                color: filled
                                    ? AppColors.surface
                                    : AppColors.primary,
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
                          fontSize: 10.5,
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
      ),
    );
  }
}

class AmoraaProfileFullscreenGallery extends StatefulWidget {
  const AmoraaProfileFullscreenGallery({
    super.key,
    required this.profile,
    required this.photos,
    required this.initialIndex,
  });

  final DummyProfile profile;
  final List<ProfilePhotoViewData> photos;
  final int initialIndex;

  @override
  State<AmoraaProfileFullscreenGallery> createState() =>
      _AmoraaProfileFullscreenGalleryState();
}

class _AmoraaProfileFullscreenGalleryState
    extends State<AmoraaProfileFullscreenGallery> {
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
                      return AmoraaProfilePhotoView(
                        photo: widget.photos[index],
                        width: imageConstraints.maxWidth,
                        height: imageConstraints.maxHeight,
                        fit: BoxFit.contain,
                        showTransferState: false,
                        semanticLabel:
                            '${widget.profile.name} full-screen profile photo ${index + 1} of ${widget.photos.length}',
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
            ),
          ),
        ],
      ),
    );
  }
}

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
      ),
    );
  }
}
