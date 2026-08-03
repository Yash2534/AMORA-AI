import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';

abstract final class ProfileFormValidators {
  static String? requiredText(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  static String? bio(String? value) {
    return (value ?? '').trim().length < 40
        ? 'Use at least 40 characters'
        : null;
  }

  static String? dateOfBirth(DateTime? value) {
    return AmoraDateOfBirth.validate(value);
  }

  static String? photos(UserProfile profile) =>
      profile.photos.length < 2 ? 'Add at least two profile photos' : null;

  static String? interests(UserProfile profile) {
    final count = profile.completionResult.sections
        .firstWhere((section) => section.title == 'Interests')
        .completedFields;
    return count < 5 ? 'Choose at least five interests' : null;
  }

  static String? prompt(UserProfile profile) =>
      profile.completedPromptCount < 1 ? 'Complete one profile prompt' : null;

  static String? promptAnswer(String? value) {
    final answer = value?.trim() ?? '';
    if (answer.isEmpty) return 'Write an answer for this prompt';
    if (answer.length > ProfileFormOptions.profilePromptAnswerMaxLength) {
      return 'Use ${ProfileFormOptions.profilePromptAnswerMaxLength} characters or fewer';
    }
    return null;
  }

  static String? identityValue(String? value, String label) =>
      requiredText(value) == null ? null : 'Select $label';

  static String? approvedSelection(
    String? value,
    List<String> options,
    String label,
  ) => options.contains(value?.trim()) ? null : 'Select $label';

  static String? customEducation(String? selected, String? customValue) {
    if (selected != 'Other') return null;
    final value = customValue?.trim() ?? '';
    if (value.isEmpty) return 'Specify education';
    if (value.length > ProfileFormOptions.customEducationMaxLength) {
      return 'Use ${ProfileFormOptions.customEducationMaxLength} characters or fewer';
    }
    return null;
  }

  static List<String> profile(UserProfile profile) {
    final errors = <String>[
      ?requiredText(profile.name),
      ?dateOfBirth(profile.dateOfBirth),
      ?approvedSelection(
        ProfileFormOptions.normalizeGender(profile.gender),
        ProfileFormOptions.genderOptions,
        'gender',
      ),
      ?approvedSelection(
        profile.profession,
        ProfileFormOptions.occupations,
        'occupation',
      ),
      ?approvedSelection(
        ProfileFormOptions.normalizeEducation(profile.education),
        ProfileFormOptions.education,
        'education',
      ),
      ?approvedSelection(
        ProfileFormOptions.normalizeCity(profile.location),
        ProfileFormOptions.cities,
        'city',
      ),
      ?approvedSelection(
        ProfileFormOptions.normalizeDatingIntention(profile.datingIntention),
        ProfileFormOptions.datingIntentions,
        'dating intention',
      ),
      if (ProfileFormOptions.parseHeightCentimeters(
            profile.lifestyle['Height'],
          ) ==
          null)
        'Select height',
      ?identityValue(profile.lifestyle['Languages'], 'languages'),
      ?approvedSelection(
        profile.lifestyle['Religion'],
        ProfileFormOptions.religions,
        'religion',
      ),
      ?bio(profile.bio),
      ?photos(profile),
      ?interests(profile),
      ?prompt(profile),
      if (!profile.completionResult.sections
          .firstWhere((section) => section.title == 'Lifestyle')
          .isComplete)
        'Choose at least one lifestyle preference',
    ];
    return errors;
  }

  static List<String> editableProfile(UserProfile profile) => <String>[
    ?requiredText(profile.name),
    ?dateOfBirth(profile.dateOfBirth),
    ?approvedSelection(
      ProfileFormOptions.normalizeGender(profile.gender),
      ProfileFormOptions.genderOptions,
      'gender',
    ),
    ?approvedSelection(
      profile.profession,
      ProfileFormOptions.occupations,
      'occupation',
    ),
    ?approvedSelection(
      ProfileFormOptions.normalizeEducation(profile.education),
      ProfileFormOptions.education,
      'education',
    ),
    ?approvedSelection(
      ProfileFormOptions.normalizeCity(profile.location),
      ProfileFormOptions.cities,
      'city',
    ),
    ?approvedSelection(
      ProfileFormOptions.normalizeDatingIntention(profile.datingIntention),
      ProfileFormOptions.datingIntentions,
      'dating intention',
    ),
    ?bio(profile.bio),
  ];
}
