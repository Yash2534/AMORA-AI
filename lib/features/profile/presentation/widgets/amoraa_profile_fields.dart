import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/features/discover/presentation/widgets/amoraa_minimum_height_picker.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_form_navigation.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_dating_intention_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_language_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_prompt_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraaProfilePhotoSection extends StatelessWidget {
  const AmoraaProfilePhotoSection({
    super.key,
    required this.profile,
    required this.onManage,
    this.onAdd,
    this.showError = false,
  });

  final UserProfile profile;
  final VoidCallback onManage;
  final VoidCallback? onAdd;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final error = showError ? ProfileFormValidators.photos(profile) : null;
    final sharedPhotos = LocalProfileRepository.instance.currentPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile.photos.isEmpty)
          _InlineEmptyState(
            icon: Icons.add_a_photo_rounded,
            label: 'Add at least two profile photos',
            actionLabel: 'Add Photo',
            onAction: onAdd ?? onManage,
          )
        else
          SizedBox(
            height: 128,
            child: ListView.separated(
              key: const PageStorageKey<String>('profile-form-photo-list'),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: profile.photos.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AmoraSpacing.space12),
              itemBuilder: (context, index) {
                final primary = index == profile.primaryPhotoIndex;
                final source = profile.photos[index];
                final photo = sharedPhotos
                    .where((candidate) => candidate.source == source)
                    .firstOrNull;
                final viewPhoto =
                    photo ??
                    ProfilePhotoViewData(
                      id: 'profile-form-photo-$index',
                      source: source,
                      order: index,
                      isPrimary: primary,
                      uploadState: ProfilePhotoUploadState.bundled,
                    );
                return Stack(
                  children: [
                    AmoraaProfilePhotoView(
                      photo: viewPhoto,
                      width: 98,
                      height: 128,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(18),
                      semanticLabel: 'Profile photo ${index + 1}',
                    ),
                    if (primary)
                      Positioned(
                        left: 7,
                        bottom: 7,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AmoraRadius.pillBorder,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AmoraSpacing.space8,
                              vertical: AmoraSpacing.space4,
                            ),
                            child: Text(
                              'Primary',
                              style: AmoraTextStyles.labelSmall.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: AmoraSpacing.space12),
        Wrap(
          spacing: AmoraSpacing.space8,
          runSpacing: AmoraSpacing.space8,
          children: [
            if (profile.photos.isNotEmpty && profile.photos.length < 6)
              TextButton.icon(
                key: const ValueKey('profile-add-photo-action'),
                onPressed: onAdd ?? onManage,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Add Photo'),
              ),
            TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Manage photos'),
            ),
          ],
        ),
        if (error != null) _FormError(error),
      ],
    );
  }
}

class AmoraaBasicDetailsSection extends StatelessWidget {
  const AmoraaBasicDetailsSection({
    super.key,
    required this.controller,
    required this.showValidation,
    this.navigationTargets,
    this.highlightedField,
  });

  final ProfileFormController controller;
  final bool showValidation;
  final ProfileFormNavigationTargets? navigationTargets;
  final ProfileFormFieldId? highlightedField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _profileTarget(
          id: ProfileFormFieldId.name,
          label: 'Full Name',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: TextFormField(
            key: const ValueKey('profile-name-field'),
            controller: controller.name,
            focusNode: navigationTargets?.focusNodeFor(ProfileFormFieldId.name),
            textInputAction: TextInputAction.next,
            validator: ProfileFormValidators.requiredText,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        _profileTarget(
          id: ProfileFormFieldId.dateOfBirth,
          label: 'Date of Birth',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraDobField(
            value: controller.birthDate,
            errorText: showValidation
                ? ProfileFormValidators.dateOfBirth(controller.birthDate)
                : null,
            onChanged: controller.setBirthDate,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        _profileTarget(
          id: ProfileFormFieldId.gender,
          label: 'Gender',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaSelectField<String>(
            key: const ValueKey('profile-gender-field'),
            value: ProfileFormOptions.genderOptions.contains(controller.gender)
                ? controller.gender
                : null,
            label: 'Gender',
            hintText: 'Select gender',
            prefixIcon: Icons.person_outline_rounded,
            isRequired: true,
            validator: ProfileFormValidators.requiredText,
            options: [
              for (final value in ProfileFormOptions.genderOptions)
                AmoraaSelectOption(value: value, label: value),
            ],
            onChanged: (value) {
              if (value != null) controller.setGender(value);
            },
          ),
        ),
      ],
    );
  }
}

class AmoraaWorkEducationSection extends StatelessWidget {
  const AmoraaWorkEducationSection({
    super.key,
    required this.controller,
    this.navigationTargets,
    this.highlightedField,
  });

