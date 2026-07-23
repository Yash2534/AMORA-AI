<<<<<<< HEAD
import 'dart:async';
import 'dart:math' as math;

import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_gradients.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_empty_state.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
=======
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_empty_state.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/discovery/presentation/super_like_screen.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/gestures.dart';
>>>>>>> main
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

class BrowseGridScreen extends StatefulWidget {
  const BrowseGridScreen({
    super.key,
    this.showNavigation = true,
    this.controller,
  });

  static const routeName = '/browse';

  final bool showNavigation;
  final DiscoverActionController? controller;

  @override
  State<BrowseGridScreen> createState() => _BrowseGridScreenState();
}

class _BrowseGridScreenState extends State<BrowseGridScreen> {
<<<<<<< HEAD
  static const _defaultDistance = 300.0;
  static const _swipeThreshold = 88.0;
  static const _velocityThreshold = 650.0;

  late List<DummyProfile> _profiles;
  DiscoverActionController? _controller;
  Timer? _loadingTimer;
  Timer? _completionSuccessTimer;
  late final FocusNode _keyboardFocus;
  Object? _error;
  bool _loading = true;
  bool _dragging = false;
  double _dragX = 0;
  double _distance = _defaultDistance;
  final Set<String> _selectedIntents = {};
  final Map<String, int> _photoIndices = {};
  bool _verifiedOnly = false;
  late int _lastCompletionPercent;
  bool _showCompletionSuccess = false;

  DiscoverActionController get _actions => _controller!;

  @override
  void initState() {
    super.initState();
    _keyboardFocus = FocusNode(debugLabel: 'Discover keyboard shortcuts');
    _lastCompletionPercent =
        LocalProfileRepository.instance.profile.completionPercent;
    LocalProfileRepository.instance.addListener(_handleProfileUpdate);
    _loadProfiles();
=======
  GlobalKey<_SwipeProfileCardState> _cardKey =
      GlobalKey<_SwipeProfileCardState>();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFilters = <String>{};
  final Set<String> _likedProfileIds = <String>{};
  final Set<String> _seenProfileIds = <String>{};
  final List<DummyProfile> _history = <DummyProfile>[];

  int _profileIndex = 0;
  String _query = '';

  List<DummyProfile> get _visibleProfiles {
    final query = _query.trim().toLowerCase();
    return ImageRepository.profiles
        .where((profile) {
          final searchable = <String>[
            profile.name,
            profile.city,
            profile.profession,
            profile.intent,
            profile.bio,
            ...profile.interests,
          ].join(' ').toLowerCase();
          final matchesSearch = query.isEmpty || searchable.contains(query);
          final matchesFilters = _selectedFilters.every(
            (filter) => _profileMatchesFilter(profile, filter),
          );
          return matchesSearch && matchesFilters;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
>>>>>>> main
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _completionSuccessTimer?.cancel();
    LocalProfileRepository.instance.removeListener(_handleProfileUpdate);
    _keyboardFocus.dispose();
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  void _loadProfiles() {
    _loadingTimer?.cancel();
    try {
      _profiles = ImageRepository.profiles.take(18).toList(growable: false);
      _error = null;
      _replaceController();
      _loading = true;
      _loadingTimer = Timer(AmoraMotion.fast, () {
        if (mounted) setState(() => _loading = false);
      });
    } catch (error) {
      _error = error;
      _loading = false;
    }
  }

  List<DummyProfile> get _filteredProfiles => _profiles
      .where((profile) {
        final distance = int.tryParse(profile.distance.split(' ').first);
        final withinDistance =
            distance == null || distance <= _distance.round();
        final matchesVerification = !_verifiedOnly || profile.verified;
        final matchesIntent =
            _selectedIntents.isEmpty ||
            _selectedIntents.contains(profile.intent);
        return withinDistance && matchesVerification && matchesIntent;
      })
      .toList(growable: false);

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

  bool get _hasActiveFilters =>
      _verifiedOnly ||
      _selectedIntents.isNotEmpty ||
      _distance != _defaultDistance;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showNavigation
          ? const FloatingBottomNav(activeTab: AmoraNavTab.discover)
          : null,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 540,
          child: Focus(
            focusNode: _keyboardFocus,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space12,
                AmoraSpacing.space20,
                AmoraSpacing.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DiscoverHeader(
                    filtersActive: _hasActiveFilters,
                    onFilters: _openFilters,
                  ),
                  _buildCompletionLine(),
                  const SizedBox(height: AmoraSpacing.space12),
                  Expanded(child: _buildExperience()),
                ],
              ),
=======
    final profiles = _visibleProfiles;
    final keyboardIsOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      drawer: _DiscoverNavigationDrawer(onNavigate: _navigateFromMenu),
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space24,
                  AmoraSpacing.space16,
                  AmoraSpacing.space24,
                  keyboardIsOpen
                      ? AmoraSpacing.space8
                      : FloatingBottomNav.contentBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DiscoverSearchHeader(
                      controller: _searchController,
                      hasQuery: _query.isNotEmpty,
                      onChanged: _updateQuery,
                      onClear: _clearSearch,
                      onNotifications: _openNotifications,
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    _PremiumFilterRail(
                      selectedFilters: _selectedFilters,
                      onOpenFilters: _openFilters,
                      onToggle: _toggleFilter,
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    Expanded(
                      child: _buildDiscoverArea(
                        profiles,
                        keyboardIsOpen: keyboardIsOpen,
                      ),
                    ),
                  ],
                ),
              ),
              if (!keyboardIsOpen)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AmoraSpacing.space16,
                    ),
                    child: FloatingBottomNav(activeTab: AmoraNavTab.discover),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverArea(
    List<DummyProfile> profiles, {
    required bool keyboardIsOpen,
  }) {
    if (profiles.isEmpty) {
      return AmoraEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'No profiles match',
        message: 'Try another search or clear your selected filters.',
        actionLabel: 'Clear search and filters',
        onAction: _clearSearchAndFilters,
      );
    }

    if (_profileIndex >= profiles.length) {
      return AmoraEmptyState(
        icon: Icons.refresh_rounded,
        title: 'You are all caught up',
        message: 'You have seen every profile in this set.',
        actionLabel: 'View profiles again',
        onAction: _restartProfiles,
      );
    }

    final profile = profiles[_profileIndex];
    return _ProfileCardStage(
      actionBar: keyboardIsOpen
          ? null
          : _DiscoverActionBar(
              canUndo: _history.isNotEmpty,
              onPass: () => _dismissFromAction(SwipeDirection.left),
              onUndo: _undo,
              onSuperLike: () => _openSuperLike(profile),
              onLike: () => _dismissFromAction(SwipeDirection.right),
            ),
      child: KeyedSubtree(
        key: ValueKey('discover-profile-card-${profile.id}'),
        child: _SwipeProfileCard(
          key: _cardKey,
          profile: profile,
          heroTag: _heroTag(profile),
          liked: _likedProfileIds.contains(profile.id),
          compact: keyboardIsOpen,
          onOpen: () => _openProfile(profile),
          onDismissed: (direction) => _handleDismissed(profile, direction),
        ),
      ),
    );
  }

