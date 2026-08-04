import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';

abstract final class ProfileFormValidators {
  static const int minimumPhotoCount = 2;
  static const int minimumInterestCount = 5;

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

  static int validPhotoCount(
    UserProfile profile, {
    Iterable<ProfilePhotoViewData>? photoStates,
  }) {
    final statesBySource = <String, ProfilePhotoViewData>{
      for (final photo in photoStates ?? const <ProfilePhotoViewData>[])
        photo.source.trim(): photo,
    };
    final validSources = <String>{};
    for (final rawSource in profile.photos) {
      final source = rawSource.trim();
      if (source.isEmpty || !_isUsablePhotoSource(source)) continue;
      final photo = statesBySource[source];
      if (photo?.uploadState == ProfilePhotoUploadState.deleting) continue;
      if (photo?.uploadState == ProfilePhotoUploadState.failed &&
          !_hasUsableLocalPreview(photo!)) {
        continue;
      }
      validSources.add(source);
    }
    return validSources.length;
  }

  static String? photos(
    UserProfile profile, {
    Iterable<ProfilePhotoViewData>? photoStates,
  }) => validPhotoCount(profile, photoStates: photoStates) < minimumPhotoCount
      ? 'Add at least 2 profile photos before saving.'
      : null;

  static String? interests(UserProfile profile) {
    return ProfileInterestPolicy.visibleCount(profile.interests) <
            minimumInterestCount
        ? 'Select at least 5 interests before saving.'
        : null;
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

  static String? customOccupation(String? selected, String? customValue) {
    if (selected != 'Other') return null;
    final value = customValue?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your occupation.';
    if (value.length > ProfileFormOptions.customOccupationMaxLength) {
      return 'Use ${ProfileFormOptions.customOccupationMaxLength} characters or fewer';
    }
    return null;
  }

  static String? storedOccupation(String? value) =>
      ProfileFormOptions.isValidStoredOccupation(value)
      ? null
      : 'Select occupation';

  static List<String> profile(UserProfile profile) {
    final errors = <String>[
      ?requiredText(profile.name),
      ?dateOfBirth(profile.dateOfBirth),
      ?approvedSelection(
        ProfileFormOptions.normalizeGender(profile.gender),
        ProfileFormOptions.genderOptions,
        'gender',
      ),
      ?storedOccupation(profile.profession),
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

  static List<String> editableProfile(
    UserProfile profile, {
    Iterable<ProfilePhotoViewData>? photoStates,
  }) => <String>[
    ?requiredText(profile.name),
    ?dateOfBirth(profile.dateOfBirth),
    ?approvedSelection(
      ProfileFormOptions.normalizeGender(profile.gender),
      ProfileFormOptions.genderOptions,
      'gender',
    ),
    ?storedOccupation(profile.profession),
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
    ?photos(profile, photoStates: photoStates),
    ?interests(profile),
  ];

  static bool _isUsablePhotoSource(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('placeholder') ||
        normalized.contains('profile_fallback') ||
        normalized.contains('add_photo') ||
        normalized.contains('add-photo')) {
      return false;
    }
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('file://') ||
        normalized.startsWith('/') ||
        RegExp(r'^[a-z]:[\\/]').hasMatch(normalized)) {
      return true;
    }
    if (normalized.startsWith('data:image/')) {
      final separator = normalized.indexOf(',');
      return separator >= 0 && separator < normalized.length - 1;
    }
    return normalized.startsWith('assets/') &&
        RegExp(r'\.(avif|gif|jpe?g|png|webp)$').hasMatch(normalized);
  }

  static bool _hasUsableLocalPreview(ProfilePhotoViewData photo) {
    if (photo.bytes?.isNotEmpty ?? false) return true;
    return photo.dataUri != null || photo.localPath != null;
  }
}
