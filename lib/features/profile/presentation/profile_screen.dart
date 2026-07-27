import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_setup_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/settings/presentation/settings_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showNavigation = true});

  final bool showNavigation;
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = LocalProfileRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showNavigation
          ? const FloatingBottomNav(activeTab: AmoraNavTab.profile)
          : null,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: CustomScrollView(
            key: const PageStorageKey('main-profile-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Profile',
                            style: AmoraTextStyles.screenTitle,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(SettingsScreen.routeName),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _IdentityCard(profile: profile),
                    const SizedBox(height: 16),
                    _CompletionCard(
                      percent: profile.completionPercent,
                      onComplete: () =>
                          _open(ProfileCompletionScreen.routeName),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Edit Profile',
                            icon: Icons.edit_rounded,
                            onPressed: () =>
                                _open(ProfileSetupScreen.routeName),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Preview',
                            icon: Icons.visibility_rounded,
                            variant: AppPrimaryButtonVariant.outlined,
                            onPressed: () =>
                                _open(ProfilePreviewScreen.routeName),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Your profile', style: AmoraTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    _InsightsCard(profile: profile),
                    const SizedBox(height: 16),
                    _ShortcutCard(
                      icon: Icons.shield_rounded,
                      title: 'Safety & support',
                      subtitle: 'Privacy, reporting and trusted guidance',
                      onTap: () => _open(ReportFlowScreen.routeName),
                    ),
                    const SizedBox(height: 12),
                    _MembershipCard(
                      onTap: () => _open(SubscriptionScreen.routeName),
                    ),
                    const SizedBox(height: 12),
                    _ShortcutCard(
                      icon: Icons.tune_rounded,
                      title: 'Settings',
                      subtitle: 'Preferences, account and accessibility',
                      onTap: () => _open(SettingsScreen.routeName),
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

  Future<void> _open(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) setState(() {});
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});
  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final image = PremiumAssetImage(
            imageUrl: profile.primaryPhoto,
            fallbackAsset: profile.primaryPhoto,
            initials: AppImages.initialsForName(profile.name),
            width: compact ? 88 : 108,
            height: compact ? 112 : 136,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(24),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.age == null
                    ? profile.name
                    : '${profile.name}, ${profile.age}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.headlineMedium,
              ),
              const SizedBox(height: 8),
              _Meta(icon: Icons.location_on_rounded, text: profile.location),
              _Meta(
                icon: Icons.favorite_rounded,
                text: profile.datingIntention,
              ),
              _Meta(icon: Icons.work_rounded, text: profile.profession),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: image),
                const SizedBox(height: 16),
                details,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: 18),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percent, required this.onComplete});
  final int percent;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile completion',
                  style: AmoraTextStyles.titleLarge,
                ),
              ),
              Text(
                '$percent%',
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: percent >= 100 ? 'Review profile' : 'Complete profile',
            variant: AppPrimaryButtonVariant.text,
            onPressed: onComplete,
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.profile});
  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.photo_library_rounded, 'Photos', '${profile.photos.length}/6'),
      (
        Icons.chat_bubble_rounded,
        'Prompts',
        '${profile.completedPromptCount}/3',
      ),
      (Icons.interests_rounded, 'Interests', '${profile.interests.length}/10'),
    ];
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ListTile(
              minTileHeight: 64,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.activeContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(items[index].$1, color: AppColors.primary),
              ),
              title: Text(items[index].$2),
              trailing: Text(
                items[index].$3,
                style: AmoraTextStyles.labelLarge.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
            if (index != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 76,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AmoraTextStyles.titleMedium),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.premiumContainer,
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 84,
        leading: const Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.onPremiumContainer,
        ),
        title: const Text('AMORA Membership'),
        subtitle: const Text('Review premium features and membership options.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