  void _updateQuery(String value) {
    setState(() {
      _query = value;
      _profileIndex = 0;
      _history.clear();
      _resetCardKey();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _updateQuery('');
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedFilters.clear();
      _profileIndex = 0;
      _history.clear();
      _resetCardKey();
    });
  }

  void _toggleFilter(String filter) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedFilters.add(filter)) _selectedFilters.remove(filter);
      _profileIndex = 0;
      _history.clear();
      _resetCardKey();
    });
  }

  void _dismissFromAction(SwipeDirection direction) {
    _cardKey.currentState?.dismissFromAction(direction);
  }

  void _handleDismissed(DummyProfile profile, SwipeDirection direction) {
    if (direction == SwipeDirection.right) {
      _registerPositiveAction(profile);
    } else {
      HapticFeedback.selectionClick();
    }

    if (!mounted) return;
    setState(() {
      _history.add(profile);
      _seenProfileIds.add(profile.id);
      if (!_selectedFilters.contains('New')) _profileIndex++;
      _resetCardKey();
    });
  }

  void _registerPositiveAction(DummyProfile profile) {
    if (AmoraSession.isGuest) {
      AmoraSession.requireAuth(
        context: context,
        onAuthenticated: () => _registerPositiveAction(profile),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _likedProfileIds.add(profile.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Liked ${profile.name}')));
  }

  void _undo() {
    if (_history.isEmpty) return;
    HapticFeedback.selectionClick();
    final previous = _history.removeLast();
    setState(() {
      _seenProfileIds.remove(previous.id);
      final restoredIndex = _visibleProfiles.indexWhere(
        (profile) => profile.id == previous.id,
      );
      _profileIndex = restoredIndex < 0 ? 0 : restoredIndex;
      _resetCardKey();
    });
  }

  void _restartProfiles() {
    setState(() {
      _profileIndex = 0;
      _history.clear();
      _resetCardKey();
    });
  }

  void _resetCardKey() {
    _cardKey = GlobalKey<_SwipeProfileCardState>();
  }

  Future<void> _openProfile(DummyProfile profile) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        settings: RouteSettings(
          name: ProfileDetailScreen.routeName,
          arguments: profile,
        ),
        transitionDuration: const Duration(milliseconds: 440),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Hero(
            tag: _heroTag(profile),
            createRectTween: (begin, end) =>
                MaterialRectArcTween(begin: begin, end: end),
            child: const ProfileDetailScreen(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  void _openSuperLike(DummyProfile profile) {
    if (AmoraSession.isGuest) {
      AmoraSession.requireAuth(
        context: context,
        onAuthenticated: () => _openSuperLike(profile),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(SuperLikeScreen.routeName, arguments: profile);
  }

  void _openNotifications() {
    Navigator.of(context).pushNamed(NotificationsHubScreen.routeName);
  }

  void _openFilters() {
    Navigator.of(context).pushNamed(AdvancedFiltersScreen.routeName);
  }

  Future<void> _navigateFromMenu(String routeName) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    if (routeName == AdvancedFiltersScreen.routeName) {
      await Navigator.of(context).pushNamed(routeName);
      return;
    }
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  bool _profileMatchesFilter(DummyProfile profile, String filter) {
    final interests = profile.interests.join(' ').toLowerCase();
    final profession = profile.profession.toLowerCase();
    final intent = profile.intent.toLowerCase();
    final status = profile.status.toLowerCase();
    final weekend = profile.weekendPlan.toLowerCase();
    final religion = profile.religion.toLowerCase();

    return switch (filter) {
      'Verified' => profile.verified,
      'Online' => _isOnline(profile),
      'Nearby' => _distanceInKm(profile) <= 30,
      'Most Compatible' => profile.score >= 92,
      'New' => !_seenProfileIds.contains(profile.id),
      'Recently Active' => status.contains('recently active'),
      'Music Lovers' => _containsAny(interests, ['music', 'concert']),
      'Travel' => _containsAny(interests, ['travel', 'road trip']),
      'Marriage' => intent.contains('marriage'),
      'Coffee Dates' => interests.contains('coffee'),
      'Fitness' => _containsAny(interests, ['fitness', 'cycling', 'gym']),
      'Entrepreneurs' => _containsAny(profession, ['founder', 'entrepreneur']),
      'Foodies' =>
        _containsAny(interests, ['food', 'dining', 'dessert']) ||
            profession.contains('chef'),
      'Pets' => !profile.petPreference.toLowerCase().contains('no pet'),
      'Adventure' => _containsAny('$interests $weekend', [
        'road trip',
        'cycling',
        'hiking',
        'adventure',
      ]),
      'Art' => _containsAny(interests, [
        'art',
        'museum',
        'design',
        'architecture',
      ]),
      'Movies' => _containsAny(interests, ['movie', 'cinema', 'film']),
      'Gaming' => _containsAny(interests, ['game', 'gaming']),
      'Spiritual' =>
        _containsAny(interests, ['temple', 'spiritual']) ||
            religion.contains('spiritual'),
      'Language Exchange' => profile.languages.length > 1,
      'Long Term' => _containsAny(intent, [
        'long-term',
        'serious',
        'meaningful',
        'marriage',
      ]),
      'Casual' => _containsAny(intent, ['exploring', 'friendship']),
      _ => true,
    };
  }
}

String _heroTag(DummyProfile profile) => 'discover-profile-${profile.id}';

bool _isOnline(DummyProfile profile) =>
    profile.status.trim().toLowerCase() == 'online now';

bool _containsAny(String value, List<String> terms) =>
    terms.any(value.toLowerCase().contains);

int _distanceInKm(DummyProfile profile) =>
    int.tryParse(profile.distance.split(' ').first) ?? 10000;

class _DiscoverSearchHeader extends StatefulWidget {
  const _DiscoverSearchHeader({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
    required this.onNotifications,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onNotifications;

  @override
  State<_DiscoverSearchHeader> createState() => _DiscoverSearchHeaderState();
}

class _DiscoverSearchHeaderState extends State<_DiscoverSearchHeader> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              key: const ValueKey('discover-search-container'),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              height: focused ? 58 : 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: focused ? AppColors.secondary : AppColors.tertiary,
                  width: focused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (focused ? AppColors.secondary : AppColors.primary)
                        .withValues(alpha: focused ? .20 : .08),
                    blurRadius: focused ? 22 : 14,
                    spreadRadius: focused ? 1 : -4,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: TextField(
                key: const ValueKey('discover-search-field'),
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: AmoraTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search people, interests or cities',
                  hintStyle: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .62),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: widget.hasQuery
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: widget.onClear,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AmoraSpacing.space16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AmoraSpacing.space8),
          _GlassIconButton(
            key: const ValueKey('discover-notifications-button'),
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed: widget.onNotifications,
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _SpringScale(
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: AppColors.surface.withValues(alpha: .92),
              child: InkWell(
                onTap: onPressed,
                child: SizedBox.square(
                  dimension: AmoraSpacing.minimumTouchTarget,
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
              ),
>>>>>>> main
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildCompletionLine() {
    final percent = LocalProfileRepository.instance.profile.completionPercent;
    if (percent >= 100 && !_showCompletionSuccess) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space8),
      child: _ProfileCompletionLine(
        percent: percent,
        complete: percent >= 100,
        onTap: () =>
            Navigator.of(context).pushNamed(ProfileCompletionScreen.routeName),
      ),
    );
  }

  void _handleProfileUpdate() {
    if (!mounted) return;
    final percent = LocalProfileRepository.instance.profile.completionPercent;
    if (percent >= 100 && _lastCompletionPercent < 100) {
      _completionSuccessTimer?.cancel();
      setState(() {
        _lastCompletionPercent = percent;
        _showCompletionSuccess = true;
      });
      _completionSuccessTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showCompletionSuccess = false);
      });
      return;
    }
    setState(() => _lastCompletionPercent = percent);
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
            onRefresh: _refreshDeck,
          );
        }
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(
                    500.0,
                    math.min(constraints.maxWidth, constraints.maxHeight * .8),
                  );
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: width * 1.25,
                      child: _buildDraggableCard(profile, width),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            _DiscoverActions(
              enabled: !_actions.isTransitioning,
              canRewind: _actions.canRewind,
              onReject: () => _performAction(profile, like: false),
              onLike: () => _performAction(profile, like: true),
              onRewind: _rewind,
            ),
          ],
=======
}

class _PremiumFilterRail extends StatelessWidget {
  const _PremiumFilterRail({
    required this.selectedFilters,
    required this.onOpenFilters,
    required this.onToggle,
  });

  final Set<String> selectedFilters;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('discover-filter-rail'),
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _discoverFilters.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PremiumFilterChip(
              key: const ValueKey('discover-filters-button'),
              filter: const _DiscoverFilter('Filters', Icons.tune_rounded),
              selected: false,
              onTap: onOpenFilters,
            );
          }
          final filter = _discoverFilters[index - 1];
          return _PremiumFilterChip(
            key: ValueKey('discover-filter-${filter.label}'),
            filter: filter,
            selected: selectedFilters.contains(filter.label),
            onTap: () => onToggle(filter.label),
          );
        },
      ),
    );
  }
}

