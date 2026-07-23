import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';

<<<<<<< HEAD
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, this.showNavigation = true});

  final bool showNavigation;
=======
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});
>>>>>>> main

  static const routeName = '/matches';

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  AiMatchFilter _filter = AiMatchFilter.all;

  List<DummyProfile> get _recommendations => _uniqueRecommendations;

  List<DummyProfile> get _visibleRecommendations {
    final profiles = _recommendations;
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
        child: ResponsiveMobileFrame(
<<<<<<< HEAD
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space24,
                  AmoraSpacing.space24,
                  AmoraSpacing.space24,
                  (showNavigation
                          ? AmoraSpacing.navigationContentInset
                          : AmoraSpacing.space32) +
                      bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Likes',
                      subtitle: 'People who liked you and mutual connections.',
                    ),
                    const SizedBox(height: AmoraSpacing.space20),
                    Text(
                      'Liked you',
                      style: AmoraTextStyles.titleLarge.copyWith(
                        color: AppColors.deepWine,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space12),
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _newMatches.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AmoraSpacing.space12),
                        itemBuilder: (context, index) {
                          final match = _newMatches[index];
                          return _NewMatchCard(match: match);
                        },
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    Text(
                      'Mutual matches',
                      style: AmoraTextStyles.titleLarge.copyWith(
                        color: AppColors.deepWine,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space12),
                    for (final match in _conversations)
=======
          maxWidth: 1080,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 760;
              return Stack(
                children: [
                  Column(
                    children: [
>>>>>>> main
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? AmoraSpacing.space24 : AmoraSpacing.space16,
                          AmoraSpacing.space8,
                          desktop ? AmoraSpacing.space24 : AmoraSpacing.space16,
                          AmoraSpacing.space8,
                        ),
                        child: AiMatchesAppBar(onInfo: _showRecommendationInfo),
                      ),
<<<<<<< HEAD
                  ],
                ),
              ),
              if (showNavigation)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AmoraSpacing.space16,
                      AmoraSpacing.space0,
                      AmoraSpacing.space16,
                      AmoraSpacing.space12 + bottomInset,
                    ),
                    child: const FloatingBottomNav(
                      activeTab: AmoraNavTab.likes,
                    ),
                  ),
                ),
            ],
=======
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
                              padding: EdgeInsets.symmetric(
                                horizontal: desktop
                                    ? AmoraSpacing.space24
                                    : AmoraSpacing.space16,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: AiMatchSummary(
                                  recommendationCount: _recommendations.length,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AmoraSpacing.space16,
                                  AmoraSpacing.space16,
                                  AmoraSpacing.space16,
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
                                      : AmoraSpacing.space16,
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
                                      FeaturedAiMatchCard(
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
                                            mainAxisExtent: 880,
                                          ),
                                      itemCount: feed.length,
                                      itemBuilder: (context, index) =>
                                          _buildFeedCard(feed[index], index),
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AmoraSpacing.space16,
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
                              const SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      FloatingBottomNav.contentBottomPadding,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AmoraSpacing.space16,
                      ),
                      child: FloatingBottomNav(activeTab: AmoraNavTab.matches),
                    ),
                  ),
                ],
              );
            },
