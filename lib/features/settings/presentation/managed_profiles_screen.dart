import 'dart:async';

import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/amoraa_confirm_action_sheet.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';

class SavedProfilesScreen extends StatefulWidget {
  const SavedProfilesScreen({super.key, this.controller});

  static const routeName = '/saved-profiles';

  final ProfileRelationshipController? controller;

  @override
  State<SavedProfilesScreen> createState() => _SavedProfilesScreenState();
}

class _SavedProfilesScreenState extends State<SavedProfilesScreen> {
  late final ScrollController _scrollController;

  ProfileRelationshipController get source =>
      widget.controller ?? ProfileRelationshipController.instance;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMore);
    if (widget.controller == null) unawaited(source.refreshRemote());
  }

  void _loadMore() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 240) {
      unawaited(source.loadMoreSaved());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: source,
      builder: (context, _) {
        if (source.loading && source.savedProfiles.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (source.error != null && source.savedProfiles.isEmpty) {
          return Scaffold(
            appBar: AmoraAppBar(
              title: 'Saved Profiles',
              onBack: () => Navigator.of(context).maybePop(),
              maxContentWidth: 720,
            ),
            body: Center(
              child: TextButton(
                onPressed: source.refreshRemote,
                child: Text('${source.error}\nTry again'),
              ),
            ),
          );
        }
        return ManagedProfilesScreen(
          title: 'Saved Profiles',
          subtitle: 'People you saved to revisit thoughtfully.',
          icon: Icons.bookmark_rounded,
          profiles: source.savedProfiles,
          emptyTitle: 'No saved profiles yet',
          emptyMessage: 'Profiles you save will appear here.',
          emptyActionLabel: 'Discover profiles',
          onEmptyAction: () =>
              Navigator.of(context).pushNamed(DiscoverScreen.routeName),
          actionLabel: 'Unsave Profile',
          actionSemanticLabel: (profile) => AmoraaProfileAction.unsave
              .semanticLabel(amoraaProfileActionName(profile.name)),
          actionIcon: Icons.bookmark_remove_rounded,
          scrollController: _scrollController,
          loadingMore: source.savedLoadingMore,
          loadMoreError: source.error,
          onRetry: source.savedHasMore
              ? source.loadMoreSaved
              : source.refreshRemote,
          onAction: (profile) => showAmoraaProfileActionConfirmation(
            context: context,
            action: AmoraaProfileAction.unsave,
            profileName: profile.name,
            onConfirm: () => source.removeSavedPersisted(profile.id),
          ),
        );
      },
    );
  }
}

class BlockedProfilesScreen extends StatefulWidget {
  const BlockedProfilesScreen({super.key, this.controller, this.api});

  static const routeName = '/blocked-profiles';

  final ProfileRelationshipController? controller;
  final PhaseTwoApiService? api;

  @override
  State<BlockedProfilesScreen> createState() => _BlockedProfilesScreenState();
}