class _PremiumFilterChip extends StatelessWidget {
  const _PremiumFilterChip({
    super.key,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _DiscoverFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${filter.label} filter',
      child: _SpringScale(
        child: Material(
          color: selected ? AppColors.primary : AppColors.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.secondary,
            ),
          ),
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: .10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: filter.icon == Icons.circle ? 10 : 18,
                    color: selected ? AppColors.surface : AppColors.secondary,
                  ),
                  const SizedBox(width: AmoraSpacing.space4),
                  Text(
                    filter.label,
                    style: AmoraTextStyles.labelLarge.copyWith(
                      fontSize: 12,
                      color: selected
                          ? AppColors.surface
                          : AppColors.textNeutral,
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

class _ProfileCardStage extends StatelessWidget {
  const _ProfileCardStage({required this.child, required this.actionBar});

  final Widget child;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          constraints.maxHeight * .76,
        );
        return Center(
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(child: child),
                if (actionBar != null)
                  Positioned(
                    left: AmoraSpacing.space8,
                    right: AmoraSpacing.space8,
                    bottom: AmoraSpacing.space12,
                    child: actionBar!,
                  ),
              ],
            ),
          ),
>>>>>>> main
        );
      },
    );
  }

  Widget _buildDraggableCard(DummyProfile profile, double width) {
    final progress = (_dragX / width).clamp(-1.0, 1.0);
    final duration = _dragging ? Duration.zero : AmoraMotion.selection;
    return GestureDetector(
      key: const Key('discover-horizontal-swipe'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _actions.isTransitioning
          ? null
          : (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: _actions.isTransitioning
          ? null
          : (details) => setState(() {
              _dragX = (_dragX + details.delta.dx).clamp(-width, width);
            }),
      onHorizontalDragCancel: _actions.isTransitioning
          ? null
          : () => setState(() {
              _dragging = false;
              _dragX = 0;
            }),
      onHorizontalDragEnd: _actions.isTransitioning
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              final shouldComplete =
                  _dragX.abs() >= _swipeThreshold ||
                  velocity.abs() >= _velocityThreshold;
              if (!shouldComplete) {
                setState(() {
                  _dragging = false;
                  _dragX = 0;
                });
                return;
              }
              _performAction(
                profile,
                like: velocity == 0 ? _dragX > 0 : velocity > 0,
              );
            },
      child: AnimatedSlide(
        offset: Offset(progress * 1.45, 0),
        duration: duration,
        curve: AmoraMotion.curve,
        child: AnimatedRotation(
          turns: progress * (7 / 360),
          duration: duration,
          curve: AmoraMotion.curve,
          child: _DiscoverProfileCard(
            profile: profile,
            dragProgress: progress,
            photoIndex: _photoIndices[profile.id] ?? 0,
            onPreviousPhoto: () => _changePhoto(profile, -1),
            onNextPhoto: () => _changePhoto(profile, 1),
            onOpen: () => _openProfile(profile),
          ),
        ),
      ),
    );
  }

  Future<void> _performAction(
    DummyProfile profile, {
    required bool like,
  }) async {
    if (_actions.isTransitioning) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dragging = false;
      _dragX = like ? 520 : -520;
    });
    if (like) {
      await _actions.likeProfile();
    } else {
      await _actions.rejectProfile();
    }
    if (!mounted) return;
    setState(() {
      _dragX = 0;
      _photoIndices.remove(profile.id);
    });
    if (like && _actions.matchedProfileId == profile.id) {
      _actions.consumeMatch();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You and ${profile.name} liked each other')),
      );
    }
  }

  void _changePhoto(DummyProfile profile, int delta) {
    if (_actions.isTransitioning || profile.gallery.length < 2) return;
    final current = _photoIndices[profile.id] ?? 0;
    final next = (current + delta).clamp(0, profile.gallery.length - 1);
    if (next == current) return;
    setState(() => _photoIndices[profile.id] = next);
    if (next + 1 < profile.gallery.length) {
      precacheImage(AssetImage(profile.gallery[next + 1]), context);
    }
  }

  void _keyboardAction({required bool like}) {
    final profile = _profileFor(_controller?.currentProfileId);
    if (profile != null) _performAction(profile, like: like);
  }

  void _openCurrent() {
    final profile = _profileFor(_controller?.currentProfileId);
    if (profile != null) _openProfile(profile);
  }

  Future<void> _openProfile(DummyProfile profile) async {
    final decision = await Navigator.of(
      context,
    ).pushNamed(ProfileDetailScreen.routeName, arguments: profile);
    if (!mounted || decision == null) return;
    await _performAction(profile, like: decision == ProfileDetailDecision.like);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _keyboardAction(like: false);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _keyboardAction(like: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _openCurrent();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _rewind() async {
    if (!_actions.canRewind) return;
    await _actions.rewindProfile();
  }

  void _refreshDeck() {
    setState(() {
      _replaceController();
      _dragX = 0;
      _photoIndices.clear();
    });
  }

  Future<void> _openFilters() async {
    final selection = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _DiscoverFilterSheet(
        initial: _FilterSelection(
          distance: _distance,
          verifiedOnly: _verifiedOnly,
          intents: _selectedIntents,
        ),
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _distance = selection.distance;
      _verifiedOnly = selection.verifiedOnly;
      _selectedIntents
        ..clear()
        ..addAll(selection.intents);
      _replaceController();
      _dragX = 0;
      _photoIndices.clear();
    });
  }
}

