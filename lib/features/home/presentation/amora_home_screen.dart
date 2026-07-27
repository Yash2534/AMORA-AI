import 'dart:math' as math;

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_ai_assistant.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_banner_card.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/profile_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/section_header.dart';
import 'package:amora_ai/features/ai_coach/presentation/ai_dating_coach_screen.dart';
import 'package:amora_ai/features/auth/presentation/compatibility_onboarding_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/commerce/presentation/send_gift_screen.dart';
import 'package:amora_ai/features/date_spots/presentation/date_spots_map_screen.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/messaging/presentation/match_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_setup_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/roadmap/presentation/phase23_premium_screens.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class AmoraHomeScreen extends StatefulWidget {
  const AmoraHomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<AmoraHomeScreen> createState() => _AmoraHomeScreenState();
}

class _AmoraHomeScreenState extends State<AmoraHomeScreen> {
  int _heroIndex = 0;
  AmoraProfileCardData? _lastProfile;

  AmoraProfileCardData get _heroProfile =>
      _heroProfiles[_heroIndex % _heroProfiles.length];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AmoraSession.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return _buildScaffold(context, isLoggedIn);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, bool isLoggedIn) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isGuest = !isLoggedIn;
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = MediaQuery.sizeOf(context).height;
                final padding = width < 390 ? 18.0 : 22.0;
                final heroHeight = math
                    .min(height * .70, width * 1.52)
                    .clamp(500.0, 640.0);

                return Stack(
                  children: [
                    CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            AmoraSpacing.space24,
                            padding,
                            FloatingBottomNav.contentBottomPadding +
                                bottomInset,
                          ),
                          sliver: SliverList.list(
                            children: [
                              FadeUp(
                                child: _HomeTopBar(
                                  user: _currentUser,
                                  isGuest: isGuest,
                                ),
                              ),
                              if (!isGuest) ...[
                                const SizedBox(height: AmoraSpacing.space20),
                                FadeUp(
                                  delay: const Duration(milliseconds: 20),
                                  child: const _ProfileCompletionCard(),
                                ),
                              ] else ...[
                                const SizedBox(height: AmoraSpacing.space20),
                                FadeUp(
                                  delay: const Duration(milliseconds: 20),
                                  child: const _ExploreBanner(),
                                ),
                              ],
                              const SizedBox(height: AmoraSpacing.space20),
                              FadeUp(
                                delay: const Duration(milliseconds: 40),
                                child: _QuickActionsRow(
                                  onFilters: () => Navigator.of(
                                    context,
                                  ).pushNamed(AdvancedFiltersScreen.routeName),
                                  onNearby: () => _scrollSnack(
                                    context,
                                    'Nearby profiles are ready below',
                                  ),
                                  onChats: () => isGuest
                                      ? _requireAuth(
                                          () => Navigator.of(
                                            context,
                                          ).pushNamed(ChatListScreen.routeName),
                                        )
                                      : Navigator.of(
                                          context,
                                        ).pushNamed(ChatListScreen.routeName),
                                  onEvents: () => Navigator.of(
                                    context,
                                  ).pushNamed(EventsScreen.routeName),
                                  onProfile: () => isGuest
                                      ? _requireAuth(
                                          () => Navigator.of(
                                            context,
                                          ).pushNamed(ProfileScreen.routeName),
                                        )
                                      : Navigator.of(
                                          context,
                                        ).pushNamed(ProfileScreen.routeName),
                                ),
                              ),
                              const SizedBox(height: AmoraSpacing.space20),
                              FadeUp(
                                delay: const Duration(milliseconds: 80),
                                child: _HeroMatchCard(
                                  profile: _heroProfile,
                                  height: heroHeight,
                                  onOpen: () =>
                                      _openProfile(context, _heroProfile),
                                  onLike: () => isGuest
                                      ? _requireAuth(
                                          () => _advanceHero(
                                            'Profile liked successfully',
                                          ),
                                        )
                                      : _advanceHero(
                                          'AMORA noted the spark with ${_heroProfile.name.split(' ').first}',
                                        ),
                                  onPass: () =>
                                      _advanceHero('Showing another profile'),
                                  onGift: () => isGuest
                                      ? _requireAuth(
                                          () => Navigator.of(
                                            context,
                                          ).pushNamed(SendGiftScreen.routeName),
                                        )
                                      : Navigator.of(
                                          context,
                                        ).pushNamed(SendGiftScreen.routeName),
                                  onChat: () => isGuest
                                      ? _requireAuth(
                                          () => Navigator.of(context).pushNamed(
                                            ChatDetailScreen.routeName,
                                          ),
                                        )
                                      : Navigator.of(
                                          context,
                                        ).pushNamed(ChatDetailScreen.routeName),
                                  onMatch: () => isGuest
                                      ? _requireAuth(
                                          () => Navigator.of(context).pushNamed(
                                            MatchScreen.routeName,
                                            arguments: _heroProfile,
                                          ),
                                        )
                                      : Navigator.of(context).pushNamed(
                                          MatchScreen.routeName,
                                          arguments: _heroProfile,
                                        ),
                                  onUndo: _undoHero,
                                ),
                              ),
                              if (isGuest) ...[
                                const SizedBox(height: AmoraSpacing.space20),
                                _ExploreAiPreview(
                                  onUnlock: () => _requireAuth(
                                    () => Navigator.of(
                                      context,
                                    ).pushNamed(AiDatingCoachScreen.routeName),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AmoraSpacing.space32),
                              _DailyPicksRail(
                                profiles: _dailyPicks,
                                onOpen: (profile) =>
                                    _openProfile(context, profile),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              _AvailableNowRail(
                                profiles: _nearbyProfiles,
                                onOpen: (profile) =>
                                    _openProfile(context, profile),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              _RecentlyActiveRail(
                                profiles: _recentlyActive,
                                onOpen: (profile) =>
                                    _openProfile(context, profile),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              _TrendingProfilesRail(
                                profiles: _trendingProfiles,
                                onOpen: (profile) =>
                                    _openProfile(context, profile),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              _WeekendEventsRail(
                                events: ImageRepository.events.take(8).toList(),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              _DateSpotsRail(
                                venues: ImageRepository.venues.take(6).toList(),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              _AiCoachPanel(
                                profile: _heroProfile,
                                onOpenCoach: () => isGuest
                                    ? _requireAuth(
                                        () => Navigator.of(context).pushNamed(
                                          AiDatingCoachScreen.routeName,
                                        ),
                                      )
                                    : Navigator.of(context).pushNamed(
                                        AiDatingCoachScreen.routeName,
                                      ),
                              ),
                              const SizedBox(height: AmoraSpacing.space24),
                              PremiumBannerCard(
                                title: 'AI relationship ecosystem',
                                subtitle:
                                    'Explore learning mode, travel, question decks, matchmaker, events, and relationship prediction.',
                                cta: 'Open Modules',
                                badge: 'Phase 2+3',
                                icon: Icons.auto_awesome_rounded,
                                gradient: const [
                                  AppColors.primaryPurple,
                                  AppColors.primaryPurple,
                                  AppColors.primaryPurple,
                                ],
                                onTap: () => isGuest
                                    ? _requireAuth(
                                        () => Navigator.of(context).pushNamed(
                                          RelationshipEcosystemHubScreen
                                              .routeName,
                                        ),
                                      )
                                    : Navigator.of(context).pushNamed(
                                        RelationshipEcosystemHubScreen
                                            .routeName,
                                      ),
                              ),
                              const SizedBox(height: 26),
                              PremiumBannerCard(
                                title: 'Gold unlocks intent-first dating',
                                subtitle:
                                    'See deeper compatibility, priority likes, and AI-crafted first messages.',
                                cta: 'Explore Gold',
                                badge: 'Premium',
                                icon: Icons.workspace_premium_rounded,
                                gradient: const [
                                  AppColors.deepWine,
                                  AppColors.deepWine,
                                  AppColors.deepWine,
                                ],
                                onTap: () => isGuest
                                    ? _requireAuth(
                                        () => Navigator.of(context).pushNamed(
                                          SubscriptionScreen.routeName,
                                        ),
                                      )
                                    : Navigator.of(
                                        context,
                                      ).pushNamed(SubscriptionScreen.routeName),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          FloatingBottomNav.bottomMargin + bottomInset,
                        ),
                        child: const FloatingBottomNav(
                          activeTab: AmoraNavTab.discover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 22,
                      bottom:
                          FloatingBottomNav.assistantBottomPadding +
                          bottomInset,
                      child: const FloatingAiAssistant(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static void _openProfile(BuildContext context, AmoraProfileCardData profile) {
    Navigator.of(
      context,
    ).pushNamed(ProfileDetailScreen.routeName, arguments: profile);
  }

  Future<void> _requireAuth(VoidCallback action) {
    return AmoraSession.requireAuth(context: context, onAuthenticated: action);
  }

  void _advanceHero(String message) {
    setState(() {
      _lastProfile = _heroProfile;
      _heroIndex = (_heroIndex + 1) % _heroProfiles.length;
    });
    _scrollSnack(context, message);
  }

  void _undoHero() {
    if (_lastProfile == null) {
      _scrollSnack(context, 'No recent profile to rewind');
      return;
    }

    setState(() {
      final index = _heroProfiles.indexOf(_lastProfile!);
      if (index >= 0) _heroIndex = index;
      _lastProfile = null;
    });
    _scrollSnack(context, 'Last profile restored');
  }

  static void _scrollSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.user, required this.isGuest});

  final DummyProfile user;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final repository = LocalProfileRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final profile = repository.profile;
        return Row(
          children: [
            _RoundAvatar(
              imageUrl: isGuest ? user.imageUrl : profile.primaryPhoto,
              fallbackAsset: isGuest
                  ? user.fallbackAsset
                  : profile.primaryPhoto,
              initials: isGuest
                  ? user.initials
                  : AppImages.initialsForName(profile.name),
              size: AmoraSpacing.minimumTouchTarget,
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest
                        ? 'Good Evening'
                        : 'Hi ${profile.name.split(' ').first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.headlineLarge.copyWith(
                      color: AppColors.deepWine,
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space4),
                  Text(
                    '${profile.location} matches with real intent',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AmoraSpacing.space12),
            _IconBubble(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => Navigator.of(context).pushNamed('/notifications'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onFilters,
    required this.onNearby,
    required this.onChats,
    required this.onEvents,
    required this.onProfile,
  });

  final VoidCallback onFilters;
  final VoidCallback onNearby;
  final VoidCallback onChats;
  final VoidCallback onEvents;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(Icons.tune_rounded, 'Filters', onFilters),
      _QuickAction(Icons.near_me_rounded, 'Nearby', onNearby),
      _QuickAction(Icons.chat_bubble_outline_rounded, 'Chats', onChats),
      _QuickAction(Icons.event_available_rounded, 'Events', onEvents),
      _QuickAction(Icons.person_outline_rounded, 'Profile', onProfile),
    ];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AmoraSpacing.space12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionChip(action: action);
        },
      ),
    );
  }
}

class _ExploreBanner extends StatelessWidget {
  const _ExploreBanner();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      color: AppColors.deepWine,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Row(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            color: AppColors.premiumGold,
            size: AmoraIconSizes.large,
          ),
          const SizedBox(width: AmoraSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore first',
                  style: AmoraTextStyles.titleLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  'Browse profiles, photos, interests, and AI previews before signing in.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.background,
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

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard();

  @override
  Widget build(BuildContext context) {
    final repository = LocalProfileRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final strength = repository.profile.completionPercent;
        final tasks = [
          _CompletionTask(
            'Add Photos',
            Icons.add_a_photo_rounded,
            strength >= 40,
            () => Navigator.of(context).pushNamed(PhotoManagerScreen.routeName),
          ),
          _CompletionTask(
            'Basic Information',
            Icons.badge_outlined,
            strength >= 60,
            () => Navigator.of(context).pushNamed(ProfileSetupScreen.routeName),
          ),
          _CompletionTask(
            'Interests',
            Icons.interests_rounded,
            strength >= 60,
            () => Navigator.of(context).pushNamed(ProfileSetupScreen.routeName),
          ),
          _CompletionTask(
            'AI Questions',
            Icons.psychology_alt_rounded,
            strength >= 80,
            () => Navigator.of(
              context,
            ).pushNamed(CompatibilityOnboardingScreen.routeName),
          ),
          _CompletionTask(
            'Verification',
            Icons.verified_user_rounded,
            strength >= 100,
            () => Navigator.of(
              context,
            ).pushNamed(KycVerificationScreen.routeName),
          ),
        ];

        return PremiumCard(
          radius: AmoraRadius.extraLarge,
          padding: const EdgeInsets.all(AmoraSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: Text(
                      'Profile Strength',
                      style: AmoraTextStyles.titleLarge.copyWith(
                        color: AppColors.deepWine,
                      ),
                    ),
                  ),
                  Text(
                    '$strength%',
                    style: AmoraTextStyles.titleLarge.copyWith(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AmoraSpacing.space12),
              ClipRRect(
                borderRadius: AmoraRadius.pillBorder,
                child: LinearProgressIndicator(
                  value: strength / 100,
                  minHeight: 9,
                  color: AppColors.active,
                  backgroundColor: AppColors.lavenderBackground,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                'Complete your profile to unlock better matches.',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              Wrap(
                spacing: AmoraSpacing.space8,
                runSpacing: AmoraSpacing.space8,
                children: [
                  for (final task in tasks) _ProfileTaskChip(task: task),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTaskChip extends StatelessWidget {
  const _ProfileTaskChip({required this.task});

  final _CompletionTask task;

  @override
  Widget build(BuildContext context) {
    return AmoraFilterChip(
      label: task.label,
      selected: task.done,
      icon: task.done ? Icons.check_circle_rounded : task.icon,
      onSelected: (_) => task.onTap(),
    );
  }
}

class _CompletionTask {
  const _CompletionTask(this.label, this.icon, this.done, this.onTap);

  final String label;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;
}

class _ExploreAiPreview extends StatelessWidget {
  const _ExploreAiPreview({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUnlock,
      borderRadius: AmoraRadius.card,
      child: PremiumCard(
        radius: AmoraRadius.extraLarge,
        padding: const EdgeInsets.all(AmoraSpacing.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.blur_on_rounded,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Text(
                    'AI Match Preview',
                    style: AmoraTextStyles.titleLarge.copyWith(
                      color: AppColors.deepWine,
                    ),
                  ),
                ),
                const Icon(Icons.lock_rounded, color: AppColors.textGray),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space16),
            ClipRRect(
              borderRadius: AmoraRadius.button,
              child: Stack(
                children: [
                  LinearProgressIndicator(
                    value: .92,
                    minHeight: 48,
                    color: AppColors.primaryRose.withValues(alpha: .34),
                    backgroundColor: AppColors.lavenderBackground,
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        'Compatibility report unlocks after login',
                        style: AmoraTextStyles.labelLarge.copyWith(
                          color: AppColors.deepWine,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMatchCard extends StatelessWidget {
  const _HeroMatchCard({
    required this.profile,
    required this.height,
    required this.onOpen,
    required this.onLike,
    required this.onPass,
    required this.onGift,
    required this.onChat,
    required this.onMatch,
    required this.onUndo,
  });

  final AmoraProfileCardData profile;
  final double height;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onGift;
  final VoidCallback onChat;
  final VoidCallback onMatch;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Best match ${profile.name}, ${profile.score}% AI match',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
              boxShadow: AmoraShadows.floating,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AmoraProfileImage(
                    imageUrl: profile.imageUrl,
                    assetPath:
                        profile.fallbackAsset ?? AppImages.fallbackProfile,
                    initials:
                        profile.initials ??
                        AppImages.initialsForName(profile.name),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.transparent,
                          AppColors.transparent,
                          AppColors.text,
                        ],
                        stops: [0, .52, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AmoraSpacing.space16,
                    left: AmoraSpacing.space16,
                    right: AmoraSpacing.space16,
                    child: Wrap(
                      spacing: AmoraSpacing.space8,
                      runSpacing: AmoraSpacing.space8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _SolidOverlayBadge(
                          icon: Icons.auto_awesome_rounded,
                          label: '${profile.score}% AI Match',
                          strong: true,
                        ),
                        if (profile.isVerified)
                          const _SolidOverlayBadge(
                            icon: Icons.verified_rounded,
                            label: 'Verified',
                          ),
                        if (profile.isOnline)
                          const _SolidOverlayBadge(
                            icon: Icons.circle_rounded,
                            label: 'Online now',
                            iconColor: AppColors.successGreen,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: AmoraSpacing.space20,
                    right: AmoraSpacing.space20,
                    bottom: 156,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profile.name}, ${profile.age}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (MediaQuery.sizeOf(context).width < 360
                                      ? AmoraTextStyles.headlineLarge
                                      : AmoraTextStyles.displaySmall)
                                  .copyWith(color: AppColors.surface),
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Text(
                          '${profile.profession ?? profile.city} - ${profile.distance} away',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AmoraTextStyles.bodyLarge.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space12),
                        Wrap(
                          spacing: AmoraSpacing.space8,
                          runSpacing: AmoraSpacing.space8,
                          children: [
                            _SolidOverlayPill(text: profile.intent),
                            if (profile.interests.isNotEmpty)
                              _SolidOverlayPill(text: profile.interests.first),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: AmoraSpacing.space16,
                    right: AmoraSpacing.space16,
                    bottom: AmoraSpacing.space20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                        border: Border.all(color: AppColors.borderGray),
                        boxShadow: AmoraShadows.level2,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AmoraSpacing.space12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 262,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _CircleAction(
                                  icon: Icons.undo_rounded,
                                  label: 'Undo',
                                  onTap: onUndo,
                                ),
                                _CircleAction(
                                  icon: Icons.close_rounded,
                                  label: 'Next',
                                  onTap: onPass,
                                ),
                                _CircleAction(
                                  icon: Icons.favorite_rounded,
                                  label: 'Match',
                                  emphasis: true,
                                  onTap: onMatch,
                                ),
                                _CircleAction(
                                  icon: Icons.card_giftcard_rounded,
                                  label: 'Gift',
                                  onTap: onGift,
                                ),
                                _CircleAction(
                                  icon: Icons.chat_bubble_rounded,
                                  label: 'Chat',
                                  onTap: onChat,
                                ),
                              ],
                            ),
                          ),
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

class _DailyPicksRail extends StatelessWidget {
  const _DailyPicksRail({required this.profiles, required this.onOpen});

  final List<AmoraProfileCardData> profiles;
  final ValueChanged<AmoraProfileCardData> onOpen;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Daily Picks',
      subtitle: 'Curated profiles ranked by compatibility, trust, and intent.',
      child: SizedBox(
        height: 270,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return SizedBox(
              width: 176,
              child: ProfileCard(
                profile: profile,
                compact: true,
                onTap: () => onOpen(profile),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvailableNowRail extends StatelessWidget {
  const _AvailableNowRail({required this.profiles, required this.onOpen});

  final List<AmoraProfileCardData> profiles;
  final ValueChanged<AmoraProfileCardData> onOpen;

  @override
  Widget build(BuildContext context) {
    final windows = ['Morning', 'Afternoon', 'Evening', 'Weekend'];
    return _SectionShell(
      title: 'Available Near You',
      subtitle: 'People open to meeting soon, filtered by time and distance.',
      child: SizedBox(
        height: 162,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return _AvailabilityCard(
              profile: profile,
              window: windows[index % windows.length],
              onTap: () => onOpen(profile),
            );
          },
        ),
      ),
    );
  }
}

class _RecentlyActiveRail extends StatelessWidget {
  const _RecentlyActiveRail({required this.profiles, required this.onOpen});

  final List<AmoraProfileCardData> profiles;
  final ValueChanged<AmoraProfileCardData> onOpen;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Recently Active',
      subtitle: 'Premium members who reply with clarity.',
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return _ActiveAvatar(
              profile: profile,
              label: index.isEven ? 'Now' : '${index + 2}m',
              onTap: () => onOpen(profile),
            );
          },
        ),
      ),
    );
  }
}

class _TrendingProfilesRail extends StatelessWidget {
  const _TrendingProfilesRail({required this.profiles, required this.onOpen});

  final List<AmoraProfileCardData> profiles;
  final ValueChanged<AmoraProfileCardData> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final cardWidth = (constraints.maxWidth * .46).clamp(148.0, 188.0);
        final cardHeight = textScale > 1.2 ? 270.0 : 250.0;
        return _SectionShell(
          title: 'Trending Profiles',
          subtitle:
              'High-signal profiles getting thoughtful attention this week.',
          child: SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: profiles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 360 + index * 45),
                  tween: Tween(begin: .96, end: 1),
                  curve: AmoraMotion.curve,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: SizedBox(
                    key: ValueKey('trending-${profile.name}'),
                    width: cardWidth,
                    child: ProfileCard(
                      profile: profile,
                      compact: true,
                      onTap: () => onOpen(profile),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WeekendEventsRail extends StatelessWidget {
  const _WeekendEventsRail({required this.events});

  final List<EventImageData> events;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Weekend Events',
      subtitle: 'Curated offline spaces for safer first meetings.',
      child: SizedBox(
        height: 214,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventBanner(event: event);
          },
        ),
      ),
    );
  }
}

class _DateSpotsRail extends StatelessWidget {
  const _DateSpotsRail({required this.venues});

  final List<VenueImageData> venues;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Date Spots',
      subtitle: 'Luxury cafes, restaurants, rooftops, and quieter corners.',
      actionLabel: 'Map',
      onAction: () =>
          Navigator.of(context).pushNamed(DateSpotsMapScreen.routeName),
      child: SizedBox(
        height: 178,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: venues.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final venue = venues[index];
            return _VenueCard(venue: venue);
          },
        ),
      ),
    );
  }
}

class _AiCoachPanel extends StatelessWidget {
  const _AiCoachPanel({required this.profile, required this.onOpenCoach});

  final AmoraProfileCardData profile;
  final VoidCallback onOpenCoach;

  @override
  Widget build(BuildContext context) {
    final interest = profile.interests.isEmpty
        ? 'coffee'
        : profile.interests.first;
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AmoraRadius.lg),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach',
                  style: AmoraTextStyles.titleLarge.copyWith(
                    color: AppColors.deepWine,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Text(
                  'Daily tip: ask ${profile.name.split(' ').first} about ${interest.toLowerCase()} and suggest a simple plan, not a vague hello.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppPrimaryButton(
                    label: 'Coach my opener',
                    fullWidth: false,
                    size: AmoraButtonSize.compact,
                    onPressed: onOpenCoach,
                    icon: Icons.auto_awesome_rounded,
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

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          trailing: actionLabel == null
              ? null
              : AppPrimaryButton(
                  label: actionLabel!,
                  variant: AppPrimaryButtonVariant.text,
                  size: AmoraButtonSize.compact,
                  fullWidth: false,
                  onPressed: onAction,
                  icon: Icons.arrow_forward_rounded,
                ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        child,
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.label,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderGray),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepWine.withValues(alpha: .08),
                  blurRadius: 18,
                  spreadRadius: -10,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: AppColors.primaryPurple, size: 22),
                  const SizedBox(height: 5),
                  FittedBox(
                    child: Text(
                      action.label,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.deepWine,
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

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.profile,
    required this.window,
    required this.onTap,
  });

  final AmoraProfileCardData profile;
  final String window;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 250,
        child: PremiumCard(
          radius: 28,
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            children: [
              _RoundAvatar(
                imageUrl: profile.imageUrl,
                fallbackAsset:
                    profile.fallbackAsset ?? AppImages.fallbackProfile,
                initials:
                    profile.initials ?? AppImages.initialsForName(profile.name),
                size: 78,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TinyStatus(text: window),
                    const SizedBox(height: 8),
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.titleMedium.copyWith(
                        color: AppColors.deepWine,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.distance} - ${profile.intent}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.textGray,
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

class _ActiveAvatar extends StatelessWidget {
  const _ActiveAvatar({
    required this.profile,
    required this.label,
    required this.onTap,
  });

  final AmoraProfileCardData profile;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            Stack(
              children: [
                _RoundAvatar(
                  imageUrl: profile.imageUrl,
                  fallbackAsset:
                      profile.fallbackAsset ?? AppImages.fallbackProfile,
                  initials:
                      profile.initials ??
                      AppImages.initialsForName(profile.name),
                  size: 68,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              profile.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.deepWine,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelSmall.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.event});

  final EventImageData event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/event-detail'),
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 286,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PremiumImage.asset(
                assetPath: event.imageUrl,
                fallbackAsset: event.fallbackAsset,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(28),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.transparent,
                      AppColors.transparent,
                      AppColors.text,
                    ],
                    stops: [0, .48, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SolidOverlayPill(text: event.countdown),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.titleLarge.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${event.city} - ${event.ticketCount} seats left',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.surface,
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

class _VenueCard extends StatelessWidget {
  const _VenueCard({required this.venue});

  final VenueImageData venue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed(DateSpotsMapScreen.routeName),
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: 232,
        child: PremiumCard(
          radius: 26,
          padding: const EdgeInsets.all(10),
          color: AppColors.surface,
          child: Row(
            children: [
              PremiumImage.asset(
                assetPath: venue.imageUrl,
                fallbackAsset: venue.fallbackAsset,
                width: 86,
                height: 132,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TinyStatus(text: venue.category),
                    const SizedBox(height: 8),
                    Text(
                      venue.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.titleMedium.copyWith(
                        color: AppColors.deepWine,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${venue.rating.toStringAsFixed(1)} star - ${venue.priceRange}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.textGray,
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

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: emphasis ? 62 : 50,
          height: emphasis ? 62 : 50,
          decoration: BoxDecoration(
            color: emphasis ? AppColors.primaryRose : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: emphasis ? AppColors.primaryRose : AppColors.borderGray,
            ),
            boxShadow: [
              BoxShadow(
                color: (emphasis ? AppColors.primaryRose : AppColors.deepWine)
                    .withValues(alpha: .20),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: emphasis ? AppColors.surface : AppColors.deepWine,
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon),
        color: AppColors.deepWine,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}

class _SolidOverlayBadge extends StatelessWidget {
  const _SolidOverlayBadge({
    required this.icon,
    required this.label,
    this.strong = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool strong;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: strong ? AppColors.primaryRose : AppColors.deepWine,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: strong ? AppColors.primaryRose : AppColors.deepWine,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor ?? AppColors.surface),
            const SizedBox(width: 6),
            Text(
              label,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidOverlayPill extends StatelessWidget {
  const _SolidOverlayPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.deepWine,
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: AppColors.deepWine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.labelMedium.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }
}

class _TinyStatus extends StatelessWidget {
  const _TinyStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: .10),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }
}

class _RoundAvatar extends StatelessWidget {
  const _RoundAvatar({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.initials,
    required this.size,
  });

  final String imageUrl;
  final String fallbackAsset;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: AmoraProfileImage(
          imageUrl: imageUrl,
          assetPath: fallbackAsset,
          initials: initials,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

List<AmoraProfileCardData> _uniqueProfileCards({
  required bool male,
  required int count,
  int skip = 0,
}) {
  final seen = <String>{};
  final cards = <AmoraProfileCardData>[];
  final source = ImageRepository.profiles.skip(skip);
  for (final profile in source) {
    if ((profile.gender == Gender.male) != male) continue;
    if (!seen.add(profile.imageUrl)) continue;
    cards.add(_toProfileCardData(profile));
    if (cards.length == count) break;
  }
  return cards;
}

final _heroProfiles = [
  ..._uniqueProfileCards(male: false, count: 4),
  ..._uniqueProfileCards(male: true, count: 4),
];

final _dailyPicks = [
  ..._uniqueProfileCards(male: false, count: 4, skip: 1),
  ..._uniqueProfileCards(male: true, count: 4, skip: 150),
];

final _nearbyProfiles = [
  ..._uniqueProfileCards(male: false, count: 4, skip: 8),
  ..._uniqueProfileCards(male: true, count: 4, skip: 154),
];

final _recentlyActive = [
  ..._uniqueProfileCards(male: false, count: 4, skip: 16),
  ..._uniqueProfileCards(male: true, count: 4, skip: 158),
];

final _trendingProfiles = [
  ..._uniqueProfileCards(male: false, count: 4, skip: 24),
  ..._uniqueProfileCards(male: true, count: 4, skip: 162),
];

AmoraProfileCardData _toProfileCardData(DummyProfile profile) {
  return AmoraProfileCardData(
    name: profile.name,
    age: profile.age,
    city: profile.city,
    distance: profile.distance,
    score: profile.score,
    intent: profile.intent,
    imageUrl: profile.imageUrl,
    fallbackAsset: profile.fallbackAsset,
    initials: profile.initials,
    profession: profile.profession,
    bio: profile.bio,
    interests: profile.interests,
    isOnline: profile.status.toLowerCase().contains('online'),
    isVerified: profile.verified,
  );
}

final _currentUser = ImageRepository.profileByName('Yash');