class _BlockedProfilesScreenState extends State<BlockedProfilesScreen> {
  List<DummyProfile> _profiles = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.api != null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await widget.api!.blockedProfiles();
      if (mounted) {
        setState(() => _profiles = values.map((item) => item.profile).toList());
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load blocked profiles.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(DummyProfile profile) async {
    if (widget.api == null) {
      widget.controller?.unblockProfile(profile.id);
      return;
    }
    try {
      await widget.api!.unblock(profile.id);
      if (mounted) {
        setState(() => _profiles.removeWhere((item) => item.id == profile.id));
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.controller ?? ProfileRelationshipController.instance;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AmoraAppBar(
          title: 'Blocked Profiles',
          onBack: () => Navigator.of(context).maybePop(),
          maxContentWidth: 720,
        ),
        body: Center(
          child: TextButton(
            onPressed: _load,
            child: Text('$_error\nTry again'),
          ),
        ),
      );
    }
    if (widget.api != null) {
      return ManagedProfilesScreen(
        title: 'Blocked Profiles',
        subtitle: 'Private controls for profiles you chose not to see.',
        icon: Icons.block_rounded,
        profiles: _profiles,
        emptyTitle: 'No blocked profiles',
        emptyMessage: 'Profiles you block will appear here.',
        actionLabel: 'Unblock Profile',
        actionSemanticLabel: (profile) => AmoraaProfileAction.unblock
            .semanticLabel(amoraaProfileActionName(profile.name)),
        actionIcon: Icons.lock_open_rounded,
        onAction: (profile) => showAmoraaProfileActionConfirmation(
          context: context,
          action: AmoraaProfileAction.unblock,
          profileName: profile.name,
          onConfirm: () => _unblock(profile),
        ),
      );
    }
    return AnimatedBuilder(
      animation: source,
      builder: (context, _) => ManagedProfilesScreen(
        title: 'Blocked Profiles',
        subtitle: 'Private controls for profiles you chose not to see.',
        icon: Icons.block_rounded,
        profiles: source.blockedProfiles,
        emptyTitle: 'No blocked profiles',
        emptyMessage: 'Profiles you block will appear here.',
        actionLabel: 'Unblock Profile',
        actionSemanticLabel: (profile) => AmoraaProfileAction.unblock
            .semanticLabel(amoraaProfileActionName(profile.name)),
        actionIcon: Icons.lock_open_rounded,
        onAction: (profile) => showAmoraaProfileActionConfirmation(
          context: context,
          action: AmoraaProfileAction.unblock,
          profileName: profile.name,
          onConfirm: () => source.unblockProfile(profile.id),
        ),
      ),
    );
  }
}

class ManagedProfilesScreen extends StatelessWidget {
  const ManagedProfilesScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.profiles,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.actionLabel,
    required this.actionSemanticLabel,
    required this.actionIcon,
    required this.onAction,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.scrollController,
    this.loadingMore = false,
    this.loadMoreError,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<DummyProfile> profiles;
  final String emptyTitle;
  final String emptyMessage;
  final String actionLabel;
  final String Function(DummyProfile profile) actionSemanticLabel;
  final IconData actionIcon;
  final ValueChanged<DummyProfile> onAction;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final ScrollController? scrollController;
  final bool loadingMore;
  final String? loadMoreError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AmoraAppBar(
        title: title,
        onBack: () => Navigator.of(context).maybePop(),
        maxContentWidth: 720,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: profiles.isEmpty
                ? _ManagedProfilesEmptyState(
                    key: ValueKey('managed-empty-$title'),
                    icon: icon,
                    title: emptyTitle,
                    message: emptyMessage,
                    actionLabel: emptyActionLabel,
                    onAction: onEmptyAction,
                  )
                : ListView(
                    controller: scrollController,
                    key: ValueKey(
                      'managed-$title-${profiles.map((profile) => profile.id).join('-')}',
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AmoraSpacing.space20,
                      AmoraSpacing.space16,
                      AmoraSpacing.space20,
                      AmoraSpacing.space32,
                    ),
                    children: [
                      Text(title, style: AmoraTextStyles.headlineLarge),
                      const SizedBox(height: AmoraSpacing.space8),
                      Text(
                        subtitle,
                        style: AmoraTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space20),
                      for (final profile in profiles) ...[
                        ManagedProfileCard(
                          profile: profile,
                          actionLabel: actionLabel,
                          actionSemanticLabel: actionSemanticLabel(profile),
                          actionIcon: actionIcon,
                          onAction: () => onAction(profile),
                        ),
                        const SizedBox(height: AmoraSpacing.space12),
                      ],
                      if (loadingMore)
                        const Padding(
                          padding: EdgeInsets.all(AmoraSpacing.space16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (loadMoreError != null && onRetry != null)
                        Padding(
                          padding: const EdgeInsets.all(AmoraSpacing.space12),
                          child: TextButton(
                            onPressed: onRetry,
                            child: Text('$loadMoreError\nTry again'),
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

class ManagedProfileCard extends StatelessWidget {
  const ManagedProfileCard({
    super.key,
    required this.profile,
    required this.actionLabel,
    required this.actionSemanticLabel,
    required this.actionIcon,
    required this.onAction,
    this.onOpen,
  });

  final DummyProfile profile;
  final String actionLabel;
  final String actionSemanticLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${profile.name}, $actionSemanticLabel available',
      child: PremiumCard(
        key: key ?? ValueKey('managed-profile-${profile.id}'),
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: AmoraRadius.card,
          onTap:
              onOpen ??
              () => Navigator.of(
                context,
              ).pushNamed(ProfileDetailScreen.routeName, arguments: profile),
          child: Padding(
            padding: const EdgeInsets.all(AmoraSpacing.space12),
            child: Row(
              children: [
                AmoraProfileImage(
                  imageUrl: profile.imageUrl,
                  assetPath: profile.fallbackAsset,
                  initials: profile.initials,
                  width: 64,
                  height: 72,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(18),
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${profile.name}, ${profile.age}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AmoraTextStyles.titleMedium,
                            ),
                          ),
                          if (resolveAmoraaIdentityBadge(
                                isAadhaarVerified: profile.verified,
                                isPremium: profile.premium,
                              ) !=
                              AmoraaIdentityBadgeType.none) ...[
                            const SizedBox(width: AmoraSpacing.space8),
                            AmoraaIdentityBadge(
                              isAadhaarVerified: profile.verified,
                              isPremium: profile.premium,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AmoraSpacing.space4),
                      Text(
                        '${profile.profession} · ${profile.city}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('$actionLabel-${profile.id}'),
                  tooltip: actionSemanticLabel,
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagedProfilesEmptyState extends StatelessWidget {
  const _ManagedProfilesEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: PremiumCard(
          radius: AmoraRadius.extraLarge,
          padding: const EdgeInsets.all(AmoraSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AmoraTextStyles.titleLarge,
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AmoraSpacing.space16),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