<<<<<<< HEAD
class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({required this.filtersActive, required this.onFilters});

  final bool filtersActive;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Discover', style: AmoraTextStyles.screenTitle),
              Text(
                'Ahmedabad · intentional matches',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.metadata,
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Open Discover filters',
          child: Tooltip(
            message: 'Filters',
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  key: const Key('discover-filter-button'),
                  onPressed: onFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.activeContainer,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.square(
                      AmoraSpacing.minimumTouchTarget,
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                ),
                if (filtersActive)
                  const Positioned(
                    right: 3,
                    top: 3,
                    child: DecoratedBox(
                      key: Key('discover-active-filter-indicator'),
                      decoration: BoxDecoration(
                        color: AppColors.active,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 10),
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

class _ProfileCompletionLine extends StatelessWidget {
  const _ProfileCompletionLine({
    required this.percent,
    required this.complete,
    required this.onTap,
  });

  final int percent;
  final bool complete;
  final VoidCallback onTap;

  String get _message {
    if (complete) return 'Your profile is complete';
    if (percent < 40) return 'Build your profile · $percent% complete';
    if (percent < 80) return 'You’re making progress · $percent% complete';
    return 'Almost ready · $percent% complete';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !complete,
      label: complete ? _message : 'Complete your profile, $_message',
      child: Material(
        color: complete ? AppColors.successContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('discover-profile-completion-line'),
          onTap: complete ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.activeContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    complete
                        ? Icons.check_rounded
                        : Icons.person_outline_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      if (!complete) ...[
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!complete) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Complete',
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ],
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
    required this.photoIndex,
    required this.onPreviousPhoto,
    required this.onNextPhoto,
    required this.onOpen,
  });

  final DummyProfile profile;
  final double dragProgress;
  final int photoIndex;
  final VoidCallback onPreviousPhoto;
  final VoidCallback onNextPhoto;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile details for ${profile.name}',
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        elevation: 0,
        child: Ink(
          key: const Key('discover-profile-card'),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: AmoraShadows.level2,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'profile-image-${profile.id}',
                  child: AnimatedSwitcher(
                    key: const Key('discover-cover-image'),
                    duration: const Duration(milliseconds: 210),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: AmoraProfileImage(
                      key: ValueKey('discover-cover-${profile.id}-$photoIndex'),
                      imageUrl: profile.gallery[photoIndex],
                      assetPath: profile.fallbackAsset,
                      initials: profile.initials,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.transparent,
                        AppColors.transparent,
                        AppColors.overlayDark,
                      ],
                      stops: [0, .48, 1],
                    ),
                  ),
                ),
                if (profile.verified)
                  const Positioned(
                    top: AmoraSpacing.space16,
                    right: AmoraSpacing.space16,
                    child: _VerifiedBadge(),
                  ),
                if (profile.gallery.length > 1)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 10,
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < profile.gallery.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 4),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 3,
                              decoration: BoxDecoration(
                                color: index == photoIndex
                                    ? AppColors.surface
                                    : AppColors.overlayLight.withValues(
                                        alpha: .45,
                                      ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        Positioned(
                          left: AmoraSpacing.space20,
                          top: AmoraSpacing.space24,
                          child: _SwipeBadge(
                            label: 'PASS',
                            icon: Icons.close_rounded,
                            color: AppColors.primary,
                            opacity: (-dragProgress).clamp(0.0, 1.0),
                          ),
                        ),
                        Positioned(
                          right: AmoraSpacing.space20,
                          top: AmoraSpacing.space24,
                          child: _SwipeBadge(
                            label: 'LIKE',
                            icon: Icons.favorite_rounded,
                            color: AppColors.active,
                            opacity: dragProgress.clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: AmoraSpacing.space20,
                  right: AmoraSpacing.space20,
                  bottom: AmoraSpacing.space20,
                  child: _ProfileSummary(profile: profile),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Show previous photo',
                          child: InkWell(
                            key: const Key('discover-previous-photo'),
                            onTap: onPreviousPhoto,
                            focusColor: AppColors.hover.withValues(alpha: .22),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'View full profile',
                          child: InkWell(
                            key: const Key('discover-open-profile'),
                            onTap: onOpen,
                            focusColor: AppColors.hover.withValues(alpha: .22),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Show next photo',
                          child: InkWell(
                            key: const Key('discover-next-photo'),
                            onTap: onNextPhoto,
                            focusColor: AppColors.hover.withValues(alpha: .22),
                          ),
                        ),
                      ),
                    ],
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

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${profile.name}, ${profile.age}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.profileName.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.surface,
              semanticLabel: 'View profile',
            ),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          '${profile.profession} · ${profile.distance}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.bodyMedium.copyWith(color: AppColors.surface),
        ),
        Text(
          '${profile.city} · ${profile.intent}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.overlayLight,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Wrap(
          spacing: AmoraSpacing.space8,
          runSpacing: AmoraSpacing.space4,
          children: [
            for (final interest in profile.interests.take(2))
              _InterestPill(label: interest),
          ],
        ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .94),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space8,
          vertical: AmoraSpacing.space4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
            SizedBox(width: AmoraSpacing.space4),
            Text('Verified', style: AmoraTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _SwipeBadge extends StatelessWidget {
  const _SwipeBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.opacity,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .94),
          borderRadius: AmoraRadius.pillBorder,
          border: Border.all(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AmoraSpacing.space12,
            vertical: AmoraSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: AmoraIconSizes.small),
              const SizedBox(width: AmoraSpacing.space4),
              Text(
                label,
                style: AmoraTextStyles.labelLarge.copyWith(color: color),
=======
enum SwipeDirection { left, right }

class _SwipeProfileCard extends StatefulWidget {
  const _SwipeProfileCard({
    super.key,
    required this.profile,
    required this.heroTag,
    required this.liked,
    required this.compact,
    required this.onOpen,
    required this.onDismissed,
  });

  final DummyProfile profile;
  final String heroTag;
  final bool liked;
  final bool compact;
  final VoidCallback onOpen;
  final ValueChanged<SwipeDirection> onDismissed;

  @override
  State<_SwipeProfileCard> createState() => _SwipeProfileCardState();
}

class _SwipeProfileCardState extends State<_SwipeProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset>? _offsetAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;
  bool _didDrag = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = _offsetAnimation?.value ?? _dragOffset;
        final cardWidth = math.max(1.0, MediaQuery.sizeOf(context).width);
        final rotation = (offset.dx / cardWidth).clamp(-1.0, 1.0) * .09;
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: rotation,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Semantics(
        button: true,
        label: 'Open ${widget.profile.name} profile',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.start,
          onTap: () {
            if (!_didDrag && !_isAnimating) widget.onOpen();
          },
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onPanCancel: _snapBack,
          child: _CardEntrance(
            child: Hero(
              tag: widget.heroTag,
              transitionOnUserGestures: true,
              createRectTween: (begin, end) =>
                  MaterialRectArcTween(begin: begin, end: end),
              child: RepaintBoundary(
                child: _PremiumProfileCard(
                  profile: widget.profile,
                  liked: widget.liked,
                  compact: widget.compact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void dismissFromAction(SwipeDirection direction) {
    if (_isAnimating) return;
    _dragOffset = Offset(direction == SwipeDirection.right ? 12 : -12, 0);
    _dismiss(direction);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isAnimating) return;
    _didDrag = false;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    if (details.delta.distanceSquared > 0) _didDrag = true;
    setState(() {
      _offsetAnimation = null;
      _dragOffset += Offset(details.delta.dx, details.delta.dy * .20);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final width = math.max(1.0, context.size?.width ?? 1.0);
    final velocity = details.velocity.pixelsPerSecond.dx;
    final crossedDistance = _dragOffset.dx.abs() >= width * .24;
    final crossedVelocity = velocity.abs() >= 800 && _dragOffset.dx.abs() > 18;

    if (crossedDistance || crossedVelocity) {
      final direction = (_dragOffset.dx == 0 ? velocity : _dragOffset.dx) > 0
          ? SwipeDirection.right
          : SwipeDirection.left;
      _dismiss(direction);
      return;
    }
    _snapBack();
  }

  Future<void> _dismiss(SwipeDirection direction) async {
    if (_isAnimating) return;
    _isAnimating = true;
    final width = MediaQuery.sizeOf(context).width;
    final target = Offset(
      direction == SwipeDirection.right ? width * 1.35 : -width * 1.35,
      _dragOffset.dy,
    );
    await _animateTo(target, Curves.easeInCubic);
    if (!mounted) return;
    widget.onDismissed(direction);
  }

  Future<void> _snapBack() async {
    if (_isAnimating || _dragOffset == Offset.zero) {
      _didDrag = false;
      return;
    }
    _isAnimating = true;
    _controller.reset();
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(_controller);
    await _controller.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 440, damping: 30),
        0,
        1,
        0,
      ),
    );
    if (!mounted) return;
    setState(() {
      _dragOffset = Offset.zero;
      _offsetAnimation = null;
      _isAnimating = false;
      _didDrag = false;
    });
  }

  Future<void> _animateTo(Offset target, Curve curve) async {
    _controller.reset();
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
    await _controller.forward();
  }
}

class _PremiumProfileCard extends StatelessWidget {
  const _PremiumProfileCard({
    required this.profile,
    required this.liked,
    required this.compact,
  });

  final DummyProfile profile;
  final bool liked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .20),
            blurRadius: 34,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumImage(
              imageUrl: profile.imageUrl,
              fallbackAsset: profile.fallbackAsset,
              initials: profile.initials,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              borderRadius: BorderRadius.zero,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.primary.withValues(alpha: .05),
                    AppColors.primary.withValues(alpha: .96),
                  ],
                  stops: const [0, .48, 1],
                ),
              ),
            ),
            Positioned(
              left: AmoraSpacing.space20,
              right: AmoraSpacing.space20,
              bottom: compact ? AmoraSpacing.space20 : 92,
              child: _ProfileInformation(
                profile: profile,
                compact: compact,
                liked: liked,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInformation extends StatelessWidget {
  const _ProfileInformation({
    required this.profile,
    required this.compact,
    required this.liked,
  });

  final DummyProfile profile;
  final bool compact;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    final languages = profile.languages.take(2).join(' • ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.verified)
          const _OverlayBadge(icon: Icons.verified_rounded, label: 'Verified'),
        const SizedBox(height: AmoraSpacing.space8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${profile.name.split(' ').first}, ${profile.age}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? AmoraTextStyles.titleLarge
                            : AmoraTextStyles.headlineLarge)
                        .copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                        ),
              ),
            ),
            if (liked)
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.secondary,
                size: 24,
              ),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          profile.profession,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.titleMedium.copyWith(color: AppColors.surface),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Wrap(
          spacing: AmoraSpacing.space12,
          runSpacing: AmoraSpacing.space4,
          children: [
            _OverlayDetail(
              icon: Icons.location_on_rounded,
              label: '${profile.distance} away',
            ),
            if (_isOnline(profile))
              const _OverlayDetail(
                icon: Icons.circle,
                label: 'Online now',
                smallIcon: true,
              ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: AmoraSpacing.space8),
          _OverlayDetail(icon: Icons.translate_rounded, label: languages),
          const SizedBox(height: AmoraSpacing.space8),
          _OverlayDetail(
            icon: Icons.favorite_outline_rounded,
            label: 'Looking for ${profile.intent}',
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              for (final interest in profile.interests.take(3))
                _InterestPill(label: interest),
            ],
          ),
        ],
      ],
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .94),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(width: AmoraSpacing.space4),
            Text(
              label,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayDetail extends StatelessWidget {
  const _OverlayDetail({
    required this.icon,
    required this.label,
    this.smallIcon = false,
  });

  final IconData icon;
  final String label;
  final bool smallIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: smallIcon ? 9 : 17, color: AppColors.tertiary),
        const SizedBox(width: AmoraSpacing.space4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelLarge.copyWith(
              color: AppColors.surface,
            ),
          ),
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
        color: AppColors.surface.withValues(alpha: .16),
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .58)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
        child: Text(
          label,
          style: AmoraTextStyles.labelMedium.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }
}

class _DiscoverActionBar extends StatelessWidget {
  const _DiscoverActionBar({
    required this.canUndo,
    required this.onPass,
    required this.onUndo,
    required this.onSuperLike,
    required this.onLike,
  });

  final bool canUndo;
  final VoidCallback onPass;
  final VoidCallback onUndo;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        final size = compact ? 48.0 : 54.0;
        return ClipRRect(
          borderRadius: AmoraRadius.pillBorder,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: .88),
                borderRadius: AmoraRadius.pillBorder,
                border: Border.all(
                  color: AppColors.tertiary.withValues(alpha: .72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .16),
                    blurRadius: 26,
                    spreadRadius: -8,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space8,
                  vertical: AmoraSpacing.space8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionCircle(
                      key: const ValueKey('discover-pass-button'),
                      icon: Icons.close_rounded,
                      label: 'Pass',
                      size: size,
                      onTap: onPass,
                    ),
                    _ActionCircle(
                      key: const ValueKey('discover-undo-button'),
                      icon: Icons.undo_rounded,
                      label: 'Undo',
                      size: size,
                      enabled: canUndo,
                      onTap: onUndo,
                    ),
                    _ActionCircle(
                      key: const ValueKey('discover-super-like-button'),
                      icon: Icons.star_rounded,
                      label: 'Super Like',
                      size: size,
                      filled: true,
                      onTap: onSuperLike,
                    ),
                    _ActionCircle(
                      key: const ValueKey('discover-like-button'),
                      icon: Icons.favorite_rounded,
                      label: 'Like',
                      size: size,
                      filled: true,
                      onTap: onLike,
                    ),
                  ],
                ),
>>>>>>> main
              ),
            ),
          ),
