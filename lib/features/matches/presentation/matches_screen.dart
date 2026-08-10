import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/matches/presentation/widgets/amoraa_inline_compatibility_filter.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, this.showNavigation = true});

  static const routeName = '/matches';
  final bool showNavigation;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _relationships = ProfileRelationshipController.instance;
  AiMatchFilter _filter = AiMatchFilter.all;
  int _compatibilityThreshold = defaultCompatibilityThreshold;
  final Set<String> _selectedProfileIds = <String>{};
  final Set<String> _likedProfileIds = <String>{};
  final Set<String> _processingProfileIds = <String>{};
  bool _selectionMode = false;
  bool _bulkSubmitting = false;
  int _bulkCompleted = 0;
  int _bulkTotal = 0;
  int? _successCount;

  @override
  void initState() {
    super.initState();
    _relationships.addListener(_refreshReactions);
  }

  @override
  void dispose() {
    _relationships.removeListener(_refreshReactions);
    super.dispose();
  }

  void _refreshReactions() {
    if (mounted) setState(() {});
  }

  List<DummyProfile> get _recommendations {
    return List<DummyProfile>.of(_uniqueRecommendations)
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  List<DummyProfile> get _thresholdRecommendations => _recommendations
      .where(
        (profile) => profile.score.clamp(0, 100) >= _compatibilityThreshold,
      )
      .toList(growable: false);

  List<DummyProfile> get _visibleRecommendations {
    final profiles = _thresholdRecommendations;
    if (profiles.isEmpty) return const [];
    final best = _highestScoring(profiles);
    return profiles
        .where((profile) {
          return switch (_filter) {
            AiMatchFilter.all => true,
            AiMatchFilter.bestMatch => profile.id == best.id,
            AiMatchFilter.activeNow => _isOnline(profile),
            AiMatchFilter.verified => profile.verified,
          };
        })
        .toList(growable: false);
  }

  List<DummyProfile> get _selectedProfiles => _recommendations
      .where((profile) => _selectedProfileIds.contains(profile.id))
      .toList(growable: false);

  List<DummyProfile> get _eligibleVisibleRecommendations =>
      _visibleRecommendations.where(_canLike).toList(growable: false);

  bool _canLike(DummyProfile profile) =>
      !_likedProfileIds.contains(profile.id) &&
      !_relationships.isLiked(profile.id) &&
      !_processingProfileIds.contains(profile.id);

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRecommendations;
    final featured = visible.isEmpty ? null : _highestScoring(visible);
    final feed = featured == null
        ? const <DummyProfile>[]
        : visible
              .where((profile) => profile.id != featured.id)
              .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 1080,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 760;
              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AmoraaMainPageHeader.pageHorizontalInset,
                          AmoraaMainPageHeader.safeTopSpacing,
                          AmoraaMainPageHeader.pageHorizontalInset,
                          0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _selectionMode
                              ? AiMatchesSelectionToolbar(
                                  key: const ValueKey(
                                    'ai-matches-selection-toolbar',
                                  ),
                                  selectedCount: _selectedProfileIds.length,
                                  canSelectAll:
                                      !_bulkSubmitting &&
                                      _eligibleVisibleRecommendations.any(
                                        (profile) => !_selectedProfileIds
                                            .contains(profile.id),
                                      ),
                                  editingLocked: _bulkSubmitting,
                                  onClose: _exitSelectionMode,
                                  onSelectAll: _selectAllVisible,
                                  onClearAll: _clearSelection,
                                )
                              : AiMatchesAppBar(
                                  key: const ValueKey(
                                    'ai-matches-default-app-bar',
                                  ),
                                  onInfo: _showRecommendationInfo,
                                  onSelect: _enterSelectionMode,
                                ),
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          key: const PageStorageKey<String>(
                            'ai-matches-scroll',
                          ),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                desktop
                                    ? AmoraSpacing.space24
                                    : AmoraSpacing.space20,
                                AmoraSpacing.space8,
                                desktop
                                    ? AmoraSpacing.space24
                                    : AmoraSpacing.space20,
                                AmoraSpacing.space12,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Best Matches',
                                      style: AmoraTextStyles.sectionTitle,
                                    ),
                                    const SizedBox(
                                      height: AmoraSpacing.space12,
                                    ),
                                    AmoraaInlineCompatibilityFilter(
                                      value: _compatibilityThreshold,
                                      onChanged: (value) {
                                        if (value == _compatibilityThreshold) {
                                          return;
                                        }
                                        setState(
                                          () => _compatibilityThreshold = value,
                                        );
                                      },
                                      onReset: () => setState(
                                        () => _compatibilityThreshold =
                                            defaultCompatibilityThreshold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  desktop
                                      ? AmoraSpacing.space24
                                      : AmoraSpacing.space20,
                                  AmoraSpacing.space8,
                                  desktop
                                      ? AmoraSpacing.space24
                                      : AmoraSpacing.space20,
                                  AmoraSpacing.space20,
                                ),
                                child: AiMatchFilterBar(
                                  selected: _filter,
                                  onSelected: (filter) =>
                                      setState(() => _filter = filter),
                                ),
                              ),
                            ),
                            if (_recommendations.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: AiMatchesEmptyState(
                                  onDiscover: () => Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/browse'),
                                ),
                              )
                            else if (_thresholdRecommendations.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: AiMatchesThresholdEmptyState(
                                  onLowerFilter: () => setState(
                                    () => _compatibilityThreshold =
                                        defaultCompatibilityThreshold,
                                  ),
                                ),
                              )
                            else if (featured == null)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: AiMatchesFilteredEmptyState(
                                  onShowAll: () => setState(
                                    () => _filter = AiMatchFilter.all,
                                  ),
                                ),
                              )
                            else ...[
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: desktop
                                      ? AmoraSpacing.space24
                                      : AmoraSpacing.space20,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const _SectionTitle(
                                        icon: Icons.auto_awesome_rounded,
                                        title: 'Featured recommendation',
                                      ),
                                      const SizedBox(
                                        height: AmoraSpacing.space12,
                                      ),
                                      _MatchReveal(
                                        key: ValueKey(
                                          'featured-reveal-'
                                          '$_compatibilityThreshold-'
                                          '${featured.id}',
                                        ),
                                        delay: Duration.zero,
                                        child: SelectableAiMatchCard(
                                          profile: featured,
                                          selectionMode: _selectionMode,
                                          selected: _selectedProfileIds
                                              .contains(featured.id),
                                          enabled: _canLike(featured),
                                          processing: _processingProfileIds
                                              .contains(featured.id),
                                          radius: 30,
                                          onToggle: () =>
                                              _toggleProfileSelection(featured),
                                          onLongPress: () =>
                                              _enterSelectionMode(featured),
                                          child: FeaturedAiMatchCard(
                                            key: ValueKey(
                                              'featured-match-${featured.id}',
                                            ),
                                            profile: featured,
                                            horizontal: desktop,
                                            onOpenProfile: () =>
                                                _openProfile(featured),
                                            onMessage: () =>
                                                _openConversation(featured),
                                            onWhyMatch: () =>
                                                _showWhyThisMatch(featured),
                                          ),
                                        ),
                                      ),
                                      if (feed.isNotEmpty) ...[
                                        const SizedBox(
                                          height: AmoraSpacing.space24,
                                        ),
                                        const _SectionTitle(
                                          icon: Icons.favorite_border_rounded,
                                          title: 'More recommendations',
                                        ),
                                        const SizedBox(
                                          height: AmoraSpacing.space12,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (feed.isNotEmpty)
                                if (desktop)
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AmoraSpacing.space24,
                                    ),
                                    sliver: SliverGrid.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing:
                                                AmoraSpacing.space16,
                                            crossAxisSpacing:
                                                AmoraSpacing.space16,
                                            mainAxisExtent: 1024,
                                          ),
                                      itemCount: feed.length,
                                      itemBuilder: (context, index) =>
                                          _buildFeedCard(feed[index], index),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AmoraSpacing.space20,
                                    ),
                                    sliver: SliverList.separated(
                                      itemCount: feed.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(
                                            height: AmoraSpacing.space16,
                                          ),
                                      itemBuilder: (context, index) =>
                                          _buildFeedCard(feed[index], index),
                                    ),
                                  ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      _selectionMode &&
                                          (_selectedProfileIds.isNotEmpty ||
                                              _bulkSubmitting)
                                      ? (widget.showNavigation ? 224 : 132)
                                      : widget.showNavigation
                                      ? FloatingBottomNav.contentBottomPaddingFor(
                                          context,
                                        )
                                      : FloatingBottomNav.contentSpacing,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.showNavigation)
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: FloatingBottomNav(activeTab: AmoraNavTab.matches),
                    ),
                  Positioned(
                    left: desktop ? AmoraSpacing.space24 : AmoraSpacing.space12,
                    right: desktop
                        ? AmoraSpacing.space24
                        : AmoraSpacing.space12,
                    bottom: widget.showNavigation
                        ? FloatingBottomNav.contentBottomPaddingFor(context)
                        : AmoraSpacing.space8,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .18),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child:
                          _selectionMode &&
                              (_selectedProfileIds.isNotEmpty ||
                                  _bulkSubmitting)
                          ? BulkLikeActionBar(
                              key: const ValueKey('bulk-like-action-bar'),
                              profiles: _selectedProfiles,
                              submitting: _bulkSubmitting,
                              completed: _bulkCompleted,
                              total: _bulkTotal,
                              onLikeSelected: _reviewBulkLike,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('bulk-like-action-bar-hidden'),
                            ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -.08),
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: _successCount != null
                            ? _BulkLikeSuccessToast(
                                key: ValueKey(
                                  'bulk-like-success-$_successCount',
                                ),
                                count: _successCount!,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(DummyProfile profile, int index) {
    return _MatchReveal(
      key: ValueKey('match-reveal-$_compatibilityThreshold-${profile.id}'),
      delay: Duration(milliseconds: (index % 4) * 45),
      child: SelectableAiMatchCard(
        profile: profile,
        selectionMode: _selectionMode,
        selected: _selectedProfileIds.contains(profile.id),
        enabled: _canLike(profile),
        processing: _processingProfileIds.contains(profile.id),
        radius: 26,
        onToggle: () => _toggleProfileSelection(profile),
        onLongPress: () => _enterSelectionMode(profile),
        child: AiMatchCard(
          key: ValueKey('ai-match-${profile.id}'),
          profile: profile,
          onOpenProfile: () => _openProfile(profile),
          onMessage: () => _openConversation(profile),
          onWhyMatch: () => _showWhyThisMatch(profile),
        ),
      ),
    );
  }

  void _enterSelectionMode([DummyProfile? profile]) {
    if (_bulkSubmitting) return;
    setState(() {
      _selectionMode = true;
      if (profile != null && _canLike(profile)) {
        _selectedProfileIds.add(profile.id);
      }
    });
  }

  void _exitSelectionMode() {
    if (_bulkSubmitting) return;
    setState(() {
      _selectionMode = false;
      _selectedProfileIds.clear();
    });
  }

  void _toggleProfileSelection(DummyProfile profile) {
    if (_bulkSubmitting || !_canLike(profile)) return;
    setState(() {
      _selectionMode = true;
      if (!_selectedProfileIds.add(profile.id)) {
        _selectedProfileIds.remove(profile.id);
      }
    });
  }

  void _selectAllVisible() {
    if (_bulkSubmitting) return;
    setState(() {
      _selectedProfileIds.addAll(
        _eligibleVisibleRecommendations.map((profile) => profile.id),
      );
    });
  }

  void _clearSelection() {
    if (_bulkSubmitting) return;
    setState(_selectedProfileIds.clear);
  }

  Future<void> _reviewBulkLike() async {
    if (_bulkSubmitting) return;
    final profiles = _selectedProfiles.where(_canLike).toList(growable: false);
    if (profiles.isEmpty) return;

    if (profiles.length > 1) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (_) => BulkLikeConfirmationSheet(profiles: profiles),
      );
      if (confirmed != true || !mounted) return;
    }

    await _sendSelectedLikes(profiles);
  }

  Future<bool> _sendExistingLike(DummyProfile profile) async {
    final actions = DiscoverActionController(profileIds: [profile.id]);
    try {
      await actions.likeProfile();
      return actions.likedProfileIds.contains(profile.id);
    } finally {
      actions.dispose();
    }
  }

  Future<void> _sendSelectedLikes(List<DummyProfile> profiles) async {
    if (_bulkSubmitting || profiles.isEmpty) return;
    final successes = <DummyProfile>[];
    final failures = <DummyProfile>[];

    setState(() {
      _bulkSubmitting = true;
      _bulkCompleted = 0;
      _bulkTotal = profiles.length;
    });

    for (final profile in profiles) {
      if (!mounted) return;
      if (_likedProfileIds.contains(profile.id)) {
        setState(() {
          _selectedProfileIds.remove(profile.id);
          _bulkCompleted++;
        });
        continue;
      }

      setState(() => _processingProfileIds.add(profile.id));
      var sent = false;
      try {
        sent = await _sendExistingLike(profile);
      } catch (_) {
        sent = false;
      }
      if (!mounted) return;

      setState(() {
        _processingProfileIds.remove(profile.id);
        _bulkCompleted++;
        if (sent) {
          _likedProfileIds.add(profile.id);
          _selectedProfileIds.remove(profile.id);
          successes.add(profile);
        } else {
          failures.add(profile);
        }
      });
      if (sent) _relationships.likeProfile(profile);
    }

    if (!mounted) return;
    setState(() => _bulkSubmitting = false);

    if (failures.isEmpty) {
      final successCount = successes.length;
      setState(() {
        _selectionMode = false;
        _selectedProfileIds.clear();
        _successCount = successCount;
      });
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _successCount == successCount) {
          setState(() => _successCount = null);
        }
      });
      return;
    }

    final action = await showModalBottomSheet<_BulkLikeResultAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => BulkLikeResultSheet(
        successCount: successes.length,
        failedProfiles: failures,
      ),
    );
    if (!mounted) return;

    if (successes.isEmpty && action == _BulkLikeResultAction.retry) {
      await _sendSelectedLikes(failures);
      return;
    }
    if (action == _BulkLikeResultAction.done) {
      _exitSelectionMode();
    }
  }

  void _openProfile(DummyProfile profile) {
    Navigator.of(
      context,
    ).pushNamed(ProfileDetailScreen.routeName, arguments: profile);
  }

  void _openConversation(DummyProfile profile) {
    final conversationId = LocalChatRepository.instance
        .ensureConversationForProfile(profile);
    Navigator.of(context).pushNamed(
      ChatDetailScreen.routeName,
      arguments: ChatDetailArgs(conversationId: conversationId),
    );
  }

  void _showWhyThisMatch(DummyProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => WhyThisMatchSheet(profile: profile),
    );
  }

  void _showRecommendationInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AmoraSpacing.space20,
            AmoraSpacing.space20,
            AmoraSpacing.space20,
            AmoraSpacing.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: AmoraSpacing.space20),
              const _SectionTitle(
                icon: Icons.auto_awesome_rounded,
                title: 'How recommendations work',
              ),
              const SizedBox(height: AmoraSpacing.space12),
              Text(
                'AMORAA presents the compatibility scores and profile information already available for this recommendation set. Scores are guidance, not a guarantee of chemistry.',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .72),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AiMatchFilter { all, bestMatch, activeNow, verified }

