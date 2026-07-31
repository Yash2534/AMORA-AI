import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:flutter/material.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  static const routeName = '/profile-completion';

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late final ProfileFormController _controller;
  final Map<ProfileCompletionSectionId, GlobalKey> _sectionKeys = {
    for (final id in ProfileCompletionSectionId.values) id: GlobalKey(),
  };
  final Set<ProfileCompletionSectionId> _expanded = {};
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _controller = ProfileFormController()..addListener(_refresh);
    final recommended =
        _controller.draftProfile.completionResult.recommendedNext;
    if (recommended != null) _expanded.add(recommended.id);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _controller.draftProfile;
    final result = profile.completionResult;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complete your profile'),
            Text(
              'Build a profile that feels like you',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ResponsiveMobileFrame(
          maxWidth: 820,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              key: const PageStorageKey<String>('profile-completion-scroll'),
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AmoraSpacing.space20,
                    AmoraSpacing.space16,
                    AmoraSpacing.space20,
                    AmoraSpacing.space40 +
                        MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _CompletionHeader(profile: profile, result: result),
                      const SizedBox(height: AmoraSpacing.space16),
                      if (result.isComplete)
                        _CompletionReadyCard(
                          onViewProfile: () =>
                              _saveAndOpen(ProfileScreen.routeName),
                          onDiscover: () =>
                              _saveAndOpen(DiscoverScreen.routeName),
                        )
                      else
                        _NextStepCard(
                          section: result.recommendedNext!,
                          onContinue: () =>
                              _focusSection(result.recommendedNext!.id),
                        ),
                      const SizedBox(height: AmoraSpacing.space24),
                      Text(
                        'Build your profile',
                        style: AmoraTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space4),
                      Text(
                        'Open a section, add what’s missing, and watch your progress update.',
                        style: AmoraTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      for (final section in result.sections)
                        _GuidedSectionCard(
                          key: _sectionKeys[section.id],
                          section: section,
                          expanded: _expanded.contains(section.id),
                          showValidation: _showValidation,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              expanded
                                  ? _expanded.add(section.id)
                                  : _expanded.remove(section.id);
                            });
                          },
                          child: _sectionContent(section.id, profile),
                        ),
                      _GuidedVerificationCard(
                        onOpen: () =>
                            _openNamed(KycVerificationScreen.routeName),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _CompletionActionBar(
        result: result,
        saving: _controller.saving,
        onPressed: result.isComplete
            ? () => _saveAndOpen(DiscoverScreen.routeName)
            : _saveProgressAndContinue,
        onFinish: _saveAndContinue,
      ),
    );
  }

  Widget _sectionContent(ProfileCompletionSectionId id, UserProfile profile) =>
      switch (id) {
        ProfileCompletionSectionId.photos => AmoraaProfilePhotoSection(
          profile: profile,
          showError: _showValidation,
          onManage: () => _openNamed(PhotoManagerScreen.routeName),
        ),
        ProfileCompletionSectionId.basicDetails => AmoraaBasicDetailsSection(
          controller: _controller,
          showValidation: _showValidation,
        ),
        ProfileCompletionSectionId.workEducation => AmoraaWorkEducationSection(
          controller: _controller,
        ),
        ProfileCompletionSectionId.locationIntentions =>
          AmoraaLocationIntentionsSection(controller: _controller),
        ProfileCompletionSectionId.identityDetails =>
          AmoraaIdentityDetailsSelector(
            controller: _controller,
            showValidation: _showValidation,
          ),
        ProfileCompletionSectionId.bio => AmoraaProfileBioField(
          controller: _controller.bio,
        ),
        ProfileCompletionSectionId.interests => AmoraaInterestsSelector(
          controller: _controller,
          showValidation: _showValidation,
        ),
        ProfileCompletionSectionId.lifestyle => AmoraaLifestyleSelector(
          controller: _controller,
          showValidation: _showValidation,
        ),
        ProfileCompletionSectionId.prompt => AmoraaProfilePromptField(
          controller: _controller,
          showValidation: _showValidation,
        ),
      };

  Future<void> _focusSection(ProfileCompletionSectionId id) async {
    setState(() => _expanded.add(id));
    await WidgetsBinding.instance.endOfFrame;
    final context = _sectionKeys[id]?.currentContext;
    if (context == null || !context.mounted) return;
    await Scrollable.ensureVisible(
      context,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: .08,
    );
  }

  Future<void> _openNamed(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) _controller.refreshExternalProfile();
  }

  Future<void> _saveAndContinue() => _saveAndOpen(DiscoverScreen.routeName);

  Future<void> _saveProgressAndContinue() async {
    if (_controller.saving) return;
    try {
      await _controller.save();
      if (!mounted) return;
      final next = _controller.draftProfile.completionResult.recommendedNext;
      if (next != null) await _focusSection(next.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Profile progress saved')),
          );
      }
    } catch (_) {
      if (mounted) {
        _showError('Profile progress could not be saved. Please try again.');
      }
    }
  }

  Future<void> _saveAndOpen(String route) async {
    FocusScope.of(context).unfocus();
    setState(() => _showValidation = true);
    final profile = _controller.draftProfile;
    final validForm = _formKey.currentState?.validate() ?? false;
    final errors = ProfileFormValidators.profile(profile);
    if (!validForm || errors.isNotEmpty || _controller.saving) {
      final next = profile.completionResult.recommendedNext;
      if (next != null) await _focusSection(next.id);
      if (mounted && errors.isNotEmpty) _showError(errors.first);
      return;
    }
    try {
      await _controller.save();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } catch (_) {
      if (mounted) {
        _showError('Profile could not be saved. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CompletionHeader extends StatelessWidget {
  const _CompletionHeader({required this.profile, required this.result});

  final UserProfile profile;
  final ProfileCompletionResult result;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PremiumCard(
      key: const ValueKey('completion-progress-header'),
      radius: 24,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AmoraProfileImage(
                imageUrl: profile.primaryPhoto,
                assetPath: profile.primaryPhoto,
                initials: profile.name.trim().isEmpty
                    ? 'AM'
                    : profile.name.trim().substring(0, 1),
                width: 58,
                height: 66,
                borderRadius: BorderRadius.circular(18),
                semanticLabel: 'Current profile photo',
              ),
              const SizedBox(width: AmoraSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.statusLabel,
                      style: AmoraTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      result.remainingSectionCount == 0
                          ? 'Every required section is ready.'
                          : '${result.remainingSectionCount} sections · ${result.remainingFieldCount} details remaining',
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Profile completion, ${result.percentage} percent',
                child: ExcludeSemantics(
                  child: Text(
                    '${result.percentage}%',
                    style: AmoraTextStyles.headlineSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space16),
          TweenAnimationBuilder<double>(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: result.percentage / 100),
            builder: (context, value, _) => ClipRRect(
              borderRadius: AmoraRadius.pillBorder,
              child: LinearProgressIndicator(
                minHeight: 8,
                value: value,
                backgroundColor: AppColors.tertiary.withValues(alpha: .45),
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Text(
            'Help AMORAA understand you better and create more meaningful matches.',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.section, required this.onContinue});

  final ProfileSectionProgress section;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('completion-next-step'),
      radius: 20,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AmoraSpacing.minimumTouchTarget,
            height: AmoraSpacing.minimumTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next best step', style: AmoraTextStyles.labelLarge),
                const SizedBox(height: AmoraSpacing.space4),
                Text(section.title, style: AmoraTextStyles.titleLarge),
                const SizedBox(height: AmoraSpacing.space4),
                Text(section.description, style: AmoraTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}

class _GuidedSectionCard extends StatelessWidget {
  const _GuidedSectionCard({
    super.key,
    required this.section,
    required this.expanded,
    required this.showValidation,
    required this.onExpansionChanged,
    required this.child,
  });

  final ProfileSectionProgress section;
  final bool expanded;
  final bool showValidation;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
      child: Semantics(
        button: true,
        expanded: expanded,
        label: '${section.title}, ${section.statusLabel}',
        child: PremiumCard(
          radius: 20,
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            key: ValueKey('completion-section-${section.id.name}-$expanded'),
            initiallyExpanded: expanded,
            onExpansionChanged: onExpansionChanged,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
              vertical: AmoraSpacing.space4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space16,
              0,
              AmoraSpacing.space16,
              AmoraSpacing.space20,
            ),
            leading: Container(
              width: AmoraSpacing.minimumTouchTarget,
              height: AmoraSpacing.minimumTouchTarget,
              decoration: BoxDecoration(
                color: section.isComplete
                    ? AppColors.tertiary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.tertiary),
              ),
              child: Icon(
                section.isComplete
                    ? Icons.check_rounded
                    : _sectionIcon(section.id),
                color: AppColors.primary,
              ),
            ),
            title: Text(section.title, style: AmoraTextStyles.titleMedium),
            subtitle: Text(
              section.statusLabel,
              style: AmoraTextStyles.bodySmall.copyWith(
                color: showValidation && !section.isComplete
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            children: [child],
          ),
        ),
      ),
    );
  }

  static IconData _sectionIcon(ProfileCompletionSectionId id) => switch (id) {
    ProfileCompletionSectionId.photos => Icons.photo_camera_rounded,
    ProfileCompletionSectionId.basicDetails => Icons.badge_rounded,
    ProfileCompletionSectionId.workEducation => Icons.work_outline_rounded,
    ProfileCompletionSectionId.locationIntentions =>
      Icons.favorite_outline_rounded,
    ProfileCompletionSectionId.identityDetails => Icons.tune_rounded,
    ProfileCompletionSectionId.bio => Icons.notes_rounded,
    ProfileCompletionSectionId.interests => Icons.interests_rounded,
    ProfileCompletionSectionId.lifestyle => Icons.self_improvement_rounded,
    ProfileCompletionSectionId.prompt => Icons.forum_outlined,
  };
}

class _GuidedVerificationCard extends StatelessWidget {
  const _GuidedVerificationCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('completion-section-verification'),
      radius: 20,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Row(
        children: [
          Container(
            width: AmoraSpacing.minimumTouchTarget,
            height: AmoraSpacing.minimumTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.tertiary),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification', style: AmoraTextStyles.titleMedium),
                Text(
                  'Available through AMORAA’s secure KYC flow.',
                  style: AmoraTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('Review')),
        ],
      ),
    );
  }
}

class _CompletionReadyCard extends StatelessWidget {
  const _CompletionReadyCard({
    required this.onViewProfile,
    required this.onDiscover,
  });

  final VoidCallback onViewProfile;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('profile-complete-state'),
      radius: 20,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.secondary,
            size: 36,
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Text(
            'Profile complete',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.titleLarge,
          ),
          const SizedBox(height: AmoraSpacing.space4),
          const Text(
            'Your AMORAA profile is ready.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: onViewProfile,
                child: const Text('View profile'),
              ),
              FilledButton(
                onPressed: onDiscover,
                child: const Text('Continue to Discover'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionActionBar extends StatelessWidget {
  const _CompletionActionBar({
    required this.result,
    required this.saving,
    required this.onPressed,
    required this.onFinish,
  });

  final ProfileCompletionResult result;
  final bool saving;
  final VoidCallback onPressed;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final readyToFinish = result.percentage >= 90 && !result.isComplete;
    return Material(
      color: AppColors.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: AppPrimaryButton(
                key: const ValueKey('profile-completion-primary-button'),
                label: result.isComplete
                    ? 'Continue to Discover'
                    : readyToFinish
                    ? 'Finish profile'
                    : 'Continue profile',
                icon: result.isComplete
                    ? Icons.arrow_forward_rounded
                    : Icons.auto_awesome_rounded,
                isLoading: saving,
                onPressed: saving
                    ? null
                    : readyToFinish
                    ? onFinish
                    : onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