<<<<<<< HEAD
        ),
      ),
=======
        );
      },
>>>>>>> main
    );
  }
}

<<<<<<< HEAD
class _InterestPill extends StatelessWidget {
  const _InterestPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .88),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space8,
          vertical: AmoraSpacing.space4,
        ),
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

class _DiscoverActions extends StatelessWidget {
  const _DiscoverActions({
    required this.enabled,
    required this.canRewind,
    required this.onReject,
    required this.onLike,
    required this.onRewind,
  });

  final bool enabled;
  final bool canRewind;
  final VoidCallback onReject;
  final VoidCallback onLike;
  final VoidCallback onRewind;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Profile actions',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundAction(
            key: const Key('discover-reject-button'),
            label: 'Reject profile',
            icon: Icons.close_rounded,
            onPressed: enabled ? onReject : null,
          ),
          const SizedBox(width: AmoraSpacing.space16),
          _RoundAction(
            key: const Key('discover-rewind-button'),
            label: 'Rewind profile',
            icon: Icons.undo_rounded,
            compact: true,
            onPressed: enabled && canRewind ? onRewind : null,
          ),
          const SizedBox(width: AmoraSpacing.space16),
          _RoundAction(
            key: const Key('discover-like-button'),
            label: 'Like profile',
            icon: Icons.favorite_rounded,
            primary: true,
            onPressed: enabled ? onLike : null,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact
        ? 48.0
        : primary
        ? 64.0
        : 56.0;
=======
class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconColor = !enabled
        ? AppColors.textNeutral.withValues(alpha: .28)
        : filled
        ? AppColors.surface
        : label == 'Pass'
        ? AppColors.secondary
        : AppColors.primary;

>>>>>>> main
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
<<<<<<< HEAD
        enabled: onPressed != null,
        label: label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AmoraRadius.pillBorder,
          focusColor: AppColors.hover,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onPressed == null
                  ? AppColors.disabled
                  : primary
                  ? null
                  : AppColors.surface,
              gradient: onPressed != null && primary
                  ? AmoraGradients.primary
                  : null,
              shape: BoxShape.circle,
              border: primary
                  ? null
                  : Border.all(color: AppColors.borderStrong),
              boxShadow: onPressed == null
                  ? AmoraShadows.level0
                  : AmoraShadows.level1,
            ),
            child: Icon(
              icon,
              color: onPressed == null
                  ? AppColors.textDisabled
                  : primary
                  ? AppColors.surface
                  : AppColors.primary,
              size: primary ? 28 : AmoraIconSizes.standard,
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
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: .8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: AmoraSpacing.card,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonLine(width: 180),
                        SizedBox(height: AmoraSpacing.space8),
                        _SkeletonLine(width: 130),
                      ],
                    ),
                  ),
                ),
