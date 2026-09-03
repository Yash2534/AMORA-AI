import 'dart:async';

import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/amoraa_confirm_action_sheet.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:flutter/material.dart';

class LikesSuperLikesScreen extends StatefulWidget {
  const LikesSuperLikesScreen({super.key, this.controller});

  static const routeName = '/likes-super-likes';

  final ProfileRelationshipController? controller;

  @override
  State<LikesSuperLikesScreen> createState() => _LikesSuperLikesScreenState();
}

class _LikesSuperLikesScreenState extends State<LikesSuperLikesScreen> {
  ProfileReactionType _selected = ProfileReactionType.like;
  late final ScrollController _scrollController;

  ProfileRelationshipController get _source =>
      widget.controller ?? ProfileRelationshipController.instance;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMore);
    _source.addListener(_refresh);
    if (widget.controller == null) unawaited(_source.refreshRemote());
  }

  @override
  void didUpdateWidget(covariant LikesSuperLikesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous =
        oldWidget.controller ?? ProfileRelationshipController.instance;
    if (previous == _source) return;
    previous.removeListener(_refresh);
    _source.addListener(_refresh);
  }

  @override
  void dispose() {
    _source.removeListener(_refresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 240) {
      unawaited(_source.loadMoreReactions(_selected));
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _selected == ProfileReactionType.like
        ? _source.likedProfiles
        : _source.superLikedProfiles;
    final likes = _source.likedProfiles.length;
    final superLikes = _source.superLikedProfiles.length;
    if (_source.loading && profiles.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_source.error != null && profiles.isEmpty) {
      return Scaffold(
        appBar: AmoraAppBar(
          title: 'Likes & Super Likes',
          onBack: () => Navigator.of(context).maybePop(),
          maxContentWidth: 720,
        ),
        body: Center(
          child: TextButton(
            onPressed: _source.refreshRemote,
            child: Text('${_source.error}\nTry again'),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AmoraAppBar(
        title: 'Likes & Super Likes',
        onBack: () => Navigator.of(context).maybePop(),
        maxContentWidth: 720,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space16,
                  AmoraSpacing.space20,
                  AmoraSpacing.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Likes & Super Likes',
                      style: AmoraTextStyles.headlineLarge,
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      'People you’ve shown interest in.',
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    _ReactionSegment(
                      selected: _selected,
                      likes: likes,
                      superLikes: superLikes,
                      onSelected: (value) => setState(() => _selected = value),
                    ),
                    if (_source.error != null && profiles.isNotEmpty) ...[
                      const SizedBox(height: AmoraSpacing.space8),
                      TextButton(
                        onPressed: () => _source.reactionHasMore(_selected)
                            ? _source.loadMoreReactions(_selected)
                            : _source.refreshRemote(),
                        child: Text('${_source.error}\nTry again'),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: profiles.isEmpty
                      ? _ReactionEmptyState(
                          key: ValueKey('reaction-empty-${_selected.name}'),
                          type: _selected,
                          onDiscover: () => Navigator.of(
                            context,
                          ).pushNamed(DiscoverScreen.routeName),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          key: ValueKey(
                            'reaction-${_selected.name}-${profiles.map((profile) => profile.id).join('-')}',
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            AmoraSpacing.space20,
                            AmoraSpacing.space8,
                            AmoraSpacing.space20,
                            AmoraSpacing.space32,
                          ),
                          itemCount:
                              profiles.length +
                              (_source.reactionLoadingMore(_selected) ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AmoraSpacing.space12),
                          itemBuilder: (context, index) {
                            if (index == profiles.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final profile = profiles[index];
                            final isLike =
                                _selected == ProfileReactionType.like;
                            return ManagedProfileCard(
                              key: ValueKey(
                                '${isLike ? 'liked' : 'super-liked'}-${profile.id}',
                              ),
                              profile: profile,
                              actionLabel: isLike
                                  ? 'Unlike'
                                  : 'Remove Super Like',
                              actionSemanticLabel:
                                  (isLike
                                          ? AmoraaProfileAction.unlike
                                          : AmoraaProfileAction.removeSuperLike)
                                      .semanticLabel(
                                        amoraaProfileActionName(profile.name),
                                      ),
                              actionIcon: isLike
                                  ? Icons.favorite_rounded
                                  : Icons.star_rounded,
                              onAction: () =>
                                  _confirmRemoval(profile, isLike: isLike),
                              onOpen: () => Navigator.of(context).pushNamed(
                                ProfileDetailScreen.routeName,
                                arguments: profile,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemoval(
    DummyProfile profile, {
    required bool isLike,
  }) async {
    final action = isLike
        ? AmoraaProfileAction.unlike
        : AmoraaProfileAction.removeSuperLike;
    await showAmoraaProfileActionConfirmation(
      context: context,
      action: action,
      profileName: profile.name,
      onConfirm: () {
        if (isLike) {
          return _source.removeLikePersisted(profile.id);
        } else {
          return _source.removeSuperLikePersisted(profile.id);
        }
      },
    );
  }
}

class _ReactionSegment extends StatelessWidget {
  const _ReactionSegment({
    required this.selected,
    required this.likes,
    required this.superLikes,
    required this.onSelected,
  });

  final ProfileReactionType selected;
  final int likes;
  final int superLikes;
  final ValueChanged<ProfileReactionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('likes-super-likes-segment'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ReactionSegmentItem(
              key: const ValueKey('likes-tab'),
              label: 'Likes ($likes)',
              icon: Icons.favorite_rounded,
              selected: selected == ProfileReactionType.like,
              onTap: () => onSelected(ProfileReactionType.like),
            ),
          ),
          Expanded(
            child: _ReactionSegmentItem(
              key: const ValueKey('super-likes-tab'),
              label: 'Super Likes ($superLikes)',
              icon: Icons.star_rounded,
              selected: selected == ProfileReactionType.superLike,
              onTap: () => onSelected(ProfileReactionType.superLike),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionSegmentItem extends StatelessWidget {
  const _ReactionSegmentItem({
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.tertiary : AppColors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? AppColors.secondary : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        label,
                        key: ValueKey(label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.labelMedium.copyWith(
                          color: AppColors.text,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
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

class _ReactionEmptyState extends StatelessWidget {
  const _ReactionEmptyState({
    super.key,
    required this.type,
    required this.onDiscover,
  });

  final ProfileReactionType type;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final isLike = type == ProfileReactionType.like;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: PremiumCard(
          radius: AmoraRadius.extraLarge,
          padding: const EdgeInsets.all(AmoraSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLike
                    ? Icons.favorite_border_rounded
                    : Icons.star_border_rounded,
                color: AppColors.primary,
                size: 42,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              Text(
                isLike ? 'No liked profiles yet' : 'No Super Likes yet',
                textAlign: TextAlign.center,
                style: AmoraTextStyles.titleLarge,
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                isLike
                    ? 'Profiles you like will appear here.'
                    : 'Profiles you Super Like will appear here.',
                textAlign: TextAlign.center,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              TextButton(
                onPressed: onDiscover,
                child: const Text('Discover profiles'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
