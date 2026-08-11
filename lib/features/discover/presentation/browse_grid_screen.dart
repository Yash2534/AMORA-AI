import 'dart:async';
import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_super_like_animation.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/amoraa_confirm_action_sheet.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

List<String> cleanDiscoverPhotoPaths(
  Iterable<String> candidates, {
  required String fallback,
}) {
  final seen = <String>{};
  final photos = <String>[];
  for (final candidate in candidates) {
    final photo = candidate.trim();
    if (photo.isNotEmpty && seen.add(photo)) photos.add(photo);
  }
  if (photos.isEmpty) photos.add(fallback);
  return List<String>.unmodifiable(photos);
}

class BrowseGridScreen extends StatefulWidget {
  const BrowseGridScreen({
    super.key,
    this.showNavigation = true,
    this.controller,
    this.apiService,
  });

  static const routeName = '/browse';

  final bool showNavigation;
  final DiscoverActionController? controller;
  final DiscoverApiService? apiService;

  @override
  State<BrowseGridScreen> createState() => _BrowseGridScreenState();
}

class _BrowseGridScreenState extends State<BrowseGridScreen>
    with SingleTickerProviderStateMixin {
  static const _velocityThreshold = 650.0;
  static const _quickFilters = <_QuickFilter>[
    _QuickFilter('Verified', Icons.verified_rounded),
    _QuickFilter('Online', Icons.circle_rounded),
    _QuickFilter('Nearby', Icons.near_me_rounded),
    _QuickFilter('Most Compatible', Icons.auto_awesome_rounded),
    _QuickFilter('Recently Active', Icons.schedule_rounded),
    _QuickFilter('Music Lovers', Icons.music_note_rounded),
    _QuickFilter('Travel', Icons.flight_takeoff_rounded),
    _QuickFilter('Marriage', Icons.favorite_rounded),
    _QuickFilter('Coffee Dates', Icons.local_cafe_rounded),
  ];

  late final FocusNode _keyboardFocus;
  late final AnimationController _superLikeAnimation;
  List<DummyProfile> _profiles = const <DummyProfile>[];
  DiscoverActionController? _controller;
  late final DiscoverApiService _discoverApi;
  Timer? _loadingTimer;
  Object? _error;
  bool _loading = true;
  bool _dragging = false;
  bool _horizontalDragLocked = false;
  final ValueNotifier<double> _dragOffsetX = ValueNotifier<double>(0);
  final Set<String> _selectedQuickFilters = <String>{};
  final Map<String, int> _photoIndices = <String, int>{};
  String _superLikeProfileName = '';
  int _nextPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  DiscoverActionController get _actions => _controller!;

  @override
  void initState() {
    super.initState();
    _keyboardFocus = FocusNode(debugLabel: 'Discover keyboard shortcuts');
    _discoverApi = widget.apiService ?? DiscoverApiService();
    _superLikeAnimation = AnimationController(
      vsync: this,
      duration: AmoraSuperLikeAnimation.duration,
    );
    unawaited(_loadProfiles());
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _keyboardFocus.dispose();
    _superLikeAnimation.dispose();
    _dragOffsetX.dispose();
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    _loadingTimer?.cancel();
    setState(() => _loading = true);
    final result = await _discoverApi.getFeed(
      page: 1,
      communicationStyles: appliedProfilePreferenceFilters
          .value
          .communicationStyles
          .map((style) => style.storageValue),
    );
    if (!mounted) return;
    if (!result.success || result.data == null) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
      return;
    }
    setState(() {
      _profiles = result.data!.profiles
          .map(_profileFromRemote)
          .toList(growable: false);
      _nextPage = result.data!.nextPage ?? 2;
      _hasMore = result.data!.hasMore;
      _error = null;
      _replaceController();
      _loading = false;
    });
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    final result = await _discoverApi.getFeed(
      page: _nextPage,
      communicationStyles: appliedProfilePreferenceFilters
          .value
          .communicationStyles
          .map((style) => style.storageValue),
    );
    _loadingMore = false;
    if (!mounted) return;
    if (!result.success || result.data == null) {
      _showSyncError(result.message);
      return;
    }
    final profiles = result.data!.profiles
        .map(_profileFromRemote)
        .toList(growable: false);
    setState(() {
      _profiles = [..._profiles, ...profiles];
      _nextPage = result.data!.nextPage ?? (_nextPage + 1);
      _hasMore = result.data!.hasMore;
    });
    _actions.appendProfileIds(profiles.map((profile) => profile.id));
  }

  DummyProfile _profileFromRemote(Map<String, dynamic> values) {
    String text(Object? value) => value?.toString() ?? '';
    List<String> strings(Object? value) => value is List
        ? value
              .map(text)
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    Map<String, String> prompts(Object? value) => value is Map
        ? value.map((key, item) => MapEntry(key.toString(), text(item)))
        : const <String, String>{};
    final lifestyle = values['lifestyle'];
    final lifestyleValues = lifestyle is Map
        ? lifestyle.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .toList(growable: false)
        : strings(lifestyle);
    final distance = values['distance'];
    return DummyProfile(
      id: text(values['id']),
      gender: text(values['gender']).toLowerCase() == 'female'
          ? Gender.female
          : Gender.male,
      name: text(values['name']),
      age: (values['age'] as num?)?.toInt() ?? 0,
      city: text(values['city']),
      profession: text(values['profession']),
      education: text(values['education']),
      distance: distance is num ? '${distance.round()} km' : text(distance),
      score: (values['score'] as num?)?.round() ?? 0,
      intent: text(values['intent']),
      personality: text(values['personality']),
      status: text(values['status']),
      bio: text(values['bio']),
      interests: strings(values['interests']),
      imageUrl: text(values['imageUrl']),
      gallery: strings(values['gallery']),
      languages: strings(values['languages']),
      verification: text(values['verification']).toLowerCase() == 'verified'
          ? 'Verified'
          : 'Not verified',
      lifestyle: lifestyleValues,
      promptAnswers: prompts(values['promptAnswers']),
      travelPreference: text(values['travelPreference']),
      musicTaste: text(values['musicTaste']),
      foodPreference: text(values['foodPreference']),
      weekendPlan: text(values['weekendPlan']),
      petPreference: text(values['petPreference']),
      coffeePreference: text(values['coffeePreference']),
      religion: text(values['religion']),
      community: text(values['community']),
      height: text(values['height']),
      fitnessLevel: text(values['fitnessLevel']),
      smoking: text(values['smoking']),
      drinking: text(values['drinking']),
      weed: text(values['weed']),
      children: text(values['children']),
      loveLanguage: text(values['loveLanguage']),
      greenFlags: strings(values['greenFlags']),
      redFlags: strings(values['redFlags']),
      familyValues: text(values['familyValues']),
      dateIdeas: strings(values['dateIdeas']),
      hometown: text(values['hometown']),
      valuedQualities: strings(values['valuedQualities']),
      pronouns: strings(values['pronouns']),
      sexuality: text(values['sexuality']),
      preferredTalkingHours: strings(values['preferredTalkingHours']),
      loveLanguages: strings(values['loveLanguages']),
      communicationStyle: CommunicationStyle.fromStorageValue(
        values['communicationStyle'],
      ),
    );
  }

  List<DummyProfile> get _filteredProfiles {
    return _profiles
        .where((profile) {
          final distance = int.tryParse(profile.distance.split(' ').first);
          for (final filter in _selectedQuickFilters) {
            switch (filter) {
              case 'Verified':
                if (!profile.verified) return false;
                break;
              case 'Online':
                if (profile.status != 'Online now') return false;
                break;
              case 'Nearby':
                if (distance != null && distance > 50) return false;
                break;
              case 'Most Compatible':
                if (profile.score < 90) return false;
                break;
              case 'Recently Active':
                if (!profile.status.toLowerCase().contains('active') &&
                    profile.status != 'Online now') {
                  return false;
                }
                break;
              case 'Music Lovers':
                if (!_containsAny(<String>[
                  profile.musicTaste,
                  ...profile.interests,
                ], 'music')) {
                  return false;
                }
                break;
              case 'Travel':
                if (!_containsAny(<String>[
                  profile.travelPreference,
                  ...profile.interests,
                ], 'travel')) {
                  return false;
                }
                break;
              case 'Marriage':
                if (!profile.intent.toLowerCase().contains('marriage')) {
                  return false;
                }
                break;
              case 'Coffee Dates':
                if (!_containsAny(<String>[
                  profile.coffeePreference,
                  ...profile.interests,
                ], 'coffee')) {
                  return false;
                }
                break;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  bool _containsAny(Iterable<String> values, String needle) =>
      values.any((value) => value.toLowerCase().contains(needle));

  void _replaceController() {
    if (widget.controller case final injected?) {
      _controller = injected;
      return;
    }
    _controller?.dispose();
    final profiles = _filteredProfiles;
    _controller = DiscoverActionController(
      profileIds: profiles.map((profile) => profile.id),
      mutualLikeProfileIds: profiles
          .where((profile) => profile.score >= 94)
          .map((profile) => profile.id),
      apiService: _discoverApi,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  DummyProfile? _profileFor(String? id) {
    if (id == null) return null;
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showNavigation
          ? const FloatingBottomNav(activeTab: AmoraNavTab.discover)
          : null,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Focus(
                focusNode: _keyboardFocus,
                autofocus: true,
                onKeyEvent: _handleKeyEvent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AmoraaMainPageHeader.pageHorizontalInset,
                    AmoraaMainPageHeader.safeTopSpacing,
                    AmoraaMainPageHeader.pageHorizontalInset,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DiscoverHeader(
                        onNotifications: () => Navigator.of(
                          context,
                        ).pushNamed(NotificationsHubScreen.routeName),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AmoraSpacing.space4,
                        ),
                        child: _DiscoverFilterRail(
                          filters: _quickFilters,
                          selected: _selectedQuickFilters,
                          onFilters: _openFilters,
                          onToggle: _toggleQuickFilter,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AmoraSpacing.space4,
                          ),
                          child: _buildExperience(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AmoraSuperLikeAnimation(
                    animation: _superLikeAnimation,
                    profileName: _superLikeProfileName,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperience() {
    if (_loading) return const _DiscoverSkeleton();
    if (_error != null) {
      return _DiscoverError(onRetry: () => setState(_loadProfiles));
    }
    return AnimatedBuilder(
      animation: _actions,
      builder: (context, _) {
        final profile = _profileFor(_actions.currentProfileId);
        if (profile == null) {
          return _DiscoverEmpty(
            onFilters: _openFilters,
            onRefresh: _resetFiltersAndDeck,
          );
        }
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        return AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 260),
          reverseDuration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            children: [...previousChildren, ?currentChild],
          ),
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .025),
                  end: Offset.zero,
                ).animate(fade),
                child: ScaleTransition(
                  scale: Tween(begin: .985, end: 1.0).animate(fade),
                  child: child,
                ),
              ),
            );
          },
          child: LayoutBuilder(
            key: ValueKey('discover-deck-${profile.id}'),
            builder: (context, constraints) {
              final width = math.min(512.0, constraints.maxWidth);
              final desiredHeight = (width * 1.72).clamp(420.0, 760.0);
              final availableHeight = math.max(0.0, constraints.maxHeight - 16);
              final height = math.min(availableHeight, desiredHeight);
              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: _buildDraggableCard(profile, width),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(DummyProfile profile, double width) {
    final photos = _photosFor(profile);
    final photoIndex = (_photoIndices[profile.id] ?? 0).clamp(
      0,
      photos.length - 1,
    );
    return ValueListenableBuilder<double>(
      valueListenable: _dragOffsetX,
      builder: (context, dragX, _) {
        final progress = (dragX / width).clamp(-1.0, 1.0);
        final duration = _dragging ? Duration.zero : AmoraMotion.selection;
        return GestureDetector(
          key: ValueKey('discover-profile-card-${profile.id}'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _actions.isTransitioning
              ? null
              : (_) {
                  _dragging = true;
                  _horizontalDragLocked = true;
                },
          onHorizontalDragUpdate: _actions.isTransitioning
              ? null
              : (details) {
                  if (!_horizontalDragLocked) return;
                  _dragOffsetX.value = (_dragOffsetX.value + details.delta.dx)
                      .clamp(-width, width);
                },
          onHorizontalDragCancel: _actions.isTransitioning ? null : _springBack,
          onHorizontalDragEnd: _actions.isTransitioning
              ? null
              : (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  final horizontalOffset = _dragOffsetX.value;
                  final shouldComplete =
                      horizontalOffset.abs() >= width * .27 ||
                      velocity.abs() >= _velocityThreshold;
                  if (!shouldComplete) {
                    _springBack();
                    return;
                  }
                  _performAction(
                    profile,
                    action: velocity == 0
                        ? (horizontalOffset > 0
                              ? DiscoverAction.like
                              : DiscoverAction.pass)
                        : (velocity > 0
                              ? DiscoverAction.like
                              : DiscoverAction.pass),
                    width: width,
                  );
                },
          child: AnimatedSlide(
            key: const ValueKey('discover-card-slide'),
            offset: Offset(progress * 1.5, 0),
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedRotation(
              turns: progress * (7 / 360),
              duration: duration,
              curve: Curves.easeOutCubic,
              child: _DiscoverProfileCard(
                profile: profile,
                dragProgress: progress,
                photos: photos,
                photoIndex: photoIndex,
                enabled: !_actions.isTransitioning,
                canRewind: _actions.canRewind,
                onPreviousPhoto: () => _changePhoto(profile, photos, -1),
                onNextPhoto: () => _changePhoto(profile, photos, 1),
                onOpenProfile: () => _openProfile(profile),
                onPass: () => _performAction(
                  profile,
                  action: DiscoverAction.pass,
                  width: width,
                ),
                onUndo: _rewind,
                onSuperLike: () => _sendSuperLike(profile),
                onLike: () => _performAction(
                  profile,
                  action: DiscoverAction.like,
                  width: width,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _springBack() {
    _dragging = false;
    _horizontalDragLocked = false;
    _dragOffsetX.value = 0;
  }

  Future<void> _performAction(
    DummyProfile profile, {
    required DiscoverAction action,
    double? width,
  }) async {
    if (_actions.isTransitioning) return;
    HapticFeedback.selectionClick();
    final exitDistance = math.max(
      (width ?? MediaQuery.sizeOf(context).width) * 1.4,
      420.0,
    );
    _dragging = false;
    _horizontalDragLocked = false;
    _dragOffsetX.value = action == DiscoverAction.like
        ? exitDistance
        : -exitDistance;
    var saved = false;
    if (action == DiscoverAction.like) {
      saved = await _actions.likeProfile();
      if (saved) ProfileRelationshipController.instance.likeProfile(profile);
      if (!saved && mounted) {
        _showSyncError(_actions.lastError ?? 'Unable to save this like.');
      }
    } else {
      saved = await _actions.rejectProfile();
      if (!saved && mounted) {
        _showSyncError(_actions.lastError ?? 'Unable to save this pass.');
      }
    }
    if (!mounted) return;
    setState(() {
      _photoIndices.remove(profile.id);
    });
    _dragOffsetX.value = 0;
    if (action == DiscoverAction.like && saved) {
      final matched = _actions.matchedProfileId == profile.id;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 900),
            content: Text(
              matched
                  ? 'You and ${profile.name} liked each other'
                  : 'Liked ${profile.name}',
            ),
          ),
        );
      if (matched) {
        _actions.consumeMatch();
      }
    }
    unawaited(_loadNextPage());
  }

  Future<void> _rewind() async {
    if (!_actions.canRewind) return;
    final entry = _actions.history.last;
    HapticFeedback.selectionClick();
    final removalAction = switch (entry.action) {
      DiscoverAction.like => AmoraaProfileAction.unlike,
      DiscoverAction.superLike => AmoraaProfileAction.removeSuperLike,
      _ => null,
    };
    if (removalAction == null) {
      final saved = await _actions.rewindProfile();
      if (!saved && mounted) {
        _showSyncError(_actions.lastError ?? 'Unable to rewind this swipe.');
      }
      return;
    }
    final profile = _profileFor(entry.profileId);
    await showAmoraaProfileActionConfirmation(
      context: context,
      action: removalAction,
      profileName: profile?.name,
      onConfirm: () async {
        final saved = await _actions.rewindProfile();
        if (!saved && mounted) {
          _showSyncError(_actions.lastError ?? 'Unable to rewind this swipe.');
        }
        if (saved && entry.action == DiscoverAction.like) {
          ProfileRelationshipController.instance.removeLike(entry.profileId);
        } else if (saved) {
          ProfileRelationshipController.instance.removeSuperLike(
            entry.profileId,
          );
        }
      },
    );
  }

  List<String> _photosFor(DummyProfile profile) {
    return cleanDiscoverPhotoPaths(<String>[
      profile.imageUrl,
      ...profile.gallery,
    ], fallback: profile.fallbackAsset);
  }

  void _changePhoto(DummyProfile profile, List<String> photos, int delta) {
    if (_actions.isTransitioning || photos.length < 2) return;
    final current = (_photoIndices[profile.id] ?? 0).clamp(
      0,
      photos.length - 1,
    );
    final next = (current + delta).clamp(0, photos.length - 1);
    if (next == current) return;
    setState(() => _photoIndices[profile.id] = next);

    final preloadIndex = next + 1;
    if (preloadIndex < photos.length) {
      final nextPhoto = photos[preloadIndex];
      final uri = Uri.tryParse(nextPhoto);
      if (uri != null && uri.hasScheme) {
        precacheImage(NetworkImage(nextPhoto), context);
      } else {
        final asset = AppImages.resolveAsset(
          nextPhoto,
          fallback: profile.fallbackAsset,
        );
        precacheImage(AssetImage(asset), context);
      }
    }
  }

  Future<void> _sendSuperLike(DummyProfile profile) {
    return AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () async {
        if (_actions.isTransitioning) return;
        HapticFeedback.mediumImpact();
        _superLikeProfileName = profile.name;
        final saved = await _actions.superLikeProfile();
        if (saved) {
          ProfileRelationshipController.instance.superLikeProfile(profile);
        }
        if (!saved && mounted) {
          _showSyncError(
            _actions.lastError ?? 'Unable to save this Super Like.',
          );
        }
        if (!mounted) return;
        setState(() => _photoIndices.remove(profile.id));
        if (!MediaQuery.disableAnimationsOf(context)) {
          await _superLikeAnimation.forward(from: 0);
          if (!mounted) return;
        }
        if (saved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1200),
                content: const Text('Super Like sent'),
              ),
            );
        }
        unawaited(_loadNextPage());
      },
    );
  }

  Future<void> _openProfile(DummyProfile profile) async {
    final decision = await Navigator.of(context).push(
      MaterialPageRoute<Object?>(
        settings: RouteSettings(
          name: ProfileDetailScreen.routeName,
          arguments: profile,
        ),
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          api: PhaseTwoApiService.instance,
          onSuperLike: () async {
            if (_actions.currentProfileId != profile.id) return false;
            final sent = await _actions.superLikeProfile();
            if (sent) {
              ProfileRelationshipController.instance.superLikeProfile(profile);
            } else if (mounted) {
              _showSyncError(
                _actions.lastError ?? 'Unable to save this Super Like.',
              );
            }
            return sent;
          },
        ),
      ),
    );
    if (!mounted || decision == null) return;
    await _performAction(
      profile,
      action: decision == ProfileDetailDecision.like
          ? DiscoverAction.like
          : DiscoverAction.pass,
    );
  }

  Future<void> _openFilters() async {
    final applied = await Navigator.of(
      context,
    ).pushNamed(AdvancedFiltersScreen.routeName);
    if (mounted && applied == true) await _loadProfiles();
  }

  void _toggleQuickFilter(String filter) {
    setState(() {
      if (!_selectedQuickFilters.add(filter)) {
        _selectedQuickFilters.remove(filter);
      }
      _replaceController();
      _photoIndices.clear();
    });
    _dragOffsetX.value = 0;
  }

  void _resetFiltersAndDeck() {
    setState(() {
      _selectedQuickFilters.clear();
      _photoIndices.clear();
    });
    _dragOffsetX.value = 0;
    unawaited(_loadProfiles());
  }

  void _showSyncError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _keyboardAction(DiscoverAction action) {
    final profile = _profileFor(_controller?.currentProfileId);
    if (profile != null) _performAction(profile, action: action);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _keyboardAction(DiscoverAction.pass);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _keyboardAction(DiscoverAction.like);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _DiscoverFilterRail extends StatelessWidget {
  const _DiscoverFilterRail({
    required this.filters,
    required this.selected,
    required this.onFilters,
    required this.onToggle,
  });

  final List<_QuickFilter> filters;
  final Set<String> selected;
  final VoidCallback onFilters;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('discover-filter-rail'),
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AmoraSpacing.space20),
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        children: [
          _DiscoverFilterChip(
            key: const ValueKey('discover-filters-button'),
            label: 'Filters',
            icon: Icons.tune_rounded,
            selected: false,
            onTap: onFilters,
          ),
          for (final filter in filters) ...[
            const SizedBox(width: 5),
            _DiscoverFilterChip(
              key: ValueKey('discover-filter-${filter.label}'),
              label: filter.label,
              icon: filter.icon,
              selected: selected.contains(filter.label),
              onTap: () => onToggle(filter.label),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return AmoraaMainPageHeader(
      titleWidget: Semantics(
        header: true,
        image: true,
        label: 'AMORAA',
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            AmoraBrandAssets.wordmark,
            width: AmoraHeaderTokens.discoverLogoWidth,
            height: AmoraHeaderTokens.discoverLogoHeight,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
      actions: [
        AmoraaMainPageHeaderAction(
          key: const ValueKey('discover-notifications'),
          tooltip: 'Notifications',
          semanticLabel: 'Open notifications',
          icon: Icons.notifications_none_rounded,
          onPressed: onNotifications,
        ),
      ],
    );
  }
}

class _DiscoverFilterChip extends StatefulWidget {
  const _DiscoverFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DiscoverFilterChip> createState() => _DiscoverFilterChipState();
}

class _DiscoverFilterChipState extends State<_DiscoverFilterChip>
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

  void _animate(double target, {double velocity = 0}) {
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .75, stiffness: 520, damping: 30),
        _scale.value,
        target,
        velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _animate(.96, velocity: -1),
      onPointerUp: (_) => _animate(1, velocity: 1),
      onPointerCancel: (_) => _animate(1),
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: widget.selected ? AppColors.primary : AppColors.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: widget.selected
                  ? AppColors.primary
                  : AppColors.secondary.withValues(alpha: .55),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.selected
                        ? AppColors.surface
                        : AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: widget.selected
                          ? AppColors.surface
                          : AppColors.text,
                      fontWeight: FontWeight.w600,
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

class _DiscoverProfileCard extends StatelessWidget {
  const _DiscoverProfileCard({
    required this.profile,
    required this.dragProgress,
    required this.photos,
    required this.photoIndex,
    required this.enabled,
    required this.canRewind,
    required this.onPreviousPhoto,
    required this.onNextPhoto,
    required this.onOpenProfile,
    required this.onPass,
    required this.onUndo,
    required this.onSuperLike,
    required this.onLike,
  });

  final DummyProfile profile;
  final double dragProgress;
  final List<String> photos;
  final int photoIndex;
  final bool enabled;
  final bool canRewind;
  final VoidCallback onPreviousPhoto;
  final VoidCallback onNextPhoto;
  final VoidCallback onOpenProfile;
  final VoidCallback onPass;
  final VoidCallback onUndo;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: 28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .19),
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.tertiary.withValues(alpha: .32),
                    child: Semantics(
                      image: true,
                      label: 'Photo ${photoIndex + 1} of ${photos.length}',
                      child: Hero(
                        tag: 'profile-image-${profile.id}',
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [...previousChildren, ?currentChild],
                            );
                          },
                          child: AmoraProfileImage(
                            key: ValueKey(
                              'discover-photo-${profile.id}-$photoIndex',
                            ),
                            imageUrl: photos[photoIndex],
                            assetPath: photos[photoIndex],
                            initials: profile.initials,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            borderRadius: BorderRadius.zero,
                            semanticLabel:
                                '${profile.name} profile photo ${photoIndex + 1}',
                          ),
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .40),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      key: ValueKey('discover-photo-progress-${profile.id}'),
                      left: 14,
                      right: 14,
                      top: 11,
                      child: _ProfilePhotoProgress(
                        count: photos.length,
                        currentIndex: photoIndex,
                      ),
                    ),
                  Positioned(
                    left: 20,
                    top: 24,
                    child: _SwipeFeedback(
                      label: 'LIKE',
                      icon: Icons.favorite_rounded,
                      color: AppColors.secondary,
                      opacity: dragProgress.clamp(0.0, 1.0),
                      angle: -.12,
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 24,
                    child: _SwipeFeedback(
                      label: 'Not Now',
                      icon: Icons.close_rounded,
                      color: AppColors.primary,
                      opacity: (-dragProgress).clamp(0.0, 1.0),
                      angle: .12,
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  label: 'Previous profile photo',
                                  child: GestureDetector(
                                    key: const ValueKey(
                                      'discover-previous-photo',
                                    ),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onPreviousPhoto,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  label: 'Next profile photo',
                                  child: GestureDetector(
                                    key: const ValueKey('discover-next-photo'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onNextPhoto,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(flex: 2, child: SizedBox.expand()),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 62,
                    child: Semantics(
                      button: true,
                      label: 'View profile for ${profile.name}',
                      child: GestureDetector(
                        key: const ValueKey('discover-open-profile'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onOpenProfile,
                        child: _ProfileOverlay(profile: profile),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 0,
          child: _DiscoverActionBar(
            enabled: enabled,
            canRewind: canRewind,
            onPass: onPass,
            onUndo: onUndo,
            onSuperLike: onSuperLike,
            onLike: onLike,
          ),
        ),
      ],
    );
  }
}

class _ProfilePhotoProgress extends StatelessWidget {
  const _ProfilePhotoProgress({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Photo ${currentIndex + 1} of $count',
      child: Row(
        children: [
          for (var index = 0; index < count; index++) ...[
            if (index > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 3,
                decoration: BoxDecoration(
                  color: index == currentIndex
                      ? AppColors.secondary
                      : AppColors.surface.withValues(alpha: .48),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileOverlay extends StatelessWidget {
  const _ProfileOverlay({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if (profile.profession.trim().isNotEmpty) profile.profession,
      if (profile.distance.trim().isNotEmpty) profile.distance,
    ];
    final languages = profile.languages
        .where((language) => language.trim().isNotEmpty)
        .take(3)
        .join(' • ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resolveAmoraaIdentityBadge(
              isAadhaarVerified: profile.verified,
              isPremium: profile.premium,
            ) !=
            AmoraaIdentityBadgeType.none) ...[
          AmoraaIdentityBadge(
            isAadhaarVerified: profile.verified,
            isPremium: profile.premium,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          '${profile.name}, ${profile.age}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.profileName.copyWith(
            color: AppColors.surface,
            fontSize: 28,
            height: 1.05,
          ),
        ),
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            metadata.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (languages.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            languages,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.surface.withValues(alpha: .9),
            ),
          ),
        ],
        if (profile.intent.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.favorite_outline_rounded,
                color: AppColors.tertiary,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  profile.intent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final interest in ProfileInterestPolicy.visible(
              profile.interests,
            ).toSet().take(3))
              _InterestPill(label: interest),
          ],
        ),
      ],
    );
  }
}

class _InterestPill extends StatelessWidget {
  const _InterestPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.labelSmall.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SwipeFeedback extends StatelessWidget {
  const _SwipeFeedback({
    required this.label,
    required this.icon,
    required this.color,
    required this.opacity,
    required this.angle,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .94),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AmoraTextStyles.labelLarge.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverActionBar extends StatelessWidget {
  const _DiscoverActionBar({
    required this.enabled,
    required this.canRewind,
    required this.onPass,
    required this.onUndo,
    required this.onSuperLike,
    required this.onLike,
  });

  final bool enabled;
  final bool canRewind;
  final VoidCallback onPass;
  final VoidCallback onUndo;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.tertiary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .15),
            blurRadius: 24,
            spreadRadius: -7,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DiscoverActionButton(
              key: const ValueKey('discover-pass-button'),
              label: 'Not Now',
              icon: Icons.close_rounded,
              foreground: AppColors.secondary,
              onPressed: enabled ? onPass : null,
            ),
            _DiscoverActionButton(
              key: const ValueKey('discover-undo-button'),
              label: 'Undo previous action',
              icon: Icons.undo_rounded,
              foreground: AppColors.primary,
              onPressed: enabled && canRewind ? onUndo : null,
            ),
            _DiscoverActionButton(
              key: const ValueKey('discover-super-like-button'),
              label: 'Super Like profile',
              icon: Icons.star_rounded,
              filled: true,
              onPressed: enabled ? onSuperLike : null,
            ),
            _DiscoverActionButton(
              key: const ValueKey('discover-like-button'),
              label: 'Like profile',
              icon: Icons.favorite_rounded,
              filled: true,
              onPressed: enabled ? onLike : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverActionButton extends StatefulWidget {
  const _DiscoverActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foreground = AppColors.surface,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color foreground;
  final bool filled;

  @override
  State<_DiscoverActionButton> createState() => _DiscoverActionButtonState();
}

class _DiscoverActionButtonState extends State<_DiscoverActionButton>
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

  void _animate(double target, {double velocity = 0}) {
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .75, stiffness: 540, damping: 28),
        _scale.value,
        target,
        velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.label,
      child: Listener(
        onPointerDown: enabled ? (_) => _animate(.9, velocity: -1) : null,
        onPointerUp: enabled ? (_) => _animate(1, velocity: 1) : null,
        onPointerCancel: enabled ? (_) => _animate(1) : null,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: widget.filled
                ? (enabled
                      ? AppColors.secondary
                      : AppColors.tertiary.withValues(alpha: .65))
                : AppColors.surface,
            shape: CircleBorder(
              side: BorderSide(
                color: widget.filled ? AppColors.secondary : AppColors.tertiary,
              ),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: 54,
                child: Icon(
                  widget.icon,
                  color: enabled
                      ? widget.foreground
                      : AppColors.text.withValues(alpha: .32),
                  size: widget.filled ? 25 : 24,
                  semanticLabel: widget.label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const aspect = 1.35;
        final width = math.min(
          512.0,
          math.min(constraints.maxWidth, constraints.maxHeight / aspect),
        );
        return Center(
          child: Container(
            width: width,
            height: width * aspect,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: .36),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(24),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonLine(width: 180, height: 26),
                SizedBox(height: 10),
                _SkeletonLine(width: 140, height: 14),
                SizedBox(height: 8),
                _SkeletonLine(width: 220, height: 14),
                SizedBox(height: 72),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _DiscoverEmpty extends StatelessWidget {
  const _DiscoverEmpty({required this.onFilters, required this.onRefresh});

  final VoidCallback onFilters;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.tertiary),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_outline_rounded,
                  color: AppColors.secondary,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'You are all caught up',
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Adjust your filters or check back later.',
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.bodyMedium,
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: 'Edit Filters',
                  onPressed: onFilters,
                  icon: Icons.tune_rounded,
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(
                  label: 'View profiles again',
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverError extends StatelessWidget {
  const _DiscoverError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_outline_rounded,
            color: AppColors.secondary,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Couldn’t load profiles',
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _QuickFilter {
  const _QuickFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}