=======
        enabled: enabled,
        label: label,
        child: _SpringScale(
          enabled: enabled,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? null : AppColors.surface,
                gradient: filled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.secondary, AppColors.tertiary],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (filled ? AppColors.secondary : AppColors.primary)
                        .withValues(alpha: .18),
                    blurRadius: 14,
                    spreadRadius: -5,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: InkWell(
                onTap: enabled ? onTap : null,
                child: Icon(icon, color: iconColor, size: size * .46),
>>>>>>> main
              ),
            ),
          ),
        ),
<<<<<<< HEAD
        const SizedBox(height: AmoraSpacing.space12),
        const _SkeletonLine(width: 196, height: 56),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, this.height = 16});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHighest,
      borderRadius: AmoraRadius.pillBorder,
    ),
  );
}

class _DiscoverEmpty extends StatelessWidget {
  const _DiscoverEmpty({required this.onFilters, required this.onRefresh});

  final VoidCallback onFilters;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AmoraEmptyState(
      icon: Icons.favorite_outline_rounded,
      title: 'You’re all caught up',
      message: 'Adjust your preferences or refresh the local profile deck.',
      actionLabel: 'Adjust Filters',
      onAction: onFilters,
      secondaryActionLabel: 'Refresh',
      onSecondaryAction: onRefresh,
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
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: AmoraSpacing.space16),
          Text(
            'Profiles could not be loaded',
            style: AmoraTextStyles.titleLarge,
          ),
          const SizedBox(height: AmoraSpacing.space8),
          const Text('Your filters are still available. Please try again.'),
          const SizedBox(height: AmoraSpacing.space20),
          AppPrimaryButton(
            label: 'Retry',
            onPressed: onRetry,
            fullWidth: false,
          ),
        ],
