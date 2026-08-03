import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';

class SavedProfilesScreen extends StatelessWidget {
  const SavedProfilesScreen({super.key, this.controller});

  static const routeName = '/saved-profiles';

  final ProfileRelationshipController? controller;

  @override
  Widget build(BuildContext context) {
    final source = controller ?? ProfileRelationshipController.instance;
    return AnimatedBuilder(
      animation: source,
      builder: (context, _) => ManagedProfilesScreen(
        title: 'Saved Profiles',
        subtitle: 'People you saved to revisit thoughtfully.',
        icon: Icons.bookmark_rounded,
        profiles: source.savedProfiles,
        emptyTitle: 'No saved profiles yet',
        emptyMessage: 'Profiles you save will appear here.',
        emptyActionLabel: 'Discover profiles',
        onEmptyAction: () =>
            Navigator.of(context).pushNamed(DiscoverScreen.routeName),
        actionLabel: 'Remove saved profile',
        actionIcon: Icons.bookmark_remove_rounded,
        onAction: (profile) => source.removeSaved(profile.id),
      ),
    );
  }
}

class BlockedProfilesScreen extends StatelessWidget {
  const BlockedProfilesScreen({super.key, this.controller});

  static const routeName = '/blocked-profiles';

  final ProfileRelationshipController? controller;

  @override
  Widget build(BuildContext context) {
    final source = controller ?? ProfileRelationshipController.instance;
    return AnimatedBuilder(
      animation: source,
      builder: (context, _) => ManagedProfilesScreen(
        title: 'Blocked Profiles',
        subtitle: 'Private controls for profiles you chose not to see.',
        icon: Icons.block_rounded,
        profiles: source.blockedProfiles,
        emptyTitle: 'No blocked profiles',
        emptyMessage: 'Profiles you block will appear here.',
        actionLabel: 'Unblock profile',
        actionIcon: Icons.lock_open_rounded,
        onAction: (profile) => source.unblockProfile(profile.id),
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
    required this.actionIcon,
    required this.onAction,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<DummyProfile> profiles;
  final String emptyTitle;
  final String emptyMessage;
  final String actionLabel;
  final IconData actionIcon;
  final ValueChanged<DummyProfile> onAction;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: profiles.isEmpty
              ? _ManagedProfilesEmptyState(
                  icon: icon,
                  title: emptyTitle,
                  message: emptyMessage,
                  actionLabel: emptyActionLabel,
                  onAction: onEmptyAction,
                )
              : ListView(
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
                        actionIcon: actionIcon,
                        onAction: () => onAction(profile),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                    ],
                  ],
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
    required this.actionIcon,
    required this.onAction,
    this.onOpen,
  });

  final DummyProfile profile;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${profile.name}, $actionLabel available',
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
                  tooltip: '$actionLabel ${profile.name}',
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
