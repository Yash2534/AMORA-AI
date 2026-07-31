import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';

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

  static String? identityValue(String? value, String label) =>
      requiredText(value) == null ? null : 'Select $label';

  static List<String> profile(UserProfile profile) {
    final errors = <String>[
      ?requiredText(profile.name),
      ?dateOfBirth(profile.dateOfBirth),
      ?requiredText(profile.gender),
      ?requiredText(profile.profession),
      ?requiredText(profile.education),
      ?requiredText(profile.location),
      ?requiredText(profile.datingIntention),
      ?identityValue(profile.lifestyle['Height'], 'height'),
      ?identityValue(profile.lifestyle['Languages'], 'languages'),
      ?identityValue(profile.lifestyle['Religion'], 'religion'),
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
    ?requiredText(profile.gender),
    ?requiredText(profile.profession),
    ?requiredText(profile.education),
    ?requiredText(profile.location),
    ?requiredText(profile.datingIntention),
    ?bio(profile.bio),
  ];
}