=======
>>>>>>> main
      ),
    );
  }
}

<<<<<<< HEAD
class _FilterSelection {
  const _FilterSelection({
    required this.distance,
    required this.verifiedOnly,
    required this.intents,
  });

  final double distance;
  final bool verifiedOnly;
  final Set<String> intents;
}

class _DiscoverFilterSheet extends StatefulWidget {
  const _DiscoverFilterSheet({required this.initial});

  final _FilterSelection initial;

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  late double _distance;
  late bool _verifiedOnly;
  late Set<String> _intents;
=======
class _SpringScale extends StatefulWidget {
  const _SpringScale({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<_SpringScale> createState() => _SpringScaleState();
}

class _SpringScaleState extends State<_SpringScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  bool _hovered = false;
>>>>>>> main

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _distance = widget.initial.distance;
    _verifiedOnly = widget.initial.verifiedOnly;
    _intents = Set<String>.of(widget.initial.intents);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final intents = ImageRepository.profiles
        .map((profile) => profile.intent)
        .toSet()
        .take(5);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AmoraSpacing.space20,
        AmoraSpacing.space8,
        AmoraSpacing.space20,
        AmoraSpacing.space24 + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Discover filters',
                    style: AmoraTextStyles.bottomSheetTitle,
                  ),
                ),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text('Distance · ${_distance.round()} km'),
            Slider(
              value: _distance,
              min: 25,
              max: 300,
              divisions: 11,
              label: '${_distance.round()} km',
              onChanged: (value) => setState(() => _distance = value),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Verified profiles only'),
              value: _verifiedOnly,
              onChanged: (value) => setState(() => _verifiedOnly = value),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Text('Relationship intention', style: AmoraTextStyles.titleMedium),
            const SizedBox(height: AmoraSpacing.space8),
            Wrap(
              spacing: AmoraSpacing.space8,
              runSpacing: AmoraSpacing.space8,
              children: [
                for (final intent in intents)
                  AmoraFilterChip(
                    label: intent,
                    selected: _intents.contains(intent),
                    onSelected: (_) => setState(() {
                      if (!_intents.add(intent)) _intents.remove(intent);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space24),
            AppPrimaryButton(
              label: 'Apply filters',
              onPressed: () => Navigator.of(context).pop(
                _FilterSelection(
                  distance: _distance,
                  verifiedOnly: _verifiedOnly,
                  intents: _intents,
                ),
              ),
            ),
          ],
        ),
=======
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _animateTo(double target, {double velocity = 0}) {
    if (!widget.enabled) return;
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .8, stiffness: 520, damping: 30),
        _scale.value,
        target,
        velocity,
>>>>>>> main
      ),
    );
  }

<<<<<<< HEAD
  void _reset() {
    setState(() {
      _distance = _BrowseGridScreenState._defaultDistance;
      _verifiedOnly = false;
      _intents.clear();
    });
  }
}
=======
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hovered = true;
        _animateTo(1.035);
      },
      onExit: (_) {
        _hovered = false;
        _animateTo(1);
      },
      child: Listener(
        onPointerDown: (_) => _animateTo(.94, velocity: -1),
        onPointerUp: (_) => _animateTo(_hovered ? 1.035 : 1, velocity: 1),
        onPointerCancel: (_) => _animateTo(_hovered ? 1.035 : 1),
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

class _CardEntrance extends StatefulWidget {
  const _CardEntrance({required this.child});

  final Widget child;

  @override
  State<_CardEntrance> createState() => _CardEntranceState();
}

class _CardEntranceState extends State<_CardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: .97)
      ..animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 360, damping: 28),
          .97,
          1,
          0,
        ),
      );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