  final ProfileFormController controller;
  final ProfileFormNavigationTargets? navigationTargets;
  final ProfileFormFieldId? highlightedField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _profileTarget(
          id: ProfileFormFieldId.occupation,
          label: 'Occupation',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaSearchableSelect<String>(
            key: const ValueKey('profile-occupation-field'),
            value: controller.profession.text.isEmpty
                ? null
                : controller.profession.text,
            label: 'Occupation',
            hintText: 'Select occupation',
            searchHint: 'Search occupation',
            prefixIcon: Icons.work_rounded,
            isRequired: true,
            validator: ProfileFormValidators.requiredText,
            options: [
              for (final value in ProfileFormOptions.occupations)
                AmoraaSelectOption(value: value, label: value),
            ],
            onChanged: (value) {
              if (value != null) controller.profession.text = value;
            },
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        TextFormField(
          controller: controller.company,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Company (optional)',
            prefixIcon: Icon(Icons.business_rounded),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        _profileTarget(
          id: ProfileFormFieldId.education,
          label: 'Education',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaSelectField<String>(
            key: const ValueKey('profile-education-field'),
            value: controller.education.text.isEmpty
                ? null
                : controller.education.text,
            label: 'Education',
            hintText: 'Select education',
            prefixIcon: Icons.school_rounded,
            isRequired: true,
            validator: ProfileFormValidators.requiredText,
            options: [
              for (final value in ProfileFormOptions.education)
                AmoraaSelectOption(value: value, label: value),
            ],
            onChanged: (value) {
              if (value != null) controller.setEducation(value);
            },
          ),
        ),
        if (controller.education.text == 'Other') ...[
          const SizedBox(height: AmoraSpacing.space12),
          TextFormField(
            key: const ValueKey('profile-custom-education-field'),
            controller: controller.customEducation,
            maxLength: ProfileFormOptions.customEducationMaxLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                ProfileFormOptions.customEducationMaxLength,
              ),
            ],
            validator: (value) => ProfileFormValidators.customEducation(
              controller.education.text,
              value,
            ),
            decoration: const InputDecoration(
              labelText: 'Specify education',
              hintText: 'Enter your education',
              prefixIcon: Icon(Icons.edit_note_rounded),
              counterText: '',
            ),
          ),
        ],
      ],
    );
  }
}

class AmoraaLocationIntentionsSection extends StatelessWidget {
  const AmoraaLocationIntentionsSection({
    super.key,
    required this.controller,
    this.navigationTargets,
    this.highlightedField,
  });

  final ProfileFormController controller;
  final ProfileFormNavigationTargets? navigationTargets;
  final ProfileFormFieldId? highlightedField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _profileTarget(
          id: ProfileFormFieldId.city,
          label: 'City',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaSearchableSelect<String>(
            key: const ValueKey('profile-city-field'),
            value: controller.city.text.isEmpty ? null : controller.city.text,
            label: 'City',
            hintText: 'Select city',
            searchHint: 'Search city',
            prefixIcon: Icons.location_on_rounded,
            isRequired: true,
            validator: ProfileFormValidators.requiredText,
            options: [
              for (final value in ProfileFormOptions.cities)
                AmoraaSelectOption(value: value, label: value),
            ],
            onChanged: (value) {
              if (value != null) controller.city.text = value;
            },
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        _profileTarget(
          id: ProfileFormFieldId.datingIntention,
          label: 'Dating Intention',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaDatingIntentionSelector(
            value: controller.datingIntention.text,
            onChanged: (value) => controller.datingIntention.text = value,
          ),
        ),
      ],
    );
  }
}

