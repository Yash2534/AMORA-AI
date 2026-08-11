import 'dart:async';
import 'dart:math' as math;

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_gradients.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_metrics.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_photo_gallery.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_attribute_icons.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:amora_ai/features/settings/presentation/likes_super_likes_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/subscription/domain/amoraa_membership_status.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
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
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    AmoraaMembershipStatus.listenable.addListener(_refresh);
    if (AuthService.instance.currentUser != null) {
      unawaited(_retryProfile());
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    AmoraaMembershipStatus.listenable.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    const bottomInset = FloatingBottomNav.contentSpacing;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showNavigation
          ? const FloatingBottomNav(activeTab: AmoraNavTab.profile)
          : null,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 1040,
          child: CustomScrollView(
            key: const PageStorageKey('main-profile-scroll'),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProfileHeaderDelegate(
                  extent: AmoraaMainPageHeader.sliverExtentFor(context),
                  onSettings: () => _open(ProfileSettingsScreen.routeName),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  AmoraaMainPageHeader.contentSpacing,
                  20,
                  bottomInset,
                ),
                sliver: SliverList.list(
                  children: [
                    if (_repository.lastSyncError != null) ...[
                      PremiumCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.errorRed,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_repository.lastSyncError!)),
                            TextButton(
                              onPressed: _refreshing ? null : _retryProfile,
                              child: Text(_refreshing ? 'Loading...' : 'Retry'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FadeUp(
                      child: ProfileHero(
                        profile: profile,
                        isAadhaarVerified: false,
                        isPremium: AmoraaMembershipStatus.isPremiumActive,
                        onEdit: () => _open(ProfileEditScreen.routeName),
                        onPreview: () => _open(ProfilePreviewScreen.routeName),
                        onComplete: () =>
                            _open(ProfileCompletionScreen.routeName),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ProfileAboutSection(profile: profile),
                    const SizedBox(height: 32),
                    ProfileSectionHeading(
                      key: const ValueKey('profile-photo-gallery-heading'),
                      icon: Icons.photo_camera_rounded,
                      title: 'Photo Gallery',
                      subtitle: 'The moments that tell your story.',
                    ),
                    const SizedBox(height: 12),
                    ProfilePhotoGallery(profile: profile),
                    const SizedBox(height: 32),
                    ProfileEditorialSections(
                      profile: profile,
                      zodiac: _zodiacFor(profile.birthdate),
                      onEditPrompt: () async {
                        await Navigator.of(context).pushNamed(
                          ProfileEditScreen.routeName,
                          arguments: ProfileFormFieldId.profilePrompt,
                        );
                        if (mounted) setState(() {});
                      },
                      onVerify: () => _open(KycVerificationScreen.routeName),
                      onSafety: () => _open(SafetyPrivacyScreen.routeName),
                      onViewPremium: () => _open(SubscriptionScreen.routeName),
                      onManagePremium: () =>
                          _open(SubscriptionScreen.manageRoute),
                      onLikesSuperLikes: () =>
                          _open(LikesSuperLikesScreen.routeName),
                      onSavedProfiles: () =>
                          _open(SavedProfilesScreen.routeName),
                      onBlockedProfiles: () =>
                          _open(BlockedProfilesScreen.routeName),
                      onSupport: () => _open(FaqSupportScreen.routeName),
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

  Future<void> _retryProfile() async {
    setState(() => _refreshing = true);
    try {
      await _repository.refreshFromServer();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _open(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) setState(() {});
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileHeaderDelegate({
    required this.extent,
    required this.onSettings,
  });

  final double extent;
  final VoidCallback onSettings;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmoraaMainPageHeader.pageHorizontalInset,
          AmoraaMainPageHeader.safeTopSpacing,
          AmoraaMainPageHeader.pageHorizontalInset,
          0,
        ),
        child: AmoraaMainPageHeader(
          title: 'My Dating Identity',
          subtitle: 'Your dating identity',
          actions: [
            AmoraaMainPageHeaderAction(
              key: const ValueKey('profile-settings-button'),
              tooltip: 'Profile settings',
              semanticLabel: 'Open profile settings',
              onPressed: onSettings,
              icon: Icons.settings_rounded,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent || oldDelegate.onSettings != onSettings;
  }
}

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.profile,
    required this.isAadhaarVerified,
    required this.isPremium,
    required this.onEdit,
    required this.onPreview,
    required this.onComplete,
  });

  final LocalProfileDraft profile;
  final bool isAadhaarVerified;
  final bool isPremium;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final photo = _ProfilePortrait(profile: profile);
        final identity = _HeroIdentity(
          profile: profile,
          isAadhaarVerified: isAadhaarVerified,
          isPremium: isPremium,
          onEdit: onEdit,
          onPreview: onPreview,
          onComplete: onComplete,
        );
        return PremiumCard(
          radius: 28,
          padding: const EdgeInsets.all(12),
          borderColor: AppColors.tertiary.withValues(alpha: .72),
          shadowOpacity: .08,
          child: wide
              ? SizedBox(
                  height: 488,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 10, child: photo),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          child: identity,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.min(470, constraints.maxWidth * 1.2),
                      ),
                      child: AspectRatio(aspectRatio: 4 / 5, child: photo),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: identity,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ProfilePortrait extends StatelessWidget {
  const _ProfilePortrait({required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    final photos = LocalProfileRepository.instance.currentPhotos;
    final primary =
        photos.where((photo) => photo.isPrimary).firstOrNull ??
        (photos.isEmpty
            ? ProfilePhotoViewData(
                id: 'profile-hero-fallback',
                source: profile.primaryPhoto,
                order: 0,
                isPrimary: true,
                uploadState: ProfilePhotoUploadState.bundled,
              )
            : photos.first);
    return Hero(
      tag: 'current-user-primary-photo',
      child: Semantics(
        image: true,
        label: 'Primary profile photo for ${profile.name}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: .86),
              width: 2,
            ),
            boxShadow: AmoraShadows.level2,
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AmoraaProfilePhotoView(
                photo: primary,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.1),
                borderRadius: BorderRadius.circular(20),
                semanticLabel: 'Primary profile photo for ${profile.name}',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class _HeroIdentity extends StatelessWidget {
  const _HeroIdentity({
    required this.profile,
    required this.isAadhaarVerified,
    required this.isPremium,
    required this.onEdit,
    required this.onPreview,
    required this.onComplete,
  });

  final LocalProfileDraft profile;
  final bool isAadhaarVerified;
  final bool isPremium;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final city = ProfileFormOptions.normalizeCity(profile.location);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.headlineLarge.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        if (resolveAmoraaIdentityBadge(
              isAadhaarVerified: isAadhaarVerified,
              isPremium: isPremium,
            ) !=
            AmoraaIdentityBadgeType.none) ...[
          const SizedBox(height: 8),
          AmoraaIdentityBadge(
            isAadhaarVerified: isAadhaarVerified,
            isPremium: isPremium,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          [
            if (profile.age != null) '${profile.age}',
            if (city.isNotEmpty) city,
          ].join('  •  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: AppColors.text.withValues(alpha: .70),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Relationship intention',
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.text.withValues(alpha: .58),
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroPill(
              icon: Icons.favorite_rounded,
              text: ProfileFormOptions.normalizeDatingIntention(
                profile.datingIntention,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ProfileCompletionCard(profile: profile, onComplete: onComplete),
        const SizedBox(height: 16),
        _HeroActions(onEdit: onEdit, onPreview: onPreview),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.onEdit, required this.onPreview});

  final VoidCallback onEdit;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final edit = AppPrimaryButton(
      label: 'Edit Profile',
      icon: Icons.edit_rounded,
      onPressed: onEdit,
    );
    final preview = AppPrimaryButton(
      label: 'Preview',
      icon: Icons.visibility_rounded,
      variant: AppPrimaryButtonVariant.outlined,
      onPressed: onPreview,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [edit, const SizedBox(height: 10), preview],
          );
        }
        return Row(
          children: [
            Expanded(child: edit),
            const SizedBox(width: 10),
            Expanded(child: preview),
          ],
        );
      },
    );
  }
}

class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    super.key,
    required this.profile,
    required this.onComplete,
  });

  final LocalProfileDraft profile;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final missingSections = <String>[
      if (profile.photos.length < 2) 'photos',
      if (profile.bio.trim().length < 40) 'bio',
      if (ProfileInterestPolicy.visibleCount(profile.interests) < 5)
        'interests',
      if (profile.completedPromptCount < 1) 'prompt',
      if ((profile.lifestyle['Height'] ?? '').trim().isEmpty) 'height',
      if ((profile.lifestyle['Languages'] ?? '').trim().isEmpty) 'languages',
      if ((profile.lifestyle['Religion'] ?? '').trim().isEmpty) 'religion',
    ];
    final completionPercent = profile.presentationCompletionPercent;

    return PremiumCard(
      key: const ValueKey('profile-completion-card'),
      radius: 22,
      padding: EdgeInsets.zero,
      color: AppColors.background,
      borderColor: AppColors.tertiary.withValues(alpha: .78),
      shadowOpacity: 0,
      child: Semantics(
        button: true,
        label: 'Complete profile, $completionPercent percent complete',
        child: InkWell(
          onTap: onComplete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _AnimatedProfileProgress(percent: completionPercent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Complete',
                        style: AmoraTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        missingSections.isEmpty
                            ? 'Your story is ready to be discovered.'
                            : 'Only ${missingSections.length} ${missingSections.length == 1 ? 'section' : 'sections'} remaining',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.bodySmall.copyWith(
                          color: AppColors.text.withValues(alpha: .66),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        missingSections.isEmpty
                            ? 'Review profile'
                            : 'Complete Profile',
                        style: AmoraTextStyles.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Kept temporarily for source compatibility with older golden fixtures.
// ignore: unused_element
class _LegacyProfileCompletionCard extends StatelessWidget {
  const _LegacyProfileCompletionCard({
    required this.profile,
    required this.onComplete,
  });

  final LocalProfileDraft profile;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (profile.photos.length < 2) 'Add another photo',
      if (profile.bio.trim().length < 40) 'Write a fuller introduction',
      if (ProfileInterestPolicy.visibleCount(profile.interests) < 5)
        'Add more interests',
      if (profile.completedPromptCount < 1) 'Complete a profile prompt',
      if ((profile.lifestyle['Height'] ?? '').trim().isEmpty) 'Add your height',
      if ((profile.lifestyle['Languages'] ?? '').trim().isEmpty)
        'Add languages',
      if ((profile.lifestyle['Religion'] ?? '').trim().isEmpty) 'Add religion',
      if (profile.lifestyle.isEmpty) 'Share a lifestyle detail',
    ];
    final completionPercent = profile.presentationCompletionPercent;
    final quality = completionPercent >= 90
        ? 'Excellent profile'
        : completionPercent >= 70
        ? 'Strong foundation'
        : 'Building your story';

    return PremiumCard(
      key: const ValueKey('profile-completion-card'),
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final progress = _AnimatedProfileProgress(percent: completionPercent);
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quality,
                style: AmoraTextStyles.titleLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                missing.isEmpty
                    ? 'Your profile story is ready to meet the community.'
                    : 'Still improve: ${missing.take(2).join(' · ')}',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.text.withValues(alpha: .68),
                ),
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: missing.isEmpty ? 'Review profile' : 'Complete profile',
                icon: Icons.auto_awesome_rounded,
                size: AmoraButtonSize.compact,
                onPressed: onComplete,
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: progress),
                const SizedBox(height: 16),
                copy,
              ],
            );
          }
          return Row(
            children: [
              progress,
              const SizedBox(width: 20),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedProfileProgress extends StatelessWidget {
  const _AnimatedProfileProgress({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Semantics(
          label: 'Profile completion ${(value * 100).round()} percent',
          child: CustomPaint(
            painter: _ProgressRingPainter(value),
            child: SizedBox.square(
              dimension: 68,
              child: Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: AmoraTextStyles.titleLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 8) / 2;
    final track = Paint()
      ..color = AppColors.tertiary.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final progress = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class ProfileAboutSection extends StatelessWidget {
  const ProfileAboutSection({super.key, required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionHeading(
          icon: Icons.favorite_outline_rounded,
          title: '❤️ About Me',
          subtitle: 'The heart behind the profile.',
        ),
        const SizedBox(height: 12),
        ProfileBioCard(bio: profile.bio),
      ],
    );
  }
}

class ProfileEditorialSections extends StatelessWidget {
  const ProfileEditorialSections({
    super.key,
    required this.profile,
    required this.zodiac,
    required this.onEditPrompt,
    required this.onVerify,
    required this.onSafety,
    required this.onViewPremium,
    required this.onManagePremium,
    required this.onLikesSuperLikes,
    required this.onSavedProfiles,
    required this.onBlockedProfiles,
    required this.onSupport,
  });

  final LocalProfileDraft profile;
  final String? zodiac;
  final VoidCallback onEditPrompt;
  final VoidCallback onVerify;
  final VoidCallback onSafety;
  final VoidCallback onViewPremium;
  final VoidCallback onManagePremium;
  final VoidCallback onLikesSuperLikes;
  final VoidCallback onSavedProfiles;
  final VoidCallback onBlockedProfiles;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[
      _ProfileSectionBlock(
        heading: ProfileSectionHeading(
          icon: Icons.badge_rounded,
          title: '💼 Profile',
          subtitle: 'The details that shape your story.',
        ),
        child: ProfileAboutCard(profile: profile, zodiac: zodiac),
      ),
      _ProfileSectionBlock(
        heading: ProfileSectionHeading(
          icon: Icons.interests_rounded,
          title: '🎯 Interests',
          subtitle: 'Easy places for a conversation to begin.',
        ),
        child: ProfileInterestsCard(interests: profile.interests),
      ),
      _ProfileSectionBlock(
        heading: ProfileSectionHeading(
          icon: Icons.auto_awesome_rounded,
          title: '🧳 Lifestyle',
          subtitle: 'A glimpse into how you live and recharge.',
        ),
        child: ProfilePersonalityCard(lifestyle: profile.lifestyle),
      ),
      _ProfileSectionBlock(
        heading: ProfileSectionHeading(
          icon: Icons.chat_bubble_outline_rounded,
          title: '💬 Profile prompts',
          subtitle: 'Thoughtful openings for a real conversation.',
        ),
        child: ProfilePromptsCard(profile: profile, onEdit: onEditPrompt),
      ),
      _ProfileSectionBlock(
        heading: const ProfileSectionHeading(
          icon: Icons.verified_user_rounded,
          title: 'Verification & trust',
          subtitle: 'Private controls that help keep dating safer.',
        ),
        child: VerificationTrustCard(onVerify: onVerify, onSafety: onSafety),
      ),
      _ProfileSectionBlock(
        heading: const ProfileSectionHeading(
          icon: Icons.workspace_premium_rounded,
          title: 'Premium membership',
          subtitle: 'More intention, with less noise.',
        ),
        child: PremiumMembershipCard(
          onViewPremium: onViewPremium,
          onManage: onManagePremium,
        ),
      ),
      _ProfileSectionBlock(
        heading: const ProfileSectionHeading(
          icon: Icons.grid_view_rounded,
          title: 'Quick Actions',
          subtitle: 'Shortcuts for your profile and privacy.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileQuickActions(
              onLikesSuperLikes: onLikesSuperLikes,
              onSavedProfiles: onSavedProfiles,
              onBlockedProfiles: onBlockedProfiles,
              onSupport: onSupport,
            ),
          ],
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 760;
        final width = useColumns
            ? (constraints.maxWidth - 24) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 24,
          runSpacing: 32,
          children: [
            for (var index = 0; index < blocks.length; index++)
              SizedBox(
                width: width,
                child: FadeUp(
                  duration: const Duration(milliseconds: 240),
                  offset: 8,
                  child: blocks[index],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileSectionBlock extends StatelessWidget {
  const _ProfileSectionBlock({required this.heading, required this.child});

  final Widget heading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [heading, const SizedBox(height: 12), child],
    );
  }
}

class ProfileSectionHeading extends StatelessWidget {
  const ProfileSectionHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: .76),
            ),
            boxShadow: AmoraShadows.level1,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AmoraTextStyles.titleLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.text.withValues(alpha: .62),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          SizedBox(
            height: 48,
            child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
      ],
    );
  }
}

class ProfileBioCard extends StatefulWidget {
  const ProfileBioCard({super.key, required this.bio});

  final String bio;

  @override
  State<ProfileBioCard> createState() => _ProfileBioCardState();
}

class _ProfileBioCardState extends State<ProfileBioCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.bio.trim();
    if (bio.isEmpty) {
      return const _ProfileEmptyCard(
        icon: Icons.notes_rounded,
        title: 'Your story starts here',
        description: 'Share a few words about what makes you feel most alive.',
      );
    }
    final canExpand = bio.characters.length > 150;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PremiumCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'In my own words',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Text(
              bio,
              maxLines: _expanded ? null : 4,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: AmoraTextStyles.bodyLarge.copyWith(
                height: 1.62,
                color: AppColors.text.withValues(alpha: .84),
              ),
            ),
          ),
          if (canExpand) ...[
            const SizedBox(height: 4),
            Semantics(
              button: true,
              label: _expanded ? 'Show less biography' : 'Read more biography',
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: Text(
                    _expanded ? 'Show Less' : 'Read More',
                    key: ValueKey(_expanded),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfilePromptsCard extends StatelessWidget {
  const ProfilePromptsCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final LocalProfileDraft profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final prompts = profile.prompts.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList(growable: false);
    if (prompts.isEmpty) {
      return const _ProfileEmptyCard(
        icon: Icons.add_comment_rounded,
        title: 'No prompts yet',
        description: 'Add one answer that makes it easy to start talking.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < prompts.length; index++) ...[
          PremiumCard(
            key: ValueKey('profile-prompt-$index'),
            radius: 24,
            padding: EdgeInsets.zero,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AmoraGradients.warmSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      prompts[index].key,
                      style: AmoraTextStyles.labelLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '“${prompts[index].value.trim()}”',
                      style: AmoraTextStyles.titleLarge.copyWith(
                        fontSize: 19,
                        height: 1.48,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (index != prompts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class ProfileAboutCard extends StatelessWidget {
  const ProfileAboutCard({
    super.key,
    required this.profile,
    required this.zodiac,
  });

  final LocalProfileDraft profile;
  final String? zodiac;

  @override
  Widget build(BuildContext context) {
    final values = <(IconData, String, String)>[
      (Icons.work_rounded, 'Occupation', profile.profession),
      if (profile.company.trim().isNotEmpty)
        (Icons.business_rounded, 'Company', profile.company),
      (
        Icons.school_rounded,
        'Education',
        ProfileFormOptions.normalizeEducation(profile.education),
      ),
      if ((profile.lifestyle['Height'] ?? '').trim().isNotEmpty)
        (Icons.straighten_rounded, 'Height', profile.lifestyle['Height']!),
      if ((profile.lifestyle['Languages'] ?? '').trim().isNotEmpty)
        (
          Icons.language_rounded,
          'Languages',
          ProfileFormOptions.parseLanguages(
            profile.lifestyle['Languages'],
          ).join(' • '),
        ),
      if ((profile.lifestyle['Religion'] ?? '').trim().isNotEmpty)
        (
          Icons.self_improvement_rounded,
          'Religion',
          ProfileFormOptions.normalizeReligion(profile.lifestyle['Religion']),
        ),
      (
        Icons.person_rounded,
        'Gender',
        ProfileFormOptions.normalizeGender(profile.gender),
      ),
      if (zodiac != null) (Icons.brightness_2_rounded, 'Zodiac', zodiac!),
    ];
    return ProfileInfoCard(items: values);
  }
}

class DatingIntentionsCard extends StatelessWidget {
  const DatingIntentionsCard({super.key, required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    final intention = ProfileFormOptions.normalizeDatingIntention(
      profile.datingIntention,
    );
    final description =
        ProfileFormOptions.datingIntentionDescriptions[intention] ?? '';
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intention.isEmpty ? 'Dating intention' : intention,
                  style: AmoraTextStyles.titleMedium,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(items[index].$1, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[index].$2,
                          style: AmoraTextStyles.bodySmall.copyWith(
                            color: AppColors.text.withValues(alpha: .56),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[index].$3,
                          style: AmoraTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: AppColors.primary.withValues(alpha: .07),
              ),
          ],
        ],
      ),
    );
  }
}

class ProfileInterestsCard extends StatelessWidget {
  const ProfileInterestsCard({super.key, required this.interests});

  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    final visibleInterests = ProfileInterestPolicy.visible(interests);
    if (visibleInterests.isEmpty) {
      return const _ProfileEmptyCard(
        icon: Icons.interests_rounded,
        title: 'No interests yet',
        description: 'Choose interests that make it easier to connect.',
      );
    }
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final interest in visibleInterests)
              Container(
                constraints: BoxConstraints(
                  minHeight: 36,
                  maxWidth: constraints.maxWidth,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: .28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        interest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.labelLarge,
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

class ProfilePersonalityCard extends StatelessWidget {
  const ProfilePersonalityCard({super.key, required this.lifestyle});

  final Map<String, String> lifestyle;

  @override
  Widget build(BuildContext context) {
    final icons = <String, IconData>{
      'Exercise': Icons.fitness_center_rounded,
      'Pets': Icons.pets_rounded,
      'Drinking': Icons.local_bar_rounded,
      'Sleep habits': Icons.bedtime_rounded,
      'Food preference': Icons.restaurant_rounded,
    };
    final normalized = ProfileFormOptions.normalizeLifestyleSelections(
      lifestyle,
    );
    final entries = normalized.entries
        .where(
          (entry) =>
              ProfileFormOptions.lifestyleOptions.containsKey(entry.key) &&
              entry.value.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (entries.isEmpty) {
      return const _ProfileEmptyCard(
        icon: Icons.psychology_alt_rounded,
        title: 'Keep this private or add a little more',
        description: 'Only the lifestyle details you choose appear here.',
      );
    }
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth >= 300
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in entries)
                SizedBox(
                  width: tileWidth,
                  child: _LifestyleTile(
                    icon: entry.key == 'Smoking'
                        ? ProfileAttributeIcons.smoking(entry.value)
                        : icons[entry.key] ?? Icons.auto_awesome_rounded,
                    label: entry.key,
                    value: entry.value,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LifestyleTile extends StatelessWidget {
  const _LifestyleTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .64)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 19),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelSmall.copyWith(
              color: AppColors.text.withValues(alpha: .58),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Kept temporarily for source compatibility with older golden fixtures.
// ignore: unused_element
class _LegacyProfilePersonalityCard extends StatelessWidget {
  const _LegacyProfilePersonalityCard({required this.lifestyle});

  final Map<String, String> lifestyle;

  @override
  Widget build(BuildContext context) {
    if (lifestyle.isEmpty) {
      return const _ProfileEmptyCard(
        icon: Icons.psychology_alt_rounded,
        title: 'Keep this private or add a little more',
        description: 'Only the personality details you choose are shown here.',
      );
    }
    final icons = <String, IconData>{
      'Exercise': Icons.fitness_center_rounded,
      'Pets': Icons.pets_rounded,
      'Drinking': Icons.local_bar_rounded,
      'Smoking': Icons.smoke_free_rounded,
      'Sleep habits': Icons.bedtime_rounded,
      'Food preference': Icons.restaurant_rounded,
    };
    return ProfileInfoCard(
      items: [
        for (final entry in lifestyle.entries)
          (
            icons[entry.key] ?? Icons.psychology_alt_rounded,
            entry.key,
            entry.key == 'Languages'
                ? ProfileFormOptions.parseLanguages(entry.value).join(' · ')
                : entry.value,
          ),
      ],
    );
  }
}

class VerificationTrustCard extends StatelessWidget {
  const VerificationTrustCard({
    super.key,
    required this.onVerify,
    required this.onSafety,
  });

  final VoidCallback onVerify;
  final VoidCallback onSafety;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TrustStatusRow(
            icon: Icons.photo_camera_rounded,
            title: 'Photo verification',
            status: 'Review available',
          ),
          const SizedBox(height: 12),
          const _TrustStatusRow(
            icon: Icons.shield_rounded,
            title: 'Safety guidelines',
            status: 'Always available',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final verify = AppPrimaryButton(
                label: 'Verify profile',
                icon: Icons.verified_rounded,
                onPressed: onVerify,
              );
              final safety = AppPrimaryButton(
                label: 'Safety',
                icon: Icons.shield_outlined,
                variant: AppPrimaryButtonVariant.outlined,
                onPressed: onSafety,
              );
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [verify, const SizedBox(height: 10), safety],
                );
              }
              return Row(
                children: [
                  Expanded(child: verify),
                  const SizedBox(width: 10),
                  Expanded(child: safety),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrustStatusRow extends StatelessWidget {
  const _TrustStatusRow({
    required this.icon,
    required this.title,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 11),
        Expanded(child: Text(title, style: AmoraTextStyles.titleMedium)),
        Text(
          status,
          style: AmoraTextStyles.labelMedium.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class PremiumMembershipCard extends StatelessWidget {
  const PremiumMembershipCard({
    super.key,
    required this.onViewPremium,
    required this.onManage,
  });

  final VoidCallback onViewPremium;
  final VoidCallback onManage;

  static const _features = <(IconData, String)>[
    (Icons.favorite_rounded, 'See likes'),
    (Icons.tune_rounded, 'Advanced filters'),
    (Icons.visibility_rounded, 'Priority visibility'),
    (Icons.auto_awesome_rounded, 'Exclusive features'),
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('premium-membership-section'),
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactActions = constraints.maxWidth < 360;
          final featureWidth = constraints.maxWidth >= 480
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          final viewPremium = AppPrimaryButton(
            key: const ValueKey('profile-view-premium-button'),
            label: 'View premium',
            icon: Icons.workspace_premium_rounded,
            onPressed: onViewPremium,
          );
          final manage = AppPrimaryButton(
            key: const ValueKey('profile-manage-membership-button'),
            label: 'Manage',
            icon: Icons.manage_accounts_rounded,
            variant: AppPrimaryButtonVariant.outlined,
            onPressed: onManage,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: .48),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMORAA Premium',
                          style: AmoraTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore the membership options already available.',
                          style: AmoraTextStyles.bodyMedium.copyWith(
                            color: AppColors.text.withValues(alpha: .72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final feature in _features)
                    SizedBox(
                      width: featureWidth,
                      child: _PremiumFeatureRow(
                        icon: feature.$1,
                        label: feature.$2,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (compactActions) ...[
                viewPremium,
                const SizedBox(height: 10),
                manage,
              ] else
                Row(
                  children: [
                    Expanded(child: viewPremium),
                    const SizedBox(width: 10),
                    Expanded(child: manage),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  const _PremiumFeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileQuickActions extends StatelessWidget {
  const ProfileQuickActions({
    super.key,
    required this.onLikesSuperLikes,
    required this.onSavedProfiles,
    required this.onBlockedProfiles,
    required this.onSupport,
  });

  final VoidCallback onLikesSuperLikes;
  final VoidCallback onSavedProfiles;
  final VoidCallback onBlockedProfiles;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.favorite_rounded, 'Likes & Super Likes', onLikesSuperLikes),
      (Icons.bookmark_rounded, 'Saved Profiles', onSavedProfiles),
      (Icons.block_rounded, 'Blocked Profiles', onBlockedProfiles),
      (Icons.support_agent_rounded, 'Support', onSupport),
    ];
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth >= 280
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final action in actions)
                SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(
                    icon: action.$1,
                    label: action.$2,
                    semanticLabel: switch (action.$2) {
                      'Likes & Super Likes' => 'Open Likes and Super Likes',
                      'Saved Profiles' => 'Open Saved Profiles',
                      'Blocked Profiles' => 'Open Blocked Profiles',
                      _ => 'Open Support',
                    },
                    onTap: action.$3,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              if (_pressed != pressed) setState(() => _pressed = pressed);
            },
            child: SizedBox(
              height: 96,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: AppColors.secondary, size: 22),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AmoraTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          color: AppColors.primary,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileLinkItem {
  const ProfileLinkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class ProfileLinkGroup extends StatelessWidget {
  const ProfileLinkGroup({super.key, required this.items});

  final List<ProfileLinkItem> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ListTile(
              minTileHeight: 72,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(items[index].icon, color: AppColors.secondary),
              ),
              title: Text(
                items[index].title,
                style: AmoraTextStyles.titleMedium,
              ),
              subtitle: Text(
                items[index].subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: items[index].onTap,
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                indent: 76,
                color: AppColors.primary.withValues(alpha: .07),
              ),
          ],
        ],
      ),
    );
  }
}

class SessionActionButton extends StatelessWidget {
  const SessionActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.secondary : AppColors.primary;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .7)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _ProfileEmptyCard extends StatelessWidget {
  const _ProfileEmptyCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AmoraTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.text.withValues(alpha: .65),
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

String? _zodiacFor(String birthdate) {
  final parts = birthdate
      .split('/')
      .map((part) => int.tryParse(part.trim()))
      .toList(growable: false);
  if (parts.length != 3 || parts[0] == null || parts[1] == null) return null;
  final day = parts[0]!;
  final month = parts[1]!;
  return switch (month) {
    1 => day >= 20 ? 'Aquarius' : 'Capricorn',
    2 => day >= 19 ? 'Pisces' : 'Aquarius',
    3 => day >= 21 ? 'Aries' : 'Pisces',
    4 => day >= 20 ? 'Taurus' : 'Aries',
    5 => day >= 21 ? 'Gemini' : 'Taurus',
    6 => day >= 21 ? 'Cancer' : 'Gemini',
    7 => day >= 23 ? 'Leo' : 'Cancer',
    8 => day >= 23 ? 'Virgo' : 'Leo',
    9 => day >= 23 ? 'Libra' : 'Virgo',
    10 => day >= 23 ? 'Scorpio' : 'Libra',
    11 => day >= 22 ? 'Sagittarius' : 'Scorpio',
    12 => day >= 22 ? 'Capricorn' : 'Sagittarius',
    _ => null,
  };
}
