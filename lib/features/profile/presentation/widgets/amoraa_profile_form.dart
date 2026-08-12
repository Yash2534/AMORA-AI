import 'dart:async';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_form_navigation.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_preference_selectors.dart';
import 'package:flutter/material.dart';

enum ProfileFormMode { edit }

typedef ProfileFormSaved =
    Future<void> Function(BuildContext context, UserProfile profile);

/// The concise, full-form Edit Profile experience.
///
/// Profile Completion intentionally does not use this page shell. Both flows
/// share the controller, fields, validators, repository and completion result.
class AmoraaProfileForm extends StatefulWidget {
  const AmoraaProfileForm({
    super.key,
    this.mode = ProfileFormMode.edit,
    this.initialField,
    this.repository,
    required this.onSaved,
  });

  final ProfileFormMode mode;
  final ProfileFormFieldId? initialField;
  final LocalProfileRepository? repository;
  final ProfileFormSaved onSaved;

  @override
  State<AmoraaProfileForm> createState() => _AmoraaProfileFormState();
}

class _AmoraaProfileFormState extends State<AmoraaProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late ProfileFormController _controller;
  late final ProfileFormNavigationTargets _navigationTargets;
  bool _showValidation = false;
  ProfileFormFieldId? _highlightedField;
  int _scrollRequest = 0;
  String? _validationSummary;
  Timer? _highlightTimer;
  bool _loadingCanonicalProfile = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = ProfileFormController(repository: widget.repository)
      ..addListener(_refresh);
    _navigationTargets = ProfileFormNavigationTargets();
    if (AuthService.instance.currentUser != null) {
      _loadingCanonicalProfile = true;
      unawaited(_loadCanonicalProfile());
    }
    if (widget.initialField case final field?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToField(field, requestFocus: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollRequest++;
    _highlightTimer?.cancel();
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _scrollController.dispose();
    _navigationTargets.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCanonicalProfile() async {
    setState(() {
      _loadingCanonicalProfile = true;
      _loadError = null;
    });
    try {
      await _controller.repository.refreshFromServer();
      if (!mounted) return;
      _controller
        ..removeListener(_refresh)
        ..dispose();
      _controller = ProfileFormController(repository: widget.repository)
        ..addListener(_refresh);
      setState(() => _loadingCanonicalProfile = false);
      if (widget.initialField case final field?) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToField(field, requestFocus: true);
        });
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCanonicalProfile = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCanonicalProfile = false;
        _loadError = 'Profile could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCanonicalProfile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AmoraAppBar(
          title: 'Edit profile',
          onBack: () => Navigator.of(context).maybePop(),
          maxContentWidth: 820,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            key: ValueKey('own-profile-loading'),
          ),
        ),
      );
    }
    if (_loadError case final message?) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AmoraAppBar(
          title: 'Edit profile',
          onBack: () => Navigator.of(context).maybePop(),
          maxContentWidth: 820,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AmoraSpacing.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  key: const ValueKey('own-profile-load-error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AmoraSpacing.space12),
                AppPrimaryButton(
                  label: 'Retry',
                  onPressed: _loadCanonicalProfile,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final profile = _controller.draftProfile;
    final pending = profile.pendingFields;
    return PopScope<Object?>(
      canPop: !_controller.dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AmoraAppBar(
          title: 'Edit profile',
          subtitle: 'Update your AMORAA story',
          onBack: () => Navigator.of(context).maybePop(),
          maxContentWidth: 820,
          actions: [
            AmoraHeaderActionButton(
              tooltip: 'Preview profile',
              icon: Icons.visibility_rounded,
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(ProfilePreviewScreen.routeName),
            ),
            const SizedBox(width: AmoraSpacing.space4),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: ResponsiveMobileFrame(
            maxWidth: 820,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                key: const PageStorageKey<String>('edit-profile-scroll'),
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AmoraSpacing.space20,
                      AmoraSpacing.space20,
                      AmoraSpacing.space20,
                      AmoraSpacing.space40 +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'All profile details',
                            style: AmoraTextStyles.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space4),
                          Text(
                            'Edit any supported field, then save everything together.',
                            style: AmoraTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (pending.isNotEmpty) ...[
                            const SizedBox(height: AmoraSpacing.space16),
                            _EditPendingSummary(
                              pending: pending,
                              onSelected: (field) =>
                                  _scrollToField(field.id, requestFocus: true),
                            ),
                          ],
                          if (_validationSummary case final message?) ...[
                            const SizedBox(height: AmoraSpacing.space12),
                            _EditValidationSummary(message: message),
                          ],
                          const SizedBox(height: AmoraSpacing.space24),
                          _EditSection(
                            id: ProfileCompletionSectionId.photos,
                            icon: Icons.photo_camera_rounded,
                            title: 'Profile Photos',
                            child: _target(
                              ProfileFormFieldId.photos,
                              'Profile Photos',
                              AmoraaProfilePhotoSection(
                                profile: profile,
                                showError: _showValidation,
                                onManage: _openPhotoManager,
                                onAdd: () =>
                                    _openPhotoManager(openPicker: true),
                              ),
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.basicDetails,
                            icon: Icons.badge_rounded,
                            title: 'Basic Details',
                            child: AmoraaBasicDetailsSection(
                              controller: _controller,
                              showValidation: _showValidation,
                              navigationTargets: _navigationTargets,
                              highlightedField: _highlightedField,
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.workEducation,
                            icon: Icons.work_outline_rounded,
                            title: 'Work & Education',
                            child: AmoraaWorkEducationSection(
                              controller: _controller,
                              navigationTargets: _navigationTargets,
                              highlightedField: _highlightedField,
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.locationIntentions,
                            icon: Icons.favorite_outline_rounded,
                            title: 'Location & Dating Intentions',
                            child: AmoraaLocationIntentionsSection(
                              controller: _controller,
                              navigationTargets: _navigationTargets,
                              highlightedField: _highlightedField,
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.identityDetails,
                            icon: Icons.tune_rounded,
                            title: 'Height, Languages & Religion',
                            child: AmoraaIdentityDetailsSelector(
                              controller: _controller,
                              showValidation: _showValidation,
                              navigationTargets: _navigationTargets,
                              highlightedField: _highlightedField,
                            ),
                          ),
                          _EditSection(
                            id: null,
                            keyName: 'personal-details',
                            icon: Icons.person_search_rounded,
                            title: 'Personal Details',
                            child: AmoraaPersonalPreferencesEditor(
                              controller: _controller,
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.bio,
                            icon: Icons.notes_rounded,
                            title: 'Bio',
                            child: AmoraaProfileBioField(
                              controller: _controller.bio,
                              navigationTargets: _navigationTargets,
                              highlightedField: _highlightedField,
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.interests,
                            icon: Icons.interests_rounded,
                            title: 'Interests',
                            child: _target(
                              ProfileFormFieldId.interests,
                              'Interests',
                              AmoraaInterestsSelector(
                                controller: _controller,
                                showValidation: _showValidation,
                              ),
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.lifestyle,
                            icon: Icons.self_improvement_rounded,
                            title: 'Lifestyle',
                            child: _target(
                              ProfileFormFieldId.lifestyle,
                              'Lifestyle',
                              AmoraaLifestyleSelector(
                                controller: _controller,
                                showValidation: _showValidation,
                              ),
                            ),
                          ),
                          _EditSection(
                            id: ProfileCompletionSectionId.prompt,
                            icon: Icons.forum_outlined,
                            title: 'Profile Prompt',
                            unframed: true,
                            child: AmoraaProfilePromptField(
                              controller: _controller,
                              showValidation: _showValidation,
                              navigationTargets: _navigationTargets,
                              highlightedField: _highlightedField,
                            ),
                          ),
                          _EditSection(
                            id: null,
                            keyName: 'connection-preferences',
                            icon: Icons.favorite_border_rounded,
                            title: 'Connection Preferences',
                            child: AmoraaConnectionPreferencesEditor(
                              controller: _controller,
                            ),
                          ),
                          _EditSection(
                            id: null,
                            icon: Icons.verified_user_rounded,
                            title: 'Verification',
                            child: AmoraaVerificationSection(
                              onOpenVerification: () =>
                                  _openNamed(KycVerificationScreen.routeName),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _ProfileSaveBar(
          saving: _controller.saving,
          enabled:
              !_controller.promptEditorActive ||
              ProfileFormValidators.promptAnswer(
                    _controller.promptAnswer.text,
                  ) ==
                  null,
          label: 'Save changes',
          onPressed: _save,
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showValidation = true;
      _validationSummary = null;
    });
    final profile = _controller.draftProfile;
    _formKey.currentState?.validate();
    final errors = ProfileFormValidators.editableProfile(
      profile,
      photoStates: _controller.repository.currentPhotos,
    );
    final customEducationError = ProfileFormValidators.customEducation(
      _controller.education.text,
      _controller.customEducation.text,
    );
    final customOccupationError = ProfileFormValidators.customOccupation(
      _controller.profession.text,
      _controller.customOccupation.text,
    );
    final promptError = _controller.promptEditorActive
        ? ProfileFormValidators.promptAnswer(_controller.promptAnswer.text)
        : null;
    if (errors.isNotEmpty ||
        customOccupationError != null ||
        customEducationError != null ||
        promptError != null ||
        _controller.saving) {
      final firstInvalid = _firstInvalidEditableField(profile);
      final message = errors.isNotEmpty
          ? errors.first
          : customOccupationError ??
                customEducationError ??
                promptError ??
                'Review the highlighted profile field.';
      setState(() => _validationSummary = message);
      if (firstInvalid != null) {
        await _scrollToField(firstInvalid, requestFocus: true);
      }
      return;
    }
    try {
      final saved = await _controller.save();
      if (!mounted) return;
      await widget.onSaved(context, saved);
    } on AuthException catch (error) {
      if (mounted) {
        _showError(error.userMessage);
      }
    } catch (_) {
      if (mounted) {
        _showError('Profile could not be saved. Please try again.');
      }
    }
  }

  ProfileFormFieldId? _firstInvalidEditableField(UserProfile profile) {
    if (ProfileFormValidators.requiredText(profile.name) != null) {
      return ProfileFormFieldId.name;
    }
    if (ProfileFormValidators.dateOfBirth(profile.dateOfBirth) != null) {
      return ProfileFormFieldId.dateOfBirth;
    }
    if (ProfileFormValidators.approvedSelection(
          ProfileFormOptions.normalizeGender(profile.gender),
          ProfileFormOptions.genderOptions,
          'gender',
        ) !=
        null) {
      return ProfileFormFieldId.gender;
    }
    if (ProfileFormValidators.storedOccupation(profile.profession) != null ||
        ProfileFormValidators.customOccupation(
              _controller.profession.text,
              _controller.customOccupation.text,
            ) !=
            null) {
      return ProfileFormFieldId.occupation;
    }
    if (ProfileFormValidators.approvedSelection(
              ProfileFormOptions.normalizeEducation(profile.education),
              ProfileFormOptions.education,
              'education',
            ) !=
            null ||
        ProfileFormValidators.customEducation(
              _controller.education.text,
              _controller.customEducation.text,
            ) !=
            null) {
      return ProfileFormFieldId.education;
    }
    if (ProfileFormOptions.normalizeCity(profile.location).isEmpty) {
      return ProfileFormFieldId.city;
    }
    if (ProfileFormOptions.normalizeDatingIntention(
      profile.datingIntention,
    ).isEmpty) {
      return ProfileFormFieldId.datingIntention;
    }
    if (ProfileFormValidators.bio(profile.bio) != null) {
      return ProfileFormFieldId.bio;
    }
    if (ProfileFormValidators.photos(
          profile,
          photoStates: _controller.repository.currentPhotos,
        ) !=
        null) {
      return ProfileFormFieldId.photos;
    }
    if (ProfileFormValidators.interests(profile) != null) {
      return ProfileFormFieldId.interests;
    }
    if (_controller.promptEditorActive &&
        ProfileFormValidators.promptAnswer(_controller.promptAnswer.text) !=
            null) {
      return ProfileFormFieldId.profilePrompt;
    }
    return null;
  }

  Widget _target(ProfileFormFieldId id, String label, Widget child) {
    return ProfileFormTarget(
      id: id,
      targets: _navigationTargets,
      highlighted: _highlightedField == id,
      label: label,
      child: child,
    );
  }

  Future<void> _scrollToField(
    ProfileFormFieldId id, {
    bool requestFocus = false,
  }) async {
    final request = ++_scrollRequest;
    _highlightTimer?.cancel();
    FocusScope.of(context).unfocus();
    setState(() => _highlightedField = id);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || request != _scrollRequest) return;
    var targetContext = _navigationTargets.keyFor(id).currentContext;
    if (targetContext == null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || request != _scrollRequest) return;
      targetContext = _navigationTargets.keyFor(id).currentContext;
    }
    final renderObject = targetContext?.findRenderObject();
    if (targetContext == null ||
        !targetContext.mounted ||
        renderObject == null ||
        !renderObject.attached ||
        !_scrollController.hasClients) {
      return;
    }
    await _scrollController.position.ensureVisible(
      renderObject,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: .12,
    );
    if (!mounted || request != _scrollRequest) return;
    if (requestFocus) {
      _navigationTargets.focusNodeFor(id)?.requestFocus();
    }
    _highlightTimer = Timer(const Duration(milliseconds: 950), () {
      if (!mounted || request != _scrollRequest) return;
      setState(() => _highlightedField = null);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openNamed(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) _controller.refreshExternalProfile();
  }

  Future<void> _openPhotoManager({bool openPicker = false}) async {
    if (openPicker) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PhotoManagerScreen(openPickerOnStart: true),
        ),
      );
    } else {
      await Navigator.of(context).pushNamed(PhotoManagerScreen.routeName);
    }
    if (mounted) _controller.refreshExternalProfile();
  }

  Future<void> _confirmDiscard() async {
    if (_controller.saving) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'Your latest profile edits have not been saved yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    Navigator.of(context).pop();
  }
}

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.child,
    this.unframed = false,
    this.keyName,
  });

  final ProfileCompletionSectionId? id;
  final IconData icon;
  final String title;
  final Widget child;
  final bool unframed;
  final String? keyName;

  String get _keyName => keyName ?? id?.name ?? 'verification';

  @override
  Widget build(BuildContext context) {
    if (unframed) {
      return KeyedSubtree(
        key: ValueKey('edit-section-$_keyName'),
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: AmoraSpacing.space16,
            left: AmoraSpacing.space4,
            right: AmoraSpacing.space4,
          ),
          child: child,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AmoraSpacing.space16),
      child: PremiumCard(
        key: ValueKey('edit-section-$_keyName'),
        radius: 22,
        padding: const EdgeInsets.all(AmoraSpacing.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: AmoraSpacing.minimumTouchTarget,
                  height: AmoraSpacing.minimumTouchTarget,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(child: Text(title, style: AmoraTextStyles.titleLarge)),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EditPendingSummary extends StatelessWidget {
  const _EditPendingSummary({required this.pending, required this.onSelected});

  final List<ProfilePendingField> pending;
  final ValueChanged<ProfilePendingField> onSelected;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('edit-profile-pending-summary'),
      radius: 20,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Information still pending', style: AmoraTextStyles.titleMedium),
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            'Choose an item to go directly to its field.',
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          for (final field in pending)
            Semantics(
              button: true,
              label: '${field.actionLabel}, incomplete profile field',
              child: InkWell(
                key: ValueKey('edit-pending-${field.id.name}'),
                onTap: () => onSelected(field),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AmoraSpacing.minimumTouchTarget,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded),
                      const SizedBox(width: AmoraSpacing.space8),
                      Expanded(child: Text(field.actionLabel)),
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

class _EditValidationSummary extends StatelessWidget {
  const _EditValidationSummary({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('edit-profile-validation-summary'),
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: .34),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ProfileSaveBar extends StatelessWidget {
  const _ProfileSaveBar({
    required this.saving,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool saving;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: AppColors.primary.withValues(alpha: .12),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: AppPrimaryButton(
                key: const ValueKey('profile-save-button'),
                label: label,
                icon: Icons.check_rounded,
                isLoading: saving,
                onPressed: saving || !enabled ? null : onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