class AmoraaIdentityDetailsSelector extends StatelessWidget {
  const AmoraaIdentityDetailsSelector({
    super.key,
    required this.controller,
    this.showValidation = false,
    this.navigationTargets,
    this.highlightedField,
  });

  final ProfileFormController controller;
  final bool showValidation;
  final ProfileFormNavigationTargets? navigationTargets;
  final ProfileFormFieldId? highlightedField;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _profileTarget(
          id: ProfileFormFieldId.height,
          label: 'Height',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: _ProfileHeightSelector(
            controller: controller,
            showValidation: showValidation,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        _profileTarget(
          id: ProfileFormFieldId.languages,
          label: 'Languages',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaLanguageSelector(
            selectedLanguages: controller.languages,
            onChanged: controller.setLanguages,
            showError: showValidation,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        _profileTarget(
          id: ProfileFormFieldId.religion,
          label: 'Religion',
          targets: navigationTargets,
          highlightedField: highlightedField,
          child: AmoraaSelectField<String>(
            key: const ValueKey('profile-religion-field'),
            label: 'Religion',
            value:
                ProfileFormOptions.normalizeReligion(
                  controller.lifestyle['Religion'],
                ).isEmpty
                ? null
                : ProfileFormOptions.normalizeReligion(
                    controller.lifestyle['Religion'],
                  ),
            hintText: 'Select religion',
            prefixIcon: Icons.diversity_3_rounded,
            isRequired: true,
            validator: (value) => ProfileFormValidators.approvedSelection(
              value,
              ProfileFormOptions.religions,
              'religion',
            ),
            errorText: showValidation
                ? ProfileFormValidators.approvedSelection(
                    controller.lifestyle['Religion'],
                    ProfileFormOptions.religions,
                    'religion',
                  )
                : null,
            options: [
              for (final value in ProfileFormOptions.religions)
                AmoraaSelectOption(value: value, label: value),
            ],
            onChanged: (value) => controller.setLifestyle('Religion', value),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeightSelector extends StatelessWidget {
  const _ProfileHeightSelector({
    required this.controller,
    required this.showValidation,
  });

  final ProfileFormController controller;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    final centimeters = ProfileFormOptions.parseHeightCentimeters(
      controller.lifestyle['Height'],
    );
    final value = centimeters == null
        ? ''
        : ProfileFormOptions.formatProfileHeight(centimeters);
    return FormField<String>(
      key: const ValueKey('profile-height-field'),
      initialValue: value,
      validator: (current) =>
          ProfileFormValidators.identityValue(current, 'height'),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: value.isEmpty ? 'Choose height' : 'Height, $value',
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : AppColors.tertiary,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  final selected = await showModalBottomSheet<int>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.transparent,
                    builder: (sheetContext) => AmoraaMinimumHeightPicker(
                      purpose: HeightPickerPurpose.profileHeight,
                      initialMinimumCentimeters: centimeters,
                      onClose: () => Navigator.of(sheetContext).pop(),
                      onApply: (next) => Navigator.of(sheetContext).pop(next),
                    ),
                  );
                  if (selected == null) return;
                  final next = ProfileFormOptions.formatProfileHeight(selected);
                  field.didChange(next);
                  controller.setLifestyle('Height', next);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AmoraSpacing.space16),
                  child: Row(
                    children: [
                      const Icon(Icons.height_rounded),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Height', style: AmoraTextStyles.labelMedium),
                            const SizedBox(height: AmoraSpacing.space4),
                            Text(
                              value.isEmpty ? 'Choose height' : value,
                              style: AmoraTextStyles.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showValidation && field.errorText != null)
            _FormError(field.errorText!),
        ],
      ),
    );
  }
}

class AmoraaProfileBioField extends StatelessWidget {
  const AmoraaProfileBioField({
    super.key,
    required this.controller,
    this.navigationTargets,
    this.highlightedField,
  });

  final TextEditingController controller;
  final ProfileFormNavigationTargets? navigationTargets;
  final ProfileFormFieldId? highlightedField;

  @override
  Widget build(BuildContext context) {
    return _profileTarget(
      id: ProfileFormFieldId.bio,
      label: 'Bio',
      targets: navigationTargets,
      highlightedField: highlightedField,
      child: TextFormField(
        key: const ValueKey('profile-bio-field'),
        controller: controller,
        focusNode: navigationTargets?.focusNodeFor(ProfileFormFieldId.bio),
        minLines: 5,
        maxLines: 8,
        maxLength: 240,
        inputFormatters: [LengthLimitingTextInputFormatter(240)],
        validator: ProfileFormValidators.bio,
        decoration: const InputDecoration(
          labelText: 'Bio',
          hintText: 'Tell people what life with you feels like',
          prefixIcon: Icon(Icons.notes_rounded),
          counterText: '',
        ),
      ),
    );
  }
}

class AmoraaInterestsSelector extends StatelessWidget {
  const AmoraaInterestsSelector({
    super.key,
    required this.controller,
    this.showValidation = false,
  });

  final ProfileFormController controller;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    final error = showValidation
        ? ProfileFormValidators.interests(controller.draftProfile)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${controller.interests.length}/10 selected',
          style: AmoraTextStyles.labelLarge,
        ),
        const SizedBox(height: AmoraSpacing.space16),
        for (final group in ProfileFormOptions.interestGroups.entries) ...[
          Text(group.key, style: AmoraTextStyles.titleMedium),
          const SizedBox(height: AmoraSpacing.space8),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              for (final item in group.value)
                FilterChip(
                  label: Text(item),
                  selected: controller.interests.contains(item),
                  showCheckmark: false,
                  avatar: controller.interests.contains(item)
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  onSelected: (selected) =>
                      controller.toggleInterest(item, selected),
                ),
            ],
          ),
          if (group.key != ProfileFormOptions.interestGroups.keys.last)
            const SizedBox(height: AmoraSpacing.space16),
        ],
        if (error != null) _FormError(error),
      ],
    );
  }
}

