import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_metrics.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_section_editor_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_photo_gallery.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_story_image.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

typedef ProfileAccountDeletionCallback =
    Future<bool> Function(String reason, String? details);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.showNavigation = true,
    this.onDeleteAccount,
  });

  final bool showNavigation;
  final ProfileAccountDeletionCallback? onDeleteAccount;
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

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    final primaryPhotoIndex = profile.photos.isEmpty
        ? -1
        : profile.primaryPhotoIndex.clamp(0, profile.photos.length - 1);
    final storyPhotos = <(int, String)>[
      for (var index = 0; index < profile.photos.length; index++)
        if (index != primaryPhotoIndex) (index, profile.photos[index]),
    ];
    final bottomInset = widget.showNavigation ? 116.0 : 36.0;
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
                  onSettings: () => _open(ProfileSettingsScreen.routeName),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset),
                sliver: SliverList.list(
                  children: [
                    FadeUp(
                      child: ProfileHero(
                        profile: profile,
                        zodiac: _zodiacFor(profile.birthdate),
                        onEdit: () => _open(ProfileEditScreen.routeName),
                        onPreview: () => _open(ProfilePreviewScreen.routeName),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeUp(
                      delay: const Duration(milliseconds: 35),
                      child: ProfileCompletionCard(
                        profile: profile,
                        onComplete: () =>
                            _open(ProfileCompletionScreen.routeName),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ProfileSectionHeading(
                      key: const ValueKey('profile-photo-gallery-heading'),
                      icon: Icons.photo_camera_rounded,
                      title: 'Photo Gallery',
                      subtitle: 'The moments that make your story feel real.',
                      actionLabel: 'Manage',
                      onAction: () => _open(PhotoManagerScreen.routeName),
                    ),
                    const SizedBox(height: 12),
                    ProfilePhotoGallery(
                      profile: profile,
                      onManage: () => _open(PhotoManagerScreen.routeName),
                    ),
                    const SizedBox(height: 30),
                    ProfileSectionHeading(
                      icon: Icons.forum_rounded,
                      title: 'Profile prompts',
                      subtitle:
                          'One thoughtful glimpse into how you think and connect.',
                      actionLabel: 'Edit',
                      onAction: () => _openSection(ProfileSection.prompts),
                    ),
                    const SizedBox(height: 12),
                    ProfilePromptsCard(profile: profile),
                    const SizedBox(height: 30),
                    if (storyPhotos.isNotEmpty) ...[
                      AmoraaProfileStoryImage(
                        image: storyPhotos.first.$2,
                        semanticLabel:
                            'Profile photo ${storyPhotos.first.$1 + 1}',
                        initials: AppImages.initialsForName(profile.name),
                      ),
                      const SizedBox(height: 30),
                    ],
                    ProfileSectionHeading(
                      icon: Icons.favorite_rounded,
                      title: 'Dating intentions',
                      subtitle: 'Clear about the connection you want to build.',
                      actionLabel: 'Edit',
                      onAction: () => _open(ProfileEditScreen.routeName),
                    ),
                    const SizedBox(height: 12),
                    DatingIntentionsCard(profile: profile),
                    const SizedBox(height: 30),
                    ProfileSectionHeading(
                      icon: Icons.interests_rounded,
                      title: 'Interests',
                      subtitle: 'Easy places for a conversation to begin.',
                      actionLabel: 'Edit',
                      onAction: () => _openSection(ProfileSection.interests),
                    ),
                    const SizedBox(height: 12),
                    ProfileInterestsCard(interests: profile.interests),
                    const SizedBox(height: 30),
                    if (storyPhotos.length > 1) ...[
                      AmoraaProfileStoryImage(
                        image: storyPhotos[1].$2,
                        semanticLabel: 'Profile photo ${storyPhotos[1].$1 + 1}',
                        initials: AppImages.initialsForName(profile.name),
                      ),
                      const SizedBox(height: 30),
                    ],
                    ProfileSectionHeading(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Personality',
                      subtitle: 'The lifestyle details you chose to share.',
                      actionLabel: 'Edit',
                      onAction: () => _openSection(ProfileSection.lifestyle),
                    ),
                    const SizedBox(height: 12),
                    ProfilePersonalityCard(lifestyle: profile.lifestyle),
                    for (
                      var index = 2;
                      index < storyPhotos.length;
                      index++
                    ) ...[
                      const SizedBox(height: 24),
                      AmoraaProfileStoryImage(
                        image: storyPhotos[index].$2,
                        semanticLabel:
                            'Profile photo ${storyPhotos[index].$1 + 1}',
                        initials: AppImages.initialsForName(profile.name),
                      ),
                    ],
                    const SizedBox(height: 30),
                    const ProfileSectionHeading(
                      icon: Icons.verified_user_rounded,
                      title: 'Verification & trust',
                      subtitle: 'Safety signals are shown only when verified.',
                    ),
                    const SizedBox(height: 12),
                    VerificationTrustCard(
                      onVerify: () => _open(KycVerificationScreen.routeName),
                      onSafety: () => _open(SafetyPrivacyScreen.routeName),
                    ),
                    const SizedBox(height: 30),
                    const ProfileSectionHeading(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Premium membership',
                      subtitle: 'A quieter invitation to get more from AMORAA.',
                    ),
                    const SizedBox(height: 12),
                    PremiumMembershipCard(
                      onViewPremium: () => _open(SubscriptionScreen.routeName),
                      onManage: () => _open(SubscriptionScreen.routeName),
                    ),
                    const SizedBox(height: 30),
                    const ProfileSectionHeading(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Account actions',
                      subtitle:
                          'Sign out or permanently remove your AMORAA account.',
                    ),
                    const SizedBox(height: 12),
                    ProfileLinkGroup(
                      items: [
                        ProfileLinkItem(
                          icon: Icons.logout_rounded,
                          title: 'Log out',
                          subtitle:
                              'Sign out of this device without deleting your profile.',
                          onTap: _confirmLogout,
                        ),
                        ProfileLinkItem(
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete account',
                          subtitle:
                              'Permanently delete your AMORAA account and associated data.',
                          onTap: _confirmDeleteAccount,
                        ),
                      ],
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

  Future<void> _openSection(ProfileSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSectionEditorScreen(section: section),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
        title: const Text('Log out of AMORAA?'),
        content: const Text(
          'Your profile stays saved. You can sign back in with your registered account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AmoraSession.logOut();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }

  Future<void> _confirmDeleteAccount() async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.primary.withValues(alpha: .24),
      builder: (sheetContext) =>
          _AccountDeletionFlowSheet(onDeleteAccount: widget.onDeleteAccount),
    );
    if (deleted != true || !mounted) return;
    await _clearDeletedAccountState();
    if (!mounted) return;
    AmoraSession.logOut();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }

  Future<void> _clearDeletedAccountState() async {
    for (final clear in <Future<void> Function()>[
      LocalChatRepository.instance.clearForAccountDeletion,
      LocalProfileRepository.instance.clearForAccountDeletion,
      LocalOnboardingRepository.instance.clearForAccountDeletion,
    ]) {
      try {
        await clear();
      } catch (_) {
        // A backend-confirmed deletion still requires the local session to end.
      }
    }
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileHeaderDelegate({required this.onSettings});

  final VoidCallback onSettings;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.surface,
      elevation: overlapsContent ? 2 : 0,
      shadowColor: AppColors.primary.withValues(alpha: .08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My dating identity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.titleLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Your story, your way',
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.text.withValues(alpha: .62),
                    ),
                  ),
                ],
              ),
            ),
            _ProfileHeaderActionButton(
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
    return oldDelegate.onSettings != onSettings;
  }
}

class _ProfileHeaderActionButton extends StatelessWidget {
  const _ProfileHeaderActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: .28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: AppColors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  overlayColor: WidgetStatePropertyAll(
                    AppColors.tertiary.withValues(alpha: .22),
                  ),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(icon, color: AppColors.primary, size: 22),
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

enum _AccountDeletionState {
  collectingReason,
  reviewingConsequences,
  confirmingIdentity,
  submitting,
  failure,
}

class _AccountDeletionReason {
  const _AccountDeletionReason(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;
}

const _accountDeletionReasons = <_AccountDeletionReason>[
  _AccountDeletionReason(
    'found_partner',
    'I found a partner',
    Icons.favorite_rounded,
  ),
  _AccountDeletionReason(
    'taking_break',
    'I am taking a break from dating',
    Icons.pause_circle_rounded,
  ),
  _AccountDeletionReason(
    'not_enough_matches',
    'I am not getting enough matches',
    Icons.person_search_rounded,
  ),
  _AccountDeletionReason(
    'poor_experience',
    'I had a poor experience',
    Icons.sentiment_dissatisfied_rounded,
  ),
  _AccountDeletionReason(
    'privacy_safety',
    'I have privacy or safety concerns',
    Icons.shield_rounded,
  ),
  _AccountDeletionReason(
    'difficult_to_use',
    'The app is difficult to use',
    Icons.touch_app_rounded,
  ),
  _AccountDeletionReason(
    'too_many_notifications',
    'I receive too many notifications',
    Icons.notifications_off_rounded,
  ),
  _AccountDeletionReason(
    'subscription_expensive',
    'The subscription is too expensive',
    Icons.workspace_premium_rounded,
  ),
  _AccountDeletionReason(
    'duplicate_account',
    'I created another account',
    Icons.switch_account_rounded,
  ),
  _AccountDeletionReason('other', 'Other', Icons.more_horiz_rounded),
];

class _AccountDeletionFlowSheet extends StatefulWidget {
  const _AccountDeletionFlowSheet({required this.onDeleteAccount});

  final ProfileAccountDeletionCallback? onDeleteAccount;

  @override
  State<_AccountDeletionFlowSheet> createState() =>
      _AccountDeletionFlowSheetState();
}

class _AccountDeletionFlowSheetState extends State<_AccountDeletionFlowSheet> {
  final _detailsController = TextEditingController();
  final _confirmationController = TextEditingController();
  _AccountDeletionState _state = _AccountDeletionState.collectingReason;
  _AccountDeletionReason? _selectedReason;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detailsController.addListener(_refreshValidation);
    _confirmationController.addListener(_refreshValidation);
  }

  @override
  void dispose() {
    _detailsController
      ..removeListener(_refreshValidation)
      ..dispose();
    _confirmationController
      ..removeListener(_refreshValidation)
      ..dispose();
    super.dispose();
  }

  bool get _isOther => _selectedReason?.code == 'other';
  bool get _otherReasonIsValid =>
      !_isOther || _detailsController.text.trim().length >= 10;
  bool get _identityConfirmed =>
      _confirmationController.text.trim() == 'DELETE';
  bool get _isDeleting => _state == _AccountDeletionState.submitting;

  void _refreshValidation() {
    if (mounted) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final maximumHeight = math.min(760.0, availableHeight * .92);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              side: BorderSide(
                color: AppColors.secondary.withValues(alpha: .2),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: PopScope(
              canPop: !_isDeleting,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maximumHeight),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: switch (_state) {
                    _AccountDeletionState.collectingReason => _buildReasonStep(
                      mediaQuery,
                    ),
                    _AccountDeletionState.reviewingConsequences =>
                      _buildConsequencesStep(mediaQuery),
                    _AccountDeletionState.confirmingIdentity ||
                    _AccountDeletionState.submitting ||
                    _AccountDeletionState.failure => _buildConfirmationStep(
                      mediaQuery,
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonStep(MediaQueryData mediaQuery) {
    return Column(
      key: const ValueKey('account-deletion-reason-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DeletionSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you leaving AMORAA?',
                style: AmoraTextStyles.headlineSmall.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Your feedback helps us improve the experience.',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.text.withValues(alpha: .68),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                for (final reason in _accountDeletionReasons) ...[
                  _DeletionReasonOption(
                    key: ValueKey('delete-reason-${reason.code}'),
                    reason: reason,
                    selected: identical(reason, _selectedReason),
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                        _errorMessage = null;
                      });
                    },
                  ),
                  if (!identical(reason, _accountDeletionReasons.last))
                    const SizedBox(height: 8),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _isOther
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextField(
                            key: const ValueKey('delete-other-reason-field'),
                            controller: _detailsController,
                            textInputAction: TextInputAction.done,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 240,
                            decoration: InputDecoration(
                              labelText: 'Tell us more',
                              helperText: 'Enter at least 10 characters.',
                              errorText:
                                  _detailsController.text.isNotEmpty &&
                                      !_otherReasonIsValid
                                  ? 'Please enter a meaningful reason.'
                                  : null,
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: AppColors.background,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: AppColors.secondary.withValues(
                                    alpha: .24,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        _DeletionSheetActions(
          bottomPadding: math.max(20, mediaQuery.viewPadding.bottom + 12),
          secondaryLabel: 'Cancel',
          onSecondary: () => Navigator.of(context).pop(false),
          primaryLabel: 'Continue',
          onPrimary: _selectedReason == null || !_otherReasonIsValid
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _state = _AccountDeletionState.reviewingConsequences;
                    _errorMessage = null;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildConsequencesStep(MediaQueryData mediaQuery) {
    const consequences = <(IconData, String)>[
      (
        Icons.person_off_rounded,
        'Your profile, photos, matches, and chat access may be removed after the server confirms deletion.',
      ),
      (
        Icons.payments_outlined,
        'This app does not claim that subscriptions or event bookings are cancelled automatically.',
      ),
      (
        Icons.schedule_rounded,
        'Whether deletion is immediate or scheduled is controlled by the connected account service.',
      ),
      (
        Icons.policy_outlined,
        'Data retention follows the backend policy; this app does not define a separate retention period.',
      ),
    ];
    return Column(
      key: const ValueKey('account-deletion-consequences-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DeletionSheetHandle(),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Understand what happens next',
                  style: AmoraTextStyles.headlineSmall.copyWith(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Account deletion cannot be undone after the account service confirms it.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.text.withValues(alpha: .7),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                for (final consequence in consequences)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            consequence.$1,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            consequence.$2,
                            style: AmoraTextStyles.bodyMedium.copyWith(
                              height: 1.45,
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
        _DeletionSheetActions(
          bottomPadding: math.max(20, mediaQuery.viewPadding.bottom + 12),
          secondaryLabel: 'Keep my account',
          onSecondary: () => Navigator.of(context).pop(false),
          primaryLabel: 'Continue',
          onPrimary: () => setState(() {
            _state = _AccountDeletionState.confirmingIdentity;
            _errorMessage = null;
          }),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(MediaQueryData mediaQuery) {
    final selectedReason = _selectedReason;
    return Column(
      key: const ValueKey('account-deletion-confirmation-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DeletionSheetHandle(),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: .24),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: .28),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Confirm account deletion',
                    textAlign: TextAlign.center,
                    style: AmoraTextStyles.headlineSmall.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'For protection against accidental deletion, type DELETE exactly below.',
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.text.withValues(alpha: .7),
                  ),
                ),
                if (selectedReason != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: .24),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          selectedReason.icon,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected reason',
                                style: AmoraTextStyles.labelMedium.copyWith(
                                  color: AppColors.text.withValues(alpha: .62),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selectedReason.label,
                                style: AmoraTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (selectedReason.code == 'other' &&
                                  _detailsController.text
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  _detailsController.text.trim(),
                                  style: AmoraTextStyles.bodySmall.copyWith(
                                    height: 1.4,
                                    color: AppColors.text.withValues(
                                      alpha: .68,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('delete-account-confirmation-field'),
                  controller: _confirmationController,
                  enabled: !_isDeleting,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Type DELETE to confirm',
                    helperText: _identityConfirmed
                        ? 'Identity confirmation complete.'
                        : 'This confirmation is case-sensitive.',
                  ),
                ),
                if (widget.onDeleteAccount == null) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: .24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.tertiary),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.link_off_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Account deletion is unavailable because this build has no account-deletion endpoint. Your account has not been changed.',
                              style: TextStyle(
                                color: AppColors.text,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Semantics(
                    liveRegion: true,
                    label: _errorMessage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: .34),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AmoraTextStyles.bodySmall.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_isDeleting)
                  Semantics(
                    liveRegion: true,
                    label: 'Deleting account',
                    child: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
        _DeletionSheetActions(
          bottomPadding: math.max(20, mediaQuery.viewPadding.bottom + 12),
          secondaryLabel: 'Keep my account',
          onSecondary: _isDeleting
              ? null
              : () => Navigator.of(context).pop(false),
          primaryLabel: _isDeleting ? 'Deleting account…' : 'Delete my account',
          primaryIcon: _isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : const Icon(Icons.person_remove_rounded, size: 20),
          destructive: true,
          onPrimary:
              _isDeleting ||
                  !_identityConfirmed ||
                  widget.onDeleteAccount == null
              ? null
              : _deleteAccount,
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    final selectedReason = _selectedReason;
    if (_isDeleting ||
        selectedReason == null ||
        !_otherReasonIsValid ||
        !_identityConfirmed) {
      return;
    }

    final deletionCallback = widget.onDeleteAccount;
    if (deletionCallback == null) {
      setState(() {
        _errorMessage =
            'Account deletion is unavailable because no account-deletion endpoint is connected.';
      });
      return;
    }

    setState(() {
      _state = _AccountDeletionState.submitting;
      _errorMessage = null;
    });

    var deleted = false;
    try {
      final details = selectedReason == _accountDeletionReasons.last
          ? _detailsController.text.trim()
          : '';
      deleted = await deletionCallback(
        selectedReason.code,
        details.isEmpty ? null : details,
      );
    } catch (_) {
      deleted = false;
    }

    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _state = _AccountDeletionState.failure;
      _errorMessage = 'We couldn’t delete your account. Please try again.';
    });
  }
}

class _DeletionSheetHandle extends StatelessWidget {
  const _DeletionSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: .24),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _DeletionReasonOption extends StatelessWidget {
  const _DeletionReasonOption({
    super.key,
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final _AccountDeletionReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: selected,
      label: reason.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tertiary.withValues(alpha: .2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.secondary.withValues(alpha: .2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            focusColor: AppColors.tertiary.withValues(alpha: .24),
            overlayColor: WidgetStatePropertyAll(
              AppColors.tertiary.withValues(alpha: .18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  Icon(reason.icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reason.label,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.secondary.withValues(alpha: .4),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.surface,
                            size: 16,
                          )
                        : null,
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

class _DeletionSheetActions extends StatelessWidget {
  const _DeletionSheetActions({
    required this.bottomPadding,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.destructive = false,
  });

  final double bottomPadding;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Widget? primaryIcon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final primaryColor = destructive ? AppColors.secondary : AppColors.primary;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.secondary.withValues(alpha: .14)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: .34),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('delete-primary-action'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: AppColors.surface,
                  disabledBackgroundColor: primaryColor.withValues(alpha: .3),
                  disabledForegroundColor: AppColors.surface.withValues(
                    alpha: .86,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (primaryIcon != null) ...[
                      primaryIcon!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        primaryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.profile,
    required this.zodiac,
    required this.onEdit,
    required this.onPreview,
  });

  final LocalProfileDraft profile;
  final String? zodiac;
  final VoidCallback onEdit;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final media = Semantics(
          image: true,
          label: 'Primary profile photo for ${profile.name}',
          child: SizedBox(
            height: wide ? 430 : math.min(470, constraints.maxWidth * 1.18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AmoraProfileImage(
                  imageUrl: profile.primaryPhoto,
                  assetPath: profile.primaryPhoto,
                  initials: AppImages.initialsForName(profile.name),
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(30),
                  semanticLabel: 'Primary profile photo for ${profile.name}',
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppColors.primary.withValues(alpha: .40),
                  ),
                ),
                if (!wide)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _HeroIdentity(
                      profile: profile,
                      zodiac: zodiac,
                      light: true,
                    ),
                  ),
              ],
            ),
          ),
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              media,
              const SizedBox(height: 14),
              _HeroActions(onEdit: onEdit, onPreview: onPreview),
            ],
          );
        }

        return SizedBox(
          height: 510,
          child: PremiumCard(
            radius: 30,
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: media),
                const SizedBox(width: 24),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeroIdentity(
                        profile: profile,
                        zodiac: zodiac,
                        light: false,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        profile.bio,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _HeroActions(onEdit: onEdit, onPreview: onPreview),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroIdentity extends StatelessWidget {
  const _HeroIdentity({
    required this.profile,
    required this.zodiac,
    required this.light,
  });

  final LocalProfileDraft profile;
  final String? zodiac;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? AppColors.surface : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.age == null
              ? profile.name
              : '${profile.name}, ${profile.age}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.headlineLarge.copyWith(
            color: color,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (zodiac != null)
              _HeroPill(
                icon: Icons.brightness_2_rounded,
                text: zodiac!,
                light: light,
              ),
            _HeroPill(
              icon: Icons.location_on_rounded,
              text: profile.location,
              light: light,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          profile.profession,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: color.withValues(alpha: light ? .88 : .72),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.text,
    required this.light,
  });

  final IconData icon;
  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: light
            ? AppColors.surface.withValues(alpha: .16)
            : AppColors.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: light
              ? AppColors.surface.withValues(alpha: .28)
              : AppColors.tertiary,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: light ? AppColors.surface : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: light ? AppColors.surface : AppColors.primary,
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
      label: 'Edit profile',
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
          : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Semantics(
          label: 'Profile completion ${(value * 100).round()} percent',
          child: CustomPaint(
            painter: _ProgressRingPainter(value),
            child: SizedBox.square(
              dimension: 88,
              child: Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: AmoraTextStyles.titleLarge.copyWith(
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
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 10),
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
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class ProfilePromptsCard extends StatelessWidget {
  const ProfilePromptsCard({super.key, required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    final prompts = profile.prompts.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (prompts.isEmpty) {
      return const _ProfileEmptyCard(
        icon: Icons.add_comment_rounded,
        title: 'No prompts yet',
        description: 'Add three answers that make it easy to start talking.',
      );
    }
    return Column(
      children: [
        for (var index = 0; index < prompts.length; index++) ...[
          PremiumCard(
            key: ValueKey('profile-prompt-$index'),
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        prompts[index].key,
                        style: AmoraTextStyles.labelLarge.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  prompts[index].value,
                  style: AmoraTextStyles.titleMedium.copyWith(
                    fontSize: 17,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${prompts[index].value.characters.length}/180',
                  textAlign: TextAlign.end,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.text.withValues(alpha: .55),
                  ),
                ),
              ],
            ),
          ),
          if (index != prompts.length - 1) const SizedBox(height: 10),
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
      (Icons.school_rounded, 'Education', profile.education),
      (Icons.location_on_rounded, 'City', profile.location),
      (Icons.person_rounded, 'Gender', profile.gender),
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
                  minHeight: 42,
                  maxWidth: constraints.maxWidth,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
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
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 17,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 7),
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
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'Verify profile',
                  icon: Icons.verified_rounded,
                  onPressed: onVerify,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Safety',
                  icon: Icons.shield_outlined,
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: onSafety,
                ),
              ),
            ],
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