class _DiscoverNavigationDrawer extends StatelessWidget {
  const _DiscoverNavigationDrawer({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AmoraSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amora',
                style: AmoraTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space24),
              for (final item in _drawerItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: AmoraSpacing.space8),
                  child: ListTile(
                    leading: Icon(item.icon, color: AppColors.primary),
                    title: Text(item.label),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AmoraRadius.button,
                    ),
                    onTap: () => onNavigate(item.routeName),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverFilter {
  const _DiscoverFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _DrawerItem {
  const _DrawerItem(this.label, this.icon, this.routeName);

  final String label;
  final IconData icon;
  final String routeName;
}

const _discoverFilters = <_DiscoverFilter>[
  _DiscoverFilter('Verified', Icons.verified_rounded),
  _DiscoverFilter('Online', Icons.circle),
  _DiscoverFilter('Nearby', Icons.near_me_rounded),
  _DiscoverFilter('Most Compatible', Icons.auto_awesome_rounded),
  _DiscoverFilter('New', Icons.fiber_new_rounded),
  _DiscoverFilter('Recently Active', Icons.schedule_rounded),
  _DiscoverFilter('Music Lovers', Icons.music_note_rounded),
  _DiscoverFilter('Travel', Icons.flight_takeoff_rounded),
  _DiscoverFilter('Marriage', Icons.favorite_rounded),
  _DiscoverFilter('Coffee Dates', Icons.coffee_rounded),
  _DiscoverFilter('Fitness', Icons.fitness_center_rounded),
  _DiscoverFilter('Entrepreneurs', Icons.rocket_launch_rounded),
  _DiscoverFilter('Foodies', Icons.restaurant_rounded),
  _DiscoverFilter('Pets', Icons.pets_rounded),
  _DiscoverFilter('Adventure', Icons.landscape_rounded),
  _DiscoverFilter('Art', Icons.palette_rounded),
  _DiscoverFilter('Movies', Icons.movie_rounded),
  _DiscoverFilter('Gaming', Icons.sports_esports_rounded),
  _DiscoverFilter('Spiritual', Icons.self_improvement_rounded),
  _DiscoverFilter('Language Exchange', Icons.translate_rounded),
  _DiscoverFilter('Long Term', Icons.all_inclusive_rounded),
  _DiscoverFilter('Casual', Icons.waves_rounded),
];

const _drawerItems = <_DrawerItem>[
  _DrawerItem(
    'Advanced filters',
    Icons.tune_rounded,
    AdvancedFiltersScreen.routeName,
  ),
];
>>>>>>> main