class AmoraaLifestyleSelector extends StatelessWidget {
  const AmoraaLifestyleSelector({
    super.key,
    required this.controller,
    this.showValidation = false,
  });

  final ProfileFormController controller;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    final hasSelection = ProfileFormOptions.lifestyleOptions.keys.any(
      controller.lifestyle.containsKey,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in ProfileFormOptions.lifestyleOptions.entries) ...[
          Text(entry.key, style: AmoraTextStyles.titleMedium),
          const SizedBox(height: AmoraSpacing.space8),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              for (final value in entry.value)
                ChoiceChip(
                  label: Text(value),
                  selected: controller.lifestyle[entry.key] == value,
                  showCheckmark: false,
                  onSelected: (_) => controller.setLifestyle(entry.key, value),
                ),
            ],
          ),
          if (entry.key != ProfileFormOptions.lifestyleOptions.keys.last)
            const SizedBox(height: AmoraSpacing.space16),
        ],
        if (showValidation && !hasSelection)
          const _FormError('Choose at least one lifestyle preference'),
      ],
    );
  }
}

class AmoraaProfilePromptField extends StatelessWidget {
  const AmoraaProfilePromptField({
    super.key,
    required this.controller,
    this.showValidation = false,
    this.navigationTargets,
    this.highlightedField,
  });

