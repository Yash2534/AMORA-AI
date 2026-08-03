import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:flutter/material.dart';

/// A progress dashboard. The full editor deliberately lives elsewhere.
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  static const routeName = '/profile-completion';

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _repository = LocalProfileRepository.instance;
  final Set<ProfileCompletionSectionId> _expanded = {};
  final Set<ProfileCompletionSectionId> _showValidation = {};
  final Map<ProfileCompletionSectionId, GlobalKey<FormState>> _formKeys = {
    for (final id in ProfileCompletionSectionId.values) id: GlobalKey(),
  };
  final Map<ProfileCompletionSectionId, String> _saveErrors = {};
  late final ProfileFormController _controller;
  ProfileCompletionSectionId? _savingSection;

  @override
  void initState() {
    super.initState();
    _controller = ProfileFormController(repository: _repository)
      ..addListener(_refresh);
    _repository.addListener(_refresh);
    final next = _repository.profile.completionResult.recommendedNext;
    if (next != null) _expanded.add(next.id);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    final result = profile.completionResult;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const AmoraScreenTitle(
          title: 'Profile Completion',
          subtitle: 'Your progress dashboard',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 820,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space16,
                  AmoraSpacing.space20,
                  AmoraSpacing.space40 +
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    _CompletionDashboardHeader(
                      profile: profile,
                      result: result,
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    if (result.recommendedNext case final next?)
                      _RecommendationCard(
                        section: next,
                        onOpen: () => _toggle(next.id, true),
                      )
                    else
                      const _ReadyCard(),
                    const SizedBox(height: AmoraSpacing.space24),
                    Text(
                      'Completion Checklist',
                      style: AmoraTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      'Open a section to review what is complete and what still needs attention.',
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    for (final section in result.sections) ...[
                      _CompletionSectionCard(
                        key: ValueKey('completion-section-${section.id.name}'),
                        section: section,
                        expanded: _expanded.contains(section.id),
                        onTap: () => _toggle(section.id),
                        editor: _editorFor(section.id),
                        saving: _savingSection == section.id,
                        error: _saveErrors[section.id],
                        onSave: () => _saveSection(section.id),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                    ],
                    _VerificationRecommendationCard(
                      onOpen: () async {
                        await Navigator.of(
                          context,
                        ).pushNamed(KycVerificationScreen.routeName);
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    AppPrimaryButton(
                      key: const ValueKey('profile-completion-primary-button'),
                      label: 'Back to Profile',
                      icon: Icons.person_rounded,
                      onPressed: _backToProfile,
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

  void _toggle(ProfileCompletionSectionId id, [bool forceOpen = false]) {
    setState(() {
      if (forceOpen) {
        _expanded.add(id);
      } else if (!_expanded.add(id)) {
        _expanded.remove(id);
      }
    });
  }

  Widget _editorFor(ProfileCompletionSectionId id) {
    final showValidation = _showValidation.contains(id);
    final profile = _controller.draftProfile;
    final editor = switch (id) {
      ProfileCompletionSectionId.photos => AmoraaProfilePhotoSection(
        profile: profile,
        showError: showValidation,
        onManage: _openPhotoManager,
      ),
      ProfileCompletionSectionId.basicDetails => AmoraaBasicDetailsSection(
        controller: _controller,
        showValidation: showValidation,
      ),
      ProfileCompletionSectionId.workEducation => AmoraaWorkEducationSection(
        controller: _controller,
      ),
      ProfileCompletionSectionId.locationIntentions =>
        AmoraaLocationIntentionsSection(controller: _controller),
      ProfileCompletionSectionId.identityDetails =>
        AmoraaIdentityDetailsSelector(
          controller: _controller,
          showValidation: showValidation,
        ),
      ProfileCompletionSectionId.bio => AmoraaProfileBioField(
        controller: _controller.bio,
      ),
      ProfileCompletionSectionId.interests => AmoraaInterestsSelector(
        controller: _controller,
        showValidation: showValidation,
      ),
      ProfileCompletionSectionId.lifestyle => AmoraaLifestyleSelector(
        controller: _controller,
        showValidation: showValidation,
      ),
      ProfileCompletionSectionId.prompt => AmoraaProfilePromptField(
        controller: _controller,
        showValidation: showValidation,
      ),
    };
    return Form(key: _formKeys[id], child: editor);
  }

  Future<void> _openPhotoManager() async {
    await Navigator.of(context).pushNamed(PhotoManagerScreen.routeName);
    if (!mounted) return;
    _controller.refreshExternalProfile();
  }

  Future<void> _saveSection(ProfileCompletionSectionId id) async {
    if (_savingSection != null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _showValidation.add(id);
      _saveErrors.remove(id);
    });
    final formValid = _formKeys[id]?.currentState?.validate() ?? true;
    final draft = _controller.draftProfile;
    final section = draft.completionResult.sections.firstWhere(
      (candidate) => candidate.id == id,
    );
    if (!formValid || !section.isComplete) {
      setState(() {
        _saveErrors[id] =
            '${section.title} still needs ${section.missingFields} ${section.missingFields == 1 ? 'detail' : 'details'}.';
      });
      return;
    }
    setState(() => _savingSection = id);
    try {
      await _controller.save();
      if (!mounted) return;
      setState(() {
        _savingSection = null;
        _showValidation.remove(id);
        _saveErrors.remove(id);
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${section.title} saved successfully.')),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingSection = null;
        _saveErrors[id] = 'Could not save this section. Please retry.';
      });
    }
  }

  void _backToProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(ProfileScreen.routeName);
  }
}

class _CompletionDashboardHeader extends StatelessWidget {
  const _CompletionDashboardHeader({
    required this.profile,
    required this.result,
  });

  final UserProfile profile;
  final ProfileCompletionResult result;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PremiumCard(
      key: const ValueKey('completion-progress-header'),
      radius: 24,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 350;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.statusLabel, style: AmoraTextStyles.sectionTitle),
              const SizedBox(height: AmoraSpacing.space4),
              Text(
                result.remainingSectionCount == 0
                    ? 'Every required section is ready.'
                    : '${result.remainingSectionCount} sections · ${result.remainingFieldCount} details remaining',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
          final progress = _CompletionRing(
            percent: result.percentage,
            reduceMotion: reduceMotion,
          );
          return Column(
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
                  const SizedBox(width: AmoraSpacing.space12),
                  if (!compact) Expanded(child: identity),
                  if (!compact) const SizedBox(width: AmoraSpacing.space12),
                  progress,
                ],
              ),
              if (compact) ...[
                const SizedBox(height: AmoraSpacing.space12),
                identity,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.percent, required this.reduceMotion});

  final int percent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile completion, $percent percent',
      child: SizedBox.square(
        dimension: 68,
        child: TweenAnimationBuilder<double>(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: percent / 100),
          builder: (context, value, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: 64,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.tertiary,
                  color: AppColors.secondary,
                ),
              ),
              Text('$percent%', style: AmoraTextStyles.cardTitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.section, required this.onOpen});

  final ProfileSectionProgress section;
  final VoidCallback onOpen;

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
            width: 48,
            height: 48,
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
                Text('Recommended Next', style: AmoraTextStyles.labelMedium),
                const SizedBox(height: AmoraSpacing.space4),
                Text(section.title, style: AmoraTextStyles.cardTitle),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  section.description,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('Review')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard();

  @override
  Widget build(BuildContext context) {
    return const PremiumCard(
      radius: 20,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.verified_rounded, color: AppColors.primary),
        title: Text('Profile Ready'),
        subtitle: Text('All required profile sections are complete.'),
      ),
    );
  }
}

class _CompletionSectionCard extends StatelessWidget {
  const _CompletionSectionCard({
    super.key,
    required this.section,
    required this.expanded,
    required this.onTap,
    required this.editor,
    required this.saving,
    required this.error,
    required this.onSave,
  });

  final ProfileSectionProgress section;
  final bool expanded;
  final VoidCallback onTap;
  final Widget editor;
  final bool saving;
  final String? error;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PremiumCard(
      radius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: '${section.title}, ${section.statusLabel}',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.all(AmoraSpacing.space16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: section.isComplete
                              ? AppColors.tertiary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          section.isComplete
                              ? Icons.check_rounded
                              : _sectionIcon(section.id),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: AmoraTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              section.statusLabel,
                              style: AmoraTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        child: const Icon(Icons.expand_more_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AmoraSpacing.space16,
                      0,
                      AmoraSpacing.space16,
                      AmoraSpacing.space16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AmoraSpacing.space12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            section.isComplete
                                ? '${section.description} This section is complete.'
                                : '${section.description} ${section.missingFields} ${section.missingFields == 1 ? 'detail remains' : 'details remain'}.',
                            style: AmoraTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space16),
                        editor,
                        if (error case final message?) ...[
                          const SizedBox(height: AmoraSpacing.space8),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              style: AmoraTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AmoraSpacing.space16),
                        AppPrimaryButton(
                          key: ValueKey('completion-save-${section.id.name}'),
                          label: saving ? 'Saving' : 'Save Section',
                          icon: Icons.check_rounded,
                          isLoading: saving,
                          onPressed: saving ? null : onSave,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _VerificationRecommendationCard extends StatelessWidget {
  const _VerificationRecommendationCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('completion-section-verification'),
      radius: 20,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 44,
            child: Icon(Icons.verified_user_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification', style: AmoraTextStyles.cardTitle),
                Text(
                  'Optional identity and selfie verification.',
                  style: AmoraTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open verification',
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

IconData _sectionIcon(ProfileCompletionSectionId id) => switch (id) {
  ProfileCompletionSectionId.photos => Icons.photo_library_rounded,
  ProfileCompletionSectionId.basicDetails => Icons.person_rounded,
  ProfileCompletionSectionId.workEducation => Icons.work_rounded,
  ProfileCompletionSectionId.locationIntentions => Icons.favorite_rounded,
  ProfileCompletionSectionId.identityDetails => Icons.badge_rounded,
  ProfileCompletionSectionId.bio => Icons.notes_rounded,
  ProfileCompletionSectionId.interests => Icons.interests_rounded,
  ProfileCompletionSectionId.lifestyle => Icons.self_improvement_rounded,
  ProfileCompletionSectionId.prompt => Icons.format_quote_rounded,
};
