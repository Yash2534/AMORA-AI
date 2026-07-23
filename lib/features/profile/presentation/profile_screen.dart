import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
<<<<<<< HEAD
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_setup_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
=======
import 'package:amora_ai/core/widgets/section_header.dart';
import 'package:amora_ai/features/insights/presentation/dating_recap_screen.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/bio_builder_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/monetization/presentation/liked_you_paywall_screen.dart';
import 'package:amora_ai/features/preferences/presentation/dealbreakers_screen.dart';
import 'package:amora_ai/features/roadmap/presentation/phase23_premium_screens.dart';
import 'package:amora_ai/features/roadmap/presentation/roadmap_feature_screens.dart';
>>>>>>> main
import 'package:amora_ai/features/settings/presentation/settings_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
<<<<<<< HEAD
=======
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
>>>>>>> main
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showNavigation = true});

  final bool showNavigation;
  static const routeName = '/profile';

  @override
<<<<<<< HEAD
  State<ProfileScreen> createState() => _ProfileScreenState();
=======
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightPinkBackground,
              AppColors.background,
              AppColors.lightPinkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = constraints.maxWidth < 380
                        ? AmoraSpacing.space16
                        : AmoraSpacing.space24;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        AmoraSpacing.space24,
                        padding,
                        FloatingBottomNav.contentBottomPadding,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHero(),
                          SizedBox(height: AmoraSpacing.space16),
                          _StatsGrid(),
                          SizedBox(height: AmoraSpacing.space16),
                          _BioCard(),
                          SizedBox(height: AmoraSpacing.space16),
                          _ProfileStudioCard(),
                          SizedBox(height: AmoraSpacing.space16),
                          _PremiumMembershipCard(),
                          SizedBox(height: AmoraSpacing.space16),
                          _DashboardCards(),
                          SizedBox(height: AmoraSpacing.space16),
                          _PromptsCard(),
                          SizedBox(height: AmoraSpacing.space16),
                          _QuickActionsCard(),
                          SizedBox(height: AmoraSpacing.space16),
                          _AccountSupportCard(),
                          SizedBox(height: AmoraSpacing.space16),
                          _LogoutCard(),
                        ],
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AmoraSpacing.space16,
                      AmoraSpacing.space0,
                      AmoraSpacing.space16,
                      FloatingBottomNav.bottomMargin,
                    ),
                    child: const FloatingBottomNav(
                      activeTab: AmoraNavTab.profile,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
>>>>>>> main
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
<<<<<<< HEAD
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
=======
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(
                        text: suffix,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: const [
        _StatCard(label: 'Matches', value: '42', icon: Icons.favorite_rounded),
        _StatCard(
          label: 'Likes',
          value: '128',
          icon: Icons.thumb_up_alt_rounded,
        ),
        _StatCard(label: 'Events', value: '5', icon: Icons.celebration_rounded),
        _StatCard(
          label: 'Visitors',
          value: '76',
          icon: Icons.visibility_rounded,
        ),
      ],
    );
  }
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: _MiniInsightCard(
                title: 'AI Insight',
                value: 'Profile warmth is up 18%',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MiniInsightCard(
                title: 'Membership',
                value: 'Gold active - VIP events unlocked',
                icon: Icons.workspace_premium_rounded,
              ),
            ),
          ],
        ),
      ],
>>>>>>> main
    );
  }
}

<<<<<<< HEAD
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
=======
class _PremiumMembershipCard extends StatelessWidget {
  const _PremiumMembershipCard();
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
<<<<<<< HEAD
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
=======
      color: AppColors.deepWine,
      borderColor: AppColors.deepWine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
>>>>>>> main
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

<<<<<<< HEAD
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
=======
class _StudioTool {
  const _StudioTool(this.title, this.subtitle, this.progress, this.icon);

  final String title;
  final String subtitle;
  final double progress;
  final IconData icon;
}

class _StudioToolTile extends StatelessWidget {
  const _StudioToolTile({required this.tool});

  final _StudioTool tool;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lavenderBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(tool.icon, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.title,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tool.subtitle,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: tool.progress,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('${tool.title} opened'))),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
>>>>>>> main

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

<<<<<<< HEAD
class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.onTap});
=======
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.softPink.withValues(alpha: .18),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w700,
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