>>>>>>> main
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(DummyProfile profile, int index) {
    return _MatchReveal(
      delay: Duration(milliseconds: (index % 4) * 45),
      child: AiMatchCard(
        key: ValueKey('ai-match-${profile.id}'),
        profile: profile,
        onOpenProfile: () => _openProfile(profile),
        onMessage: () => _openConversation(profile),
        onWhyMatch: () => _showWhyThisMatch(profile),
      ),
    );
  }

  void _openProfile(DummyProfile profile) {
    Navigator.of(
      context,
    ).pushNamed(ProfileDetailScreen.routeName, arguments: profile);
  }

  void _openConversation(DummyProfile profile) {
    Navigator.of(context).pushNamed(ChatDetailScreen.routeName);
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
                'Amora presents the compatibility scores and profile information already available for this recommendation set. Scores are guidance, not a guarantee of chemistry.',
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
  const AiMatchesAppBar({super.key, required this.onInfo});

  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Matches',
                  maxLines: 1,
                  style: AmoraTextStyles.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
                Text(
                  'Curated for you',
                  maxLines: 1,
                  style: AmoraTextStyles.labelSmall.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .58),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'About AI recommendations',
            child: IconButton(
              key: const ValueKey('ai-matches-info'),
              onPressed: onInfo,
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiMatchSummary extends StatelessWidget {
  const AiMatchSummary({super.key, required this.recommendationCount});

  final int recommendationCount;

  @override
  Widget build(BuildContext context) {
    final copy = recommendationCount == 1
        ? '1 recommendation selected from the compatibility and profile signals available in Amora.'
        : '$recommendationCount recommendations selected from the compatibility and profile signals available in Amora.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .07),
            blurRadius: 24,
            spreadRadius: -12,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .42),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(
                dimension: 48,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Text(
                copy,
                style: AmoraTextStyles.bodyMedium.copyWith(
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
    return SizedBox(
      key: const ValueKey('ai-match-filter-bar'),
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AiMatchFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AmoraSpacing.space8),
        itemBuilder: (context, index) {
          final filter = AiMatchFilter.values[index];
          return _AiMatchFilterChip(
            filter: filter,
            selected: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _AiMatchFilterChip extends StatelessWidget {
  const _AiMatchFilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final AiMatchFilter filter;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (filter) {
    AiMatchFilter.all => 'All',
    AiMatchFilter.bestMatch => 'Best Match',
    AiMatchFilter.activeNow => 'Active Now',
    AiMatchFilter.verified => 'Verified',
  };

  IconData get _icon => switch (filter) {
    AiMatchFilter.all => Icons.favorite_border_rounded,
    AiMatchFilter.bestMatch => Icons.auto_awesome_rounded,
    AiMatchFilter.activeNow => Icons.circle,
    AiMatchFilter.verified => Icons.verified_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: AppColors.surface,
        borderRadius: AmoraRadius.pillBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(
            'ai-match-filter-${_label.toLowerCase().replaceAll(' ', '-')}',
          ),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: AmoraRadius.pillBorder,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.secondary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _icon,
                  size: filter == AiMatchFilter.activeNow ? 10 : 17,
                  color: selected ? AppColors.surface : AppColors.secondary,
                ),
                const SizedBox(width: AmoraSpacing.space8),
                Text(
                  _label,
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: selected ? AppColors.surface : AppColors.textNeutral,
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
              aspectRatio: 1.12,
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
              Positioned(
                top: AmoraSpacing.space12,
                left: AmoraSpacing.space12,
                child: AiCompatibilityBadge(score: profile.score),
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

class AiCompatibilityBadge extends StatelessWidget {
  const AiCompatibilityBadge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$score percent compatibility supplied by Amora',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .94),
          borderRadius: AmoraRadius.pillBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AmoraSpacing.space12,
            vertical: AmoraSpacing.space8,
          ),
          child: Text(
            '$score% Match',
            style: AmoraTextStyles.labelSmall.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w800,
            ),
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
                  if (profile.verified)
                    const Padding(
                      padding: EdgeInsets.only(left: AmoraSpacing.space8),
                      child: Icon(
                        Icons.verified_rounded,
                        color: AppColors.secondary,
                        size: 20,
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
            if (profile.interests.isNotEmpty) ...[
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
                  for (final interest in profile.interests.take(3))
                    SharedInterestChip(label: interest),
                  if (profile.interests.length > 3)
                    SharedInterestChip(
                      label: '+${profile.interests.length - 3} more',
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

class WhyThisMatchSheet extends StatelessWidget {
  const WhyThisMatchSheet({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final factors = <_RecommendationFactor>[
      _RecommendationFactor(
        Icons.auto_awesome_rounded,
        'Compatibility score',
        '${profile.score}% supplied by Amora',
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
              'These are profile and recommendation details already available in Amora.',
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
                  'Recommendations are based on the preferences and profile information available in Amora. They do not guarantee compatibility.',
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
  const _MatchReveal({required this.child, required this.delay});

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