  final ProfileFormController controller;
  final bool showValidation;
  final ProfileFormNavigationTargets? navigationTargets;
  final ProfileFormFieldId? highlightedField;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final saved = controller.savedPrompts.entries.toList(growable: false);
    return _profileTarget(
      id: ProfileFormFieldId.profilePrompt,
      label: 'Profile Prompts',
      targets: navigationTargets,
      highlightedField: highlightedField,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < saved.length; index++) ...[
            _SavedProfilePromptCard(
              key: ValueKey('saved-profile-prompt-$index'),
              prompt: saved[index].key,
              answer: saved[index].value,
              editing:
                  controller.promptEditorActive &&
                  controller.promptEditingOriginalTitle == saved[index].key,
              onEdit: () {
                controller.beginEditPrompt(saved[index].key);
                _focusPromptAnswer();
              },
            ),
            const SizedBox(height: AmoraSpacing.space12),
          ],
          if (controller.promptEditorActive) ...[
            Semantics(
              container: true,
              label: 'Profile prompt editor',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AmoraaProfilePromptSelector(
                    selectedPrompt: controller.promptTitle,
                    options: {
                      ...controller.availablePromptTitles,
                      controller.promptTitle,
                    },
                    onSelected: controller.setPromptTitle,
                  ),
                  const SizedBox(height: AmoraSpacing.space12),
                  TextFormField(
                    key: const ValueKey('profile-prompt-answer-field'),
                    controller: controller.promptAnswer,
                    focusNode: navigationTargets?.focusNodeFor(
                      ProfileFormFieldId.profilePrompt,
                    ),
                    minLines: 3,
                    maxLines: 6,
                    maxLength: ProfileFormOptions.profilePromptAnswerMaxLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        ProfileFormOptions.profilePromptAnswerMaxLength,
                      ),
                    ],
                    validator: ProfileFormValidators.promptAnswer,
                    autovalidateMode: showValidation
                        ? AutovalidateMode.always
                        : AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Your answer',
                      hintText: 'Write a specific, warm answer',
                      counterText: '',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('cancel-profile-prompt-edit'),
                      onPressed: controller.cancelPromptEditing,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (controller.canAddPrompt)
            OutlinedButton.icon(
              key: const ValueKey('add-profile-prompt'),
              onPressed: () => showAmoraaProfilePromptPicker(
                context,
                selectedPrompt: '',
                options: controller.availablePromptTitles,
                onSelected: (prompt) {
                  controller.beginAddPrompt(prompt);
                  _focusPromptAnswer();
                },
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Prompt'),
            ),
          if (showValidation && saved.isEmpty && !controller.promptEditorActive)
            const _FormError('Complete one profile prompt'),
        ],
      ),
    );
  }

  void _focusPromptAnswer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationTargets
          ?.focusNodeFor(ProfileFormFieldId.profilePrompt)
          ?.requestFocus();
    });
  }
}

class _SavedProfilePromptCard extends StatelessWidget {
  const _SavedProfilePromptCard({
    super.key,
    required this.prompt,
    required this.answer,
    required this.editing,
    required this.onEdit,
  });

  final String prompt;
  final String answer;
  final bool editing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Prompt, $prompt. Answer, $answer${editing ? '. Editing' : ''}',
      child: SizedBox(
        width: double.infinity,
        child: PremiumCard(
          radius: 18,
          padding: const EdgeInsets.all(AmoraSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Prompt', style: AmoraTextStyles.labelMedium),
              const SizedBox(height: AmoraSpacing.space4),
              Text(prompt, style: AmoraTextStyles.titleMedium),
              const SizedBox(height: AmoraSpacing.space12),
              Text('Answer', style: AmoraTextStyles.labelMedium),
              const SizedBox(height: AmoraSpacing.space4),
              Text(answer, style: AmoraTextStyles.bodyMedium),
              const SizedBox(height: AmoraSpacing.space8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(
                    editing ? Icons.edit_rounded : Icons.edit_outlined,
                  ),
                  label: Text(editing ? 'Editing' : 'Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmoraaVerificationSection extends StatelessWidget {
  const AmoraaVerificationSection({
    super.key,
    required this.onOpenVerification,
  });

  final VoidCallback onOpenVerification;

  @override
  Widget build(BuildContext context) {
    return _InlineEmptyState(
      icon: Icons.verified_user_outlined,
      label: 'Verification is managed through AMORAA’s secure KYC flow.',
      actionLabel: 'Review verification',
      onAction: onOpenVerification,
    );
  }
}

Widget _profileTarget({
  required ProfileFormFieldId id,
  required String label,
  required ProfileFormNavigationTargets? targets,
  required ProfileFormFieldId? highlightedField,
  required Widget child,
}) {
  if (targets == null) return child;
  return ProfileFormTarget(
    id: id,
    targets: targets,
    highlighted: highlightedField == id,
    label: label,
    child: child,
  );
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AmoraTextStyles.bodyMedium),
              const SizedBox(height: AmoraSpacing.space8),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space8),
      child: Text(
        message,
        style: AmoraTextStyles.bodySmall.copyWith(color: AppColors.primary),
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
