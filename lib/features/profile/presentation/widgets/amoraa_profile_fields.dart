import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/features/onboarding/data/gujarat_cities.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraaProfilePhotoSection extends StatelessWidget {
  const AmoraaProfilePhotoSection({
    super.key,
    required this.profile,
    required this.onManage,
    this.showError = false,
  });

  final UserProfile profile;
  final VoidCallback onManage;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final error = showError ? ProfileFormValidators.photos(profile) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile.photos.isEmpty)
          _InlineEmptyState(
            icon: Icons.add_a_photo_rounded,
            label: 'Add at least two profile photos',
            actionLabel: 'Open Photo Manager',
            onAction: onManage,
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
                return Stack(
                  children: [
                    AmoraProfileImage(
                      imageUrl: profile.photos[index],
                      assetPath: profile.photos[index],
                      initials: 'AM',
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onManage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Manage photos'),
          ),
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
  });

  final ProfileFormController controller;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: const ValueKey('profile-name-field'),
          controller: controller.name,
          textInputAction: TextInputAction.next,
          validator: ProfileFormValidators.requiredText,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_rounded),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        AmoraDobField(
          value: controller.birthDate,
          errorText: showValidation
              ? ProfileFormValidators.dateOfBirth(controller.birthDate)
              : null,
          onChanged: controller.setBirthDate,
        ),
        const SizedBox(height: AmoraSpacing.space12),
        DropdownButtonFormField<String>(
          key: const ValueKey('profile-gender-field'),
          initialValue: const ['Male', 'Female'].contains(controller.gender)
              ? controller.gender
              : null,
          isExpanded: true,
          validator: ProfileFormValidators.requiredText,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          items: const ['Male', 'Female']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) controller.setGender(value);
          },
        ),
      ],
    );
  }
}

class AmoraaWorkEducationSection extends StatelessWidget {
  const AmoraaWorkEducationSection({super.key, required this.controller});

  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AmoraaSearchableDropdown(
          key: const ValueKey('profile-occupation-field'),
          controller: controller.profession,
          label: 'Occupation',
          icon: Icons.work_rounded,
          options: ProfileFormOptions.occupations,
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
        AmoraaSearchableDropdown(
          key: const ValueKey('profile-education-field'),
          controller: controller.education,
          label: 'Education',
          icon: Icons.school_rounded,
          options: ProfileFormOptions.education,
        ),
      ],
    );
  }
}

class AmoraaLocationIntentionsSection extends StatelessWidget {
  const AmoraaLocationIntentionsSection({super.key, required this.controller});

  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    final intention =
        ProfileFormOptions.datingIntentions.contains(
          controller.datingIntention.text,
        )
        ? controller.datingIntention.text
        : null;
    return Column(
      children: [
        AmoraaSearchableDropdown(
          key: const ValueKey('profile-city-field'),
          controller: controller.city,
          label: 'City',
          icon: Icons.location_on_rounded,
          options: gujaratCities,
        ),
        const SizedBox(height: AmoraSpacing.space12),
        DropdownButtonFormField<String>(
          key: const ValueKey('profile-dating-intention-field'),
          initialValue: intention,
          isExpanded: true,
          validator: ProfileFormValidators.requiredText,
          decoration: const InputDecoration(
            labelText: 'Dating Intention',
            prefixIcon: Icon(Icons.favorite_outline_rounded),
          ),
          items: ProfileFormOptions.datingIntentions
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) controller.datingIntention.text = value;
          },
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
  });

  final ProfileFormController controller;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in ProfileFormOptions.identityOptions.entries) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('profile-${entry.key.toLowerCase()}-field'),
            initialValue: entry.value.contains(controller.lifestyle[entry.key])
                ? controller.lifestyle[entry.key]
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: entry.key,
              prefixIcon: Icon(_identityIcon(entry.key)),
              errorText: showValidation
                  ? ProfileFormValidators.identityValue(
                      controller.lifestyle[entry.key],
                      entry.key.toLowerCase(),
                    )
                  : null,
            ),
            items: entry.value
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => controller.setLifestyle(entry.key, value),
          ),
          if (entry.key != ProfileFormOptions.identityOptions.keys.last)
            const SizedBox(height: AmoraSpacing.space12),
        ],
      ],
    );
  }

  IconData _identityIcon(String key) => switch (key) {
    'Height' => Icons.height_rounded,
    'Languages' => Icons.translate_rounded,
    _ => Icons.diversity_3_rounded,
  };
}

class AmoraaProfileBioField extends StatelessWidget {
  const AmoraaProfileBioField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('profile-bio-field'),
      controller: controller,
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
  });

  final ProfileFormController controller;
  final bool showValidation;

  @override
  Widget build(BuildContext context) {
    final promptTitles = <String>{
      ...ProfileFormOptions.promptTitles,
      controller.promptTitle,
    };
    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: const ValueKey('profile-prompt-selector'),
          initialValue: controller.promptTitle,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Prompt'),
          items: promptTitles
              .map(
                (title) => DropdownMenuItem(
                  value: title,
                  child: Text(title, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) controller.setPromptTitle(value);
          },
        ),
        const SizedBox(height: AmoraSpacing.space12),
        TextFormField(
          key: const ValueKey('profile-prompt-answer-field'),
          controller: controller.promptAnswer,
          minLines: 2,
          maxLines: 4,
          maxLength: 180,
          inputFormatters: [LengthLimitingTextInputFormatter(180)],
          decoration: InputDecoration(
            labelText: 'Your answer',
            hintText: 'Write a specific, warm answer',
            errorText:
                showValidation && controller.promptAnswer.text.trim().isEmpty
                ? 'Complete one profile prompt'
                : null,
          ),
        ),
      ],
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

class AmoraaSearchableDropdown extends StatelessWidget {
  const AmoraaSearchableDropdown({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.options,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<String>(
        controller: controller,
        width: constraints.maxWidth,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        leadingIcon: Icon(icon),
        label: Text(label),
        hintText: 'Search $label',
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
        ),
        menuStyle: MenuStyle(
          maximumSize: const WidgetStatePropertyAll(Size.fromHeight(320)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        dropdownMenuEntries: options
            .map(
              (value) => DropdownMenuEntry<String>(value: value, label: value),
            )
            .toList(growable: false),
        onSelected: (value) {
          if (value != null) controller.text = value;
        },
      ),
    );
  }
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