class _BioCard extends StatelessWidget {
  const _BioCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'About ${_currentUserProfile.name.split(' ').first}',
            subtitle: 'Premium profile preview with relationship depth.',
          ),
          const SizedBox(height: 14),
          Text(
            _currentUserProfile.bio,
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.42,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          IntentChip(label: _currentUserProfile.intent, selected: true),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final interest in _currentUserProfile.interests)
                LifestyleChip(label: interest, selected: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptsCard extends StatelessWidget {
  const _PromptsCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Prompt Questions',
            subtitle: 'Written answers that help matches start better chats.',
          ),
          const SizedBox(height: 14),
          for (final prompt in _currentUserProfile.promptAnswers.entries) ...[
            _PromptCard(prompt: prompt.key, answer: prompt.value),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.answer});

  final String prompt;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.lavenderBackground.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prompt,
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              answer,
              style: const TextStyle(
                color: AppColors.textDark,
                height: 1.35,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Quick actions',
            subtitle: 'Profile, safety, and subscription tools.',
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Photo Manager',
            icon: Icons.photo_library_rounded,
            variant: AppPrimaryButtonVariant.outlined,
            onPressed: () =>
                Navigator.of(context).pushNamed(PhotoManagerScreen.routeName),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Edit Profile',
            icon: Icons.person_search_rounded,
            onPressed: () {
              Navigator.of(context).pushNamed(ProfileDetailScreen.routeName);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'Upgrade Plan',
                  icon: Icons.workspace_premium_rounded,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(SubscriptionScreen.routeName);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  onTap: () {
                    Navigator.of(context).pushNamed(SettingsScreen.routeName);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  label: 'Safety Center',
                  icon: Icons.verified_user_rounded,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(SafetyPrivacyScreen.routeName);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'Bio Builder',
                  icon: Icons.edit_note_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(BioBuilderScreen.routeName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  label: 'Dealbreakers',
                  icon: Icons.tune_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(DealbreakersScreen.routeName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'Liked You',
                  icon: Icons.favorite_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(LikedYouPaywallScreen.routeName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WideActionTile(
            label: 'Weekly Dating Recap',
            subtitle: 'Views, likes, chat quality, and match suggestions',
            icon: Icons.insights_rounded,
            onTap: () {
              Navigator.of(context).pushNamed(DatingRecapScreen.routeName);
            },
          ),
          const SizedBox(height: 10),
          _WideActionTile(
            label: 'AI Relationship Ecosystem',
            subtitle: 'Learning, travel, matchmaker, events, prediction',
            icon: Icons.auto_awesome_rounded,
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed(RelationshipEcosystemHubScreen.routeName);
            },
          ),
          const SizedBox(height: 10),
          _WideActionTile(
            label: 'Stories and Success',
            subtitle: '24-hour updates and premium testimonial examples',
            icon: Icons.auto_stories_rounded,
            onTap: () {
              Navigator.of(context).pushNamed(StoriesScreen.routeName);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'Notifications',
                  icon: Icons.notifications_rounded,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(NotificationsHubScreen.routeName);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountSupportCard extends StatelessWidget {
  const _AccountSupportCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Account',
            subtitle: 'Privacy, alerts, support, and AMORA policies.',
          ),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
          ),
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Privacy',
            onTap: () =>
                Navigator.of(context).pushNamed(SafetyPrivacyScreen.routeName),
          ),
          _AccountRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            onTap: () => Navigator.of(
              context,
            ).pushNamed(NotificationPreferencesScreen.routeName),
          ),
          _AccountRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () =>
                Navigator.of(context).pushNamed(FaqSupportScreen.routeName),
          ),
          _AccountRow(
            icon: Icons.policy_outlined,
            label: 'Terms & Policies',
            onTap: () => _showInfo(context, 'Terms & Policies'),
          ),
          _AccountRow(
            icon: Icons.info_outline_rounded,
            label: 'About AMORA',
            onTap: () => _showInfo(
              context,
              'AMORA AI is built for verified, intentional relationships.',
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
>>>>>>> main
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return PremiumCard(
      color: AppColors.premiumContainer,
      padding: EdgeInsets.zero,
      child: ListTile(
        minTileHeight: 84,
        leading: const Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.onPremiumContainer,
=======
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryPurple, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: 'Log Out',
      icon: AmoraIcons.logout,
      onPressed: () => _confirmLogout(context),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showAmoraDialog<bool>(
      context: context,
      title: 'Log out of AMORA?',
      message:
          'You can continue browsing in Explore Mode and sign in again whenever you are ready.',
      icon: AmoraIcons.logout,
      primaryLabel: 'Log out',
      secondaryLabel: 'Cancel',
      onPrimary: () => Navigator.of(context).pop(true),
      onSecondary: () => Navigator.of(context).pop(false),
    );

    if (shouldLogout != true || !context.mounted) return;

    AmoraSession.logOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/browse', (route) => false);
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryPurple),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideActionTile extends StatelessWidget {
  const _WideActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lavenderBackground,
              child: Icon(icon, color: AppColors.primaryPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
>>>>>>> main
        ),
        title: const Text('AMORA Membership'),
        subtitle: const Text('Review premium features and membership options.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