class AiMatchesAppBar extends StatelessWidget {
  const AiMatchesAppBar({
    super.key,
    required this.onInfo,
    required this.onSelect,
  });

  final VoidCallback onInfo;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AmoraaMainPageHeader(
      title: 'AI Matches',
      subtitle: 'Curated for you',
      actions: [
        AmoraaMainPageHeaderAction(
          key: const ValueKey('ai-matches-select'),
          tooltip: 'Select matches',
          semanticLabel: 'Select matches',
          icon: Icons.checklist_rounded,
          onPressed: onSelect,
        ),
        AmoraaMainPageHeaderAction(
          key: const ValueKey('ai-matches-info'),
          tooltip: 'About AI recommendations',
          semanticLabel: 'About AI recommendations',
          icon: Icons.info_outline_rounded,
          onPressed: onInfo,
        ),
      ],
    );
  }
}

class AiMatchesSelectionToolbar extends StatelessWidget {
  const AiMatchesSelectionToolbar({
    super.key,
    required this.selectedCount,
    required this.canSelectAll,
    required this.editingLocked,
    required this.onClose,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final int selectedCount;
  final bool canSelectAll;
  final bool editingLocked;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$selectedCount profiles selected',
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            return Row(
              children: [
                IconButton(
                  key: const ValueKey('ai-matches-selection-close'),
                  tooltip: 'Cancel selection',
                  onPressed: editingLocked ? null : onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.primary,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$selectedCount selected',
                      maxLines: 1,
                      style: AmoraTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (canSelectAll)
                  if (compact)
                    IconButton(
                      key: const ValueKey('ai-matches-select-all'),
                      tooltip: 'Select all eligible profiles',
                      onPressed: onSelectAll,
                      icon: const Icon(Icons.done_all_rounded),
                      color: AppColors.primary,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    )
                  else
                    TextButton(
                      key: const ValueKey('ai-matches-select-all'),
                      onPressed: onSelectAll,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Select All'),
                    ),
                if (compact)
                  IconButton(
                    key: const ValueKey('ai-matches-clear-all'),
                    tooltip: 'Clear all selected profiles',
                    onPressed: editingLocked || selectedCount == 0
                        ? null
                        : onClearAll,
                    icon: const Icon(Icons.remove_done_rounded),
                    color: AppColors.secondary,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  )
                else
                  TextButton(
                    key: const ValueKey('ai-matches-clear-all'),
                    onPressed: editingLocked || selectedCount == 0
                        ? null
                        : onClearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Text('Clear All'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AiMatchFilterBar extends StatelessWidget {
  const AiMatchFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AiMatchFilter selected;
  final ValueChanged<AiMatchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return AmoraaHorizontalFilterBar<AiMatchFilter>(
      key: const ValueKey('ai-match-filter-bar'),
      options: AiMatchFilter.values,
      selectedValues: <AiMatchFilter>{selected},
      multiSelect: false,
      labelBuilder: _aiMatchFilterLabel,
      iconBuilder: _aiMatchFilterIcon,
      optionKeyPrefix: 'ai-match-filter',
      onChanged: (filters) => onSelected(filters.single),
    );
  }
}

String _aiMatchFilterLabel(AiMatchFilter filter) => switch (filter) {
  AiMatchFilter.all => 'All',
  AiMatchFilter.bestMatch => 'Best Match',
  AiMatchFilter.activeNow => 'Active Now',
  AiMatchFilter.verified => 'Verified',
};

IconData _aiMatchFilterIcon(AiMatchFilter filter) => switch (filter) {
  AiMatchFilter.all => Icons.favorite_border_rounded,
  AiMatchFilter.bestMatch => Icons.auto_awesome_rounded,
  AiMatchFilter.activeNow => Icons.circle,
  AiMatchFilter.verified => Icons.verified_rounded,
};

class SelectableAiMatchCard extends StatelessWidget {
  const SelectableAiMatchCard({
    super.key,
    required this.profile,
    required this.selectionMode,
    required this.selected,
    required this.enabled,
    required this.processing,
    required this.radius,
    required this.onToggle,
    required this.onLongPress,
    required this.child,
  });

  final DummyProfile profile;
  final bool selectionMode;
  final bool selected;
  final bool enabled;
  final bool processing;
  final double radius;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = processing
        ? 'Sending Like to ${profile.name}'
        : !enabled
        ? '${profile.name} cannot be selected'
        : selected
        ? '${profile.name} selected'
        : 'Select ${profile.name}';
    return Semantics(
      container: true,
      selected: selectionMode ? selected : null,
      label: selectionMode ? semanticLabel : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: selected ? .992 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(selectionMode ? 2 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius + 3),
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : AppColors.secondary.withValues(alpha: 0),
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: .16),
                      blurRadius: 20,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: selectionMode && enabled && !processing ? onToggle : null,
              onLongPress: enabled && !processing ? onLongPress : null,
              borderRadius: BorderRadius.circular(radius),
              focusColor: AppColors.tertiary.withValues(alpha: .24),
              child: Stack(
                children: [
                  AbsorbPointer(absorbing: selectionMode, child: child),
                  if (selectionMode)
                    Positioned(
                      top: AmoraSpacing.space12,
                      right: AmoraSpacing.space12,
                      child: ProfileSelectionIndicator(
                        profileName: profile.name,
                        selected: selected,
                        enabled: enabled,
                        processing: processing,
                        onTap: onToggle,
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

class ProfileSelectionIndicator extends StatelessWidget {
  const ProfileSelectionIndicator({
    super.key,
    required this.profileName,
    required this.selected,
    required this.enabled,
    required this.processing,
    required this.onTap,
  });

  final String profileName;
  final bool selected;
  final bool enabled;
  final bool processing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = processing
        ? 'Sending Like to $profileName'
        : !enabled
        ? '$profileName is already liked'
        : selected
        ? 'Remove $profileName from selection'
        : 'Select $profileName';
    return Tooltip(
      message: label,
      child: Semantics(
        button: enabled && !processing,
        selected: selected,
        label: label,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Material(
              color: selected
                  ? AppColors.primary
                  : AppColors.surface.withValues(alpha: .94),
              shape: CircleBorder(
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : AppColors.secondary.withValues(
                          alpha: enabled ? .72 : .28,
                        ),
                ),
              ),
              elevation: selected ? 2 : 0,
              shadowColor: AppColors.primary.withValues(alpha: .18),
              child: InkWell(
                onTap: enabled && !processing ? onTap : null,
                customBorder: const CircleBorder(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox.square(
                    key: ValueKey('$selected-$processing-$enabled'),
                    dimension: 30,
                    child: processing
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        : Icon(
                            selected
                                ? Icons.check_rounded
                                : enabled
                                ? Icons.circle_outlined
                                : Icons.favorite_rounded,
                            color: selected
                                ? AppColors.surface
                                : enabled
                                ? AppColors.secondary
                                : AppColors.primary.withValues(alpha: .38),
                            size: selected ? 20 : 18,
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

class FeaturedAiMatchCard extends StatelessWidget {
  const FeaturedAiMatchCard({
    super.key,
    required this.profile,
    required this.horizontal,
    required this.onOpenProfile,
    required this.onMessage,
    required this.onWhyMatch,
  });

  final DummyProfile profile;
  final bool horizontal;
  final VoidCallback onOpenProfile;
  final VoidCallback onMessage;
  final VoidCallback onWhyMatch;

  @override
  Widget build(BuildContext context) {
    final image = AiMatchImage(
      profile: profile,
      featured: true,
      onTap: onOpenProfile,
    );
    final content = _AiMatchContent(
      profile: profile,
      featured: true,
      onOpenProfile: onOpenProfile,
      onMessage: onMessage,
      onWhyMatch: onWhyMatch,
    );
    return DecoratedBox(
      decoration: _matchCardDecoration(radius: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: horizontal
            ? SizedBox(
                height: 470,
                child: Row(
                  children: [
                    Expanded(flex: 10, child: image),
                    Expanded(flex: 11, child: content),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(aspectRatio: .82, child: image),
                  content,
                ],
              ),
      ),
    );
  }
}

class AiMatchCard extends StatelessWidget {
  const AiMatchCard({
    super.key,
    required this.profile,
    required this.onOpenProfile,
    required this.onMessage,
    required this.onWhyMatch,
  });

  final DummyProfile profile;
  final VoidCallback onOpenProfile;
  final VoidCallback onMessage;
  final VoidCallback onWhyMatch;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _matchCardDecoration(radius: 26),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: AiMatchImage(profile: profile, onTap: onOpenProfile),
            ),
            _AiMatchContent(
              profile: profile,
              onOpenProfile: onOpenProfile,
              onMessage: onMessage,
              onWhyMatch: onWhyMatch,
            ),
          ],
        ),
      ),
    );
  }
}

class AiMatchImage extends StatelessWidget {
  const AiMatchImage({
    super.key,
    required this.profile,
    required this.onTap,
    this.featured = false,
  });

  final DummyProfile profile;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      image: true,
      label: 'Open ${profile.name} profile',
      child: Material(
        color: AppColors.tertiary.withValues(alpha: .34),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return AmoraProfileImage(
                    imageUrl: profile.imageUrl,
                    assetPath: profile.fallbackAsset,
                    initials: profile.initials,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  );
                },
              ),
              if (featured)
                Positioned(
                  top: AmoraSpacing.space12,
                  right: AmoraSpacing.space12,
                  child: DecoratedBox(
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
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: AmoraSpacing.space4),
                          Text(
                            'Top recommendation',
                            style: AmoraTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiMatchContent extends StatelessWidget {
  const _AiMatchContent({
    required this.profile,
    required this.onOpenProfile,
    required this.onMessage,
    required this.onWhyMatch,
    this.featured = false,
  });

  final DummyProfile profile;
  final VoidCallback onOpenProfile;
  final VoidCallback onMessage;
  final VoidCallback onWhyMatch;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.name.trim().split(RegExp(r'\s+')).first;
    final visibleInterests = ProfileInterestPolicy.visible(profile.interests);
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(
          featured ? AmoraSpacing.space20 : AmoraSpacing.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpenProfile,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${profile.name}, ${profile.age}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (featured
                                  ? AmoraTextStyles.headlineSmall
                                  : AmoraTextStyles.titleLarge)
                              .copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                  if (resolveAmoraaIdentityBadge(
                        isAadhaarVerified: profile.verified,
                        isPremium: profile.premium,
                      ) !=
                      AmoraaIdentityBadgeType.none)
                    Padding(
                      padding: EdgeInsets.only(left: AmoraSpacing.space8),
                      child: AmoraaIdentityBadge(
                        isAadhaarVerified: profile.verified,
                        isPremium: profile.premium,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AmoraSpacing.space4),
            Text(
              profile.profession,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            MatchQuickFacts(profile: profile),
            const SizedBox(height: AmoraSpacing.space12),
            AiMatchReason(profile: profile, onTap: onWhyMatch),
            if (visibleInterests.isNotEmpty) ...[
              const SizedBox(height: AmoraSpacing.space12),
              Text(
                '$firstName’s interests',
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .62),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Wrap(
                spacing: AmoraSpacing.space8,
                runSpacing: AmoraSpacing.space8,
                children: [
                  for (final interest in visibleInterests.take(3))
                    SharedInterestChip(label: interest),
                  if (visibleInterests.length > 3)
                    SharedInterestChip(
                      label: '+${visibleInterests.length - 3} more',
                    ),
                ],
              ),
            ],
            const SizedBox(height: AmoraSpacing.space16),
            AiMatchActionBar(
              onOpenProfile: onOpenProfile,
              onMessage: onMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class MatchQuickFacts extends StatelessWidget {
  const MatchQuickFacts({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AmoraSpacing.space12,
      runSpacing: AmoraSpacing.space8,
      children: [
        _InlineFact(icon: Icons.location_on_rounded, label: profile.distance),
        _InlineFact(
          icon: _isOnline(profile) ? Icons.circle : Icons.schedule_rounded,
          label: profile.status,
          smallIcon: _isOnline(profile),
        ),
        _InlineFact(
          icon: Icons.favorite_outline_rounded,
          label: profile.intent,
        ),
      ],
    );
  }
}

class AiMatchReason extends StatelessWidget {
  const AiMatchReason({super.key, required this.profile, required this.onTap});

  final DummyProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.name.trim().split(RegExp(r'\s+')).first;
    return Material(
      color: AppColors.tertiary.withValues(alpha: .26),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('why-match-${profile.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(AmoraSpacing.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: AmoraSpacing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why this recommendation?',
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      '$firstName is looking for ${profile.intent.toLowerCase()} and describes their style as ${profile.personality.toLowerCase()}.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.textNeutral.withValues(alpha: .72),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedInterestChip extends StatelessWidget {
  const SharedInterestChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .86)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
        child: Text(
          label,
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.textNeutral,
          ),
        ),
      ),
    );
  }
}

class AiMatchActionBar extends StatelessWidget {
  const AiMatchActionBar({
    super.key,
    required this.onOpenProfile,
    required this.onMessage,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenProfile,
            icon: const Icon(Icons.person_outline_rounded, size: 18),
            label: const Text('View Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space8,
              ),
              side: const BorderSide(color: AppColors.tertiary),
              textStyle: AmoraTextStyles.labelMedium,
            ),
          ),
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: FilledButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Message'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space8,
              ),
              textStyle: AmoraTextStyles.labelMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class SelectedProfilesAvatarStack extends StatelessWidget {
  const SelectedProfilesAvatarStack({
    super.key,
    required this.profiles,
    this.avatarSize = 34,
  });

  final List<DummyProfile> profiles;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final visible = profiles.take(3).toList(growable: false);
    final extra = profiles.length - visible.length;
    final itemCount = visible.length + (extra > 0 ? 1 : 0);
    if (itemCount == 0) {
      return SizedBox.square(
        dimension: avatarSize,
        child: const Icon(Icons.favorite_rounded, color: AppColors.secondary),
      );
    }
    final overlap = avatarSize * .62;
    return Semantics(
      label: '${profiles.length} selected profile avatars',
      child: SizedBox(
        width: avatarSize + ((itemCount - 1) * overlap),
        height: avatarSize,
        child: Stack(
          children: [
            for (var index = 0; index < visible.length; index++)
              Positioned(
                left: index * overlap,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: AmoraProfileImage(
                      imageUrl: visible[index].imageUrl,
                      assetPath: visible[index].fallbackAsset,
                      initials: visible[index].initials,
                      width: avatarSize - 3,
                      height: avatarSize - 3,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (extra > 0)
              Positioned(
                left: visible.length * overlap,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+$extra',
                    style: AmoraTextStyles.labelSmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
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

class BulkLikeActionBar extends StatelessWidget {
  const BulkLikeActionBar({
    super.key,
    required this.profiles,
    required this.submitting,
    required this.completed,
    required this.total,
    required this.onLikeSelected,
  });

  final List<DummyProfile> profiles;
  final bool submitting;
  final int completed;
  final int total;
  final VoidCallback onLikeSelected;

  @override
  Widget build(BuildContext context) {
    final count = profiles.length;
    final status = submitting
        ? 'Sending Likes… $completed of $total'
        : 'Send Likes to $count ${count == 1 ? 'profile' : 'profiles'}';
    final summary = Row(
      children: [
        SelectedProfilesAvatarStack(profiles: profiles),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Text(
            status,
            maxLines: 2,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
    final action = FilledButton.icon(
      key: const ValueKey('like-selected-button'),
      onPressed: submitting ? null : onLikeSelected,
      icon: submitting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.surface,
              ),
            )
          : const Icon(Icons.favorite_rounded, size: 19),
      label: Text(submitting ? 'Sending Likes' : 'Like Selected'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: .62),
        disabledForegroundColor: AppColors.surface,
        minimumSize: const Size(142, 52),
        padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space16),
      ),
    );

    return Semantics(
      liveRegion: submitting,
      label: submitting ? status : 'Send Likes to $count selected profiles',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.secondary.withValues(alpha: .38)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .13),
              blurRadius: 28,
              spreadRadius: -10,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AmoraSpacing.space12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (compact) ...[
                    summary,
                    const SizedBox(height: AmoraSpacing.space8),
                    SizedBox(width: double.infinity, child: action),
                  ] else
                    Row(
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: AmoraSpacing.space12),
                        action,
                      ],
                    ),
                  if (submitting) ...[
                    const SizedBox(height: AmoraSpacing.space8),
                    ClipRRect(
                      borderRadius: AmoraRadius.pillBorder,
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : completed / total,
                        minHeight: 4,
                        backgroundColor: AppColors.tertiary.withValues(
                          alpha: .42,
                        ),
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BulkLikeConfirmationSheet extends StatelessWidget {
  const BulkLikeConfirmationSheet({super.key, required this.profiles});

  final List<DummyProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final count = profiles.length;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AmoraSpacing.space20,
          AmoraSpacing.space12,
          AmoraSpacing.space20,
          AmoraSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AmoraSpacing.space20),
            Center(
              child: SelectedProfilesAvatarStack(
                profiles: profiles,
                avatarSize: 44,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text(
              'Like selected profiles?',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              'You’re about to send Likes to $count people.',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .72),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 52),
                      side: const BorderSide(color: AppColors.tertiary),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('confirm-send-likes'),
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.favorite_rounded, size: 19),
                    label: const Text('Send Likes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _BulkLikeResultAction { reviewFailed, done, retry }

class BulkLikeResultSheet extends StatelessWidget {
  const BulkLikeResultSheet({
    super.key,
    required this.successCount,
    required this.failedProfiles,
  });

  final int successCount;
  final List<DummyProfile> failedProfiles;

  @override
  Widget build(BuildContext context) {
    final fullFailure = successCount == 0;
    final failedCount = failedProfiles.length;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AmoraSpacing.space20,
          AmoraSpacing.space12,
          AmoraSpacing.space20,
          AmoraSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AmoraSpacing.space20),
            Icon(
              fullFailure
                  ? Icons.favorite_border_rounded
                  : Icons.favorite_rounded,
              color: AppColors.secondary,
              size: 42,
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Text(
              fullFailure
                  ? 'Likes couldn’t be sent'
                  : '$successCount Likes sent, $failedCount couldn’t be sent.',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              fullFailure
                  ? 'Please try again. Your selected profiles are still available.'
                  : 'The failed profiles remain selected so you can review them.',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .72),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Center(
              child: SelectedProfilesAvatarStack(
                profiles: failedProfiles,
                avatarSize: 40,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            if (fullFailure)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, _BulkLikeResultAction.done),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(color: AppColors.tertiary),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, _BulkLikeResultAction.retry),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size(0, 52),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, _BulkLikeResultAction.done),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(color: AppColors.tertiary),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _BulkLikeResultAction.reviewFailed,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size(0, 52),
                      ),
                      child: const Text('Review Failed'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BulkLikeSuccessToast extends StatelessWidget {
  const _BulkLikeSuccessToast({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .82, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Semantics(
        liveRegion: true,
        label: 'Likes sent to $count profiles',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AmoraRadius.pillBorder,
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: .42),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .14),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space20,
              vertical: AmoraSpacing.space12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.secondary),
                const SizedBox(width: AmoraSpacing.space8),
                Text(
                  'Likes sent to $count ${count == 1 ? 'profile' : 'profiles'}',
                  style: AmoraTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
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

class WhyThisMatchSheet extends StatelessWidget {
  const WhyThisMatchSheet({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final factors = <_RecommendationFactor>[
      _RecommendationFactor(
        Icons.auto_awesome_rounded,
        'Compatibility score',
        '${profile.score}% supplied by AMORAA',
      ),
      _RecommendationFactor(
        Icons.favorite_outline_rounded,
        'Relationship intention',
        profile.intent,
      ),
      _RecommendationFactor(
        Icons.location_on_rounded,
        'Distance',
        profile.distance,
      ),
      _RecommendationFactor(
        _isOnline(profile) ? Icons.circle : Icons.schedule_rounded,
        'Activity',
        profile.status,
      ),
      if (profile.verified)
        const _RecommendationFactor(
          Icons.verified_rounded,
          'Trust signal',
          'Profile verified',
        ),
      if (profile.languages.isNotEmpty)
        _RecommendationFactor(
          Icons.translate_rounded,
          'Languages',
          profile.languages.join(' · '),
        ),
    ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AmoraSpacing.space20,
          AmoraSpacing.space16,
          AmoraSpacing.space20,
          AmoraSpacing.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AmoraSpacing.space20),
            const _SectionTitle(
              icon: Icons.auto_awesome_rounded,
              title: 'Why this recommendation',
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              'These are profile and recommendation details already available in AMORAA.',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .66),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            for (final factor in factors)
              Padding(
                padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
                child: _RecommendationFactorTile(factor: factor),
              ),
            const SizedBox(height: AmoraSpacing.space8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AmoraSpacing.space12),
                child: Text(
                  'Recommendations are based on the preferences and profile information available in AMORAA. They do not guarantee compatibility.',
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .68),
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

class AiMatchesEmptyState extends StatelessWidget {
  const AiMatchesEmptyState({super.key, required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return _AiMatchesStateLayout(
      icon: Icons.auto_awesome_rounded,
      title: 'We’re finding better matches for you',
      description:
          'Update your preferences or check back after more compatible people join.',
      actionLabel: 'Explore Discover',
      onAction: onDiscover,
    );
  }
}

class AiMatchesFilteredEmptyState extends StatelessWidget {
  const AiMatchesFilteredEmptyState({super.key, required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return _AiMatchesStateLayout(
      icon: Icons.filter_alt_off_rounded,
      title: 'No matches in this category',
      description: 'Try another filter or broaden your preferences.',
      actionLabel: 'Show all matches',
      onAction: onShowAll,
    );
  }
}

class AiMatchesThresholdEmptyState extends StatelessWidget {
  const AiMatchesThresholdEmptyState({super.key, required this.onLowerFilter});

  final VoidCallback onLowerFilter;

  @override
  Widget build(BuildContext context) {
    return _AiMatchesStateLayout(
      icon: Icons.tune_rounded,
      title: 'No matches at this level yet',
      description: 'Try lowering the compatibility filter to see more people.',
      actionLabel: 'Lower to 70%',
      onAction: onLowerFilter,
    );
  }
}

class AiMatchesErrorState extends StatelessWidget {
  const AiMatchesErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AiMatchesStateLayout(
      icon: Icons.error_outline_rounded,
      title: 'Couldn’t load your AI matches',
      description: 'Check your connection and try again.',
      actionLabel: 'Try Again',
      onAction: onRetry,
    );
  }
}

class AiMatchesLockedState extends StatelessWidget {
  const AiMatchesLockedState({super.key, required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return _AiMatchesStateLayout(
      icon: Icons.lock_outline_rounded,
      title: 'Unlock personalized recommendations',
      description:
          'Use the existing subscription flow to access eligible AI Match benefits.',
      actionLabel: 'View plans',
      onAction: onUpgrade,
    );
  }
}

class AiMatchesOfflineBanner extends StatelessWidget {
  const AiMatchesOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: .38),
        border: Border(
          bottom: BorderSide(color: AppColors.secondary.withValues(alpha: .42)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space16,
          vertical: AmoraSpacing.space8,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(
              child: Text(
                'You’re offline. Showing your most recent matches.',
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.textNeutral,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiMatchesSkeleton extends StatelessWidget {
  const AiMatchesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('ai-matches-skeleton'),
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      children: const [
        _SkeletonBlock(height: 96, radius: 24),
        SizedBox(height: AmoraSpacing.space16),
        _SkeletonBlock(height: 420, radius: 30),
        SizedBox(height: AmoraSpacing.space16),
        _SkeletonBlock(height: 300, radius: 26),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: .36),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

class _AiMatchesStateLayout extends StatelessWidget {
  const _AiMatchesStateLayout({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .42),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 72,
                child: Icon(icon, color: AppColors.primary, size: 34),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .68),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                minimumSize: const Size(168, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationFactorTile extends StatelessWidget {
  const _RecommendationFactorTile({required this.factor});

  final _RecommendationFactor factor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: .36),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 42,
            child: Icon(factor.icon, color: AppColors.primary, size: 20),
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                factor.label,
                style: AmoraTextStyles.labelSmall.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .56),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space4),
              Text(
                factor.value,
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

class _InlineFact extends StatelessWidget {
  const _InlineFact({
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
        Icon(icon, color: AppColors.secondary, size: smallIcon ? 9 : 16),
        const SizedBox(width: AmoraSpacing.space4),
        Text(
          label,
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.textNeutral.withValues(alpha: .72),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: Text(
            title,
            style: AmoraTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: AmoraRadius.pillBorder,
        ),
      ),
    );
  }
}

class _MatchReveal extends StatefulWidget {
  const _MatchReveal({super.key, required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_MatchReveal> createState() => _MatchRevealState();
}

class _MatchRevealState extends State<_MatchReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, .025),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _RecommendationFactor {
  const _RecommendationFactor(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

BoxDecoration _matchCardDecoration({required double radius}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.tertiary.withValues(alpha: .66)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: .10),
        blurRadius: 28,
        spreadRadius: -12,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

bool _isOnline(DummyProfile profile) =>
    profile.status.trim().toLowerCase() == 'online now';

DummyProfile _highestScoring(List<DummyProfile> profiles) {
  return profiles.reduce(
    (current, candidate) =>
        candidate.score > current.score ? candidate : current,
  );
}

List<DummyProfile> _buildUniqueRecommendations() {
  final ids = <String>{};
  final images = <String>{};
  return ImageRepository.profiles
      .skip(18)
      .take(12)
      .where((profile) => ids.add(profile.id) && images.add(profile.imageUrl))
      .toList(growable: false);
}

final _uniqueRecommendations = _buildUniqueRecommendations();
